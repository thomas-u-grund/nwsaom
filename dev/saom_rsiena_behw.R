# RSiena behavior effects of the network x a constant dyadic covariate (avAltW ... totSimW), s50 + alcohol
library(RSiena)
m <- as.matrix(read.csv("dev/saom_rsiena_dyadcov_m.csv"))
dimnames(m) <- NULL
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a[, 1:3], type = "behavior")
dc <- coDyadCovar(m)
d <- sienaDataCreate(net, beh, dc)
for (ef in strsplit(Sys.getenv("EFFS", "avAltW totAltW avInAltW totInAltW avWAlt totWAlt avWInAlt totWInAlt avSimW totSimW"), " ")[[1]]) {
	e <- includeEffects(getEffects(d), recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = 'net', interaction2 = 'dc')", ef)))
	if (Sys.getenv('PARM', '') != '') e <- eval(parse(text = sprintf("setEffect(e, %s, name = 'beh', interaction1 = 'net', interaction2 = 'dc', parameter = %s)", ef, Sys.getenv('PARM'))))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", r, "\n")
	}
}
