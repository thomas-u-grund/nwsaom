*! version 1.4.0  30oct2026 _nwsaom_groupspost: e() results of nwsaom for the joint estimation of several groups of a grouped fit (groups() option)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop nwsaom_gof_groupbegin
program define nwsaom_gof_groupbegin, rclass
	syntax , GROUP(integer)
	tempname gw rg rt
	matrix `gw' = e(groupwaves)
	matrix `rg' = e(rates_group)
	matrix `rt' = e(rates)
	local nW = `gw'[1, `group']
	local s 0
	forvalues g = 1/`=`group'-1' {
		local s = `s' + `gw'[1, `g'] - 1
	}
	forvalues q = 1/`nW' {
		capture mata: mata drop __nwsaom_gofg_G`q'
		mata: __nwsaom_gofg_G`q' = SaomGraph()
		mata: SaomGroupsSubGraph(__nwsaom_last_G`=`s'+`q'', `group', __nwsaom_gofg_G`q')
	}
	local c 0
	capture confirm matrix e(rates_beh)
	local hasrb = (_rc == 0)
	if `hasrb' {
		tempname rb
		matrix `rb' = e(rates_beh)
	}
	forvalues j = 1/`=colsof(`rg')' {
		if `rg'[1, `j'] == `group' {
			local ++c
			return scalar rate`c' = `rt'[1, `j']
			if `hasrb' return scalar ratebeh`c' = `rb'[1, `j']
		}
	}
	return scalar nwaves = `nW'
	tempname gnn
	matrix `gnn' = e(groupn)
	return scalar nodes = `gnn'[1, `group']
	mata: SaomModelSubsetBegin(__nwsaom_last_M, `group')
	if e(has_behavior) == 1 mata: SaomGroupsBehBegin(`group', `s', `nW')
end
