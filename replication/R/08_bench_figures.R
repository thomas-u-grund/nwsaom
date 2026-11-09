# The benchmark figure of the article (difference between the mean estimates of nwsaom and RSiena, in RSiena
# standard errors: fig_bench_agree) and the timing figure (fig_bench_time, not in the article; Table 6 has
# the same numbers). Reads bench_results.json written by tools/build_tables.py.
# Run from the replication folder: Rscript R/08_bench_figures.R [TABLES_DIR [FIG_DIR]]
# Defaults: results/benchmark/tables and results/benchmark/figures.
suppressPackageStartupMessages({
  library(ggplot2); library(jsonlite); library(scales)
})
args <- commandArgs(trailingOnly = TRUE)
run <- if (length(args) > 0) args[1] else file.path("results", "benchmark", "tables")
paper <- if (length(args) > 1) args[2] else file.path("results", "benchmark", "figures")
dir.create(paper, recursive = TRUE, showWarnings = FALSE)

theme_sj <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        legend.position = "top", legend.title = element_blank(),
        plot.margin = margin(4, 8, 4, 4))
save <- function(p, name, w, h) {
  ggsave(file.path(paper, paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(paper, paste0(name, ".png")), p, width = w, height = h, dpi = 150, bg = "white")
}

groups <- c(N = "Network", U = "Undirected", C = "Co-evolution", R = "Realistic",
            S = "Larger networks", T = "Larger networks")
xgroup <- function(id) ifelse(substr(id, 1, 1) != "X", groups[substr(id, 1, 1)],
  ifelse(id %in% c("X1", "X2"), "Two-mode", ifelse(id %in% c("X3", "X4", "X5", "X6"), "Two networks", "Single network")))
glev <- c("Network", "Undirected", "Co-evolution", "Realistic", "Larger networks", "Two-mode", "Two networks", "Single network")
order <- c("N1", "N2", "N4", "N5", "N6", "N7", "U1", "U2", "C1", "C2", "C3",
           "R1", "R2", "R3", "R4", "R5", "S100", "S200", "S500", "T200",
           "X1", "X2", "X3", "X4", "X5", "X6", "X7")
nof <- c(R4 = 200, R5 = 200, S100 = 100, S200 = 200, S500 = 500, T200 = 200, X1 = "40x20", X2 = "40x30")

res <- fromJSON(file.path(run, "bench_results.json"), simplifyVector = FALSE)$models
ids <- vapply(res, `[[`, "", "id")

# ---------- 1. seconds per fit, nwsaom (1 thread) vs RSiena ----------
tm <- do.call(rbind, lapply(res, function(m) data.frame(
  id = m$id, nwsaom = m$time_nw_1core, RSiena = m$time_rs)))
tm$speedup <- tm$RSiena / tm$nwsaom
tm$group <- factor(xgroup(tm$id), levels = glev)
tm$lab <- ifelse(tm$id %in% names(nof), paste0(tm$id, " (n = ", nof[tm$id], ")"), tm$id)
tm$lab <- factor(tm$lab, levels = rev(tm$lab[order(match(tm$id, order))]))
long <- rbind(data.frame(tm[, c("lab", "group")], program = "nwsaom (1 thread)", secs = tm$nwsaom),
              data.frame(tm[, c("lab", "group")], program = "RSiena", secs = tm$RSiena))
p1 <- ggplot(tm, aes(y = lab)) +
  geom_segment(aes(x = nwsaom, xend = RSiena, yend = lab), colour = "grey70", linewidth = 0.6) +
  geom_point(data = long, aes(x = secs, shape = program, fill = program), size = 2.2) +
  geom_text(aes(x = RSiena, label = sprintf("%.1f×", speedup)), hjust = -0.35, size = 2.8) +
  scale_shape_manual(values = c("nwsaom (1 thread)" = 21, RSiena = 21), breaks = c("nwsaom (1 thread)", "RSiena")) +
  scale_fill_manual(values = c("nwsaom (1 thread)" = "white", RSiena = "black"), breaks = c("nwsaom (1 thread)", "RSiena")) +
  scale_x_log10("Seconds per fit (log scale)", breaks = c(0.1, 0.3, 1, 3, 10, 30, 100, 300),
                labels = label_number(drop0trailing = TRUE),
                expand = expansion(mult = c(0.04, 0.12))) +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  labs(y = NULL) + theme_sj +
  theme(strip.text.y = element_text(angle = 0, hjust = 0))
save(p1, "fig_bench_time", 6.2, 7.6)

# ---------- 2. agreement of the estimates ----------
ag <- do.call(rbind, lapply(res, function(m) do.call(rbind, lapply(m$rows, function(r)
  if (!is.null(r$d)) data.frame(id = m$id, param = r$param, d = r$d)))))
ag$group <- factor(xgroup(ag$id), levels = glev)
ag$id <- factor(ag$id, levels = rev(order[order %in% ag$id]))
lim <- max(0.15, ceiling(max(abs(ag$d)) * 20) / 20)
if (lim > 0.5) lim <- ceiling(lim * 4) / 4  # wide range: whole quarters, so that the breaks below fall on the limits
p2 <- ggplot(ag, aes(x = d, y = id)) +
  annotate("rect", xmin = -0.1, xmax = 0.1, ymin = -Inf, ymax = Inf, fill = "grey95") +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_point(shape = 21, fill = "grey30", colour = "white", size = 1.9, stroke = 0.3, alpha = 0.9) +
  scale_x_continuous("Difference in mean estimate, nwsaom minus RSiena, in RSiena standard errors",
                     limits = c(-lim, lim), breaks = seq(-lim, lim, by = if (lim <= 0.2) 0.05 else if (lim <= 0.5) 0.1 else 0.25),
                     labels = label_number(accuracy = 0.01)) +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  labs(y = NULL) + theme_sj +
  theme(strip.text.y = element_text(angle = 0, hjust = 0), panel.grid.major.x = element_line(colour = "grey90"))
save(p2, "fig_bench_agree", 6.2, 7.2)

cat("figures written to", normalizePath(paper), "\n")
