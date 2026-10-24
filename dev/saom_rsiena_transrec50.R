library(RSiena)
data(s501); data(s502); data(s503)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
e <- getEffects(d)
e <- includeEffects(e, recip)
e <- includeEffects(e, transRecTrip, type = "endow")
e <- includeEffects(e, transRecTrip, type = "creation")
for (sd in 1:50) {
	alg <- sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4)
	r <- tryCatch({
		ans <- siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE)
		sprintf("%s fixed=%s", paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(which(ans$fix), collapse = ","))
	}, error = function(err) paste("ERROR", conditionMessage(err)))
	cat(sprintf("RTR seed %d: %s\n", sd, r))
}
