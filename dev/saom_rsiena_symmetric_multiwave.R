# nwsaom `symmetric` with 3 waves (waves()) against RSiena: s501-s503 forced symmetric by OR
# with the reverse, BJOINT (modelType 6), density + transTies, 4 seeds.
library(RSiena)
data(s501); data(s502); data(s503)
sy <- function(x) { x <- as.matrix(x); x[is.na(x)] <- 0; m <- ((x | t(x)) * 1); diag(m) <- 0; m }
w <- list(sy(s501), sy(s502), sy(s503))
for (i in 1:3) write.csv(w[[i]], sprintf("dev/saom_rsiena_symmulti_w%d.csv", i), row.names = FALSE)
net <- sienaDependent(array(unlist(w), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
eff <- getEffects(d)
eff <- includeEffects(eff, transTies)
res <- list()
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, modelType = c(net = 6))
	ans <- siena07(alg, data = d, effects = eff, batch = TRUE, silent = TRUE)
	res[[sd]] <- c(ans$rate, ans$theta)
}
m <- do.call(rbind, res); print(round(m, 3)); cat("MEAN\n"); print(round(colMeans(m), 3)); cat("SD\n"); print(round(apply(m, 2, sd), 3))
