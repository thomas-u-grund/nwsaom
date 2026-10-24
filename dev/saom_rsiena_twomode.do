* nwsaom counterpart of dev/saom_rsiena_twomode_sim.R (40 actors x 20 events, 3 waves; RSiena's targets and estimates are printed there)

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
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_twomode_cvA.csv", clear varnames(1)
mkmat ega, matrix(CA)
import delimited "dev/saom_twomode_cvB.csv", clear varnames(1)
mkmat altb, matrix(CB)
mata: CAm = st_matrix("CA"); CBm = st_matrix("CB")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
* node-level covariates live on the rows of the node dataset (one row per node, _nwmode = 1: columns of the
* matrix = events, 2: rows of the matrix = actors), in the nodes' order
gen double ega = .
gen double altb = .
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); ie = selectindex(md :== "1"); st_store(ia, "ega", CAm); st_store(ie, "altb", CBm)
forvalues s = 1/1 {
	nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 nodeocov(ega) nodeicov(altb) k3(1000) seed(`s')
	matrix b = e(b)
	di "TWOMODE seed `s': " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,6] " engine " e(engine)
}
* observed statistics (sum over the two periods, end waves) against RSiena's targets 529 12990 2399.29 4359 103.142 71.484
* (RSiena order: density cycle4 inPopSqrt outAct egoX altX)
mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st1 + st2
