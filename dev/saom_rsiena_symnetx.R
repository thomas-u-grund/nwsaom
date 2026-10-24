library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
cv <- read.csv("_cov.csv")
age <- coCovar(cv$age); agep <- coCovar(cv$age + 1, centered = FALSE)
d <- sienaDataCreate(net, age, agep)
efs <- strsplit(Sys.getenv("EFFS"), " ")[[1]]
for (ef in efs) {
	cov <- if (ef == "homXOutAct2") "agep" else "age"
	e <- getEffects(d)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = '%s')", ef, cov)))
	x <- unclass(e); k <- which(x$shortName == ef & x$include & x$type == "eval")
	if (ef %in% c("homXOutAct2", "outXMore")) e$parm[k] <- 1
	r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 500, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
	cat("RSIENA", ef, ":", gsub("\n", " ", r), "\n")
}
