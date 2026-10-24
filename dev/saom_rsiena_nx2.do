* Stata side of the covariate effects of protocol 50. MODE: A static directed, B tvcov directed, C behavior directed, D static symmetric, E tvcov symmetric, F behavior symmetric
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
local mode : environ MODE
local efs : environ EFFS
import delimited "_cov.csv", clear varnames(1)
tempfile cv
save `cv'
local tvf : environ TVCSV
if "`tvf'" == "" local tvf "_tv.csv"
import delimited "`tvf'", clear varnames(1)
tempfile tv
save `tv'
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
tempfile bd
save `bd'
local files "dev/saom_rsiena_netendow_w"
if inlist("`mode'", "D", "E", "F") local files "sym_w"
forvalues w = 1/3 {
	import delimited "`files'`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(nx`w') nooutput
}
use `cv', clear
merge 1:1 _n using `tv', nogen
merge 1:1 _n using `bd', nogen
local sym ""
if inlist("`mode'", "D", "E", "F") local sym "symmetric"
local rec "reciprocity"
if "`sym'" != "" local rec ""
foreach ef of local efs {
	forvalues s = 1/2 {
		if inlist("`mode'", "A", "D") capture noisily nwsaom, waves(nx1 nx2 nx3) `sym' outdegree `rec' netx(`ef':age) k3(500) seed(`s')
		if inlist("`mode'", "B", "E") capture noisily nwsaom, waves(nx1 nx2 nx3) `sym' outdegree `rec' tvcov(v1 v2) netx(`ef':v) k3(500) seed(`s')
		if inlist("`mode'", "C", "F") capture noisily nwsaom, waves(nx1 nx2 nx3) `sym' outdegree `rec' behavior(a1 a2 a3 : linear quadratic avalt) netbeh(`ef') k3(500) seed(`s')
		if _rc {
			di "NX2 `mode' `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		local row ""
		forvalues c = 1/`=colsof(b)' {
			local row "`row' `=string(b[1,`c'], "%7.3f")'"
		}
		di "NX2 `mode' `ef' seed `s': b `row' engine " e(engine)
	}
}
