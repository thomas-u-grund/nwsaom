* The logs and graphs of Section 5 of the article (glasgow_*.log.tex or .log, the goodness-of-fit graphs) and
* the plain-text logs of the shorter listings (extras.log: version, describe, time test, importance, score
* test, maximum likelihood, Bayes, simulate and meta; extras2.log: larger goodness-of-fit runs, value rules,
* undirected network). Run from the replication folder: do article/gen_logs.do   (about 5 minutes; the
* Bayesian run takes about two of them). Output in results/article.
do stata/setup.do
* sjlog (the Stata Journal's logging command) writes the .log.tex files that the article inputs. Without the
* Stata Journal tools, a plain text log with the same name is written instead.
capture which sjlog
if _rc {
	capture program drop sjlog
	program define sjlog
		gettoken sub 0 : 0, parse(" ,")
		if "`sub'" == "using" {
			syntax anything(name=fn) [, replace]
			log using `fn'.log, text replace name(sjlog) nomsg
		}
		else if "`sub'" == "close" log close sjlog
	end
}
capture mkdir results
capture mkdir results/article
cd results/article
capture set scheme stsj   // the Stata Journal graph scheme (Stata 18 and later); the article's graphs were made with it
if _rc set scheme sj      // Stata 17: the older Stata Journal scheme

* =====================================================================
* Example 1: a basic model on all three Glasgow waves, chained via
* waves() - does smoking-status homophily predict new friendship
* formation, net of reciprocity and cyclical closure? cycle3, not
* transtrip, is used here deliberately: see glasgow_badmodel below for
* why (reciprocity+transtrip together are badly behaved on this
* particular network - a real, disclosed finding, not a software bug).
* =====================================================================
sjlog using glasgow_fit, replace
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity cycle3 nodematch(smoke1) k0(50) k3(2000) seed(12345)
sjlog close, replace

* =====================================================================
* Example 2: postestimation - goodness of fit on the model above.
* =====================================================================
sjlog using glasgow_gof, replace
estat gof, seed(12345) name(glasgow_gof_plot)
sjlog close, replace
graph export glasgow_gof_plot_outdegree.pdf, name(glasgow_gof_plot_outdegree) replace

* =====================================================================
* Example 3: reading the convergence summary - transitive triplets instead
* of cycle3, with a short phase 3 (k3(200)).
* =====================================================================
sjlog using glasgow_badmodel, replace
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(200) seed(12345)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(1000) theta0(-2.683 2.472 0.621) seed(12346)
sjlog close, replace

* =====================================================================
* Example 4: co-evolution of friendship and alcohol use - selection
* (behsim) and influence (avalt) in one model.
* =====================================================================
sjlog using glasgow_coev, replace
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behsim behavior(alcohol1 alcohol2 alcohol3) linear avalt k0(50) k3(2000) seed(12345)
sjlog close, replace

sjlog using glasgow_coev_gof, replace
estat gof, seed(12345) name(glasgow_coev_gof_plot)
sjlog close, replace
graph export glasgow_coev_gof_plot_behavior.pdf, name(glasgow_coev_gof_plot_behavior) replace

* =====================================================================
* Example 5: endowment and creation - the quadratic shape effect split
* into separate effects for decreasing and increasing alcohol use.
* =====================================================================
sjlog using glasgow_endow, replace
nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation k0(50) k3(1000) seed(12345)
sjlog close, replace


* =====================================================================
* "Fixing effects, simulating, testing": the score-type test, the time test and relative importance
* (sjlog listings; the fits run quietly)
* =====================================================================
sjlog using glasgow_score, replace
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip cycle3 theta0(-2.3 2 0 0) fix(transtrip cycle3) k0(100) k3(1000) seed(1)
estat score
sjlog close, replace

sjlog using glasgow_timetest, replace
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(1000) seed(12345)
estat timetest
sjlog close, replace

sjlog using glasgow_importance, replace
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip cycle3 k0(50) k3(1000) seed(12345)
estat importance
sjlog close, replace

* =====================================================================
* Plain-text logs for the short listings of the article (extras.log):
* version, describe, ML, Bayes, score test, time test, importance, simulate + meta
* =====================================================================
log using extras.log, text replace nomsg
nwsaom version
nwsaom describe, waves(glasgow1 glasgow2 glasgow3)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(1000) seed(12345)
estat timetest
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip cycle3 k0(50) k3(1000) seed(12345)
estat importance
nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip cycle3 theta0(-2.3 2 0 0) fix(transtrip cycle3) k0(100) k3(1000) seed(1)
estat score
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ml seed(1)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ml seed(2)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(1000) seed(12345)
timer clear 9
timer on 9
nwsaom bayes, seed(1)
timer off 9
timer list 9
nwsaom simulate, waves(glasgow1 glasgow2) outdegree reciprocity transtrip theta(-2.3 2 0.5) rates(5) nsim(4) seed(7) generate(g)
forvalues s = 1/4 {
	quietly nwsaom, waves(glasgow1 g_`s'_p1) outdegree reciprocity transtrip k3(500) seed(`s')
	estimates store grp`s'
}
nwsaom meta grp1 grp2 grp3 grp4
log close

* ---- larger gof runs for the comparison with sienaGOF (1000 simulations)
log using extras2.log, text replace nomsg
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity cycle3 nodematch(smoke1) k0(50) k3(2000) seed(12345)
estat gof, nsim(1000) seed(1) name(gofbig)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behsim behavior(alcohol1 alcohol2 alcohol3) linear avalt k0(50) k3(2000) seed(12345)
estat gof, nsim(1000) seed(1) name(gofbig)
* ---- value rules: a wave with a tie value 10, and a wave of shares
nwtomata glasgow1, mat(F)
mata: F1 = F; F1[1,2] = 10; F2 = F * 0.5
nwset, mat(F1) directed name(val10)
nwset, mat(F2) directed name(shares)
capture noisily nwsaom, waves(val10 glasgow2) outdegree reciprocity k3(50)
capture noisily nwsaom, waves(shares glasgow2) outdegree reciprocity k3(50)
* ---- undirected network over three waves
nwsym glasgow1, generate(sym1)
nwsym glasgow2, generate(sym2)
nwsym glasgow3, generate(sym3)
capture noisily nwsaom, waves(sym1 sym2 sym3) outdegree k0(30) k3(200) seed(1)
log close

cd "$REP"
display "=== Article reproduction complete ==="
