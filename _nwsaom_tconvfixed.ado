*! version 1.5.15  11nov2026 _nwsaom_tconvfixed
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/* Which columns of e(tconv) belong to fixed parameters: the effects held
   with fix() and those kept at their starting values because their phase-1
   derivative was not positive. Both have variance 0 in e(V). The coefficient
   columns come first in e(tconv), in the order of e(b). RSiena applies its
   convergence criteria to the estimated parameters only (phase3.r: the
   largest |t| and tconv.max over !z$fixed); the t-ratio of a fixed parameter
   is reported but not judged.
   Usage: _nwsaom_tconvfixed <localname> puts one 0/1 flag per column of
   e(tconv) into <localname> of the caller. */
capture program drop _nwsaom_tconvfixed
program define _nwsaom_tconvfixed
	args lname
	local flags ""
	tempname tc V
	capture matrix `tc' = e(tconv)
	if _rc {
		c_local `lname' ""
		exit
	}
	local kv 0
	capture matrix `V' = e(V)
	if !_rc local kv = colsof(`V')
	forvalues j = 1/`=colsof(`tc')' {
		local f 0
		if `j' <= `kv' {
			if `V'[`j',`j'] == 0 local f 1
		}
		local flags `flags' `f'
	}
	c_local `lname' `flags'
end
