# RSiena: behavior effects with ANOTHER co-evolving behavior (smoking) as the covariate of the alcohol effects, s50 + alcohol + smoking
library(RSiena)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
alc <- sienaDependent(s50a, type = "behavior")
smk <- sienaDependent(s50s, type = "behavior")
d <- sienaDataCreate(net, alc, smk)
for (ef in strsplit(Sys.getenv("EFFS", "avXAlt"), " ")[[1]]) {
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
	e <- includeEffects(e, avAlt, name = "smk", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'alc', interaction1 = 'smk', interaction2 = 'net')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
