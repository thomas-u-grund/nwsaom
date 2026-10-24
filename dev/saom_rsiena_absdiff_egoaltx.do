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
mkmat a1, matrix(AM)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(cx`w') nooutput
}
gen double alc = .
mata: st_store(., "alc", st_matrix("AM")[., 1])
foreach ef in absdiffx egoxaltx {
	forvalues s = 1/3 {
		nwsaom, waves(cx1 cx2 cx3) outdegree reciprocity `ef'(alc) k3(1000) seed(`s')
		di "NWCOVX `ef' seed `s': " el(e(b),1,1) " " el(e(b),1,2) " " el(e(b),1,3) " " e(engine)
	}
}
