* nwsaom counterpart of dev/saom_rsiena_multibeh.R (two co-evolving behaviors: alcohol and smoking)
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
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip behavior(a1 a2 a3 : linear quadratic avalt | s1 s2 s3 : linear quadratic avalt) k3(1000) seed(`s')
	matrix bb = e(b)
	matrix rr = e(rates)
	matrix rb = e(rates_beh)
	di "MBADO seed `s': net " bb[1,1] " " bb[1,2] " " bb[1,3] " | alc " bb[1,4] " " bb[1,5] " " bb[1,6] " | smk " bb[1,7] " " bb[1,8] " " bb[1,9] " | rates net " rr[1,1] " " rr[1,2] " alc " rb[1,1] " " rb[2,1] " smk " rb[2,1] " " rb[2,2] " engine " e(engine)
}
