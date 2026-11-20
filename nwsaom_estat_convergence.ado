*! version 1.8.1  18nov2026 nwcommands: estat convergence after nwsaom (convergence t-ratios of the estimation, with a plot)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	estat convergence: the t-ratios for convergence of the last method-of-moments fit (e(tconv)), one per coefficient and rate, and the overall
	maximum convergence ratio (e(tconv_max)); RSiena prints them under its estimates and calls the estimation converged when every t-ratio is
	below 0.1 in absolute value and the overall ratio below 0.25. plot draws the t-ratios (an extension: RSiena shows them in its table only).
*/
capture program drop nwsaom_estat_convergence
program define nwsaom_estat_convergence, rclass
	syntax [, PLOT NAME(string) SAVing(string) EXPort(string asis) *]
	local __gopts `"`options'"'
	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	if "`plot'" == "" & (`"`saving'`export'`__gopts'"' != "" | "`name'" != "") {
		di as err "{p 0 0 2}name(), saving(), export() and graph options need {bf:plot}.{p_end}"
		exit 198
	}
	capture confirm matrix e(tconv)
	if _rc {
		di as err "{p 0 0 2}the estimates have no convergence t-ratios (they come from method of moments fits only).{p_end}"
		exit 498
	}
	tempname T
	matrix `T' = e(tconv)
	local names : colnames `T'
	local K = colsof(`T')
	local tmax = e(tconv_max)
	local w = 12
	foreach nm of local names {
		local w = max(`w', min(28, udstrlen("`nm'")))
	}
	local w1 = `w' + 1
	di
	di as txt "Convergence of the estimation (t-ratios for convergence)"
	di as txt "{hline `w1'}{c TT}{hline 22}"
	di as txt %`w's "Parameter" " {c |}" %12s "t-ratio" %10s "|t| < 0.1"
	di as txt "{hline `w1'}{c +}{hline 22}"
	local nbad 0
	forvalues k = 1/`K' {
		local nm : word `k' of `names'
		local t = `T'[1, `k']
		local ok = (abs(`t') < 0.1)
		if !`ok' local ++nbad
		di as txt %`w's abbrev("`nm'", `w') " {c |}" as res %12.3f `t' as txt %10s cond(`ok', "yes", "no")
	}
	di as txt "{hline `w1'}{c BT}{hline 22}"
	di as txt "Overall maximum convergence ratio: " as res %6.3f `tmax' as txt cond(`tmax' < 0.25 & `nbad' == 0, " (converged: every |t| < 0.1 and overall < 0.25)", cond(`tmax' < 0.25, " (overall < 0.25, but not every |t| < 0.1)", " (not converged: overall >= 0.25)"))
	if "`plot'" != "" {
		if "`name'" == "" local name "convergence"
		preserve
		quietly drop _all
		quietly set obs `K'
		quietly gen double t = .
		quietly gen double pos = _n
		local yl ""
		forvalues k = 1/`K' {
			local nm : word `k' of `names'
			quietly replace t = `T'[1, `k'] in `k'
			local yl `"`yl' `k' "`nm'""'
		}
		quietly gen double zero = 0
		quietly gen byte bad = abs(t) >= 0.1
		quietly summarize t, meanonly
		local xhi = max(0.12, abs(r(min)) * 1.1, abs(r(max)) * 1.1)
		local xlo = -`xhi'
		local ttl `"title("Convergence t-ratios")"'
		if strpos(`"`__gopts'"', "title(") local ttl
		twoway (rspike zero t pos if !bad, horizontal lcolor(gs10)) (rspike zero t pos if bad, horizontal lcolor(red)) ///
			(scatter pos t if !bad, mcolor(black) msymbol(circle)) (scatter pos t if bad, mcolor(red) msymbol(circle)), ///
			xline(-0.1 0.1, lpattern(dash) lcolor(gs8)) xline(0, lcolor(gs12)) ylabel(`yl', angle(0) valuelabel nogrid labsize(small)) yscale(reverse) ///
			xscale(range(`xlo' `xhi')) xtitle("t-ratio for convergence (dashed: |t| = 0.1)") ytitle("") legend(off) ///
			note("Overall maximum convergence ratio `=string(`tmax', "%5.3f")' (RSiena: below 0.25)", size(small)) ///
			`ttl' name(`name', replace) `__gopts'
		restore
		_nwsaom_gfin `name', saving(`saving') export(`export')
	}
	return scalar tconv_max = `tmax'
	return scalar n_notconverged = `nbad'
	return matrix tconv = `T'
end
