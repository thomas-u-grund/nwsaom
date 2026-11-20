*! version 1.9.1  20nov2026 _nwsaom_tabopts: the options of ereturn display for the coefficient tables of nwsaom
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
// the options of ereturn display for the coefficient table. The coefficient names are shown in full: the
// confidence intervals are left out (noci) at a linesize below 100, where names of up to 32 characters do not fit next
// to them. ci, or level(#) given explicitly, shows the intervals (long names are then cut, e.g. nodematch_o~e); noci,
// nopvalues, cformat() and the other display options of Stata's estimation commands are passed on. With check, only
// the options are checked (before a fit).
// Use: _nwsaom_tabopts <local> [check] [, options]; the options for ereturn display are returned in <local>.
capture program drop _nwsaom_tabopts
program _nwsaom_tabopts
	version 14
	gettoken __mac 0 : 0, parse(" ,")
	gettoken __chk : 0, parse(" ,")
	if `"`__chk'"' == "check" gettoken __chk 0 : 0, parse(" ,")
	else local __chk
	syntax [, Level(string) *]
	local __lev `"`level'"'
	// ci is picked out by hand: declared to syntax, ci would also take noci (as its negation)
	local ci
	local __rest
	while `"`options'"' != "" {
		gettoken __o options : options, bind
		if strlower(`"`__o'"') == "ci" local ci ci
		else local __rest `"`__rest' `__o'"'
	}
	_get_diopts __di, `__rest'
	local __noci : list posof "noci" in __di
	local __nopv : list posof "nopvalues" in __di
	if "`ci'" != "" & `__noci' {
		di as err "only one of options ci or noci is allowed"
		exit 198
	}
	local __show = ("`ci'" != "" | `"`__lev'"' != "")
	if `"`__lev'"' != "" {
		local 0 , level(`__lev')
		syntax [, Level(cilevel)]
		local __lev `level'
	}
	else local __lev = c(level)
	if "`__chk'" != "" exit
	local __add
	if !`__show' & !`__noci' & !`__nopv' {
		// full names: at a linesize below 100 (or with lstretch off) the names of up to 32 characters do not fit next
		// to the intervals; from 100 on both fit
		if c(linesize) < 100 | c(lstretch) == "off" | `: list posof "nolstretch" in __di' local __add noci
	}
	c_local `__mac' `"level(`__lev') `__di' `__add'"'
end
