# undirected co-evolution, simpler behavior part: linear + avAlt (no quad); each seed guarded
library(RSiena)
data(s50a)
w <- lapply(1:2, function(i) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", i))))
net <- sienaDependent(array(unlist(w), dim = c(50, 50, 2)))
alc <- sienaDependent(s50a[, 1:2], type = "behavior")
d <- sienaDataCreate(net, alc)
e <- getEffects(d)
e <- includeEffects(e, quad, name = "alc", include = FALSE)
e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
for (sd in 1:4) {
	t0 <- Sys.time()
	r <- tryCatch({
		alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, modelType = c(net = 6))
		ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
		paste(round(c(ans$rate, ans$theta), 3), collapse = " ")
	}, error = function(err) paste("ERROR:", conditionMessage(err)))
	cat(sprintf("RSIENA2 seed %d %.1f s: %s\n", sd, as.numeric(Sys.time() - t0, units = "secs"), r))
}
