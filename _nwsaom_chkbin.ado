*! version 1.0.10  26oct2026 _nwsaom_chkbin - the wave networks of nwsaom must hold 0/1 ties (as RSiena: "entries in networks must be 0, 1, 10 or 11")
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
* Since nwcommands 3.6.0 the Valued flag is set when a network is created (nwfromedge with a value variable makes a valued
* network also when every value is 1), so the flag no longer says whether the ties are 0/1. The values decide here:
* a network whose ties are all 1 passes, valued flag or not; any other tie value stops the command, flag or not
* (a network saved as binary by an earlier release can still hold shares). Never silently dichotomised.
capture program drop _nwsaom_chkbin
program define _nwsaom_chkbin
	version 14
	syntax , NETOBJ(string) NAME(string) [VALUED(string) CMD(string)]
	if "`cmd'" == "" local cmd "nwsaom"
	mata: st_local("__cb_ok", strofreal(`netobj'->get_arcs_count() == 0 | (`netobj'->get_maximum() <= 1 & `netobj'->get_minimum() >= 0 & `netobj'->get_arcs_sum() == `netobj'->get_arcs_count())))
	if `__cb_ok' exit
	if "`valued'" == "true" di "{err}{bf:`cmd'} estimates on binary ties only (as RSiena, which stops on tie values other than 0 and 1); {bf:`name'} is a valued network with tie values other than 1. Dichotomize it first ({help nwdichotomize}); {bf:`cmd'} never turns tie values into ties silently."
	else di "{err}{bf:`cmd'} estimates on binary ties only (as RSiena, which stops on tie values other than 0 and 1); {bf:`name'} is not declared valued but holds tie values other than 0 and 1 (saved by an earlier release?). Dichotomize it first ({help nwdichotomize}); {bf:`cmd'} never turns tie values into ties silently."
	error 198
end
