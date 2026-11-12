* Extended tests: PROBES OF SUSPECTED BUGS found by reading the code (list and file:line references in cscripts/xt_NOTES.md).
* Each probe runs in its own capture block and prints "SUSPECT Sn CONFIRMED" or "SUSPECT Sn NOT CONFIRMED" (or "PROBE Sn
* FAILED rc=..." when the probe itself could not run). Confirmed suspects and failed probes are counted in $XT_FAIL; the file
* ends with assert $XT_FAIL == 0, so it FAILS while any suspect is real. Items marked NOTE are design questions: they are
* printed, not counted.
* DRAFT, not yet run. Expected runtime: about 3-4 minutes.
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

global XT_FAIL 0
global XT_NOTES 0
* xt_verdict id rc confirmed text: rc = _rc of the probe block, confirmed = 1/0
capture program drop xt_verdict
program define xt_verdict
	args id rc conf text
	if `rc' != 0 {
		di as error "PROBE `id' FAILED rc=`rc' (`text')"
		global XT_FAIL = $XT_FAIL + 1
	}
	else if `conf' == 1 {
		di as error "SUSPECT `id' CONFIRMED: `text'"
		global XT_FAIL = $XT_FAIL + 1
	}
	else di as text "SUSPECT `id' NOT CONFIRMED: `text'"
end
capture program drop xt_note
program define xt_note
	args id rc conf text
	if `rc' != 0 di as text "NOTE `id': probe failed rc=`rc' (`text')"
	else di as text "NOTE `id' " cond(`conf' == 1, "HOLDS", "DOES NOT HOLD") ": `text'"
	global XT_NOTES = $XT_NOTES + 1
end
* xt_nnet: r(n) = number of networks in memory, r(cur) = current network
capture program drop xt_nnet
program define xt_nnet, rclass
	quietly nwcurrent
	return scalar n = r(networks)
	return local cur "`r(current)'"
end

* ---------------------------------------------------------------------------------------------------------------------------
* data: 40 actors, 3 waves; actor 1 absent (and without ties) at waves 1 and 2, actor 40 absent at wave 3
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 40
mata: xt_dir("D", 40, 3, 0.08, 0.04, 101)
mata:
for (w=1; w<=3; w++) {
	M = st_matrix("D" + strofreal(w))
	if (w <= 2) {
		M[1, .] = J(1, 40, 0)
		M[., 1] = J(40, 1, 0)
	}
	if (w == 3) {
		M[40, .] = J(1, 40, 0)
		M[., 40] = J(40, 1, 0)
	}
	st_matrix("P" + strofreal(w), M)
}
end
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(dn`w') nooutput
	nwset, mat(P`w') directed name(pn`w') nooutput
}
gen byte p1 = _n != 1
gen byte p2 = _n != 1
gen byte p3 = _n != 40
gen double x = mod(_n * 7, 11) / 3

* ---------------------------------------------------------------------------------------------------------------------------
* S2a: waves(a b) with present(): help says waves(a b) is an equivalent spelling of wave1(a) wave2(b), but
*      __nwsaom_last_present is set only on the wave1()/wave2() path (nwsaom.ado:3085), so estat simulate may let the absent
*      actor 1 form ties
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, waves(pn1 pn2) outdegree reciprocity present(p1 p2) k0(10) k3(60) seed(1)
	estat simulate, nsim(5) seed(1) generate(sa)
	forvalues s = 1/5 {
		xt_rowcol sa_`s'_p1 1
		if r(deg) > 0 local c = 1
	}
	nwdrop sa_*
}
xt_verdict S2a `=_rc' `c' "waves(a b) present(): absent actor 1 gets ties in estat simulate"

* S2b: three waves with present(): actor 1 is absent at waves 1-2, so it must stay isolated in period 1 of every simulation
local c = 0
capture noisily {
	nwsaom, waves(pn1 pn2 pn3) outdegree reciprocity present(p1 p2 p3) k0(10) k3(60) seed(1)
	estat simulate, nsim(5) seed(1) generate(sb)
	forvalues s = 1/5 {
		xt_rowcol sb_`s'_p1 1
		if r(deg) > 0 local c = 1
	}
	nwdrop sb_*
}
xt_verdict S2b `=_rc' `c' "3-wave present(): absent actor 1 gets ties in period 1 of estat simulate"

* S2c: estat importance after a 3-wave present() fit (help: not available with present()); the guard
*      (nwsaom_estat_importance.ado:37) reads __nwsaom_last_present, which this path leaves empty
local c = 0
capture noisily {
	capture noisily estat importance
	local c = (_rc == 0)
}
xt_verdict S2c `=_rc' `c' "estat importance runs after a 3-wave present() fit"

* S2d: joinat()/leaveat(): actor 1 joins at time 2.5, so it must have no ties in period 1 (it has none at wave 1)
local c = 0
capture noisily {
	gen double jn = cond(_n == 1, 2.5, .)
	nwsaom, waves(pn1 pn2 pn3) outdegree reciprocity joinat(jn) k0(10) k3(60) seed(1)
	estat simulate, nsim(5) seed(1) generate(sj)
	forvalues s = 1/5 {
		xt_rowcol sj_`s'_p1 1
		if r(deg) > 0 local c = 1
	}
	nwdrop sj_*
}
capture drop jn
xt_verdict S2d `=_rc' `c' "joinat(): actor 1 gets ties before it joins in estat simulate"

* ---------------------------------------------------------------------------------------------------------------------------
* S1: e(present) is read by the groups postestimation (nwsaom_estat.ado:537, nwsaom_estat_simulate.ado:209,
*     nwsaom_estat_impgroups.ado:12) but never posted, so groups() + present() simulations ignore presence
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	gen byte grp = 1 + (_n > 20)
	nwsaom, waves(pn1 pn2 pn3) groups(grp) outdegree reciprocity present(p1 p2 p3) k0(10) k3(60) seed(1) cores(1)
	di "e(present) = `e(present)'"
	estat simulate, nsim(4) seed(1) generate(sg)
	forvalues s = 1/4 {
		xt_rowcol sg_g1_`s'_p1 1
		if r(deg) > 0 local c = 1
	}
	nwdrop sg_*
	capture noisily estat importance
	if _rc == 0 local c = 1
}
capture drop grp
xt_verdict S1 `=_rc' `c' "groups() + present(): absent actor gets ties, or estat importance runs (e(present) not posted)"

* ---------------------------------------------------------------------------------------------------------------------------
* S3: estat importance after missnet() (help: not available with missing-data options); the guard checks only endowment
*     effects and present (nwsaom_estat_importance.ado:37)
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	matrix M1 = J(40, 40, 0)
	matrix M2 = J(40, 40, 0)
	forvalues j = 2/8 {
		matrix M2[3, `j'] = 1
	}
	nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity missnet(M1 M2) k0(10) k3(60) seed(1)
	capture noisily estat importance
	local c = (_rc == 0)
}
xt_verdict S3 `=_rc' `c' "estat importance runs after missnet()"

* ---------------------------------------------------------------------------------------------------------------------------
* S4: estat mems after fix(): e(V) has a zero row and column for the fixed parameter (unw_saom.do:9204-9211), cholesky(V) in
*     saom_mems_draw_theta() (nwsaom_estat.ado:1383) then returns missing values
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity theta0(-2 0.5) fix(reciprocity) k0(10) k3(60) seed(1)
	capture noisily estat mems, effect(outdegree) macro(xt_mties) nsim(20) seed(1) nodots
	if _rc local c = 1
	else if r(mems) >= . local c = 1
}
xt_verdict S4 `=_rc' `c' "estat mems after fix() fails or gives a missing r(mems)"

* ---------------------------------------------------------------------------------------------------------------------------
* S7: an nwsaom call that fails late overwrites the Mata state (__nwsaom_last_G*, nwsaom.ado:834; __nwsaom_last_M, :1089)
*     while e() keeps the earlier fit, so estat simulate afterwards simulates another model
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(60) seed(1)
	estat simulate, nsim(3) seed(5)
	matrix __A = r(sim)
	* transtriads is refused for a directed relation only after the Mata model was rebuilt (nwsaom.ado:1467)
	capture noisily nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity transtrip transtriads k3(60)
	assert _rc != 0
	capture noisily estat simulate, nsim(3) seed(5)
	if _rc local c = 1
	else {
		matrix __B = r(sim)
		if mreldif(__A, __B) != 0 local c = 1
	}
}
xt_verdict S7a `=_rc' `c' "estat simulate after a late nwsaom error differs from before it"

* S7b: estimates restore of an older fit: the Mata state is that of the latest fit, there is no guard
local c = 0
capture noisily {
	nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(60) seed(1)
	estimates store xa
	estat simulate, nsim(3) seed(5)
	matrix __A = r(sim)
	nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity egox(x) k0(10) k3(60) seed(1)
	estimates restore xa
	capture noisily estat simulate, nsim(3) seed(5)
	if _rc == 0 {
		matrix __B = r(sim)
		if mreldif(__A, __B) != 0 local c = 1
	}
	* (a clean refusal with an error is acceptable)
	estimates drop xa
}
xt_verdict S7b `=_rc' `c' "estat simulate after estimates restore simulates the latest fit, not the restored one"

* ---------------------------------------------------------------------------------------------------------------------------
* S8 (NOTE): nwsaom simulate replaces e() with its set-up fit (not in the help); an error after the set-up fit leaves e() changed
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(60) seed(1)
	xt_esnap
	capture noisily nwsaom simulate, waves(dn1 dn2 dn3) outdegree theta(-2) rates(3 3) nsim(0) seed(1)
	local rc0 = _rc
	if `"`e(cmdline)'"' != `"$XT_ECMDLINE"' local c = 1
	di "nsim(0): rc = `rc0'"
}
xt_note S8 `=_rc' `c' "e() is replaced after nwsaom simulate ... nsim(0)"

* ---------------------------------------------------------------------------------------------------------------------------
* S9 (NOTE): r(sim) of estat simulate is a Stata matrix; nsim*periods > 800 rows fails on Stata BE (matsize, GOTCHA)
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, waves(dn1 dn2 dn3) outdegree k0(10) k3(40) seed(1)
	capture noisily estat simulate, nsim(401) seed(1)
	local c = (_rc != 0)
	di "nsim(401) x 2 periods: rc = `=_rc' (c(matsize) = `c(matsize)')"
}
xt_note S9 `=_rc' `c' "estat simulate fails for nsim*periods > 800"

* ---------------------------------------------------------------------------------------------------------------------------
* S10: nwsaom describe rejects waves of mixed declaration (undirected and directed but tie-symmetric) that nwsaom accepts
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	mata: xt_sym("S", 40, 2, 0.08, 0.04, 12)
	nwset, mat(S1) undirected name(su1) nooutput
	nwset, mat(S2) directed name(sd2) nooutput
	capture noisily nwsaom, waves(su1 sd2) outdegree k0(10) k3(40) seed(1)
	local rfit = _rc
	capture noisily nwsaom describe, waves(su1 sd2)
	local rdes = _rc
	di "nwsaom rc = `rfit', nwsaom describe rc = `rdes'"
	local c = (`rfit' == 0 & `rdes' != 0)
}
xt_verdict S10 `=_rc' `c' "nwsaom accepts the mixed waves, nwsaom describe refuses them"

* ---------------------------------------------------------------------------------------------------------------------------
* S11: generate() names. (a, NOTE) an existing stub stops with an nwset name clash, there is no replace option; (b) a stub of
*      28 characters makes names of 33 characters: a refusal must come before any network is created
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(60) seed(1)
	estat simulate, nsim(1) seed(1) generate(dup)
	capture noisily estat simulate, nsim(1) seed(1) generate(dup)
	local c = (_rc != 0)
	di "second generate(dup): rc = `=_rc'"
	capture nwdrop dup_*
}
xt_note S11a `=_rc' `c' "generate() with an existing stub stops"
local c = 0
capture noisily {
	xt_nnet
	local n0 = r(n)
	capture noisily estat simulate, nsim(2) seed(1) generate(abcdefghijabcdefghijabcdefgh)
	local rc1 = _rc
	xt_nnet
	di "28-character stub: rc = `rc1', networks before `n0' after `r(n)'"
	if `rc1' != 0 & r(n) != `n0' local c = 1
	if `rc1' == 0 {
		* the networks were created: their names must be complete (no truncation that merges simulations)
		capture xt_netinfo abcdefghijabcdefghijabcdefgh_2_p2
		if _rc local c = 1
	}
}
xt_verdict S11b `=_rc' `c' "a long generate() stub leaves partial or truncated networks"

* ---------------------------------------------------------------------------------------------------------------------------
* S14: estat mems with a macro() that fails: the trial call (nwsaom_estat.ado:1253) may leave its temporary network
*      (__nwsaom_mems_tmpnet) and change the current network
* ---------------------------------------------------------------------------------------------------------------------------
local c = 0
capture noisily {
	nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity k0(10) k3(60) seed(1)
	nwcurrent dn1
	xt_nnet
	local n0 = r(n)
	local cur0 "`r(cur)'"
	capture noisily estat mems, effect(outdegree) macro(nosuchprogram) nsim(20) seed(1) nodots
	assert _rc == 498
	xt_nnet
	if r(n) != `n0' | "`r(cur)'" != "`cur0'" local c = 1
	capture nwdrop __nwsaom_mems_tmpnet
}
xt_verdict S14 `=_rc' `c' "estat mems with a failing macro() leaves a network behind or changes the current network"

* ---------------------------------------------------------------------------------------------------------------------------
* groups: S5 (estat simulate ratesbeh() after groups() + behavior: nwsaom_estat_simgroups.ado:10 has no RATESBEH() option)
* and S6 (rates() after gwaves(): the per-group count check, nwsaom_estat_simulate.ado:118, uses the number of periods of
* the whole fit before the group's own number is set at :149)
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 50
mata: xt_grp("G", (15, 20, 15), 3, 0.15, 0.06, 55, 0)
forvalues w = 1/3 {
	nwset, mat(G`w') directed name(g`w') nooutput
	gen double z`w' = .
}
mata: xt_beh("z", 50, 3, 5, 77)
gen byte grp = 1 + (_n > 15) + (_n > 35)
local c = 0
capture noisily {
	nwsaom, waves(g1 g2 g3) groups(grp) outdegree reciprocity behavior(z1 z2 z3) linear k0(10) k3(60) seed(1) cores(1)
	xt_rclist
	local rl "`r(list)'"
	local bl "`r(behlist)'"
	di "rates: `rl'   behavior rates: `bl'"
	capture noisily estat simulate, nsim(2) seed(1) rates(`rl') ratesbeh(`bl')
	local c = (_rc != 0)
}
xt_verdict S5 `=_rc' `c' "estat simulate ratesbeh() after groups() + behavior() is refused"
local c = 0
capture noisily {
	nwsaom, waves(g1 g2 g3) groups(grp) gwaves(2: 1 2) outdegree reciprocity k0(10) k3(60) seed(1) cores(1)
	xt_rclist
	capture noisily estat simulate, nsim(2) seed(1) rates(`r(list)')
	local c = (_rc != 0)
}
xt_verdict S6 `=_rc' `c' "estat simulate rates() after gwaves() is refused"

di as text "suspects confirmed or probes failed: $XT_FAIL; notes printed: $XT_NOTES"
assert $XT_FAIL == 0
di "ALL PASS"
