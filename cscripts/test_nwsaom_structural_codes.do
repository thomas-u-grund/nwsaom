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

* ---- simulation at fixed parameters (unconditional): the convergence t-ratios (mean / sd of the deviation of the simulated statistics and distances from the
* targets) against RSiena's (siena07 simOnly, means of 10 seeds of 1000 simulations)
mata:
mata set matastrict off
void sc_sim(real scalar cond, real scalar K, real rowvector par, string scalar ref, real scalar usepres, real scalar tmflag) {
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
	SaomNetCtxInit(C, Gw, __nwsaom_last_M, pres, J(1, 0, NULL), fnt, J(0, 0, 0), 0, (tmflag ? st_matrix("__nwsaom_tm_structmat") : J(0, 0, 0)))
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
	syntax , pref(string) spec(string) theta0(string) par(string) ref(string) [tm cc]
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
	mata: sc_sim(0, 2500, (`par'), "`ref'", ("`cc'" != ""), ("`tm'" != ""))
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
capture nwsaom, waves(g1 g2 g3) outdegree reciprocity symmetric k3(20)
assert _rc == 198
capture nwsaom, waves(g1 g2 g3) outdegree reciprocity ml k3(20)
assert _rc == 198
capture nwsaom describe, waves(g1 g2 g3)
assert _rc == 198
* a fit runs; its postestimation commands that do not know the codes yet refuse
nwsaom, waves(g1 g2 g3) outdegree reciprocity transtrip k0(5) k3(30) seed(3)
assert e(b)[1,1] < .
foreach sub in gof mems simulate importance score timetest {
	capture estat `sub'
	assert _rc == 198
}
capture nwsaom_ml
assert _rc == 198
capture nwsaom bayes
assert _rc == 198
* a fit without codes afterwards works as before
nwsaom, waves(g1 g1 g1) outdegree reciprocity k0(5) k3(30) seed(3)
capture estat score
di "PASS errors and gates"
