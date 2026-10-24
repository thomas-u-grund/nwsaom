# RSiena further covariate network effects (crossXOutAct ... sameEgoInDist2), s50, covariate age (+1 for homXOutAct2) from _cov.csv
library(RSiena)
cv <- read.csv("_cov.csv")
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
age <- coCovar(cv$age); agep <- coCovar(cv$age + 1, centered = FALSE)
d <- sienaDataCreate(net, age, agep)
efs <- strsplit(Sys.getenv("EFFS", "crossXOutAct homXOutAct2 outXMore IndTies transTripX jumpXTransTrip altDist2 totDist2 simDist2 simEgoDist2 sameEgoDist2 altInDist2 totInDist2 simEgoInDist2 sameEgoInDist2"), " ")[[1]]
for (ef in efs) {
	cov <- if (ef == "homXOutAct2") "agep" else "age"
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = '%s')", ef, cov)))
	x <- unclass(e); k <- which(x$shortName == ef & x$include & x$type == "eval")
	if (ef %in% c("homXOutAct2", "outXMore")) e$parm[k] <- 1
	cat("PARM", ef, e$parm[k], "\n")
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = d, effects = fx, batch = TRUE, silent = TRUE), silent = TRUE)
	if (!inherits(tg, "try-error")) cat("RTGT", ef, round(tg$targets, 3), "\n")
	r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
	cat("RSIENA", ef, ":", gsub("\n", " ", r), "\n")
}
