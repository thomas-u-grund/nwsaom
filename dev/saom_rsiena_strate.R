# RSiena structural rate effects (outRate, inRate, recipRate, outRateInv, outRateLog, inRateInv, inRateLog, recipRateInv, recipRateLog), s50
library(RSiena)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
efs <- strsplit(Sys.getenv("EFFS", "outRate inRate recipRate outRateInv outRateLog inRateInv inRateLog recipRateInv recipRateLog"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, type = 'rate')", ef)))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = TRUE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
