# transTies endowment/creation (3 waves, directed): s501-s503; density + recip eval + transTies endow + creation
library(RSiena)
data(s501); data(s502); data(s503)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- getEffects(d)
e <- includeEffects(e, recip)
e <- includeEffects(e, transTies, type = "endow")
e <- includeEffects(e, transTies, type = "creation")
res <- list()
for (sd in 1:3) {
	t0 <- Sys.time()
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	res[[sd]] <- c(ans$rate, ans$theta)
	cat(sprintf("RSIENA seed %d %.1f s: %s\n", sd, as.numeric(Sys.time() - t0, units = "secs"), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
print(as.data.frame(e)[as.data.frame(e)$include, c("shortName", "type")])
