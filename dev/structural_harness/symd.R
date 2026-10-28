suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3))); d <- sienaDataCreate(net)
for (mt in c(6,2,3)) {
e <- getEffects(d)
e$initialValue[e$shortName=='density'] <- -1.2
e$fix[e$include & e$shortName!='Rate'] <- TRUE
a <- siena07(sienaAlgorithmCreate(projname=NULL, seed=1, n3=1000, nsub=4, cond=FALSE, modelType=c(net=mt)), data=d, effects=e, batch=TRUE, silent=TRUE); cat("DRATES modelType", mt, a$theta[1:2], "\n") }
