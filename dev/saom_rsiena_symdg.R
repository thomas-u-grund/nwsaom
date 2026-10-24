# RSiena degree-function and Jaccard effects in a NON-DIRECTED network (symmetric s50 waves)
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
parm <- list(outTrunc2 = 3, outMore2 = 2, outMore3 = 3, outThreshold2 = 2, outTrunc = 3, outMore = 2, outThreshold = 2)
for (ef in strsplit(Sys.getenv("EFFS", "Jout"), " ")[[1]]) {
	e <- eval(parse(text = sprintf("includeEffects(getEffects(d), %s)", ef)))
	if (!is.null(parm[[ef]])) { x <- unclass(e); k <- which(x$shortName == ef & x$include & x$type == "eval"); e$parm[k] <- parm[[ef]] }
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
