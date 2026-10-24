* nwsaom counterpart of dev/saom_rsiena_crosscheck_covmiss.R (missing covariate values).
* Real RSiena (mean of 4 seeds): density -2.272, recip 2.416, altX -0.1246, egoX 0.0429, simX 0.7794
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
import delimited "dev/saom_rsiena_covmiss_cov.csv", clear varnames(1) case(preserve)
mkmat x, matrix(XM)
import delimited "dev/saom_rsiena_covmiss_wave1.csv", clear varnames(1)
mkmat v1-v50, matrix(W1)
import delimited "dev/saom_rsiena_covmiss_wave2.csv", clear varnames(1)
mkmat v1-v50, matrix(W2)
nwset, mat(W1) directed name(cmw1)
nwset, mat(W2) directed name(cmw2)
gen double x = .
mata: st_store(., "x", st_matrix("XM"))
replace x = . if x == -999
count if missing(x)
assert r(N) == 8
forvalues s = 1/4 {
	nwsaom, wave1(cmw1) wave2(cmw2) outdegree reciprocity nodeicov(x) nodeocov(x) simcov(x) k3(1500) seed(`s')
	matrix list e(b)
}
