*! version 1.6.0  13nov2026 nwcommands: checks of nwsaom options that run before the model of the last fit is replaced
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	Called by nwsaom before it replaces the Mata model of the last fit (the wave graphs, the effects): an option refused
	here leaves the last fit usable for estat. The same checks are repeated where the options are used.
*/
capture program drop _nwsaom_prevalid
program define _nwsaom_prevalid
	syntax , NODES(integer) CORES(integer) [PRESENT(string) MISSNET(string) GWAVES(string) GROUPS(string) HASTIMED(integer 0)]
	if `cores' < 0 {
		di "{err}option {bf:cores()} must be 0 (all physical cores) or a positive number of threads."
		exit 198
	}
	if "`gwaves'" != "" & "`groups'" == "" {
		di "{err}{bf:gwaves()} belongs to {bf:groups()}: give {bf:groups(varname)} as well."
		exit 198
	}
	if !`hastimed' foreach v of local present {
		confirm variable `v'
		capture assert inlist(`v', 0, 1)
		if _rc {
			di "{p 0 0 2}{err}option {bf:present()} variables must be coded 0/1 (0=absent, 1=present) - `v' has a value outside {0,1}.{p_end}"
			exit 198
		}
	}
	foreach m of local missnet {
		confirm matrix `m'
		if rowsof(`m') != `nodes' | colsof(`m') != `nodes' {
			di "{p 0 0 2}{err}option {bf:missnet()} matrices must be `nodes' x `nodes' (one row/column per actor) - `m' is not.{p_end}"
			exit 198
		}
		mata: st_local("ok", strofreal(all((st_matrix("`m'") :== 0) :| (st_matrix("`m'") :== 1))))
		if `ok' == 0 {
			di "{p 0 0 2}{err}option {bf:missnet()} matrices must be coded 0/1 (0=observed, 1=missing) - `m' has a value outside {0,1}.{p_end}"
			exit 198
		}
	}
end
