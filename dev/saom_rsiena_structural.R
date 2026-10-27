# Reference for structural zeros and ones (RSiena codes 10 and 11 in the wave networks), RSiena 1.6.14, on the s50 data.
# Usage: Rscript dev/saom_rsiena_structural.R <outdir> <variant> <task> [seeds] [n3]
# variants: v1 (two classes, cross-class dyads 10 in all waves), v2 (3% dyads 11 and 5% dyads 10, the same in all waves),
#           v3 (structural flags independent per wave with probability 0.03, value 10 or 11), v3s (changing sets, a few designed cases),
#           v5 (v3 plus missing ties in wave 2, via NA), v0 (no structural values)
# tasks: data (write w1.csv .. w3.csv, the coded waves)
#        targets (siena07 nsub=0, n3=1: the targets of the standard effect list, per period and summed; prints TARGET lines; distance and counts)
#        sim (simOnly with fixed theta and rates, n3 simulations, `seeds` seeds: prints mean and sd of the simulated statistics and of the rate statistics)
#        est (conditional/unconditional estimation with `seeds` seeds)
suppressMessages(library(RSiena))
args <- commandArgs(TRUE)
out <- args[1]; variant <- args[2]; task <- args[3]
nseed <- if (length(args) >= 4) as.integer(args[4]) else 8
n3 <- if (length(args) >= 5) as.integer(args[5]) else 500
dir.create(out, showWarnings = FALSE, recursive = TRUE)
base <- lapply(list(s501, s502, s503), function(m) { m[is.na(m)] <- 0; m })
n <- 50
set.seed(20261027)
mk <- function(variant) {
  w <- base
  if (variant == 'v1') {
    cls <- c(rep(1, 25), rep(2, 25))
    for (k in 1:3) { m <- w[[k]]; m[outer(cls, cls, "!=")] <- 10; w[[k]] <- m }
  }
  if (variant == 'v2') {
    d <- which(row(diag(n)) != col(diag(n)), arr.ind = TRUE)
    pick <- sample(nrow(d), round(0.08 * nrow(d)))
    one <- pick[1:round(0.03 * nrow(d))]; zero <- setdiff(pick, one)
    for (k in 1:3) { m <- w[[k]]; m[d[one, ]] <- 11; m[d[zero, ]] <- 10; w[[k]] <- m }
  }
  if (variant %in% c('v3', 'v5')) {
    d <- which(row(diag(n)) != col(diag(n)), arr.ind = TRUE)
    for (k in 1:3) {
      m <- w[[k]]
      pick <- sample(nrow(d), round(0.03 * nrow(d)))
      val <- sample(c(10, 11), length(pick), replace = TRUE)
      m[d[pick, ]] <- val
      w[[k]] <- m
    }
  }
  if (variant == 'v4') {    # frozen egos: actors 1-6 have every out-dyad structural (code 10, ties of the data kept as structural ones 11) in all waves; actors 7-10 all but 3 out-dyads;
                            # nobody can send to actors 11-13 (in-dyads 10); actor 20 is frozen at wave 2 only
    for (k in 1:3) {
      m <- w[[k]]
      for (a in 1:6) { for (b in 1:n) if (a != b) m[a, b] <- 10 + (m[a, b] == 1) }
      for (a in 7:10) { free <- c(a + 10, a + 11, a + 12); for (b in setdiff(1:n, c(a, free))) m[a, b] <- 10 }
      for (b in 11:13) for (a in setdiff(1:n, b)) if (m[a, b] < 10) m[a, b] <- 10 + (m[a, b] == 1)
      if (k == 2) for (b in setdiff(1:n, 20)) m[20, b] <- 10
      w[[k]] <- m
    }
  }
  if (variant == 'v3s') {   # designed cases: (1,2) 10 at wave 1 only; (3,4) 10 at wave 2 only; (5,6) 10 at wave 1, 11 at wave 2; (7,8) 11 at waves 1 and 2, 10 at wave 3; (9,10) 11 at wave 3 only
    w[[1]][1,2] <- 10; w[[2]][3,4] <- 10; w[[1]][5,6] <- 10; w[[2]][5,6] <- 11; w[[1]][7,8] <- 11; w[[2]][7,8] <- 11; w[[3]][7,8] <- 10; w[[3]][9,10] <- 11
    for (a in 11:30) { w[[1]][a, a + 1] <- 10 + (a %% 2); w[[3]][a + 1, a] <- 10 + (a %% 3 == 0); if (a %% 2 == 0) w[[2]][a, a + 1] <- 11 }
  }
  w
}
waves <- mk(variant)
if (variant == 'v5') {
  miss <- matrix(0, n, n); miss[sample(n * n, 120)] <- 1; diag(miss) <- 0
  # NA in wave 2 at the missing dyads (wave 1 and 3 complete)
  waves[[2]][miss == 1] <- NA
  write.table(miss, file.path(out, "miss2.csv"), row.names = FALSE, col.names = FALSE, sep = ",")
}
for (k in 1:3) write.table(waves[[k]], file.path(out, sprintf("w%d.csv", k)), row.names = FALSE, col.names = FALSE, sep = ",")
if (task == 'data') quit()
arr <- function(ws) array(unlist(ws), dim = c(n, n, length(ws)))
# the standard effect list
mkeff <- function(d, theta = NULL) {
  e <- getEffects(d)
  e <- includeEffects(e, recip, transTrip, cycle3, inPopSqrt, outAct)
  e
}
if (task == 'targets') {
  tot <- NULL
  for (p in 1:2) {
    d <- sienaDataCreate(sienaDependent(arr(waves[p:(p + 1)])))
    nm <- attr(d$depvars[[1]], 'distance'); cat("DIST", p, nm, "\n")
    e <- mkeff(d)
    ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
    tg <- ans$targets
    for (k in seq_along(tg)) cat("TARGET", p, gsub(" ", "_", ans$effects$effectName[k]), round(tg[k], 6), "\n")
  }
  d3 <- sienaDataCreate(sienaDependent(arr(waves)))
  e <- mkeff(d3)
  ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d3, effects = e, batch = TRUE, silent = TRUE)
  for (k in seq_along(ans$targets)) cat("TARGET", 0, gsub(" ", "_", ans$effects$effectName[k]), round(ans$targets[k], 6), "\n")
  cat("DISTANCES", attr(d3$depvars[[1]], 'distance'), "\n")
}
if (task == 'sim') {
  # fixed parameters, unconditional (or conditional with COND=1): the convergence t-ratios of the phase-3 simulations are mean(dev)/sd(dev) per statistic
  cnd <- Sys.getenv("COND", "0") == "1"
  d3 <- sienaDataCreate(sienaDependent(arr(waves)))
  e <- mkeff(d3)
  th <- c(outdegree = -1.7, reciprocity = 0.6, indegpopularity = 0.25, outactivity = -0.067, transtrip = 0.4, cycle3 = 0.02)
  e$initialValue[e$shortName == 'density'] <- th['outdegree']; e$initialValue[e$shortName == 'recip'] <- th['reciprocity']
  e$initialValue[e$shortName == 'inPopSqrt'] <- th['indegpopularity']; e$initialValue[e$shortName == 'outAct'] <- th['outactivity']
  e$initialValue[e$shortName == 'transTrip'] <- th['transtrip']; e$initialValue[e$shortName == 'cycle3'] <- th['cycle3']
  e$initialValue[e$shortName == 'Rate'] <- 4
  e$fix[e$include] <- TRUE
  res <- NULL
  for (s in 1:nseed) {
    ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 100 + s, n3 = n3, nsub = 0, cond = cnd, simOnly = TRUE), data = d3, effects = e, batch = TRUE, silent = TRUE)
    res <- rbind(res, colMeans(ans$sf) / apply(ans$sf, 2, sd))
  }
  cat("SIMCOLS", gsub(" ", "_", e$effectName[e$include]), "\n")
  print(round(res, 3))
  cat("MEAN", round(colMeans(res), 3), "\n")
  cat("SE", round(apply(res, 2, sd) / sqrt(nrow(res)), 3), "\n")
}
