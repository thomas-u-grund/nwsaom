* behavior rate effects that send the rate to infinity (avexposure, avtinexposuredist2 on a model whose behavior is not a diffusion process):
* the fit must stop at once with r(498) (RSiena: "thetaBound should be set higher", checked for every free parameter, rates included, and a
* simulated period of more than a million ministeps is abandoned) instead of running for hours. A well-behaved rate effect still estimates.
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
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bd_data() {
	n = 40
	rseed(8642)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
bd_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(w`w') nooutput
	gen double b`w' = 1 + mod(_n * 7 + (_n > 20) * (`w' - 1) + (_n > 10) * (`w' > 2), 5)
	gen double c`w' = 1 + mod(_n * 7, 5) + (mod(_n + `w', 4) == 0) * (`w' > 1)
}
timer clear 1
timer on 1
foreach ef in avexposure avtinexposuredist2 {
	capture nwsaom, waves(w1 w2 w3) outdegree reciprocity behavior(b1 b2 b3) linear behrate(`ef') k0(10) k3(40) seed(5) cores(1)
	assert _rc == 498
}
timer off 1
quietly timer list 1
assert r(t1) < 60
* a rate effect that does not run away still estimates (a behavior with few changes)
nwsaom, waves(w1 w2 w3) outdegree reciprocity behavior(c1 c2 c3) linear behrate(outrate) k0(10) k3(40) seed(5) cores(1)
assert colsof(e(b)) >= 3
di as text "behavior rate divergence PASS"
