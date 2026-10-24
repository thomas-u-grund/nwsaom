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
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
foreach ef in altx egox samex simx {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity endow(`ef':a1) creation(`ef':a1) k3(1000) seed(1)
	matrix b = e(b)
	mata: s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); p1 = SaomNetworkPatchEndowCreation(__nwsaom_last_M, __nwsaom_last_fntype, s1, __nwsaom_last_G1, __nwsaom_last_G2); p2 = SaomNetworkPatchEndowCreation(__nwsaom_last_M, __nwsaom_last_fntype, s2, __nwsaom_last_G2, __nwsaom_last_G3); st = p1 + p2; st_numscalar("__e3", st[3]); st_numscalar("__e4", st[4])
	di "COVEND `ef': est " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " targets (end, cre) " scalar(__e3) " " scalar(__e4)
}
