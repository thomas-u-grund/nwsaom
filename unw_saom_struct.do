/*
 * Copyright (C) 2026 Thomas U. Grund
 * This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
 * nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
 * Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
 */
/*
	unw_saom_struct.do -- structural zeros and ones (RSiena's codes 10 and 11 in the wave networks).

	Included at the end of unw_saom.do (so the library build and the do-file development route see it).  Loaded AFTER the classes and
	structs of unw_saom.do.

	Representation.  The raw structural set is ONE real matrix, the Mata external __nwsaom_sset, with one row per structural dyad of
	one wave: (wave, i, j, v), v = 0 for code 10 (structural zero), 1 for code 11 (structural one), sorted by (wave, i, j).  The wave
	graphs carry the value (a structural one is a tie, a structural zero is no tie), as RSiena (the tie list of a wave holds the
	structural ones, the structural list holds all of them).  From the sets S_w of the waves the periods p = 1..W-1 derive
	  A_p = S_p                       dyads fixed during period p (they keep their start value, they are not among an actor's alternatives)
	  B_p = S_{p+1} minus S_p         dyads free during period p whose value is replaced by the end value before the statistics
	  target graph T_p = x_{p+1} with the A_p dyads set to their start value   (RSiena: replaceNetwork(x_{p+1}, S_p))
	  rate graph    R_p = x_p with the B_p dyads set to their end value
	  the observed distance counts the differences R_p / T_p, i.e. it excludes S_p, S_{p+1} and the missing dyads (sienaDataCreate).
	The simulated distance of the conditional estimation is NOT restricted (RSiena's NetworkVariable::makeChange() counts every change of a
	dyad that is not missing); the plugin does exactly that.
*/
mata:
mata set matastrict on

/* ---- the external store ---- */
void SaomStructReset() {
	rmexternal("__nwsaom_sset")
	rmexternal("__nwsaom_sset_on")
}

real matrix SaomStructRaw() {
	pointer(real matrix) scalar p
	p = findexternal("__nwsaom_sset")
	if (p == NULL) return(J(0, 4, 0))
	return(*p)
}

void SaomStructSetRaw(real matrix X) {
	pointer(real matrix) scalar p
	p = findexternal("__nwsaom_sset")
	if (p == NULL) p = crexternal("__nwsaom_sset")
	*p = X
}

/* 1 while the structural sets of the running fit are built (set by SaomStructBuild(), removed by SaomStructReset()) */
real scalar SaomStructOn() {
	pointer(real scalar) scalar p
	p = findexternal("__nwsaom_sset_on")
	if (p == NULL) return(0)
	return(*p)
}

/* the sets survive the end of the fit for the postestimation commands (SaomRatesReset() removes the working copy) */
void SaomStructKeepLast() {
	pointer(real matrix) scalar p, q
	p = findexternal("__nwsaom_sset")
	rmexternal("__nwsaom_last_sset")
	if (p == NULL) return
	q = crexternal("__nwsaom_last_sset")
	*q = *p
}
/* put the sets of the last fit back as the working sets (tests that rebuild a fit context by hand) */
void SaomStructRestoreLast() {
	pointer(real matrix) scalar q
	pointer(real scalar) scalar p
	q = findexternal("__nwsaom_last_sset")
	if (q == NULL) return
	SaomStructSetRaw(*q)
	p = findexternal("__nwsaom_sset_on")
	if (p == NULL) p = crexternal("__nwsaom_sset_on")
	*p = 1
}
real scalar SaomStructLastOn() {
	pointer(real matrix) scalar q
	q = findexternal("__nwsaom_last_sset")
	if (q == NULL) return(0)
	return(rows(*q) > 0)
}

/* selectindex() as a column; selectindex() of a 1 x 1 argument is a 1 x 0 or 1 x 1 ROW vector */
real colvector SaomStructSel(real matrix x) {
	real matrix r
	r = selectindex(x)
	if (cols(r) != 1) r = r'
	return(r)
}

/* ---- the check in _nwsaom_chkbin: are all tie values of the network in {1, 10, 11}?  (0 is no tie.)  Returns 1 if the values are allowed.
   On failure the locals __cb_badv, __cb_badi, __cb_badj of the calling program hold the first offending value and its dyad; the local
   __cb_nstr the number of arcs with a value other than 1 (codes 10 and 11 and explicit zeros) ---- */
real scalar SaomStructCheck(pointer(class nw_def scalar) scalar netobj) {
	real scalar n, i, nstr, k
	real colvector nb, wc
	real colvector bad

	n = netobj->get_nodes()
	nstr = 0
	for (i=1; i<=n; i++) {
		nb = netobj->neighbors(i)
		if (rows(nb) == 0) continue
		wc = netobj->edge_weight_row(i)'
		nstr = nstr + sum(wc :!= 1)
		bad = ((wc :!= 0) :& (wc :!= 1) :& (wc :!= 10) :& (wc :!= 11)) :& (nb :!= i)
		if (any(bad)) {
			k = SaomStructSel(bad)
			k = k[1]
			st_local("__cb_badv", strofreal(wc[k], "%12.0g"))
			st_local("__cb_badi", strofreal(i))
			st_local("__cb_badj", strofreal(nb[k]))
			return(0)
		}
	}
	st_local("__cb_nstr", strofreal(nstr))
	return(1)
}

/* ---- the wave graph after the bridge: the bridge made every stored arc a tie; remove the ties of the arcs with value 0 or 10 and
   record the dyads with value 10 / 11 as structural.  tm = 1: two-mode (the actors are the rows isactor == 1, the arcs actor -> event) ---- */
real scalar SaomStructFix(pointer(class nw_def scalar) scalar netobj, class SaomGraph scalar G, real scalar wave, real scalar tm,
	real rowvector isactor) {
	real scalar n, i, cnt, cap, m
	real colvector nb, sel, ia, wc
	real matrix buf, add

	n = G.n
	ia = (tm ? isactor' : J(n, 1, 0))
	cap = 1024
	buf = J(cap, 4, 0)
	cnt = 0
	for (i=1; i<=n; i++) {
		if (tm) if (!isactor[i]) continue
		nb = netobj->neighbors(i)
		if (rows(nb) == 0) continue
		wc = netobj->edge_weight_row(i)'
		// arcs with the value 0 or 10 are no ties
		sel = SaomStructSel(((wc :== 0) :| (wc :== 10)) :& (nb :!= i))
		for (m=1; m<=rows(sel); m++) if (G.has_edge(i, nb[sel[m]])) G.toggle(i, nb[sel[m]])
		// the structural dyads
		sel = SaomStructSel(((wc :== 10) :| (wc :== 11)) :& (nb :!= i))
		if (tm) sel = select(sel, !ia[nb[sel]])
		if (rows(sel) == 0) continue
		add = (J(rows(sel), 1, wave), J(rows(sel), 1, i), nb[sel], wc[sel] :- 10)
		if (cnt + rows(add) > cap) {
			cap = max((2 * cap, cnt + rows(add)))
			buf = buf[1::cnt, .] \ J(cap - cnt, 4, 0)
		}
		buf[(cnt+1)::(cnt+rows(add)), .] = add
		cnt = cnt + rows(add)
	}
	if (cnt > 0) SaomStructSetRaw(SaomStructRaw() \ buf[1::cnt, .])
	return(cnt)
}

/* ---- membership: for each key in kq (unique) whether it is in kset (unique); both real colvectors ---- */
real colvector SaomStructInSet(real colvector kq, real colvector kset) {
	real colvector K, src, ss, Ks, res, dup
	real scalar N, nq
	real colvector p

	nq = rows(kq)
	if (nq == 0) return(J(0, 1, 0))
	if (rows(kset) == 0) return(J(nq, 1, 0))
	K = kq \ kset
	src = J(nq, 1, 1) \ J(rows(kset), 1, 0)
	N = rows(K)
	p = order((K, src), (1, 2))
	Ks = K[p]
	ss = src[p]
	dup = J(N, 1, 0)
	if (N > 1) dup[2::N] = (Ks[2::N] :== Ks[1::(N-1)]) :& (ss[2::N] :== 1) :& (ss[1::(N-1)] :== 0)
	res = J(N, 1, 0)
	res[p] = dup
	return(res[1::nq])
}

real colvector SaomStructKeys(real matrix X, real scalar n) {
	return((X[., 1] :- 1) * n :+ X[., 2])
}

/* the rows (i, j, v) of wave w of the raw store */
real matrix SaomStructWave(real matrix raw, real scalar w) {
	if (rows(raw) == 0) return(J(0, 3, 0))
	return(select(raw[., 2..4], raw[., 1] :== w))
}

/* ---- missing data: a dyad that is missing at wave w takes the code (and the value) of wave w-1 (RSiena: networks[[w]][netmiss] <- networks[[w-1]][netmiss]);
   the own code of a missing dyad is dropped.  Called for w = 2..W in this order, with the missnet() mask of the wave (n x n, 1 = missing) ---- */
void SaomStructCarry(real scalar w, real matrix mask, real scalar n) {
	real matrix raw, cur, prev, keep, mi
	real colvector kq, in, kp
	real scalar k

	raw = SaomStructRaw()
	if (rows(raw) == 0) return
	cur = SaomStructWave(raw, w)
	prev = SaomStructWave(raw, w - 1)
	// the dyads missing at wave w (off-diagonal)
	mi = J(0, 2, 0)
	if (any(mask :!= 0)) {
		mi = SaomMaskToDyadList(mask)
	}
	if (rows(mi) == 0) return
	// own rows of wave w at missing dyads are dropped
	if (rows(cur) > 0) {
		in = SaomStructInSet(SaomStructKeys(cur, n), SaomStructKeys(mi, n))
		cur = select(cur, !in)
	}
	// the structural dyads of wave w-1 that are missing at wave w are carried
	if (rows(prev) > 0) {
		kp = SaomStructKeys(prev, n)
		in = SaomStructInSet(kp, SaomStructKeys(mi, n))
		if (any(in)) cur = cur \ select(prev, in)
	}
	keep = select(raw, raw[., 1] :!= w)
	if (rows(cur) > 0) keep = keep \ (J(rows(cur), 1, w), cur)
	if (rows(keep) > 0) keep = keep[order(keep, (1, 2, 3)), .]
	SaomStructSetRaw(keep)
}

/* non-directed relation: the codes must be given for both directions with the same value (RSiena: otherwise the network is directed).  Returns the first offending wave, 0 if fine */
real scalar SaomStructSymCheck(real scalar W, real scalar n) {
	real matrix raw, S, Sr
	real colvector in, k1, k2
	real scalar w
	raw = SaomStructRaw()
	for (w=1; w<=W; w++) {
		S = SaomStructWave(raw, w)
		if (rows(S) == 0) continue
		Sr = (S[., 2], S[., 1], S[., 3])
		k1 = SaomStructKeys(S, n)
		k2 = SaomStructKeys(Sr, n)
		if (any(SaomStructInSet(k2, k1) :== 0)) return(w)
		// the same value: sort both by key and compare
		if (any(S[order(k1, 1), 3] :!= Sr[order(k2, 1), 3])) return(w)
	}
	return(0)
}

/* ---- finish: sort, check, switch on ---- */
void SaomStructBuild(real scalar W, real scalar n) {
	real matrix raw
	pointer(real scalar) scalar p

	raw = SaomStructRaw()
	if (rows(raw) > 0) {
		raw = raw[order(raw, (1, 2, 3)), .]
		SaomStructSetRaw(raw)
	}
	p = findexternal("__nwsaom_sset_on")
	if (p == NULL) p = crexternal("__nwsaom_sset_on")
	*p = 1
}

/* the number of structural zeros and ones per wave: W x 2 */
real matrix SaomStructCounts(real scalar W) {
	real matrix raw, out
	real scalar w
	raw = SaomStructRaw()
	out = J(W, 2, 0)
	for (w=1; w<=W; w++) {
		if (rows(raw) == 0) continue
		out[w, 1] = sum(raw[., 1] :== w :& raw[., 4] :== 0)
		out[w, 2] = sum(raw[., 1] :== w :& raw[., 4] :== 1)
	}
	return(out)
}

/* ---- the derived sets of period pd (1 .. W-1): A = S_pd (i, j, v); B = the dyads of S_{pd+1} that are not in S_pd (i, j, v) ---- */
void SaomStructPeriod(real matrix raw, real scalar pd, real scalar n, real matrix A, real matrix B) {
	real matrix Sn
	real colvector in
	A = SaomStructWave(raw, pd)
	Sn = SaomStructWave(raw, pd + 1)
	if (rows(Sn) == 0) B = J(0, 3, 0)
	else if (rows(A) == 0) B = Sn
	else {
		in = SaomStructInSet(SaomStructKeys(Sn, n), SaomStructKeys(A, n))
		B = select(Sn, !in)
	}
}

/* a copy of G with the dyads (i, j, v) of X set to v (v = 1: tie, 0: no tie) */
class SaomGraph scalar SaomStructPatched(class SaomGraph scalar G, real matrix X) {
	class SaomGraph scalar Gp
	real scalar k
	Gp = SaomGraph()
	SaomCopyGraph(G, Gp)
	for (k=1; k<=rows(X); k++) {
		if (Gp.has_edge(X[k,1], X[k,2]) != X[k,3]) Gp.toggle(X[k,1], X[k,2])
	}
	return(Gp)
}

/* the missing-data mask of a period with the structural dyads cleared (RSiena: the structural value is put back after the missing ties were removed) */
real matrix SaomStructClearMask(real matrix mask, real matrix A, real matrix B) {
	real matrix m
	real scalar k
	m = mask
	for (k=1; k<=rows(A); k++) m[A[k,1], A[k,2]] = 0
	for (k=1; k<=rows(B); k++) m[B[k,1], B[k,2]] = 0
	return(m)
}

/* ---- the targets of a fit with structural dyads: called by SaomNetCtxInit() after the ordinary targets were computed ---- */
void SaomStructTargets(struct SaomNetCtx scalar C, class SaomModel scalar M, pointer(class SaomGraph scalar) rowvector Gwaves,
	real rowvector fntype, pointer(real matrix) rowvector missMaskPd) {
	real matrix raw, A, B, mk, mkfull
	real scalar pd, n
	class SaomGraph scalar Tg, Gs

	if (!SaomStructOn()) return
	raw = SaomStructRaw()
	n = C.n
	for (pd=1; pd<=C.P; pd++) {
		SaomStructPeriod(raw, pd, n, A, B)
		if (rows(A) == 0 & rows(B) == 0) continue
		if (C.hastv) SaomTVSync(M, pd)
		SaomGroupsSync(M, pd)
		Tg = SaomStructPatched(*Gwaves[pd+1], A)
		Gs = SaomStructPatched(*Gwaves[pd], B)
		if (C.hasmiss) {
			mkfull = *missMaskPd[pd]
			mk = SaomStructClearMask(mkfull, A, B)
			C.target[pd,.] = SaomMaskedStatistic(Tg, M, mk)
			C.targetRate[pd] = SaomCountDifferingMasked(Gs, Tg, mkfull)
		}
		else {
			mkfull = J(0, 0, 0)
			C.target[pd,.] = M.full_statistic(Tg)
			C.targetRate[pd] = SaomCountDiffering(Gs, Tg)
		}
		if (C.hasnetgate) C.target[pd,.] = SaomNetworkPatchEndowCreation(M, fntype, C.target[pd,.], *Gwaves[pd], Tg, (C.hasmiss ? mkfull : J(0, 0, 0)))
		if (C.hasratecov) C.targetRateCov[pd,.] = SaomCovariateDifferingSum(Gs, Tg, SaomRCPd(C.ratecovattr, pd), (C.hasmiss ? mkfull : J(0, 0, 0)))
		if (cols(SaomSRTypes()) > 0) C.targetRateCov[pd, (C.hasratecov - cols(SaomSRTypes()) + 1)..C.hasratecov] = SaomCovariateDifferingSum(Gs, Tg, SaomStructRateAttr(*Gwaves[pd], SaomSRTypes()), J(0, 0, 0))
	}
	// NWSAOM_TRACE 5: the targets and the observed distances of the periods as Stata matrices (for the tests)
	if (strtoreal(st_global("NWSAOM_TRACE")) == 5) {
		st_matrix("__nwsaom_tr_target", C.target)
		st_matrix("__nwsaom_tr_rate", C.targetRate)
	}
}

/* ---- co-evolution with one behavior: the network part of the targets and the observed network distance of period pd (called inside the per-period loop of
   SaomEstimateRMCoevMulti(), after the ordinary values were computed) ---- */
void SaomStructCoevPd(struct SaomCoevCtx scalar C, class SaomModel scalar M, real scalar pd, real rowvector fntype) {
	real matrix raw, A, B, mk, mkfull
	class SaomGraph scalar Tg, Gs

	raw = SaomStructRaw()
	SaomStructPeriod(raw, pd, C.n, A, B)
	if (rows(A) == 0 & rows(B) == 0) return
	Tg = SaomStructPatched(*C.Gwaves[pd+1], A)
	Gs = SaomStructPatched(*C.Gwaves[pd], B)
	if (C.hasmiss) {
		mkfull = *C.missMaskNetPd[pd]
		mk = SaomStructClearMask(mkfull, A, B)
		C.target[pd, 1..C.pNet] = SaomMaskedStatistic(Tg, M, mk)
		C.targetRateNet[pd] = SaomCountDifferingMasked(Gs, Tg, mkfull)
	}
	else {
		mkfull = J(0, 0, 0)
		C.target[pd, 1..C.pNet] = M.full_statistic(Tg)
		C.targetRateNet[pd] = SaomCountDiffering(Gs, Tg)
	}
	if (C.hasnetgate) C.target[pd, 1..C.pNet] = SaomNetworkPatchEndowCreation(M, fntype, C.target[pd, 1..C.pNet], *C.Gwaves[pd], Tg, mkfull)
	if (strtoreal(st_global("NWSAOM_TRACE")) == 5) {
		st_matrix("__nwsaom_tr_target", C.target)
		st_matrix("__nwsaom_tr_rate", C.targetRateNet)
	}
}

/* the plugin needs the batch path for the sets; version and path checks of a context that sends them */
void SaomStructNeedBatch(real scalar use_batch) {
	if (!SaomStructOn()) return
	if (!use_batch | SaomNativePluginVersion() < 150) {
		errprintf("nwsaom: structural zeros and ones (the codes 10 and 11) need the native plugin of this release (update nwsaom: net install ... replace); there is no Mata implementation.\n")
		exit(198)
	}
}

/* ---- the rows for the plugin: (pd, i, j, kind).  kind 1: dyad fixed during the period (pd = 0: in every period), 2 / 3: end value zero / one.
   Dyads fixed in every period are sent once (pd = 0) ---- */
real matrix SaomStructRows(real scalar P, real scalar n) {
	real matrix raw, A, B, rows_, common, ex
	real colvector in
	real scalar pd
	pointer(real matrix) rowvector As

	raw = SaomStructRaw()
	As = J(1, P, NULL)
	for (pd=1; pd<=P; pd++) {
		SaomStructPeriod(raw, pd, n, A, B)
		As[pd] = &(A :+ 0)
	}
	common = *As[1]
	for (pd=2; pd<=P; pd++) {
		if (rows(common) == 0) break
		in = SaomStructInSet(SaomStructKeys(common, n), SaomStructKeys(*As[pd], n))
		common = select(common, in)
	}
	rows_ = J(0, 4, 0)
	if (rows(common) > 0) rows_ = (J(rows(common), 1, 0), common[., 1..2], J(rows(common), 1, 1))
	for (pd=1; pd<=P; pd++) {
		A = *As[pd]
		if (rows(A) > 0 & rows(common) > 0) {
			in = SaomStructInSet(SaomStructKeys(A, n), SaomStructKeys(common, n))
			ex = select(A, !in)
		}
		else ex = A
		if (rows(ex) > 0) rows_ = rows_ \ (J(rows(ex), 1, pd), ex[., 1..2], J(rows(ex), 1, 1))
		SaomStructPeriod(raw, pd, n, A, B)
		if (rows(B) > 0) rows_ = rows_ \ (J(rows(B), 1, pd), B[., 1..2], 2 :+ B[., 3])
	}
	return(rows_)
}

/* ---- send the sets to the plugin (after BATCHSETUP); the plugin attaches them to the resident batch data ---- */
void SaomStructSend(real scalar P, real scalar n) {
	real matrix X
	string scalar origframe, argstr
	real scalar junk
	string rowvector names

	X = SaomStructRows(P, n)
	names = ("s_pd", "s_i", "s_j", "s_k")
	origframe = st_framecurrent()
	stata("capture frame drop __saom_struct")
	stata("frame create __saom_struct")
	st_framecurrent("__saom_struct")
	st_addobs(max((rows(X), 1)))
	junk = st_addvar("double", names)
	if (rows(X) > 0) st_store((1::rows(X)), names, X)
	argstr = "STRUCTSET|" + strofreal(n) + " " + strofreal(P) + " " + strofreal(rows(X))
	stata("plugin call saomnativesim " + invtokens(names) + ", " + char(34) + argstr + char(34))
	st_framecurrent(origframe)
	stata("capture frame drop __saom_struct")
}

/* ---- postestimation (single-call simulations): the period the next simulation belongs to ---- */
void SaomStructPeriodSet(real scalar pd) {
	pointer(real scalar) scalar p
	p = findexternal("__nwsaom_sf_pd")
	if (p == NULL) p = crexternal("__nwsaom_sf_pd")
	*p = pd
}
real scalar SaomStructPeriodGet() {
	pointer(real scalar) scalar p
	p = findexternal("__nwsaom_sf_pd")
	if (p == NULL) return(0)
	return(*p)
}

/* the observed end network of period pd with the dyads that were structural at the start set to their start value (RSiena: sparseMatrixExtraction()), dense */
real matrix SaomStructObsDense(class SaomGraph scalar Gend, real scalar pd) {
	real matrix raw, A, B
	class SaomGraph scalar Tg
	if (!SaomStructOn()) return(Gend.to_dense())
	raw = SaomStructRaw()
	SaomStructPeriod(raw, pd, Gend.n, A, B)
	Tg = SaomStructPatched(Gend, A)
	return(Tg.to_dense())
}

/* install the sets of period pd for the NEXT single-call simulation of the plugin (STRUCTSET1|) */
void SaomStructSend1(real scalar n) {
	real matrix raw, A, B, X
	real scalar pd, junk
	string scalar origframe
	string rowvector names

	if (!SaomStructOn()) return
	pd = SaomStructPeriodGet()
	if (pd < 1) return
	if (SaomNativePluginVersion() < 150) {
		errprintf("nwsaom: structural zeros and ones need the native plugin of this release (update nwsaom: net install ... replace).\n")
		exit(198)
	}
	raw = SaomStructRaw()
	SaomStructPeriod(raw, pd, n, A, B)
	X = J(0, 4, 0)
	if (rows(A) > 0) X = (J(rows(A), 1, pd), A[., 1..2], J(rows(A), 1, 1))
	if (rows(B) > 0) X = X \ (J(rows(B), 1, pd), B[., 1..2], 2 :+ B[., 3])
	names = ("s_pd", "s_i", "s_j", "s_k")
	origframe = st_framecurrent()
	stata("capture frame drop __saom_struct")
	stata("frame create __saom_struct")
	st_framecurrent("__saom_struct")
	st_addobs(max((rows(X), 1)))
	junk = st_addvar("double", names)
	if (rows(X) > 0) st_store((1::rows(X)), names, X)
	stata("capture program saomnativesim, plugin using(" + char(34) + SaomNativePluginPath() + char(34) + ")")
	stata("plugin call saomnativesim " + invtokens(names) + ", " + char(34) + "STRUCTSET1|" + strofreal(n) + " " + strofreal(rows(X)) + char(34))
	st_framecurrent(origframe)
	stata("capture frame drop __saom_struct")
}

/* estat importance: the choices that are available in period pd (1 = available): the dyads that are structural at the start are excluded (RSiena: NA) */
real matrix SaomStructAvail(real scalar pd, real scalar n, real matrix mk0) {
	real matrix raw, A, B, m
	real scalar k
	m = (rows(mk0) > 0 ? mk0 : J(n, n, 1))
	raw = SaomStructRaw()
	SaomStructPeriod(raw, pd, n, A, B)
	for (k=1; k<=rows(A); k++) m[A[k,1], A[k,2]] = 0
	return(m)
}

/* the n x n matrix of tie values of a network (0 = no tie); used by nwsaom describe, which must see the codes 10 and 11 */
real matrix SaomStructWeights(pointer(class nw_def scalar) scalar netobj) {
	real scalar n, i
	real matrix W
	real colvector nb
	n = netobj->get_nodes()
	W = J(n, n, 0)
	for (i=1; i<=n; i++) {
		nb = netobj->neighbors(i)
		if (rows(nb) == 0) continue
		W[i, nb] = netobj->edge_weight_row(i)
	}
	return(W)
}
end
