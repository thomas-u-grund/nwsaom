*! version 1.2.0  27oct2026 _nwsaom_groupspost: e() results of nwsaom for the joint estimation of several groups of a grouped fit (groups() option)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop nwsaom_estat_gofgroups
program define nwsaom_estat_gofgroups, rclass
	syntax [, NSIM(integer 50) SEED(integer -1) STATS(string) MAXDEG(integer 15) MAXDIST(integer 6) TWOTAILED NAME(string) JOIN(string) GROUP(integer 0)]
	local G = e(ngroups)
	if "`e(ratecov)'" != "" | e(has_behavior) == 1 | "`e(present)'" != "" {
		di as err "estat gof after a fit with groups is available for network-only fits without {bf:ratecov()}/{bf:present()}."
		exit 198
	}
	if `group' < 0 | `group' > `G' {
		di as err "group() must be between 1 and `G'."
		exit 198
	}
	if "`stats'" == "" local stats "outdegree indegree geodesic"
	local opts "nsim(`nsim') seed(`seed') stats(`stats') maxdeg(`maxdeg') maxdist(`maxdist') `twotailed'"
	if "`join'" != "" local opts "`opts' join(`join')"
	tempname gsz
	matrix `gsz' = e(groupn)
	forvalues g = `=cond(`group' > 0, `group', 1)'/`=cond(`group' > 0, `group', `G')' {
		di
		di as txt "Group `g' of `G' (" as res `gsz'[1, `g'] as txt " actors)"
		capture noisily nwsaom_estat gof, `opts' name(`=cond("`name'" == "", "gof_g`g'", "`name'_g`g'")') grp(`g')
		local rc = _rc
		foreach s of local stats {
			if "`join'" == "off" | `rc' continue
			local p`g'_`s' = r(p_`s')
			return scalar p_`s'_g`g' = r(p_`s')
			return scalar mhd_`s'_g`g' = r(mhd_`s')
		}
		capture mata: SaomModelSubsetEnd(__nwsaom_last_M)
		if `rc' exit `rc'
	}
	if `group' == 0 & `G' > 1 & "`join'" != "off" {
		di
		di as txt "Combined over the groups (inverse normal method, Liptak; the manual of RSiena)"
		di as txt "{hline 60}"
		foreach s of local stats {
			local z 0
			forvalues g = 1/`G' {
				local pp = min(max(`p`g'_`s'', 1e-6), 1 - 1e-6)
				local z = `z' + invnormal(1 - `pp')
			}
			local pc = 1 - normal(`z' / sqrt(`G'))
			di as txt %-14s proper("`s'") "{c |}" as res "   combined p = " %6.3f `pc'
			return scalar p_`s' = `pc'
		}
		di as txt "{hline 60}"
	}
end

