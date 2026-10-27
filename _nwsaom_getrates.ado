*! version 1.2.0  27oct2026 nwcommands: the rates of the last nwsaom fit (or of nwsaom bayes / ml) for the Bayesian and maximum likelihood estimators
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	Returns r(rt) and r(se): 1 x (periods * variables) row vectors of the rates (network rates of the periods, then, with a co-evolving behavior,
	the behavior rates of the periods) and their standard errors (missing when not available).
*/
capture program drop _nwsaom_getrates
program _nwsaom_getrates, rclass
	args nper coev
	tempname rt se r1 s1 r2 s2
	_nwsaom_getrates1 `nper' "" "`r1'" "`s1'"
	matrix `rt' = `r1'
	matrix `se' = `s1'
	if `coev' {
		_nwsaom_getrates1 `nper' "_beh" "`r2'" "`s2'"
		matrix `rt' = `rt', `r2'
		matrix `se' = `se', `s2'
	}
	return matrix rt = `rt'
	return matrix se = `se'
end

capture program drop _nwsaom_getrates1
program _nwsaom_getrates1
	args nper suffix rname sname
	capture confirm matrix e(rates`suffix')
	if !_rc {
		tempname M S
		matrix `M' = e(rates`suffix')
		matrix `rname' = `M'[1, 1..`nper']
		if rowsof(`M') >= 2 {
			matrix `sname' = `M'[2, 1..`nper']
		}
		else {
			capture confirm matrix e(rates`suffix'_se)
			if !_rc {
				matrix `S' = e(rates`suffix'_se)
				matrix `sname' = `S'[1, 1..`nper']
			}
			else matrix `sname' = J(1, `nper', .)
		}
	}
	else {
		local r = e(rate`suffix')
		local s = e(rate`suffix'_se)
		matrix `rname' = J(1, `nper', `r')
		matrix `sname' = J(1, `nper', `s')
	}
end
