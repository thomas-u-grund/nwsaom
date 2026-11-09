# Example 4 in RSiena 1.6.14: sienaTimeTest() and the score test (test = TRUE) after a fit with three groups, ten seeds.
# Run from the replication folder: Rscript R/05_groups_ex4.R   (reads data/groups; writes results/groups/ex4_rsiena.csv)
source("R/common.R")
invisible(out_dir("groups"))
act <- read.csv("data/groups/s50g_actors.csv")
W   <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("data/groups/s50g_wave%d.csv", w), header = FALSE)))
grp <- act$group
# centred covariate: RSiena centres it at the mean over all groups, as nwsaom does
mk <- function(g) {
  i <- which(grp == g)
  net <- sienaDependent(array(unlist(lapply(W, function(m) m[i, i])), dim = c(length(i), length(i), 3)), allowOnly = FALSE)
  alc <- coCovar(act$alc[i], centered = TRUE)
  sienaDataCreate(net, alc)
}
gd <- sienaGroupCreate(lapply(1:3, mk))
res <- NULL
for (s in 1:10) {
  # time test: all four effects free
  eff <- getEffects(gd)
  eff <- includeEffects(eff, transTrip)
  eff <- includeEffects(eff, egoX, altX, interaction1 = "alc")
  alg <- sienaAlgorithmCreate(projname = NULL, cond = FALSE, seed = s, n3 = 1000, nsub = 4)
  a  <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = TRUE)
  tt <- sienaTimeTest(a)
  res <- rbind(res, data.frame(seed = s, what = "joint", k = 0, c = tt$JointTestStatistics$testresOverall, df = sum(tt$EffectTest[, 2])))
  res <- rbind(res, data.frame(seed = s, what = "effect", k = seq_len(nrow(tt$EffectTest)), c = tt$EffectTest[, 1], df = tt$EffectTest[, 2]))
  res <- rbind(res, data.frame(seed = s, what = "group", k = seq_len(nrow(tt$GroupTest)), c = tt$GroupTest[, 1], df = tt$GroupTest[, 2]))
  # score test: egoX and altX of alc fixed at 0 and tested
  eff2 <- getEffects(gd)
  eff2 <- includeEffects(eff2, transTrip)
  eff2 <- includeEffects(eff2, egoX, altX, interaction1 = "alc", fix = TRUE, test = TRUE)
  b <- siena07(alg, data = gd, effects = eff2, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = FALSE)
  res <- rbind(res, data.frame(seed = s, what = "score", k = 0, c = b$testresOverall, df = sum(b$test)))
}
write.csv(res, "results/groups/ex4_rsiena.csv", row.names = FALSE)
print(aggregate(c ~ what + k, res, mean))
