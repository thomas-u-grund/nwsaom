*! version 1.7.1  13nov2026 _nwsaom_tconvtable (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/* Convergence t-ratios on RSiena's scale (phase-3 mean deviation / its
   standard deviation, e(tconv)) for every parameter including the rates,
   two per line within 80 columns, then RSiena's overall maximum
   convergence ratio e(tconv_max). As in RSiena, the criteria apply to the
   estimated parameters only: a fixed parameter (fix(), or kept at its
   starting value) is listed with detail but never reported as "not met"
   (e(tconv_max) leaves the fixed parameters out already). */
capture program drop _nwsaom_tconvtable
program define _nwsaom_tconvtable
	syntax [, DETail]
	tempname m
	matrix `m' = e(tconv)
	local names : colnames `m'
	local k = colsof(`m')
	// RSiena's two criteria, used by both layouts for the refit hint below
	local ok = e(tconv_max) < 0.25
	_nwsaom_tconvfixed fx
	local nfx 0
	local fxnames ""
	local anybad 0
	forvalues j = 1/`k' {
		local f`j' : word `j' of `fx'
		if "`f`j''" == "" local f`j' 0
		if `f`j'' {
			local ++nfx
			local fxnames `fxnames' `: word `j' of `names''
		}
		else if abs(`m'[1,`j']) >= 0.1 local anybad 1
	}
	if "`detail'" != "" {
		di as text "{p 0 0 2}Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):{p_end}"
		forvalues j = 1/`k' {
			local nm : word `j' of `names'
			if udstrlen("`nm'") > 24 local nm = usubstr("`nm'", 1, 23) + "~"
			if mod(`j', 2) == 1 di as text "  " %-24s "`nm'" as result %8.3f `m'[1,`j'] _continue
			else di as text "      " %-24s "`nm'" as result %8.3f `m'[1,`j']
		}
		if mod(`k', 2) == 1 di ""
		if `nfx' di as text "{p 0 2 2}Fixed, not part of the criteria: `fxnames'{p_end}"
		di as text "Overall maximum convergence ratio: " as result %6.3f e(tconv_max)
	}
	else {
		local bad ""
		local nbad 0
		forvalues j = 1/`k' {
			if !`f`j'' & abs(`m'[1,`j']) >= 0.1 {
				local nm : word `j' of `names'
				local bad "`bad' `nm' (`: di %5.3f `m'[1,`j']')"
				local ++nbad
				local bad`nbad' "`nm' (`: di %5.3f `m'[1,`j']')"
			}
		}
		/* RSiena's two criteria are separate and both are needed (siena.Rd): every convergence t-ratio below 0.1 in absolute value
		   AND the overall maximum convergence ratio (a different quantity, it also reflects the correlations of the deviations) below
		   0.25. Each line states one criterion and whether it is met, so that the text cannot contradict the numbers. */
		di as text "Overall maximum convergence ratio: " as result %5.3f e(tconv_max) as text " (criterion: below 0.25; " cond(`ok', "met", "{bf:not met}") ")"
		if "`bad'" == "" di as text "Convergence t-ratios (criterion: all below 0.1 in absolute value): met"
		else {
			// the parameters that fail on lines of their own, broken between parameters, never within a name
			di as text "Convergence t-ratios (criterion: all below 0.1 in absolute value): {bf:not met} for"
			local line ""
			forvalues j = 1/`nbad' {
				if `"`line'"' != "" & strlen(`"`line' `bad`j''"') > 76 {
					di as result "  `line'"
					local line ""
				}
				local line = trim(`"`line' `bad`j''"')
			}
			if `"`line'"' != "" di as result "  `line'"
		}
	}
	// the hint also follows the detail layout (it was printed only without detail up to 1.5.13)
	if !`ok' | `anybad' {
		if "`e(cmd)'" == "nwsaom" & `"`e(cmdline)'"' != "" di as text "Convergence is good only if both criteria are met." _n "To refit starting from these estimates, type {bf:nwsaom refit}."
		else di as text "{p 0 0 2}Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see {help nwsaom}.{p_end}"
	}
	if "`e(engine)'" == "mata" {
		di as text "(simulated in Mata, not the native plugin: `e(engine_why)')"
	}
end
