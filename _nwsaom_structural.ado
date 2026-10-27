*! version 1.2.0  27oct2026 _nwsaom_structural - structural zeros and ones (the codes 10 and 11 in the wave networks, as RSiena): build the per-wave sets, refuse the combinations not yet supported
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
* Called by nwsaom after the wave graphs are built (the codes were recorded by SaomStructFix() while the graphs were built):
*   _nwsaom_structural build, nodes() nwaves() hasmissnet() tm() ml() symmetric() symtype() groups() behavior() structural()
* The state is the Mata external __nwsaom_sset (see unw_saom_struct.do); SaomRatesReset() removes it at the start and the end of every nwsaom call.
capture program drop _nwsaom_structural
program define _nwsaom_structural, rclass
	version 14
	gettoken sub 0 : 0, parse(" ,")
	if "`sub'" == "build" {
		_nwsaom_structural_build `0'
		exit
	}
	di "{err}_nwsaom_structural: unknown subcommand `sub'"
	error 198
end

capture program drop _nwsaom_structural_build
program define _nwsaom_structural_build
	version 14
	syntax , NODES(integer) NWAVES(integer) HASMISSNET(integer) TM(integer) [ML(string) SYMMETRIC(string) SYMTYPE(string) GROUPS(string) BEHAVIOR(string) STRUCTURAL(string) MB(string) RATE(string)]
	// the combinations that are not supported yet
	local bad ""
	if "`ml'" != "" local bad "`bad' ml"
	if "`symmetric'`symtype'" != "" local bad "`bad' symmetric"
	if "`groups'" != "" local bad "`bad' groups()"
	if "`behavior'" != "" & ("`mb'" == "1" | "`rate'" != "") local bad "`bad' behavior() with several behaviors or rate covariates"
	if "`structural'" != "" & !(`tm' & "`structural'" == "__nwsaom_tm_structmat") local bad "`bad' structural()"
	if "`bad'" != "" {
		di "{err}structural zeros and ones (the codes 10 and 11 in the wave networks) are not yet supported together with:`bad'."
		error 198
	}
	// missing data: a dyad that is missing at a wave takes the structural code of the previous wave (RSiena)
	if `hasmissnet' {
		forvalues w = 2/`nwaves' {
			mata: SaomStructCarry(`w', __ns_missnet_w`w', `nodes')
		}
	}
	if "`symmetric'`symtype'" != "" {
		mata: st_local("symbad", strofreal(SaomStructSymCheck(`nwaves', `nodes')))
		if `symbad' {
			di "{err}in a non-directed relation the structural codes (10 and 11) must be given for both directions of a dyad, with the same value (wave `symbad' has a code that is not mirrored); RSiena would treat the network as directed."
			error 198
		}
	}
	mata: SaomStructBuild(`nwaves', `nodes')
end
