suppressMessages(library(RSiena))
x <- allEffects; print(class(x));
x <- as.data.frame(x)
cat(as.character(packageVersion("RSiena")), nrow(x), length(unique(x$shortName)), "\n")
write.csv(x[,intersect(c("effectGroup","shortName","effectName","type","parm","interaction1","interaction2","interactionType","functionName"),names(x))], "all.csv", row.names=FALSE)
