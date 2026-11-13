* Goodness of fit, simulation, time test, relative importance and score test after a fit with SEVERAL co-evolving behaviors (alcohol and smoking, s50): the Stata side of
* dev/saom_rsiena_mbgof.R (RSiena 1.6.14: siena07 with returnDeps, sienaGOF per variable, the simulated end states,
* sienaTimeTest, sienaRI, the score test of a fixed effect).
* Run from the repository root with NWCORE set.
local nwcore : env NWCORE
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 200
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
forvalues sd = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
		behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behsim) k3(1000) seed(`sd')
	estat gof, nsim(500) seed(`sd') maxdeg(15) stats(outdegree indegree behavior)
	return list
	estat simulate, nsim(300) seed(`sd')
	mata: S = st_matrix("r(sim)")
	mata: for (p=1; p<=2; p++) printf("STATA seed %g period %g: ties %8.1f alc %6.3f smk %6.3f\n", `sd', p, mean(select(S[.,3], S[.,2]:==p)), mean(select(S[.,6], S[.,2]:==p)), mean(select(S[.,7], S[.,2]:==p)))
	estat timetest
	if `sd' == 1 estat importance
}
forvalues sd = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
		behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behsim) k3(1000) seed(`sd') fix(transtrip) theta0(0 0 0 0 0)
	estat score
}
