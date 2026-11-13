* test_nwsaom_mnfix: fix() with nwsaom multinet holds a named effect at its theta0() value (help said
* "not with multinet" while the multinet section and the code take fix())
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
set linesize 80
nwclear
set seed 1
forvalues w = 1/3 {
	nwrandom 15, prob(.15) name(fa`w')
	nwrandom 15, prob(.15) name(fb`w')
}
nwsaom multinet, net1(fa1 fa2 fa3) net2(fb1 fb2 fb3) eff1(outdegree reciprocity) eff2(outdegree) theta0(-1 0.5 -1) fix(net1_reciprocity) k0(10) k3(40) seed(1)
matrix b = e(b)
matrix V = e(V)
local c = colnumb(b, "net1_reciprocity")
assert `c' < .
assert reldif(b[1,`c'], .5) < 1e-8
assert V[`c',`c'] == 0
* the estimated effects have a variance
local d = colnumb(b, "net1_outdegree")
assert V[`d',`d'] > 0
di "PASS test_nwsaom_mnfix"
