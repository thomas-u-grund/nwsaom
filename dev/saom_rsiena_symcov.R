# RSiena covariate effects for a non-directed (symmetric) relation: statistics and estimates, covariate age (_cov.csv), data sym_w1..3.csv
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
cv <- read.csv("_cov.csv")
age <- coCovar(cv$age)
d <- sienaDataCreate(net, age)
efs <- strsplit(Sys.getenv("EFFS"), " ")[[1]]
for (ef in efs) {
	e <- getEffects(d)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'age')", ef)))
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = d, effects = fx, batch = TRUE, silent = TRUE), silent = TRUE)
	if (!inherits(tg, "try-error")) cat("RTGT", ef, round(tg$targets, 3), "\n")
	r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
	cat("RSIENA", ef, ":", gsub("\n", " ", r), "\n")
}
