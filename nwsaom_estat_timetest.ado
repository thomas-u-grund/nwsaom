*! version 1.9.2  22nov2026 nwcommands: estat timetest after nwsaom
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	estat timetest: test of time heterogeneity (RSiena's sienaTimeTest).
	For every effect of the fitted model it asks whether the parameter is the
	same in all inter-wave periods, with a score-type test of period-specific
	deviations (effect x dummy for periods 2..P) against the model fitted. No
	new fit is needed beyond the one in memory, which must have at least three
	waves (two periods).

	With fixrates the rate parameters are treated as known (as RSiena's
	sienaTimeTest does); by default they are estimated together with the
	effects, which is the score test of a model with a fixed time dummy.

	Reported: a joint test of all deviations, one test per effect (d.f. = P-1),
	and one test per effect and period with the one-step estimate of the
	deviation.
*/
capture program drop nwsaom_estat_timetest
program define nwsaom_estat_timetest, rclass
	_nwsaom_libcheck
	syntax [, EFFects(string) FIXRates PLOT NAME(string) SAVing(string) EXPort(string asis) *]
	local __gopts `"`options'"'
	// the plot options need the shared graph helper of the core (3.29.0 or later); without them the command works with an older core
	if "`plot'" != "" | `"`name'`saving'`export'`__gopts'"' != "" {
		capture _nw_gfinish version
		if _rc | r(api) < 1 {
			di as err `"{p 0 0 2}estat timetest, plot needs nwcommands 3.29.0 or later (the installed core is older). Update: {stata ado update nwcommands:ado update nwcommands}, or run nwinstall.{p_end}"'
			exit 199
		}
		_nw_gfinish check, plot(`plot') name(`"`name'"') saving(`"`saving'"') export(`"`export'"') gopts(`"`__gopts'"') default(timetest) cmd(estat timetest)
		local name `"`r(name)'"'
		local saving `"`r(saving)'"'
	}

	if !inlist(`"`e(cmd)'"', "nwsaom", "nwsaom_multinet") {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	local nwaves = e(nwaves)
	if e(ngroups) < . local nwaves = colsof(e(rates)) + 1
	if `nwaves' < 3 {
		di as err "estat timetest needs at least three waves (two periods)."
		exit 198
	}
	local nper = `nwaves' - 1
	capture mata: st_numscalar("__nwsaom_tt_have", rows(__nwsaom_score_Zp))
	if _rc {
		di as err "estat timetest is not available for this fit."
		exit 198
	}
	tempname b
	matrix `b' = e(b)
	local names : colnames `b'
	local p : word count `names'
	mata: st_local("nall", strofreal(cols(__nwsaom_score_par)))
	if "`effects'" == "" local effects `names'
	local flags ""
	forvalues i = 1/`nall' {
		local nm : word `i' of `names'
		local flags `flags' `=(`i' <= `p' & "`: list nm & effects'" != "")'
	}
	foreach w of local effects {
		if !`: list w in names' {
			di as err "effects(): `w' is not an effect of the fitted model (`names')."
			exit 198
		}
	}
	if e(ngroups) < . {
		tempname rgm
		matrix `rgm' = e(rates_group) \ J(1, `nper', 1)
		forvalues q = 1/`nper' {
			matrix `rgm'[2, `q'] = `q'
		}
		mata: SaomTimeTestRun(`nper', strtoreal(tokens("`flags'")), `p', ("`fixrates'" != ""), st_matrix("`rgm'"))
	}
	else mata: SaomTimeTestRun(`nper', strtoreal(tokens("`flags'")), `p', ("`fixrates'" != ""))
	tempname joint eff ind
	matrix `joint' = __nwsaom_tt_joint
	matrix `eff' = __nwsaom_tt_effect
	matrix `ind' = __nwsaom_tt_indiv
	tempname idx
	matrix `idx' = __nwsaom_tt_eff
	local ne = colsof(`idx')

	di
	di as txt "Test of time heterogeneity (score-type test)"
	di as txt "H0: the parameter of each effect is the same in all periods"
	di
	di as txt "{hline 13}{c TT}{hline 43}"
	di as txt %12s "Effect" " {c |}" %14s "chi2" %10s "df" %19s "Prob > chi2"
	di as txt "{hline 13}{c +}{hline 43}"
	local rows ""
	forvalues j = 1/`ne' {
		local k = `idx'[1, `j']
		local nm : word `k' of `names'
		di as txt %12s abbrev("`nm'", 12) " {c |}" as res %14.3f `eff'[`j', 1] %10.0f `eff'[`j', 2] %19.4f chi2tail(`eff'[`j', 2], `eff'[`j', 1])
		local rows `rows' `nm'
	}
	di as txt "{hline 13}{c +}{hline 43}"
	di as txt %12s "Joint" " {c |}" as res %14.3f `joint'[1,1] %10.0f `joint'[1,2] %19.4f chi2tail(`joint'[1,2], `joint'[1,1])
	di as txt "{hline 13}{c BT}{hline 43}"
	if e(ngroups) < . {
		tempname gt
		matrix `gt' = __nwsaom_tt_group
		di
		di as txt "H0: the parameters of the periods of a group are the same as in the other groups"
		di as txt "{hline 13}{c TT}{hline 43}"
		di as txt %12s "Group" " {c |}" %14s "chi2" %10s "df" %19s "Prob > chi2"
		di as txt "{hline 13}{c +}{hline 43}"
		forvalues g = 1/`=rowsof(`gt')' {
			di as txt %12s "`g'" " {c |}" as res %14.3f `gt'[`g', 1] %10.0f `gt'[`g', 2] %19.4f chi2tail(`gt'[`g', 2], `gt'[`g', 1])
		}
		di as txt "{hline 13}{c BT}{hline 43}"
		return matrix group = `gt'
		tempname pt
		matrix `pt' = __nwsaom_tt_periodtest
		di
		di as txt "Test of each period (all effects)"
		di as txt "{hline 13}{c TT}{hline 43}"
		di as txt %12s "Period" " {c |}" %14s "chi2" %10s "df" %19s "Prob > chi2"
		di as txt "{hline 13}{c +}{hline 43}"
		forvalues g = 1/`=rowsof(`pt')' {
			di as txt %12s "`g'" " {c |}" as res %14.3f `pt'[`g', 1] %10.0f `pt'[`g', 2] %19.4f chi2tail(`pt'[`g', 2], `pt'[`g', 1])
		}
		di as txt "{hline 13}{c BT}{hline 43}"
		return matrix period = `pt'
	}
	di
	di as txt "Period-specific deviations (one-step estimates) and separate tests"
	di as txt "{hline 13}{c TT}{hline 43}"
	di as txt %12s "Effect" " {c |}" %8s "Period" %12s "Deviation" %10s "chi2" %13s "Prob > chi2"
	di as txt "{hline 13}{c +}{hline 43}"
	local r 0
	forvalues j = 1/`ne' {
		local k = `idx'[1, `j']
		local nm : word `k' of `names'
		forvalues q = 2/`nper' {
			local ++r
			di as txt %12s abbrev("`nm'", 12) " {c |}" as res %8.0f `ind'[`r', 3] %12.4f `ind'[`r', 2] %10.3f `ind'[`r', 1] %13.4f chi2tail(1, `ind'[`r', 1])
		}
	}
	di as txt "{hline 13}{c BT}{hline 43}"
	matrix colnames `eff' = c df
	matrix colnames `ind' = c deviation period
	capture scalar drop __nwsaom_tt_have
	if "`plot'" != "" {
		nwsaom_tt_plot, ind(`ind') idx(`idx') b(`b') nper(`nper') name(`name') saving(`saving') export(`export') `__gopts'
	}
	return scalar chi2 = `joint'[1,1]
	return scalar df = `joint'[1,2]
	return scalar p = chi2tail(`joint'[1,2], `joint'[1,1])
	return matrix effect = `eff'
	return matrix individual = `ind'
end


// estat timetest, plot: RSiena's plot.sienaTimeTest. For every tested effect the parameter value in each period: the estimate of the model
// (period 1) and the estimate plus the one-step deviation (later periods) with 90, 95 and 97.5 percent intervals from the standard
// error of the deviation (deviation / sqrt(chi2)); the horizontal line is the estimate of the model, red marks a deviation with P < 0.05.
capture program drop nwsaom_tt_plot
program define nwsaom_tt_plot
	syntax , IND(name) IDX(name) B(name) NPER(integer) [NAME(string) SAVing(string) EXPort(string asis) *]
	local __opts `"`options'"'
	local names : colnames `b'
	local ne = colsof(`idx')
	local graphs ""
	preserve
	quietly drop _all
	quietly set obs `nper'
	quietly gen double period = _n
	quietly gen double val = .
	quietly gen double dev = .
	quietly gen double sd = .
	quietly gen byte sig = 0
	local r 0
	forvalues j = 1/`ne' {
		local k = `idx'[1, `j']
		local nm : word `k' of `names'
		local th = `b'[1, `k']
		quietly replace val = `th' in 1
		quietly replace dev = 0 in 1
		quietly replace sd = . in 1
		quietly replace sig = 0 in 1
		forvalues q = 2/`nper' {
			local ++r
			local c = `ind'[`r', 1]
			local d = `ind'[`r', 2]
			quietly replace val = `th' + `d' in `q'
			quietly replace dev = `d' in `q'
			quietly replace sd = cond(`c' > 0, abs(`d') / sqrt(`c'), .) in `q'
			quietly replace sig = (chi2tail(1, `c') < 0.05) in `q'
		}
		quietly gen double lo1 = val - 1.644854 * sd
		quietly gen double hi1 = val + 1.644854 * sd
		quietly gen double lo2 = val - 1.959964 * sd
		quietly gen double hi2 = val + 1.959964 * sd
		quietly gen double lo3 = val - 2.241403 * sd
		quietly gen double hi3 = val + 2.241403 * sd
		local g "__nwsaom_tt`j'"
		local xl ""
		forvalues q = 1/`nper' {
			local xl `"`xl' `q' "`q'""'
		}
		quietly twoway (rspike lo3 hi3 period if sig == 0, lcolor(gs13) lwidth(medthick)) (rspike lo2 hi2 period if sig == 0, lcolor(gs11) lwidth(thick)) ///
			(rspike lo1 hi1 period if sig == 0, lcolor(gs8) lwidth(vthick)) ///
			(rspike lo3 hi3 period if sig == 1, lcolor("255 200 200") lwidth(medthick)) (rspike lo2 hi2 period if sig == 1, lcolor("255 150 150") lwidth(thick)) ///
			(rspike lo1 hi1 period if sig == 1, lcolor("230 90 90") lwidth(vthick)) ///
			(connected val period, lcolor(black) mcolor(black) msymbol(circle) lwidth(medthin)), ///
			yline(`th', lcolor(black) lwidth(medium)) xlabel(`xl') xscale(range(0.5 `=`nper'+0.5')) ///
			xtitle("Period") ytitle("Parameter value", size(small)) title("`nm'", size(medsmall)) legend(off) ///
			ylabel(, angle(horizontal) labsize(small)) name(`g', replace) nodraw
		drop lo1 hi1 lo2 hi2 lo3 hi3
		local graphs "`graphs' `g'"
	}
	_nw_gfinish title "Time heterogeneity: parameter value by period", gopts(`"`__opts'"')
	local ttl `"`r(t)'"'
	graph combine `graphs', cols(`=min(`ne', cond(`ne' > 4, 3, 2))') `ttl' note("grey/red bars: 90, 95 and 97.5% intervals of the one-step deviation; red: P < 0.05; line: estimate of the model", size(vsmall)) name(`name', replace) `__opts'
	foreach g of local graphs {
		capture graph drop `g'
	}
	restore
	_nw_gfinish save, name(`name') saving(`"`saving'"') export(`"`export'"')
end
