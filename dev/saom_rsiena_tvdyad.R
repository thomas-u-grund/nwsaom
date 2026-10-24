# RSiena changing dyadic covariate (varDyadCovar): X, XRecip and the nine W effects (WWX ... XXW), s50; period matrices dev/saom_rsiena_dyadx_w.csv and dev/saom_rsiena_dyadx_w2.csv
library(RSiena)
if (!file.exists("dev/saom_rsiena_dyadx_w2.csv")) {
	set.seed(12)
	W2 <- matrix(sample(0:2, 2500, replace = TRUE, prob = c(0.75, 0.15, 0.1)), 50, 50); diag(W2) <- 0
	write.csv(W2, "dev/saom_rsiena_dyadx_w2.csv", row.names = FALSE)
}
W1 <- as.matrix(read.csv("dev/saom_rsiena_dyadx_w.csv")); W2 <- as.matrix(read.csv("dev/saom_rsiena_dyadx_w2.csv"))
dimnames(W1) <- NULL; dimnames(W2) <- NULL
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
dv <- varDyadCovar(array(c(W1, W2), dim = c(50, 50, 2)))
d <- sienaDataCreate(net, dv)
for (ef in strsplit(Sys.getenv("EFFS", "X"), " ")[[1]]) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'dv')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
