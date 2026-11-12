* Extended tests: DETERMINISM AND INVARIANCE.
* (a) The same seed gives identical results (exactly: mreldif == 0) for fits, estat simulate / gof / mems, nwsaom simulate and
*     nwsaom refit; the number of threads does not change them (help of cores()); different seeds give different draws.
* (b) Relabelling the actors (a permutation of the node order, with the covariates permuted alike) changes nothing that is
*     deterministic (nwsaom describe, the observed statistics r(obs) of estat simulate: exactly equal), and changes the random
*     results only within Monte Carlo error. Tolerances, stated loosely on purpose:
*     - simulated means at the SAME coefficients and rates (nwsaom simulate, 100 draws each): |mean1 - mean2| < 4 standard
*       errors of the difference (computed from the draws themselves; a false alarm has probability below 1e-4 per comparison);
*     - estimates of the permuted data: |b1 - b2| < 0.5 * max(se1, se2) for every coefficient (k3(500); two runs of the
*       Robbins-Monro algorithm on the same data with different random numbers typically differ by 0.05-0.2 se).
* DRAFT, not yet run. Expected runtime: about 5-8 minutes (the permutation fits use k3(500)).
cscript
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 255
do cscripts/xt_common.do

* xt_mcsame A B col period: the means of column col of two r(sim) matrices in a period agree within 4 standard errors
capture program drop xt_mcsame
program define xt_mcsame
	args A B col p
	mata: __xa = select(st_matrix("`A'")[., `col'], st_matrix("`A'")[., 2] :== `p')
	mata: __xb = select(st_matrix("`B'")[., `col'], st_matrix("`B'")[., 2] :== `p')
	mata: st_numscalar("__xt_z", abs(mean(__xa) - mean(__xb)) / sqrt(variance(__xa) / rows(__xa) + variance(__xb) / rows(__xb) + 1e-12))
	di as text "  column `col', period `p': |difference| / se = " %6.3f scalar(__xt_z)
	assert scalar(__xt_z) < 4
	mata: mata drop __xa __xb
end
* xt_bclose B1 SE1 B2 SE2: every coefficient within 0.5 * max(se)
capture program drop xt_bclose
program define xt_bclose
	args b1 s1 b2 s2
	forvalues j = 1/`=colsof(`b1')' {
		local tol = 0.5 * max(`s1'[1, `j'], `s2'[1, `j'])
		di as text "  coefficient `j': " %9.4f `b1'[1, `j'] " vs " %9.4f `b2'[1, `j'] "  (tolerance " %6.4f `tol' ")"
		assert abs(`b1'[1, `j'] - `b2'[1, `j']) < `tol'
	}
end
* the standard errors of e(b) as a row vector
capture program drop xt_se
program define xt_se
	args name
	matrix `name' = vecdiag(e(V))
	forvalues j = 1/`=colsof(`name')' {
		matrix `name'[1, `j'] = sqrt(`name'[1, `j'])
	}
end

nwclear
clear
set obs 40
mata: xt_dir("D", 40, 3, 0.08, 0.04, 101)
mata: xt_sym("S", 40, 3, 0.08, 0.04, 4242)
* a fixed relabelling of the 40 actors
mata: rseed(99); __xt_p = order(runiform(40, 1), 1)
mata: xt_perm("D", "DP", 3, __xt_p)
mata: xt_perm("S", "SP", 3, __xt_p)
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(dn`w') nooutput
	nwset, mat(DP`w') directed name(dp`w') nooutput
	nwset, mat(S`w') undirected name(sn`w') nooutput
	nwset, mat(SP`w') undirected name(sp`w') nooutput
	gen double z`w' = .
	gen double zp`w' = .
}
gen double x = mod(_n * 7, 11) / 3
gen double xp = .
mata: st_store(., "xp", st_data(., "x")[__xt_p])
mata: xt_beh("z", 40, 3, 5, 77)
forvalues w = 1/3 {
	mata: st_store(., "zp`w'", st_data(., "z`w'")[__xt_p])
}

* ---------------------------------------------------------------------------------------------------------------------------
* 1. same seed, same results; threads do not matter; another seed differs
* ---------------------------------------------------------------------------------------------------------------------------
foreach model in "waves(dn1 dn2 dn3) outdegree reciprocity transtrip egox(x)" "waves(dn1 dn2 dn3) outdegree reciprocity unconditional" "waves(sn1 sn2 sn3) outdegree transtriads symtype(joint)" "wave1(dn1) wave2(dn2) outdegree reciprocity behavior(z1 z2) linear avalt" "waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) linear quadratic" {
	nwsaom, `model' k0(10) k3(100) seed(7)
	matrix B1 = e(b)
	matrix V1 = e(V)
	xt_rclist
	local r1 "`r(list)' `r(behlist)'"
	nwsaom, `model' k0(10) k3(100) seed(7) cores(1)
	matrix B2 = e(b)
	matrix V2 = e(V)
	xt_rclist
	local r2 "`r(list)' `r(behlist)'"
	assert mreldif(B1, B2) == 0 & mreldif(V1, V2) == 0
	assert "`r1'" == "`r2'"
	nwsaom, `model' k0(10) k3(100) seed(7) cores(2)
	matrix B3 = e(b)
	assert mreldif(B1, B3) == 0
	nwsaom, `model' k0(10) k3(100) seed(8)
	matrix B4 = e(b)
	assert mreldif(B1, B4) > 0
	di "PASS same seed: `model'"
}
di "PASS fits: same seed identical, threads irrelevant, another seed differs"

* the postestimation commands
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(100) seed(7)
estat simulate, nsim(5) seed(3)
matrix A = r(sim)
estat simulate, nsim(5) seed(3)
matrix B = r(sim)
assert mreldif(A, B) == 0
estat simulate, nsim(5) seed(4)
matrix C = r(sim)
assert mreldif(A, C) > 0
* seed() is set seed: without seed() the simulation follows the current random-number state
set seed 3
estat simulate, nsim(5)
matrix D = r(sim)
assert mreldif(A, D) == 0
estat gof, nsim(20) seed(3)
local p1 = r(p_outdegree)
local m1 = r(mhd_geodesic)
estat gof, nsim(20) seed(3)
assert r(p_outdegree) == `p1' & r(mhd_geodesic) == `m1'
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity theta(-2 1.5) rates(4 4) nsim(5) seed(3)
matrix A = r(sim)
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity theta(-2 1.5) rates(4 4) nsim(5) seed(3)
matrix B = r(sim)
assert mreldif(A, B) == 0
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity theta(-2 1.5) rates(4 4) nsim(5) seed(5)
matrix C = r(sim)
assert mreldif(A, C) > 0
nwsaom, waves(dn1 dn2) outdegree reciprocity k0(10) k3(100) seed(7)
estimates store two
estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(3) nodots
local ms = r(mems)
estat mems, effect(reciprocity) macro(xt_mties) nsim(20) seed(3) nodots
assert r(mems) == `ms'
nwsaom refit, k3(100) seed(9)
matrix R1 = e(b)
estimates restore two
nwsaom refit, k3(100) seed(9)
matrix R2 = e(b)
assert mreldif(R1, R2) == 0
di "PASS postestimation: same seed identical"

* ---------------------------------------------------------------------------------------------------------------------------
* 2. relabelled actors: deterministic quantities exactly equal
* ---------------------------------------------------------------------------------------------------------------------------
foreach pr in "dn dp" "sn sp" {
	local o : word 1 of `pr'
	local q : word 2 of `pr'
	nwsaom describe, waves(`o'1 `o'2 `o'3)
	matrix W1 = r(waves)
	matrix P1 = r(periods)
	nwsaom describe, waves(`q'1 `q'2 `q'3)
	matrix W2 = r(waves)
	matrix P2 = r(periods)
	assert mreldif(W1, W2) == 0 & mreldif(P1, P2) == 0
}
nwsaom describe, waves(dn1 dn2 dn3) behavior(z1 z2 z3)
matrix C1 = r(behchange)
nwsaom describe, waves(dp1 dp2 dp3) behavior(zp1 zp2 zp3)
matrix C2 = r(behchange)
assert mreldif(C1, C2) == 0
* the observed statistics of estat simulate (ties, mutual dyads, transitive triples, behavior mean)
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) linear theta(-2 1.5) behtheta(0) rates(4 4) ratesbeh(1 1) nsim(2) seed(1)
matrix O1 = r(obs)
nwsaom simulate, waves(dp1 dp2 dp3) outdegree reciprocity behavior(zp1 zp2 zp3) linear theta(-2 1.5) behtheta(0) rates(4 4) ratesbeh(1 1) nsim(2) seed(1)
matrix O2 = r(obs)
assert mreldif(O1, O2) < 1e-12
di "PASS relabelled actors: describe and observed statistics identical"

* ---------------------------------------------------------------------------------------------------------------------------
* 3. relabelled actors: simulations at the same coefficients agree within Monte Carlo error
* ---------------------------------------------------------------------------------------------------------------------------
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity transtrip egox(x) theta(-2.2 1.8 0.2 0.1) rates(4 4) nsim(100) seed(1)
matrix A = r(sim)
nwsaom simulate, waves(dp1 dp2 dp3) outdegree reciprocity transtrip egox(xp) theta(-2.2 1.8 0.2 0.1) rates(4 4) nsim(100) seed(2)
matrix B = r(sim)
forvalues p = 1/2 {
	forvalues c = 3/5 {
		xt_mcsame A B `c' `p'
	}
}
nwsaom simulate, waves(sn1 sn2 sn3) outdegree transtriads symtype(joint) theta(-1.5 0.3) rates(0.5 0.5) nsim(100) seed(1)
matrix A = r(sim)
nwsaom simulate, waves(sp1 sp2 sp3) outdegree transtriads symtype(joint) theta(-1.5 0.3) rates(0.5 0.5) nsim(100) seed(2)
matrix B = r(sim)
forvalues p = 1/2 {
	xt_mcsame A B 3 `p'
	xt_mcsame A B 5 `p'
}
nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) linear avalt theta(-2 1.5) behtheta(0 0.5) rates(4 4) ratesbeh(1.5 1.5) nsim(100) seed(1)
matrix A = r(sim)
nwsaom simulate, waves(dp1 dp2 dp3) outdegree reciprocity behavior(zp1 zp2 zp3) linear avalt theta(-2 1.5) behtheta(0 0.5) rates(4 4) ratesbeh(1.5 1.5) nsim(100) seed(2)
matrix B = r(sim)
forvalues p = 1/2 {
	xt_mcsame A B 3 `p'
	xt_mcsame A B 6 `p'
}
di "PASS relabelled actors: simulations agree within Monte Carlo error"

* ---------------------------------------------------------------------------------------------------------------------------
* 4. relabelled actors: estimates agree within half a standard error
* ---------------------------------------------------------------------------------------------------------------------------
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity transtrip egox(x) k3(500) seed(11)
matrix B1 = e(b)
xt_se S1
nwsaom, waves(dp1 dp2 dp3) outdegree reciprocity transtrip egox(xp) k3(500) seed(12)
matrix B2 = e(b)
xt_se S2
xt_bclose B1 S1 B2 S2
nwsaom, waves(sn1 sn2 sn3) outdegree transtriads symtype(joint) k3(500) seed(11)
matrix B1 = e(b)
xt_se S1
matrix R1 = e(rates)
nwsaom, waves(sp1 sp2 sp3) outdegree transtriads symtype(joint) k3(500) seed(12)
matrix B2 = e(b)
xt_se S2
matrix R2 = e(rates)
xt_bclose B1 S1 B2 S2
* conditional rates: the observed distances are the same, so the rates agree closely (5 percent, a loose bound)
assert mreldif(R1, R2) < 0.05
di "PASS relabelled actors: estimates agree"

di "ALL PASS"
