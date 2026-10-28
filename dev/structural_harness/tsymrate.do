do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "../p0/sy0/w`w'.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(S`w')
	clear
	nwset, mat(S`w') directed name(w`w') nooutput
}
forvalues s=1/1 {
quietly nwsaom, waves(w1 w2 w3) symmetric symtype(joint) outdegree transties indegpopularity theta0(-1.2 0.1 0.3) fix(_all) k3(1000) seed(`s') unconditional
matrix bb = e(b)
matrix list e(tconv)
di "NWEST " bb[1,1] " " bb[1,2] " " bb[1,3] " RATES " e(rates)[1,1] " " e(rates)[1,2]
}
