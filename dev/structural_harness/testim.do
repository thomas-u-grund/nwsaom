* usage: stata -e do testim.do <dir> <nseeds> <uncond or none>
args dir nseeds cond
do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
local mopt ""
capture confirm file "`dir'/cc.csv"
local hascc = (_rc == 0)
capture confirm file "`dir'/miss2.csv"
if _rc == 0 {
	import delimited "`dir'/miss2.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(M2)
	matrix Z0 = J(50, 50, 0)
	local mopt "missnet(Z0 M2 Z0)"
}
forvalues w = 1/3 {
	import delimited "`dir'/w`w'.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(S`w')
	clear
	nwset, mat(S`w') directed name(w`w') nooutput
}
if `hascc' {
	import delimited "`dir'/cc.csv", clear varnames(1)
	local mopt "`mopt' joinat(jn) leaveat(lv)"
}
local mdl : env MODEL
local kk3 : env K3
if "`kk3'" == "" local kk3 1000
local kk0 : env K0
if "`kk0'" == "" local kk0 50
local rcs ""
local nb 6
if "`mdl'" == "ratecov" {
	clear
	set obs 50
	gen double cv = mod(_n, 4) + 0.5
	local rcs "ratecov(cv)"
	local nb 7
}
tempname fh
file open `fh' using "`dir'/nws_est_`cond'.csv", write replace
forvalues s = 1/`nseeds' {
	nwsaom, `mopt' waves(w1 w2 w3) outdegree reciprocity transtrip cycle3 indegpopularity outactivity `rcs' k0(`kk0') k3(`kk3') seed(`s') `=cond("`cond'"=="uncond","unconditional","")'
	matrix b = e(b)
	local line ""
	forvalues j = 1/`nb' {
		local line "`line' `=b[1,`j']'"
	}
	file write `fh' "`line' `=e(tconv_max)'" _n
}
file close `fh'
