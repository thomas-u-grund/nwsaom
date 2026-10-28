* two-mode targets: stata -e do tvtm.do <dir>
args dir
do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
set seed 1
forvalues w = 1/3 {
	import delimited "`dir'/w`w'.csv", clear varnames(nonames)
	mkmat v1-v20, matrix(S`w')
	clear
	nwset, mat(S`w') bipartite name(w`w') nooutput
}
global NWSAOM_TRACE 5
nwsaom, waves(w1 w2 w3) outdegree indegpopularity outactivity cycle4 k0(2) k3(10) seed(1)
matrix list __nwsaom_tr_target
matrix list __nwsaom_tr_rate
