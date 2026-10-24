# RSiena behavior shape effects (quad_cc quad_nc constant threshold simAllNear simAllFar avGroup totGroup), s50 + alcohol
library(RSiena)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
d <- sienaDataCreate(net, beh)
efs <- strsplit(Sys.getenv("EFFS", "quad_cc quad_nc constant threshold:3 simAllNear:2 simAllFar:3 avGroup:1 totGroup:1"), " ")[[1]]
for (ef in efs) {
	pr <- strsplit(ef, ":")[[1]]
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	if (grepl("^quad_", pr[1])) e <- includeEffects(e, quad, name = "beh", include = FALSE)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh')", pr[1])))
	if (length(pr) > 1) { x <- unclass(e); k <- which(x$shortName == pr[1] & x$include & x$name == "beh"); e$parm[k] <- as.numeric(pr[2]) }
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
