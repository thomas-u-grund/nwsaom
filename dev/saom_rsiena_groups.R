# Multi-group reference: RSiena sienaGroupCreate() + siena07() on three groups cut out of the s50 data.
# Writes the stacked data (wave matrices block-diagonal, group, alc) for nwsaom and the RSiena estimates.
# Usage: Rscript dev/saom_rsiena_groups.R <outdir> [cond 0/1] [seeds] [feature: base|balsim]
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
for (w in 1:3) write.table(waves[[w]], file.path(out, paste0("w", w, ".csv")), row.names = FALSE, col.names = FALSE, sep = ",")
write.csv(data.frame(group = grp, alc = s50a[, 1]), file.path(out, "actors.csv"), row.names = FALSE)
mk <- function(g) {
  i <- which(grp == g)
  arr <- array(c(waves[[1]][i, i], waves[[2]][i, i], waves[[3]][i, i]), dim = c(length(i), length(i), 3))
  net <- sienaDependent(arr)
  alc <- coCovar(s50a[i, 1])
  sienaDataCreate(net, alc)
}
gd <- sienaGroupCreate(list(mk(1), mk(2), mk(3)))
eff <- getEffects(gd)
if (feat == 'base') {
  eff <- includeEffects(eff, transTrip, cycle3)
  eff <- includeEffects(eff, egoX, altX, interaction1 = "alc")
}
if (feat == 'balsim') {
  eff <- includeEffects(eff, balance)
  eff <- includeEffects(eff, egoX, simX, interaction1 = "alc")
}
res <- NULL
for (s in 1:nseed) {
  alg <- sienaAlgorithmCreate(projname = NULL, cond = cond, seed = s, n3 = 2000, nsub = 4)
  a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = FALSE)
  ef <- a$effects[a$effects$include, ]
  sel <- ef$type != "rate" | TRUE
  th <- data.frame(seed = s, name = ef$effectName, theta = a$theta, se = sqrt(diag(a$covtheta)))
  if (cond) {
    rr <- data.frame(seed = s, name = paste("rate", seq_along(a$rate)), theta = a$rate, se = sqrt(a$vrate))
    th <- rbind(rr, th)
  }
  res <- rbind(res, th)
}
write.csv(res, file.path(out, paste0("rsiena_", feat, "_cond", as.integer(cond), ".csv")), row.names = FALSE)
print(aggregate(cbind(theta, se) ~ name, res, mean))
