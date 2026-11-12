* Simulation after a fit (estat simulate / gof / mems): two-mode networks of any size (the structural dyads of the two-mode embedding
* reach the plugin through the data, not the option string), and non-directed fits with waves() or a behavior (e(symtype), per-actor
* rates e(rates_actor) / e(rate_actor): the simulated networks are symmetric)
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

mata: st_numscalar("__fx_pv", SaomNativePluginVersion())
assert scalar(__fx_pv) >= 155

mata:
mata set matastrict off
void fx_tm(real scalar na, real scalar ne, real scalar sd) {
	rseed(sd)
	X = (runiform(na, ne) :< 0.15)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.10)
		X = abs(X - F)
	}
}
void fx_sn() {
	n = 40
	rseed(4242)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	A = ((A + A') :> 0)
	for (w=1; w<=3; w++) {
		st_matrix("__S" + strofreal(w), A)
		F = (runiform(n, n) :< 0.04)
		F = ((F + F') :> 0)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
// asymmetric cells of a network; for a two-mode network (saved as actors x events, nwtomata gives the symmetric square form):
// the difference to the number of ties of the whole simulated embedding, which is positive when the simulation made ties
// that are not actor -> event (they are not in the saved network)
real scalar fx_bad(string scalar nm, real scalar tm) {
	stata("nwtomata " + nm + ", mat(__fxm)")
	M = *findexternal("__fxm")
	if (!tm) return(sum(M :!= M'))
	return(abs(sum(M) / 2 - tm))
}
end

* 1. two-mode networks: 24 x 10 (failed with "options too long" before) and 60 x 30
foreach sz in "24 10" "60 30" {
	local na : word 1 of `sz'
	local ne : word 2 of `sz'
	nwclear
	clear
	mata: fx_tm(`na', `ne', 8642)
	forvalues w = 1/3 {
		nwset, mat(__T`w') bipartite name(tm`w') nooutput
	}
	nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity k0(10) k3(60) seed(3)
	assert e(twomode) == 1
	estat simulate, nsim(4) seed(5) generate(ts)
	matrix S = r(sim)
	matrix O = r(obs)
	assert rowsof(S) == 8
	forvalues pd = 1/2 {
		mata: st_numscalar("__fx_m", mean(select(st_matrix("S")[., 3], st_matrix("S")[., 2] :== `pd')))
		di as text "two-mode `na' x `ne', period `pd': simulated ties " scalar(__fx_m) ", observed " O[`pd', 3]
		assert abs(scalar(__fx_m) / O[`pd', 3] - 1) < 0.25
	}
	forvalues s = 1/4 {
		forvalues pd = 1/2 {
			mata: st_numscalar("__fx_b", fx_bad("ts_`s'_p`pd'", st_matrix("S")[(`s' - 1) * 2 + `pd', 3]))
			assert scalar(__fx_b) == 0
		}
	}
	nwsaom simulate, waves(tm1 tm2 tm3) outdegree indegpopularity theta(-1 0.1) rates(3 3) nsim(2) seed(2)
	assert r(nsim) == 2
}
di "PASS two-mode simulation, 24 x 10 and 60 x 30"

* 2. non-directed waves() fits: e(symtype), per-actor rates, symmetric simulated networks
nwclear
clear
set obs 40
mata: fx_sn()
forvalues w = 1/3 {
	nwset, mat(__S`w') undirected name(sn`w') nooutput
}
foreach st in forcing joint {
	nwsaom, waves(sn1 sn2 sn3) outdegree transtriads symtype(`st') k0(10) k3(100) seed(3)
	assert "`e(symtype)'" == "`st'"
	matrix RA = e(rates_actor)
	matrix R = e(rates)
	assert colsof(RA) == 2
	if "`st'" == "forcing" assert mreldif(RA, R) < 1e-12
	* conditional estimation, pairwise type: RSiena's rate = per-actor rate / (actors - 1)
	else assert reldif(RA[1,1] / 39, R[1,1]) < 1e-10 & reldif(RA[1,2] / 39, R[1,2]) < 1e-10
	estat simulate, nsim(5) seed(1) generate(ss)
	matrix S = r(sim)
	matrix O = r(obs)
	forvalues pd = 1/2 {
		mata: st_numscalar("__fx_m", mean(select(st_matrix("S")[., 3], st_matrix("S")[., 2] :== `pd')))
		di as text "`st', period `pd': simulated ties " scalar(__fx_m) ", observed " O[`pd', 3]
		assert abs(scalar(__fx_m) / O[`pd', 3] - 1) < 0.2
		forvalues s = 1/5 {
			mata: st_numscalar("__fx_b", fx_bad("ss_`s'_p`pd'", 0))
			assert scalar(__fx_b) == 0
		}
	}
	estat gof, nsim(10) seed(2)
	assert r(p_outdegree) < . & r(p_geodesic) < .
	nwdrop ss_*
}
di "PASS non-directed fits with waves(): estat simulate and gof"

* estat mems after a two-wave waves() non-directed fit: symmetric, undirected networks for macro()
capture program drop fx_asym
program define fx_asym, rclass
	args netname
	_nwsyntax `netname', max(1)
	if "`directed'" != "false" global FX_BAD = $FX_BAD + 1
	nwtomata `netname', mat(__fxm)
	mata: st_numscalar("__fx_a", sum(__fxm :!= __fxm'))
	mata: st_numscalar("__fx_t", sum(__fxm))
	global FX_BAD = $FX_BAD + scalar(__fx_a)
	global FX_SUM = $FX_SUM + scalar(__fx_t)
	return scalar stat = scalar(__fx_t)
end
nwsaom, waves(sn1 sn2) outdegree transtriads symtype(joint) k0(10) k3(100) seed(3)
assert "`e(symtype)'" == "joint"
global FX_BAD 0
global FX_SUM 0
estat mems, effect(transtriads) macro(fx_asym) nsim(20) seed(1) interval(1 1.000001) nodots
assert $FX_BAD == 0
mata: st_numscalar("__fx_o1", sum(st_matrix("__S1")))
mata: st_numscalar("__fx_o2", sum(st_matrix("__S2")))
local memsties = ($FX_SUM - scalar(__fx_o1)) / 40
di as text "estat mems mean ties: " `memsties' ", observed: " scalar(__fx_o2)
assert abs(`memsties' / scalar(__fx_o2) - 1) < 0.2
di "PASS estat mems after a non-directed waves() fit"

* the two-wave fit with wave1()/wave2() keeps its scalar results
nwsaom, wave1(sn1) wave2(sn2) outdegree transtriads symtype(joint) k0(10) k3(100) seed(3)
assert "`e(symtype)'" == "joint" & e(rate_actor) < .
capture confirm matrix e(rates_actor)
assert _rc != 0

* 3. a non-directed network with a co-evolving behavior (waves() and wave1()/wave2())
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
nwsaom, waves(sn1 sn2 sn3) symmetric outdegree behavior(z1 z2 z3 : linear) k0(10) k3(60) seed(3)
assert "`e(symtype)'" == "forcing"
confirm matrix e(rates_actor)
estat simulate, nsim(3) seed(1) generate(cs)
matrix S = r(sim)
matrix O = r(obs)
forvalues pd = 1/2 {
	mata: st_numscalar("__fx_m", mean(select(st_matrix("S")[., 3], st_matrix("S")[., 2] :== `pd')))
	di as text "co-evolution, period `pd': simulated ties " scalar(__fx_m) ", observed " O[`pd', 3]
	assert abs(scalar(__fx_m) / O[`pd', 3] - 1) < 0.25
	forvalues s = 1/3 {
		mata: st_numscalar("__fx_b", fx_bad("cs_`s'_p`pd'", 0))
		assert scalar(__fx_b) == 0
	}
}
estat gof, nsim(10) seed(2)
assert r(p_behavior) < .
nwsaom, wave1(sn2) wave2(sn3) symmetric outdegree behavior(z2 z3 : linear) k0(10) k3(60) seed(3)
assert "`e(symtype)'" == "forcing" & e(rate_actor) < .
estat simulate, nsim(3) seed(1) generate(c2)
forvalues s = 1/3 {
	mata: st_numscalar("__fx_b", fx_bad("c2_`s'_p1", 0))
	assert scalar(__fx_b) == 0
}
di "PASS non-directed fits with a behavior"

* 4. estat simulate, rates() after a pairwise-type non-directed fit: rates() is on the scale of e(rates)/e(rate); the fit's own rates
*    give the same simulations as no rates() (same seed)
capture program drop fx_samerates
program define fx_samerates
	tempname A B
	estat simulate, nsim(4) seed(11)
	matrix `A' = r(sim)
	capture confirm matrix e(rates)
	if _rc == 0 {
		local rl ""
		forvalues j = 1/`=colsof(e(rates))' {
			local rl "`rl' `=strofreal(el(e(rates), 1, `j'), "%21.0g")'"
		}
	}
	else local rl = strofreal(e(rate), "%21.0g")
	estat simulate, nsim(4) seed(11) rates(`rl')
	matrix `B' = r(sim)
	assert mreldif(`A', `B') == 0
end
* (agree, the third pairwise type, uses the same conversion; its estimation does not converge with these data)
foreach st in joint force forcing {
	foreach cu in "" unconditional {
		nwsaom, waves(sn1 sn2 sn3) outdegree symtype(`st') `cu' k0(20) k3(100) seed(3)
		fx_samerates
	}
}
nwsaom, wave1(sn1) wave2(sn2) outdegree symtype(joint) k0(20) k3(100) seed(3)
fx_samerates
nwsaom, wave1(sn1) wave2(sn2) outdegree symtype(joint) unconditional k0(20) k3(100) seed(3)
fx_samerates
* a larger reported rate gives more change than the fitted one
nwsaom, waves(sn1 sn2 sn3) outdegree symtype(joint) unconditional k0(20) k3(100) seed(3)
matrix R = e(rates)
estat simulate, nsim(10) seed(11) rates(`=R[1,1] * 3' `=R[1,2] * 3')
matrix S = r(sim)
estat simulate, nsim(10) seed(11)
matrix S0 = r(sim)
mata: st_numscalar("__fx_d", mean(abs(st_matrix("S")[., 3] :- st_matrix("S0")[., 3])))
assert scalar(__fx_d) > 0
* nwsaom simulate: rates() on the same scale (simulation at e(rates) of a fit = the fitted simulation)
nwsaom, waves(sn1 sn2 sn3) outdegree symtype(joint) k0(10) k3(60) seed(3)
local th = strofreal(_b[outdegree], "%21.0g")
local r1 = strofreal(el(e(rates), 1, 1), "%21.0g")
local r2 = strofreal(el(e(rates), 1, 2), "%21.0g")
estat simulate, nsim(4) seed(11)
matrix A = r(sim)
nwsaom simulate, waves(sn1 sn2 sn3) outdegree symtype(joint) theta(`th') rates(`r1' `r2') nsim(4) seed(11)
matrix B = r(sim)
assert mreldif(A, B) < 1e-12
di "PASS rates() on RSiena's scale after pairwise non-directed fits"

* 5. models with one effect (one parameter, fixed in nwsaom simulate): two-mode, one-mode, wave1()/wave2(), fix(), co-evolution
nwclear
clear
mata: fx_tm(24, 10, 8642)
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
nwsaom simulate, waves(tm1 tm2 tm3) outdegree theta(-1) rates(3 3) nsim(2) seed(2)
assert r(nsim) == 2
nwsaom simulate, waves(tm1 tm2) outdegree theta(-1) rates(3) nsim(2) seed(2)
nwsaom, waves(tm1 tm2 tm3) outdegree theta0(-1) fix(outdegree) k0(10) k3(40) seed(1)
assert _b[outdegree] == -1
estat simulate, nsim(2) seed(1)
nwclear
clear
set obs 40
mata: fx_sn()
forvalues w = 1/3 {
	nwset, mat(__S`w') directed name(dd`w') nooutput
}
nwsaom simulate, waves(dd1 dd2 dd3) outdegree theta(-1.5) rates(3 3) nsim(2) seed(2)
nwsaom simulate, wave1(dd1) wave2(dd2) outdegree theta(-1.5) rates(3) nsim(2) seed(2)
nwsaom, wave1(dd1) wave2(dd2) outdegree theta0(-1.5) fix(outdegree) k0(10) k3(40) seed(1)
assert _b[outdegree] == -1.5 & e(tconv_max) == 0
nwsaom, waves(dd1 dd2 dd3) outdegree k0(10) k3(60) seed(1)
estat simulate, nsim(2) seed(1)
estat gof, nsim(10) seed(1)
nwsaom simulate, waves(dd1 dd2 dd3) outdegree reciprocity theta(-1.5 1) rates(3 3) nsim(2) seed(2)
forvalues w = 1/3 {
	nwset, mat(__S`w') undirected name(su`w') nooutput
}
nwsaom simulate, waves(su1 su2 su3) outdegree symtype(joint) theta(-1) rates(0.3 0.3) nsim(2) seed(2)
gen double y1 = mod(_n * 7, 5)
gen double y2 = mod(_n * 7 + (_n > 20), 5)
gen double y3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
nwsaom simulate, waves(dd1 dd2 dd3) outdegree behavior(y1 y2 y3 : linear) theta(-1.5) behtheta(0) rates(3 3) ratesbeh(1 1) nsim(2) seed(2)
di "PASS models with one effect"

di "ALL PASS"
