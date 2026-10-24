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
	nwset, mat(W`w') directed name(dg`w') nooutput
}
local efs : environ EFFS
foreach ef of local efs {
	forvalues s = 1/2 {
		capture noisily nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity ownx(`ef') k3(1000) seed(`s')
		if _rc {
			di "DG `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		di "DG `ef' seed `s': b " b[1,1] " " b[1,2] " " b[1,3] " engine " e(engine)
	}
}
