* Regression test: nwsaom multinet with a behavior used to print debris before the table (the effect list "linear quadratic avalt"
* and three whitespace-only lines, the values returned by the Mata functions that add the terms). The data setup is that of test_nwsaom_mnbeh.
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
nwclear
* the data (siena07's s50 friendship waves, a second network, a non-directed network, alcohol, smoking): cscripts/mnbeh_ties.csv (net: 1 friendship, 2 second, 3 non-directed; wave; i; j)
* and cscripts/mnbeh_actors.csv (a1-a3 alcohol, s1 smoking, ma1-ma3 alcohol with missing values, m1-m3 their missing indicators)
import delimited "cscripts/mnbeh_ties.csv", clear varnames(1)
mata:
void mnbeh_mats() {
	real matrix ties, M, T
	string rowvector nm
	real scalar nt, w, r
	ties = st_data(., ("net", "wave", "i", "j"))
	nm = ("W", "B", "S")
	for (nt=1; nt<=3; nt++) for (w=1; w<=3; w++) {
		M = J(50, 50, 0)
		T = select(ties, (ties[., 1] :== nt) :& (ties[., 2] :== w))
		for (r=1; r<=rows(T); r++) M[T[r,3], T[r,4]] = 1
		st_matrix(nm[nt] + strofreal(w), M)
	}
}
mnbeh_mats()
end
import delimited "cscripts/mnbeh_actors.csv", clear varnames(1)
gen double xa = mod(_n * 7, 5)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(na`w') nooutput
	nwset, mat(B`w') directed name(nb`w') nooutput
	nwset, mat(S`w') undirected name(ns`w') nooutput
}


tempfile lg
log using `"`lg'"', text replace name(fixes1)
nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) eff1(outdegree reciprocity) eff2(outdegree reciprocity) ///
	beheff1(linear quadratic avalt) k0(3) k3(10) fix(net1_reciprocity net2_reciprocity beh_linear beh_quadratic) seed(1)
log close fixes1

tempname fh
local n = 0
local debris = 0
local blank = 0
local seen = 0
file open `fh' using `"`lg'"', read text
file read `fh' line
while r(eof) == 0 {
	if `seen' == 0 & strpos(`"`macval(line)'"', "Several co-evolving") > 0 local seen = 1
	if `seen' == 0 {
		if trim(`"`macval(line)'"') == "linear quadratic avalt" local debris = 1
		if trim(`"`macval(line)'"') == "" & `n' > 0 local blank = `blank' + 1
		local n = `n' + 1
	}
	file read `fh' line
}
file close `fh'
assert `seen' == 1
assert `debris' == 0
* the only blank lines before the table are the one after the command and, possibly, the break after the log header
assert `blank' <= 2
di as text "  PASS: nwsaom multinet prints no debris before the table (blank lines before the table: `blank')"
di as result "ALL TESTS PASSED"
