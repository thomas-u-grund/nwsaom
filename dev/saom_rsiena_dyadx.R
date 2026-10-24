# RSiena network effects of a constant dyadic covariate W (WWX cyWWX InWWX OutWWX WXX XWX XWX1 XWX2 XXW), s50; W = a random asymmetric 0/1/2 matrix
library(RSiena)
set.seed(11)
W <- matrix(sample(0:2, 2500, replace = TRUE, prob = c(0.8, 0.12, 0.08)), 50, 50); diag(W) <- 0
write.csv(W, "dev/saom_rsiena_dyadx_w.csv", row.names = FALSE)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
dc <- coDyadCovar(W)
d <- sienaDataCreate(net, dc)
for (ef in strsplit(Sys.getenv("EFFS", "WWX cyWWX InWWX OutWWX WXX XWX XWX1 XWX2 XXW"), " ")[[1]]) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'dc')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
