# Compares the nwsaom runs (exN_nwsaom.csv, ten seeds) with the RSiena runs (exN_rsiena.csv, ten seeds): means over seeds.
# Table 4 of the article and the agreement numbers of Section 5.9. Run from the replication folder after
# stata/03_groups_ex1.do to 05_groups_ex4.do and R/03_groups_ex1.R to 05_groups_ex4.R:
#     Rscript R/06_groups_compare.R   (writes results/groups/compare.log)
dir.create("results/groups", recursive = TRUE, showWarnings = FALSE)
sink("results/groups/compare.log", split = TRUE)
mean_by <- function(f) {
  d <- read.csv(f)
  m <- aggregate(cbind(theta, se) ~ name, d, mean)
  s <- aggregate(theta ~ name, d, sd); names(s)[2] <- "sd"
  merge(m, s, by = "name")
}
tab <- function(title, fn, fr, map) {
  a <- mean_by(fn); b <- mean_by(fr)
  out <- data.frame(row.names = NULL, parameter = names(map), nwsaom = NA, RSiena = NA, diff = NA, se_nwsaom = NA, se_RSiena = NA, sd_seeds = NA)
  for (i in seq_along(map)) {
    x <- a[a$name == names(map)[i], ]; y <- b[b$name == map[[i]], ]
    if (nrow(x) != 1 || nrow(y) != 1) stop("missing: ", names(map)[i], " / ", map[[i]])
    out[i, -1] <- c(x$theta, y$theta, x$theta - y$theta, x$se, y$se, max(x$sd, y$sd))
  }
  cat("\n", title, "\n", strrep("-", nchar(title)), "\n", sep = "")
  print(format(out, digits = 3, nsmall = 3), row.names = FALSE)
  cat("largest |difference| of an effect (not rate):", round(max(abs(out$diff[!grepl("^(rate|beh)?period", out$parameter)])), 3), "\n")
}
tab("Example 1: four classes, joint model (means of 10 seeds each)", "results/groups/ex1_nwsaom.csv", "results/groups/ex1_rsiena.csv",
    list(outdegree = "outdegree (density)", reciprocity = "reciprocity", transtrip = "transitive triplets",
         period1 = "rate 1", period3 = "rate 2", period5 = "rate 3", period7 = "rate 4"))
tab("Example 3a: co-evolution of friendship and alcohol use, three groups", "results/groups/ex3a_nwsaom.csv", "results/groups/ex3a_rsiena.csv",
    list(outdegree = "outdegree (density)", reciprocity = "reciprocity", transtrip = "transitive triplets",
         behegox = "alc ego", behaltx = "alc alter", beh_linear = "alc linear shape", beh_quadratic = "alc quadratic shape", beh_avalt = "alc average alter",
         period1 = "constant net rate (period 1)", period2 = "constant net rate (period 2)", period4 = "constant net rate (period 4)",
         period5 = "constant net rate (period 5)", period7 = "constant net rate (period 7)", period8 = "constant net rate (period 8)",
         behperiod1 = "rate alc (period 1)", behperiod2 = "rate alc (period 2)", behperiod4 = "rate alc (period 4)",
         behperiod5 = "rate alc (period 5)", behperiod7 = "rate alc (period 7)", behperiod8 = "rate alc (period 8)"))
tab("Example 3b: groups with 3, 2 and 2 waves (RSiena: equivalent object of two-wave groups)", "results/groups/ex3b_nwsaom.csv", "results/groups/ex3b_rsiena.csv",
    list(outdegree = "outdegree (density)", reciprocity = "reciprocity", transtrip = "transitive triplets",
         period1 = "rate 1", period2 = "rate 2", period4 = "rate 3", period6 = "rate 4"))
# Example 4: test statistics
a <- read.csv("results/groups/ex4_nwsaom.csv"); b <- read.csv("results/groups/ex4_rsiena.csv")
mm <- function(d, w, k) mean(d$c[d$what == w & d$k == k])
rows <- list(
  list("joint time test (25 d.f.)", mm(a, "joint", 0), mm(b, "joint", 0)),
  list("outdegree (5 d.f.)", mm(a, "effect", 1), mm(b, "effect", 1)),
  list("reciprocity (5 d.f.)", mm(a, "effect", 2), mm(b, "effect", 2)),
  list("altx_alc (5 d.f.)", mm(a, "effect", 3), mm(b, "effect", 4)),
  list("egox_alc (5 d.f.)", mm(a, "effect", 4), mm(b, "effect", 5)),
  list("transtrip (5 d.f.)", mm(a, "effect", 5), mm(b, "effect", 3)))
for (k in 1:6) rows[[length(rows) + 1]] <- list(sprintf("period %d (5 d.f.; RSiena: 'group' test)", k), mm(a, "period", k), mm(b, "group", k))
rows[[length(rows) + 1]] <- list("score test, altx + egox (2 d.f.)", mm(a, "score", 0), mm(b, "score", 0))
out <- data.frame(test = sapply(rows, `[[`, 1), nwsaom = sapply(rows, `[[`, 2), RSiena = sapply(rows, `[[`, 3))
out$diff <- out$nwsaom - out$RSiena
cat("\nExample 4: time-heterogeneity tests and score test, three groups (c = chi-squared statistic; means of 10 seeds each)\n", strrep("-", 90), "\n", sep = "")
print(format(out, digits = 3, nsmall = 2), row.names = FALSE)
sink()
