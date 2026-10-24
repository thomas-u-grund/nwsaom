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
import delimited "dev/saom_rsiena_cov2miss_cov.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
foreach ef in absdiffx egoxaltx diffx higher egosqx altsqx samexrecip simrecipx {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity `ef'(am) k3(1000) seed(1)
	matrix b = e(b)
	mata: s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st = s1 + s2; st_numscalar("__st3", st[3])
	di "COV2M `ef': est " b[1,1] " " b[1,2] " " b[1,3] " stat " scalar(__st3) " engine " e(engine)
}
