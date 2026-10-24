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
timer clear
forvalues s = 1/3 {
	timer on `s'
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtiesendow transtiescreation k3(1000) seed(`s')
	timer off `s'
	di "RESULT seed `s': rates " el(e(rates),1,1) " " el(e(rates),1,2) " | b: " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " el(e(b),1,4) " engine " e(engine)
}
timer list
