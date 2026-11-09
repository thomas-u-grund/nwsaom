# Checks that the CSV files in data/ hold the same data as the copies the scripts use:
# RSiena's s501-s503, s50a, s50s (Glasgow excerpt) and N3401 ... HN3406 (four Dutch school classes).
# The Stata side does the same check in stata/01_check_data.do against nwcommands' copy (nwwebuse glasgow).
source("R/common.R")
ok <- TRUE
chk <- function(what, a, b) { same <- identical(dim(a), dim(b)) && all(a == b); cat(sprintf("%-40s %s\n", what, if (same) "identical" else "DIFFERENT")); ok <<- ok && same }
cl <- function(x) { x <- unname(as.matrix(x)); x[x > 1] <- 0; x }
for (w in 1:3) chk(sprintf("Glasgow friendship wave %d", w), glasgow_wave(w), cl(get(sprintf("s50%d", w))))
a <- glasgow_actors()
chk("Glasgow alcohol use, waves 1-3", as.matrix(a[, c("alcohol1", "alcohol2", "alcohol3")]), unname(as.matrix(s50a)))
chk("Glasgow smoking, waves 1-3", as.matrix(a[, c("smoke1", "smoke2", "smoke3")]), unname(as.matrix(s50s)))
cls <- c(1, 3, 4, 6)
for (k in 1:4) for (w in 1:2) {
  r <- get(sprintf("%sN340%d", if (w == 2) "H" else "", cls[k]))
  r <- unname(as.matrix(r)); r[is.na(r) | r > 1] <- 0; diag(r) <- 0
  chk(sprintf("school class %d, wave %d", k, w), read_adj(sprintf("data/groups/school%d_wave%d.csv", k, w)), r)
}
cat(if (ok) "All data identical.\n" else "Some data differ.\n")
