# Installs the R packages used by the replication scripts, at the versions of the article.
# Run once, from the replication folder:  Rscript R/00_install.R
# RSiena 1.6.14 is not on CRAN (CRAN has 1.6.6); it is installed from the release tag v1.6.14 of the
# RSiena repository (github.com/stocnet/rsiena), which needs a C++ compiler (Rtools on Windows, Xcode
# command line tools on macOS). The article used R 4.6.0.
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
have <- function(p, v) requireNamespace(p, quietly = TRUE) && as.character(packageVersion(p)) == v
if (!have("RSiena", "1.6.14")) remotes::install_github("stocnet/rsiena@v1.6.14", upgrade = "never")
# for the benchmark figure only
for (p in list(c("ggplot2", "4.0.3"), c("jsonlite", "2.0.0"), c("scales", "1.4.0")))
  if (!have(p[1], p[2])) remotes::install_version(p[1], p[2], upgrade = "never")
for (p in c("RSiena", "ggplot2", "jsonlite", "scales")) cat(sprintf("%-10s %s\n", p, packageVersion(p)))
cat(R.version.string, "\n")
