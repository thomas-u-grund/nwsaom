* String covariates (1.5.16): effects that compare categories take a string variable and give the fit of the
* encoded variable; effects that use values as numbers stop with r(109) (before, a string was read as missing).
* Needs nwcommands 3.20.1 (_nwstrcat).
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
set obs 36
mata:
mata set matastrict off
void c2_data() {
	n = 36
	rseed(86420)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
c2_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(c2`w') nooutput
}
gen double z = mod(_n * 5, 4)
gen str8 zs = word("delta alpha charlie bravo", z + 1)
label variable zs "group (string)"
describe, varlist
local vars0 `r(varlist)'
datasignature
local sig0 `r(datasignature)'

* the scanner: categorical uses are returned, numeric ones stop
local __saom_strcat
_nwsaom_strcheck , wave1(c22) wave2(c23) outdegree samex(zs) homxoutact(zs) behx(avsamexalt:zs) egox(z)
assert "`__saom_strcat'" == "zs zs zs"
rcof "_nwsaom_strcheck , wave1(c22) wave2(c23) samex(zs) egox(zs)" == 109
rcof "_nwsaom_strcheck , wave1(c22) wave2(c23) endow(altx:zs)" == 109
rcof "_nwsaom_strcheck , wave1(c22) wave2(c23) nodecov(zs)" == 109
rcof "_nwsaom_strcheck , wave1(c22) wave2(c23) ratecov(zs)" == 109

* samex() and two triadic same-type effects: the string fit is the fit of the numeric codes
foreach ef in samex samexoutact homxtranstrip {
	nwsaom, wave1(c22) wave2(c23) outdegree reciprocity `ef'(z) k0(30) k3(120) seed(2)
	matrix bn = e(b)
	nwsaom, wave1(c22) wave2(c23) outdegree reciprocity `ef'(zs) k0(30) k3(120) seed(2)
	matrix bs = e(b)
	assert mreldif(bn, bs) < 1e-10
	local cn : colnames bs
	assert strpos("`cn'", "zs")
	confirm string variable zs
	if "`ef'" == "samex" matrix bsame = bs
}
* nodematch() is the same effect as samex()
nwsaom, wave1(c22) wave2(c23) outdegree reciprocity nodematch(zs) k0(30) k3(120) seed(2)
assert mreldif(e(b), bsame) < 1e-10
* numeric effects: an error, and the data stay as they were
rcof "nwsaom, wave1(c22) wave2(c23) outdegree egox(zs) k0(30) k3(120) seed(2)" == 109
rcof "nwsaom, wave1(c22) wave2(c23) outdegree samex(zs) altx(zs) k0(30) k3(120) seed(2)" == 109
describe, varlist
assert "`r(varlist)'" == "`vars0'"
datasignature
assert "`r(datasignature)'" == "`sig0'"
assert "`: variable label zs'" == "group (string)"
di "PASS test_nwsaom_strcov"
