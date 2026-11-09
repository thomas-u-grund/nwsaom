# Helpers shared by the R scripts. Every script is run from the replication folder (Rscript R/NN_name.R).
if (!file.exists("R/common.R")) stop("run the R scripts from the replication folder: Rscript R/NN_name.R")
suppressMessages(library(RSiena))
if (as.character(packageVersion("RSiena")) != "1.6.14")
  warning("the article used RSiena 1.6.14; this is ", packageVersion("RSiena"), " (run R/00_install.R)")
# The Glasgow excerpt (50 pupils, three waves) as data/glasgow/*.csv. It is the same data as RSiena's
# s501, s502, s503, s50a, s50s (structural codes above 1 set to 0); R/01_check_data.R checks that.
glasgow_wave <- function(w) unname(as.matrix(read.csv(sprintf("data/glasgow/s50_friend_w%d.csv", w), header = FALSE)))
glasgow_actors <- function() read.csv("data/glasgow/s50_actors.csv")
# read a 0/1 adjacency matrix without header (data/groups, data/benchmark)
read_adj <- function(f) { m <- unname(as.matrix(read.csv(f, header = FALSE))); diag(m) <- 0; m }
out_dir <- function(...) { d <- file.path("results", ...); dir.create(d, recursive = TRUE, showWarnings = FALSE); d }
