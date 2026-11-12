* Extended tests: COMPARISONS WITH RSiena. Only numbers obtained outside Stata are asserted: the hand counts below were checked with
* base R and RSiena 1.6.14 (sienaDataCreate, print of the data object) on 2026-11-12. Everything that needs an RSiena estimation is
* a TODO-R block: the exact R code is given and the Stata assertion is commented out until the reference number is filled in.
* DRAFT, not yet run. Expected runtime: under 1 minute.
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

* ---------------------------------------------------------------------------------------------------------------------------
* the 6-actor data (R: T1 <- matrix(c(...), 6, byrow=TRUE) with the same rows)
*   wave   ties  mutual pairs  transitive triplets  cyclic (trace(A^3))
*   1      9     1             1                    3
*   2      10    3             3                    3
*   3      11    3             3                    6
*   period 1: kept 6 created 4 dissolved 3 Jaccard 6/13 Hamming 7 persistence 6/9
*   period 2: kept 8 created 3 dissolved 2 Jaccard 8/13 Hamming 5 persistence 8/10
*   RSiena (print(sienaDataCreate(...))): densities 0.3 0.333 0.367, average degree 1.5 1.667 1.833
* ---------------------------------------------------------------------------------------------------------------------------
nwclear
clear
matrix T1 = (0,1,0,0,1,0 \ 0,0,1,0,0,0 \ 1,0,0,0,0,1 \ 0,0,1,0,1,0 \ 0,0,0,1,0,0 \ 1,0,0,0,0,0)
matrix T2 = (0,1,1,0,0,0 \ 1,0,1,0,0,0 \ 1,0,0,0,0,0 \ 0,0,1,0,1,1 \ 0,0,0,1,0,0 \ 0,1,0,0,0,0)
matrix T3 = (0,0,1,0,0,1 \ 1,0,1,0,0,0 \ 1,1,0,0,0,0 \ 0,0,0,0,1,1 \ 0,1,0,1,0,0 \ 0,1,0,0,0,0)
forvalues w = 1/3 {
	nwset, mat(T`w') directed name(rt`w') nooutput
}

* 1. nwsaom describe = RSiena's data description
nwsaom describe, waves(rt1 rt2 rt3)
matrix W = r(waves)
matrix P = r(periods)
matrix WX = (9, 0.3, 1.5 \ 10, 10/30, 10/6 \ 11, 11/30, 11/6)
matrix W3 = W[1..3, 1..3]
assert mreldif(W3, WX) < 1e-12
assert W[1, 4] == 0 & W[1, 5] == 0
matrix PX = (6, 4, 3, 6/13, 7, 6/9 \ 8, 3, 2, 8/13, 5, 8/10)
assert mreldif(P, PX) < 1e-12
di "PASS nwsaom describe equals the R counts"

* 2. observed statistics of the fitted model (columns in the order of the effects typed)
nwsaom, waves(rt1 rt2 rt3) outdegree reciprocity transtrip cycle3 k0(10) k3(60) seed(1)
mata: st_matrix("__XT_S2", __nwsaom_last_M.full_statistic(__nwsaom_last_G2))
mata: st_matrix("__XT_S3", __nwsaom_last_M.full_statistic(__nwsaom_last_G3))
* find the columns by the coefficient names (the model may order its terms differently from the options typed);
* the statistics vector has one entry per coefficient of e(b) (no rate parameters)
assert colsof(__XT_S2) == colsof(e(b))
local cn : colnames e(b)
local j = 0
foreach c of local cn {
	local ++j
	foreach t in outdegree reciprocity transtrip cycle3 {
		if strpos("`c'", "`t'") local c_`t' `j'
	}
}
foreach t in outdegree reciprocity transtrip cycle3 {
	assert "`c_`t''" != ""
}
* outdegree = ties, transTrip = transitive triplets, cycle3 = trace(A^3) (stat_saom_cycle3, unw_saom.do:4325, sums the closed
* 3-cycles over the arcs, as RSiena's cycle3 target does)
assert __XT_S2[1, `c_outdegree'] == 10 & __XT_S2[1, `c_transtrip'] == 3 & __XT_S2[1, `c_cycle3'] == 3
assert __XT_S3[1, `c_outdegree'] == 11 & __XT_S3[1, `c_transtrip'] == 3 & __XT_S3[1, `c_cycle3'] == 6
* reciprocity: RSiena's target counts reciprocated arcs (6 in both waves); sn_stat_mutual() lives in the core Mata library and its
* convention (arcs 6 or pairs 3) was not checked from source. Either is accepted; the display records which one holds.
assert inlist(__XT_S2[1, `c_reciprocity'], 3, 6) & __XT_S3[1, `c_reciprocity'] == __XT_S2[1, `c_reciprocity']
di "reciprocity statistic counts " cond(__XT_S2[1, `c_reciprocity'] == 6, "reciprocated arcs (as RSiena)", "mutual pairs (half of RSiena's target)")
* estat simulate reports the observed end-of-period values in r(obs): ties, mutual, transitive
estat simulate, nsim(2) seed(1)
matrix O = r(obs)
assert rowsof(O) == 2
assert O[1, 3] == 10 & O[1, 4] == 3 & O[1, 5] == 3
assert O[2, 3] == 11 & O[2, 4] == 3 & O[2, 5] == 3
di "PASS observed statistics equal the R counts"

* 3. initial rate values (RSiena's default starting rate for a period, getEffects()$initialValue) - TODO-R
* TODO-R:
*   library(RSiena)
*   net <- sienaDependent(array(c(T1, T2, T3), dim = c(6, 6, 3)))
*   eff <- getEffects(sienaDataCreate(net))
*   print(eff$initialValue[eff$include], digits = 15)
* local r1 = ...
* local r2 = ...
* (nwsaom: the starting rates are not in e(); compare by eye with the k0 iteration log, or add the assert if a stored result appears)

* 4. estimates of the 6-actor model - TODO-R (tiny data, the estimates are unstable; use a loose tolerance of 2 standard errors)
* TODO-R:
*   alg <- sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 1000)
*   eff <- includeEffects(getEffects(sienaDataCreate(net)), transTrip, cycle3)
*   ans <- siena07(alg, data = sienaDataCreate(net), effects = eff, batch = TRUE, silent = TRUE)
*   print(cbind(ans$theta, ans$se), digits = 10); print(ans$rate)
* matrix RB = (...)
* matrix RS = (...)
* forvalues j = 1/4 {
*	assert abs(el(e(b), 1, `j' + 0) - RB[1, `j']) < 2 * max(RS[1, `j'], sqrt(el(e(V), `j', `j')))
* }

* 5. 40-actor directed model with an ego covariate - TODO-R (data from xt_dir("RD", 40, 2, 0.10, 0.05, 4242); export with
*    mata: st_matrix(); then write the two matrices to csv and read them in R)
* TODO-R:
*   W1 <- as.matrix(read.csv("rd1.csv", header = FALSE)); W2 <- as.matrix(read.csv("rd2.csv", header = FALSE))
*   x <- coCovar((1:40 %% 5) / 2)
*   d <- sienaDataCreate(net = sienaDependent(array(c(W1, W2), dim = c(40, 40, 2))), x = x)
*   eff <- includeEffects(getEffects(d), transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = "x")
*   ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 3000), data = d, effects = eff, batch = TRUE, silent = TRUE)
*   print(cbind(ans$theta, ans$se), digits = 10); print(ans$rate)
* (Stata side, once the numbers are in:)
* mata: xt_dir("RD", 40, 2, 0.10, 0.05, 4242)
* nwset, mat(RD1) directed name(rd1) nooutput
* nwset, mat(RD2) directed name(rd2) nooutput
* gen double x = mod(_n, 5) / 2
* nwsaom, waves(rd1 rd2) outdegree reciprocity transtrip egox(x) altx(x) seed(1)
* assert abs(e(rate) - RRATE) < 2 * max(e(rate_se), RRATESE)

* 6. undirected (symmetric) data: RSiena's description and the rate scale of the pairwise types - TODO-R
* TODO-R:
*   U1 <- (T1 | t(T1)) * 1; U2 <- (T2 | t(T2)) * 1
*   d <- sienaDataCreate(u = sienaDependent(array(c(U1, U2), dim = c(6, 6, 2))))
*   print(d)                                        # density, average degree as RSiena counts them for symmetric data
*   for (mt in c(2, 3, 4, 5, 6)) {
*     eff <- getEffects(d); eff <- setEffect(eff, density, initialValue = -1.6, fix = TRUE)
*     alg <- sienaAlgorithmCreate(projname = NULL, modelType = c(u = mt), simOnly = TRUE, nsub = 0, n3 = 1000, seed = 1)
*     print(siena07(alg, data = d, effects = eff, batch = TRUE, silent = TRUE)$rate)
*   }
* (expected Stata analogue: nwsaom, waves(u1 u2) degree theta0(-1.6) fix(_all) symtype(...); compare e(rates) to the R rates
*  with the conditional scale RA/(n-1) for the pairwise types and sqrt(RA/(n-1)) for unconditional, see xt_shapes_undirected.do)

di "ALL PASS"
