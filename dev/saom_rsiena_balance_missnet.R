# balance endow/creation with missing network entries: RSiena reference (nwsaom: dev/saom_rsiena_balance_missnet.do)
library(RSiena)
data(s501); data(s502); data(s503)
W <- list(s501, s502, s503)
set.seed(99)
masks <- lapply(1:3, function(w) { m <- matrix(0, 50, 50); idx <- sample(which(row(m) != col(m)), 100); m[idx] <- 1; m })
for (w in 1:3) {
	x <- W[[w]]; x[masks[[w]] == 1] <- NA
	write.csv(ifelse(is.na(x), 0, x), sprintf("dev/saom_rsiena_balmiss_w%d.csv", w), row.names = FALSE)
	write.csv(masks[[w]], sprintf("dev/saom_rsiena_balmiss_m%d.csv", w), row.names = FALSE)
	W[[w]] <- x
}
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- getEffects(d)
e <- includeEffects(e, recip)
e <- includeEffects(e, balance, type = "endow")
e <- includeEffects(e, balance, type = "creation")
for (sd in 1:3) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA seed %d targets: %s | est: %s\n", sd, paste(round(ans$targets, 2), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
