* Several co-evolving behaviors (alcohol and smoking, s50) with present(), structural zeros (code 10), network endowment/creation and a
* non-directed network: the Stata side of dev/saom_rsiena_mbopts.R (RSiena 1.6.14; run the R script first, it writes the data files).
* Prints the observed statistics (the targets of the fit) and the estimates of three seeds per model.
* Run from the repository root with NWCORE set:  do dev/saom_rsiena_mbopts.do [A B D F]
args which
if "`which'" == "" local which "A B D F"
local nwcore : env NWCORE
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 200
capture program drop mbtargets
program define mbtargets
	mata: __r0 = .
	mata: __rb0 = .
	mata: __t = SaomMBInit(__ns_mbGw, __nwsaom_last_M, __ns_mbBw, __ns_mbmin, __ns_mbmax, __ns_mbsim, __ns_mbover, __ns_mbMb, __r0, __rb0)
	mata: SaomBatchCleanup()
	mata: printf("STATA targets: %s | rates net %s alc %s smk %s\n", invtokens(strofreal(colsum(__t.target), "%9.4f")), invtokens(strofreal(__t.targetRateNet)), invtokens(strofreal(__t.targetRateBeh[1,.])), invtokens(strofreal(__t.targetRateBeh[2,.])))
end
local bv "behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behsim)"
* the waves and the behaviors
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	import delimited "dev/saom_rsiena_mbopts_struct_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
	import delimited "dev/saom_rsiena_mbopts_sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(Y`w')
}
import delimited "dev/saom_rsiena_mbopts_present.csv", clear varnames(1)
rename (v1 v2 v3) (p1 p2 p3)
tempfile pres
save `pres'
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
merge 1:1 _n using `pres', nogenerate
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
	nwset, mat(S`w') directed name(st`w') nooutput
	nwset, mat(Y`w') undirected name(sy`w') nooutput
}
* A. present(): actors 1-4 join at wave 2, actors 47-50 leave at wave 2
if strpos("`which'", "A") {
	forvalues sd = 1/3 {
		nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip `bv' present(p1 p2 p3) k3(1000) seed(`sd')
		if `sd' == 1 mbtargets
	}
}
* B. structural zeros: code 10 between actors 1-10 and 41-50
if strpos("`which'", "B") {
	forvalues sd = 1/3 {
		nwsaom, waves(st1 st2 st3) outdegree reciprocity transtrip `bv' k3(1000) seed(`sd')
		if `sd' == 1 mbtargets
	}
}
* D. reciprocity split into endowment and creation
if strpos("`which'", "D") {
	forvalues sd = 1/3 {
		nwsaom, waves(te1 te2 te3) outdegree transtrip `bv' endow(reciprocity) creation(reciprocity) k3(1000) seed(`sd')
		if `sd' == 1 mbtargets
	}
}
* F. non-directed network, forcing model (RSiena modelType 2; RSiena's seed 1 diverges here, so seeds 2-4 on both sides)
if strpos("`which'", "F") {
	forvalues sd = 2/4 {
		nwsaom, waves(sy1 sy2 sy3) symmetric outdegree transtriads `bv' k3(1000) seed(`sd')
		if `sd' == 2 mbtargets
	}
}
