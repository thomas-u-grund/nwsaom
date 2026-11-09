# Table "The estimates of two examples, nwsaom and RSiena" (Section 5.7) and the sienaGOF reference:
# the article's examples E1, E3, E4, E5 fitted in RSiena with the same data, effects and Phase 3 length
# (1,000 simulations) as stata/02_examples.do, seeds 12345, 1, 2, 3, 4.
# Run from the replication folder: Rscript R/02_examples.R   (about 5 minutes)
# Writes results/examples/rs_examples.csv and results/examples/rs_gof.txt.
source("R/common.R")
args <- file.path(out_dir("examples"), c("rs_examples.csv", "rs_gof.txt"))
clean <- function(x) { x[x > 1] <- 0; x }
w <- lapply(list(s501, s502, s503), clean)
net3 <- sienaDependent(array(unlist(w), dim = c(50, 50, 3)))
net2 <- sienaDependent(array(unlist(w[1:2]), dim = c(50, 50, 2)))
smoke1 <- coCovar(s50s[, 1]); alc1 <- coCovar(s50a[, 1])
# directed geodesic distances 1..6 and "not reached", counted over ordered pairs (as estat gof's geodesic statistic)
GeodesicDistribution <- function(i, data, sims, period, groupName, varName, levls = c(1:6, Inf), ...) {
  x <- networkExtraction(i, data, sims, period, groupName, varName)
  x <- as.matrix(x); x[is.na(x)] <- 0; x <- (x > 0) * 1; n <- nrow(x); diag(x) <- 0
  d <- matrix(Inf, n, n); reach <- diag(n) > 0; cur <- reach
  for (k in 1:(n - 1)) { nxt <- ((cur %*% x) > 0) & !reach
    if (!any(nxt)) break; d[nxt] <- k; reach <- reach | nxt; cur <- nxt }
  diag(d) <- NA
  g <- sapply(levls, function(l) sum(d == l, na.rm = TRUE)); names(g) <- as.character(levls); g }
out <- list()
fit <- function(tag, d, e, seed, ...) {
  a <- sienaAlgorithmCreate(projname = NULL, seed = seed, n3 = 1000, useStdInits = FALSE, ...)
  ans <- siena07(a, data = d, effects = e, batch = TRUE, silent = TRUE, returnDeps = (seed == 12345))
  o <- data.frame(model = tag, seed = seed, param = paste0(ans$effects$effectName[ans$effects$include], " [", ans$effects$type[ans$effects$include], "]"),
                  est = ans$theta, se = sqrt(diag(ans$covtheta)), t = ans$tconv, tmax = ans$tconv.max)
  # fixed-parameter rows have se 0: keep
  out[[length(out) + 1]] <<- o
  invisible(ans)
}
dE1 <- sienaDataCreate(friendship = net3, smoke1 = smoke1)
e1 <- includeEffects(getEffects(dE1), recip, cycle3)
e1 <- includeEffects(e1, sameX, interaction1 = "smoke1")
dE3 <- sienaDataCreate(friendship = net3)
e3 <- includeEffects(getEffects(dE3), recip, transTrip)
dE4 <- sienaDataCreate(friendship = net3, drinking = sienaDependent(s50a, type = "behavior"))
e4 <- includeEffects(getEffects(dE4), recip, name = "friendship")
e4 <- includeEffects(e4, simX, interaction1 = "drinking", name = "friendship")
e4 <- includeEffects(e4, avAlt, name = "drinking", interaction1 = "friendship")
e4 <- includeEffects(e4, quad, name = "drinking", include = FALSE)
dE5 <- sienaDataCreate(friendship = net2, drinking = sienaDependent(s50a[, 1:2], type = "behavior"))
e5 <- includeEffects(getEffects(dE5), recip, name = "friendship")
e5 <- includeEffects(e5, quad, name = "drinking", include = FALSE)
e5 <- includeEffects(e5, quad, name = "drinking", type = "endow")
e5 <- includeEffects(e5, quad, name = "drinking", type = "creation")
seeds <- c(12345, 1, 2, 3, 4)
gof <- character()
for (s in seeds) {
  a1 <- fit("E1", dE1, e1, s)
  a3 <- fit("E3", dE3, e3, s)
  a4 <- fit("E4", dE4, e4, s)
  a5 <- fit("E5", dE5, e5, s)
  if (s == 12345) {
    gof <- c(gof, "E1 outdegree/indegree/geodesic", capture.output({
      print(sienaGOF(a1, OutdegreeDistribution, varName = "friendship", verbose = FALSE))
      print(sienaGOF(a1, IndegreeDistribution, varName = "friendship", verbose = FALSE))
      print(sienaGOF(a1, GeodesicDistribution, varName = "friendship", verbose = FALSE))}))
    gof <- c(gof, "E4 behavior", capture.output(print(sienaGOF(a4, BehaviorDistribution, varName = "drinking", verbose = FALSE))))
  }
  write.csv(do.call(rbind, out), args[1], row.names = FALSE); writeLines(gof, args[2])
}
