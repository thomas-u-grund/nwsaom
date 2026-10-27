suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("../p0/v0/w%d.csv", k), header=FALSE)))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3))); d <- sienaDataCreate(net)
e <- getEffects(d); e <- includeEffects(e, recip, transTrip, cycle3, inPopSqrt, outAct)
run <- function(th, lab) {
  e$initialValue[e$shortName=='density'] <- th[1]; e$initialValue[e$shortName=='recip'] <- th[2]; e$initialValue[e$shortName=='inPopSqrt'] <- th[3]
  e$initialValue[e$shortName=='outAct'] <- th[4]; e$initialValue[e$shortName=='transTrip'] <- th[5]; e$initialValue[e$shortName=='cycle3'] <- th[6]
  e$fix[e$include] <- TRUE
  res <- NULL
  for (s in 1:8) { a <- siena07(sienaAlgorithmCreate(projname=NULL, seed=s, n3=5000, nsub=0, cond=TRUE, simOnly=TRUE), data=d, effects=e, batch=TRUE, silent=TRUE); res <- rbind(res, colMeans(a$sf)/apply(a$sf,2,sd)) }
  cat(lab, "t(outdeg recip transTrip cycle3 inPop outAct):", round(colMeans(res),3), "\n")
}
run(c(-1.307,2.331,-0.392,-0.152,0.873,-0.175), "AT_NWSAOM")
run(c(-1.284,2.321,-0.400,-0.152,0.856,-0.146), "AT_R")
