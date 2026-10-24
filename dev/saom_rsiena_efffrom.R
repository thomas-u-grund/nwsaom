# RSiena effFrom (covariate main effects on the behavior) with two covariates, s50 + alcohol
library(RSiena)
cv <- read.csv(Sys.getenv("COVCSV", "_cov.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
g <- coCovar(cv$g)
age <- coCovar(cv$age)
d <- sienaDataCreate(net, beh, g, age)
e <- includeEffects(getEffects(d), recip)
e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
e <- includeEffects(e, effFrom, name = "beh", interaction1 = "g")
e <- includeEffects(e, effFrom, name = "beh", interaction1 = "age")
for (sd in 1:3) {
	r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
		sprintf("targets %s est %s names %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(ans$effects$effectName, collapse = " | ")) }, silent = TRUE)
	cat("RSIENA effFrom seed", sd, ":", r, "\n")
}
