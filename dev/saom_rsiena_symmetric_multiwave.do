* nwsaom counterpart of dev/saom_rsiena_symmetric_multiwave.R (3 symmetrized s50 waves, BJOINT)
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
	import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(sm`w') nooutput
}
timer clear
forvalues s = 1/2 {
	timer on 1
	nwsaom, waves(sm1 sm2 sm3) symmetric symtype(joint) outdegree transties k3(1000) seed(`s')
	timer off 1
	matrix list e(b)
	matrix list e(rates)
}
timer list
