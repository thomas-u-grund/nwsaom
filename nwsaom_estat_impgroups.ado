*! version 1.2.0  27oct2026 _nwsaom_groupspost: e() results of nwsaom for the joint estimation of several groups of a grouped fit (groups() option)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop nwsaom_estat_impgroups
program define nwsaom_estat_impgroups, rclass
	syntax [, GROUP(integer 0)]
	local G = e(ngroups)
	if "`e(ratecov)'" != "" | e(has_behavior) == 1 {
		di as err "estat importance after a fit with groups is available for network-only fits without {bf:ratecov()}."
		exit 198
	}
	if `group' < 0 | `group' > `G' {
		di as err "group() must be between 1 and `G'."
		exit 198
	}
	tempname gsz
	matrix `gsz' = e(groupn)
	forvalues g = `=cond(`group' > 0, `group', 1)'/`=cond(`group' > 0, `group', `G')' {
		di
		di as txt "Group `g' of `G' (" as res `gsz'[1, `g'] as txt " actors)"
		capture noisily nwsaom_estat importance, grp(`g')
		local rc = _rc
		tempname ri sgp
		capture matrix `ri' = r(ri)
		capture matrix `sgp' = r(sigma_period)
		capture mata: SaomModelSubsetEnd(__nwsaom_last_M)
		if `rc' exit `rc'
		capture return matrix ri_g`g' = `ri'
		capture return matrix sigma_period_g`g' = `sgp'
	}
end
