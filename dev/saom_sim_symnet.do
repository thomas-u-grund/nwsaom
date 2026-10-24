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
import delimited "dev/saom_rsiena_symmulti_w1.csv", clear varnames(1)
mkmat v1-v50, matrix(W1)
nwset, mat(W1) directed name(sw1) nooutput
forvalues r = 1/20 {
	import delimited "dev/saom_sim_symnet_`r'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W2)
	capture nwdrop sw2
	nwset, mat(W2) directed name(sw2) nooutput
	capture nwsaom, wave1(sw1) wave2(sw2) symmetric symtype(joint) outdegree k0(50) k3(1000) seed(`r')
	if _rc == 0 di "NREP `r': rate " e(rate) " outdeg " el(e(b),1,1)
	else di "NREP `r' rc " _rc
}
