# Simulation study for undirected co-evolution: RSiena simulates (BJOINT, modelType 6) from KNOWN parameters starting at
# the symmetrized s50 wave 1 + alcohol; nwsaom re-estimates each replicate (dev/saom_sim_symcoev.do); the mean estimate
# should recover the truth. Writes dev/saom_sim_symcoev_<r>_{net,beh}.csv and the truth.
library(RSiena)
data(s50a)
w1 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w1.csv")); w2 <- as.matrix(read.csv("dev/saom_rsiena_symmulti_w2.csv"))
net <- sienaDependent(array(c(w1, w2), dim = c(50, 50, 2)))
alc <- sienaDependent(s50a[, 1:2], type = "behavior")
d <- sienaDataCreate(net, alc)
e <- getEffects(d)
e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
truth <- c(rate_net = 0.6, rate_beh = 1.5, outdegree = -1.4, linear = 0.3, quad = -0.2, avalt = 1.5)
set <- function(sn, nm, v, type = "eval") e$initialValue[e$shortName == sn & e$name == nm & e$type == type] <<- v
set("Rate", "net", truth["rate_net"], "rate"); set("Rate", "alc", truth["rate_beh"], "rate")
set("density", "net", truth["outdegree"]); set("linear", "alc", truth["linear"]); set("quad", "alc", truth["quad"]); set("avAlt", "alc", truth["avalt"])
alg <- sienaAlgorithmCreate(projname = NULL, seed = 123, cond = FALSE, nsub = 0, n3 = 40, simOnly = TRUE, modelType = c(net = 6))
ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE, returnDeps = TRUE)
write.csv(as.data.frame(t(truth)), "dev/saom_sim_symcoev_truth.csv", row.names = FALSE)
for (r in seq_along(ans$sims)) {
	s <- ans$sims[[r]][[1]]
	m <- matrix(0, 50, 50); el <- s$net[[1]]; m[el[, 1:2, drop = FALSE]] <- 1
	write.csv(m, sprintf("dev/saom_sim_symcoev_%d_net.csv", r), row.names = FALSE)
	write.csv(data.frame(b = s$alc[[1]]), sprintf("dev/saom_sim_symcoev_%d_beh.csv", r), row.names = FALSE)
}
cat("replicates", length(ans$sims), " symmetric check:", all(sapply(1:3, function(r) { m <- as.matrix(read.csv(sprintf("dev/saom_sim_symcoev_%d_net.csv", r))); isSymmetric(unname(m)) })), "\n")
