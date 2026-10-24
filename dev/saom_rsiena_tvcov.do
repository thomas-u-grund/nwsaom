* nwsaom counterpart of dev/saom_rsiena_tvcov.R: alcohol (waves 1-2) as a time-varying covariate
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
forvalues s = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip tvcov(a1 a2 a3) egox(a) altx(a) simx(a) samex(a) k3(1000) seed(`s')
	matrix b = e(b)
	di "TVCOV seed `s': " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,6] " " b[1,7]
}
* observed statistics: period 1 (end wave 2, covariate of wave 1) + period 2 (end wave 3, covariate of wave 2)
mata: SaomTVSync(__nwsaom_last_M, 1); s1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); SaomTVSync(__nwsaom_last_M, 2); s2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); s1 + s2
