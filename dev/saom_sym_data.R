# symmetric 3-wave data (n = 50) for the non-directed effect comparisons
set.seed(7)
n <- 50
A <- matrix(0, n, n); for (i in 1:(n-1)) for (j in (i+1):n) if (runif(1) < .10) { A[i,j] <- 1; A[j,i] <- 1 }
W <- list(A)
for (w in 2:3) { B <- W[[w-1]]; for (i in 1:(n-1)) for (j in (i+1):n) if (runif(1) < .05) { B[i,j] <- 1 - B[i,j]; B[j,i] <- B[i,j] }; W[[w]] <- B }
for (w in 1:3) write.csv(W[[w]], sprintf("sym_w%d.csv", w), row.names = FALSE)
