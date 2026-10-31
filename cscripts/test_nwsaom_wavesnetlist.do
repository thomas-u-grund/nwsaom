* waves(netlist): wildcard patterns and ranges expand like the netlist of nwcommands, in the order of the networks
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
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity k0(20) k3(60) seed(1)
matrix B0 = e(b)
matrix V0 = e(V)
local n0 = colsof(e(rates))
foreach spec in "glasgow*" "glasgow1-glasgow3" "glasg*1 glas*2 glasgow3" "_all" {
	quietly nwsaom, waves(`spec') outdegree reciprocity k0(20) k3(60) seed(1)
	assert mreldif(e(b), B0) < 1e-12
	assert mreldif(e(V), V0) < 1e-12
	assert colsof(e(rates)) == `n0'
}
quietly nwsaom describe, waves(glasgow*)
assert rowsof(r(waves)) == 3
capture nwsaom, waves(glasgow1) outdegree k0(10) k3(20)
assert _rc != 0
capture nwsaom, waves(nosuch*) outdegree k0(10) k3(20)
assert _rc != 0
di "PASS: waves() takes a netlist"
