*! version 1.2.0  27oct2026 _nwsaom_chkbin - the wave networks of nwsaom must hold the tie values 1, 10 and 11 (as RSiena: "entries in networks must be 0, 1, 10, 11, or NA")
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
* Since nwcommands 3.6.0 the Valued flag is set when a network is created (nwfromedge with a value variable makes a valued
* network also when every value is 1), so the flag no longer says whether the ties are 0/1. The values decide here:
* a network whose ties are all 1 passes, valued flag or not. RSiena's codes 10 (structural zero) and 11 (structural one) pass when the
* caller says the wave number (option wave()): the calling program then records the structural dyads (SaomStructFix in unw_saom_struct.do).
* Without wave() (the other commands: multiplex, multinet) a network with these codes stops the command with a message that says so.
* Any other tie value stops the command, flag or not (a network saved as binary by an earlier release can still hold shares). Never silently dichotomised.
* Returns r(nstruct): the number of arcs whose value is not 1 (codes 10 and 11, explicit zeros).

capture program drop _nwsaom_chkbin
program define _nwsaom_chkbin, rclass
	version 14
	syntax , NETOBJ(string) NAME(string) [VALUED(string) CMD(string) WAVE(integer 0)]
	if "`cmd'" == "" local cmd "nwsaom"
	mata: st_local("__cb_ok", strofreal(`netobj'->get_arcs_count() == 0 | (`netobj'->get_maximum() <= 1 & `netobj'->get_minimum() >= 0 & `netobj'->get_arcs_sum() == `netobj'->get_arcs_count())))
	if `__cb_ok' {
		return scalar nstruct = 0
		exit
	}
	local __cb_nstr 0
	mata: st_local("__cb_ok", strofreal(SaomStructCheck(`netobj')))
	if `__cb_ok' {
		if `wave' == 0 {
			di "{err}{bf:`cmd'} does not yet support structural zeros and ones (the codes 10 and 11); {bf:`name'} holds such tie values."
			error 198
		}
		return scalar nstruct = `__cb_nstr'
		exit
	}
	if "`valued'" == "true" di "{err}{bf:`cmd'} estimates on binary ties only (as RSiena, which stops on tie values other than 0, 1, 10 and 11); {bf:`name'} is a valued network with the tie value `__cb_badv' (dyad `__cb_badi' -> `__cb_badj'). Dichotomize it first ({help nwdichotomize}); {bf:`cmd'} never turns tie values into ties silently."
	else di "{err}{bf:`cmd'} estimates on binary ties only (as RSiena, which stops on tie values other than 0, 1, 10 and 11); {bf:`name'} is not declared valued but holds the tie value `__cb_badv' (dyad `__cb_badi' -> `__cb_badj') (saved by an earlier release?). Dichotomize it first ({help nwdichotomize}); {bf:`cmd'} never turns tie values into ties silently."
	error 198
end
