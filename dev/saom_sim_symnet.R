# network-only undirected simulation check of the rate scale: RSiena BJOINT, rate 4, outdegree -1.4 from symmetrized s50 wave 1
library(RSiena)
w1 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w1.csv")); w2 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w2.csv"))
net <- sienaDependent(array(c(w1, w2), dim = c(50, 50, 2)))
d <- sienaDataCreate(net)
e <- getEffects(d)
e$initialValue[e$shortName == "Rate"] <- 4
e$initialValue[e$shortName == "density"] <- -1.4
alg <- sienaAlgorithmCreate(projname = NULL, seed = 7, cond = FALSE, nsub = 0, n3 = 20, simOnly = TRUE, modelType = c(net = 6))
ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE, returnDeps = TRUE)
for (r in seq_along(ans$sims)) {
	m <- matrix(0, 50, 50); el <- ans$sims[[r]][[1]]$net[[1]]; m[el[, 1:2, drop = FALSE]] <- 1
	write.csv(m, sprintf("dev/saom_sim_symnet_%d.csv", r), row.names = FALSE)
}
