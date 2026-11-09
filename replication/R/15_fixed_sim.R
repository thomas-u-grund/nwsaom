# The same simulation (for Appendix D of the nwsaom manual): both programs simulate the same model at
# the same fixed parameters, and the simulated statistics are compared with the observed ones. Models N1, N2
# and R1 of the benchmark. RSiena first estimates each model (seed 1); the estimates are written to
# results/fixedsim/theta.csv, which stata/15_fixed_sim.do reads. Then RSiena simulates 1,000 times at these
# parameters, five times (seeds 1 to 5), with simOnly = TRUE (no estimation); nwsaom does the same with
# fix(_all) k3(1000). For each statistic the t-ratio (mean deviation from the observed value over its standard
# deviation) is compared; if both programs simulate the same model, the two t-ratios differ only by sampling
# error, with a standard deviation of about sqrt(2/5000) = 0.02 for the mean over the five runs.
# Run from the replication folder: Rscript R/15_fixed_sim.R   (about a minute)
source("R/common.R")
source("R/07_bench_specs.R")
od <- out_dir("fixedsim")
th <- NULL; res <- NULL
for (m in c("N1", "N2", "R1")) {
  x <- spec[[m]](); d <- x[[1]]; e <- x[[2]]
  invisible(capture.output(fit <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1), data = d, effects = e,
                                          batch = TRUE, silent = TRUE)))
  idx <- which(e$include & !e$basicRate)
  if (length(idx) != length(fit$theta)) stop("parameters and effects do not line up")
  e$initialValue[idx] <- fit$theta
  th <- rbind(th, data.frame(model = m, rsname = e$shortName[idx], value = fit$theta))
  for (s in 1:5) {
    alg <- sienaAlgorithmCreate(projname = NULL, seed = s, simOnly = TRUE, nsub = 0, n3 = 1000)
    invisible(capture.output(sim <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)))
    sf <- sim$sf
    res <- rbind(res, data.frame(program = "RSiena", model = m, seed = s, rsname = e$shortName[idx],
                                 mean_dev = colMeans(sf), sd_dev = apply(sf, 2, sd), tconv = colMeans(sf) / apply(sf, 2, sd)))
  }
}
write.csv(th, file.path(od, "theta.csv"), row.names = FALSE)
write.csv(res, file.path(od, "rsiena_fixedsim.csv"), row.names = FALSE)
print(aggregate(tconv ~ model + rsname, res, mean))
