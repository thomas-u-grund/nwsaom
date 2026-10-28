*! version 1.3.2  28oct2026 _nwsaom_tconvtable (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/* Convergence t-ratios on RSiena's scale (phase-3 mean deviation / its
   standard deviation, e(tconv)) for every parameter including the rates,
   two per line within 80 columns, then RSiena's overall maximum
   convergence ratio e(tconv_max). */
capture program drop _nwsaom_tconvtable
program define _nwsaom_tconvtable
	syntax [, DETail]
	tempname m
	matrix `m' = e(tconv)
	local names : colnames `m'
	local k = colsof(`m')
	if "`detail'" != "" {
		di as text "Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):"
		forvalues j = 1/`k' {
			local nm : word `j' of `names'
			if udstrlen("`nm'") > 24 local nm = usubstr("`nm'", 1, 23) + "~"
			if mod(`j', 2) == 1 di as text "  " %-24s "`nm'" as result %8.3f `m'[1,`j'] _continue
			else di as text "      " %-24s "`nm'" as result %8.3f `m'[1,`j']
		}
		if mod(`k', 2) == 1 di ""
		di as text "Overall maximum convergence ratio: " as result %6.3f e(tconv_max)
	}
	else {
		local bad ""
		forvalues j = 1/`k' {
			if abs(`m'[1,`j']) >= 0.1 {
				local nm : word `j' of `names'
				local bad "`bad' `nm' (`: di %5.3f `m'[1,`j']')"
			}
		}
		/* RSiena's two criteria are separate and both are needed (siena.Rd): every convergence t-ratio below 0.1 in absolute value
		   AND the overall maximum convergence ratio (a different quantity, it also reflects the correlations of the deviations) below
		   0.25. Each line states one criterion and whether it is met, so that the text cannot contradict the numbers. */
		local ok = e(tconv_max) < 0.25
		di as text "Overall maximum convergence ratio: " as result %5.3f e(tconv_max) as text " (criterion: below 0.25; " cond(`ok', "met", "{bf:not met}") ")"
		if "`bad'" == "" di as text "Convergence t-ratios (criterion: all below 0.1 in absolute value): met"
		else di as text "Convergence t-ratios (criterion: all below 0.1 in absolute value): {bf:not met} for" as result "`bad'"
		if !`ok' | "`bad'" != "" {
			di as text "Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see {help nwsaom}."
		}
	}
	if "`e(engine)'" == "mata" {
		di as text "(simulated in Mata, not the native plugin: `e(engine_why)')"
	}
end
