* nwsaom endow/creation of balance vs RSiena (dev/saom_rsiena_balance_endow.R): targets -155.47 / 185.89
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
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
forvalues s = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity endow(balance) creation(balance) k3(1000) seed(`s')
	di "BAL seed `s': rates " el(e(rates),1,1) " " el(e(rates),1,2) " | b: " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " el(e(b),1,4) " engine " e(engine)
}
