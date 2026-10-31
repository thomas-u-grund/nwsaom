*! version 1.4.2  31oct2026 nwcommands: nwsaom describe - the data description that comes before a SAOM fit
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	nwsaom describe, waves(net1 net2 ...) [behavior(var1 var2 ...)]

	What RSiena prints before estimation (its data report): for every wave the number of
	ties, the density and the average degree; for every period the numbers of ties created,
	dissolved and kept, the Jaccard index and the Hamming distance; for a behavior the mean
	and the numbers of actors who move up, down or stay between the waves. The Jaccard
	index of a period is kept / (kept + created + dissolved); RSiena's rule of thumb is
	that values below about 0.3 give little information about the process.
*/
capture program drop nwsaom_describe
program define nwsaom_describe, rclass
	version 14
	_nwsaom_libcheck
	syntax , WAVES(string) [ BEHavior(string) ACTORMODE(integer 2) ]
	nwunab waves : `waves', min(2)
	local nw : word count `waves'
	if `nw' < 2 {
		di as err "waves() needs at least two networks."
		exit 198
	}
	tempname P W
	local n0 = .
	local ntm 0
	matrix `P' = J(`=`nw'-1', 6, .)
	matrix `W' = J(`nw', 5, .)
	forvalues w = 1/`nw' {
		local nm : word `w' of `waves'
		_nwsyntax `nm', max(1)
		local nodes`w' = `nodes'
		local dir`w' = ("`directed'" == "true")
		local obj`w' `netobj'
		if "`is2mode'" == "true" local ++ntm
		if `w' == 1 local n0 = `nodes'
		if `nodes' != `n0' {
			di as err "all waves need the same number of nodes."
			exit 198
		}
		if `dir`w'' != `dir1' {
			di as err "all waves must be directed or all undirected."
			exit 198
		}
	}
	// a two-mode network: the ties are the cells of the actors x events matrix (as nwsaom models them), not the cells within a mode
	local tm 0
	tempname ISA
	if `ntm' > 0 {
		if `ntm' < `nw' {
			di as err "the waves mix two-mode and one-mode networks."
			exit 198
		}
		if !inlist(`actormode', 1, 2) {
			di as err "actormode() must be 1 or 2 (the mode whose nodes are the actors)."
			exit 198
		}
		local tm 1
		mata: `ISA' = (`obj1'->get_modes() :== "`actormode'")
		mata: st_local("na", strofreal(sum(`ISA')))
		local ne = `n0' - `na'
		if `na' == 0 | `ne' == 0 {
			capture mata: mata drop `ISA'
			di as err "the two-mode network needs nodes in both modes."
			exit 198
		}
	}
	local div = cond(`tm', 1, cond(`dir1', 1, 2))
	tempname MA MB EX
	forvalues w = 1/`nw' {
		mata: `MA' = SaomStructWeights(`obj`w'')
		if `tm' mata: `MA' = `MA'[selectindex(`ISA'), selectindex(1 :- `ISA')]
		else mata: _diag(`MA', 0)
		mata: st_numscalar("__nwsd_s0", sum(`MA' :== 10) / `div')
		mata: st_numscalar("__nwsd_s1", sum(`MA' :== 11) / `div')
		matrix `W'[`w', 4] = scalar(__nwsd_s0)
		matrix `W'[`w', 5] = scalar(__nwsd_s1)
		mata: `MA' = (`MA' :!= 0) :& (`MA' :!= 10)
		mata: st_numscalar("__nwsd_ties", sum(`MA') / `div')
		local ties = scalar(__nwsd_ties)
		matrix `W'[`w', 1] = `ties'
		if `tm' {
			matrix `W'[`w', 2] = `ties' / (`na' * `ne')
			matrix `W'[`w', 3] = `ties' / `na'
		}
		else {
			matrix `W'[`w', 2] = `ties' / (`n0' * (`n0' - 1) / `div')
			matrix `W'[`w', 3] = `ties' * `div' / `n0'
		}
	}
	forvalues w = 1/`=`nw'-1' {
		local w2 = `w' + 1
		mata: `MA' = SaomStructWeights(`obj`w'')
		mata: `MB' = SaomStructWeights(`obj`w2'')
		mata: `EX' = ((`MA' :== 10) :| (`MA' :== 11) :| (`MB' :== 10) :| (`MB' :== 11))
		mata: `MA' = (`MA' :!= 0) :& (`MA' :!= 10)
		mata: `MB' = (`MB' :!= 0) :& (`MB' :!= 10)
		if `tm' {
			mata: `EX' = `EX'[selectindex(`ISA'), selectindex(1 :- `ISA')]
			mata: `MA' = `MA'[selectindex(`ISA'), selectindex(1 :- `ISA')]
			mata: `MB' = `MB'[selectindex(`ISA'), selectindex(1 :- `ISA')]
		}
		else {
			mata: _diag(`MA', 0)
			mata: _diag(`MB', 0)
		}
		else mata: _diag(`EX', 0)
		mata: st_numscalar("__nwsd_k", sum(`MA' :& `MB') / `div')
		mata: st_numscalar("__nwsd_c", sum(!`MA' :& `MB') / `div')
		mata: st_numscalar("__nwsd_d", sum(`MA' :& !`MB') / `div')
		mata: st_numscalar("__nwsd_h", sum(((`MA' :& !`MB') :| (!`MA' :& `MB')) :& !`EX') / `div')
		local kept = scalar(__nwsd_k)
		local cre = scalar(__nwsd_c)
		local dis = scalar(__nwsd_d)
		matrix `P'[`w', 1] = `kept'
		matrix `P'[`w', 2] = `cre'
		matrix `P'[`w', 3] = `dis'
		matrix `P'[`w', 4] = cond(`kept' + `cre' + `dis' > 0, `kept' / (`kept' + `cre' + `dis'), .)
		matrix `P'[`w', 5] = scalar(__nwsd_h)
		matrix `P'[`w', 6] = cond(`kept' + `dis' > 0, `kept' / (`kept' + `dis'), .)
	}
	capture mata: mata drop `MA' `MB' `EX' `ISA'
	di
	if `tm' di as txt "Network data: " as res `nw' as txt " waves, two-mode network, " as res `na' as txt " actors (mode `actormode') x " as res `ne' as txt " events; ties are attendances (actor-event cells), density is over the " as res `na' * `ne' as txt " cells"
	else di as txt "Network data: " as res `nw' as txt " waves, " as res `n0' as txt " actors, " as res cond(`dir1', "directed", "undirected")
	di as txt "{hline 13}{c TT}{hline 39}"
	di as txt %12s "wave" " {c |}" %9s "ties" %12s "density" %14s "avg. degree"
	di as txt "{hline 13}{c +}{hline 39}"
	forvalues w = 1/`nw' {
		di as txt %12s "`w'" " {c |}" as res %9.0f `W'[`w', 1] %12.4f `W'[`w', 2] %14.3f `W'[`w', 3]
	}
	mata: st_numscalar("__nwsd_anys", sum(st_matrix("`W'")[., 4..5]) > 0)
	if scalar(__nwsd_anys) {
		di as txt "Structural values (codes 10 and 11), counted as ties when 11; the distance (Hamming) between two waves leaves out the dyads that are structural at either end, as RSiena (the kept/created/dissolved counts and the Jaccard index include them):"
		forvalues w = 1/`nw' {
			di as txt "  wave `w': " as res `W'[`w', 4] as txt " structural zeros, " as res `W'[`w', 5] as txt " structural ones"
		}
	}
	di as txt "{hline 13}{c BT}{hline 39}"
	di
	di as txt "{hline 13}{c TT}{hline 56}"
	di as txt %12s "period" " {c |}" %8s "kept" %10s "created" %11s "dissolved" %10s "Jaccard" %10s "Hamming"
	di as txt "{hline 13}{c +}{hline 56}"
	forvalues w = 1/`=`nw'-1' {
		di as txt %12s "`w'->`=`w'+1'" " {c |}" as res %8.0f `P'[`w', 1] %10.0f `P'[`w', 2] %11.0f `P'[`w', 3] %10.3f `P'[`w', 4] %10.0f `P'[`w', 5]
	}
	di as txt "{hline 13}{c BT}{hline 56}"
	forvalues w = 1/`=`nw'-1' {
		if `P'[`w', 4] < 0.3 di as txt "Note: Jaccard < 0.3 in period `w'->`=`w'+1'; few ties stay, the data say little about change."
	}
	matrix colnames `P' = kept created dissolved jaccard hamming persistence
	matrix colnames `W' = ties density avgdegree structural0 structural1
	return matrix periods = `P'
	return matrix waves = `W'
	return scalar twomode = `tm'
	if `tm' {
		return scalar n_actors = `na'
		return scalar n_events = `ne'
	}
	if "`behavior'" != "" {
		local nb : word count `behavior'
		if `nb' != `nw' {
			di as err "behavior() needs one variable per wave (`nw')."
			exit 198
		}
		tempname Bh
		matrix `Bh' = J(`nw', 3, .)
		di
		di as txt "{hline 13}{c TT}{hline 36}"
		di as txt %12s "behavior" " {c |}" %12s "mean" %12s "sd" %12s "missing"
		di as txt "{hline 13}{c +}{hline 36}"
		forvalues w = 1/`nw' {
			local v : word `w' of `behavior'
			qui count if missing(`v') in 1/`n0'
			local nmiss = r(N)
			qui summarize `v' in 1/`n0'
			matrix `Bh'[`w', 1] = r(mean)
			di as txt %12s "wave `w'" " {c |}" as res %12.3f r(mean) %12.3f r(sd) %12.0f `nmiss'
		}
		tempname Bc
		matrix `Bc' = J(`=`nw'-1', 3, .)
		di as txt "{hline 13}{c BT}{hline 36}"
		di
		di as txt "{hline 13}{c TT}{hline 36}"
		di as txt %12s "change" " {c |}" %12s "up" %12s "down" %12s "same"
		di as txt "{hline 13}{c +}{hline 36}"
		forvalues w = 1/`=`nw'-1' {
			local v1 : word `w' of `behavior'
			local v2 : word `=`w'+1' of `behavior'
			qui count if `v2' > `v1' & !missing(`v1', `v2') in 1/`n0'
			local up = r(N)
			qui count if `v2' < `v1' & !missing(`v1', `v2') in 1/`n0'
			local dn = r(N)
			qui count if `v2' == `v1' & !missing(`v1', `v2') in 1/`n0'
			local sm = r(N)
			matrix `Bc'[`w', 1] = `up'
			matrix `Bc'[`w', 2] = `dn'
			matrix `Bc'[`w', 3] = `sm'
			di as txt %12s "`w'->`=`w'+1'" " {c |}" as res %12.0f `up' %12.0f `dn' %12.0f `sm'
		}
		di as txt "{hline 13}{c BT}{hline 36}"
		matrix colnames `Bc' = up down same
		return matrix behchange = `Bc'
	}
	capture scalar drop __nwsd_ties __nwsd_k __nwsd_c __nwsd_d
end
