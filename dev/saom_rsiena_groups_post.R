# estat gof per group vs sienaGOF(groupName = "DataK"): three groups cut out of the s50 data (see saom_rsiena_groups.R), the p-values of the
# Mahalanobis test for the out-degree, in-degree and geodesic distributions of every group, for seeds 1..nseed; written to <outdir>/rsiena_gof.csv
# Usage: Rscript dev/saom_rsiena_groups_post.R <outdir> [nseed]
library(RSiena)
args <- commandArgs(TRUE); out <- args[1]; nseed <- if (length(args) >= 2) as.integer(args[2]) else 6
dir.create(out, showWarnings = FALSE, recursive = TRUE)
grp <- c(rep(1, 15), rep(2, 20), rep(3, 15))
wv <- lapply(list(s501, s502, s503), function(m) { m[outer(grp, grp, "!=")] <- 0; m })
mk <- function(g) { i <- which(grp == g)
  net <- sienaDependent(array(unlist(lapply(wv, function(m) m[i, i])), dim = c(length(i), length(i), 3)), allowOnly = FALSE)
  alc <- coCovar(s50a[i, 1]); sienaDataCreate(net, alc) }
gd <- sienaGroupCreate(lapply(1:3, mk))
eff <- getEffects(gd); eff <- includeEffects(eff, transTrip); eff <- includeEffects(eff, egoX, altX, interaction1 = "alc")
res <- NULL
for (s in 1:nseed) {
  alg <- sienaAlgorithmCreate(projname = NULL, cond = FALSE, seed = s, n3 = 500, nsub = 3)
  a <- siena07(alg, data = gd, effects = eff, batch = TRUE, verbose = FALSE, silent = TRUE, returnDeps = TRUE)
  for (g in 1:3) for (st in c("outdegree", "indegree", "triad")) {
    f <- switch(st, outdegree = OutdegreeDistribution, indegree = IndegreeDistribution, triad = TriadCensus)
    lv <- 0:5
    gf <- if (st == 'triad') sienaGOF(a, f, varName = "net", groupName = paste0("Data", g), verbose = FALSE, join = TRUE) else sienaGOF(a, f, varName = "net", groupName = paste0("Data", g), verbose = FALSE, join = TRUE, levls = lv)
    res <- rbind(res, data.frame(seed = s, group = g, stat = st, p = gf[[1]]$p, mhd = gf[[1]]$Observed))
  }
}
write.csv(res, file.path(out, "rsiena_gof.csv"), row.names = FALSE)
print(aggregate(p ~ group + stat, res, mean))
