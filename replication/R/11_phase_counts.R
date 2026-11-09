# How many simulations RSiena runs in each phase of a fit (for Appendix D of the nwsaom manual): benchmark models
# N1, N2 and R1, seeds 1 to 10, default settings as in the benchmark. stata/11_phase_counts.do counts
# the same for nwsaom. Run from the replication folder: Rscript R/11_phase_counts.R   (about a minute)
# Writes results/phases/rsiena_phases.csv.
# a$n counts the simulations of Phases 1 and 2 together with Phase 3, so Phase 2 is a$n - a$nitPhase1 - a$Phase3nits.
# A trace on RSiena's doIterations records every run of a Phase 2 subphase, which gives the number of repeated
# subphases (RSiena's safeguard against oscillation, proc2subphase) and checks the Phase 2 count.
source("R/common.R")
source("R/07_bench_specs.R")
RUNS <- NULL
trace(RSiena:::doIterations, print = FALSE, where = asNamespace("RSiena"),
      exit = quote(if (z$Phase == 2 && subphase >= 1)
        RUNS <<- rbind(RUNS, data.frame(subphase = subphase, run = z$repeatsubphase, nit = z$nit))))
res <- NULL
for (m in c("N1", "N2", "R1")) for (s in 1:10) {
  x <- spec[[m]](); d <- x[[1]]; e <- x[[2]]
  alg <- sienaAlgorithmCreate(projname = NULL, seed = s, cond = if (!is.null(x$cond)) x$cond else NA)
  RUNS <- NULL
  invisible(capture.output(a <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)))
  p2 <- a$n - a$nitPhase1 - a$Phase3nits
  if (p2 != sum(RUNS$nit)) stop("Phase 2 count and trace disagree")
  res <- rbind(res, data.frame(program = "RSiena", model = m, seed = s, nparam = sum(e$include),
                               phase1 = a$nitPhase1, phase2 = p2, phase3 = a$Phase3nits,
                               repeats = sum(RUNS$run > 1)))
}
untrace(RSiena:::doIterations, where = asNamespace("RSiena"))
print(res, row.names = FALSE)
write.csv(res, file.path(out_dir("phases"), "rsiena_phases.csv"), row.names = FALSE)
