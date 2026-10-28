*! version 1.3.1  28oct2026 _nwsaom_groups: helpers of nwsaom for the joint estimation of several groups (groups() option; kept out of nwsaom.ado, whose size is at Stata's limit)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/* build: checks the options and the networks, glues the groups into one chain of virtual waves (see unw_saom.do, "Joint
   estimation of several groups"), replaces the Mata wave graphs __nwsaom_last_G1.. and __nwsaom_last_Gwaves and sets the
   presence matrix. Returns r(nwaves) (virtual waves), r(pnames) (period names with RSiena's numbering), r(ngroups).
   post: e() results of a grouped fit. show: header lines. */
capture program drop _nwsaom_groups
program define _nwsaom_groups, rclass
	gettoken sub 0 : 0, parse(" ,")
	if "`sub'" == "build" {
		syntax , GROUPS(string) NODES(integer) NWAVES(integer) MULTI(integer) TM(integer) COEV(integer) HASPRES(integer) HASMISSNET(integer) [GWAVES(string) BAD(string) TVCOV(string) JOINAT(string) LEAVEAT(string)]
		if "`bad'" != "" {
			di "{err}groups() is not yet combinable with: {bf:`bad'}."
			error 198
		}
		if !`multi' | `tm' {
			di "{err}groups() needs {bf:waves()} and a one-mode network."
			error 198
		}
		confirm numeric variable `groups'
		mata: __ns_ggrp = st_data(1::`nodes', "`groups'")
		mata: __ns_gwl = SaomGroupsParseWaves(`"`gwaves'"', __ns_ggrp, `nwaves')
		mata: st_numscalar("__ns_g_G", SaomGroupsSet(__nwsaom_last_Gwaves, __ns_ggrp, __ns_gwl, `haspres'))
		local G = scalar(__ns_g_G)
		scalar drop __ns_g_G
		local W = `nwaves'
		mata: st_numscalar("__ns_g_Wv", sum(SaomGroupsNW() :- 1) + 1)
		local Wv = scalar(__ns_g_Wv)
		scalar drop __ns_g_Wv
		forvalues k = 1/`Wv' {
			mata: __ns_gv`k' = SaomGraph()
			mata: SaomGroupsWave(__nwsaom_last_Gwaves, `k', __ns_gv`k')
		}
		if "`joinat'`leaveat'" != "" {
			* composition change at fractional times: the times are on the time scale of the waves of the actor's own group (RSiena: every group is its own data object)
			mata: SaomGroupsTimed(`nwaves', "`joinat'", "`leaveat'")
		}
		if `haspres' mata: __ns_gpres = SaomGroupsPresent(__nwsaom_presentmat)
		else mata: __ns_gpres = SaomGroupsPresent(J(0, 0, 0))
		if `hasmissnet' {
			local ptrs ""
			forvalues k = 1/`W' {
				local ptrs `ptrs'`=cond(`k' > 1, ", ", "")'&__ns_missnet_w`k'
			}
			mata: __ns_gmp = (`ptrs')
			forvalues k = 1/`Wv' {
				mata: __ns_gm`k' = SaomGroupsCarry(__ns_gmp, `k')
			}
		}
		capture mata: mata drop __nwsaom_last_Gwaves
		forvalues k = 1/`W' {
			capture mata: mata drop __nwsaom_last_G`k'
			if `hasmissnet' capture mata: mata drop __ns_missnet_w`k'
		}
		local ptrs ""
		forvalues k = 1/`Wv' {
			mata: __nwsaom_last_G`k' = SaomGraph()
			mata: SaomCopyGraph(__ns_gv`k', __nwsaom_last_G`k')
			capture mata: mata drop __ns_gv`k'
			if `hasmissnet' {
				mata: __ns_missnet_w`k' = __ns_gm`k'
				capture mata: mata drop __ns_gm`k'
			}
			local ptrs `ptrs'`=cond(`k' > 1, ", ", "")'&__nwsaom_last_G`k'
		}
		mata: __nwsaom_last_Gwaves = (`ptrs')
		capture mata: mata drop __nwsaom_presentmat __ns_present1
		mata: __nwsaom_presentmat = __ns_gpres
		capture mata: mata drop __ns_gpres __ns_gwl __ns_ggrp __ns_gmp
		* group sizes, waves per group and period names (RSiena numbers the periods of the glued series with the switching steps skipped)
		mata: st_matrix("__ns_gnmat", SaomGroupsSizes())
		mata: st_matrix("__ns_gwmat", SaomGroupsNW()')
		mata: st_local("pn", invtokens("period" :+ strofreal(SaomGroupsRSienaPeriod())))
		local tvnew ""
		if `"`tvcov'"' != "" {
			mata: st_local("tvnew", SaomGroupsTvExpand(`"`tvcov'"'))
		}
		return scalar nwaves = `Wv'
		return scalar ngroups = `G'
		return local pnames "`pn'"
		return local tvcov `"`tvnew'"'
	}
	else if "`sub'" == "behvars" {
		* the behavior at the virtual waves (one new variable per virtual wave), the group constants of the behavior (RSiena keeps them per group)
		syntax , NAMES(string) BEHAVIOR(string) NODES(integer) [NAMES2(string) MISSBEH(string)]
		confirm numeric variable `behavior'
		if "`missbeh'" != "" mata: SaomGroupsBehConstants(st_data(1::`nodes', "`behavior'"), st_data(1::`nodes', "`missbeh'"))
		else mata: SaomGroupsBehConstants(st_data(1::`nodes', "`behavior'"), J(0, 0, 0))
		foreach v of local names {
			quietly gen double `v' = .
		}
		mata: st_store(1::`nodes', tokens("`names'"), SaomGroupsBehVirtual(st_data(1::`nodes', "`behavior'")))
		return local behavior "`names'"
		if "`missbeh'" != "" {
			foreach v of local names2 {
				quietly gen double `v' = .
			}
			mata: st_store(1::`nodes', tokens("`names2'"), SaomGroupsBehVirtual(st_data(1::`nodes', "`missbeh'")))
			return local missbeh "`names2'"
		}
	}
	else if "`sub'" == "show" {
		syntax , GROUPS(string) W(integer)
		tempname gn gw
		matrix `gn' = __ns_gnmat
		local G = colsof(`gn')
		local sz ""
		forvalues g = 1/`G' {
			local sz "`sz'`=cond(`g'>1, ", ", "")'`=`gn'[1,`g']'"
		}
		matrix `gw' = __ns_gwmat
		local wz ""
		forvalues g = 1/`G' {
			local wz "`wz'`=cond(`g'>1, ", ", "")'`=`gw'[1,`g']'"
		}
		di as text "Groups: " as result `G' as text " (variable " as result "`groups'" as text "), actors per group: " as result "`sz'" as text "; waves per group: " as result "`wz'"
	}
end
