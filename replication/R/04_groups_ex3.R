# Example 3 in RSiena 1.6.14: (a) co-evolution of friendship and alcohol use in three groups, (b) groups with different numbers of waves.
# Run from the replication folder: Rscript R/04_groups_ex3.R   (reads data/groups; writes results/groups/ex3a_rsiena.csv and ex3b_rsiena.csv)
# RSiena 1.6.14 stops (INTEGER() ... not a 'list') for a group object whose groups have different numbers of waves. Part (b) is therefore
# run on the equivalent object: group 1 (waves 1,2,3) becomes two groups of the same actors (waves 1,2 and waves 2,3), group 2 has waves 1,2
# and group 3 waves 2,3. Without covariates and without effects that use group constants the model is the same, period by period.
source("R/common.R")
invisible(out_dir("groups"))
act <- read.csv("data/groups/s50g_actors.csv")
W   <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("data/groups/s50g_wave%d.csv", w), header = FALSE)))
grp <- act$group
alcm <- as.matrix(act[, c("alc1", "alc2", "alc3")])
mk <- function(g, ws, behavior) {
  i <- which(grp == g)
  net <- sienaDependent(array(unlist(lapply(ws, function(w) W[[w]][i, i])), dim = c(length(i), length(i), length(ws))), allowOnly = FALSE)
  alc <- sienaDependent(alcm[i, ws, drop = FALSE], type = "behavior", allowOnly = FALSE)
  if (behavior) sienaDataCreate(net, alc)
  else sienaDataCreate(net)
}
run <- function(gd, eff, tag) {
  res <- NULL
  for (s in 1:10) {
    alg <- sienaAlgorithmCreate(projname = NULL, seed = s, n3 = 1000, nsub = 4)
    a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = FALSE)
    ef <- a$effects[a$effects$include, ]
    th <- data.frame(seed = s, name = ef$effectName, theta = a$theta, se = sqrt(diag(a$covtheta)))
    if (a$cconditional) th <- rbind(data.frame(seed = s, name = paste("rate", seq_along(a$rate)), theta = a$rate, se = sqrt(a$vrate)), th)
    res <- rbind(res, th)
  }
  write.csv(res, sprintf("results/groups/ex3%s_rsiena.csv", tag), row.names = FALSE)
  print(aggregate(cbind(theta, se) ~ name, res, mean))
}
# (a) three groups, three waves, network and behavior
gd  <- sienaGroupCreate(lapply(1:3, function(g) mk(g, 1:3, TRUE)))
eff <- getEffects(gd)
eff <- includeEffects(eff, transTrip)
eff <- includeEffects(eff, egoX, altX, interaction1 = "alc")
eff <- includeEffects(eff, avAlt, name = "alc", interaction1 = "net")
run(gd, eff, "a")
# (b) unequal waves, network only: equivalent object (see above)
gd2  <- sienaGroupCreate(list(mk(1, 1:2, FALSE), mk(1, 2:3, FALSE), mk(2, 1:2, FALSE), mk(3, 2:3, FALSE)))
eff2 <- getEffects(gd2)
eff2 <- includeEffects(eff2, transTrip)
run(gd2, eff2, "b")
