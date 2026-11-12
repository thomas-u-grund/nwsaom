* Extended tests: LONG OPTION STRINGS. Stata's plugin call takes at most about 4,000 characters of options (GOTCHA "options too
* long"); anything that grows with the network or the model must not travel in that string. Stress: a 120 x 40 two-mode network
* (the structural dyads of its embedding), a 100-actor one-mode network with about 2,500 structural zeros and some structural
* ones (directed and non-directed), 42 covariate effects with long variable names (22 characters), 10 interactions, 16 rate covariates,
* full-precision theta()/rates() lists, and a long generate() stub. Every postestimation path that makes a single plugin call
* (estat simulate, nwsaom simulate, estat gof, estat mems) is run on each.
* DRAFT, not yet run. Expected runtime: about 4-6 minutes (the 100- and 160-node fits dominate).
cscript
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 255
do cscripts/xt_common.do

* ---------------------------------------------------------------------------------------------------------------------------
* 1. a 120 x 40 two-mode network, 3 waves (about 120 * 40 free and 160^2 - 4,800 structural dyads)
* ---------------------------------------------------------------------------------------------------------------------------
global XT_LFAILS ""
nwclear
clear
mata: xt_tm("TB", 120, 40, 3, 0.06, 0.04, 31)
forvalues w = 1/3 {
	nwset, mat(TB`w') bipartite name(tb`w') nooutput
}
nwsaom, waves(tb1 tb2 tb3) outdegree indegpopularity outactivity k0(10) k3(60) seed(1)
assert e(n_actors) == 120 & e(n_events) == 40
estat simulate, nsim(2) seed(1) generate(bt)
xt_simcheck bt 2 2, nodes(160) twomode nactors(120)
nwdrop bt_*
xt_samerates
estat importance
estat timetest
local th ""
forvalues j = 1/3 {
	local th "`th' `=strofreal(el(e(b), 1, `j'), "%21.0g")'"
}
xt_rclist
nwsaom simulate, waves(tb1 tb2 tb3) outdegree indegpopularity outactivity theta(`th') rates(`r(list)') nsim(2) seed(1)
nwsaom simulate, waves(tb1 tb2 tb3) outdegree theta(-2) rates(5 5) nsim(2) seed(1)
di "PASS 120 x 40 two-mode network"

* ---------------------------------------------------------------------------------------------------------------------------
* 2. 100 actors, two classes: every cross-class dyad is a structural zero (2 x 50 x 50 = 5,000 cells), 20 structural ones
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 100
mata: xt_grp("SB", (50, 50), 3, 0.10, 0.04, 32, 0)
mata: xt_grp("SU", (50, 50), 3, 0.10, 0.04, 33, 1)
mata:
cls = (J(50, 1, 1) \ J(50, 1, 2))
SZ = (cls * J(1, rows(cls), 1) :!= J(rows(cls), 1, 1) * cls')
SO = J(100, 100, 0)
for (k=1; k<=10; k++) {
	SO[2 * k, 2 * k + 1] = 1
	SO[2 * k + 1, 2 * k] = 1
}
for (w=1; w<=3; w++) {
	M = st_matrix("SB" + strofreal(w))
	st_matrix("SBc" + strofreal(w), M :* (1 :- SZ) :* (1 :- SO) + 10 :* SZ + 11 :* SO)
	M = st_matrix("SU" + strofreal(w))
	st_matrix("SUc" + strofreal(w), M :* (1 :- SZ) :* (1 :- SO) + 10 :* SZ + 11 :* SO)
}
st_matrix("SZ", SZ)
st_matrix("SO", SO)
end
forvalues w = 1/3 {
	nwset, mat(SBc`w') directed name(sb`w') nooutput
	nwset, mat(SUc`w') undirected name(su`w') nooutput
}
foreach net in sb su {
	nwsaom, waves(`net'1 `net'2 `net'3) outdegree k0(10) k3(60) seed(1)
	local und = ("`net'" == "su")
	estat simulate, nsim(2) seed(1) generate(lz)
	xt_simcheck lz 2 2, nodes(100) `=cond(`und', "undirected", "")'
	forvalues s = 1/2 {
		forvalues p = 1/2 {
			xt_masked lz_`s'_p`p' SZ 0
			assert r(bad) == 0
			xt_masked lz_`s'_p`p' SO 1
			assert r(bad) == 0
		}
	}
	nwdrop lz_*
	xt_samerates
	estat gof, nsim(10) seed(1) stats(outdegree)
	nwsaom, waves(`net'1 `net'2) outdegree k0(10) k3(60) seed(1)
	estat mems, effect(outdegree) macro(xt_mties) nsim(20) seed(1) nodots
	assert r(mems) < .
	nwsaom simulate, waves(`net'1 `net'2 `net'3) outdegree theta(-2) rates(4 4) nsim(2) seed(1) generate(lq)
	forvalues s = 1/2 {
		xt_masked lq_`s'_p2 SZ 0
		assert r(bad) == 0
	}
	nwdrop lq_*
}
di "PASS 100 actors with 5,000 structural zeros (directed and non-directed)"

* ---------------------------------------------------------------------------------------------------------------------------
* 3. 42 covariate effects with long variable names (22 characters), 10 interactions, 16 rate covariates
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 100
mata: xt_dir("DL", 100, 3, 0.05, 0.03, 34)
forvalues w = 1/3 {
	nwset, mat(DL`w') directed name(dl`w') nooutput
}
local vl ""
forvalues k = 1/21 {
	local nm = "covariate_long_name_" + string(`k', "%02.0f")
	gen double `nm' = mod(_n * (`k' + 2), 7 + `k') / 3
	local vl "`vl' `nm'"
}
local nv : word count `vl'
assert `nv' == 21
* 2 + 21 + 21 effects; the coefficients in theta() with full precision
local th "-2.512345678901234 1.234567890123456"
forvalues k = 1/42 {
	local th "`th' `=strofreal(0.001 * `k', "%21.0g")'"
}
nwsaom simulate, waves(dl1 dl2 dl3) outdegree reciprocity egox(`vl') altx(`vl') theta(`th') rates(4.123456789012345 4.987654321098765) nsim(3) seed(1) generate(lc)
assert rowsof(r(sim)) == 6
xt_simcheck lc 3 2, nodes(100)
nwdrop lc_*
* the model in memory is the set-up fit of nwsaom simulate: 44 coefficients
assert colsof(e(b)) == 44
local cn : colnames e(b)
assert strpos("`cn'", "egox_covariate_long_name_21") > 0 & strpos("`cn'", "altx_covariate_long_name_01") > 0
estat simulate, nsim(2) seed(1)
estat gof, nsim(10) seed(1) stats(outdegree)
* 10 interactions with an ego covariate (coefficient names longer than 32 characters become ix_...)
local ia ""
forvalues k = 1/10 {
	local ia "`ia' egox_covariate_long_name_`=string(`k', "%02.0f")'#reciprocity"
}
local evl ""
forvalues k = 1/10 {
	local evl "`evl' covariate_long_name_`=string(`k', "%02.0f")'"
}
local th "-2.5 1.2"
forvalues k = 1/20 {
	local th "`th' 0.01"
}
nwsaom simulate, waves(dl1 dl2 dl3) outdegree reciprocity egox(`evl') interact(`ia') theta(`th') rates(4 4) nsim(2) seed(1)
assert colsof(e(b)) == 22
local cn : colnames e(b)
foreach c of local cn {
	assert strlen("`c'") <= 32
}
* 16 rate covariates (the maximum, nwsaom.ado:786); 17 are refused
local rl16 : word 1 of `vl'
forvalues k = 2/16 {
	local rl16 "`rl16' `: word `k' of `vl''"
}
capture noisily nwsaom, waves(dl1 dl2 dl3) outdegree reciprocity ratecov(`rl16') k0(10) k3(40) seed(1)
assert inlist(_rc, 0, 498)
if _rc == 0 {
	assert colsof(e(ratecoefs)) == 16
	// N8 (fixed): estat simulate after ratecov() with 16 covariates (before: "too many options", r(3598); the K x n covariate
	// values went into the plugin argument string; now they travel in the data)
	capture noisily estat simulate, nsim(2) seed(1)
	if _rc {
		di as error "FAIL N8: estat simulate after ratecov(16 covariates) -> r(" _rc "), frame `c(frame)'"
		global XT_LFAILS "$XT_LFAILS N8"
		if "`c(frame)'" != "default" frame change default
	}
	capture noisily estat gof, nsim(10) seed(1) stats(outdegree)
	if _rc {
		di as error "FAIL N8: estat gof after ratecov(16 covariates) -> r(" _rc ")"
		global XT_LFAILS "$XT_LFAILS N8-gof"
		if "`c(frame)'" != "default" frame change default
	}
}
local rl17 "`rl16' `: word 17 of `vl''"
capture noisily nwsaom, waves(dl1 dl2 dl3) outdegree reciprocity ratecov(`rl17') k3(40)
assert _rc == 198
di "PASS many covariates, interactions and rate covariates"

* ---------------------------------------------------------------------------------------------------------------------------
* 4. long network names and a long generate() stub (the generated names stay within 32 characters)
* ---------------------------------------------------------------------------------------------------------------------------
forvalues w = 1/2 {
	nwset, mat(DL`w') directed name(a_rather_long_network_name_w`w') nooutput
}
// N10 (fixed): two waves with 29-character names (before: the results table failed, "<w1>_to_<w2> invalid name", r(3598); the
// equation name is now cut to 32 characters)
capture noisily nwsaom, waves(a_rather_long_network_name_w1 a_rather_long_network_name_w2) outdegree reciprocity k0(10) k3(60) seed(1)
if _rc {
	di as error "FAIL N10: 2 waves with long names -> r(" _rc "), e(cmd) now `e(cmd)', e(waves) `e(waves)', frame `c(frame)'"
	global XT_LFAILS "$XT_LFAILS N10"
	if "`c(frame)'" != "default" frame change default
}
else {
	assert "`e(waves)'" == "a_rather_long_network_name_w1 a_rather_long_network_name_w2"
	estat simulate, nsim(2) seed(1) generate(stub_of_twenty_two_ch)
	xt_simcheck stub_of_twenty_two_ch 2 1, nodes(100)
	nwdrop stub_of_twenty_two_ch_*
	di "PASS long network names"
}

if "$XT_LFAILS" != "" {
	di as error "failures: $XT_LFAILS"
	exit 9
}
di "ALL PASS"
