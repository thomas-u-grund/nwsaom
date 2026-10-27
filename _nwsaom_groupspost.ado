*! version 1.2.0  27oct2026 _nwsaom_groupspost: e() results of nwsaom for the joint estimation of several groups of a grouped fit (groups() option)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop _nwsaom_groupspost
program define _nwsaom_groupspost, eclass
	syntax , GROUPS(string) W(integer)
	tempname gn gw rg rp
	matrix `gn' = __ns_gnmat
	matrix `gw' = __ns_gwmat
	local G = colsof(`gn')
	local P = colsof(e(rates))
	matrix `rg' = J(1, `P', .)
	matrix `rp' = J(1, `P', .)
	local c 0
	local off 0
	forvalues g = 1/`G' {
		forvalues m = 1/`=`gw'[1,`g']-1' {
			local ++c
			matrix `rg'[1, `c'] = `g'
			matrix `rp'[1, `c'] = `off' + `m'
		}
		local off = `off' + `gw'[1,`g']
	}
	local cn : colnames e(rates)
	matrix colnames `rg' = `cn'
	matrix colnames `rp' = `cn'
	capture matrix drop __ns_gnmat
	capture matrix drop __ns_gwmat
	ereturn matrix rates_group = `rg'
	ereturn matrix rates_period = `rp'
	ereturn matrix groupn = `gn'
	ereturn matrix groupwaves = `gw'
	ereturn scalar ngroups = `G'
	ereturn scalar nwaves = `w'
	ereturn local groupvar "`groups'"
end
