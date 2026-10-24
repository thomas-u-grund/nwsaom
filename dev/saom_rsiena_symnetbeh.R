# RSiena network effects with the dependent behavior as the covariate (interaction1 = "beh") in a NON-DIRECTED network, s50 alcohol + symmetric waves sym_w1..3.csv
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
d <- sienaDataCreate(net, beh)
efs <- strsplit(Sys.getenv("EFFS"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'beh')", ef)))
	x <- unclass(e); k <- which(x$shortName == ef & x$include & x$name == "net")
	if (ef == "outXMore" || ef == "homXOutAct2") e$parm[k] <- 1
	if (grepl("Threshold", ef)) e$parm[k] <- 0
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
