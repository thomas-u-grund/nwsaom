cscript

* The core package nwcommands is found through the environment variable NWCORE (path of the core checkout).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do

* nwsaom multiplex (own estimator, with theta01()/theta02()): one starting value per effect of the network. Up to
* 1.7.1 a vector of another length went into the engine and the fit stopped in phase 1 with Mata error 3301
* (subscript invalid), e.g. crprod with theta02(-1 0 0) (network B has no cross effect without crprodb), or for a
* network without cross effect theta01(-1 0 0); now r(198) with a message that names the number of effects.
nwuse `"`nwcore'/data/glasgow"', nwclear
local c "nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(glasgow2) netbwave2(glasgow3) k0(10) k3(60) seed(2)"

* 1. a vector of the wrong length
rcof "`c' crprod theta01(-1 0 0) theta02(-1 0 0)" == 198
rcof "`c' theta01(-1 0 0) theta02(-1 0)" == 198
rcof "`c' crprod theta01(-1 0) theta02(-1 0)" == 198
rcof "`c' crprodb theta01(-1 0) theta02(-1 0)" == 198
rcof "`c' theta01(-1 0 0 0)" == 198
rcof "`c' crprod crprodb theta01(-1 0 0) theta02(-1 0 0 0)" == 198
di "PASS multiplex: a start vector of the wrong length is refused (r(198))"

* 2. the message names the problem
tempfile lg
log using `"`lg'"', text replace name(mps)
capture noisily `c' crprod theta01(-1 0 0) theta02(-1 0 0)
log close mps
tempname fh
local seen 0
file open `fh' using `"`lg'"', read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`macval(line)'"', "theta02() has 3 values") > 0 local seen 1
	file read `fh' line
}
file close `fh'
assert `seen' == 1
di "PASS the message names theta02() and the number of values"

* 3. the right number of values is accepted (no cross effect: two values per network)
`c' theta01(-1 0) theta02(-1 0)
assert e(N) == . | e(N) < .
local cn : colnames e(b)
assert "`cn'" == "net1_outdegree net1_reciprocity net2_outdegree net2_reciprocity"
di "PASS multiplex with theta01() and theta02() of the right length"
di "ALL TESTS PASSED"
