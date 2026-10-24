library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net, alc = coCovar(s50a[, 1]))
for (ef in c("altX", "egoX", "sameX", "simX")) {
	e <- includeEffects(getEffects(d), recip)
	r <- try({
		e <- do.call(includeEffects, list(e, as.name(ef), interaction1 = "alc", type = "endow"))
		e <- do.call(includeEffects, list(e, as.name(ef), interaction1 = "alc", type = "creation"))
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
		sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
	cat("RSIENA", ef, ":", r, "\n")
}
