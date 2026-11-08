*! version 1.5.3  08nov2026 _nwsaom_precheck - option checks moved out of nwsaom.ado (Stata limits the size of one ado program)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P.).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
* Called by nwsaom:
*   _nwsaom_precheck structural, nodes() tm() multi() coev() [structural() symmetric() ratecov() ode() odc() rce() rcc()]
*       checks structural(); sets in the caller: __ns_hasstructural, __ns_ustruct, structural
*   _nwsaom_precheck timed, [joinat() leaveat() present() opts()]
*       checks joinat()/leaveat(); opts() lists the names of the other options that were given (they are not combinable)
*   _nwsaom_precheck miss, nwaves() coev() [missnet() missbeh()]
*       checks missnet()/missbeh(); sets in the caller: __ns_hasmissnet, __ns_hasmissbeh, __ns_hasmiss
* nwsaom is a large program and Stata refuses to load an ado program above a fixed size, so checks that only read option values live here.
capture program drop _nwsaom_precheck
program define _nwsaom_precheck
	version 14
	gettoken sub 0 : 0, parse(" ,")
	if "`sub'" == "structural" {
		_nwsaom_precheck_structural `0'
		c_local __ns_hasstructural "`__ns_hasstructural'"
		c_local __ns_ustruct "`__ns_ustruct'"
		c_local structural "`structural'"
		exit
	}
	if "`sub'" == "timed" {
		_nwsaom_precheck_timed `0'
		exit
	}
	if "`sub'" == "miss" {
		_nwsaom_precheck_miss `0'
		c_local __ns_hasmissnet "`__ns_hasmissnet'"
		c_local __ns_hasmissbeh "`__ns_hasmissbeh'"
		c_local __ns_hasmiss "`__ns_hasmiss'"
		exit
	}
	di "{err}_nwsaom_precheck: unknown subcommand `sub'"
	error 198
end

capture program drop _nwsaom_precheck_structural
program define _nwsaom_precheck_structural
	version 14
	syntax , NODES(integer) TM(integer) MULTI(integer) COEV(integer) [STRuctural(string) SYMmetric(string) RATEcov(string) ODE(string) ODC(string) RCE(string) RCC(string)]
	local hasstructural = 0
	local ustruct ""
	if "`structural'" != "" & !`tm' {
		local ustruct "`structural'"
		local structural ""
	}
	if "`structural'" != "" {
		if `multi' & !`tm' {
			di "{err}option {bf:structural()} is v1 scope: exactly two waves ({bf:wave1()}/{bf:wave2()}, not {bf:waves()})."
			error 198
		}
		if `coev' & !`tm' {
			di "{err}option {bf:structural()} is v1 scope: network-only, not combinable with {bf:behavior()}."
			error 198
		}
		if "`symmetric'" != "" {
			di "{err}option {bf:structural()} is v1 scope: not yet combinable with {bf:symmetric}."
			error 198
		}
		if "`ratecov'" != "" & !`tm' {
			di "{err}option {bf:structural()} is v1 scope: not yet combinable with {bf:ratecov()}."
			error 198
		}
		if "`ode'" != "" | "`odc'" != "" | "`rce'" != "" | "`rcc'" != "" {
			di "{err}option {bf:structural()} is v1 scope: not yet combinable with {bf:outdegreeendow()}/{bf:outdegreecreation()}/{bf:reciprocityendow()}/{bf:reciprocitycreation()} (network endowment/creation)."
			error 198
		}
		confirm matrix `structural'
		tempname chk
		mata: `chk' = st_matrix("`structural'")
		mata: st_local("dimok", strofreal(rows(`chk') == `nodes' & cols(`chk') == `nodes'))
		if `dimok' == 0 {
			di "{err}option {bf:structural()} matrix must be `nodes' x `nodes' (one row/column per actor) - `structural' is not."
			error 198
		}
		mata: st_local("valok", strofreal(all((`chk' :== 0) :| (`chk' :== 1))))
		if `valok' == 0 {
			di "{err}option {bf:structural()} matrix must be coded 0/1 (1=dyad frozen, not toggleable this period) - `structural' has a value outside {0,1}."
			error 198
		}
		mata: st_local("diagok", strofreal(sum(diagonal(`chk')) == 0))
		if `diagok' == 0 {
			di "{err}option {bf:structural()} matrix must have an all-zero diagonal (no self-ties)."
			error 198
		}
		mata: mata drop `chk'
		local hasstructural = 1
	}
	c_local __ns_hasstructural "`hasstructural'"
	c_local __ns_ustruct "`ustruct'"
	c_local structural "`structural'"
end

capture program drop _nwsaom_precheck_timed
program define _nwsaom_precheck_timed
	version 14
	syntax , [JOINAT(string) LEAVEAT(string) PRESENT(string) OPTS(string)]
	if "`joinat'`leaveat'" == "" exit
	if "`present'" != "" {
		di "{err}{bf:joinat()}/{bf:leaveat()} and {bf:present()} are alternatives: give the actors' joining and leaving times, or their presence at each wave, not both."
		error 198
	}
	foreach opt in joinat leaveat {
		if "``opt''" != "" confirm numeric variable ``opt''
	}
	foreach opt of local opts {
		di "{err}{bf:joinat()}/{bf:leaveat()} cannot yet be combined with {bf:`opt'}."
		error 198
	}
end

capture program drop _nwsaom_precheck_miss
program define _nwsaom_precheck_miss
	version 14
	syntax , NWAVES(integer) COEV(integer) [MISSNET(string) MISSBEH(string)]
	local hasmissnet = 0
	if "`missnet'" != "" {
		local n : word count `missnet'
		if `n' != `nwaves' {
			di "{err}option {bf:missnet()} must supply exactly `nwaves' matrix name(s), one per wave, in the same temporal order."
			error 198
		}
		local hasmissnet = 1
	}
	local hasmissbeh = 0
	if "`missbeh'" != "" {
		if `coev' == 0 {
			di "{err}option {bf:missbeh()} requires {bf:behavior()} to be specified."
			error 198
		}
		local n : word count `missbeh'
		if `n' != `nwaves' {
			di "{err}option {bf:missbeh()} must supply exactly `nwaves' variable name(s), one per wave, in the same temporal order."
			error 198
		}
		local hasmissbeh = 1
	}
	c_local __ns_hasmissnet "`hasmissnet'"
	c_local __ns_hasmissbeh "`hasmissbeh'"
	local hasmiss = (`hasmissnet' | `hasmissbeh')
	c_local __ns_hasmiss "`hasmiss'"
end
