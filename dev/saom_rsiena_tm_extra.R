# RSiena bipartite effects (degree functions, centred, covariate-weighted) on the 40 x 20 data of saom_rsiena_twomode_sim.R
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_twomode_w%d.csv", w))))
A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
dep <- sienaDependent(array(unlist(W), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
c1 <- coCovar(read.csv("dev/saom_twomode_cvA.csv")$ega, nodeSet = "A"); c2 <- coCovar(read.csv("dev/saom_twomode_cvB.csv")$altb, nodeSet = "B")
dat <- sienaDataCreate(dep, c1, c2, nodeSets = list(A, B))
specs <- strsplit(Sys.getenv("SPECS", "outTrunc:2:- outMore:2:- outThreshold:2:- outInv:1:- outSqInv:1:- inPop:0:- outActSqrt:0:- inPop.c:0:- outAct.c:0:- sameXInPop:0:c1 diffXInPop:0:c1 inPopX:0:c1 homXOutAct:0:c2 altXOutAct:0:c2 outActX:0:c2 egoLThresholdX:0:c1 egoRThresholdX:0:c1 altLThresholdX:0:c2 altRThresholdX:0:c2 degAbsDiffX:0:c1 degPosDiffX:0:c1 degNegDiffX:0:c1"), " ")[[1]]
for (sp in specs) {
	pr <- strsplit(sp, ":")[[1]]
	e <- getEffects(dat)
	if (pr[3] == "-") e <- eval(parse(text = sprintf("includeEffects(e, %s)", pr[1])))
	else e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = '%s')", pr[1], pr[3])))
	if (pr[2] != "0") { x <- unclass(e); k <- which(x$shortName == pr[1] & x$include & x$type == "eval"); e$parm[k] <- as.integer(pr[2]) }
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = dat, effects = fx, batch = TRUE, silent = TRUE), silent = TRUE)
	if (!inherits(tg, "try-error")) cat("RTGT", sp, round(tg$targets, 3), "\n")
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 500, nsub = 4, cond = FALSE), data = dat, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", sp, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
