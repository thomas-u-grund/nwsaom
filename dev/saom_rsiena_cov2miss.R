library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
x <- s50a[, 1]; set.seed(5); x[sample(50, 7)] <- NA
write.csv(data.frame(am = x), "dev/saom_rsiena_cov2miss_cov.csv", row.names = FALSE, na = ".")
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net, alc = coCovar(x))
for (ef in c("absDiffX", "egoXaltX", "diffX", "higher", "egoSqX", "altSqX", "sameXRecip", "simRecipX")) {
	e <- includeEffects(getEffects(d), recip)
	e <- do.call(includeEffects, list(e, as.name(ef), interaction1 = "alc"))
	r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
		sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
	cat("RSIENA", ef, ":", r, "\n")
}
