library(RSiena)
W <- lapply(1:3, function(w) { x <- as.matrix(read.csv(sprintf("dev/saom_rsiena_balmiss_w%d.csv", w))); m <- as.matrix(read.csv(sprintf("dev/saom_rsiena_balmiss_m%d.csv", w))); x[m == 1] <- NA; unname(x) })
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- includeEffects(getEffects(d), recip)
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA-simple seed %d est: %s\n", sd, paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
