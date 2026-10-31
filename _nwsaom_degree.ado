*! version 1.4.1  31oct2026 _nwsaom_degree: spelling of the outdegree (density) effect: outdegree, degree or density (RSiena's names); the label follows the spelling typed
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
program define _nwsaom_degree, sclass
	version 17
	args degree density outdegree
	sreturn clear
	local lab "outdegree"
	if "`degree'`density'" != "" {
		if "`outdegree'" != "" | ("`degree'" != "" & "`density'" != "") {
			di as error "specify only one of outdegree, degree and density - they are the same effect"
			exit 198
		}
		local outdegree "outdegree"
		local lab = cond("`degree'" != "", "degree", "density")
	}
	sreturn local od "`outdegree'"
	sreturn local lab "`lab'"
end
