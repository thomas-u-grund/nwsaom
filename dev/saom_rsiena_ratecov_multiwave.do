* nwsaom counterpart of dev/saom_rsiena_ratecov_multiwave.R
* The core package nwcommands is found through the environment variable NWCORE (path of the core checkout).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
* (not needed here: unw_ergm.do belongs to another package)
do unw_saom.do
nwclear
import delimited "dev/saom_rsiena_ratecov_mw_cov.csv", clear varnames(1) case(preserve)
mkmat x, matrix(XM)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(rc`w') nooutput
}
gen double alc = .
mata: st_store(., "alc", st_matrix("XM"))
quietly nwsaom, waves(rc1 rc2 rc3) outdegree reciprocity ratecov(alc) k3(1000) seed(1)
ereturn list
matrix list e(ratecoefs)
forvalues s = 1/3 {
	nwsaom, waves(rc1 rc2 rc3) outdegree reciprocity ratecov(alc) k3(1000) seed(`s')
	di "RESULT seed `s': " el(e(b),1,1) " " el(e(b),1,2) " rates " el(e(rates),1,1) "/" el(e(rates),1,2) " ratecoef " e(ratecoef)
}
