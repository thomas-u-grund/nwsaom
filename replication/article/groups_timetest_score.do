* Example 4: after a grouped fit, test whether the effects are the same in every period (estat timetest) and whether two effects are needed (estat score)
do stata/setup.do
set linesize 100
do stata/groups_stack_s50.do
capture mkdir results/article
log using results/article/groups_timetest_score.log, text replace nomsg

* (a) the model with the effects of the alcohol covariate; unconditional estimation (the estat tests use the simulated statistics)
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) unconditional seed(1)

* (b) time heterogeneity: joint test, test per effect, then per group and per period
estat timetest, fixrates
matrix list r(group)
matrix list r(period)

* (c) score test: fit the model WITHOUT the two alcohol effects (held fixed at 0) and ask whether they are needed
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) fix(egox(alc) altx(alc)) unconditional seed(1)
estat score
log close
