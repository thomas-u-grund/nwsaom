# RSiena two dependent networks: s50 friendship (net) + a second network (adv, built from net with noise), cross-network effects of adv on net.
# Writes dev/saom_mn_b1..3.csv once. EFFS = cross effects (shortNames); PARM optional parameter.
library(RSiena)
if (!file.exists("dev/saom_mn_b1.csv")) {
	set.seed(5151)
	A <- list(s501, s502, s503)
	B <- list()
	prev <- NULL
	for (w in 1:3) {
		base <- A[[w]]
		bb <- matrix(0, 50, 50)
		pick <- matrix(runif(2500) < 0.45, 50, 50)
		noise <- matrix(runif(2500) < 0.03, 50, 50)
		bb <- (base * pick) + noise
		if (!is.null(prev)) bb <- ((prev * (matrix(runif(2500) < 0.7, 50, 50))) + bb) > 0
		bb <- (bb > 0) * 1; diag(bb) <- 0
		B[[w]] <- bb; prev <- bb
		write.csv(bb, sprintf("dev/saom_mn_b%d.csv", w), row.names = FALSE)
	}
}
Bm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn_b%d.csv", w))))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
adv <- sienaDependent(array(unlist(Bm), dim = c(50, 50, 3)))
d <- sienaDataCreate(net, adv)
for (ef in strsplit(Sys.getenv("EFFS", "crprod"), " ")[[1]]) {
	e <- getEffects(d)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'net', interaction1 = 'adv')", ef)))
	pm <- Sys.getenv("PARM", "")
	if (pm != "") { x <- unclass(e); k <- which(x$shortName == ef & x$include & x$name == "net"); e$parm[k] <- as.numeric(pm) }
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
