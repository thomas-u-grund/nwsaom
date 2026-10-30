# Multi-group reference: RSiena sienaGroupCreate() + siena07() on three groups cut out of the s50 data (actors 1-15, 16-35, 36-50).
# Writes the stacked data (wave matrices block-diagonal, actors.csv) for nwsaom and the RSiena estimates.
# Usage: Rscript dev/saom_rsiena_groups.R <outdir> [cond 0/1] [seeds] [feature]
# feature: degc | sequiv | ownass (group-level data constants) | base | balsim | unequal (group 2 has waves 1,2 and group 3 waves 2,3) | tvcov | comp (composition change) | miss (missing ties)
#          | ratecov | inter (interaction) | dyad (dyadic covariate) | coevmb (two behaviors: alc and smk = s50a and s50s)
library(RSiena)
args <- commandArgs(TRUE)
out <- args[1]; cond <- if (length(args) >= 2) as.logical(as.integer(args[2])) else TRUE
nseed <- if (length(args) >= 3) as.integer(args[3]) else 5
feat <- if (length(args) >= 4) args[4] else 'base'
dir.create(out, showWarnings = FALSE, recursive = TRUE)
grp <- c(rep(1, 15), rep(2, 20), rep(3, 15))
waves <- list(s501, s502, s503)
blk <- function(m) { m[outer(grp, grp, "!=")] <- 0; m }
waves <- lapply(waves, blk)
if (feat == 'sym') waves <- lapply(waves, function(m) { m <- 1 * ((m + t(m)) > 0); diag(m) <- 0; m })          # non-directed networks; the model type is MODELTYPE (default 2 = forcing, nwsaom's default)
# RSiena 1.6.14 stops (INTEGER() ... not a 'list' in initializeFRAN) for a group object whose groups have different numbers of waves, so the
# reference for 'unequal' is the equivalent object with two-wave groups only: group 1 (waves 1,2,3) = two groups (1,2) and (2,3) of the same
# actors, group 2 has waves 1,2, group 3 waves 2,3. With uncentred covariates and without effects that use group constants (balance, simX)
# the model is the same, period by period.
gsets <- list(1, 1, 2, 3); gw <- list(1:3, 1:3, 1:3)
if (feat == 'unequal') { gsets <- list(1, 1, 2, 3); gw <- list(1:2, 2:3, 1:2, 2:3) } else { gsets <- list(1, 2, 3) }
present <- matrix(1, 50, 3)
if (feat == 'compl') {                                    # leavers: actors 3, 22 present at waves 1,2 only; 41 at wave 1 only; joiners 8 and 40 (waves 2,3)
  present[3, 3] <- 0; present[22, 3] <- 0; present[41, 2:3] <- 0; present[8, 1] <- 0; present[40, 1] <- 0
  orig <- waves
  for (a in 1:50) for (w in 1:3) if (present[a, w] == 0) {
    pw <- which(present[a, ] == 1); wn <- pw[which.min(abs(pw - w))]
    waves[[w]][a, ] <- orig[[wn]][a, ]; waves[[w]][, a] <- orig[[wn]][, a]
  }
}
jt <- rep(1, 50); lt <- rep(3, 50)                          # joinat() / leaveat() on the time scale of the waves of the actor's group (feature 'timed')
if (feat == 'timed') {
  jt[3] <- 1.4; lt[8] <- 2.6; lt[22] <- 1.7; jt[30] <- 2.35; jt[41] <- 1.2; lt[41] <- 2.5; lt[47] <- 2.8
  for (a in 1:50) for (w in 1:3) present[a, w] <- as.numeric(ceiling(jt[a]) <= w && w <= trunc(lt[a]))
  orig <- waves
  for (a in 1:50) for (w in 1:3) if (present[a, w] == 0) {
    pw <- which(present[a, ] == 1); wn <- pw[which.min(abs(pw - w))]
    waves[[w]][a, ] <- orig[[wn]][a, ]; waves[[w]][, a] <- orig[[wn]][, a]
  }
}
if (feat %in% c('comp', 'coevcomp')) {                                     # actors 3 and 8 (group 1), 22 (group 2) and 40 (group 3) join at wave 2 (a leaver exactly at an observation is treated differently by present() and sienaCompositionChange)
  present[3, 1] <- 0; present[8, 1] <- 0; present[40, 1] <- 0; present[22, 1] <- 0
  # the ties of an absent actor at a wave where it is absent are those of the nearest wave where it is present (RSiena and nwsaom both
  # count the ties of absent actors as they are in the data)
  orig <- waves
  for (a in 1:50) for (w in 1:3) if (present[a, w] == 0) {
    pw <- which(present[a, ] == 1); wn <- pw[which.min(abs(pw - w))]
    waves[[w]][a, ] <- orig[[wn]][a, ]; waves[[w]][, a] <- orig[[wn]][, a]
  }
}
s50b <- as.matrix(s50a[, 1:3])                             # behavior / changing covariate values; absent actors take the nearest present wave
if (feat %in% c('comp', 'coevcomp', 'compl', 'timed')) for (a in 1:50) for (w in 1:3) if (present[a, w] == 0) { pw <- which(present[a, ] == 1); s50b[a, w] <- s50b[a, pw[which.min(abs(pw - w))]] }
bmiss <- matrix(0, 50, 3)
if (feat %in% c('coevmiss', 'coevmiss0')) { bmiss[5, 2] <- 1; bmiss[25, 1] <- 1; bmiss[45, 3] <- 1; bmiss[30, 2] <- 1 }
miss <- list(NULL, NULL, NULL)
if (feat == 'miss') {                                     # all out-ties of actor 20 (group 2) at wave 2 and of actor 45 (group 3) at wave 3 are missing
  mm <- lapply(1:3, function(w) matrix(0, 50, 50))
  mm[[2]][20, ] <- 1; mm[[3]][45, ] <- 1
  for (w in 1:3) diag(mm[[w]]) <- 0
  miss <- mm
}
for (w in 1:3) {
  write.table(waves[[w]], file.path(out, paste0("w", w, ".csv")), row.names = FALSE, col.names = FALSE, sep = ",")
  write.table(if (is.null(miss[[w]])) matrix(0, 50, 50) else miss[[w]], file.path(out, paste0("m", w, ".csv")), row.names = FALSE, col.names = FALSE, sep = ",")
}
# a dyadic covariate: same sex-like similarity of the alcohol wave-1 values (block-diagonal)
D0 <- outer(s50a[, 1], s50a[, 1], function(a, b) as.numeric(abs(a - b) <= 1)); diag(D0) <- 0
D0 <- D0 * outer(grp, grp, "==")
write.table(D0, file.path(out, "dyad.csv"), row.names = FALSE, col.names = FALSE, sep = ",")
ccv <- (1:50 %% 4) + 0.5 * (s50a[, 2] > 2)
actors <- data.frame(group = grp, ccv = ccv, alc = s50a[, 1], alc1 = s50b[, 1], alc2 = s50b[, 2], alc3 = s50b[, 3], smk1 = s50s[, 1], smk2 = s50s[, 2], smk3 = s50s[, 3], p1 = present[, 1], p2 = present[, 2], p3 = present[, 3], bm1 = bmiss[, 1], bm2 = bmiss[, 2], bm3 = bmiss[, 3])
write.csv(actors, file.path(out, "actors.csv"), row.names = FALSE)
mk <- function(gi) {
  g <- gsets[[gi]]; i <- which(grp == g); ws <- gw[[gi]]
  arr <- array(unlist(lapply(ws, function(w) waves[[w]][i, i])), dim = c(length(i), length(i), length(ws)))
  if (feat == 'miss') for (k in seq_along(ws)) { m <- miss[[ws[k]]][i, i]; a <- arr[, , k]; a[m == 1] <- NA; arr[, , k] <- a }
  net <- sienaDependent(arr, allowOnly = FALSE)
  if (feat %in% c('coev', 'coevq', 'coevsim', 'coevcomp', 'coevmiss', 'coevmiss0', 'coevrate', 'coevbr', 'coevmb')) alc <- sienaDependent({ bb <- s50b[i, ws, drop = FALSE]; bb[bmiss[i, ws, drop = FALSE] == 1] <- NA; bb }, type = 'behavior', allowOnly = FALSE)
  else if (feat == 'tvcov') alc <- varCovar(as.matrix(s50a[i, ws]))
  else alc <- coCovar(s50a[i, 1], centered = (feat != 'unequal'))
  if (feat == 'coevmb') { smk <- sienaDependent(as.matrix(s50s[i, ws, drop = FALSE]), type = 'behavior', allowOnly = FALSE); return(sienaDataCreate(net, alc, smk)) }
  if (feat == 'dyad') { D <- coDyadCovar(D0[i, i]); return(sienaDataCreate(net, alc, D)) }
  if (feat == 'timed') return(sienaDataCreate(net, alc, sienaCompositionChange(lapply(i, function(a) c(jt[a], lt[a])))))
  if (feat %in% c('comp', 'compl')) {
    ch <- lapply(i, function(a) { p <- present[a, ws]; w1 <- which(p == 1); c(min(w1), max(w1)) })
    cc <- sienaCompositionChange(ch)
    return(sienaDataCreate(net, alc, cc))
  }
  if (feat == 'coevcomp') { ch <- lapply(i, function(a) { p <- present[a, ws]; w1 <- which(p == 1); c(min(w1), max(w1)) }); cc <- sienaCompositionChange(ch); return(sienaDataCreate(net, alc, cc)) }
  if (feat == 'coevrate') { ccv <- coCovar(ccv[i]); return(sienaDataCreate(net, alc, ccv)) }
  sienaDataCreate(net, alc)
}
gd <- sienaGroupCreate(lapply(seq_along(gsets), mk))
eff <- getEffects(gd)
if (feat == 'base') { eff <- includeEffects(eff, transTrip, cycle3); eff <- includeEffects(eff, egoX, altX, interaction1 = "alc") }
if (feat == 'score') {      # restricted model: altX and egoX of alc fixed at 0 and tested (score test)
  eff <- includeEffects(eff, transTrip)
  eff <- includeEffects(eff, egoX, altX, interaction1 = "alc", fix = TRUE, test = TRUE)
}
if (feat == 'balsim') { eff <- includeEffects(eff, balance); eff <- includeEffects(eff, egoX, simX, interaction1 = "alc") }
if (feat %in% c('unequal', 'comp', 'compl', 'miss')) { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = "alc") }
if (feat == 'tvcov') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, simX, interaction1 = "alc") }
if (feat == 'ratecov') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, interaction1 = "alc"); eff <- includeEffects(eff, RateX, interaction1 = "alc", type = "rate") }
if (feat == 'inter') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, interaction1 = "alc"); eff <- includeInteraction(eff, egoX, recip, interaction1 = c("alc", "")) }
if (feat %in% c('coevq', 'coevmiss0')) { eff <- includeEffects(eff, transTrip); if (feat == 'coevmiss0') eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net') }
if (feat == 'coevsim') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, avSim, name = 'alc', interaction1 = 'net'); eff <- includeEffects(eff, simX, interaction1 = 'alc') }
if (feat == 'coevrate') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net'); eff <- includeEffects(eff, RateX, name = 'alc', interaction1 = 'ccv', type = 'rate') }
if (feat %in% c('coev', 'coevcomp', 'coevmiss')) { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = 'alc'); eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net') }
if (feat == 'coevmb') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = 'alc'); eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net'); eff <- includeEffects(eff, avAlt, name = 'smk', interaction1 = 'net') }
if (feat == 'coevbr') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net'); eff <- includeEffects(eff, outRate, avExposure, name = 'alc', interaction1 = 'net', type = 'rate') }   # rate effects of the behavior (behrate()); needs a small first gain
if (feat == 'sym') { if (as.integer(Sys.getenv('MODELTYPE', '2')) < 4) eff <- includeEffects(eff, transTriads); eff <- includeEffects(eff, degPlus.c); eff <- includeEffects(eff, egoX, interaction1 = 'alc') }
if (feat == 'dyad') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, X, interaction1 = "D"); }
if (feat == 'timed') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = "alc") }
if (feat == 'degc') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, inPop.c, outAct.c) }            # centred degree effects: the average degree is a property of the group
if (feat == 'sequiv') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, inStructEq) }                    # structural equivalence: structmean of the group
if (feat == 'ownass') { eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, outInAss); eff <- setEffect(eff, outInAss, parameter = 2) }
res <- NULL; ttres <- NULL; sres <- NULL
for (s in 1:nseed) {
  alg <- if (feat == 'sym') sienaAlgorithmCreate(projname = NULL, cond = cond, seed = s, n3 = 2000, nsub = 4, modelType = c(net = as.integer(Sys.getenv('MODELTYPE', '2'))))
         else sienaAlgorithmCreate(projname = NULL, cond = cond, seed = s, n3 = 2000, nsub = 4, firstg = if (feat == 'coevbr') 0.1 else 0.2)
  a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = FALSE)
  ef <- a$effects[a$effects$include, ]
  th <- data.frame(seed = s, name = ef$effectName, theta = a$theta, se = sqrt(diag(a$covtheta)))
  if (a$cconditional) {
    rr <- data.frame(seed = s, name = paste("rate", seq_along(a$rate)), theta = a$rate, se = sqrt(a$vrate))
    th <- rbind(rr, th)
  }
  res <- rbind(res, th)
  if (feat == 'score') { sres <- rbind(sres, data.frame(seed = s, c = a$testresOverall, df = sum(a$test))) }
  if (Sys.getenv('RSIENA_TT') == '1') {      # time heterogeneity: sienaTimeTest() with the group test (rates held fixed, as sienaTimeTest does)
    tt <- sienaTimeTest(a)
    ttres <- rbind(ttres, data.frame(seed = s, what = 'joint', k = 0, c = tt$JointTest[1], df = tt$JointTest[2]))
    ttres <- rbind(ttres, data.frame(seed = s, what = 'effect', k = seq_len(nrow(tt$EffectTest)), c = tt$EffectTest[, 1], df = tt$EffectTest[, 2]))
    ttres <- rbind(ttres, data.frame(seed = s, what = 'group', k = seq_len(nrow(tt$GroupTest)), c = tt$GroupTest[, 1], df = tt$GroupTest[, 2]))
  }
}
if (!is.null(sres)) write.csv(sres, file.path(out, 'rsiena_score.csv'), row.names = FALSE)
if (!is.null(ttres)) write.csv(ttres, file.path(out, 'rsiena_tt.csv'), row.names = FALSE)
write.csv(res, file.path(out, paste0("rsiena_", feat, "_cond", as.integer(cond), ".csv")), row.names = FALSE)
print(aggregate(cbind(theta, se) ~ name, res, mean))
