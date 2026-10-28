suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3)))
d <- sienaDataCreate(net)
e <- getEffects(d); e <- includeEffects(e, transTies, inPopSqrt)
e$initialValue[e$shortName=='density'] <- -1.2; e$initialValue[e$shortName=='transTies'] <- 0.3; e$initialValue[e$shortName=='inPopSqrt'] <- 0.1
e$fix[e$include & e$shortName!='Rate'] <- TRUE
for (s in 1:3) { ans <- siena07(sienaAlgorithmCreate(projname=NULL, seed=s, n3=500, nsub=4, cond=FALSE, modelType=c(net=6)), data=d, effects=e, batch=TRUE, silent=TRUE); cat("RATES", ans$theta[1:2], "\n") }
