# Example 1 in RSiena 1.6.14: four school classes, one joint model (sienaGroupCreate + siena07), ten seeds.
# Run from the replication folder: Rscript R/03_groups_ex1.R   (reads data/groups; writes results/groups/ex1_rsiena.csv)
source("R/common.R")
invisible(out_dir("groups"))
rd <- function(f) { m <- as.matrix(read.csv(f, header = FALSE)); diag(m) <- 0; m }
mk <- function(s) {
  net <- sienaDependent(array(c(rd(sprintf("data/groups/school%d_wave1.csv", s)), rd(sprintf("data/groups/school%d_wave2.csv", s))),
                              dim = c(nrow(rd(sprintf("data/groups/school%d_wave1.csv", s))), nrow(rd(sprintf("data/groups/school%d_wave1.csv", s))), 2)))
  sienaDataCreate(net)
}
gd  <- sienaGroupCreate(lapply(1:4, mk))
eff <- getEffects(gd)
eff <- includeEffects(eff, recip, transTrip)
res <- NULL
for (s in 1:10) {
  alg <- sienaAlgorithmCreate(projname = NULL, seed = s, n3 = 1000, nsub = 4)
  a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = FALSE)
  ef <- a$effects[a$effects$include, ]
  nm <- c(ef$effectName[ef$type == "eval"], paste0("rate", seq_along(a$rate)))
  th <- data.frame(seed = s, name = ef$effectName, theta = a$theta, se = sqrt(diag(a$covtheta)))
  if (a$cconditional) th <- rbind(data.frame(seed = s, name = paste("rate", seq_along(a$rate)), theta = a$rate, se = sqrt(a$vrate)), th)
  res <- rbind(res, th)
}
write.csv(res, "results/groups/ex1_rsiena.csv", row.names = FALSE)
print(aggregate(cbind(theta, se) ~ name, res, mean))
