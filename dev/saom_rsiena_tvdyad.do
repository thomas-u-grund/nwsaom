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
import delimited "dev/saom_rsiena_dyadx_w.csv", clear varnames(1) case(preserve)
mkmat V1-V50, matrix(TW1)
import delimited "dev/saom_rsiena_dyadx_w2.csv", clear varnames(1) case(preserve)
mkmat V1-V50, matrix(TW2)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(dt`w') nooutput
}
local efs : environ EFFS
if "`efs'" == "" local efs "dyadcov"
foreach ef of local efs {
	forvalues s = 1/2 {
		if inlist("`ef'", "dyadcov", "dyadcovrecip") capture noisily nwsaom, waves(dt1 dt2 dt3) outdegree reciprocity tv`ef'(TW) k3(1000) seed(`s')
		else capture noisily nwsaom, waves(dt1 dt2 dt3) outdegree reciprocity tvdyadx(`ef':TW) k3(1000) seed(`s')
		if _rc {
			di "TD `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		di "TD `ef' seed `s': b " b[1,1] " " b[1,2] " " b[1,3] " engine " e(engine)
	}
}
