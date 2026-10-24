library(RSiena)
w1 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w1.csv"))
for (r in c(2, 3, 9)) {
	m <- as.matrix(read.csv(sprintf("dev/saom_sim_symnet_%d.csv", r)))
	n2 <- sienaDependent(array(c(w1, unname(m)), dim = c(50, 50, 2)))
	dd <- sienaDataCreate(n2); ee <- getEffects(dd)
	t0 <- Sys.time()
	a2 <- sienaAlgorithmCreate(projname = NULL, seed = r, cond = FALSE, n3 = 500, nsub = 3, modelType = c(n2 = 6))
	an <- siena07(a2, data = dd, effects = ee, batch = TRUE, silent = TRUE)
	cat(sprintf("RS rep %d (%.0fs): rate %.3f outdeg %.3f  | changes w1->w2: %d\n", r, as.numeric(Sys.time() - t0, units = "secs"), an$rate, an$theta, sum(abs(w1 - m)) / 2))
}
