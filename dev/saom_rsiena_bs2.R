# RSiena behavior effects of the network x a covariate (avXInAlt ... degNegContrX), s50 + alcohol, covariate age from _cov.csv
library(RSiena)
cv <- read.csv(Sys.getenv("COVCSV", "_cov.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
age <- coCovar(cv$age)
d <- sienaDataCreate(net, beh, age)
efs <- strsplit(Sys.getenv("EFFS", "avXInAlt totXInAlt avXRecAlt totXRecAlt avSameXInAlt totSameXInAlt avSameXRecAlt totSameXRecAlt avAltSameX totAltSameX avRecAltSameX totRecAltSameX avAltAltX avSimAltX totSimAltX minXAlt maxXAlt degAbsContrX degPosContrX degNegContrX"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = 'age', interaction2 = 'net')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
