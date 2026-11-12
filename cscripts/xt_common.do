* xt_common.do - shared data generators and checks for the extended tests cscripts/xt_*.do.
* An INCLUDE, not a test: every xt_*.do runs "do cscripts/xt_common.do" after its setup lines. It defines Mata functions
* and Stata programs only (no data, no networks) and prints no PASS line.
* DRAFT, not yet run.

mata:
mata set matastrict off

// directed waves: n actors, W waves, start density d, per-wave flip probability f, Mata seed sd -> Stata matrices stem1..stemW
void xt_dir(string scalar stem, real scalar n, real scalar W, real scalar d, real scalar f, real scalar sd) {
	rseed(sd)
	A = (runiform(n, n) :< d)
	A = A - diag(diag(A))
	for (w=1; w<=W; w++) {
		st_matrix(stem + strofreal(w), A)
		F = (runiform(n, n) :< f)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}

// tie-symmetric waves (same arguments)
void xt_sym(string scalar stem, real scalar n, real scalar W, real scalar d, real scalar f, real scalar sd) {
	rseed(sd)
	A = (runiform(n, n) :< d)
	A = A - diag(diag(A))
	A = ((A + A') :> 0)
	for (w=1; w<=W; w++) {
		st_matrix(stem + strofreal(w), A)
		F = (runiform(n, n) :< f)
		F = ((F + F') :> 0)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}

// two-mode waves: na x ne affiliation matrices (rows = actors with the default actormode(2))
void xt_tm(string scalar stem, real scalar na, real scalar ne, real scalar W, real scalar d, real scalar f, real scalar sd) {
	rseed(sd)
	X = (runiform(na, ne) :< d)
	for (w=1; w<=W; w++) {
		st_matrix(stem + strofreal(w), X)
		F = (runiform(na, ne) :< f)
		X = abs(X - F)
	}
}

// block-diagonal waves of several groups (no ties between groups); sizes = group sizes; sym = 1 for tie-symmetric waves
void xt_grp(string scalar stem, real rowvector sizes, real scalar W, real scalar d, real scalar f, real scalar sd, real scalar sym) {
	rseed(sd)
	n = sum(sizes)
	B = J(n, n, 0)
	o = 0
	for (g=1; g<=cols(sizes); g++) {
		B[(o+1)::(o+sizes[g]), (o+1)::(o+sizes[g])] = J(sizes[g], sizes[g], 1)
		o = o + sizes[g]
	}
	B = B - diag(diag(B))
	A = (runiform(n, n) :< d) :* B
	if (sym) A = ((A + A') :> 0)
	for (w=1; w<=W; w++) {
		st_matrix(stem + strofreal(w), A)
		F = (runiform(n, n) :< f) :* B
		if (sym) F = ((F + F') :> 0)
		A = abs(A - F)
	}
}

// rows and columns of the matrices src1..srcW permuted by p (new node k = old node p[k]) -> dst1..dstW
void xt_perm(string scalar src, string scalar dst, real scalar W, real colvector p) {
	for (w=1; w<=W; w++) {
		A = st_matrix(src + strofreal(w))
		st_matrix(dst + strofreal(w), A[p, p])
	}
}

// integer behavior waves: n actors, W waves, values 1..K, a few changes per wave -> variables stem1..stemW (must exist)
void xt_beh(string scalar stem, real scalar n, real scalar W, real scalar K, real scalar sd) {
	rseed(sd)
	z = ceil(runiform(n, 1) * K)
	for (w=1; w<=W; w++) {
		st_store(., stem + strofreal(w), z)
		up = (runiform(n, 1) :< 0.15)
		dn = (runiform(n, 1) :< 0.10)
		z = z + up - dn
		z = rowmax((z, J(n, 1, 1)))
		z = rowmin((z, J(n, 1, K)))
	}
}
end

* xt_netinfo netname: r(nodes), r(directed), r(is2mode), r(asym) (asymmetric cells of the nwtomata matrix; -1 if not square),
* r(ties) (sum of the matrix: an undirected tie counts twice), r(rows), r(nmode2) (two-mode only: nodes of mode "2")
capture program drop xt_netinfo
program define xt_netinfo, rclass
	args netname
	_nwsyntax `netname', max(1)
	return local directed "`directed'"
	return local is2mode "`is2mode'"
	return scalar nodes = `nodes'
	capture mata: mata drop __xtm
	nwtomata `netname', mat(__xtm)
	mata: st_numscalar("__xt_asym", (rows(__xtm) == cols(__xtm)) ? sum(__xtm :!= __xtm') : -1)
	mata: st_numscalar("__xt_sum", sum(__xtm))
	mata: st_numscalar("__xt_rows", rows(__xtm))
	return scalar asym = scalar(__xt_asym)
	return scalar ties = scalar(__xt_sum)
	return scalar rows = scalar(__xt_rows)
	if "`is2mode'" == "true" {
		mata: st_numscalar("__xt_nm2", sum(`netobj'->get_modes() :== "2"))
		return scalar nmode2 = scalar(__xt_nm2)
	}
	capture scalar drop __xt_asym __xt_sum __xt_rows __xt_nm2
end

* xt_masked netname mask val: r(bad) = number of cells with mask == 1 whose tie indicator (cell != 0) is not val (0 or 1)
capture program drop xt_masked
program define xt_masked, rclass
	args netname mask val
	capture mata: mata drop __xtm
	nwtomata `netname', mat(__xtm)
	mata: st_numscalar("__xt_bad", sum((st_matrix("`mask'") :!= 0) :& ((__xtm :!= 0) :!= `val')))
	return scalar bad = scalar(__xt_bad)
	scalar drop __xt_bad
end

* xt_esnap / xt_esame: snapshot of the estimation results, and the assertion that they did not change
capture program drop xt_esnap
program define xt_esnap
	matrix __XT_B = e(b)
	matrix __XT_V = e(V)
	global XT_ECMD `"`e(cmd)'"'
	global XT_ECMDLINE `"`e(cmdline)'"'
	global XT_EWAVES `"`e(waves)'"'
end
capture program drop xt_esame
program define xt_esame
	assert `"`e(cmd)'"' == `"$XT_ECMD"'
	assert `"`e(cmdline)'"' == `"$XT_ECMDLINE"'
	assert `"`e(waves)'"' == `"$XT_EWAVES"'
	tempname b V
	matrix `b' = e(b)
	matrix `V' = e(V)
	assert mreldif(`b', __XT_B) == 0
	assert mreldif(`V', __XT_V) == 0
end

* xt_dsnap / xt_dsame: snapshot of the data (datasignature, observations, variables) and of the networks (number, current)
capture program drop xt_dsnap
program define xt_dsnap
	quietly datasignature
	global XT_DSIG "`r(datasignature)'"
	global XT_DN = c(N)
	global XT_DK = c(k)
	quietly nwcurrent
	global XT_NNET = r(networks)
	global XT_CURNET "`r(current)'"
end
capture program drop xt_dsame
program define xt_dsame
	quietly datasignature
	assert "`r(datasignature)'" == "$XT_DSIG"
	assert c(N) == $XT_DN & c(k) == $XT_DK
	quietly nwcurrent
	assert r(networks) == $XT_NNET
	assert "`r(current)'" == "$XT_CURNET"
end

* xt_rclist: the rate list of the fit in memory with full precision (e(rates) or e(rate)), in r(list)
capture program drop xt_rclist
program define xt_rclist, rclass
	local rl ""
	capture confirm matrix e(rates)
	if _rc == 0 {
		forvalues j = 1/`=colsof(e(rates))' {
			local rl "`rl' `=strofreal(el(e(rates), 1, `j'), "%21.0g")'"
		}
	}
	else local rl = strofreal(e(rate), "%21.0g")
	return local list "`rl'"
	local bl ""
	capture confirm matrix e(rates_beh)
	if _rc == 0 {
		forvalues j = 1/`=colsof(e(rates_beh))' {
			local bl "`bl' `=strofreal(el(e(rates_beh), 1, `j'), "%21.0g")'"
		}
	}
	else if e(rate_beh) < . local bl = strofreal(e(rate_beh), "%21.0g")
	return local behlist "`bl'"
end

* xt_samerates: rates() given as the fit's own rates (and ratesbeh() as its behavior rates) must give the same simulations as
* no rates() (same seed): rates() is on the scale of e(rates)/e(rate) for every model type
capture program drop xt_samerates
program define xt_samerates
	tempname A B
	quietly estat simulate, nsim(4) seed(11)
	matrix `A' = r(sim)
	xt_rclist
	local rl "`r(list)'"
	local bl "`r(behlist)'"
	if "`bl'" != "" quietly estat simulate, nsim(4) seed(11) rates(`rl') ratesbeh(`bl')
	else quietly estat simulate, nsim(4) seed(11) rates(`rl')
	matrix `B' = r(sim)
	assert mreldif(`A', `B') == 0
end

* xt_simcheck stub nsim nper, nodes(#) [undirected twomode nactors(#)]: every generated network stub_s_pP exists, has the
* fit's size and type; undirected networks are symmetric; two-mode networks stay two-mode with the actors in rows (mode 2)
capture program drop xt_simcheck
program define xt_simcheck
	syntax anything, NODES(integer) [UNDIRECTED TWOMODE NACTORS(integer 0)]
	tokenize `anything'
	local stub `1'
	local ns `2'
	local np `3'
	forvalues s = 1/`ns' {
		forvalues p = 1/`np' {
			xt_netinfo `stub'_`s'_p`p'
			assert r(nodes) == `nodes'
			if "`twomode'" != "" {
				assert "`r(is2mode)'" == "true"
				if `nactors' > 0 assert r(nmode2) == `nactors'
			}
			else {
				assert "`r(is2mode)'" != "true"
				if "`undirected'" != "" assert "`r(directed)'" == "false" & r(asym) == 0
				else assert "`r(directed)'" == "true"
			}
		}
	}
end

* xt_rowcol netname k: r(deg) = number of ties in row k plus column k of the nwtomata matrix, the diagonal left out (nwtomata
* returns a missing diagonal) (0 = actor k is isolated)
capture program drop xt_rowcol
program define xt_rowcol, rclass
	args netname k
	capture mata: mata drop __xtm
	nwtomata `netname', mat(__xtm)
	mata: _diag(__xtm, 0)
	mata: st_numscalar("__xt_d", sum(__xtm[`k', .] :!= 0) + sum(__xtm[., `k'] :!= 0))
	return scalar deg = scalar(__xt_d)
	scalar drop __xt_d
end

* xt_outdeg netname k: r(deg) = number of ties sent by actor k (row k, diagonal left out). An actor that is not active in a
* period does not act, so it sends no tie; active actors may still create ties TO it (RSiena: an inactive actor stays among
* the alters of an active ego in directed and unilateral models), so its in-ties are not checked
capture program drop xt_outdeg
program define xt_outdeg, rclass
	args netname k
	capture mata: mata drop __xtm
	nwtomata `netname', mat(__xtm)
	mata: _diag(__xtm, 0)
	mata: st_numscalar("__xt_d", sum(__xtm[`k', .] :!= 0))
	return scalar deg = scalar(__xt_d)
	scalar drop __xt_d
end

* xt_mties netname: macro() program for estat mems - the sum of the network's matrix (r(stat)); also counts the calls and the
* asymmetric matrices it was handed in $XT_MCALLS and $XT_MASYM
capture program drop xt_mties
program define xt_mties, rclass
	args netname
	capture mata: mata drop __xtmm
	nwtomata `netname', mat(__xtmm)
	mata: st_numscalar("__xt_mt", sum(__xtmm))
	mata: st_numscalar("__xt_ma", (rows(__xtmm) == cols(__xtmm)) ? sum(__xtmm :!= __xtmm') : 0)
	global XT_MCALLS = 0$XT_MCALLS + 1
	global XT_MASYM = 0$XT_MASYM + scalar(__xt_ma)
	return scalar stat = scalar(__xt_mt)
	scalar drop __xt_mt __xt_ma
end

* xt_pcheck: every r(p_*) of estat gof that is named in the list lies in [0, 1] and has its r(mhd_*)
capture program drop xt_pcheck
program define xt_pcheck
	foreach s of local 0 {
		assert r(p_`s') >= 0 & r(p_`s') <= 1
		assert r(mhd_`s') < .
	}
end

di as text "xt_common loaded"
