# Timing with a fixed workload (for Appendix D of the nwsaom manual): RSiena simulates N1, N2 and R1 at
# its own estimates (results/fixedsim/theta.csv, from R/15_fixed_sim.R) 1,000 and 5,000 times (simOnly = TRUE),
# five times each, alternating, after a warm-up. The difference of the medians is the time of 4,000
# simulations, without any estimation; stata/16_fixed_workload.do does the same for nwsaom on one thread.
# Run nothing else while timing. Run from the replication folder: Rscript R/16_fixed_workload.R   (about 5 minutes)
source("R/common.R")
source("R/07_bench_specs.R")
th <- read.csv("results/fixedsim/theta.csv", stringsAsFactors = FALSE)
res <- NULL
for (m in c("N1", "N2", "R1")) {
  x <- spec[[m]](); d <- x[[1]]; e <- x[[2]]
  idx <- which(e$include & !e$basicRate)
  e$initialValue[idx] <- th$value[th$model == m]
  run <- function(n3, s) {
    alg <- sienaAlgorithmCreate(projname = NULL, seed = s, simOnly = TRUE, nsub = 0, n3 = n3)
    invisible(capture.output(t <- system.time(siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE))[["elapsed"]]))
    t }
  run(1000, 99)
  for (r in 1:5) for (n3 in c(1000, 5000)) res <- rbind(res, data.frame(program = "RSiena", model = m, rep = r, n3 = n3, secs = run(n3, r)))
}
write.csv(res, file.path(out_dir("fixedsim"), "rsiena_workload.csv"), row.names = FALSE)
for (m in unique(res$model)) {
  a <- median(res$secs[res$model == m & res$n3 == 1000]); b <- median(res$secs[res$model == m & res$n3 == 5000])
  cat(sprintf("%s: 1,000 simulations %.3f s, 5,000 %.3f s, per simulation %.1f microseconds\n", m, a, b, 1e6 * (b - a) / 4000))
}
