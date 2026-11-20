*! version 1.9.0  20nov2026 _nwsaom_matlist (matlist of a table of rates with the row names in full)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
// matlist cuts a row name longer than its default title width of 12 (behavior_rate becomes behavior_r~e): the title
// width is widened to the longest row name; with names of up to 12 characters the output is the same as matlist's.
// Use: _nwsaom_matlist <matrix> [, options of matlist]
capture program drop _nwsaom_matlist
program _nwsaom_matlist
	version 14
	gettoken __m 0 : 0, parse(" ,")
	syntax [, *]
	tempname __M
	matrix `__M' = `__m'
	local __tw 12
	local __rn : rownames `__M'
	foreach __r of local __rn {
		local __tw = max(`__tw', ustrlen("`__r'"))
	}
	matlist `__M', `options' twidth(`__tw')
end
