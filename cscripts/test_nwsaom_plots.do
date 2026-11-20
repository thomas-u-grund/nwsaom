* nwsaom result plots: estat gof (name stub, saving(), export(), graph options, groups), estat timetest, plot, estat convergence, plot and
* nwsaom meta, plot: the graphs exist, saving()/export() write their files, graph options reach the graphs; error paths.
* Run from the repository root (cscripts/run_tests.sh).
cscript
* The core package nwcommands is found through the environment variable NWCORE (path of the core checkout).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
local out `"`c(tmpdir)'/nwsaom_plots_test"'
capture mkdir `"`out'"'

* ---- default pictures of estat gof unchanged: identical PNG files with the released nwsaom (reference directory from NWSAOM_PLOT_REF)
* Produce the reference with the released main after `cscript`: global NWP_OUT <dir>, do cscripts/nwsaom_plots_defaults.do
local ref : env NWSAOM_PLOT_REF
if `"`ref'"' == "" {
	di as text "  SKIPPED: default pictures vs released nwsaom (set NWSAOM_PLOT_REF)"
}
else {
	global NWP_OUT `"`out'/defaults"'
	do cscripts/nwsaom_plots_defaults.do
	local nfail 0
	local files gof_outdegree gof_indegree gof_geodesic gof_named gof_gg_g1 gof_gg_g2 gof_gg_g3
	foreach f of local files {
		quietly checksum `"`ref'/`f'.png"'
		local c0 = r(checksum)
		local s0 = r(filelen)
		quietly checksum `"$NWP_OUT/`f'.png"'
		if `c0' != r(checksum) | `s0' != r(filelen) {
			di as error "  FAIL: default picture `f' differs from the released nwsaom"
			local ++nfail
		}
	}
	if `nfail' > 0 exit 9
	di as text "  PASS: default gof pictures identical to the released nwsaom (`: word count `files'' files)"
	nwclear
	nwwebuse glasgow
	nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)
}
nwclear
nwwebuse glasgow
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)

* ---- estat gof: saving() and export() (one file per statistic), graph options
foreach f in gof_outdegree gof_indegree gof_geodesic {
	capture erase `"`out'/pg_`f'.gph"'
}
capture erase `"`out'/pg_gof_outdegree.png"'
estat gof, nsim(10) seed(4242) name(tg) saving(`"`out'/pg.gph"') export(`"`out'/pg.png"', width(900)) scheme(s2color) title("custom title")
foreach s in outdegree indegree geodesic {
	graph describe tg_`s'
	confirm file `"`out'/pg_tg_`s'.gph"'
	confirm file `"`out'/pg_tg_`s'.png"'
}
di as text "  PASS: gof saving(), export() and graph options"

* ---- estat gof after a fit with groups: one file per graph (the graph name is in the file name)
nwclear
import delimited "dev/saom_groups_actors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(G`w')
	restore
	nwset, mat(G`w') name(g`w') nooutput
}
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity k0(15) k3(60) seed(1) cores(1) unconditional
estat gof, nsim(10) seed(3) stats(outdegree) name(gg) saving(`"`out'/gg.gph"') export(`"`out'/gg.png"', width(700))
forvalues g = 1/3 {
	graph describe gg_g`g'_outdegree
	confirm file `"`out'/gg_gg_g`g'_outdegree.gph"'
	confirm file `"`out'/gg_gg_g`g'_outdegree.png"'
}
di as text "  PASS: gof saving() and export() after groups()"
nwclear
nwwebuse glasgow
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)

* ---- estat timetest, plot (needs a fit with three waves; the plot shows the one-step deviations by period)
estat timetest, plot name(ttp) saving(`"`out'/tt.gph"') export(`"`out'/tt.png"', width(1100)) scheme(s2color)
graph describe ttp
confirm file `"`out'/tt.gph"'
confirm file `"`out'/tt.png"'
estat timetest, effects(outdegree) plot
graph describe timetest
estat timetest
di as text "  PASS: timetest plot"

* ---- estat convergence
estat convergence
assert r(tconv_max) == e(tconv_max)
matrix T = r(tconv)
assert colsof(T) == colsof(e(tconv))
estat convergence, plot name(cvp) saving(`"`out'/cv.gph"') export(`"`out'/cv.png"', width(900)) title("t-ratios")
graph describe cvp
confirm file `"`out'/cv.gph"'
confirm file `"`out'/cv.png"'
estat convergence, plot
graph describe convergence
di as text "  PASS: convergence table and plot"

* ---- nwsaom meta, plot (made-up estimates of four groups for two effects)
capture program drop mk_est
program mk_est, eclass
	args g th1 th2 se1 se2
	tempname b V
	matrix `b' = (`th1', `th2')
	matrix colnames `b' = eff1 eff2
	matrix `V' = (`se1'^2, 0 \ 0, `se2'^2)
	matrix colnames `V' = eff1 eff2
	matrix rownames `V' = eff1 eff2
	ereturn post `b' `V'
	ereturn local cmd "fakefit"
	estimates store g`g'
end
mk_est 1 0.8 -0.4 0.3 0.2
mk_est 2 1.2 -0.1 0.4 0.3
mk_est 3 0.5 -0.9 0.25 0.35
mk_est 4 1.6 0.2 0.5 0.4
nwsaom meta g1 g2 g3 g4, notable plot name(mp) saving(`"`out'/mt.gph"') export(`"`out'/mt.png"', width(1000)) scheme(s2color)
graph describe mp
confirm file `"`out'/mt.gph"'
confirm file `"`out'/mt.png"'
nwsaom meta g1 g2 g3 g4, notable plot
graph describe meta
di as text "  PASS: meta plot"

* ---- error paths (the made-up estimates replaced e(); fit again)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)
capture estat timetest, name(x)
assert _rc == 198
capture estat timetest, saving(`"`out'/x.gph"')
assert _rc == 198
capture estat convergence, name(x)
assert _rc == 198
capture estat convergence, export(`"`out'/x.png"')
assert _rc == 198
capture nwsaom meta g1 g2 g3 g4, notable name(x)
assert _rc == 198
capture nwsaom meta g1 g2 g3 g4, notable export(`"`out'/x.png"')
assert _rc == 198
capture estat gof, nsim(10) nosuchoption(1)
assert _rc != 0
* convergence needs method-of-moments estimates; the two-wave fit has a rate scalar but still e(tconv)
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k0(15) k3(15) seed(5)
estat convergence, plot name(cv2)
graph describe cv2
capture estat timetest, plot
assert _rc == 198
di as text "  PASS: error paths"
* ---- an older core (no _nw_gfinish): a clear message and r(199) at plot time; the commands without plot options still work
capture program drop _nw_gfinish
program define _nw_gfinish
	exit 199
end
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)
estat convergence
capture estat convergence, plot
assert _rc == 199
capture estat timetest, plot
assert _rc == 199
capture estat gof, nsim(5) seed(1)
assert _rc == 199
capture program drop _nw_gfinish
di as text "  PASS: old core message and r(199)"
di as text "ALL TESTS PASSED"
