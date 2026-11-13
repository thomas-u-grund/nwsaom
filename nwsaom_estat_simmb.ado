*! version 1.7.0  13nov2026 nwcommands: estat simulate after nwsaom with several behaviors
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	estat simulate after a fit with several behaviors (called by nwsaom_estat_simulate). Every period starts at its observed
	wave and is simulated by the plugin at the fitted (or given) coefficients and rates. r(sim) has the columns sim, period,
	ties, mutual, transitive and one mean per behavior (behmean_<name>); generate(stub) saves the networks stub_<sim>_p<period>
	and the behaviors as variables stub_<sim>_p<period>_<name>.
*/
capture program drop nwsaom_estat_simmb
program define nwsaom_estat_simmb, rclass
	syntax [, NSIM(integer 100) SEED(integer -1) THETA(name) RATES(numlist >0) RATESBEH(numlist >0) GENerate(name) REPLACE GRP(integer 0)]
	if `grp' > 0 {
		di as err "estat simulate: grp() is not available after a fit with several behaviors."
		exit 198
	}
	if `nsim' < 1 {
		di as err "nsim() must be at least 1."
		exit 198
	}
	if `seed' != -1 set seed `seed'
	local nb = e(nbeh)
	local bnames `e(behavior_names)'
	local nodes = e(nodes)
	local nper = e(nwaves) - 1
	tempname bmat rn rb sim obs
	matrix `bmat' = e(b)
	matrix `rn' = e(rates)
	matrix `rb' = e(rates_beh)
	if "`theta'" != "" {
		capture confirm matrix `theta'
		if _rc {
			di as err "theta(): matrix `theta' not found."
			exit 111
		}
		if colsof(`theta') != colsof(`bmat') | rowsof(`theta') != 1 {
			di as err "{p 0 0 2}theta() must be a 1 x " colsof(`bmat') " row vector, in the order of e(b).{p_end}"
			exit 198
		}
		matrix `bmat' = `theta'
	}
	if "`rates'" != "" {
		if `: word count `rates'' != `nper' {
			di as err "rates() needs one rate per period (`nper')."
			exit 198
		}
		forvalues pd = 1/`nper' {
			matrix `rn'[1, `pd'] = `: word `pd' of `rates''
		}
	}
	if "`ratesbeh'" != "" {
		if `: word count `ratesbeh'' != `nb' * `nper' {
			di as err "{p 0 0 2}ratesbeh() needs one rate per behavior and period (`=`nb' * `nper''): the rates of the first behavior for every period, then those of the second, and so on.{p_end}"
			exit 198
		}
		local i = 0
		forvalues b = 1/`nb' {
			forvalues pd = 1/`nper' {
				local ++i
				matrix `rb'[`b', `pd'] = `: word `i' of `ratesbeh''
			}
		}
	}
	local maxmd = c(max_matdim)
	if `nsim' * `nper' > `maxmd' {
		di as err "{p 0 0 2}nsim() too large: r(sim) has one row per simulation and period, here `=`nsim' * `nper'' rows, and a matrix of this Stata has at most `maxmd' rows; use nsim() of at most `=floor(`maxmd' / `nper')'.{p_end}"
		exit 198
	}
	if "`generate'" != "" _nwsaom_genstub `generate', nsim(`nsim') nperiods(`nper') coev(1) behnames(`bnames') `replace'
	local W = 5 + `nb'
	local cn "sim period ties mutual transitive"
	foreach bn of local bnames {
		local cn `cn' behmean_`bn'
	}
	mata: __nwsaom_simmb_par = (st_matrix("`bmat'"), st_matrix("`rn'"), vec(st_matrix("`rb'")')')
	mata: SaomMBSimStudy(`nsim', `nper', __nwsaom_simmb_par, "`sim'", "`obs'", "`generate'", "`bnames'", "`replace'")
	capture mata: mata drop __nwsaom_simmb_par
	matrix colnames `sim' = `cn'
	matrix colnames `obs' = `cn'
	di as txt "{p 0 0 2}Simulation from the fitted model: " as res `nsim' as txt " replication(s) of " as res `nper' as txt " period(s), " as res `nb' as txt " behaviors{p_end}"
	di
	di as txt "{hline 13}{c TT}{hline 22}"
	di as txt %12s "Statistic" " {c |}" %10s "Sim" %10s "Obs"
	di as txt "{hline 13}{c +}{hline 22}"
	forvalues pd = 1/`nper' {
		di as txt %-12s "Period `pd'" " {c |}"
		forvalues c = 3/`W' {
			mata: st_numscalar("__nwsaom_sim_m", mean(select(st_matrix("`sim'")[., `c'], st_matrix("`sim'")[., 2] :== `pd')))
			if `c' <= 5 {
				local lab : word `=`c' - 2' of Ties Mutual Transitive
				di as txt %12s "`lab'" " {c |}" as res %10.1f __nwsaom_sim_m %10.0f `obs'[`pd', `c']
			}
			else {
				local lab : word `=`c' - 5' of `bnames'
				di as txt %12s abbrev("`lab'", 12) " {c |}" as res %10.2f __nwsaom_sim_m %10.2f `obs'[`pd', `c']
			}
		}
	}
	di as txt "{hline 13}{c BT}{hline 22}"
	di as txt "Sim is the mean over the replications; Obs is the observed end wave; behaviors: mean."
	capture scalar drop __nwsaom_sim_m
	return matrix sim = `sim'
	return matrix obs = `obs'
	return scalar nsim = `nsim'
end
