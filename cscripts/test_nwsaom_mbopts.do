* Several behaviors together with present(), structural zeros (code 10), network endowment/creation and a non-directed network: the
* observed statistics equal siena07's targets (RSiena 1.6.14, dev/saom_rsiena_mbopts.R); the estimates agree with siena07 within
* simulation error (dev/saom_rsiena_mbopts.do). Reciprocity and the non-directed degree are counted once per tie here (RSiena: twice);
* the linear shape statistics are not compared (another representation). ratecov(), missnet() and missbeh() are refused.
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
capture program drop mbcheck
program define mbcheck
	args idx ref rates
	mata: __r0 = .
	mata: __rb0 = .
	mata: __t = SaomMBInit(__ns_mbGw, __nwsaom_last_M, __ns_mbBw, __ns_mbmin, __ns_mbmax, __ns_mbsim, __ns_mbover, __ns_mbMb, __r0, __rb0)
	mata: SaomBatchCleanup()
	mata: __tg = colsum(__t.target)[strtoreal(tokens("`idx'"))]
	mata: __tg
	mata: st_numscalar("__d", max(abs(__tg - strtoreal(tokens("`ref'")))))
	assert scalar(__d) < 1e-3
	mata: st_numscalar("__d", max(abs((__t.targetRateNet, rowshape(__t.targetRateBeh, 1)) - strtoreal(tokens("`rates'")))))
	assert scalar(__d) < 1e-10
end
local bv "behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behsim)"
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	import delimited "dev/saom_rsiena_mbopts_struct_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
	import delimited "dev/saom_rsiena_mbopts_sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(Y`w')
}
import delimited "dev/saom_rsiena_mbopts_present.csv", clear varnames(1)
rename (v1 v2 v3) (p1 p2 p3)
tempfile pres
save `pres'
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
merge 1:1 _n using `pres', nogenerate
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
	nwset, mat(S`w') directed name(st`w') nooutput
	nwset, mat(Y`w') undirected name(sy`w') nooutput
}

* 1. present(): actors 1-4 join at wave 2, actors 47-50 leave at wave 2
nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip `bv' present(p1 p2 p3) k3(50) seed(1)
assert "`e(engine)'" == "native"
mbcheck "1 2 3 4 5 7 8 10 11" "238 80 225 21.9957 28.94 121.0711 53.9086 76.2 33.9625" "115 106 27 33 17 18"
estat simulate, nsim(3) seed(1)
di as text "present() PASS"

* 2. structural zeros (code 10) between actors 1-10 and 41-50
nwsaom, waves(st1 st2 st3) outdegree reciprocity transtrip `bv' k3(50) seed(1)
mbcheck "1 2 3 4 5 7 8 10 11" "232 78 212 21.792 29.3743 121.0711 54.9653 76.2 33.2691" "112 102 27 33 17 18"
* structural ones (code 11): the tie 1 -> 2 is fixed at 1
forvalues w = 1/3 {
	matrix O`w' = S`w'
	matrix O`w'[1, 2] = 11
	nwset, mat(O`w') directed name(so`w') nooutput
}
nwsaom, waves(so1 so2 so3) outdegree reciprocity transtrip `bv' k3(20) seed(1)
assert "`e(engine)'" == "native"
di as text "structural zeros PASS"

* 3. reciprocity split into endowment and creation
nwsaom, waves(te1 te2 te3) outdegree transtrip `bv' endow(reciprocity) creation(reciprocity) k3(50) seed(1)
mbcheck "1 2 3 4 5 6 8 9 11 12" "238 -58 63 225 21.9957 28.94 121.0711 53.9086 76.2 33.9625" "115 106 27 33 17 18"
capture nwsaom, waves(st1 st2 st3) outdegree transtrip `bv' endow(reciprocity) creation(reciprocity) k3(5) seed(1)
assert _rc == 198
di as text "network endowment/creation PASS"

* 4. non-directed network: forcing (the default) and a pairwise type
nwsaom, waves(sy1 sy2 sy3) symmetric outdegree transtriads `bv' k3(50) seed(2)
mbcheck "1 2 3 4 6 7 9 10" "316 66 27.3935 37.7943 121.0711 53.463 76.2 31.086" "138 128 27 33 17 18"
estat simulate, nsim(3) seed(1)
nwsaom, waves(sy1 sy2 sy3) symmetric symtype(joint) outdegree `bv' k3(50) seed(2)
assert "`e(engine)'" == "native"
estat gof, nsim(5) seed(1) stats(outdegree behavior)
di as text "non-directed PASS"

* 5. still refused: ratecov(), missnet(), missbeh()
gen double rc = a1
capture nwsaom, waves(te1 te2 te3) outdegree `bv' ratecov(rc) k3(5)
assert _rc == 198
gen byte m1 = 0
gen byte m2 = 0
gen byte m3 = 0
capture nwsaom, waves(te1 te2 te3) outdegree `bv' missbeh(m1 m2 m3) k3(5)
assert _rc == 198
di as text "refusals PASS"
