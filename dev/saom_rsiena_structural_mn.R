# nwsaom multinet with structural codes in the first network: RSiena reference. Usage: Rscript dev/saom_rsiena_structural_mn.R <dir with w1..w3.csv (coded)> targets|est [seeds] [n3]
suppressMessages(library(RSiena))
args <- commandArgs(TRUE); dir <- args[1]; task <- args[2]; nseed <- if (length(args) >= 3) as.integer(args[3]) else 8; n3 <- if (length(args) >= 4) as.integer(args[4]) else 1000
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("%s/w%d.csv", dir, k), header = FALSE)))
b <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_mn_b%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim = c(50, 50, 3))); adv <- sienaDependent(array(unlist(b), dim = c(50, 50, 3)))
d <- sienaDataCreate(net, adv)
e <- getEffects(d)
e <- includeEffects(e, recip, transTrip, name = "net")
e <- includeEffects(e, crprod, name = "net", interaction1 = "adv")
e <- includeEffects(e, recip, name = "adv")
e <- includeEffects(e, crprodRecip, name = "adv", interaction1 = "net")
if (task == "targets") {
  a <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
  cat("RTGT", round(a$targets, 4), "\n"); print(as.data.frame(e)[e$include, c("name", "shortName", "type")])
}
if (task == "est") {
  res <- NULL
  for (s in 1:nseed) { a <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 400 + s, n3 = n3, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE); res <- rbind(res, c(a$theta, a$tconv.max)) }
  cat("MEAN", round(colMeans(res), 3), "\n"); cat("SE", round(apply(res, 2, sd) / sqrt(nseed), 3), "\n")
}
