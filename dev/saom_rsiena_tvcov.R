# time-varying covariates (RSiena varCovar): alcohol as a changing covariate (waves 1-2 = periods 1-2), s50 network
library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
alc <- varCovar(s50a[, 1:2])
d <- sienaDataCreate(net, alc)
e <- getEffects(d)
e <- includeEffects(e, recip, transTrip)
e <- includeEffects(e, egoX, altX, simX, sameX, interaction1 = "alc")
print(as.data.frame(e)[as.data.frame(e)$include, c("shortName", "interaction1")])
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA seed %d targets: %s\n  est: %s\n  names: %s\n", sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(ans$effects$effectName, collapse = " | ")))
}
