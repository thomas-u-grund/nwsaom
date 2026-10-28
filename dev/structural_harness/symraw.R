suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3)))
d <- sienaDataCreate(net)
e <- getEffects(d); e <- includeEffects(e, transTies, inPopSqrt)
e$initialValue[e$shortName=='density'] <- -1.2; e$initialValue[e$shortName=='transTies'] <- 0.3; e$initialValue[e$shortName=='inPopSqrt'] <- 0.1
e$initialValue[e$shortName=='Rate'] <- 1; e$fix[e$include] <- TRUE
ans <- siena07(sienaAlgorithmCreate(projname=NULL, seed=1, n3=400, nsub=0, cond=FALSE, simOnly=TRUE, modelType=c(net=6)), data=d, effects=e, batch=TRUE, silent=TRUE)
cat("MEANDEV", colMeans(ans$sf), "\n")
cat("SDDEV", apply(ans$sf,2,sd), "\n")
