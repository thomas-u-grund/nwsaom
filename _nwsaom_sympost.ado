*! version 1.7.1  13nov2026 _nwsaom_sympost (stored results of a non-directed fit with waves() or a behavior, split out because nwsaom.ado is at the size limit of one ado program)
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	_nwsaom_sympost, val(#) src(mata expression) [scalar]
	Posts what the simulation of a non-directed fit needs (estat gof, simulate, mems): e(symtype), e(modeltype) and the
	per-actor network rates, e(rates_actor) (1 x periods, columns as e(rates)) or, with scalar, e(rate_actor). For the
	pairwise types (joint, force, agree) e(rates)/e(rate) are on RSiena's scale and differ from the per-actor rates; for
	forcing and confirmation they are equal. Prints the model-type note under the table.
*/
capture program drop _nwsaom_sympost
program define _nwsaom_sympost, eclass
	syntax , VAL(integer) SRC(string) [SCALAR]
	local nm : word `val' of joint force agree forcing confirmation
	local mt : word `val' of 6 4 5 2 3
	tempname ra
	mata: st_matrix("`ra'", `src')
	ereturn local symtype "`nm'"
	ereturn scalar modeltype = `mt'
	if "`scalar'" != "" ereturn scalar rate_actor = `ra'[1,1]
	else {
		capture local cn : colnames e(rates)
		if !_rc & `: word count `cn'' == colsof(`ra') matrix colnames `ra' = `cn'
		matrix rownames `ra' = rate_actor
		ereturn matrix rates_actor = `ra'
	}
	di as text "(non-directed relation, model type " as result "`nm'" as text " = RSiena modelType " as result "`mt'" as text ")"
	if inlist(`val', 1, 2, 3) di as text "(pairwise model: per-actor rate(s) in " cond("`scalar'" != "", "e(rate_actor)", "e(rates_actor)") ")"
end
