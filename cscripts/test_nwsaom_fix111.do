* nwsaom 1.1.1 fixes: describe for a two-mode network, estat simulate / nwsaom simulate after a two-mode fit, nwsaom meta with rates and named result matrices,
* the reciprocity refusal without the extra "invalid syntax" line.
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

* ---- 1. describe, two-mode: 18 actors x 14 events
nwclear
mata:
mata set matastrict off
void fx_data() {
	na = 18
	ne = 14
	rseed(2468)
	X = (runiform(na, ne) :< 0.25)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.10)
		X = abs(X - F)
	}
}
end
mata: fx_data()
clear
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(w`w') nooutput
}
nwsaom describe, waves(w1 w2 w3)
assert r(twomode) == 1 & r(n_actors) == 18 & r(n_events) == 14
matrix Wd = r(waves)
matrix Pd = r(periods)
forvalues w = 1/3 {
	matrix T = __T`w'
	local s = 0
	forvalues i = 1/18 {
		forvalues j = 1/14 {
			local s = `s' + (T[`i', `j'] != 0)
		}
	}
	assert Wd[`w', 1] == `s'
	assert reldif(Wd[`w', 2], `s' / 252) < 1e-12 & reldif(Wd[`w', 3], `s' / 18) < 1e-12
}
* kept + dissolved = ties of the first wave of the period
assert Pd[1, 1] + Pd[1, 3] == Wd[1, 1] & Pd[1, 1] + Pd[1, 2] == Wd[2, 1]
nwsaom describe, waves(w1 w2 w3) actormode(1)
assert r(n_actors) == 14 & r(n_events) == 18 & el(r(waves), 1, 1) == Wd[1, 1]
di as text "describe two-mode PASS"

* ---- 2. estat simulate / nwsaom simulate after / for a two-mode fit
nwsaom, waves(w1 w2 w3) outdegree indegpopularity k0(30) k3(150) seed(3)
assert e(twomode) == 1
estat simulate, nsim(6) seed(5) generate(fxs)
matrix S = r(sim)
matrix O = r(obs)
assert rowsof(S) == 12 & !missing(S[1, 3]) & O[2, 3] == Wd[3, 1]
* the simulated networks are two-mode actors x events networks: 18 + 14 = 32 nodes (read through nwtomata, which does not
* depend on how the core names its network registry)
nwtomata fxs_1_p1, mat(__fxm)
mata: st_numscalar("__fx_nn", rows(__fxm))
assert scalar(__fx_nn) == 32
nwsaom simulate, waves(w1 w2 w3) outdegree indegpopularity theta(-1 0.3) rates(5 5) nsim(4) seed(2)
assert r(nsim) == 4
* a matrix of the wrong shape as theta() gives a message, not a conformability error
mata: st_matrix("__fxbad", J(32, 32, 0))
capture noisily estat simulate, theta(__fxbad) nsim(1)
assert _rc == 198
* different rates per period needed
capture noisily nwsaom simulate, waves(w1 w2) outdegree indegpopularity theta(-1 0.3) rates(5 5) nsim(2)
assert _rc == 198
di as text "simulate two-mode PASS"

* ---- 3./4. meta with rates, names of the result matrices
mata:
void fx_one(real scalar g) {
	n = 30
	rseed(2000 + g)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	st_matrix("__MA", A)
	for (k=2; k<=3; k++) {
		F = (runiform(n, n) :< 0.06)
		A = abs(A - F)
		A = A - diag(diag(A))
		st_matrix("__M" + (k == 2 ? "B" : "C"), A)
	}
}
end
forvalues g = 1/3 {
	nwclear
	mata: fx_one(`g')
	nwset, mat(__MA) directed name(ma) nooutput
	nwset, mat(__MB) directed name(mb) nooutput
	nwset, mat(__MC) directed name(mc) nooutput
	nwsaom, waves(ma mb mc) outdegree reciprocity k0(20) k3(60) seed(`g')
	estimates store c`g'
}
nwsaom meta c1 c2 c3, notable
matrix Th0 = r(theta)
assert colsof(Th0) == 2 & rowsof(r(meta)) == 2
nwsaom meta c1 c2 c3, rates notable
matrix M = r(meta)
matrix Th = r(theta)
matrix Se = r(se)
assert rowsof(M) == 4 & colsof(Th) == 4 & colsof(Se) == 4
* the rates are really combined: three groups with a standard error each
assert M[3, 1] == 3 & M[4, 1] == 3 & !missing(M[3, 4], M[3, 5], M[4, 4])
assert !missing(Se[1, 3], Se[3, 4])
local rn : rownames Th
local cn : colnames Th
local cs : colnames Se
local rs : rownames Se
assert "`rn'" == "c1 c2 c3" & "`rs'" == "c1 c2 c3"
assert "`cn'" == "outdegree reciprocity rate_period1 rate_period2" & "`cs'" == "`cn'"
local mrn : rownames M
assert "`mrn'" == "`cn'"
di as text "meta rates and names PASS"

* ---- 6. the reciprocity refusal prints no extra line
mata:
void fx_sym() {
	n = 30
	rseed(7)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	A = ((A + A') :> 0)
	st_matrix("__UA", A)
	F = (runiform(n, n) :< 0.05)
	F = ((F + F') :> 0)
	A = abs(A - F)
	A = A - diag(diag(A))
	st_matrix("__UB", A)
}
end
mata: fx_sym()
nwset, mat(__UA) undirected name(ua) nooutput
nwset, mat(__UB) undirected name(ub) nooutput
tempname fh
capture log close fxlog
log using "fx_recip.log", text replace name(fxlog)
capture noisily nwsaom, waves(ua ub) outdegree reciprocity k0(20) k3(60) seed(1)
local rc = _rc
log close fxlog
assert `rc' == 198
local found 0
local bad 0
file open `fh' using "fx_recip.log", read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "not meaningful under") local found 1
	if strpos(`"`line'"', "invalid syntax") local bad 1
	file read `fh' line
}
file close `fh'
erase "fx_recip.log"
assert `found' == 1 & `bad' == 0
di as text "reciprocity refusal PASS"
