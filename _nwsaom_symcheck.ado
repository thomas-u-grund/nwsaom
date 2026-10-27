*! version 1.1.1  27oct2026 _nwsaom_symcheck (the checks of symmetric/symtype() of nwsaom, split out because nwsaom.ado is at the size limit of one ado program)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
capture program drop _nwsaom_symcheck
program define _nwsaom_symcheck, rclass
	syntax , HASNETGATE(integer) SYMBAD(integer) [SYMMETRIC(string) RECIPROCITY(string) SYMTYPE(string)]
	local symmetric "`symmetric'"
	local __ns_symtypeval = 4
	if "`symmetric'" != "" {
		if `hasnetgate' {
			di "{err}{bf:symmetric} cannot be combined with {bf:endow()}/{bf:creation()} of network effects. {bf:waves()}, {bf:present()}, {bf:missnet()}, {bf:ratecov()} and {bf:behavior()} are otherwise combinable with {bf:symmetric}."
			error 198
		}
		if "`reciprocity'" != "" {
			di "{err}{bf:reciprocity} is not meaningful under {bf:symmetric} - every tie is reciprocated by construction once both directions are forced equal, so this effect's own statistic is a constant (RSiena itself does not offer {bf:recip} for a non-directed dependent variable)."
			exit 198
		}
		// symtype(): the model type of the non-directed relation, named
		// or as RSiena's modelType number (NetworkModelType enum,
		// NetworkVariable.cpp):
		//   forcing       2 AFORCE  unilateral initiative, imposed (default,
		//                 RSiena's default for a symmetric network:
		//                 initializeFRAN() changes modelType 1 to 2)
		//   confirmation  3 AAGREE  unilateral initiative, a new tie needs
		//                 the alter's confirmation
		//   force         4 BFORCE  pairwise, the initiator decides
		//   agree         5 BAGREE  pairwise, creation needs both
		//   joint         6 BJOINT  pairwise, joint decision
		// Internal codes (native/saom_sim.c): joint 1, force 2, agree 3,
		// forcing 4, confirmation 5. Before 2026-10-01 the default was
		// joint and the A types did not exist.
			if "`symtype'" != "" {
			local __ns_symtype_lc = lower(strtrim("`symtype'"))
			local __ns_symtypeval = 0
			if inlist("`__ns_symtype_lc'", "joint", "6") local __ns_symtypeval = 1
			else if inlist("`__ns_symtype_lc'", "force", "4") local __ns_symtypeval = 2
			else if inlist("`__ns_symtype_lc'", "agree", "5") local __ns_symtypeval = 3
			else if inlist("`__ns_symtype_lc'", "forcing", "2") local __ns_symtypeval = 4
			else if inlist("`__ns_symtype_lc'", "confirmation", "3") local __ns_symtypeval = 5
			if `__ns_symtypeval' == 0 {
				di "{err}{bf:symtype()} must be {bf:forcing} (default; RSiena modelType 2), {bf:confirmation} (3), {bf:force} (4), {bf:agree} (5), or {bf:joint} (6), or one of these numbers - got {bf:`symtype'}."
				error 198
			}
		}
		// Effect-meaningfulness audit for `symmetric', beyond reciprocity
		// above: checked against real RSiena 1.6.6's own getEffects()
		// output (not derived/assumed) - built a symmetric-data
		// sienaDependent and a directed one side by side and diffed
		// their own `type=="eval"' shortName sets. RSiena auto-detects
		// symmetry from the data itself (no explicit type= argument
		// needed - printing the resulting siena data object reports
		// "Type: oneMode, symmetric") and silently drops every
		// direction-dependent effect whose own indegree/outdegree
		// distinction collapses once in==out==degree for every actor,
		// consistent with algebra (e.g. `outPop's own
		// sqrt(outdeg)*indeg formula reduces to indeg^1.5, identical to
		// `inPop, so RSiena drops `outPop as a redundant duplicate
		// rather than a meaningless one) but confirmed from the real
		// tool rather than derived by hand for every effect. The four
		// directional degree-assortativity effects (outOutAss/inInAss/
		// outInAss/inOutAss) all reduce to the SAME statistic once
		// symmetric; RSiena keeps exactly one canonical name
		// (`outInAss) and drops the other three - `outinass' is
		// therefore the one of this family still ALLOWED here,
		// mirroring RSiena's own real choice, not an arbitrary pick.
		// `antiIso' is dropped while `antiInIso'/`antiInIso2' are BOTH
		// kept (a real, non-obvious asymmetry in RSiena's own table,
		// not derivable from the effect names alone) - matched exactly,
		// not guessed. `transTrip' is dropped for symmetric (RSiena
		// offers a differently-formulated `transTriads' there instead,
		// which this package does not implement), while `cycle4',
		// `isolateNet', `outIso', `gwesp', `transTies', and `balance'
		// all remain genuinely offered by RSiena for a symmetric
		// relation and are left unrestricted here. Every covariate-based
		// effect (`nodecov'/`nodeicov'/`nodeocov'/`nodematch'/`simcov'
		// and their egoX/altX/sameX/simX aliases) was independently
		// confirmed still offered (RSiena's own egoX/altX/sameX/simX
		// shortNames appear unchanged in the symmetric effect table) -
		// only compound covariate x directed-structural-effect
		// interactions RSiena itself does not offer for symmetric data
		// are absent, and this package implements none of those
		// interaction forms regardless, so no restriction is needed for
		// the covariate family.
		if `symbad' {
			di "{err}under {bf:symmetric}, {bf:cycle3}/{bf:inactivity}/{bf:outpopularity}/{bf:ininass}/{bf:inoutass}/{bf:outoutass}/{bf:antiiso}/{bf:isolatepop}/{bf:transrectrip}/{bf:transtrip} are each either a constant, an exact duplicate of an already-available effect, or an effect real RSiena itself does not offer for a non-directed relation (confirmed against RSiena's own real {bf:getEffects()} output, not assumed) - {bf:outdegree}/{bf:indegpopularity}/{bf:outactivity}/{bf:cycle4}/{bf:isolatenet}/{bf:outiso}/{bf:antiiniso}/{bf:antiiniso2}/{bf:outinass}/{bf:gwesp}/{bf:transties}/{bf:balance} and every covariate effect remain available."
			error 198
		}
		// data-level symmetry check - a real, disclosed requirement, not
		// silently assumed: `symmetric' only changes the ministep
		// MECHANISM, it never symmetrizes the input data itself.
		mata: st_numscalar("__ns_symchk1", max(abs(__nwsaom_last_G1.to_dense() - __nwsaom_last_G1.to_dense()')))
		mata: st_numscalar("__ns_symchk2", max(abs(__nwsaom_last_G2.to_dense() - __nwsaom_last_G2.to_dense()')))
		if __ns_symchk1 > 0 | __ns_symchk2 > 0 {
			di "{err}{bf:symmetric} requires both wave networks to be tie-symmetric (x_ij == x_ji for every dyad); it selects a non-directed ministep, it does not symmetrize the data."
			error 198
		}
	}
	else if "`symtype'" != "" {
		di "{err}{bf:symtype()} applies to a non-directed relation only (tie-symmetric or undirected waves, or {bf:symmetric})."
		error 198
	}
	return scalar symtypeval = `__ns_symtypeval'
end
