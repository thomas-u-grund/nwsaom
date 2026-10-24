# RSiena own-network effects without a covariate: Jin Jout transTrip1 transTrip2 transRecTrip2 transTrip.FR/FE/EE outPopMore outPopSqrtMore outPopThreshold and the ego degree effects, s50
library(RSiena)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
parm <- list(outPopMore = 2, outPopSqrtMore = 2, outPopThreshold = 2, outActMore_ego = 2, outActSqrtMore_ego = 2, outMore_ego = 2)
for (ef in strsplit(Sys.getenv("EFFS", "Jin"), " ")[[1]]) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s)", ef)))
	if (!is.null(parm[[ef]])) { x <- unclass(e); k <- which(x$shortName == ef & x$include & x$type == "eval"); e$parm[k] <- parm[[ef]] }
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
