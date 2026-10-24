# RSiena changing (varCovar) covariate versions of the network covariate effects, s50, covariate from _tv.csv (v1, v2)
library(RSiena)
tv <- read.csv(Sys.getenv("TVCSV", "_tv.csv"))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
v <- varCovar(as.matrix(tv[, c("v1", "v2")]))
d <- sienaDataCreate(net, v)
efs <- strsplit(Sys.getenv("EFFS", "absDiffX egoXaltX diffX higher egoSqX altSqX sameXTransTrip altXOutAct inPopX egoPlusAltSqX unequalX degAbsDiffX egoLThresholdX"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), recip)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'v')", ef)))
	if (ef == "outXMore") { x <- unclass(e); k <- which(x$shortName == ef & x$include); e$parm[k] <- 1 }
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = d, effects = fx, batch = TRUE, silent = TRUE), silent = TRUE)
	if (!inherits(tg, "try-error")) cat("RTGT", ef, round(tg$targets, 3), "\n")
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
