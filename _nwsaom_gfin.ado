*! version 1.8.1  18nov2026 _nwsaom_gfin.ado -- saving() and export() of the plots
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
// saves each graph of the list to saving() and exports it with export(); with several graphs (or always) the name of the graph is put before the extension
capture program drop _nwsaom_gfin
program define _nwsaom_gfin
	syntax [anything(name=glist)] [, SAVing(string) EXPort(string asis) ALWAYS]
	if `"`saving'`export'"' == "" exit
	local ng : word count `glist'
	foreach g of local glist {
		if `"`saving'"' != "" {
			_nwsaom_fnsuffix `"`saving'"', suffix(`=cond(`ng' > 1 | "`always'" != "", "_`g'", "")') ext(.gph)
			quietly graph save `g' `"`r(file)'"', replace
		}
		if `"`export'"' != "" {
			gettoken __fn __ex : export, parse(",")
			local __ex = trim(substr(`"`__ex'"', 2, .))
			_nwsaom_fnsuffix `__fn', suffix(`=cond(`ng' > 1 | "`always'" != "", "_`g'", "")')
			quietly graph export `"`r(file)'"', name(`g') replace `__ex'
		}
	}
end

