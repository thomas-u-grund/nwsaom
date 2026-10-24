# RSiena avXAlt, avSameXAlt, totXAlt, totSameXAlt (covariate-moderated influence), s50 + alcohol
library(RSiena)
cv <- read.csv(Sys.getenv("COVCSV", "_cov.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
g <- coCovar(cv$g)
age <- coCovar(cv$age)
d <- sienaDataCreate(net, beh, g, age)
for (ef in c("avXAlt:age", "avSameXAlt:age", "totXAlt:g", "totSameXAlt:age")) {
	pr <- strsplit(ef, ":")[[1]]
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = '%s', interaction2 = 'net')", pr[1], pr[2])))
	for (sd in 1:3) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
