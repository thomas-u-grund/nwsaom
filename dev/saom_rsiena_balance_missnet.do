* nwsaom counterpart of dev/saom_rsiena_balance_missnet.R
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
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_balmiss_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	import delimited "dev/saom_rsiena_balmiss_m`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(M`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(bm`w') nooutput
}
forvalues s = 1/3 {
	nwsaom, waves(bm1 bm2 bm3) outdegree reciprocity endow(balance) creation(balance) missnet(M1 M2 M3) k3(1000) seed(`s')
	di "BALMISS seed `s': rates " el(e(rates),1,1) " " el(e(rates),1,2) " | b: " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " el(e(b),1,4) " engine " e(engine)
}
