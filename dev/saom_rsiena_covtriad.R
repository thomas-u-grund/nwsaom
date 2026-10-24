# RSiena covariate x triad / popularity / activity effects (s50, no behavior; covariate age from _cov.csv)
library(RSiena)
cv <- read.csv(Sys.getenv("COVCSV", "_cov.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
age <- coCovar(cv$age)
d <- sienaDataCreate(net, age)
efs <- strsplit(Sys.getenv("EFFS", "sameXTransTrip diffXTransTrip simXTransTrip homXTransTrip sameXOutAct diffXOutAct sameXReciAct diffXReciAct homXOutAct altXOutAct inPopX outPopX inActX outActX sameXInPop diffXInPop"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'age')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
