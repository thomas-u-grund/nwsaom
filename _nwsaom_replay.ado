*! version 1.6.0  13nov2026 nwcommands: redisplay the results of the last nwsaom fit
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	Replay (nwsaom typed without options, or with display options only, and estimates replay): the header, the
	coefficient table, the rates and the convergence summary, from e() alone.
*/
capture program drop _nwsaom_replay
program define _nwsaom_replay, rclass
	// r(done) = 0: the options are not display options only, so this is a fit (nwsaom goes on)
	capture syntax [, Level(cilevel) DETail]
	if _rc {
		return scalar done = 0
		exit
	}
	if `"`e(cmd)'"' != "nwsaom" {
		error 301
	}
	return scalar done = 1
	local nw = e(nwaves)
	local np = `nw' - 1
	local waves "`e(waves)'"
	if `nw' == 2 {
		local w1 : word 1 of `waves'
		local w2 : word 2 of `waves'
		local wshow "`w1'{txt} -> {res}`w2'"
	}
	else local wshow "`waves'"
	local hasrates = 0
	capture confirm matrix e(rates)
	if _rc == 0 local hasrates = 1
	di
	if e(has_behavior) == 1 {
		if e(nbeh) < . & e(nbeh) > 1 di as text "{p 0 0 2}SAOM co-evolution of the network and " e(nbeh) " behaviors (Method of Moments), waves: {res}`wshow'{p_end}"
		else di as text "{p 0 0 2}SAOM co-evolution (Method of Moments), waves: {res}`wshow'{p_end}"
	}
	else di as text "{p 0 0 2}SAOM (Method of Moments, " as result cond(e(conditional) == 1, "conditional", "unconditional") as text "), waves: {res}`wshow'{p_end}"
	if `hasrates' di as text "Actors: " as result e(nodes) _col(40) as text "Periods: " as result `np'
	else if e(has_behavior) == 1 di as text "Actors: " as result e(nodes) _col(40) as text "Network rate: " as result %6.3f e(rate) as text " (" as result %5.3f e(rate_se) as text ")"
	else di as text "Actors: " as result e(nodes) _col(40) as text "Estimated rate: " as result %6.3f e(rate) as text " (" as result %5.3f e(rate_se) as text ")"
	if e(has_behavior) == 1 {
		local bn "`e(behavior_names)'"
		if "`bn'" == "" local bn "`e(behavior)'"
		if `hasrates' di as text "Behavior: " as result "`bn'"
		else di as text "Behavior: " as result "`bn'" _col(40) as text "Behavior rate: " as result %6.3f e(rate_beh) as text " (" as result %5.3f e(rate_beh_se) as text ")"
	}
	if e(ngroups) < . di as text "Groups: " as result e(ngroups)
	if e(twomode) == 1 di as text "Two-mode network: " as result e(n_actors) as text " actors choose among " as result e(n_events) as text " events"
	di
	ereturn display, level(`level')
	if `hasrates' {
		tempname tab
		matrix `tab' = e(rates) \ e(rates_se)
		local rn "rate se"
		capture confirm matrix e(rates_beh)
		if _rc == 0 {
			matrix `tab' = `tab' \ e(rates_beh)
			local rn "`rn' rate_beh"
			capture confirm matrix e(rates_beh_se)
			if _rc == 0 {
				matrix `tab' = `tab' \ e(rates_beh_se)
				local rn "`rn' se_beh"
			}
		}
		matrix rownames `tab' = `rn'
		di as text "Rate parameters (estimated, one per inter-wave period):"
		matlist `tab', format(%9.4f) border(top bottom)
	}
	if "`e(symtype)'" != "" di as text "(non-directed relation, model type " as result "`e(symtype)'" as text " = RSiena modelType " as result e(modeltype) as text ")"
	capture confirm matrix e(ratecoefs)
	if _rc == 0 {
		tempname rc
		matrix `rc' = e(ratecoefs) \ e(ratecoefs_se)
		local rcn : colnames `rc'
		local k 0
		foreach v of local rcn {
			local ++k
			di as text "Covariate-rate coefficient (" as result "`v'" as text "): " as result %9.4f `rc'[1,`k'] as text " (se " as result %6.4f `rc'[2,`k'] as text ")"
		}
	}
	if "`detail'" != "" _nwsaom_rsnotes
	capture confirm matrix e(tconv)
	if _rc == 0 _nwsaom_tconvtable, `detail'
end
