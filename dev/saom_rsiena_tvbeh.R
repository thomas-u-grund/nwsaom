# RSiena effFrom / avXAlt / totSameXAlt with a CHANGING covariate (varCovar) on the behavior, s50 + alcohol
library(RSiena)
tv <- read.csv(Sys.getenv("TVCSV", "_tv.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
v <- varCovar(as.matrix(tv[, c("v1", "v2")]))
d <- sienaDataCreate(net, beh, v)
for (ef in c("effFrom", "avXAlt", "totSameXAlt")) {
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	if (ef == "effFrom") e <- includeEffects(e, effFrom, name = "beh", interaction1 = "v")
	else e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = 'v', interaction2 = 'net')", ef)))
	for (sd in 1:3) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
