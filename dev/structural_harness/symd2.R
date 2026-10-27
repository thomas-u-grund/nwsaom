suppressMessages(library(RSiena))
w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
net <- sienaDependent(array(unlist(w), dim=c(50,50,3))); d <- sienaDataCreate(net)
go <- function(lab, add, vals) {
  e <- getEffects(d); e <- add(e)
  for (n in names(vals)) e$initialValue[e$shortName==n] <- vals[[n]]
  e$fix[e$include & e$shortName!='Rate'] <- TRUE
  a <- siena07(sienaAlgorithmCreate(projname=NULL, seed=1, n3=1000, nsub=4, cond=FALSE, modelType=c(net=6)), data=d, effects=e, batch=TRUE, silent=TRUE); cat("DR", lab, round(a$theta[1:2],4), "\n") }
go("transTies", function(e) includeEffects(e, transTies), list(density=-1.2, transTies=0.3))
go("inPopSqrt", function(e) includeEffects(e, inPopSqrt), list(density=-1.2, inPopSqrt=0.1))
