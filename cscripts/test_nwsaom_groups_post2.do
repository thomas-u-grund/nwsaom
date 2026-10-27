* Post-estimation after a fit with groups and a co-evolving behavior (also ratecov and present): estat gof, estat simulate, estat importance per group.
* Data: dev/saom_groups_*.csv (the s50 data cut into three groups of 15, 20 and 15 actors); reference: dev/saom_rsiena_groups_post.R
cscript
set linesize 255
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
nwclear
import delimited "dev/saom_groups_actors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(G`w')
	restore
	nwset, mat(G`w') name(g`w') nooutput
}

nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx k0(30) k3(500) seed(1) cores(1) unconditional
estat gof, nsim(30) seed(3) group(2) stats(outdegree behavior)
display "PASS: behavior gof per group"
* against sienaGOF(groupName =) of RSiena 1.6.14 (means of 8 runs, dev/saom_rsiena_groups_post_beh.R); nwsaom: 3 fits, 100 simulations, tolerance 0.25
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_gof_beh.csv", clear
forvalues g = 1/3 {
	foreach st in outdegree behavior {
		scalar pp_`g'_`st' = 0
	}
}
forvalues sd = 1/3 {
	quietly nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx k0(30) k3(500) seed(`sd') cores(1) unconditional
	forvalues g = 1/3 {
		quietly estat gof, nsim(100) seed(`sd') group(`g') stats(outdegree behavior) maxdeg(5)
		foreach st in outdegree behavior {
			scalar pp_`g'_`st' = pp_`g'_`st' + r(p_`st'_g`g') / 3
		}
	}
}
forvalues g = 1/3 {
	foreach st in outdegree behavior {
		quietly frame ref: summarize p if group == `g' & stat == "`st'", meanonly
		assert abs(pp_`g'_`st' - r(mean)) < 0.25
	}
}
frame drop ref
display "PASS: behavior gof per group agrees with sienaGOF"
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx k0(30) k3(500) seed(1) cores(1) unconditional
estat simulate, nsim(4) seed(2) group(2) generate(sb)
matrix S2 = r(sim_g2)
assert rowsof(S2) == 8
confirm variable sb_g2_1_p1
estat importance, group(3)
display "PASS: behavior simulate and importance per group"
* ratecov: the rate of the actors depends on ccv (centred over all groups); the simulated number of ties changes must be close to the data
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip ratecov(ccv) k0(30) k3(500) seed(1) cores(1) unconditional
estat gof, nsim(30) seed(3) group(1) stats(outdegree)
estat simulate, nsim(4) seed(2) group(3)
display "PASS: ratecov gof and simulate per group"
* present: composition change inside the groups
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip present(p1 p2 p3) k0(30) k3(500) seed(1) cores(1) unconditional
estat gof, nsim(30) seed(3) group(2) stats(outdegree)
estat simulate, nsim(4) seed(2) group(1)
display "PASS: present gof and simulate per group"
