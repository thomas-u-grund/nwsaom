# estat gof per group after a fit with a co-evolving behavior vs sienaGOF(groupName = "DataK"): the three groups of saom_rsiena_groups.R, model with
# transTrip, behavior alc (linear, quadratic, avAlt) and egoX/altX of alc; Mahalanobis p-values of the out-degree and behavior distributions per group.
# Usage: Rscript dev/saom_rsiena_groups_post_beh.R <outdir> [nseed]   writes <outdir>/rsiena_gof_beh.csv
library(RSiena)
args <- commandArgs(TRUE); out <- args[1]; nseed <- if (length(args) >= 2) as.integer(args[2]) else 6
dir.create(out, showWarnings = FALSE, recursive = TRUE)
s50b <- as.matrix(s50a[, 1:3])
grp <- c(rep(1, 15), rep(2, 20), rep(3, 15))
wv <- lapply(list(s501, s502, s503), function(m) { m[outer(grp, grp, "!=")] <- 0; m })
mk <- function(g) { i <- which(grp == g)
  net <- sienaDependent(array(unlist(lapply(wv, function(m) m[i, i])), dim = c(length(i), length(i), 3)), allowOnly = FALSE)
  alc <- sienaDependent(s50b[i, 1:3, drop = FALSE], type = 'behavior', allowOnly = FALSE); sienaDataCreate(net, alc) }
gd <- sienaGroupCreate(lapply(1:3, mk))
eff <- getEffects(gd); eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = 'alc'); eff <- includeEffects(eff, avAlt, name = 'alc', interaction1 = 'net')
res <- NULL
for (s in 1:nseed) {
  alg <- sienaAlgorithmCreate(projname = NULL, cond = FALSE, seed = s, n3 = 500, nsub = 3)
  a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = TRUE)
  for (g in 1:3) {
    g1 <- sienaGOF(a, OutdegreeDistribution, varName = "net", groupName = paste0("Data", g), verbose = FALSE, join = TRUE, levls = 0:5)
    g2 <- sienaGOF(a, BehaviorDistribution, varName = "alc", groupName = paste0("Data", g), verbose = FALSE, join = TRUE)
    res <- rbind(res, data.frame(seed = s, group = g, stat = "outdegree", p = g1[[1]]$p, mhd = g1[[1]]$Observed),
                      data.frame(seed = s, group = g, stat = "behavior", p = g2[[1]]$p, mhd = g2[[1]]$Observed))
  }
}
write.csv(res, file.path(out, "rsiena_gof_beh.csv"), row.names = FALSE)
print(aggregate(p ~ group + stat, res, mean))
