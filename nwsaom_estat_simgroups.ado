*! version 1.2.0  27oct2026 _nwsaom_groupspost: e() results of nwsaom for the joint estimation of several groups of a grouped fit (groups() option)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop nwsaom_estat_simgroups
program define nwsaom_estat_simgroups, rclass
	syntax [, NSIM(integer 100) SEED(integer -1) THETA(name) RATES(numlist >0) GENerate(name) GROUP(integer 0)]
	local G = e(ngroups)
	if `group' < 0 | `group' > `G' {
		di as err "group() must be between 1 and `G'."
		exit 198
	}
	tempname gsz
	matrix `gsz' = e(groupn)
	local opts "nsim(`nsim') seed(`seed')"
	tempname rgm
	matrix `rgm' = e(rates_group)
	if "`rates'" != "" {
		local nr : word count `rates'
		if `nr' != colsof(`rgm') {
			di as err "rates() needs one rate per period of all groups (" colsof(`rgm') ")."
			exit 198
		}
	}
	if "`theta'" != "" local opts "`opts' theta(`theta')"
	forvalues g = `=cond(`group' > 0, `group', 1)'/`=cond(`group' > 0, `group', `G')' {
		di
		di as txt "Group `g' of `G' (" as res `gsz'[1, `g'] as txt " actors)"
		local gen = cond("`generate'" == "", "", "generate(`generate'_g`g')")
		local grates ""
		if "`rates'" != "" {
			forvalues j = 1/`=colsof(`rgm')' {
				if `rgm'[1, `j'] == `g' {
					local rj : word `j' of `rates'
					local grates "`grates' `rj'"
				}
			}
			local grates "rates(`grates')"
		}
		capture noisily nwsaom_estat simulate, `opts' `gen' `grates' grp(`g')
		local rc = _rc
		tempname sm ob
		capture matrix `sm' = r(sim)
		capture matrix `ob' = r(obs)
		capture mata: SaomModelSubsetEnd(__nwsaom_last_M)
		if e(has_behavior) == 1 capture mata: SaomGroupsBehEnd()
		if "`e(present)'" != "" capture mata: __nwsaom_last_present = J(0, 1, 0)
		if `rc' exit `rc'
		capture return matrix sim_g`g' = `sm'
		capture return matrix obs_g`g' = `ob'
	}
end
