suppressMessages(library(RSiena))
set.seed(1)
n <- 50
out <- list()
add <- function(eff, cfg){
  d <- data.frame(config=cfg, name=eff$name, shortName=eff$shortName, effectName=eff$effectName,
     type=eff$type, parm=eff$parm, interaction1=eff$interaction1, interaction2=eff$interaction2,
     interactionType=eff$interactionType, functionName=eff$functionName, netType=eff$netType, rateType=eff$rateType, setting=eff$setting, period=eff$period, effectNumber=eff$effectNumber, stringsAsFactors=FALSE)
  out[[length(out)+1]] <<- d
}
## one-mode
fr <- sienaDependent(array(c(s501,s502,s503), dim=c(50,50,3)))
beh <- sienaDependent(s50a[,1:3], type='behavior')
beh2 <- sienaDependent(s50s[,1:3], type='behavior')
cc <- coCovar(s50a[,1]); cc2 <- coCovar(s50s[,1])
vc <- varCovar(s50a[,1:2]); vc2 <- varCovar(s50s[,1:2])
dc <- coDyadCovar(matrix(rbinom(2500,1,.1),50,50)); 
vdc <- varDyadCovar(array(rbinom(5000,1,.1),dim=c(50,50,2)))
net2 <- sienaDependent(array(c(s502,s503,s501), dim=c(50,50,3)))
# 1 net, with all covariates
d1 <- sienaDataCreate(fr, cc, vc, dc, vdc)
add(getEffects(d1), "onemode_net+covars (coCovar,varCovar,coDyad,varDyad)")
# behavior + 1 net + covariates
d2 <- sienaDataCreate(fr, beh, cc, vc, dc, vdc)
e2 <- getEffects(d2)
add(e2, "net+beh (cov: co,var,dyad)")
# two behaviors + net + second behavior
d3 <- sienaDataCreate(fr, beh, beh2, cc, vc)
add(getEffects(d3), "net+2beh")
# two nets + beh
d4 <- sienaDataCreate(fr, net2, beh, cc)
add(getEffects(d4), "2net+beh")
# 3 nets
net3 <- sienaDependent(array(c(s503,s501,s502), dim=c(50,50,3)))
d5 <- sienaDataCreate(fr, net2, net3)
add(getEffects(d5), "3net")
# two-mode
A <- array(rbinom(30*15*3,1,.2), dim=c(30,15,3))
bip <- sienaDependent(A, type='bipartite', nodeSet=c("A","B"))
Aset <- sienaNodeSet(30,"A"); Bset <- sienaNodeSet(15,"B")
bip <- sienaDependent(A, type='bipartite', nodeSet=c("A","B"))
ccA <- coCovar(rnorm(30), nodeSet="A"); ccB <- coCovar(rnorm(15), nodeSet="B")
vcA <- varCovar(matrix(rnorm(60),30,2), nodeSet="A")
dcAB <- coDyadCovar(matrix(rbinom(450,1,.2),30,15), nodeSets=c("A","B"))
bh <- sienaDependent(matrix(sample(0:3,90,TRUE),30,3), type='behavior', nodeSet="A")
d6 <- sienaDataCreate(bip, ccA, ccB, vcA, dcAB, nodeSets=list(Aset,Bset))
add(getEffects(d6), "twomode")
d7 <- sienaDataCreate(bip, bh, ccA, nodeSets=list(Aset,Bset))
add(getEffects(d7), "twomode+beh")
# one-mode net + two-mode?
n1 <- sienaDependent(array(rbinom(30*30*3,1,.1),dim=c(30,30,3)), nodeSet="A")
d8 <- sienaDataCreate(n1, bip, nodeSets=list(Aset,Bset))
add(getEffects(d8), "onemodeA+twomode")
# continuous
cont <- try(sienaDependent(matrix(rnorm(150),50,3), type='continuous'))
if(!inherits(cont,'try-error')){
 d9 <- sienaDataCreate(fr, cont); add(getEffects(d9), "net+continuous")
}

sym <- function(m){ m <- ((m + t(m))>0)*1; diag(m)<-0; m }
sa <- array(c(sym(s501),sym(s502),sym(s503)), dim=c(50,50,3))
sfr <- sienaDependent(sa)
sfr2 <- sienaDependent(array(c(sym(s502),sym(s503),sym(s501)), dim=c(50,50,3)))
d11 <- sienaDataCreate(sfr, cc, vc, dc, vdc); add(getEffects(d11), "SYM net+covars")
d12 <- sienaDataCreate(sfr, beh, cc, dc); add(getEffects(d12), "SYM net+beh")
d13 <- sienaDataCreate(sfr, sfr2); add(getEffects(d13), "SYM 2net")
res <- do.call(rbind,out)
write.csv(res, "raw.csv", row.names=FALSE)
print(table(res$config))
print(table(res$config, res$type))
