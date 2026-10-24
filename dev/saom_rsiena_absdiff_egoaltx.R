# absDiffX and egoXaltX vs nwsaom absdiffx() / egoxaltx(): alcohol (s50a wave 1) as coCovar, s501-s503, density + recip
library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
x <- coCovar(s50a[, 1]); d <- sienaDataCreate(net, x)
for (ef in c("absDiffX", "egoXaltX")) {
	e <- getEffects(d); e <- includeEffects(e, recip)
	e <- do.call(includeEffects, list(e, as.name(ef), interaction1 = "x"))
	for (sd in 1:3) {
		alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
		ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
		cat(sprintf("COVX %s seed %d: targets %s | est %s\n", ef, sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
	}
}
