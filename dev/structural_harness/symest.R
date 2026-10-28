suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3))); d <- sienaDataCreate(net)
e <- getEffects(d); e <- includeEffects(e, transTies, inPopSqrt)
for (s in 1:4) { a <- siena07(sienaAlgorithmCreate(projname=NULL, seed=s, n3=1000, nsub=4, cond=FALSE, modelType=c(net=6)), data=d, effects=e, batch=TRUE, silent=TRUE); cat("REST", round(a$theta,3), "\n") }
