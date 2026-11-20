*! version 1.8.1  18nov2026 _nwsaom_fnsuffix.ado -- file name with a suffix before the extension
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
// r(file): the file name with the suffix put before the extension (ext() is added when the name has none and ext() is given)
capture program drop _nwsaom_fnsuffix
program define _nwsaom_fnsuffix, rclass
	syntax anything(name=fn) [, SUFfix(string) EXT(string)]
	local fn = trim(`"`fn'"')
	if substr(`"`fn'"', 1, 1) == `"""' & substr(`"`fn'"', -1, 1) == `"""' local fn = substr(`"`fn'"', 2, strlen(`"`fn'"') - 2)
	local dot = strrpos(`"`fn'"', ".")
	local slash = max(strrpos(`"`fn'"', "/"), strrpos(`"`fn'"', "\\"))
	if `dot' > `slash' & `dot' > 0 {
		return local file `"`=substr(`"`fn'"', 1, `dot' - 1)'`suffix'`=substr(`"`fn'"', `dot', .)'"'
	}
	else return local file `"`fn'`suffix'`ext'"'
end
