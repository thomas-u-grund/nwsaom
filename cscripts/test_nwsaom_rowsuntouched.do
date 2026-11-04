* A model that names no variable of the data must not touch the data in memory: fitting a network with other node names
* (one class of a stacked data set, say) used to extend the data by its nodes and re-sort them
cscript
adopath ++ "."
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do

nwclear
nwwebuse glasgow, nwclear
generate long rowmark = _n

* two waves of a small network whose nodes have names the data do not list
set seed 4711
mata: Z = (runiform(20, 20) :< 0.12); _diag(Z, 0)
mata: st_matrix("Z1", Z); Z2 = Z; for (i=1; i<=20; i++) for (j=1; j<=20; j++) if (runiform(1,1) < 0.05) Z2[i,j] = 1 - Z2[i,j]; _diag(Z2, 0); st_matrix("Z2", Z2)
mata: NN = "z" :+ strofreal(1..20)
nwset, mat(Z1) directed name(zw1) nodenames(NN) nooutput
nwset, mat(Z2) directed name(zw2) nodenames(NN) nooutput
* (declaring a network extends the data by its nodes; that is the state before the fit)
* put the glasgow network back first, so that the data list its nodes in their own order
nwsaom describe, waves(glasgow1 glasgow2)
sort _nwinclude rowmark
replace rowmark = _n
local n0 = _N
quietly summarize rowmark
local s0 = r(sum)

quietly nwsaom, waves(zw1 zw2) outdegree reciprocity seed(1)
assert _N == `n0'
quietly summarize rowmark
assert r(sum) == `s0'
assert rowmark == _n
display "PASS: a model without data variables leaves the data in memory as they are"

* the same model with a data variable still aligns the rows (existing behaviour)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity egox(rowmark) seed(1)
assert _N == `n0'
display "PASS: a model with a data variable is fitted on the aligned data"
