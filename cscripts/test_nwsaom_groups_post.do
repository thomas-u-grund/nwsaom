* Post-estimation after a fit with groups: estat gof (per group and combined), estat simulate, nwsaom simulate, estat importance.
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
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) k0(30) k3(500) seed(1) cores(1) unconditional
estat gof, nsim(40) seed(3) group(2)
estat gof, nsim(40) seed(3)
display "PASS: estat gof per group"
* the p-values of the Mahalanobis test per group against sienaGOF(groupName = "DataK") of RSiena 1.6.14 (means of 8 runs, dev/saom_rsiena_groups_post.R);
* nwsaom: 3 fits, 100 simulations each; the difference of the mean p-values is within the simulation error (|diff| < 0.25 at 3 runs)
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_gof.csv", clear
forvalues g = 1/3 {
	foreach st in outdegree indegree {
		scalar pp_`g'_`st' = 0
	}
}
forvalues sd = 1/3 {
	quietly nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) k0(30) k3(500) seed(`sd') cores(1) unconditional
	forvalues g = 1/3 {
		quietly estat gof, nsim(100) seed(`sd') group(`g') stats(outdegree indegree) maxdeg(5)
		foreach st in outdegree indegree {
			scalar pp_`g'_`st' = pp_`g'_`st' + r(p_`st'_g`g') / 3
		}
	}
}
forvalues g = 1/3 {
	foreach st in outdegree indegree {
		quietly frame ref: summarize p if group == `g' & stat == "`st'", meanonly
		local y = r(mean)
		assert abs(pp_`g'_`st' - `y') < 0.25
	}
}
frame drop ref
display "PASS: estat gof per group agrees with sienaGOF"
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) k0(30) k3(500) seed(1) cores(1) unconditional
* estat simulate: per group (the number of actors of the group), generate() saves the networks of the group
estat simulate, nsim(5) seed(2) group(2) generate(sg)
matrix S2 = r(sim_g2)
assert rowsof(S2) == 10
nwset
display "PASS: estat simulate per group"
nwsaom simulate, waves(g1 g2 g3) groups(group) outdegree reciprocity theta(-2.9 2.9) rates(3 2 5 2 1 2) nsim(4) seed(1)
matrix S3 = r(sim_g3)
assert rowsof(S3) == 8
display "PASS: nwsaom simulate with groups"

* estat importance per group = estat importance of the group fitted alone with the same coefficients (RSiena's sienaRI has no group version, it works on one data object)
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) nocenter k0(30) k3(500) seed(1) cores(1) unconditional
matrix B = e(b)
estat importance, group(2)
matrix RIg = r(sigma_period_g2)
preserve
keep in 16/35
forvalues w = 1/3 {
	mata: st_matrix("S`w'", st_matrix("G`w'")[16..35, 16..35])
	nwset, mat(S`w') name(s`w') nooutput
}
nwsaom, waves(s1 s2 s3) outdegree reciprocity transtrip egox(alc) altx(alc) nocenter theta0(`=B[1,1]' `=B[1,2]' `=B[1,3]' `=B[1,4]' `=B[1,5]') fix(_all) k0(5) k3(5) seed(1) cores(1) unconditional
estat importance
matrix RI1 = r(sigma_period)
* (the covariate effects differ by design: the alcohol variable has missing values, imputed by the mean of ALL groups in the fit with groups and by the mean of the group when fitted alone)
foreach j in 1 2 5 {
	forvalues q = 1/2 {
		assert abs(RIg[`j', `q'] - RI1[`j', `q']) < 1e-9
	}
}
restore
display "PASS: estat importance per group equals the group fitted alone"
