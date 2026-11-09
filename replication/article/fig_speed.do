* Time per fit of nwsaom and RSiena on the 27 benchmark models (figure fig_speed.pdf of the article).
* Same form as the speed figure of the nwergm article. Reads the raw benchmark rows (one row per fit).
* Run from the replication folder: do article/fig_speed.do   Output in results/article.
version 17
capture mkdir results
capture mkdir results/article
capture set scheme stsj
if _rc set scheme sj
tempfile main
import delimited using results/benchmark/raw/saom_main.csv, clear varnames(1) stringcols(_all) delimiters(",") bindquote(strict)
save `main'
import delimited using results/benchmark/raw/saom_extra.csv, clear varnames(1) stringcols(_all) delimiters(",") bindquote(strict)
append using `main'
keep if status == "ok"
destring secs, replace
keep cell impl rep secs
* rows from the top: the order of the benchmark in Appendix D of the manual
local order N1 N2 N4 N5 N6 N7 U1 U2 C1 C2 C3 R1 R2 R3 R4 R5 S100 S200 S500 T200 X1 X2 X3 X4 X5 X6 X7
local K : word count `order'
gen row = .
forvalues i = 1/`K' {
	local m : word `i' of `order'
	quietly replace row = `K' + 1 - `i' if cell == "`m'"
}
assert row < .
label define rl 27 "N1 outdegree, reciprocity" 26 "N2 + gwesp" 25 "N4 + gwesp, samex" ///
	24 "N5 + gwesp, popularity, activity" 23 "N6 + gwesp, egox, altx, simx" 22 "N7 N2, unconditional" ///
	21 "U1 undirected, forcing" 20 "U2 undirected, joint" ///
	19 "C1 N2 + alcohol" 18 "C2 N2 + smoking" 17 "C3 N1 + alcohol" ///
	16 "R1 realistic network model" 15 "R2 R1 + alcohol" 14 "R3 realistic, undirected" ///
	13 "R4 R1, 200 actors" 12 "R5 R2, 200 actors" ///
	11 "S100 N2, 100 actors" 10 "S200 N2, 200 actors" 9 "S500 N2, 500 actors" 8 "T200 C1, 200 actors" ///
	7 "X1 two-mode" 6 "X2 two-mode" 5 "X3 two networks" 4 "X4 two networks, behavior" ///
	3 "X5 two networks, behavior" 2 "X6 undirected and directed" 1 "X7 newer effects"
label values row rl
gen y = row + cond(impl == "RSiena", 0.17, -0.17)
bysort impl row: egen med = median(secs)
gen medR0 = med if impl == "RSiena"
gen medN0 = med if impl == "nwsaom"
bysort row: egen medR = max(medR0)
bysort row: egen medN = max(medN0)
bysort row (impl rep): gen first = _n == 1
gen ratio = string(medR/medN, "%3.1f") + "{c 215}"
gen xr = 900
twoway ///
	(pcspike row medN row medR if first, lcolor(gs13) lwidth(thick)) ///
	(scatter y secs if impl == "RSiena", msymbol(Oh) mcolor(gs9) msize(tiny)) ///
	(scatter y secs if impl == "nwsaom", msymbol(Oh) mcolor(black) msize(tiny)) ///
	(scatter row medR if first, msymbol(O) mcolor(gs9) msize(small)) ///
	(scatter row medN if first, msymbol(O) mcolor(black) msize(small)) ///
	(scatter row xr if first, msymbol(none) mlabel(ratio) mlabposition(0) mlabcolor(black) mlabsize(vsmall)) ///
	, xscale(log range(0.06 1300)) ///
	xlabel(0.1 "0.1" 1 10 100, labsize(small) grid glcolor(gs14)) xmtick(0.2(0.1)0.9 2(1)9 20(10)90 200 300, grid glcolor(gs15)) ///
	ylabel(1/`K', valuelabel angle(0) labsize(vsmall) nogrid) yscale(range(0.5 `=`K'+0.9')) ///
	xtitle("Seconds per fit (log scale)", size(small)) ytitle("") ///
	text(`=`K'+0.85' 900 "faster by", size(vsmall)) ///
	legend(order(5 "nwsaom" 4 "RSiena 1.6.14") ///
		rows(1) size(small) position(6) symxsize(*0.5)) ///
	graphregion(color(white) margin(l=8)) plotregion(color(white)) name(a, replace) xsize(6.5) ysize(6.5)
graph export results/article/fig_speed.pdf, name(a) replace
