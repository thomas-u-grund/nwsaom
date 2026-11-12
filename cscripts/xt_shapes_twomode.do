* Extended tests, data-shape grid 3: TWO-MODE networks. 2 and 3 waves, one effect and several, actormode(1), a 5 x 3 network,
* covariates and covariate rate, a co-evolving behavior of the actors, structural codes; postestimation: estat simulate (the
* table and r(sim) show ties only; generated networks are two-mode with the actors in the rows), estat importance, estat
* timetest, nwsaom simulate; estat gof and estat mems stop with r(198) (documented). nwsaom describe of a two-mode network.
* DRAFT, not yet run. Expected runtime: about 2-3 minutes.
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

nwclear
clear
mata: xt_tm("TM", 24, 10, 3, 0.15, 0.10, 8642)
forvalues w = 1/3 {
	nwset, mat(TM`w') bipartite name(tm`w') nooutput
}
gen double ega = .
gen double altb = .
gen double rca = 0
mata: __xt_md = st_sdata(., "_nwmode"); __xt_ia = selectindex(__xt_md :== "2"); __xt_ie = selectindex(__xt_md :== "1")
mata: st_store(__xt_ia, "ega", mod((1::rows(__xt_ia)) * 7, 11) / 3); st_store(__xt_ie, "altb", mod((1::rows(__xt_ie)) * 3, 5))
mata: st_store(__xt_ia, "rca", mod(1::rows(__xt_ia), 3))
assert _N == 34

* ---------------------------------------------------------------------------------------------------------------------------
* 0. nwsaom describe: ties are the cells of the actors x events matrix (hand count from the matrices)
* ---------------------------------------------------------------------------------------------------------------------------
nwsaom describe, waves(tm1 tm2 tm3)
assert r(twomode) == 1 & r(n_actors) == 24 & r(n_events) == 10
matrix DW = r(waves)
matrix DP = r(periods)
forvalues w = 1/3 {
	mata: st_numscalar("__xt_t", sum(st_matrix("TM`w'")))
	assert DW[`w', 1] == scalar(__xt_t)
	assert reldif(DW[`w', 2], scalar(__xt_t) / 240) < 1e-12
	assert reldif(DW[`w', 3], scalar(__xt_t) / 24) < 1e-12
}
forvalues p = 1/2 {
	local q = `p' + 1
	mata: A = st_matrix("TM`p'"); B = st_matrix("TM`q'")
	mata: st_numscalar("__xt_k", sum(A :& B)); st_numscalar("__xt_c", sum(!A :& B)); st_numscalar("__xt_d", sum(A :& !B))
	assert DP[`p', 1] == scalar(__xt_k) & DP[`p', 2] == scalar(__xt_c) & DP[`p', 3] == scalar(__xt_d)
	assert DP[`p', 5] == scalar(__xt_c) + scalar(__xt_d)
}
di "PASS nwsaom describe, two-mode"

* ---------------------------------------------------------------------------------------------------------------------------
* 1. 2 and 3 waves, one effect and several: stored results and postestimation
* ---------------------------------------------------------------------------------------------------------------------------
foreach spec in "wave1(tm1) wave2(tm2)" "waves(tm1 tm2)" "waves(tm1 tm2 tm3)" {
	foreach eff in "outdegree" "outdegree indegpopularity outactivity cycle4 nodeocov(ega) nodeicov(altb)" {
		nwsaom, `spec' `eff' k0(10) k3(60) seed(3)
		local P = e(nwaves) - 1
		local K = colsof(e(b))
		assert e(twomode) == 1 & e(n_actors) == 24 & e(n_events) == 10
		assert "`e(symtype)'" == ""
		estat simulate, nsim(3) seed(1) generate(ts)
		matrix S = r(sim)
		matrix O = r(obs)
		assert rowsof(S) == 3 * `P'
		forvalues r = 1/`=rowsof(S)' {
			* two-mode: ties only, mutual and transitive columns missing
			assert S[`r', 3] < . & S[`r', 4] >= . & S[`r', 5] >= .
		}
		assert O[1, 3] < . & O[1, 4] >= .
		xt_simcheck ts 3 `P', nodes(34) twomode nactors(24)
		forvalues s = 1/3 {
			forvalues p = 1/`P' {
				* the saved network holds every simulated tie (the square two-mode form counts each tie twice)
				xt_netinfo ts_`s'_p`p'
				assert r(ties) / 2 == S[(`s' - 1) * `P' + `p', 3]
			}
		}
		nwdrop ts_*
		capture noisily estat gof, nsim(10) seed(1)
		assert _rc == 198
		capture noisily estat mems, effect(outdegree) macro(xt_mties) nsim(20) seed(1) nodots
		assert _rc == 198
		estat importance
		confirm matrix r(ri)
		if `P' > 1 {
			estat timetest
			assert r(p) < .
		}
		xt_samerates
		* nwsaom simulate at the fitted values
		estat simulate, nsim(2) seed(9)
		matrix A = r(sim)
		local th ""
		forvalues j = 1/`K' {
			local th "`th' `=strofreal(el(e(b), 1, `j'), "%21.0g")'"
		}
		xt_rclist
		local rl "`r(list)'"
		nwsaom simulate, `spec' `eff' theta(`th') rates(`rl') nsim(2) seed(9) gen(tq)
		matrix B = r(sim)
		assert mreldif(A, B) < 1e-12
		xt_simcheck tq 2 `P', nodes(34) twomode nactors(24)
		nwdrop tq_*
	}
}
di "PASS two-mode: 2 and 3 waves, one and six effects"

* ---------------------------------------------------------------------------------------------------------------------------
* 2. actormode(1): the columns of the affiliation matrix are the actors
* ---------------------------------------------------------------------------------------------------------------------------
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity actormode(1) k0(10) k3(60) seed(3)
assert e(n_actors) == 10 & e(n_events) == 24
estat simulate, nsim(2) seed(1) generate(am)
* help: the generated networks have one row per actor (here the 10 actors of mode 1 become the rows, i.e. mode "2")
xt_simcheck am 2 2, nodes(34) twomode nactors(10)
nwdrop am_*
estat importance
xt_samerates
di "PASS two-mode actormode(1)"

* ---------------------------------------------------------------------------------------------------------------------------
* 3. covariate rate, structural codes and a co-evolving behavior of the actors in a two-mode network
* ---------------------------------------------------------------------------------------------------------------------------
* covariate rate on the actors (help: ratecov() works with two-mode networks)
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity ratecov(rca) k0(10) k3(60) seed(3)
confirm matrix e(ratecoefs)
estat simulate, nsim(2) seed(1) generate(rr)
xt_simcheck rr 2 2, nodes(34) twomode nactors(24)
nwdrop rr_*
xt_samerates
* structural codes: actor rows 1-3 cannot choose events 1-2 (10), actor 4 keeps event 3 (11)
mata:
for (w=1; w<=3; w++) {
	M = st_matrix("TM" + strofreal(w))
	M[|1, 1 \ 3, 2|] = J(3, 2, 10)
	M[4, 3] = 11
	st_matrix("TC" + strofreal(w), M)
}
end
forvalues w = 1/3 {
	nwset, mat(TC`w') bipartite name(tc`w') nooutput
}
nwsaom describe, waves(tc1 tc2 tc3)
matrix DW = r(waves)
assert DW[1, 4] == 6 & DW[1, 5] == 1
nwsaom, waves(tc1 tc2 tc3) outdegree indegpopularity k0(10) k3(60) seed(3)
estat simulate, nsim(3) seed(1) generate(sc)
xt_simcheck sc 3 2, nodes(34) twomode nactors(24)
nwdrop sc_*
xt_samerates
* behavior of the actors (events: absent actors with value 0); the fit may not converge on these data (as in test_nwsaom_twomode_cov)
gen double zb1 = 0
gen double zb2 = 0
gen double zb3 = 0
mata: st_store(__xt_ia, "zb1", 1 :+ mod(1::rows(__xt_ia), 4)); st_store(__xt_ia, "zb2", 1 :+ mod((1::rows(__xt_ia)) :+ (mod(1::rows(__xt_ia), 5) :== 0), 4)); st_store(__xt_ia, "zb3", 1 :+ mod(1::rows(__xt_ia), 4))
capture noisily nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505, 301)
if _rc == 0 {
	assert e(twomode) == 1 & e(has_behavior) == 1
	estat simulate, nsim(2) seed(1) generate(tb)
	xt_simcheck tb 2 2, nodes(34) twomode nactors(24)
	nwdrop tb_*
	drop tb_*
}
* nwsaom simulate sets the model up with a short fixed-parameter fit, whose rates may fail to converge in the same way
capture noisily nwsaom simulate, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear) theta(-1.5) behtheta(0) rates(3 3) ratesbeh(1 1) nsim(2) seed(1)
assert inlist(_rc, 0, 498, 505, 301)
if _rc == 0 assert rowsof(r(sim)) == 4
di "PASS two-mode with ratecov, structural codes and a behavior"

* ---------------------------------------------------------------------------------------------------------------------------
* 4. a very small two-mode network: 5 actors x 3 events, one effect
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
matrix Q1 = (1,0,0 \ 0,1,0 \ 1,1,0 \ 0,0,1 \ 0,1,1)
matrix Q2 = (1,1,0 \ 0,1,0 \ 1,0,0 \ 0,0,1 \ 0,1,0)
matrix Q3 = (0,1,0 \ 0,1,1 \ 1,0,0 \ 1,0,1 \ 0,1,0)
forvalues w = 1/3 {
	nwset, mat(Q`w') bipartite name(tq`w') nooutput
}
nwsaom, waves(tq1 tq2 tq3) outdegree k0(10) k3(60) seed(1)
assert e(n_actors) == 5 & e(n_events) == 3 & colsof(e(b)) == 1
estat simulate, nsim(3) seed(1) generate(qs)
xt_simcheck qs 3 2, nodes(8) twomode nactors(5)
nwdrop qs_*
estat importance
nwsaom simulate, wave1(tq1) wave2(tq2) outdegree theta(-0.5) rates(1) nsim(2) seed(1)
assert rowsof(r(sim)) == 2
di "PASS 5 x 3 two-mode network"

di "ALL PASS"
