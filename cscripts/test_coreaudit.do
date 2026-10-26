cscript

* Core 3.6.0 audit: the Valued flag is set when a network is created, no longer worked out from the values.
* nwsaom judges its wave networks by their tie values: ties that are all 1 are accepted whatever the flag says (RSiena
* reads a 0/1 matrix), any other tie value stops the command (RSiena: "entries in networks must be 0, 1, 10 or 11"),
* also for a network that is not declared valued. Two-mode networks keep their flag through nwdropnodes.

local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
quietly do unw_saom.do

nwclear
clear
set seed 1234
set obs 400
gen int a = ceil(_n/20)
gen int b = mod(_n-1,20)+1
drop if a==b
gen byte x1 = runiform()<.15
gen byte x2 = x1
replace x2 = runiform()<.15 if runiform()<.25
gen double val = 1 + floor(runiform()*4)
gen double sh = .1+.9*runiform()
gen double one = 1
foreach t in 1 2 {
	foreach v in "" one val sh {
		preserve
		keep if x`t'
		nwfromedge a b `v', name(n`v'`t') directed
		restore
	}
}
* the networks made without and with a value variable hold the same ties
foreach n in none1 nval1 nsh1 {
	_nwsyntax `n', max(1)
	mata: st_numscalar("__cnt", `netobj'->get_arcs_count())
	_nwsyntax n1, max(1)
	mata: st_numscalar("__cnt0", `netobj'->get_arcs_count())
	assert scalar(__cnt) == scalar(__cnt0)
}
* the flags as the core sets them (declaration): a value variable makes the network valued, also when all values are 1
_nwsyntax n1, max(1)
assert "`valued'" == "false"
_nwsyntax none1, max(1)
assert "`valued'" == "true"
_nwsyntax nsh1, max(1)
assert "`valued'" == "true"

local opts outdegree reciprocity k0(30) k3(100) seed(3)
nwsaom, wave1(n1) wave2(n2) `opts'
matrix B0 = e(b)
assert colsof(B0) == 2

* 1. declared valued, every value 1: estimated, identical to the binary network (independent expectation: the same graph)
nwsaom, wave1(none1) wave2(none2) `opts'
matrix B1 = e(b)
assert mreldif(B0, B1) < 1e-12
di as text "  PASS: valued flag with all values 1 is estimated like the binary network"

* 2. valued with values 1-4 and with shares: refused (error 198)
capture nwsaom, wave1(nval1) wave2(nval2) `opts'
assert _rc == 198
capture nwsaom, wave1(nsh1) wave2(nsh2) `opts'
assert _rc == 198
* one wave valued with shares, the other binary
capture nwsaom, wave1(n1) wave2(nsh2) `opts'
assert _rc == 198
di as text "  PASS: tie values other than 1 are refused"

* 3. not declared valued but holding values (a network saved by an earlier release): refused, not turned into ties
nwduplicate nsh1, name(f1)
nwduplicate nsh2, name(f2)
nwname f1, newvalued(false)
nwname f2, newvalued(false)
_nwsyntax f1, max(1)
assert "`valued'" == "false"
capture nwsaom, wave1(f1) wave2(f2) `opts'
assert _rc == 198
nwduplicate nval1, name(g1)
nwduplicate nval2, name(g2)
nwname g1, newvalued(false)
nwname g2, newvalued(false)
capture nwsaom, wave1(g1) wave2(g2) `opts'
assert _rc == 198
* round trip through nwsave / nwuse keeps the declaration and the refusal
tempfile fs
nwsave "`fs'", replace
nwclear
nwuse "`fs'"
_nwsyntax f1, max(1)
assert "`valued'" == "false"
capture nwsaom, wave1(f1) wave2(f2) `opts'
assert _rc == 198
_nwsyntax none1, max(1)
assert "`valued'" == "true"
di as text "  PASS: values other than 0/1 in a network not declared valued are refused"

* 4. several networks: the same rule
capture nwsaom multiplex, netawave1(n1) netawave2(n2) netbwave1(nval1) netbwave2(nval2) k0(30) k3(100) seed(3)
assert _rc == 198
capture nwsaom multinet, net1(n1 n2) net2(nsh1 nsh2) eff1(outdegree reciprocity) eff2(outdegree reciprocity) k0(30) k3(100) seed(3)
assert _rc == 198
nwsaom multinet, net1(n1 n2) net2(none1 none2) eff1(outdegree reciprocity) eff2(outdegree reciprocity) k0(30) k3(100) seed(3)
assert colsof(e(b)) == 4
di as text "  PASS: multiplex / multinet apply the same rule"

* 5. two-mode: declared valued with all ties 1 is estimated; with other values refused; nwdropnodes keeps the flag
nwclear
mata:
mata set matastrict off
void tm_data() {
	na = 24
	ne = 10
	rseed(2468)
	X = (runiform(na, ne) :< 0.15)
	for (w=1; w<=2; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.12)
		X = abs(X - F)
	}
}
tm_data()
end
forvalues w = 1/2 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
local topts outdegree indegpopularity k0(30) k3(100) seed(3)
nwsaom, wave1(tm1) wave2(tm2) `topts'
matrix T0 = e(b)
assert e(twomode) == 1 & e(n_actors) == 24 & e(n_events) == 10
forvalues w = 1/2 {
	nwduplicate tm`w', name(tv`w')
	nwname tv`w', newvalued(true)
}
_nwsyntax tv1, max(1)
assert "`valued'" == "true" & "`is2mode'" == "true"
nwsaom, wave1(tv1) wave2(tv2) `topts'
assert mreldif(T0, e(b)) < 1e-12
* a tie of value 0.5 in a two-mode wave
mata: M = st_matrix("__T2"); M[1,1] = 0.5; st_matrix("__T2f", M)
nwset, mat(__T2f) bipartite name(tm2f) nooutput
capture nwsaom, wave1(tm1) wave2(tm2f) `topts'
assert _rc == 198
* nwdropnodes keeps the flag, the modes and the labels: 4 of the 10 events dropped (nodes 1-4 are the events)
forvalues w = 1/2 {
	nwduplicate tm`w', name(kt`w')
	nwdropnodes kt`w', nodes(1/4)
}
_nwsyntax kt1, max(1)
assert "`is2mode'" == "true" & `nodes' == 30
nwsaom, wave1(kt1) wave2(kt2) `topts'
assert e(twomode) == 1 & e(n_actors) == 24 & e(n_events) == 6
di as text "  PASS: two-mode waves: declared valued with ties 1 accepted, other values refused, nwdropnodes keeps the flag"
di as text "test_coreaudit (nwsaom) PASS"
