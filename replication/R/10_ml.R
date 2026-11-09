# Section 6.3 (maximum-likelihood and Bayesian estimation): RSiena's maximum-likelihood estimates of the model outdegree, reciprocity,
# transitive triplets on the three Glasgow waves (seeds 1 to 3), which the article compares with nwsaom's
# (article/gen_logs.do, extras.log: nwsaom ..., ml seed(1) and seed(2)). Prints the estimates, standard errors
# and times. Run from the replication folder: Rscript R/10_ml.R   (about 15 minutes)
source("R/common.R")
sink(file.path(out_dir("ml"), "rsiena_ml.txt"), split = TRUE)
clean <- function(x) { x[x > 1] <- 0; x }
w <- lapply(list(s501, s502, s503), clean)
net3 <- sienaDependent(array(unlist(w), dim = c(50, 50, 3)))
d <- sienaDataCreate(friendship = net3)
e <- includeEffects(getEffects(d), recip, transTrip)
for (s in 1:3) {
  invisible(capture.output(a <- sienaAlgorithmCreate(projname = NULL, seed = s, maxlike = TRUE, cond = FALSE)))  # drops the message naming a temporary file
  t0 <- proc.time()[3]
  ans <- siena07(a, data = d, effects = e, batch = TRUE, silent = TRUE)
  cat("ML seed", s, "time", proc.time()[3] - t0, "\n"); print(round(rbind(est = ans$theta, se = sqrt(diag(ans$covtheta))), 3))
}
sink()
