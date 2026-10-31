*! version 1.4.1  31oct2026 nwcommands: estat score after nwsaom
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	estat score: the generalised score-type test of Schweinberger (2012),
	RSiena's test_parameter(method = "score") / the test = TRUE effects of siena07.

	The model is fitted with the effects to be tested held fixed at the
	restricted values (nwsaom ..., fix(effects) theta0(...); RSiena's
	fix = TRUE, test = TRUE). The test then asks whether freeing them would
	improve the fit, using only the phase-3 simulations of the restricted
	model. Reported: the joint chi-squared test, each tested effect
	separately (two-sided chi-squared and one-sided normal variate), and the
	one-step estimates of all parameters.

	tested(effects) restricts the test to some of the fixed effects; the
	others stay fixed and are treated as redundant.
*/
capture program drop nwsaom_estat_score
program define nwsaom_estat_score, rclass
	_nwsaom_libcheck
	syntax [, TESTED(string) ]

	if !inlist(`"`e(cmd)'"', "nwsaom", "nwsaom_multinet") {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	capture mata: st_numscalar("__nwsaom_score_have", rows(__nwsaom_score_D))
	if _rc {
		di as err "estat score needs a fit with fix(): fit the restricted model (the effects to be tested held fixed with fix() at their restricted values) first."
		exit 198
	}
	tempname b
	matrix `b' = e(b)
	local names : colnames `b'
	local p : word count `names'
	mata: st_numscalar("__nwsaom_score_nfix", sum(__nwsaom_score_fix))
	mata: st_numscalar("__nwsaom_score_same", cols(__nwsaom_score_par) >= `p')
	if scalar(__nwsaom_score_nfix) == 0 | scalar(__nwsaom_score_same) == 0 {
		di as err "estat score needs a fit with fix(): fit the restricted model (the effects to be tested held fixed with fix() at their restricted values) first."
		exit 198
	}
	local testlist ""
	mata: st_local("fixedflags", invtokens(strofreal(__nwsaom_score_fix)))
	local nall : word count `fixedflags'
	local fixednames ""
	forvalues i = 1/`p' {
		local f : word `i' of `fixedflags'
		if `f' == 1 local fixednames `fixednames' `: word `i' of `names''
	}
	if "`tested'" == "" local tested "`fixednames'"
	foreach w of local tested {
		if !`: list w in fixednames' {
			di as err "tested(): `w' is not a fixed effect (fixed: `fixednames')."
			exit 198
		}
	}
	local flags ""
	forvalues i = 1/`nall' {
		local nm : word `i' of `names'
		local flags `flags' `=(`i' <= `p' & "`: list nm & tested'" != "")'
	}
	mata: SaomScoreRun(strtoreal(tokens("`flags'")))
	local df = scalar(__nwsaom_score_df)
	local c = scalar(__nwsaom_score_c)
	local pv = chi2tail(`df', `c')

	di
	di as txt "Score-type test of the restricted model (as RSiena {bf:score.Test})"
	di as txt "Tests whether the fixed effects below differ from their fixed values."
	tempname sep
	matrix `sep' = __nwsaom_score_res
	di
	di as txt %18s "effect" " {c |}" %10s "Fixed at" %9s "chi2" %6s "d.f." %10s "Prob>chi2" %12s "One-sided z"
	di as txt "{hline 19}{c +}{hline 47}"
	if `df' == 1 {
		local w : word 1 of `tested'
		local pos : list posof "`w'" in names
		di as txt %18s abbrev("`w'", 18) " {c |}" as res %10.4f `b'[1, `pos'] %9.3f `c' %6.0f 1 %10.4f `pv' %12.3f scalar(__nwsaom_score_oneS)
	}
	else {
		local j 0
		foreach w of local tested {
			local ++j
			local pos : list posof "`w'" in names
			di as txt %18s abbrev("`w'", 18) " {c |}" as res %10.4f `b'[1, `pos'] %9.3f `sep'[`j', 1] %6.0f 1 %10.4f chi2tail(1, `sep'[`j', 1]) %12.3f `sep'[`j', 2]
		}
		di as txt "{hline 19}{c +}{hline 47}"
		di as txt %18s "Joint test" " {c |}" as res %10s "" %9.3f `c' %6.0f `df' %10.4f `pv'
	}
	di as txt "{hline 19}{c BT}{hline 47}"
	tempname os
	matrix `os' = __nwsaom_score_onestep
	local onames `names'
	forvalues i = `=`p'+1'/`nall' {
		local onames `onames' rate`=`i'-`p''
	}
	matrix colnames `os' = `onames'
	di
	di as txt "One-step estimates (restricted estimate plus the one-step correction)"
	di as txt %18s "effect" " {c |}" %10s "Estimate"
	di as txt "{hline 19}{c +}{hline 10}"
	forvalues i = 1/`nall' {
		local nm : word `i' of `onames'
		di as txt %18s abbrev("`nm'", 18) " {c |}" as res %10.4f `os'[1, `i']
	}
	di as txt "{hline 19}{c BT}{hline 10}"
	capture scalar drop __nwsaom_score_have __nwsaom_score_nfix __nwsaom_score_same
	return scalar chi2 = `c'
	return scalar df = `df'
	return scalar p = `pv'
	return matrix separate = `sep'
	return matrix onestep = `os'
end
