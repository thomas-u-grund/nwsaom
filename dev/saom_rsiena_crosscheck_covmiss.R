# Cross-check nwsaom's handling of MISSING covariate values (altX/egoX/sameX/simX
# = nodeicov/nodeocov/nodematch/simcov) against real RSiena, on s501/s502 with the
# s50a alcohol wave-1 value as a constant covariate, 8 of its 50 values set to NA.
library(RSiena)
data(s501); data(s502); data(s50a)
cov1 <- s50a[, 1]
na_idx <- c(3, 9, 14, 21, 28, 33, 40, 47)
cov1[na_idx] <- NA
write.csv(s501, "dev/saom_rsiena_covmiss_wave1.csv", row.names = FALSE)
write.csv(s502, "dev/saom_rsiena_covmiss_wave2.csv", row.names = FALSE)
write.csv(data.frame(x = cov1), "dev/saom_rsiena_covmiss_cov.csv", row.names = FALSE, na = "-999")

net <- sienaDependent(array(c(s501, s502), dim = c(50, 50, 2)))
x <- coCovar(cov1)
d <- sienaDataCreate(net, x)
eff <- getEffects(d)
eff <- includeEffects(eff, recip)
eff <- includeEffects(eff, altX, egoX, simX, interaction1 = "x")
res <- list()
for (sd in 1:4) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 2000, useStdInits = FALSE, nsub = 4, cond = FALSE)
	ans <- siena07(alg, data = d, effects = eff, batch = TRUE, silent = TRUE, returnDeps = FALSE)
	res[[sd]] <- c(rate = ans$rate, ans$theta)
}
m <- do.call(rbind, res)
print(m)
cat("MEAN\n"); print(colMeans(m))
cat("SD\n"); print(apply(m, 2, sd))
print(as.data.frame(eff)[as.data.frame(eff)$include, c("shortName", "interaction1")])
