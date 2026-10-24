library(RSiena)
data(s501); data(s502); data(s503)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- getEffects(d)
e <- includeEffects(e, recip, inPop, outPop, outActSqrt)
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- try(siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE), silent = TRUE)
	if (inherits(ans, "try-error")) { cat("RSIENA failed\n"); next }
	cat(sprintf("RSIENA seed %d targets: %s\n  est: %s\n  names: %s\n", sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(ans$effects$effectName, collapse = " | ")))
}
