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
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
tempfile bd
save `bd'
forvalues w = 1/3 {
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
forvalues w = 1/3 {
	nwset, mat(S`w') directed name(sk`w') nooutput
}
merge 1:1 _n using `bd', nogen
local efs : environ EFFS
foreach ef of local efs {
	forvalues s = 1/2 {
		capture noisily nwsaom, waves(sk1 sk2 sk3) symmetric outdegree behavior(a1 a2 a3 : linear quadratic avalt) netbeh(`ef') k3(500) seed(`s')
		if _rc {
			di "SNB `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		di "SNB `ef' seed `s': b " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " rates " e(rate) " " e(rate_beh) " engine " e(engine)
	}
}
