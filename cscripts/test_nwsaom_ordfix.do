cscript

* Regression test: results must not depend on the state of the random-number generator or on earlier calls that sort
* (Mata's sort() and order() break ties by that state). Joiners and leavers with the SAME fractional time are the one
* place of nwsaom where events are sorted with ties (SaomTimedFromVars / SaomTimedLoad).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do

nwclear
mata:
mata set matastrict off
void tc_data() {
	n = 30
	rseed(2468)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.06)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
tc_data()
end
clear
set obs 30
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(tc`w') nooutput
}
* four joiners at 1.4, three leavers at 1.6 (tied times)
gen double jn = 1
gen double lv = 3
replace jn = 1.4 in 1/4
replace lv = 1.6 in 5/7
replace jn = 2.3 in 8

set seed 1
quietly nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity joinat(jn) leaveat(lv) k0(30) k3(100) seed(7)
matrix bref = e(b)
forvalues s = 2/5 {
	set seed `s'
	mata: junk = sort(round(runiform(1000, 1) * 3), 1); junk = order(round(runiform(1000, 1) * 3), 1)
	quietly nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity joinat(jn) leaveat(lv) k0(30) k3(100) seed(7)
	assert mreldif(e(b), bref) < 1e-12
}
di "PASS: fit with tied join and leave times is the same whatever the generator did before"

di as result "ALL TESTS PASSED"
