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
	nwsaom, waves(te1 te2 te3) outdegree reciprocity inpop outpop outactsqrt k3(1000) seed(`s')
	matrix b = e(b)
	di "DEGFX seed `s': " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,5] " engine " e(engine)
}
mata: s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); s1 + s2
forvalues s = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity inact k3(1000) seed(`s')
	matrix b = e(b)
	di "INACT seed `s': " b[1,1] " " b[1,2] " " b[1,3]
}
mata: s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); s1 + s2
forvalues s = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity inact k3(1000) seed(`s')
	matrix b = e(b)
	di "INACT seed `s': " b[1,1] " " b[1,2] " " b[1,3]
}
mata: s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); s1 + s2
