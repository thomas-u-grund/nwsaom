# network reciprocity endow/creation + behavior (alcohol) co-evolution, 2 waves: RSiena reference
library(RSiena)
data(s501); data(s502); data(s50a)
write.csv(data.frame(a1 = s50a[, 1], a2 = s50a[, 2]), "dev/saom_rsiena_coev_netendow_beh.csv", row.names = FALSE)
net <- sienaDependent(array(c(s501, s502), dim = c(50, 50, 2)))
alc <- sienaDependent(s50a[, 1:2], type = "behavior")
d <- sienaDataCreate(net, alc)
e <- getEffects(d)
e <- includeEffects(e, recip, type = "eval", include = FALSE)
e <- includeEffects(e, recip, type = "endow")
e <- includeEffects(e, recip, type = "creation")
e <- includeEffects(e, avAlt, name = "alc", interaction1 = "net")
print(as.data.frame(e)[as.data.frame(e)$include, c("name", "shortName", "type")])
for (sd in 1:3) {
	t0 <- Sys.time()
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
	cat(sprintf("RSIENA seed %d %.1f s targets: %s\n   est: %s\n", sd, as.numeric(Sys.time() - t0, units = "secs"), paste(round(ans$targets, 2), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")))
}
