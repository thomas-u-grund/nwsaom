*! version 1.4.2  31oct2026 nwcommands: multi-group meta-analysis of separate nwsaom fits (RSiena's siena08)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	nwsaom_meta -- combine the estimates of the same nwsaom model fitted to several networks (groups), as RSiena's siena08
	(Snijders & Baerveldt 2003): for every effect the IWLS random-effects mean, the t test, Fisher's combination of one-sided tests, the
	heterogeneity test, and the maximum likelihood mean and between-group standard deviation with profile-likelihood intervals.
	The fits are given as stored estimates (estimates store). Mata functions: unw_saom.do (SaomMeta*).
*/
program nwsaom_meta, rclass
	version 14
	_nwsaom_libcheck
	syntax namelist(min=2) [, BOUND(real 10) ALPHA(real 0.05) MAXIT(integer 20) RATES NOTABLE]
	if `alpha' <= 0 | `alpha' >= 1 {
		di "{err}{bf:alpha()} must be between 0 and 1."
		error 198
	}
	local ng : word count `namelist'
	tempname B SE R b V names0
	local first 1
	local k 0
	foreach nm of local namelist {
		capture quietly estimates restore `nm'
		if _rc {
			di "{err}stored estimates {bf:`nm'} not found (use {bf:estimates store `nm'} after each {bf:nwsaom} fit)."
			error 111
		}
		matrix `b' = e(b)
		matrix `V' = e(V)
		local cn : colnames `b'
		local nb = colsof(`b')
		matrix `SE' = J(1, `nb', .)
		forvalues j = 1/`nb' {
			matrix `SE'[1, `j'] = sqrt(`V'[`j', `j'])
		}
		if "`rates'" != "" {
			capture confirm matrix e(rates)
			if !_rc {
				tempname rt rts
				matrix `rt' = e(rates)
				// the standard errors of the rates are in e(rates_se) (not a second row of e(rates)); missing when not available
				capture confirm matrix e(rates_se)
				if !_rc matrix `rts' = e(rates_se)
				else matrix `rts' = J(1, colsof(`rt'), .)
				local np = colsof(`rt')
				forvalues j = 1/`np' {
					matrix `b' = `b', `rt'[1, `j']
					matrix `SE' = `SE', `rts'[1, `j']
					local cn "`cn' rate_period`j'"
				}
				local nb = colsof(`b')
			}
		}
		if `first' {
			matrix `B' = `b'
			matrix `R' = `SE'
			local names0 "`cn'"
			local nb0 = `nb'
			local first 0
		}
		else {
			if `nb' != `nb0' | "`cn'" != "`names0'" {
				di "{err}the fits must have the same effects in the same order; {bf:`nm'} differs from {bf:`: word 1 of `namelist''}."
				error 198
			}
			matrix `B' = `B' \ `b'
			matrix `R' = `R' \ `SE'
		}
	}
	tempname M
	mata: st_matrix("`M'", SaomMeta(st_matrix("`B'"), st_matrix("`R'"), `bound', `alpha', `maxit'))
	local rn ""
	foreach c of local names0 {
		local c = subinstr("`c'", ".", "_", .)
		local rn "`rn' `c'"
	}
	matrix rownames `M' = `rn'
	// the group results carry the names of the stored estimates (rows) and of the effects (columns)
	matrix rownames `B' = `namelist'
	matrix rownames `R' = `namelist'
	matrix colnames `B' = `rn'
	matrix colnames `R' = `rn'
	matrix colnames `M' = n_used corr corr_p iwls_mean iwls_se iwls_t iwls_p iwls_sd Tsq Tsq_p Q Q_p ml_mean ml_se mu_lo mu_hi ml_sd sd_lo sd_hi fisher_right fisher_right_p fisher_left fisher_left_p level
	if "`notable'" == "" {
		di
		di as text "Meta-analysis of " as result `ng' as text " fits (as RSiena {bf:siena08})"
		di as text "Estimates with a standard error of " as result `bound' as text " or more are excluded;"
		di as text "tests of the means use a t distribution with n-1 d.f."
		di
		di as text "{bf:IWLS estimates} (Snijders and Baerveldt 2003)"
		di as text "{hline 13}{c TT}{hline 65}"
		di as text %12s "effect" " {c |}" %4s "n" %10s "Mean" %11s "Std. err." %8s "t" %8s "P>|t|" %8s "SD" %8s "Q" %8s "P>Q"
		di as text "{hline 13}{c +}{hline 65}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %4.0f `M'[`i', 1] %10.4f `M'[`i', 4] %11.4f `M'[`i', 5] %8.2f `M'[`i', 6] %8.3f `M'[`i', 7] %8.4f `M'[`i', 8] %8.2f `M'[`i', 11] %8.3f `M'[`i', 12]
		}
		di as text "{hline 13}{c BT}{hline 65}"
		di
		di as text "{bf:Maximum likelihood under normality}: mean of the parameter"
		di as text "{hline 13}{c TT}{hline 44}"
		di as text %12s "effect" " {c |}" %10s "Mean" %11s "Std. err." "   [" as result %2.0f 100*(1-`alpha') as text "% conf. interval]"
		di as text "{hline 13}{c +}{hline 44}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %10.4f `M'[`i', 13] %11.4f `M'[`i', 14] "   " %10.4f `M'[`i', 15] %10.4f `M'[`i', 16]
		}
		di as text "{hline 13}{c BT}{hline 44}"
		di
		di as text "{bf:Maximum likelihood under normality}: standard deviation between groups"
		di as text "{hline 13}{c TT}{hline 34}"
		di as text %12s "effect" " {c |}" %10s "SD" "    [" as result %2.0f 100*(1-`alpha') as text "% conf. interval]"
		di as text "{hline 13}{c +}{hline 34}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %10.4f `M'[`i', 17] "    " %10.4f `M'[`i', 18] %10.4f `M'[`i', 19]
		}
		di as text "{hline 13}{c BT}{hline 34}"
		di
		di as text "{bf:Fisher's combination of one-sided tests} (chi-squared, 2n d.f.)"
		di as text "{hline 13}{c TT}{hline 44}"
		di as text %12s "" " {c |}" %20s "Right-sided" %20s "Left-sided"
		di as text %12s "effect" " {c |}" %9s "chi2" %11s "Prob>chi2" %9s "chi2" %11s "Prob>chi2"
		di as text "{hline 13}{c +}{hline 44}"
		local i 0
		foreach c of local rn {
			local ++i
			di as text %12s abbrev("`c'", 12) " {c |}" as result %9.3f `M'[`i', 20] %11.3f `M'[`i', 21] %9.3f `M'[`i', 22] %11.3f `M'[`i', 23]
		}
		di as text "{hline 13}{c BT}{hline 44}"
		di as text "Correlations of estimates and standard errors are in {bf:r(meta)}."
	}
	return matrix meta = `M'
	return matrix theta = `B'
	return matrix se = `R'
	return scalar groups = `ng'
end
