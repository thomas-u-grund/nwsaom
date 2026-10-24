* nwsaom counterpart of dev/saom_rsiena_coev_netendow.R
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
import delimited "dev/saom_rsiena_coev_netendow_beh.csv", clear varnames(1) case(preserve)
mkmat a1 a2, matrix(AM)
forvalues w = 1/2 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/2 {
	nwset, mat(W`w') directed name(ce`w') nooutput
}
gen double alc1 = .
gen double alc2 = .
mata: st_store(., "alc1", st_matrix("AM")[., 1])
mata: st_store(., "alc2", st_matrix("AM")[., 2])
forvalues s = 1/3 {
	nwsaom, wave1(ce1) wave2(ce2) outdegree endow(reciprocity) creation(reciprocity) behavior(alc1 alc2) linear quadratic avalt k0(50) k3(1000) seed(`s')
	matrix b = e(b)
	di "COEV seed `s': " b[1,1] " " b[1,2] " " b[1,3] " | beh: " b[1,4] " " b[1,5] " " b[1,6] " rates " e(rate) " " e(rate_beh) " engine " e(engine)
}
