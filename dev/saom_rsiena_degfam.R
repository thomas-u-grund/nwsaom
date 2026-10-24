# RSiena centred / combined degree effects and transTriads: symmetric data (sym_w*.csv) or s50 (DATA=s50)
library(RSiena)
if (Sys.getenv("DATA", "sym") == "sym") {
	W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
	net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
} else net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
d <- sienaDataCreate(net)
specs <- strsplit(Sys.getenv("SPECS", "inPop:0 outActSqrt:0 inPop.c:0 outAct.c:0 degPlus:0 degPlus.c:0 avDeg:2 transTriads:0"), " ")[[1]]
for (sp in specs) {
	pr <- strsplit(sp, ":")[[1]]
	e <- getEffects(d)
	e <- eval(parse(text = sprintf("includeEffects(e, %s)", pr[1])))
	if (pr[2] != "0") e <- eval(parse(text = sprintf("setEffect(e, %s, parameter = %s)", pr[1], pr[2])))
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", sp, "seed", sd, ":", r, "\n")
	}
}
