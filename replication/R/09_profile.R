# Where RSiena spends its time (Section "Where the difference comes from"): R's sampling profiler (Rprof) on
# fits of the benchmark models N1 (outdegree, reciprocity) and N2 (with gwespFF). As in the timed benchmark,
# an untimed warm-up fit (N1, seed 100) runs first in the R process; the first (cold) fit is profiled
# separately, then seeds 1 to 10 of each model.
# Time with .Call at the top of the stack is RSiena's compiled code; the rest is the R code around it.
# Run from the replication folder: Rscript R/09_profile.R   (about a minute). Writes results/profile/rsiena_profile.txt.
source("R/common.R")
source("R/07_bench_specs.R")
out <- file.path(out_dir("profile"), "rsiena_profile.txt")
lines <- c(sprintf("RSiena %s, %s, %s", packageVersion("RSiena"), R.version.string, Sys.time()), "")
prof1 <- function(m, s) {
  x <- spec[[m]](); d <- x[[1]]; e <- x[[2]]
  alg <- sienaAlgorithmCreate(projname = NULL, seed = s, cond = if (!is.null(x$cond)) x$cond else NA)
  f <- tempfile(); Rprof(f, interval = 0.002)
  invisible(siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE))
  Rprof(NULL)
  p <- summaryRprof(f)$by.self
  k <- gsub("\"", "", rownames(p)) == ".Call"
  c(call = sum(p$self.time[k]), all = sum(p$self.time))
}
cold <- prof1("N1", 100)
lines <- c(lines, sprintf("cold first fit (N1, seed 100): compiled code %.0f%%, R code %.0f%%", 100 * cold[1] / cold[2], 100 * (1 - cold[1] / cold[2])))
for (m in c("N1", "N2")) {
  shares <- numeric(); tot_call <- 0; tot_all <- 0
  for (s in 1:10) {
    r <- prof1(m, s)
    shares <- c(shares, r[[1]] / r[[2]]); tot_call <- tot_call + r[[1]]; tot_all <- tot_all + r[[2]]
  }
  lines <- c(lines, sprintf("%s: compiled code (.Call) %.0f%% of the sampled time over 10 warm fits, R code %.0f%%; per fit %s",
                            m, 100 * tot_call / tot_all, 100 * (1 - tot_call / tot_all), paste(sprintf("%.0f%%", 100 * shares), collapse = " ")))
}
writeLines(lines); writeLines(lines, out)
