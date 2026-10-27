* usage: stata -e do tv.do <dir>   (dir with w1.csv..w3.csv)
args dir
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
set seed 1
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
local spec "outdegree reciprocity transtrip cycle3 indegpopularity outactivity"
if "`mdl'" == "endow" local spec "outdegree endow(reciprocity) creation(reciprocity) transtrip"
global NWSAOM_TRACE 5
nwsaom, `mopt' waves(w1 w2 w3) `spec' k0(2) k3(10) seed(1)
matrix list e(b)
matrix list __nwsaom_tr_target
matrix list __nwsaom_tr_rate
clear
svmat __nwsaom_tr_target
export delimited using "`dir'/nws_target.csv", replace novarnames
clear
svmat __nwsaom_tr_rate
export delimited using "`dir'/nws_rate.csv", replace novarnames
