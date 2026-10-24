# RSiena dyadic covariate effects in a NON-DIRECTED network (symmetric s50 waves sym_w1..3.csv): constant (coDyadCovar) and changing (varDyadCovar)
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
W1 <- as.matrix(read.csv("dev/saom_rsiena_dyadx_w.csv")); W2 <- as.matrix(read.csv("dev/saom_rsiena_dyadx_w2.csv"))
dimnames(W1) <- NULL; dimnames(W2) <- NULL
mode <- Sys.getenv("MODE", "const")
if (mode == "const") dv <- coDyadCovar(W1) else dv <- varDyadCovar(array(c(W1, W2), dim = c(50, 50, 2)))
d <- sienaDataCreate(net, dv)
for (ef in strsplit(Sys.getenv("EFFS", "X"), " ")[[1]]) {
	e <- eval(parse(text = sprintf("includeEffects(getEffects(d), %s, interaction1 = 'dv')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", mode, ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
