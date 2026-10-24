# RSiena behavior effects of the network position / the alters / the similarity family (s50 + alcohol)
library(RSiena)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
d <- sienaDataCreate(net, beh)
efs <- strsplit(Sys.getenv("EFFS", "indeg outdeg recipDeg isolate outIsolate totAlt avAltPop totAltPop maxAlt minAlt avRecAlt totRecAlt totSim avAttHigher avAttLower totAttHigher totAttLower avSimPopAlt totSimPopAlt avSimPopEgo"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = 'net')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
