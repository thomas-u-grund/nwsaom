adopath ++ "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/plugdev8"
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
import delimited "dev/saom_rsiena_dyadcov_m.csv", clear varnames(1) case(preserve)
mkmat v1-v50, matrix(DM)
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
tempfile bd
save `bd'
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
merge 1:1 _n using `bd', nogen
local efs : environ EFFS
if "`efs'" == "" local efs "avaltw totaltw avinaltw totinaltw avwalt totwalt avwinalt totwinalt avsimw totsimw"
foreach ef of local efs {
	forvalues s = 1/2 {
		capture noisily nwsaom, waves(te1 te2 te3) outdegree reciprocity behavior(a1 a2 a3 : linear quadratic avalt) behw(`ef':DM) k3(1000) seed(`s')
		if _rc {
			di "BW `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		di "BW `ef' seed `s': b " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,6] " engine " e(engine)
	}
}
