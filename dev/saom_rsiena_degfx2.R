library(RSiena)
data(s501); data(s502); data(s503)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- includeEffects(getEffects(d), recip, inAct)
for (sd in 1:3) {
	ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA-inAct seed %d targets: %s est: %s\n", sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
