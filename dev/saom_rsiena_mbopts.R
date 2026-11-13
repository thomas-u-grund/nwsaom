# Several co-evolving behaviors (alcohol and smoking, s50) together with the options that were refused before: composition change
# (present()), structural zeros (code 10), missing data (missnet()/missbeh()), network endowment/creation, ratecov() and a
# non-directed network. RSiena 1.6.14 reference: the targets (observed statistics) and the estimates of three seeds per model.
# Run from the repository root: Rscript dev/saom_rsiena_mbopts.R [A B C D E F]  (Stata side: dev/saom_rsiena_mbopts.do)
# Writes the data the Stata side reads: dev/saom_rsiena_mbopts_*.csv
library(RSiena)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) args <- c("A", "B", "C", "D", "E", "F")
data(s501); data(s502); data(s503); data(s50a); data(s50s)
W <- list(s501, s502, s503)
mkeff <- function(d, sym = FALSE) {
	e <- getEffects(d)
	if (!sym) e <- includeEffects(e, recip, transTrip) else e <- includeEffects(e, transTriads)
	e <- includeEffects(e, simX, interaction1 = "alc")
	e <- includeEffects(e, simX, interaction1 = "smk")
	e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
	e <- includeEffects(e, avAlt, name = "smk", interaction1 = "net")
	e
}
run <- function(tag, d, e, sym = FALSE, seeds = 1:3) {
	a0 <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, modelType = if (sym) c(net = 2) else NULL), data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA %s targets: %s\n  names: %s\n", tag, paste(round(a0$targets, 4), collapse = " "), paste(a0$effects$effectName, collapse = " | ")))
	for (sd in seeds) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, modelType = if (sym) c(net = 2) else NULL), data = d, effects = e, batch = TRUE, silent = TRUE)
		cat(sprintf("RSIENA %s seed %d tconv %.3f\n  est: %s\n  se: %s\n", tag, sd, ans$tconv.max, paste(round(c(ans$rate, ans$theta), 3), collapse = " "),
			paste(round(c(ans$vrate, sqrt(diag(ans$covtheta))), 3), collapse = " ")))
	}
}
behs <- function() list(alc = sienaDependent(s50a, type = "behavior"), smk = sienaDependent(s50s, type = "behavior"))
# A. composition change: actors 1-4 join at wave 2, actors 47-50 leave at wave 2
if ("A" %in% args) {
	iv <- lapply(1:50, function(i) if (i <= 4) c(2, 3) else if (i >= 47) c(1, 2) else c(1, 3))
	pres <- t(sapply(1:50, function(i) if (i <= 4) c(0, 1, 1) else if (i >= 47) c(1, 1, 0) else c(1, 1, 1)))
	write.csv(pres, "dev/saom_rsiena_mbopts_present.csv", row.names = FALSE)
	b <- behs()
	d <- sienaDataCreate(net = sienaDependent(array(unlist(W), dim = c(50, 50, 3))), alc = b$alc, smk = b$smk, cc = sienaCompositionChange(iv))
	run("A present", d, mkeff(d))
}
# B. structural zeros: the dyads between actors 1-10 and 41-50 (both directions) are structurally 0 at every wave
if ("B" %in% args) {
	Ws <- lapply(W, function(x) { x[1:10, 41:50] <- 10; x[41:50, 1:10] <- 10; x })
	for (w in 1:3) write.csv(Ws[[w]], sprintf("dev/saom_rsiena_mbopts_struct_w%d.csv", w), row.names = FALSE)
	b <- behs()
	d <- sienaDataCreate(net = sienaDependent(array(unlist(Ws), dim = c(50, 50, 3))), alc = b$alc, smk = b$smk)
	run("B structural", d, mkeff(d))
}
# C. missing data: rows of actors 5-7 missing at wave 2 (the network), alcohol of actors 8-10 at wave 2 and smoking of 11-12 at wave 3 missing
if ("C" %in% args) {
	Wm <- W
	Wm[[2]][5:7, ] <- NA
	diag(Wm[[2]]) <- 0
	am <- s50a; am[8:10, 2] <- NA
	sm <- s50s; sm[11:12, 3] <- NA
	for (w in 1:3) write.csv(ifelse(is.na(Wm[[w]]), 1, 0), sprintf("dev/saom_rsiena_mbopts_missnet_w%d.csv", w), row.names = FALSE)
	write.csv(cbind(ifelse(is.na(am), 1, 0), ifelse(is.na(sm), 1, 0)), "dev/saom_rsiena_mbopts_missbeh.csv", row.names = FALSE)
	d <- sienaDataCreate(net = sienaDependent(array(unlist(Wm), dim = c(50, 50, 3))), alc = sienaDependent(am, type = "behavior"), smk = sienaDependent(sm, type = "behavior"))
	run("C missing", d, mkeff(d))
}
# D. network endowment and creation of reciprocity
if ("D" %in% args) {
	b <- behs()
	d <- sienaDataCreate(net = sienaDependent(array(unlist(W), dim = c(50, 50, 3))), alc = b$alc, smk = b$smk)
	e <- mkeff(d)
	e <- includeEffects(e, recip, include = FALSE)
	e <- includeEffects(e, recip, type = "endow")
	e <- includeEffects(e, recip, type = "creation")
	run("D endow", d, e)
}
# E. a rate covariate of the network (alcohol at wave 1, constant)
if ("E" %in% args) {
	b <- behs()
	cov <- coCovar(s50a[, 1])
	d <- sienaDataCreate(net = sienaDependent(array(unlist(W), dim = c(50, 50, 3))), alc = b$alc, smk = b$smk, cov = cov)
	e <- mkeff(d)
	e <- includeEffects(e, RateX, type = "rate", interaction1 = "cov", name = "net")
	run("E ratecov", d, e)
}
# F. non-directed network (the symmetrised s50 waves), forcing model (modelType 2)
if ("F" %in% args) {
	Wsym <- lapply(W, function(x) pmax(x, t(x)))
	for (w in 1:3) write.csv(Wsym[[w]], sprintf("dev/saom_rsiena_mbopts_sym_w%d.csv", w), row.names = FALSE)
	b <- behs()
	d <- sienaDataCreate(net = sienaDependent(array(unlist(Wsym), dim = c(50, 50, 3))), alc = b$alc, smk = b$smk)
	run("F symmetric", d, mkeff(d, sym = TRUE), sym = TRUE, seeds = 2:4)	# seed 1 diverges (thetaBound)
}
