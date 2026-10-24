library(RSiena)
data(s501); data(s502); data(s503)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
for (ef in c("transTrip", "cycle3", "transMedTrip", "transRecTrip")) {
	e <- getEffects(d)
	e <- includeEffects(e, recip)
	e <- do.call(includeEffects, list(e, as.name(ef), type = "endow"))
	e <- do.call(includeEffects, list(e, as.name(ef), type = "creation"))
	alg <- sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 600, nsub = 4)
	r <- tryCatch({
		ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
		sprintf("targets %s | est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "))
	}, error = function(err) paste("ERROR", conditionMessage(err)))
	cat(sprintf("TRI %s: %s\n", ef, r))
}
