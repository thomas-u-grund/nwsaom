* Extended tests, data-shape grid 1: DIRECTED one-mode networks. For each shape a fit, then every postestimation command that
* the help says works (estat simulate / gof / mems / timetest / importance, nwsaom simulate), checking that it runs, returns the
* documented e()/r() results, and properties of the simulated networks (size, directed type, structural dyads kept).
* Shapes: 2 waves (wave1/wave2 and waves(a b)), 3 and 4 waves; 6- and 5-actor networks; one effect and one period;
* structural zeros and ones (codes 10/11); missing ties (missnet); composition change (present, joinat/leaveat); constant and
* changing covariates; covariate rate; a co-evolving behavior.
* DRAFT, not yet run. Expected runtime: about 3-5 minutes (about 25 fits with k3 <= 100, gof with nsim(10)).
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

nwclear
clear
set obs 40
mata: xt_dir("D", 40, 4, 0.08, 0.04, 101)
forvalues w = 1/4 {
	nwset, mat(D`w') directed name(dn`w') nooutput
}
* the actor variables of this file (re-created after every clear)
capture program drop xt_dvars
program define xt_dvars
	capture drop x g xr z1 z2 z3 z4 tv1 tv2 tv3 tv4
	gen double x = mod(_n * 7, 11) / 3
	gen byte g = mod(_n, 3)
	gen double xr = mod(_n * 5, 7) / 2
	forvalues w = 1/4 {
		gen double z`w' = .
		gen double tv`w' = mod(_n * 3 + `w', 5)
	}
	mata: xt_beh("z", 40, 4, 5, 77)
end
xt_dvars

* ---------------------------------------------------------------------------------------------------------------------------
* 1. number of waves: wave1/wave2, waves(a b), 3 and 4 waves; stored results and every postestimation command
* ---------------------------------------------------------------------------------------------------------------------------
foreach spec in "wave1(dn1) wave2(dn2)" "waves(dn1 dn2)" "waves(dn1 dn2 dn3)" "waves(dn1 dn2 dn3 dn4)" {
	nwsaom, `spec' outdegree reciprocity transtrip k0(10) k3(60) seed(3)
	local W = e(nwaves)
	local P = `W' - 1
	assert e(N) == 40 & e(nodes) == 40
	assert "`e(cmd)'" == "nwsaom" & "`e(estat_cmd)'" == "nwsaom_estat" & "`e(version)'" != ""
	assert e(twomode) == 0 & e(has_behavior) == 0 & "`e(symtype)'" == "" & e(conditional) == 1
	assert colsof(e(b)) == 3 & colsof(e(V)) == 3 & colsof(e(tratio)) == 3
	assert e(tconv_max) < .
	local cn : colnames e(b)
	assert "`cn'" == "outdegree reciprocity transtrip"
	if strpos("`spec'", "wave1(") {
		assert `W' == 2 & e(rate) > 0 & e(rate) < . & e(rate_se) < .
		assert "`e(wave1)'" == "dn1" & "`e(wave2)'" == "dn2"
		capture confirm matrix e(rates)
		assert _rc != 0
	}
	else {
		assert colsof(e(rates)) == `P' & colsof(e(rates_se)) == `P' & colsof(e(rate_tratios)) == `P'
		assert wordcount("`e(waves)'") == `W'
	}
	* estat simulate: r(sim) is nsim * periods x 6, r(obs) periods x 6, generated networks directed with 40 nodes
	estat simulate, nsim(3) seed(1) generate(sd)
	assert r(nsim) == 3
	matrix S = r(sim)
	matrix O = r(obs)
	assert rowsof(S) == 3 * `P' & colsof(S) == 6 & rowsof(O) == `P' & colsof(O) == 6
	local scn : colnames S
	assert "`scn'" == "sim period ties mutual transitive behmean"
	forvalues r = 1/`=rowsof(S)' {
		assert S[`r', 3] < . & S[`r', 4] < . & S[`r', 5] < . & S[`r', 6] >= .
	}
	xt_simcheck sd 3 `P', nodes(40)
	* the ties column equals the number of ties of the generated network
	xt_netinfo sd_1_p1
	assert r(ties) == S[1, 3]
	nwdrop sd_*
	* estat gof
	estat gof, nsim(10) seed(2)
	xt_pcheck outdegree indegree geodesic
	estat gof, nsim(10) seed(2) stats(outdegree triad) maxdeg(5) maxdist(3) twotailed
	xt_pcheck outdegree triad
	* estat importance
	estat importance
	confirm matrix r(ri)
	confirm matrix r(importance)
	confirm matrix r(certainty)
	* estat mems: two waves only
	global XT_MCALLS 0
	global XT_MASYM 0
	if `W' == 2 {
		estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(4) nodots
		assert r(mems) < . & r(mems_sd) < . & r(mems_lb) <= r(mems_ub) & r(mems_p) >= 0 & r(mems_p) <= 1
		assert "`r(effect)'" == "reciprocity" & "`r(macro)'" == "xt_mties"
		* one trial call plus nsim x 2 interval values
		assert $XT_MCALLS == 41
	}
	else {
		capture noisily estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(4) nodots
		assert _rc == 498
		estat timetest
		assert r(df) >= 1 & r(p) >= 0 & r(p) <= 1
		confirm matrix r(effect)
		confirm matrix r(individual)
	}
	* nwsaom simulate at the fitted values gives the fitted simulation (same seed)
	estat simulate, nsim(3) seed(9)
	matrix A = r(sim)
	local th ""
	forvalues j = 1/3 {
		local th "`th' `=strofreal(el(e(b), 1, `j'), "%21.0g")'"
	}
	xt_rclist
	local rl "`r(list)'"
	nwsaom simulate, `spec' outdegree reciprocity transtrip theta(`th') rates(`rl') nsim(3) seed(9)
	matrix B = r(sim)
	assert mreldif(A, B) < 1e-12
	di "PASS directed `spec'"
}
di "PASS directed: 2, 3 and 4 waves, all postestimation commands"

* ---------------------------------------------------------------------------------------------------------------------------
* 2. very small networks (6 and 5 actors), one effect, one period
* ---------------------------------------------------------------------------------------------------------------------------
foreach n in 6 5 {
	nwclear
	clear
	set obs `n'
	* hand-made waves so that every period has created and dissolved ties
	if `n' == 6 {
		matrix T1 = (0,1,0,0,1,0 \ 0,0,1,0,0,0 \ 1,0,0,0,0,1 \ 0,0,1,0,1,0 \ 0,0,0,1,0,0 \ 1,0,0,0,0,0)
		matrix T2 = (0,1,1,0,0,0 \ 1,0,1,0,0,0 \ 1,0,0,0,0,0 \ 0,0,1,0,1,1 \ 0,0,0,1,0,0 \ 0,1,0,0,0,0)
		matrix T3 = (0,0,1,0,0,1 \ 1,0,1,0,0,0 \ 1,1,0,0,0,0 \ 0,0,0,0,1,1 \ 0,1,0,1,0,0 \ 0,1,0,0,0,0)
	}
	else {
		matrix T1 = (0,1,0,0,1 \ 0,0,1,0,0 \ 1,0,0,0,0 \ 0,0,1,0,1 \ 0,0,0,1,0)
		matrix T2 = (0,1,1,0,0 \ 1,0,1,0,0 \ 1,0,0,0,0 \ 0,0,0,0,1 \ 0,1,0,1,0)
		matrix T3 = (0,0,1,0,0 \ 1,0,1,0,0 \ 1,1,0,0,0 \ 0,0,0,0,1 \ 0,1,0,1,0)
	}
	forvalues w = 1/3 {
		nwset, mat(T`w') directed name(tn`w') nooutput
	}
	* one effect, one period
	nwsaom, wave1(tn1) wave2(tn2) outdegree k0(10) k3(60) seed(1)
	assert e(N) == `n' & colsof(e(b)) == 1 & e(rate) > 0 & e(rate) < .
	estat simulate, nsim(5) seed(1) generate(ts)
	assert rowsof(r(sim)) == 5
	xt_simcheck ts 5 1, nodes(`n')
	nwdrop ts_*
	estat gof, nsim(10) seed(1)
	xt_pcheck outdegree indegree geodesic
	estat mems, effect(outdegree) macro(xt_mties) nsim(20) seed(1) nodots
	assert r(mems) < .
	estat importance
	nwsaom simulate, wave1(tn1) wave2(tn2) outdegree theta(-1) rates(2) nsim(3) seed(1)
	assert r(nsim) == 3 & rowsof(r(sim)) == 3
	* one effect, two periods; two effects
	nwsaom, waves(tn1 tn2 tn3) outdegree k0(10) k3(60) seed(1)
	assert colsof(e(rates)) == 2
	estat simulate, nsim(3) seed(1)
	estat timetest
	nwsaom, waves(tn1 tn2 tn3) outdegree reciprocity k0(10) k3(60) seed(1)
	estat simulate, nsim(3) seed(1)
	estat gof, nsim(10) seed(1)
	* every parameter fixed (one parameter): e(tconv_max) is 0
	nwsaom, wave1(tn1) wave2(tn2) outdegree theta0(-1) fix(outdegree) k0(10) k3(40) seed(1)
	assert _b[outdegree] == -1 & e(tconv_max) == 0
	estat simulate, nsim(2) seed(1)
	di "PASS `n'-actor networks"
}
di "PASS very small networks, one effect, one period"

* ---------------------------------------------------------------------------------------------------------------------------
* 3. structural zeros (10) and ones (11): the simulated networks keep them
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 40
mata: xt_dir("D", 40, 3, 0.08, 0.04, 101)
mata:
SZ = J(40, 40, 0)
SZ[|1, 11 \ 1, 20|] = J(1, 10, 1)
SZ[|21, 30 \ 25, 30|] = J(5, 1, 1)
SO = J(40, 40, 0)
SO[2, 3] = 1
SO[4, 5] = 1
SO[33, 34] = 1
for (w=1; w<=3; w++) {
	M = st_matrix("D" + strofreal(w))
	M = M :* (1 :- SZ) :* (1 :- SO) + 10 :* SZ + 11 :* SO
	st_matrix("C" + strofreal(w), M)
}
st_matrix("SZ", SZ)
st_matrix("SO", SO)
end
forvalues w = 1/3 {
	nwset, mat(C`w') directed name(cn`w') nooutput
}
nwsaom describe, waves(cn1 cn2 cn3)
matrix DW = r(waves)
forvalues w = 1/3 {
	assert DW[`w', 4] == 15 & DW[`w', 5] == 3
}
foreach spec in "wave1(cn1) wave2(cn2)" "waves(cn1 cn2 cn3)" {
	nwsaom, `spec' outdegree reciprocity k0(10) k3(60) seed(2)
	local P = e(nwaves) - 1
	estat simulate, nsim(4) seed(1) generate(cs)
	xt_simcheck cs 4 `P', nodes(40)
	forvalues s = 1/4 {
		forvalues p = 1/`P' {
			xt_masked cs_`s'_p`p' SZ 0
			assert r(bad) == 0
			xt_masked cs_`s'_p`p' SO 1
			assert r(bad) == 0
		}
	}
	nwdrop cs_*
	estat gof, nsim(10) seed(1)
	xt_pcheck outdegree indegree geodesic
	if `P' == 1 {
		estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(1) nodots
		assert r(mems) < .
	}
	else {
		estat timetest
		assert r(p) < .
	}
	nwsaom simulate, `spec' outdegree reciprocity theta(-2 1.5) rates(`=cond(`P' == 1, "3", "3 3")') nsim(2) seed(1) gen(cq)
	forvalues s = 1/2 {
		xt_masked cq_`s'_p1 SZ 0
		assert r(bad) == 0
		xt_masked cq_`s'_p1 SO 1
		assert r(bad) == 0
	}
	nwdrop cq_*
}
di "PASS structural zeros and ones kept in estat simulate and nwsaom simulate"

* ---------------------------------------------------------------------------------------------------------------------------
* 4. missing ties (missnet), 2 and 3 waves
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 40
mata: xt_dir("D", 40, 3, 0.08, 0.04, 101)
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(mn`w') nooutput
}
matrix M1 = J(40, 40, 0)
matrix M2 = J(40, 40, 0)
matrix M3 = J(40, 40, 0)
forvalues j = 2/8 {
	matrix M2[1, `j'] = 1
	matrix M3[`j', 1] = 1
}
nwsaom, wave1(mn1) wave2(mn2) outdegree reciprocity missnet(M1 M2) k0(10) k3(60) seed(1)
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
xt_pcheck outdegree indegree geodesic
nwsaom, waves(mn1 mn2 mn3) outdegree reciprocity missnet(M1 M2 M3) k0(10) k3(60) seed(1)
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
estat timetest
di "PASS missing ties"

* ---------------------------------------------------------------------------------------------------------------------------
* 5. composition change: present() (actor 1 absent at waves 1-2, no ties at all; actor 40 absent at wave 3) and joinat/leaveat
* ---------------------------------------------------------------------------------------------------------------------------
mata:
for (w=1; w<=3; w++) {
	M = st_matrix("D" + strofreal(w))
	M[1, .] = J(1, 40, 0)
	M[., 1] = J(40, 1, 0)
	if (w == 3) {
		M[40, .] = J(1, 40, 0)
		M[., 40] = J(40, 1, 0)
	}
	st_matrix("P" + strofreal(w), M)
}
end
forvalues w = 1/3 {
	nwset, mat(P`w') directed name(pn`w') nooutput
}
gen byte p1 = _n != 1
gen byte p2 = _n != 1
gen byte p3 = _n != 40
* two waves (wave1/wave2): actor 1 is absent in the period and has no ties at its start, so it has none in any simulation
nwsaom, wave1(pn1) wave2(pn2) outdegree reciprocity present(p1 p2) k0(10) k3(60) seed(1)
estat simulate, nsim(5) seed(1) generate(ps)
// CONFIRMED BUG S2 (triage): even on the wave1()/wave2() path the absent actor gets ties in estat simulate
global XT_SFAILS ""
forvalues s = 1/5 {
	xt_rowcol ps_`s'_p1 1
	if r(deg) != 0 {
		di as error "FAIL present(): absent actor 1 has degree " r(deg) " in simulation `s' (wave1/wave2 path)"
		global XT_SFAILS "$XT_SFAILS S2-wave1wave2"
		continue, break
	}
}
nwdrop ps_*
estat gof, nsim(10) seed(1)
estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(1) nodots
* three waves: runs (the property for three waves is probed in xt_suspects.do)
nwsaom, waves(pn1 pn2 pn3) outdegree reciprocity present(p1 p2 p3) k0(10) k3(60) seed(1)
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
estat timetest
* joiners and leavers inside the periods
gen double jn = cond(_n == 1, 2.5, .)
gen double lv = cond(_n == 40, 2.4, .)
nwsaom, waves(pn1 pn2 pn3) outdegree reciprocity joinat(jn) leaveat(lv) k0(10) k3(60) seed(1)
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
di "PASS composition change"

* ---------------------------------------------------------------------------------------------------------------------------
* 6. covariates: constant (several effects) and changing (tvcov: estat stops, as documented); covariate rate
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
set obs 40
xt_dvars
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(dn`w') nooutput
}
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity egox(x) altx(x) samex(g) simx(x) k0(10) k3(60) seed(1)
assert colsof(e(b)) == 6
confirm matrix e(covmeans)
assert e(centered) == 1
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
estat importance
estat timetest
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity tvcov(tv1 tv2 tv3) egox(tv) k0(10) k3(60) seed(1)
assert "`e(tvcov)'" == "tv"
foreach sub in "simulate, nsim(2)" "gof, nsim(10)" "importance" "timetest" "mems, effect(outdegree) macro(xt_mties) nsim(20)" {
	capture noisily estat `sub'
	assert _rc == 198
}
nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity ratecov(xr) k0(10) k3(60) seed(1)
assert "`e(ratecov)'" == "xr" & e(ratecoef) < .
confirm matrix e(ratecoefs)
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(1) nodots
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity ratecov(xr x) k0(10) k3(60) seed(1)
assert colsof(e(ratecoefs)) == 2
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
di "PASS covariates and covariate rate"

* ---------------------------------------------------------------------------------------------------------------------------
* 7. a co-evolving behavior: 2 waves (wave1/wave2) and 3 waves
* ---------------------------------------------------------------------------------------------------------------------------
nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity behavior(z1 z2) linear avalt k0(10) k3(60) seed(2)
assert e(has_behavior) == 1 & e(p_net) == 2 & colsof(e(b)) == 4
assert e(rate_beh) > 0 & e(rate_beh) < . & e(rate_beh_se) < . & e(behmean) < .
assert "`e(behavior)'" == "z1 z2"
estat simulate, nsim(3) seed(1) generate(bs)
matrix S = r(sim)
forvalues r = 1/3 {
	assert S[`r', 6] >= 1 & S[`r', 6] <= 5
}
forvalues s = 1/3 {
	confirm variable bs_`s'_p1
	quietly summarize bs_`s'_p1
	assert r(min) >= 1 & r(max) <= 5 & r(N) == 40
}
xt_simcheck bs 3 1, nodes(40)
nwdrop bs_*
drop bs_*
estat gof, nsim(10) seed(1)
xt_pcheck outdegree indegree geodesic behavior
capture noisily estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(1) nodots
assert _rc == 498
estat importance
confirm matrix r(ri_beh)
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) linear quadratic avalt k0(10) k3(60) seed(2)
assert colsof(e(rates_beh)) == 2 & colsof(e(rates)) == 2 & colsof(e(rates_beh_se)) == 2
estat simulate, nsim(3) seed(1)
estat gof, nsim(10) seed(1)
xt_pcheck behavior
estat timetest
xt_samerates
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) linear quadratic avalt theta(-2 1) behtheta(0 0 0.5) rates(3 3) ratesbeh(1 1) nsim(2) seed(1)
assert rowsof(r(sim)) == 4
di "PASS co-evolution"

if "$XT_SFAILS" != "" {
	di as error "failures:$XT_SFAILS"
	exit 9
}
di "ALL PASS"
