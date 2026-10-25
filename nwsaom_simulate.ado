*! version 1.0.6  25oct2026 nwcommands: nwsaom simulate (simulation-only mode)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	nwsaom simulate, <the model options of nwsaom> theta(#...) [behtheta(#...)] rates(#...) [ratesbeh(#...)]
		[nsim(#) seed(#) generate(stub)]

	Simulates a stochastic actor-oriented model at parameters chosen by the
	user, without estimating anything (RSiena's siena07 with simOnly = TRUE).
	The model is specified exactly as in nwsaom (waves, effects, covariates, behavior(), ...);
	theta() gives one coefficient per network effect in the order of the effect
	options, behtheta() one per behavior effect, rates() the rate of every
	period (one value per inter-wave period), ratesbeh() the behavior rates.

	Implementation: the model is set up by an ordinary nwsaom call with every
	coefficient fixed (fix(_all)) at the chosen values and a very short run,
	so every data option nwsaom has is understood; estat simulate then
	simulates at the chosen coefficients and rates.
*/
capture program drop nwsaom_simulate
program define nwsaom_simulate, rclass
	_nwsaom_libcheck
	local cmdline `"`0'"'
	local theta ""
	local behtheta ""
	local rates ""
	local ratesbeh ""
	local nsim 100
	local seed -1
	local gen ""
	foreach o in behtheta ratesbeh theta rates nsim seed generate {
		if regexm(`"`cmdline'"', "(^|[ ,])`o'\(([^)]*)\)") {
			local v = regexs(2)
			local cmdline = regexr(`"`cmdline'"', "(^|[ ,])`o'\([^)]*\)", " ")
			if "`o'" == "generate" local gen "`v'"
			else local `o' "`v'"
		}
	}
	if "`theta'" == "" & "`behtheta'" == "" {
		di as err "nwsaom simulate needs theta() (and behtheta() with behavior effects): the coefficients to simulate at."
		exit 198
	}
	if "`rates'" == "" {
		di as err "nwsaom simulate needs rates(): one rate per inter-wave period."
		exit 198
	}
	local thopt ""
	if "`theta'" != "" local thopt "theta0(`theta')"
	if "`behtheta'" != "" local thopt "`thopt' behtheta0(`behtheta')"
	capture noisily quietly nwsaom `cmdline' `thopt' fix(_all) k0(20) k3(40) seed(1)
	if _rc {
		di as err "nwsaom simulate: the model could not be set up (see the message above)."
		exit _rc
	}
	tempname tm
	matrix `tm' = e(b)
	local nt : word count `theta' `behtheta'
	if `nt' != colsof(`tm') {
		di as err "theta()/behtheta() give `nt' value(s) but the model has " colsof(`tm') " coefficient(s)."
		exit 198
	}
	local j 0
	foreach v in `theta' `behtheta' {
		local ++j
		matrix `tm'[1, `j'] = `v'
	}
	local ropt "rates(`rates')"
	if "`ratesbeh'" != "" local ropt "`ropt' ratesbeh(`ratesbeh')"
	local gopt ""
	if "`gen'" != "" local gopt "generate(`gen')"
	estat simulate, nsim(`nsim') seed(`seed') theta(`tm') `ropt' `gopt'
	return add
end
