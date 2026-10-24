# symmetric (BJOINT) + RateX over 3 waves: s501-s503 symmetrized, covariate s50a wave-1 alcohol. RSiena needs
# unconditional estimation with a rate covariate (slow for BJOINT: time it).
library(RSiena)
w <- lapply(1:3, function(i) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", i))))
net <- sienaDependent(array(unlist(w), dim = c(50, 50, 3)))
x <- coCovar(read.csv("dev/saom_rsiena_ratecov_mw_cov.csv")$x)
d <- sienaDataCreate(net, x)
e <- getEffects(d)
e <- includeEffects(e, RateX, interaction1 = "x", type = "rate")
for (sd in 1:2) {
	t0 <- Sys.time()
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, modelType = c(net = 6))
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA seed %d: %.1f s rates=%s density=%.3f RateX=%.3f\n", sd, as.numeric(Sys.time() - t0, units = "secs"), paste(round(ans$rate, 3), collapse = "/"), ans$theta[1], ans$theta[2]))
}
