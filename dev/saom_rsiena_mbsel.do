* nwsaom counterpart of dev/saom_rsiena_mbsel.R: selection effects of a SECOND co-evolving behavior (smoking) besides those of the first (alcohol)
* Run from the repository root with the core on the adopath (NWCORE = the core checkout).
capture program drop nwinstall
local nwcore : env NWCORE
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}
* the observed statistics (targets) of every effect, in RSiena's order of the network effects
capture nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
	behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behaltx behegox netbeh:higher behsim netbeh:simrecipx behegoplusalt) k0(5) k3(10) seed(1)
mata: __r0 = .
mata: __rb0 = .
mata: __t = SaomMBInit(__ns_mbGw, __nwsaom_last_M, __ns_mbBw, __ns_mbmin, __ns_mbmax, __ns_mbsim, __ns_mbover, __ns_mbMb, __r0, __rb0)
mata: SaomBatchCleanup()
mata: printf("MBSEL targets: %s\n", invtokens(strofreal(colsum(__t.target), "%10.4f")))
forvalues s = 1/3 {
	nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
		behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behaltx behegox behsim netbeh:simrecipx) k3(1000) seed(`s')
	matrix bb = e(b)
	matrix VV = e(V)
	local est ""
	local se ""
	forvalues j = 1/`=colsof(bb)' {
		local est "`est' `: di %6.3f bb[1,`j']'"
		local se "`se' `: di %6.3f sqrt(VV[`j',`j'])'"
	}
	di "MBSEL seed `s' tconv " %5.3f e(tconv_max) " engine `e(engine)'"
	di "  est:`est'"
	di "  se: `se'"
	matrix list e(rates)
	matrix list e(rates_beh)
}
di "MBSEL names: `: colnames e(b)'"
di "MBSEL labels: `e(rsiena_labels)'"
