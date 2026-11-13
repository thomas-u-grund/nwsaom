*! version 1.6.0  13nov2026 _nwsaom_mbparse - parses behavior(a1 a2 : effects | b1 b2 : effects) of nwsaom (several behaviors; Stata limits the size of one ado program)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P.).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
* Called by nwsaom: _nwsaom_mbparse, behavior() nwaves() [gl() behsim]
*   '|' separates the behaviors, ':' the per-wave variables from that behavior's effects (omitted: the global effect options gl()).
*   Returns r(nb) and, per behavior b, r(v<b>) (the variables), r(e<b>) (the behavior effects; for behavior 1 also behsim behegox behaltx behegoplusalt)
*   and r(n<b>) (b >= 2: the network effects with that behavior as the covariate: behsim behegox behaltx behegoplusalt netbeh:<effect>);
*   for behavior 1 r(beheff1) (its beheff() tokens) and r(netbeh1) (its netbeh: effects).
capture program drop _nwsaom_mbparse
program define _nwsaom_mbparse, rclass
	version 14
	syntax , BEHavior(string) NWAVES(integer) [ GL(string) BEHSIM ]
	// RSiena's behavior effects of the network position / the alters / the similarity family, also valid as beheff() tokens
	local newbeh "indeg outdeg recipdeg isolate outisolate totalt avaltpop totaltpop maxalt minalt avrecalt totrecalt totsim avatthigher avattlower totatthigher totattlower avsimpopalt totsimpopalt avsimpopego avinsim totinsim avinsimpopalt totinsimpopalt avsimrecip totsimrecip avsimrecpop totsimrecpop popalt totpopalt avinalt totinalt avaltdist2 totaltdist2 avtaltdist2 totaaltdist2 avinaltdist2 totinaltdist2 avtinaltdist2 totainaltdist2"
	local effnames "linear quadratic avalt avsim linearendow linearcreation quadraticendow quadraticcreation avaltendow avaltcreation avsimendow avsimcreation `newbeh'"
	local netnames "behsim behegox behaltx behegoplusalt"
	local rest `"`behavior'"'
	local nb 0
	while `"`rest'"' != "" {
		local bar = strpos(`"`rest'"', "|")
		if `bar' > 0 {
			local grp = strtrim(substr(`"`rest'"', 1, `bar' - 1))
			local rest = strtrim(substr(`"`rest'"', `bar' + 1, .))
		}
		else {
			local grp = strtrim(`"`rest'"')
			local rest ""
		}
		local ++nb
		local col = strpos(`"`grp'"', ":")
		if `col' > 0 {
			local v = strtrim(substr(`"`grp'"', 1, `col' - 1))
			local eff = strtrim(substr(`"`grp'"', `col' + 1, .))
		}
		else {
			local v = strtrim(`"`grp'"')
			local eff ""
		}
		if "`eff'" == "" local eff "`gl'"
		local nwc : word count `v'
		if `nwc' != `nwaves' {
			di "{p 0 0 2}{err}each behavior in {bf:behavior()} must supply exactly `nwaves' variable name(s), one per wave, in the same temporal order; behavior `nb' has `nwc'.{p_end}"
			error 198
		}
		local e ""
		local n ""
		local be ""
		local nbh ""
		foreach t of local eff {
			if substr("`t'", 1, 7) == "netbeh:" & strlen("`t'") > 7 {
				if `nb' == 1 local nbh "`nbh' `=substr("`t'", 8, .)'"
				else local n "`n' `t'"
			}
			else if `: list t in netnames' {
				if `nb' == 1 local e "`e' `t'"
				else local n "`n' `t'"
			}
			else if !`: list t in effnames' {
				di "{p 0 0 2}{err}behavior `nb' of {bf:behavior()}: unknown effect {bf:`t'}; the effects are linear quadratic avalt avsim, their endow/creation variants (linearendow ...), the {bf:beheff()} tokens, and the network effects with the behavior as covariate behsim behegox behaltx behegoplusalt and {bf:netbeh:}{it:effect}.{p_end}"
				error 198
			}
			else if `nb' == 1 & `: list t in newbeh' local be "`be' `t'"
			else local e "`e' `t'"
		}
		// the option behsim (selection on the behavior) belongs to the first behavior, as behsim in its own list
		if `nb' == 1 & "`behsim'" != "" & !`: list posof "behsim" in e' local e "`e' behsim"
		return local v`nb' `v'
		return local e`nb' `e'
		return local n`nb' `n'
		if `nb' == 1 {
			return local beheff1 `be'
			return local netbeh1 `nbh'
		}
	}
	return scalar nb = `nb'
end
