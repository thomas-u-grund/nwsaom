# dyadic covariates (X, XRecip) vs nwsaom dyadcov() / dyadcovrecip(): covariate = |alcohol_i - alcohol_j| (s50a, wave 1);
# cell NAs for the "missing" variant. 3 waves s501-s503, density + recip + the covariate effect.
library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
a <- s50a[, 1]; m <- abs(outer(a, a, "-")); diag(m) <- 0
set.seed(7); mm <- m; mm[sample(which(row(m) != col(m)), 120)] <- NA
write.csv(m, "dev/saom_rsiena_dyadcov_m.csv", row.names = FALSE)
write.csv(mm, "dev/saom_rsiena_dyadcov_mmiss.csv", row.names = FALSE, na = "")
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
run <- function(label, mat, eff) {
	dc <- coDyadCovar(mat)
	d <- sienaDataCreate(net, dc)
	e <- getEffects(d); e <- includeEffects(e, recip)
	e <- do.call(includeEffects, list(e, as.name(eff), interaction1 = "dc"))
	for (sd in 1:3) {
		alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
		ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
		cat(sprintf("DYAD %s seed %d: targets %s | est %s\n", label, sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
	}
}
run("X", m, "X"); run("XRecip", m, "XRecip"); run("Xmiss", mm, "X")
