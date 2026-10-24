library(RSiena)
w1 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w1.csv")); a1 <- read.csv("dev/saom_sim_symcoev_alc1.csv")$a1
for (r in c(13, 40, 4, 9)) {
	m <- as.matrix(read.csv(sprintf("dev/saom_sim_symcoev2_%d_net.csv", r))); b <- read.csv(sprintf("dev/saom_sim_symcoev2_%d_beh.csv", r))$b
	net <- sienaDependent(array(c(w1, unname(m)), dim = c(50, 50, 2)))
	alc <- sienaDependent(cbind(a1, b), type = "behavior")
	d <- sienaDataCreate(net, alc); e <- getEffects(d)
	e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net"); e <- includeEffects(e, quad, name = "alc", include = FALSE)
	t0 <- Sys.time()
	alg <- sienaAlgorithmCreate(projname = NULL, seed = r, n3 = 500, nsub = 3, modelType = c(net = 6))
	ans <- try(siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE), silent = TRUE)
	if (inherits(ans, "try-error")) cat(sprintf("RS rep %d: failed: %s\n", r, substr(ans, 1, 80)))
	else cat(sprintf("RS rep %d (%.0fs): est %s\n", r, as.numeric(Sys.time() - t0, units = "secs"), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
