*! version 1.3.3  28oct2026 _nwsaom_postengine (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/* e(engine): "native" or "mata", the simulator the fit used (set by the
   estimators through SaomSetEngine(), unw_saom.do); e(engine_why): why
   Mata. A model the plugin covers must never fall back silently. */
capture program drop _nwsaom_postengine
program define _nwsaom_postengine, eclass
	capture mata: st_local("__eng", __nwsaom_engine)
	if _rc local __eng ""
	capture mata: st_local("__why", __nwsaom_engine_why)
	if _rc local __why ""
	ereturn local engine "`__eng'"
	ereturn local engine_why "`__why'"
end
