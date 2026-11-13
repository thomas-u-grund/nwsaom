*! version 1.6.0  13nov2026 nwcommands: e() results of nwsaom posted after the fit (options as given, fit identifier)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	Called by nwsaom after ereturn post (the main program is at Stata's size limit): the composition-change and missing-data
	options as typed (read back from e(cmdline), because nwsaom replaces some of them by temporary variables with groups()),
	the mode of the actors of a two-mode fit, and e(fitid), which ties the estimates to the Mata model kept for postestimation.
*/
capture program drop _nwsaom_epost
program define _nwsaom_epost, eclass
	local 0 `"`e(cmdline)'"'
	gettoken cmd 0 : 0
	local 0 = strtrim(`"`0'"')
	if substr(`"`0'"', 1, 1) != "," local 0 `", `0'"'
	capture syntax [, PRESENT(string) JOINAT(string) LEAVEAT(string) MISSNET(string) MISSBEH(string) ACTORMODE(integer 0) *]
	if _rc == 0 {
		foreach o in present joinat leaveat missnet missbeh {
			if `"``o''"' != "" ereturn local `o' `"``o''"'
		}
		if e(twomode) == 1 ereturn scalar actormode = cond(`actormode' == 0, 2, `actormode')
	}
	tempname id
	mata: st_numscalar("`id'", SaomFitIdNew())
	ereturn scalar fitid = scalar(`id')
end
