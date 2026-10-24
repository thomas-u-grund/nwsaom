* nwsaom counterpart of dev/saom_rsiena_dyadcov.R
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
import delimited "dev/saom_rsiena_dyadcov_m.csv", clear varnames(1) case(preserve)
mkmat v1-v50, matrix(DM)
import delimited "dev/saom_rsiena_dyadcov_mmiss.csv", clear varnames(1) case(preserve)
destring v1-v50, replace force
mkmat v1-v50, matrix(DMM)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(dc`w') nooutput
}
forvalues s = 1/3 {
	nwsaom, waves(dc1 dc2 dc3) outdegree reciprocity dyadcov(DM) k3(1000) seed(`s')
	di "NWDYAD X seed `s': " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " e(engine)
}
forvalues s = 1/3 {
	nwsaom, waves(dc1 dc2 dc3) outdegree reciprocity dyadcovrecip(DM) k3(1000) seed(`s')
	di "NWDYAD XRecip seed `s': " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " e(engine)
}
forvalues s = 1/3 {
	nwsaom, waves(dc1 dc2 dc3) outdegree reciprocity dyadcov(DMM) k3(1000) seed(`s')
	di "NWDYAD Xmiss seed `s': " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " e(engine)
}
