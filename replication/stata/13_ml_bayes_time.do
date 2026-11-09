* Times of the slower estimators quoted in Section 6 (appendix): nwsaom's maximum-likelihood fit with seeds 1 to 3
* and the default Bayesian run, for the model with outdegree, reciprocity and transitive triplets.
* Run from the replication folder:  stata -e do stata/13_ml_bayes_time.do   (about 7 minutes)
quietly do stata/setup.do
nwwebuse glasgow, nwclear
forvalues s = 1/3 {
	timer clear 1
	timer on 1
	quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ml seed(`s')
	timer off 1
	quietly timer list 1
	display as text "ML seed `s': " as result %6.1f r(t1) as text " seconds"
}
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(50) k3(1000) seed(12345)
timer clear 1
timer on 1
quietly nwsaom bayes, seed(1)
timer off 1
quietly timer list 1
display as text "Bayes seed 1: " as result %6.1f r(t1) as text " seconds"
