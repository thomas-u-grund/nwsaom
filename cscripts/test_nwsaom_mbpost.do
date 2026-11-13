* Several behaviors: the postestimation commands (estat gof, simulate, importance, timetest, score). On s50 with alcohol and smoking the
* sigmas of estat importance equal RSiena 1.6.14's sienaRI() (they depend on the data only); gof, simulate and the tests agree with RSiena
* within simulation error (dev/saom_rsiena_mbgof.R/.do). estat mems stays network-only.
cscript
* The core package nwcommands is found through the environment variable NWCORE (path of the core checkout).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 255
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
local bv "behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behsim)"
nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip `bv' k3(200) seed(1)

* 1. estat gof: one behavior distribution per behavior; join(off) and the triad census
estat gof, nsim(20) seed(1)
foreach s in outdegree indegree geodesic behavior_a behavior_s {
	assert r(p_`s') >= 0 & r(p_`s') <= 1 & r(mhd_`s') < .
}
estat gof, nsim(6) seed(1) stats(triad behavior) join(off) name(mb)
foreach s in triad_p1 triad_p2 behavior_a_p1 behavior_a_p2 behavior_s_p1 behavior_s_p2 {
	assert r(p_`s') < .
}
di as text "estat gof PASS"

* 2. estat simulate: one mean per behavior; the observed end waves; generate() names networks and behavior variables
estat simulate, nsim(4) seed(1) generate(sm)
local cn : colnames r(sim)
assert "`cn'" == "sim period ties mutual transitive behmean_a behmean_s"
assert rowsof(r(sim)) == 8
matrix O = r(obs)
quietly summarize a2
assert abs(O[1, 6] - r(mean)) < 1e-10
quietly summarize s3
assert abs(O[2, 7] - r(mean)) < 1e-10
assert O[1, 3] == 116 & O[2, 3] == 122
confirm variable sm_4_p2_a sm_4_p2_s
quietly nwvalidate sm_4_p2
assert "`r(exists)'" == "true"
capture estat simulate, nsim(4) seed(1) generate(sm)
assert _rc == 483
estat simulate, nsim(4) seed(1) generate(sm) replace ratesbeh(1 1 2 2)
capture estat simulate, nsim(4) ratesbeh(1 1)
assert _rc == 198
di as text "estat simulate PASS"

* 3. estat importance: the sigmas equal sienaRI() (RSiena 1.6.14)
estat importance
matrix S = r(sigma)
matrix SB = r(sigma_beh)
mata: st_numscalar("__d", max(abs(st_matrix("S")' - (.4384, .2140, .6514, .2340, .3608))))
assert scalar(__d) < 1e-4
mata: st_numscalar("__d", max(abs(st_matrix("SB")' - (.9513, 1.8694, .8416, .7517, .6712, .4392))))
assert scalar(__d) < 1e-4
assert rowsof(r(certainty_beh)) == 2 & colsof(r(certainty_beh)) == 2
di as text "estat importance PASS"

* 4. estat timetest (one dummy per effect and later period); estat mems refused
estat timetest
assert r(df) == 11 & r(chi2) < .
capture estat mems, effect(reciprocity) macro(ties)
assert _rc == 498
di as text "estat timetest PASS"

* 5. estat score of a fixed effect
nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip `bv' k3(200) seed(1) fix(transtrip) theta0(0 0 0 0 0)
estat score
assert r(chi2) > 50 & r(df) == 1
di as text "estat score PASS"
