# Goodness of fit, simulation, time test, relative importance and score test after a fit with SEVERAL co-evolving behaviors (alcohol and smoking, s50): RSiena 1.6.14 reference
# for nwsaom ... behavior(a1 a2 a3 : ... | s1 s2 s3 : ...) followed by estat gof, estat simulate, estat timetest, estat importance and estat score.
# Run from the repository root: Rscript dev/saom_rsiena_mbgof.R   (Stata side: dev/saom_rsiena_mbgof.do)
library(RSiena)
data(s501); data(s502); data(s503); data(s50a); data(s50s)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
alc <- sienaDependent(s50a, type = "behavior")
smk <- sienaDependent(s50s, type = "behavior")
d <- sienaDataCreate(net, alc, smk)
e <- getEffects(d)
e <- includeEffects(e, recip, transTrip)
e <- includeEffects(e, simX, interaction1 = "alc")
e <- includeEffects(e, simX, interaction1 = "smk")
e <- includeEffects(e, quad, name = "alc")
e <- includeEffects(e, quad, name = "smk")
e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
e <- includeEffects(e, avAlt, name = "smk", interaction1 = "net")
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE, returnDeps = TRUE)
	cat(sprintf("RSIENA seed %d tconv %.3f\n  est: %s\n", sd, ans$tconv.max, paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
	g <- list(
		outdegree = sienaGOF(ans, OutdegreeDistribution, varName = "net", levls = 0:15, cumulative = FALSE, verbose = FALSE),
		indegree = sienaGOF(ans, IndegreeDistribution, varName = "net", levls = 0:15, cumulative = FALSE, verbose = FALSE),
		alc = sienaGOF(ans, BehaviorDistribution, varName = "alc", cumulative = FALSE, verbose = FALSE),
		smk = sienaGOF(ans, BehaviorDistribution, varName = "smk", cumulative = FALSE, verbose = FALSE))
	for (nm in names(g)) {
		cat(sprintf("  gof %-9s p = %.3f  observed: %s\n", nm, g[[nm]]$Joint$p, paste(round(colSums(g[[nm]]$Joint$Observations), 3), collapse = " ")))
	}
	# the simulated end states (estat simulate): mean ties and behavior means of the last period's simulations
	sims <- ans$sims
	nt <- sapply(sims, function(s) sapply(1:2, function(p) nrow(s[[1]][[1]][[p]])))
	ma <- sapply(sims, function(s) sapply(1:2, function(p) mean(s[[1]][[2]][[p]])))
	ms <- sapply(sims, function(s) sapply(1:2, function(p) mean(s[[1]][[3]][[p]])))
	cat(sprintf("  sim mean ties p1 %.1f p2 %.1f; alc mean p1 %.3f p2 %.3f; smk mean p1 %.3f p2 %.3f\n",
		mean(nt[1, ]), mean(nt[2, ]), mean(ma[1, ]), mean(ma[2, ]), mean(ms[1, ]), mean(ms[2, ])))
	tt <- sienaTimeTest(ans)
	cat(sprintf("  timetest joint p %.4f; per effect p: %s\n", tt$JointTest[1, 1], paste(round(tt$IndividualTest[, "p-Value"], 3), collapse = " ")))
	if (sd == 1) {
		ri <- RSiena:::sienaRI(d, ans)
		print(ri)
	}
}
# the score test of transitive triplets fixed at 0
eS <- setEffect(e, transTrip, fix = TRUE, test = TRUE, initialValue = 0)
for (sd in 1:3) {
	ansS <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4), data = d, effects = eS, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA score seed %d: chi2 %.3f p %.4f one-sided %.3f\n", sd, ansS$testresOverall, 1 - pchisq(ansS$testresOverall, 1), ansS$testresulto[1]))
}
