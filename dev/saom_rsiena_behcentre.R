# Behavior centring with missing behavior data (RSiena_QUIRKS_part3 C2): RSiena centres by the mean of the wave means of the
# OBSERVED values. Writes dev/saom_behcentre_data.csv (s50a with missing values) and prints the observed statistics and estimates.
library(RSiena)
b <- s50a[, 1:3]
set.seed(7)
b[sample(50, 15), 3] <- NA     # 15 missing in wave 3
b[c(4, 19, 33), 1] <- NA
b[c(8, 40), 2] <- NA
cat("mean of wave means:", mean(colMeans(b, na.rm = TRUE)), " pooled:", mean(b, na.rm = TRUE), "\n")
write.csv(data.frame(a1 = b[, 1], a2 = b[, 2], a3 = b[, 3], m1 = is.na(b[, 1]) * 1, m2 = is.na(b[, 2]) * 1, m3 = is.na(b[, 3]) * 1, f1 = s50a[, 1], f2 = s50a[, 2], f3 = s50a[, 3]),
	"dev/saom_behcentre_data.csv", row.names = FALSE, na = "")
run <- function(bb, tag) {
	net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
	beh <- sienaDependent(bb, type = "behavior")
	d <- sienaDataCreate(net, beh)
	e <- getEffects(d)
	e <- includeEffects(e, recip)
	e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
	e <- includeEffects(e, quad, name = "beh")
	for (sd in 1:3) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
		cat("RSIENA", tag, "seed", sd, "targets", paste(round(ans$targets, 3), collapse = " "), "\n")
		cat("RSIENA", tag, "seed", sd, "est", paste(round(c(ans$rate, ans$theta), 3), collapse = " "), "\n")
	}
}
run(b, "miss")
run(s50a[, 1:3], "complete")
