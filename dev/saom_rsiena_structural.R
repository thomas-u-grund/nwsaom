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
ALG <- function(...) if (sym) sienaAlgorithmCreate(..., modelType = c(net = 6)) else sienaAlgorithmCreate(...)
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
  if (variant %in% c('v3', 'v5', 'v6')) {
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
  if (variant %in% c('v3s', 'v3m', 'v6s')) {   # designed cases: (1,2) 10 at wave 1 only; (3,4) 10 at wave 2 only; (5,6) 10 at wave 1, 11 at wave 2; (7,8) 11 at waves 1 and 2, 10 at wave 3; (9,10) 11 at wave 3 only
    w[[1]][1,2] <- 10; w[[2]][3,4] <- 10; w[[1]][5,6] <- 10; w[[2]][5,6] <- 11; w[[1]][7,8] <- 11; w[[2]][7,8] <- 11; w[[3]][7,8] <- 10; w[[3]][9,10] <- 11
    for (a in 11:30) { w[[1]][a, a + 1] <- 10 + (a %% 2); w[[3]][a + 1, a] <- 10 + (a %% 3 == 0); if (a %% 2 == 0) w[[2]][a, a + 1] <- 11 }
  }
  w
}
sym <- grepl("^sy", variant)
bip <- grepl("^tm", variant)
if (sym) {   # non-directed relation: the symmetrized s50 waves; structural codes given for both directions (value 10 or 11 per pair), independent per wave
  w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
  up <- which(upper.tri(diag(n)), arr.ind = TRUE)
  if (variant != 'sy0') for (k in 1:3) { m <- w[[k]]; pick <- sample(nrow(up), round(0.03 * nrow(up))); val <- sample(c(10, 11), length(pick), replace = TRUE)
    m[up[pick, , drop = FALSE]] <- val; m[up[pick, 2:1, drop = FALSE]] <- val; w[[k]] <- m }
  waves <- w
}
if (bip) {   # two-mode: 40 actors x 20 events; tm1: actors 1-10 cannot choose events 1-5 (10 in all waves), actor 11 is frozen, event 20 cannot be chosen by anybody; tm3: changing sets
  w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_twomode_w%d.csv", k))))
  for (k in 1:3) { m <- w[[k]]
    m[1:10, 1:5] <- 10 + (m[1:10, 1:5] == 1); m[11, ] <- 10; m[, 20] <- 10 + (m[, 20] == 1)
    if (variant == 'tm3') { m[12:14, 6:8] <- 0; if (k == 1) m[15:18, 1:3] <- 10; if (k == 2) m[16:20, 2:4] <- 11; if (k == 3) m[1:3, 6:9] <- 10 }
    w[[k]] <- m }
  waves <- w
} else if (!sym) waves <- mk(variant)
cchg <- NULL
if (variant %in% c('v6', 'v6s')) {    # composition change (RSiena sienaCompositionChange): actors 3 and 8 join at 1.4 and 2.3; actors 5 and 12 leave at 1.6 and 2.5; with structural values coded as in v3
  jn <- rep(1, n); lv <- rep(3, n); jn[3] <- 1.4; jn[8] <- 2.3; lv[5] <- 1.6; lv[12] <- 2.5
  pres <- matrix(1, n, 3); for (a in 1:n) for (k in 1:3) pres[a, k] <- (ceiling(jn[a]) <= k) & (k <= trunc(lv[a]))
  orig <- waves
  for (a in 1:n) for (k in 1:3) if (pres[a, k] == 0) { pw <- which(pres[a, ] == 1); wn <- pw[which.min(abs(pw - k))]; waves[[k]][a, ] <- orig[[wn]][a, ]; waves[[k]][, a] <- orig[[wn]][, a] }
  for (k in 1:3) diag(waves[[k]]) <- 0
  cchg <- lapply(1:n, function(a) c(jn[a], lv[a]))
  write.table(data.frame(jn = jn, lv = lv), file.path(out, "cc.csv"), row.names = FALSE, sep = ",")
}
if (variant %in% c('v5', 'm0', 'v3m')) {
  miss <- matrix(0, n, n); miss[sample(n * n, 120)] <- 1; diag(miss) <- 0
  if (variant == 'v3m') { miss[] <- 0; miss[5:7, ] <- 1; miss[, 20] <- 1; miss[11:13, 12:14] <- 1; diag(miss) <- 0 }   # deterministic
  # NA in wave 2 at the missing dyads (wave 1 and 3 complete)
  waves[[2]][miss == 1] <- NA
  write.table(miss, file.path(out, "miss2.csv"), row.names = FALSE, col.names = FALSE, sep = ",")
}
for (k in 1:3) { m <- waves[[k]]; m[is.na(m)] <- 0; write.table(m, file.path(out, sprintf("w%d.csv", k)), row.names = FALSE, col.names = FALSE, sep = ",") }
if (task == 'data') quit()
arr <- function(ws) array(unlist(ws), dim = c(nrow(ws[[1]]), ncol(ws[[1]]), length(ws)))
cvv <- (1:50 %% 4) + 0.5
mkdata <- function(ws) {
  if (Sys.getenv("MODEL", "std") == 'coev') {     # a co-evolving behavior: the alcohol scores of the first waves of s50
    nw <- length(ws); bb <- as.matrix(s50a[, 1:nw]); beh <- sienaDependent(bb, type = 'behavior')
    write.table(as.matrix(s50a[, 1:3]), file.path(out, "beh.csv"), row.names = FALSE, col.names = FALSE, sep = ",")
    net <- sienaDependent(arr(ws))
    return(sienaDataCreate(net, beh))
  }
  if (Sys.getenv("MODEL", "std") == 'ratecov') { cvc <- coCovar(cvv, centered = TRUE); return(sienaDataCreate(sienaDependent(arr(ws)), cvc)) }
  if (!bip && !is.null(cchg)) { net <- sienaDependent(arr(ws)); return(sienaDataCreate(net, sienaCompositionChange(cchg))) }
  if (!bip) { net <- sienaDependent(arr(ws)); return(sienaDataCreate(net)) }
  A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
  sienaDataCreate(sienaDependent(arr(ws), type = "bipartite", nodeSet = c("A", "B")), nodeSets = list(A, B))
}
# the standard effect list
MODEL <- Sys.getenv("MODEL", "std")
mkeff <- function(d, theta = NULL) {
  e <- getEffects(d)
  if (MODEL == 'endow') {   # reciprocity split into endowment and creation, outdegree and transitive triplets plain
    e <- includeEffects(e, recip, type = 'endow'); e <- includeEffects(e, recip, type = 'creation'); e <- includeEffects(e, recip, type = 'eval', include = FALSE)
    e <- includeEffects(e, transTrip)
  } else if (MODEL == 'coev') {
    e <- includeEffects(e, recip, transTrip)
    e <- includeEffects(e, altX, simX, interaction1 = 'beh')
    e <- includeEffects(e, avAlt, interaction1 = 'net', name = 'beh')
  } else if (MODEL == 'ratecov') {
    e <- includeEffects(e, recip, transTrip, cycle3, inPopSqrt, outAct)
    e <- includeEffects(e, RateX, interaction1 = 'cvc', type = 'rate')
  } else if (sym) e <- includeEffects(e, transTies, inPopSqrt)
  else if (bip) e <- includeEffects(e, cycle4, inPopSqrt, outAct)
  else e <- includeEffects(e, recip, transTrip, cycle3, inPopSqrt, outAct)
  e
}
if (task == 'targets') {
  tot <- NULL
  for (p in if (is.null(cchg)) 1:2 else integer(0)) {
    d <- mkdata(waves[p:(p + 1)])
    nm <- attr(d$depvars[[1]], 'distance'); cat("DIST", p, nm, "\n")
    e <- mkeff(d)
    ans <- siena07(ALG(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
    tg <- ans$targets
    for (k in seq_along(tg)) cat("TARGET", p, gsub(" ", "_", ans$effects$effectName[k]), round(tg[k], 6), "\n")
  }
  d3 <- mkdata(waves)
  e <- mkeff(d3)
  ans <- siena07(ALG(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d3, effects = e, batch = TRUE, silent = TRUE)
  for (k in seq_along(ans$targets)) cat("TARGET", 0, gsub(" ", "_", ans$effects$effectName[k]), round(ans$targets[k], 6), "\n")
  cat("DISTANCES", attr(d3$depvars[[1]], 'distance'), "\n")
}
if (task == 'sim') {
  # fixed parameters, unconditional (or conditional with COND=1): the convergence t-ratios of the phase-3 simulations are mean(dev)/sd(dev) per statistic
  cnd <- Sys.getenv("COND", "0") == "1"
  d3 <- mkdata(waves)
  e <- mkeff(d3)
  if (sym) {
    e$initialValue[e$shortName == 'density'] <- -1.2; e$initialValue[e$shortName == 'transTies'] <- 0.3; e$initialValue[e$shortName == 'inPopSqrt'] <- 0.1
  } else if (MODEL == 'endow') {
    ee <- unclass(e)
    set <- function(sn, ty, v) e$initialValue[ee$shortName == sn & ee$type == ty & ee$include] <<- v
    set('density', 'eval', -1.7); set('recip', 'endow', 0.5); set('recip', 'creation', 0.8); set('transTrip', 'eval', 0.3)
  } else if (bip) {
    e$initialValue[e$shortName == 'density'] <- -1.5; e$initialValue[e$shortName == 'inPopSqrt'] <- 0.3
    e$initialValue[e$shortName == 'outAct'] <- 0.02; e$initialValue[e$shortName == 'cycle4'] <- 0.05
  } else {
  th <- c(outdegree = -1.7, reciprocity = 0.6, indegpopularity = 0.25, outactivity = -0.067, transtrip = 0.4, cycle3 = 0.02)
  e$initialValue[e$shortName == 'density'] <- th['outdegree']; e$initialValue[e$shortName == 'recip'] <- th['reciprocity']
  e$initialValue[e$shortName == 'inPopSqrt'] <- th['indegpopularity']; e$initialValue[e$shortName == 'outAct'] <- th['outactivity']
  e$initialValue[e$shortName == 'transTrip'] <- th['transtrip']; e$initialValue[e$shortName == 'cycle3'] <- th['cycle3']
  }
  e$initialValue[e$shortName == 'Rate'] <- if (sym) 1 else 4
  if (MODEL == 'ratecov') e$initialValue[e$shortName == 'RateX'] <- as.numeric(Sys.getenv('RCC', '0.3'))
  e$fix[e$include] <- TRUE
  res <- NULL
  for (s in 1:nseed) {
    ans <- siena07(ALG(projname = NULL, seed = 100 + s, n3 = n3, nsub = 0, cond = cnd, simOnly = TRUE), data = d3, effects = e, batch = TRUE, silent = TRUE)
    res <- rbind(res, colMeans(ans$sf) / apply(ans$sf, 2, sd))
  }
  cat("SIMCOLS", gsub(" ", "_", e$effectName[e$include]), "\n")
  print(round(res, 3))
  cat("MEAN", round(colMeans(res), 3), "\n")
  cat("SE", round(apply(res, 2, sd) / sqrt(nrow(res)), 3), "\n")
}

if (task == 'est') {
  cnd <- Sys.getenv("COND", "1") == "1"
  d3 <- mkdata(waves)
  e <- mkeff(d3)
  res <- NULL
  st <- as.numeric(strsplit(Sys.getenv("START", ""), ",")[[1]])
  if (length(st) == 6) { sn <- c('density','recip','transTrip','cycle3','inPopSqrt','outAct'); for (q in 1:6) e$initialValue[e$shortName == sn[q]] <- st[q] }
  for (s in 1:nseed) {
    ans <- siena07(ALG(projname = NULL, seed = 200 + s, n3 = n3, nsub = 4, cond = cnd), data = d3, effects = e, batch = TRUE, silent = TRUE)
    ans <- siena07(ALG(projname = NULL, seed = 300 + s, n3 = n3, nsub = 1, cond = cnd), data = d3, effects = e, prevAns = ans, batch = TRUE, silent = TRUE)
    res <- rbind(res, c(ans$theta, ans$tconv.max))
  }
  cat("ESTCOLS", gsub(" ", "_", e$effectName[e$include]), "tconv.max\n")
  if (MODEL == 'coev') print(round(ans$theta, 3))
  print(round(res, 3))
  cat("MEAN", round(colMeans(res), 3), "\n")
  cat("SE", round(apply(res, 2, sd) / sqrt(nrow(res)), 3), "\n")
}
