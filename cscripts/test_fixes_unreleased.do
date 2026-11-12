* Fixes of the unreleased version: estat mems after non-directed and two-mode fits, nwsaom bayes prior text, nwsaom simulate gen(),
* nwsaom multiplex detail and coefficient names, estat gof defaults after groups() with a behavior, nwsaom meta rates of wave1()/wave2() fits
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
set linesize 255

mata:
mata set matastrict off
void fx_data() {
	n = 40
	rseed(4242)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	A = ((A + A') :> 0)
	for (w=1; w<=2; w++) {
		st_matrix("__S" + strofreal(w), A)
		F = (runiform(n, n) :< 0.04)
		F = ((F + F') :> 0)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
	D = (runiform(n, n) :< 0.10)
	D = D - diag(diag(D))
	for (w=1; w<=2; w++) {
		st_matrix("__D" + strofreal(w), D)
		F = (runiform(n, n) :< 0.05)
		D = abs(D - F)
		D = D - diag(diag(D))
	}
	E = (runiform(n, n) :< 0.08)
	E = E - diag(diag(E))
	for (w=1; w<=2; w++) {
		st_matrix("__E" + strofreal(w), E)
		F = (runiform(n, n) :< 0.04)
		E = abs(E - F)
		E = E - diag(diag(E))
	}
	X = (runiform(24, 10) :< 0.15)
	for (w=1; w<=2; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(24, 10) :< 0.12)
		X = abs(X - F)
	}
}
fx_data()
end

* macro() programs for estat mems: the number of ties (one-mode: of the matrix), and checks of the network handed over
capture program drop fx_ties
program define fx_ties, rclass
	args netname
	_nwsyntax `netname', max(1)
	if "`directed'" != "$FX_DIRECTED" | "`is2mode'" != "$FX_IS2MODE" global FX_BADTYPE = $FX_BADTYPE + 1
	nwtomata `netname', mat(__fxm)
	mata: st_numscalar("__fx_asym", (rows(__fxm) == cols(__fxm)) ? sum(__fxm :!= __fxm') : 0)
	mata: st_numscalar("__fx_r", rows(__fxm))
	mata: st_numscalar("__fx_c", cols(__fxm))
	mata: st_numscalar("__fx_t", sum(__fxm))
	global FX_ASYM = $FX_ASYM + scalar(__fx_asym)
	global FX_DIM "`=scalar(__fx_r)'x`=scalar(__fx_c)'"
	global FX_SUM = $FX_SUM + scalar(__fx_t)
	global FX_N = $FX_N + 1
	return scalar stat = scalar(__fx_t)
end

* 1a. estat mems after a non-directed fit: simulated with the fit's model type (symmetric networks, declared undirected), numbers like estat simulate's
nwclear
clear
set obs 40
forvalues w = 1/2 {
	nwset, mat(__S`w') undirected name(sn`w') nooutput
}
nwsaom, wave1(sn1) wave2(sn2) outdegree transtriads k0(10) k3(100) seed(3)
assert "`e(symtype)'" != ""
global FX_BADTYPE 0
global FX_ASYM 0
global FX_SUM 0
global FX_N 0
global FX_DIRECTED "false"
global FX_IS2MODE "false"
estat mems, effect(transtriads) macro(fx_ties) nsim(40) seed(1) interval(1 1.000001) nodots
assert $FX_N == 81
assert $FX_ASYM == 0
assert $FX_BADTYPE == 0
assert "$FX_DIM" == "40x40"
* the first call of macro() is the trial call on the observed first wave
mata: st_numscalar("__fx_obs1", sum(st_matrix("__S1")))
local memsties = ($FX_SUM - scalar(__fx_obs1)) / 80
estat simulate, nsim(40) seed(2)
matrix SIM = r(sim)
matrix OBS = r(obs)
mata: st_numscalar("__fx_simties", mean(st_matrix("SIM")[., 3]))
di as text "estat mems mean ties: " `memsties' "   estat simulate mean ties: " scalar(__fx_simties) "   observed: " OBS[1,3]
* the macro sees the matrix of the undirected network (each tie counted twice), estat simulate counts the ties of the matrix too
assert abs(`memsties' / scalar(__fx_simties) - 1) < 0.1
assert abs(`memsties' / OBS[1,3] - 1) < 0.2
di "PASS estat mems after a non-directed fit"

* 1b. the same model fitted with a directed declaration of the symmetric waves gives the same type (they are tie-symmetric)
nwclear
forvalues w = 1/2 {
	nwset, mat(__S`w') directed name(sd`w') nooutput
}
nwsaom, wave1(sd1) wave2(sd2) outdegree k0(10) k3(60) seed(3)
assert "`e(symtype)'" != ""
global FX_ASYM 0
global FX_BADTYPE 0
global FX_N 0
estat mems, effect(outdegree) macro(fx_ties) nsim(20) seed(1) nodots
assert $FX_ASYM == 0 & $FX_BADTYPE == 0 & $FX_N == 41
di "PASS estat mems after a fit of tie-symmetric directed waves"

* 1c. estat mems after a two-mode fit: refused with a message (as estat gof)
nwclear
clear
forvalues w = 1/2 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
nwsaom, waves(tm1 tm2) outdegree k0(10) k3(60) seed(3)
assert e(twomode) == 1
capture noisily estat mems, effect(outdegree) macro(fx_ties) nsim(20) seed(1) nodots
assert _rc == 198
di "PASS estat mems refuses a two-mode fit"

* 1d. directed fit: unchanged (directed networks)
nwclear
clear
set obs 40
forvalues w = 1/2 {
	nwset, mat(__D`w') directed name(dn`w') nooutput
	nwset, mat(__E`w') directed name(en`w') nooutput
}
nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity k0(10) k3(60) seed(3)
assert "`e(symtype)'" == ""
global FX_BADTYPE 0
global FX_N 0
global FX_DIRECTED "true"
global FX_IS2MODE "false"
estat mems, effect(reciprocity) macro(fx_ties) nsim(20) seed(1) nodots
assert $FX_BADTYPE == 0 & $FX_N == 41
di "PASS estat mems after a directed fit"

* 3. nwsaom simulate: generate() may be abbreviated to gen()
nwsaom simulate, wave1(dn1) wave2(dn2) outdegree reciprocity theta(-2.3 2) rates(5) nsim(2) seed(3) gen(gs)
_nwsyntax gs_2_p1, max(1)
assert "`netname'" == "gs_2_p1"
nwsaom simulate, wave1(dn1) wave2(dn2) outdegree reciprocity theta(-2.3 2) rates(5) nsim(1) seed(3) genera(gt)
_nwsyntax gt_1_p1, max(1)
di "PASS nwsaom simulate gen()"

* 6. nwsaom meta, rates: the rate of wave1()/wave2() fits (scalar e(rate)) is combined as rate_period1
nwsaom, wave1(dn1) wave2(dn2) outdegree reciprocity k0(10) k3(60) seed(1)
local r1 = e(rate)
local s1 = e(rate_se)
estimates store fxm1
nwsaom, wave1(en1) wave2(en2) outdegree reciprocity k0(10) k3(60) seed(1)
local r2 = e(rate)
estimates store fxm2
nwsaom_meta fxm1 fxm2, rates notable
matrix TH = r(theta)
matrix SE = r(se)
local cn : colnames TH
assert "`cn'" == "outdegree reciprocity rate_period1"
assert reldif(TH[1,3], `r1') < 1e-12 & reldif(TH[2,3], `r2') < 1e-12 & reldif(SE[1,3], `s1') < 1e-12
di "PASS nwsaom meta, rates with wave1()/wave2() fits"

* 2. nwsaom bayes names its real prior options
nwsaom, waves(dn1 dn2) outdegree reciprocity k0(10) k3(60) seed(1)
tempfile lb
log using `"`lb'"', text replace name(fxbayes)
nwsaom bayes, nprewarm(2) nwarm(2) nmain(5) nrunmh(2) seed(3)
log close fxbayes
assert strpos("`e(priors)'", "priormeaneta") > 0 & strpos("`e(priors)'", "priorsigeta") > 0 & strpos("`e(priors)'", "ratepriorsd") > 0
tempname fh
local okline 0
local badline 0
file open `fh' using `"`lb'"', read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`macval(line)'"', "priorsigeta()") > 0 local okline 1
	if strpos(`"`macval(line)'"', " priorsd()") > 0 | strpos(`"`macval(line)'"', " priormean()") > 0 local badline 1
	file read `fh' line
}
file close `fh'
assert `okline' == 1 & `badline' == 0
di "PASS nwsaom bayes prior text"

* 4. nwsaom multiplex: detail works without theta01()/theta02(); the cross effects have the same names in both paths
tempfile lm
log using `"`lm'"', text replace name(fxmp)
nwsaom multiplex, netawave1(dn1) netawave2(dn2) netbwave1(en1) netbwave2(en2) crprod crprodb k0(10) k3(60) seed(2) detail
log close fxmp
local cn1 : colnames e(b)
local seen 0
file open `fh' using `"`lm'"', read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`macval(line)'"', "Convergence t-ratios (criterion: every") > 0 local seen 1
	file read `fh' line
}
file close `fh'
assert `seen' == 1
nwsaom multiplex, netawave1(dn1) netawave2(dn2) netbwave1(en1) netbwave2(en2) crprod crprodb theta01(-1 0 0) theta02(-1 0 0) k0(10) k3(60) seed(2)
local cn2 : colnames e(b)
local ct : colnames e(tconv)
di "`cn1'" _n "`cn2'"
assert "`cn1'" == "`cn2'"
assert strpos("`cn2'", "net1_x_crprod") > 0 & strpos("`cn2'", "net2_x_crprod") > 0
assert strpos("`ct'", "net1_x_crprod") > 0
di "PASS nwsaom multiplex detail and coefficient names"

* 5. estat gof after groups() with a behavior: behavior is a default statistic, as for a fit without groups
nwclear
import delimited "dev/saom_groups_actors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(G`w')
	restore
	nwset, mat(G`w') name(g`w') nooutput
}
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity behavior(alc1 alc2 alc3) linear quadratic k0(20) k3(100) seed(1) cores(1) unconditional
estat gof, nsim(10) seed(3) group(2)
assert r(p_behavior_g2) < .
assert r(p_outdegree_g2) < .
di "PASS estat gof after groups() with a behavior"

di "ALL PASS"
