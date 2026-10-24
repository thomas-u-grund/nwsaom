# two-mode (bipartite) SAOM reference: RSiena simulates 3 waves (40 actors x 20 events) from KNOWN parameters, writes the
# waves and RSiena's own estimates and targets for the same data; nwsaom (dev/saom_rsiena_twomode.do) re-estimates.
library(RSiena)
set.seed(11)
x1 <- matrix(rbinom(40 * 20, 1, 0.12), 40, 20)
ega <- rnorm(40); altb <- rnorm(20)
A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
dep <- sienaDependent(array(c(x1, x1, x1), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
cv1 <- coCovar(ega, nodeSet = "A"); cv2 <- coCovar(altb, nodeSet = "B")
dat <- sienaDataCreate(dep, cv1, cv2, nodeSets = list(A, B))
eff <- getEffects(dat)
eff <- includeEffects(eff, inPopSqrt, outAct, cycle4)
eff <- includeEffects(eff, egoX, interaction1 = "cv1")
eff <- includeEffects(eff, altX, interaction1 = "cv2")
truth <- list(Rate = c(4, 3), density = -2.2, inPopSqrt = 0.5, outAct = 0.04, cycle4 = 0.12, egoX = 0.4, altX = 0.3)
sv <- function(sn, v) eff$initialValue[eff$shortName == sn & eff$type == "eval"] <<- v
eff$initialValue[eff$shortName == "Rate" & eff$period == 1] <- 4
eff$initialValue[eff$shortName == "Rate" & eff$period == 2] <- 3
for (nm in c("density", "inPopSqrt", "outAct", "cycle4", "egoX", "altX")) sv(nm, truth[[nm]])
# simulate period by period: wave 2 from wave 1, wave 3 from wave 2
simfrom <- function(x, rate) {
	dep1 <- sienaDependent(array(c(x, x), dim = c(40, 20, 2)), type = "bipartite", nodeSet = c("A", "B"), allowOnly = FALSE)
	d1 <- sienaDataCreate(dep1, cv1, cv2, nodeSets = list(A, B))
	e1 <- getEffects(d1)
	e1 <- includeEffects(e1, inPopSqrt, outAct, cycle4)
	e1 <- includeEffects(e1, egoX, interaction1 = "cv1"); e1 <- includeEffects(e1, altX, interaction1 = "cv2")
	e1$initialValue[e1$shortName == "Rate"] <- rate
	for (nm in c("density", "inPopSqrt", "outAct", "cycle4", "egoX", "altX")) e1$initialValue[e1$shortName == nm & e1$type == "eval"] <- truth[[nm]]
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sample(1e6, 1), cond = FALSE, nsub = 0, n3 = 2, simOnly = TRUE)
	ans <- siena07(alg, data = d1, effects = e1, batch = TRUE, silent = TRUE, returnDeps = TRUE)
	m <- matrix(0, 40, 20); el <- ans$sims[[1]][[1]][[1]][[1]]; m[el[, 1:2, drop = FALSE]] <- 1
	m
}
x2 <- simfrom(x1, 4); x3 <- simfrom(x2, 3)
w <- list(x1, x2, x3)
for (k in 1:3) write.csv(w[[k]], sprintf("dev/saom_twomode_w%d.csv", k), row.names = FALSE)
write.csv(data.frame(ega = ega), "dev/saom_twomode_cvA.csv", row.names = FALSE)
write.csv(data.frame(altb = altb), "dev/saom_twomode_cvB.csv", row.names = FALSE)
cat("edges:", sapply(w, sum), " changes:", sum(abs(x1 - x2)), sum(abs(x2 - x3)), "\n")
dep <- sienaDependent(array(unlist(w), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
dat <- sienaDataCreate(dep, cv1, cv2, nodeSets = list(A, B))
eff <- getEffects(dat)
eff <- includeEffects(eff, inPopSqrt, outAct, cycle4)
eff <- includeEffects(eff, egoX, interaction1 = "cv1"); eff <- includeEffects(eff, altX, interaction1 = "cv2")
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- try(siena07(alg, data = dat, effects = eff, batch = TRUE, silent = TRUE), silent = TRUE)
	if (inherits(ans, "try-error")) cat(sprintf("RSIENA seed %d failed\n", sd))
	else cat(sprintf("RSIENA seed %d targets: %s\n  est: %s\n  names: %s\n", sd, paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(ans$effects$effectName, collapse = " | ")))
}
