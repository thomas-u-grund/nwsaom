* Default calls (no saving, export or graph options) of the plots of nwsaom 1.8.1 (estat gof, also after groups()): each picture is exported to
* the directory in the global NWP_OUT. Run with the released nwsaom and with this one: the PNG files must be identical.
* Used by test_nwsaom_plots.do (reference directory: environment variable NWSAOM_PLOT_REF) and by hand. The core is on the adopath already.
set graphics off
capture mkdir "$NWP_OUT"
nwclear
nwwebuse glasgow
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(15) k3(40) seed(12345)
estat gof, nsim(10) seed(4242)
foreach s in outdegree indegree geodesic {
	quietly graph display gof_`s'
	quietly graph export "$NWP_OUT/gof_`s'.png", replace width(600)
}
estat gof, nsim(10) seed(4243) name(nm) stats(outdegree)
quietly graph display nm_outdegree
quietly graph export "$NWP_OUT/gof_named.png", replace width(600)
graph drop _all
* a fit with groups: gof of every group
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
estat gof, nsim(10) seed(3) stats(outdegree) name(gg)
forvalues g = 1/3 {
	quietly graph display gg_g`g'_outdegree
	quietly graph export "$NWP_OUT/gof_gg_g`g'.png", replace width(600)
}
graph dir
