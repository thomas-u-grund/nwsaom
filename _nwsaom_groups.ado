*! version 1.1.1  27oct2026 _nwsaom_groups: helpers of nwsaom for the joint estimation of several groups (groups() option; kept out of nwsaom.ado, whose size is at Stata's limit)
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
		syntax , GROUPS(string) NODES(integer) NWAVES(integer) MULTI(integer) TM(integer) COEV(integer) [BAD(string)]
		if "`bad'" != "" {
			di "{err}groups() is not yet combinable with: {bf:`bad'}. Version 1 of the multi-group estimation covers the network-only method of moments with actor covariates."
			error 198
		}
		if !`multi' | `tm' | `coev' {
			di "{err}groups() needs {bf:waves()} and a one-mode network without a behavior."
			error 198
		}
		confirm numeric variable `groups'
		mata: st_numscalar("__ns_g_G", SaomGroupsSet(__nwsaom_last_Gwaves, st_data(1::`nodes', "`groups'")))
		local G = scalar(__ns_g_G)
		scalar drop __ns_g_G
		local W = `nwaves'
		local Wv = `G' * (`W' - 1) + 1
		forvalues k = 1/`Wv' {
			mata: __ns_gv`k' = SaomGraph()
		mata: SaomGroupsWave(__nwsaom_last_Gwaves, `k', __ns_gv`k')
		}
		mata: __ns_gpres = SaomGroupsPresent(`W')
		capture mata: mata drop __nwsaom_last_Gwaves
		forvalues k = 1/`W' {
			capture mata: mata drop __nwsaom_last_G`k'
		}
		local ptrs ""
		forvalues k = 1/`Wv' {
			mata: __nwsaom_last_G`k' = SaomGraph()
		mata: SaomCopyGraph(__ns_gv`k', __nwsaom_last_G`k')
			capture mata: mata drop __ns_gv`k'
			local ptrs `ptrs'`=cond(`k' > 1, ", ", "")'&__nwsaom_last_G`k'
		}
		mata: __nwsaom_last_Gwaves = (`ptrs')
		capture mata: mata drop __nwsaom_presentmat __ns_present1
		mata: __nwsaom_presentmat = __ns_gpres
		mata: mata drop __ns_gpres
		* group sizes and period names (RSiena numbers the periods of the glued series with the switching steps skipped)
		tempname gn
		mata: st_matrix("`gn'", SaomGroupsSizes())
		matrix __ns_gnmat = `gn'
		local pn ""
		forvalues g = 1/`G' {
			forvalues m = 1/`=`W'-1' {
				local pn "`pn' period`=(`g'-1)*`W'+`m''"
			}
		}
		return scalar nwaves = `Wv'
		return scalar ngroups = `G'
		return local pnames "`pn'"
	}
	else if "`sub'" == "show" {
		syntax , GROUPS(string) W(integer)
		tempname gn
		matrix `gn' = __ns_gnmat
		local G = colsof(`gn')
		local sz ""
		forvalues g = 1/`G' {
			local sz "`sz'`=cond(`g'>1, ", ", "")'`=`gn'[1,`g']'"
		}
		di as text "Groups: " as result `G' as text " (variable " as result "`groups'" as text "), actors per group: " as result "`sz'" as text "; periods per group: " as result `=`w'-1'
	}
end
