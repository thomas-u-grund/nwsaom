* Structural zeros and ones (RSiena's codes 10 and 11 in the wave networks): detection, targets and observed distances against RSiena 1.6.14,
* simulation at fixed parameters against RSiena (means of the convergence t-ratios), the errors and gates.
* References: dev/saom_rsiena_structural.R (variants v1, v3s, v3m, v4, v6s, tm1, tm3; tasks targets and sim; MODEL=endow for endowment/creation).
* The targets are the sums over the periods of the statistics of the standard effect list, the distances the observed distances of the periods; RSiena's
* reciprocity and 3-cycle statistics are 2 and 1/3 times nwsaom's (RSiena counts the ordered pairs and the triangles once).
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
clear

forvalues w = 1/3 {
	import delimited "dev/saom_r1614_s50_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(B`w')
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
	import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(Y`w')
}
clear

* ---- the coded data sets of the reference script, built the same way
mata:
mata set matastrict off
void sc_variants() {
	n = 50
	cls = (J(25, 1, 1) \ J(25, 1, 2))
	for (w=1; w<=3; w++) {
		B = st_matrix("B" + strofreal(w))
		// v1: cross-class dyads 10 in all waves
		M = B
		for (i=1; i<=n; i++) for (j=1; j<=n; j++) if (cls[i] != cls[j]) M[i,j] = 10
		st_matrix("V1w" + strofreal(w), M)
		// v3s: designed changing sets
		M = B
		if (w == 1) {
			M[1,2] = 10
			M[5,6] = 10
			M[7,8] = 11
		}
		if (w == 2) {
			M[3,4] = 10
			M[5,6] = 11
			M[7,8] = 11
		}
		if (w == 3) {
			M[7,8] = 10
			M[9,10] = 11
		}
		for (a=11; a<=30; a++) {
			if (w == 1) M[a, a+1] = 10 + mod(a, 2)
			if (w == 3) M[a+1, a] = 10 + (mod(a, 3) == 0)
			if (w == 2) if (mod(a, 2) == 0) M[a, a+1] = 11
		}
		st_matrix("V3w" + strofreal(w), M)
		// v3m: v3s with missing ties in wave 2 (the own codes of a missing dyad are lost)
		if (w == 2) {
			miss = J(n, n, 0)
			miss[5::7, .] = J(3, n, 1)
			miss[., 20] = J(n, 1, 1)
			miss[11::13, 12::14] = J(3, 3, 1)
			miss = miss - diag(diag(miss))
			st_matrix("MISS2", miss)
			M = M :* (1 :- miss)
		}
		st_matrix("V5w" + strofreal(w), M)
		// v4: frozen egos
		M = B
		for (a=1; a<=6; a++) for (b=1; b<=n; b++) if (a != b) M[a,b] = 10 + (M[a,b] == 1)
		for (a=7; a<=10; a++) {
			for (b=1; b<=n; b++) {
				if (b == a | b == a+10 | b == a+11 | b == a+12) continue
				M[a,b] = 10
			}
		}
		for (b=11; b<=13; b++) for (a=1; a<=n; a++) if (a != b) if (M[a,b] < 10) M[a,b] = 10 + (M[a,b] == 1)
		if (w == 2) for (b=1; b<=n; b++) if (b != 20) M[20,b] = 10
		st_matrix("V4w" + strofreal(w), M)
		// two-mode, tm1: actors 1-10 cannot choose the events 1-5, actor 11 is frozen, event 20 cannot be chosen
		M = st_matrix("T" + strofreal(w))
		for (a=1; a<=10; a++) for (b=1; b<=5; b++) M[a,b] = 10 + (M[a,b] == 1)
		M[11, .] = J(1, 20, 10)
		for (a=1; a<=40; a++) M[a,20] = 10 + (M[a,20] == 1)
		st_matrix("W1w" + strofreal(w), M)
	}
}
sc_variants()
// sy3s: symmetric relation with codes for both directions of the pair (i, i+1), i = 2, 5, ..., 38, value 10 or 11 by (i + wave)
for (w=1; w<=3; w++) {
	M = st_matrix("Y" + strofreal(w))
	for (i=2; i<=40; i=i+3) {
		cd = 10 + mod(i + w, 2)
		M[i, i+1] = cd
		M[i+1, i] = cd
	}
	if (w == 2) {
		M[20, 21] = 11
		M[21, 20] = 11
	}
	st_matrix("SYw" + strofreal(w), M)
}
// v6s: v3s with the composition change (actors 3 and 8 join at 1.4 and 2.3, 5 and 12 leave at 1.6 and 2.5); the rows and columns of an absent actor are those of the nearest present wave
jn = J(50, 1, 1)
lv = J(50, 1, 3)
jn[3] = 1.4
jn[8] = 2.3
lv[5] = 1.6
lv[12] = 2.5
O1 = st_matrix("V3w1")
O2 = st_matrix("V3w2")
O3 = st_matrix("V3w3")
X1 = O1
X2 = O2
X3 = O3
for (a=1; a<=50; a++) {
	for (k=1; k<=3; k++) {
		if (ceil(jn[a]) <= k & k <= trunc(lv[a])) continue
		pw = J(1, 0, .)
		for (kk=1; kk<=3; kk++) if (ceil(jn[a]) <= kk & kk <= trunc(lv[a])) pw = pw, kk
		best = pw[1]
		for (q=2; q<=cols(pw); q++) if (abs(pw[q] - k) < abs(best - k)) best = pw[q]
		src = (best == 1 ? O1 : (best == 2 ? O2 : O3))
		if (k == 1) {
			X1[a, .] = src[a, .]
			X1[., a] = src[., a]
		}
		if (k == 2) {
			X2[a, .] = src[a, .]
			X2[., a] = src[., a]
		}
		if (k == 3) {
			X3[a, .] = src[a, .]
			X3[., a] = src[., a]
		}
	}
}
X1 = X1 - diag(diag(X1))
X2 = X2 - diag(diag(X2))
X3 = X3 - diag(diag(X3))
st_matrix("V6w1", X1)
st_matrix("V6w2", X2)
st_matrix("V6w3", X3)
end

* ---- the targets and observed distances of a coded data set: NWSAOM_TRACE 5 leaves them in __nwsaom_tr_target (periods x effects) and __nwsaom_tr_rate
capture program drop sc_targets
program define sc_targets
	syntax , pref(string) [tm miss(string) spec(string) cc]
	nwclear
	forvalues w = 1/3 {
		if "`tm'" != "" nwset, mat(`pref'w`w') bipartite name(c`w') nooutput
		else nwset, mat(`pref'w`w') directed name(c`w') nooutput
	}
	if "`spec'" == "" local spec "outdegree reciprocity transtrip cycle3 indegpopularity outactivity"
	local mopt ""
	if "`miss'" != "" {
		matrix Z0 = J(50, 50, 0)
		local mopt "missnet(Z0 `miss' Z0)"
	}
	if "`cc'" != "" {
		clear
		set obs 50
		gen double jn = 1
		gen double lv = 3
		replace jn = 1.4 in 3
		replace jn = 2.3 in 8
		replace lv = 1.6 in 5
		replace lv = 2.5 in 12
		local mopt "`mopt' joinat(jn) leaveat(lv)"
	}
	global NWSAOM_TRACE 5
	quietly nwsaom, waves(c1 c2 c3) `mopt' `spec' k0(2) k3(10) seed(1)
	global NWSAOM_TRACE
	matrix __sc_t = J(1, colsof(__nwsaom_tr_target), 0)
	forvalues p = 1/`=rowsof(__nwsaom_tr_target)' {
		forvalues j = 1/`=colsof(__nwsaom_tr_target)' {
			matrix __sc_t[1,`j'] = __sc_t[1,`j'] + __nwsaom_tr_target[`p',`j']
		}
	}
end
capture program drop sc_chk
program define sc_chk
	args j ref
	assert reldif(__sc_t[1,`j'], `ref') < 1e-9
end

* nwsaom statistics order: outdegree, reciprocity (pairs), indegpopularity (sqrt), outactivity, transtrip, cycle3 (3 x RSiena's)
capture program drop sc_check6
program define sc_check6
	args r1 r2 r3 r4 r5 r6 d1 d2
	foreach pair in "1 `r1'" "2 `r2'" "3 `r3'" "4 `r4'" "5 `r5'" "6 `r6'" {
		tokenize `pair'
		assert reldif(__sc_t[1,`1'], `2') < 1e-6
	}
	assert __nwsaom_tr_rate[1,1] == `d1' & __nwsaom_tr_rate[1,2] == `d2'
end
sc_targets, pref(V1)
sc_check6 152 57 230.0136 374 121 123 72 58
sc_targets, pref(V3)
sc_check6 263 83 482.2081 891 225 213 110 104
sc_targets, pref(V4)
sc_check6 219 62 389.6146 683 177 147 94 83
sc_targets, pref(V5) miss(MISS2)
sc_check6 251 73 454.7038 849 199 186 104 93
di "PASS structural targets and distances (one-mode, constant and changing sets, frozen egos, missing data)"

* composition change (joiners and leavers at fractional times) with structural values
sc_targets, pref(V6) cc
sc_check6 256 80 470.0149 868 222 207 105 91
di "PASS structural targets with composition change"

* endowment and creation: the lost ties of the replaced network (RSiena: outdegree 263, reciprocity endowment -56, creation 66, transitive triplets 225)
sc_targets, pref(V3) spec(outdegree endow(reciprocity) creation(reciprocity) transtrip)
foreach pair in "1 263" "2 -56" "3 66" "4 225" {
	tokenize `pair'
	assert reldif(__sc_t[1,`1'], `2') < 1e-9
}
di "PASS structural targets with endowment and creation"

* two-mode network (40 actors, 20 events), tm1
sc_targets, pref(W1) tm spec(outdegree indegpopularity outactivity cycle4)
assert reldif(__sc_t[1,1], 506) < 1e-9 & reldif(__sc_t[1,3], 4126) < 1e-9 & reldif(__sc_t[1,4], 11676) < 1e-9
assert abs(__sc_t[1,2] - 2252.1366) < 1e-3
assert __nwsaom_tr_rate[1,1] == 140 & __nwsaom_tr_rate[1,2] == 114
di "PASS structural targets in a two-mode network"

* co-evolution with a behavior (alcohol of s50): the network part of the targets and the distances (RSiena: outdegree 263, reciprocity 166, transitive triplets 225,
* altX -4.806667, simX 21.13602)
nwclear
forvalues w = 1/3 {
	nwset, mat(V3w`w') directed name(c`w') nooutput
}
import delimited "dev/saom_structural_beh.csv", clear varnames(nonames)
rename (v1 v2 v3) (a1 a2 a3)
global NWSAOM_TRACE 5
quietly nwsaom, waves(c1 c2 c3) behavior(a1 a2 a3) outdegree reciprocity transtrip behaltx behsim linear quadratic avalt k0(2) k3(10) seed(1)
global NWSAOM_TRACE
assert reldif(__nwsaom_tr_target[1,1] + __nwsaom_tr_target[2,1], 263) < 1e-9
assert reldif(__nwsaom_tr_target[1,2] + __nwsaom_tr_target[2,2], 83) < 1e-9
assert reldif(__nwsaom_tr_target[1,3] + __nwsaom_tr_target[2,3], 225) < 1e-9
assert abs(__nwsaom_tr_target[1,4] + __nwsaom_tr_target[2,4] - 21.13602) < 1e-4
assert abs(__nwsaom_tr_target[1,5] + __nwsaom_tr_target[2,5] + 4.806667) < 1e-4
assert __nwsaom_tr_rate[1,1] == 110 & __nwsaom_tr_rate[1,2] == 104
di "PASS structural targets with a co-evolving behavior"

* ---- simulation at fixed parameters (unconditional): the convergence t-ratios (mean / sd of the deviation of the simulated statistics and distances from the
* targets) against RSiena's (siena07 simOnly, means of 10 seeds of 1000 simulations)
mata:
mata set matastrict off
void sc_sim(real scalar cond, real scalar K, real rowvector par, string scalar ref, real scalar usepres, real scalar tmflag, real scalar symctx) {
	struct SaomNetCtx scalar C
	external class SaomGraph scalar __nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_G3
	external class SaomModel scalar __nwsaom_last_M
	pointer(class SaomGraph scalar) rowvector Gw
	pointer(real matrix) rowvector MM
	real matrix Z, S, M2, pres
	real rowvector fnt, mm, sd, r, d
	real scalar k
	SaomStructRestoreLast()
	Gw = (&__nwsaom_last_G1, &__nwsaom_last_G2, &__nwsaom_last_G3)
	C.cond = cond
	pres = J(0, 0, 0)
	if (usepres) pres = *findexternal("__nwsaom_compstart")
	fnt = *findexternal("__nwsaom_last_fntype")
	SaomNetCtxInit(C, Gw, __nwsaom_last_M, pres, J(1, 0, NULL), fnt, J(0, 0, 0), symctx, (tmflag ? st_matrix("__nwsaom_tm_structmat") : J(0, 0, 0)))
	SaomNetSimMany(C, __nwsaom_last_M, par, K, 0, Z, S)
	SaomBatchCleanup()
	mm = mean(Z)
	sd = sqrt(diagonal(variance(Z)))'
	r = strtoreal(tokens(ref))
	d = mm :/ sd
	for (k=1; k<=cols(r); k++) {
		if (abs(d[k] - r[k]) > 0.3 + 0.04 * abs(r[k])) {
			printf("simulation t-ratio %g: nwsaom %g, RSiena %g\n", k, d[k], r[k])
			exit(9)
		}
	}
}
end
capture program drop sc_sim
program define sc_sim
	syntax , pref(string) spec(string) theta0(string) par(string) ref(string) [tm cc symctx(integer 0)]
	nwclear
	forvalues w = 1/3 {
		if "`tm'" != "" nwset, mat(`pref'w`w') bipartite name(c`w') nooutput
		else nwset, mat(`pref'w`w') directed name(c`w') nooutput
	}
	local mopt ""
	if "`cc'" != "" {
		clear
		set obs 50
		gen double jn = 1
		gen double lv = 3
		replace jn = 1.4 in 3
		replace jn = 2.3 in 8
		replace lv = 1.6 in 5
		replace lv = 2.5 in 12
		local mopt "joinat(jn) leaveat(lv)"
	}
	quietly nwsaom, waves(c1 c2 c3) `mopt' `spec' theta0(`theta0') rate0(4 4) fix(_all) k0(1) k3(10) seed(1)
	set seed 1
	mata: sc_sim(0, 2500, (`par'), "`ref'", ("`cc'" != ""), ("`tm'" != ""), `symctx')
end
* frozen egos (RSiena: rates -0.045 1.417; outdegree 3.191 ...)
sc_sim, pref(V4) spec(outdegree reciprocity indegpopularity outactivity transtrip cycle3) theta0(-1.7 0.6 0.25 -0.067 0.4 0.02) par(-1.7, 0.6, 0.25, -0.067, 0.4, 0.02, 4, 4) ref(3.191 -4.545 3.191 2.692 -2.612 -2.837 -0.045 1.417)
di "PASS simulation with frozen egos agrees with RSiena"
sc_sim, pref(V3) spec(outdegree reciprocity indegpopularity outactivity transtrip cycle3) theta0(-1.7 0.6 0.25 -0.067 0.4 0.02) par(-1.7, 0.6, 0.25, -0.067, 0.4, 0.02, 4, 4) ref(4.439 -5.147 4.451 3.766 -1.831 -2.647 0.692 1.410)
di "PASS simulation with changing structural sets agrees with RSiena"
sc_sim, pref(V3) spec(outdegree endow(reciprocity) creation(reciprocity) transtrip) theta0(-1.7 0.5 0.8 0.3) par(-1.7, 0.5, 0.8, 0.3, 4, 4) ref(2.026 0.049 -10.161 -5.452 0.521 1.253)
di "PASS simulation with endowment and creation agrees with RSiena"
sc_sim, pref(V6) cc spec(outdegree reciprocity indegpopularity outactivity transtrip cycle3) theta0(-1.7 0.6 0.25 -0.067 0.4 0.02) par(-1.7, 0.6, 0.25, -0.067, 0.4, 0.02, 4, 4) ref(4.160 -4.704 4.163 3.503 -2.030 -2.788 0.363 1.879)
di "PASS simulation with composition change agrees with RSiena"
sc_sim, pref(W1) tm spec(outdegree indegpopularity outactivity cycle4) theta0(-1.5 0.3 0.02 0.05) par(-1.5, 0.3, 0.02, 0.05, 4, 4) ref(-0.484 -0.713 0.421 1.176 -2.879 3.010)
di "PASS simulation in a two-mode network agrees with RSiena"

* non-directed relation (symmetric data, codes given for both directions; RSiena modelType 6 = joint, 2 = forcing): targets and simulation
sc_targets, pref(SY) spec(symmetric symtype(joint) outdegree transties indegpopularity)
assert reldif(__sc_t[1,1], 340) < 1e-9
assert abs(__sc_t[1,2] - 676.0265) < 1e-3
assert reldif(__sc_t[1,3], 232) < 1e-9
assert __nwsaom_tr_rate[1,1] == 134 & __nwsaom_tr_rate[1,2] == 128
di "PASS structural targets in a non-directed relation"
sc_sim, pref(SY) symctx(1) spec(symmetric symtype(joint) outdegree transties indegpopularity) theta0(-1.2 0.1 0.3) par(-1.2, 0.1, 0.3, 49, 49) ref(13.925 11.591 11.894 11.808 12.893)
di "PASS simulation in a non-directed relation (joint) agrees with RSiena"
sc_sim, pref(SY) symctx(4) spec(symmetric symtype(forcing) outdegree transties indegpopularity) theta0(-1.2 0.1 0.3) par(-1.2, 0.1, 0.3, 1, 1) ref(4.519 4.587 1.148 -4.09 -3.5)
di "PASS simulation in a non-directed relation (forcing) agrees with RSiena"

* ---- postestimation after a fit with codes
* estat simulate (tie counts of the simulated networks after each period, with the end values of the dyads that are structural at the end applied; RSiena
* simOnly, 3000 simulations: ties 151.65 / 163.27, mutual dyads 23.60 / 26.62; theta -1.7 0.6 0.4, rate 4)
nwclear
forvalues w = 1/3 {
	nwset, mat(V3w`w') directed name(c`w') nooutput
}
quietly nwsaom, waves(c1 c2 c3) outdegree reciprocity transtrip theta0(-1.7 0.6 0.4) rate0(4 4) fix(_all) k3(10) seed(1)
estat simulate, nsim(390) seed(2) rates(4 4)
matrix SS = r(sim)
matrix SM = J(1, 4, 0)
forvalues r = 1/780 {
	local pd = SS[`r', 2]
	matrix SM[1, 2*`pd'-1] = SM[1, 2*`pd'-1] + SS[`r', 3] / 390
	matrix SM[1, 2*`pd'] = SM[1, 2*`pd'] + SS[`r', 4] / 390
}
assert abs(SM[1,1] - 151.65) < 2.5 & abs(SM[1,3] - 163.27) < 2.5
assert abs(SM[1,2] - 23.60) < 1.0 & abs(SM[1,4] - 26.62) < 1.0
* estat gof, mems, score, timetest run (the observed statistics use the end network with the start-structural dyads set to their start value)
estat gof, nsim(10) seed(4242)
nwsaom, waves(c1 c2 c3) outdegree reciprocity transtrip theta0(-1.7 0.6 0.4) fix(transtrip) k0(5) k3(30) seed(3)
estat score
estat timetest
* estat importance: for constant structural zeros the codes and the older structural() mask give the same importance
nwclear
nwset, mat(V1w1) directed name(d1) nooutput
nwset, mat(V1w2) directed name(d2) nooutput
quietly nwsaom, wave1(d1) wave2(d2) outdegree reciprocity transtrip theta0(-1.7 0.6 0.4) fix(_all) k3(20) seed(1)
quietly estat importance
matrix RIc = r(ri)
mata:
M1 = st_matrix("V1w1")
M2 = st_matrix("V1w2")
st_matrix("MASK", (M1 :>= 10))
st_matrix("Z1", (M1 :== 1) :| (M1 :== 11))
st_matrix("Z2", (M2 :== 1) :| (M2 :== 11))
end
nwset, mat(Z1) directed name(e1) nooutput
nwset, mat(Z2) directed name(e2) nooutput
quietly nwsaom, wave1(e1) wave2(e2) outdegree reciprocity transtrip theta0(-1.7 0.6 0.4) fix(_all) k3(20) seed(1) structural(MASK)
quietly estat importance
matrix RIm = r(ri)
assert mreldif(RIc, RIm) < 1e-9
di "PASS postestimation after a fit with codes (simulate agrees with RSiena, gof/score/timetest run, importance equals the mask route)"

* nwsaom describe (RSiena print01Report: ties, structural counts per wave, the table of the periods, the distance leaves out the structural dyads)
nwclear
forvalues w = 1/3 {
	nwset, mat(V3w`w') directed name(c`w') nooutput
}
nwsaom describe, waves(c1 c2 c3)
matrix DW = r(waves)
matrix DP = r(periods)
assert DW[1,1] == 117 & DW[2,1] == 127 & DW[3,1] == 128
assert DW[1,4] == 12 & DW[1,5] == 11 & DW[2,4] == 1 & DW[2,5] == 12 & DW[3,4] == 14 & DW[3,5] == 8
assert DP[1,5] == 110 & DP[2,5] == 104
assert DP[1,2] == 70 & DP[1,3] == 60 & DP[1,1] == 57 & abs(DP[1,4] - 0.305) < 0.001
assert DP[2,2] == 62 & DP[2,3] == 61 & DP[2,1] == 66
di "PASS nwsaom describe with structural values"

* two co-evolving behaviors (alcohol, smoking of s50) and a covariate rate effect with a behavior: the network part of the targets (RSiena: as without the behaviors:
* outdegree 263, reciprocity 166 / 2, transitive triplets 225, distances 110 and 104) and the fits run (estimates agree with siena07 in dev/structural_harness)
nwclear
forvalues w = 1/3 {
	nwset, mat(V3w`w') directed name(c`w') nooutput
}
import delimited "dev/saom_structural_beh2.csv", clear varnames(nonames)
rename (v1 v2 v3 v4 v5 v6) (a1 a2 a3 s1 s2 s3)
global NWSAOM_TRACE 5
nwsaom, waves(c1 c2 c3) outdegree reciprocity transtrip behavior(a1 a2 a3 : linear quadratic avalt | s1 s2 s3 : linear quadratic avalt) k0(5) k3(30) seed(1)
global NWSAOM_TRACE
assert e(b)[1,1] < . & colsof(e(b)) == 9
assert reldif(__nwsaom_tr_target[1,1] + __nwsaom_tr_target[2,1], 263) < 1e-9 & reldif(__nwsaom_tr_target[1,2] + __nwsaom_tr_target[2,2], 83) < 1e-9
assert reldif(__nwsaom_tr_target[1,3] + __nwsaom_tr_target[2,3], 225) < 1e-9 & __nwsaom_tr_rate[1,1] == 110 & __nwsaom_tr_rate[1,2] == 104
gen double cv = mod(_n, 4) + 0.5
nwsaom, waves(c1 c2 c3) outdegree reciprocity transtrip behavior(a1 a2 a3) linear quadratic avalt ratecov(cv) k0(5) k3(30) seed(1)
assert e(b)[1,1] < . & colsof(e(b)) == 6
di "PASS several behaviors and rate covariates with a behavior run with codes"

* ---- errors and gates
nwclear
nwset, mat(V3w1) directed name(g1) nooutput
nwset, mat(V3w2) directed name(g2) nooutput
nwset, mat(V3w3) directed name(g3) nooutput
* a tie value that is neither 0, 1, 10 nor 11
matrix BAD = V3w2
matrix BAD[2,3] = 5
nwset, mat(BAD) directed name(gbad) nooutput
capture nwsaom, waves(g1 gbad g3) outdegree reciprocity k3(20)
assert _rc == 198
* not yet supported together with structural values
capture nwsaom, waves(g1 g2 g3) outdegree reciprocity ml k3(20)
assert _rc == 198
* a fit runs; its postestimation commands that do not know the codes yet refuse
nwsaom, waves(g1 g2 g3) outdegree reciprocity transtrip k0(5) k3(30) seed(3)
assert e(b)[1,1] < .
capture nwsaom_ml
assert _rc == 198
capture nwsaom bayes
assert _rc == 198
* a fit without codes afterwards works as before
nwsaom, waves(g1 g1 g1) outdegree reciprocity k0(5) k3(30) seed(3)
capture estat score
di "PASS errors and gates"
