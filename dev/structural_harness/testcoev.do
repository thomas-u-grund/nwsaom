args dir nseeds
do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "`dir'/w`w'.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(S`w')
	clear
	nwset, mat(S`w') directed name(w`w') nooutput
}
import delimited "`dir'/beh.csv", clear varnames(nonames)
rename (v1 v2 v3) (a1 a2 a3)
forvalues s = 1/`nseeds' {
	quietly nwsaom, waves(w1 w2 w3) behavior(a1 a2 a3) outdegree reciprocity transtrip behaltx behsim linear quadratic avalt seed(`s')
	matrix b = e(b)
	matrix r = e(rates)
	matrix rb = e(rates_beh)
	di "EST " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,6] " " b[1,7] " " b[1,8] " RATES " r[1,1] " " r[1,2] " BR " rb[1,1] " " rb[1,2]
}
matrix list e(b)
