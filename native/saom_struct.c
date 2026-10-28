/*
 * Copyright (C) 2026 Thomas U. Grund
 * This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
 * nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
 * Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
 */
/* Structural zeros and ones (RSiena's codes 10 and 11 in the wave networks).  Included by saom_sim.c (a few hook lines there).

   STRUCTSET|n P nrows   frame variables s_pd s_i s_j s_k (rows 1..nrows), after BATCHSETUP:
     s_k = 1  the dyad (i,j) is fixed during period s_pd (s_pd = 0: in every period)
     s_k = 2  the dyad is structural at the END of period s_pd with value 0, s_k = 3 with value 1: it is free during the period and gets that value
              before the statistics are computed (RSiena: StatisticCalculator, replaceNetwork(x_{p+1}, S_{p+1}))
   Per period the plugin keeps a copy of the model (the Mpd array, as for groups) whose fixed-dyad lists (CSR by ego, and the lists of free
   alternatives) are the union of the dyads of the BATCHSETUP trailer (the two-mode structure), the dyads of every period and the dyads of the
   period.  An ego can act in a period iff it has a free alternative among the ACTIVE actors (NetworkVariable::canMakeChange()); the actors that
   cannot act have rate 0, the plain model draws the acting ego among the others. */

typedef struct {
	long *off, *j, *fro, *frj;	/* fixed dyads CSR by ego (size n+2 offsets), free alternatives CSR */
	long cnt;
} sf_csr_t;

typedef struct {
	long P, ncsr;
	sf_csr_t *csr;			/* distinct lists; csr[0] = base + dyads of every period */
	long *ovn;			/* per period: number of end overrides */
	long **ovi, **ovj;
	unsigned char **ovv;
} sf_mem_t;

static int sf_cmp_long(const void *a, const void *b) {
	long x = *(const long *)a, y = *(const long *)b;
	return (x > y) - (x < y);
}

/* is (i,j) a fixed dyad of this period's model?  The lists of an ego are ascending. */
static int saom_sf_isfixed(const model_t *M, long i, long j) {
	long lo, hi;
	if (!M->struct_off || M->nstruct <= 0) return 0;
	lo = M->struct_off[i]; hi = M->struct_off[i + 1] - 1;
	while (lo <= hi) {
		long mid = (lo + hi) / 2;
		if (M->struct_j[mid] == j) return 1;
		if (M->struct_j[mid] < j) lo = mid + 1; else hi = mid - 1;
	}
	return 0;
}

/* the egos that can act in the period: active (pres NULL: all) with a free alternative among the active actors.  eligf[1..n] flags, idx the
   list of the eligible egos; returns their number */
static long saom_sf_elig(const model_t *M, long n, const double *pres, unsigned char *eligf, long *idx) {
	long i, q, nact = 0, cnt = 0;
	if (pres) { for (i = 1; i <= n; i++) if (pres[i] != 0.0) nact++; }
	else nact = n;
	for (i = 1; i <= n; i++) {
		long fixedact = 0;
		eligf[i] = 0;
		if (pres && pres[i] == 0.0) continue;
		if (M->struct_off && M->nstruct > 0) {
			for (q = M->struct_off[i]; q < M->struct_off[i + 1]; q++) {
				long j = M->struct_j[q];
				if (!pres || pres[j] != 0.0) fixedact++;
			}
		}
		if (nact - 1 - fixedact > 0) { eligf[i] = 1; idx[cnt++] = i; }
	}
	return cnt;
}

/* the structural values of the end of the period: set the dyads to their value */
static void saom_sf_override(const model_t *M, graph_t *g) {
	long k;
	for (k = 0; k < M->sov_n; k++) {
		int want = M->sov_v[k] ? 1 : 0;
		if ((has_edge(g, M->sov_i[k], M->sov_j[k]) ? 1 : 0) != want) toggle(g, M->sov_i[k], M->sov_j[k]);
	}
}

static void sf_csr_free(sf_csr_t *c) {
	free(c->off); free(c->j); free(c->fro); free(c->frj);
	c->off = c->j = c->fro = c->frj = NULL;
}

/* the CSR (and the free-alternative lists) of the sorted unique keys (ego-1)*n + alter */
static void sf_csr_build(sf_csr_t *c, long n, long m, const long *keys) {
	long k, i, e, tot;
	unsigned char *mark;
	c->cnt = m;
	c->off = (long *)calloc((size_t)(n + 2), sizeof(long));
	c->j = (long *)malloc((size_t)(m > 0 ? m : 1) * sizeof(long));
	for (k = 0; k < m; k++) c->off[keys[k] / n + 2]++;
	for (i = 1; i <= n + 1; i++) c->off[i] += c->off[i - 1];
	{
		long *fill = (long *)calloc((size_t)(n + 2), sizeof(long));
		for (k = 0; k < m; k++) {
			long ego = keys[k] / n + 1, alt = keys[k] % n + 1;
			c->j[c->off[ego] + fill[ego]++] = alt;
		}
		free(fill);
	}
	c->fro = (long *)calloc((size_t)(n + 2), sizeof(long));
	mark = (unsigned char *)calloc((size_t)(n + 1), 1);
	for (e = 1; e <= n; e++) {
		long cnt = 0;
		if (c->off[e + 1] > c->off[e]) {
			for (k = c->off[e]; k < c->off[e + 1]; k++) mark[c->j[k]] = 1;
			for (i = 1; i <= n; i++) if (i != e && !mark[i]) cnt++;
			for (k = c->off[e]; k < c->off[e + 1]; k++) mark[c->j[k]] = 0;
		}
		c->fro[e + 1] = c->fro[e] + cnt;
	}
	tot = c->fro[n + 1];
	c->frj = (long *)malloc((size_t)(tot > 0 ? tot : 1) * sizeof(long));
	for (e = 1; e <= n; e++) {
		long w = c->fro[e];
		if (c->off[e + 1] > c->off[e]) {
			for (k = c->off[e]; k < c->off[e + 1]; k++) mark[c->j[k]] = 1;
			for (i = 1; i <= n; i++) if (i != e && !mark[i]) c->frj[w++] = i;
			for (k = c->off[e]; k < c->off[e + 1]; k++) mark[c->j[k]] = 0;
		}
	}
	free(mark);
}

static void saom_sf_free(void **pm) {
	sf_mem_t *S = (sf_mem_t *)*pm;
	long q;
	if (!S) return;
	for (q = 0; q < S->ncsr; q++) sf_csr_free(&S->csr[q]);
	free(S->csr);
	for (q = 0; q < S->P; q++) { free(S->ovi[q]); free(S->ovj[q]); free(S->ovv[q]); }
	free(S->ovi); free(S->ovj); free(S->ovv); free(S->ovn);
	free(S);
	*pm = NULL;
}

/* keys of the fixed dyads of the BATCHSETUP trailer (the two-mode structure) */
static long sf_base_keys(const model_t *M, long n, long *out) {
	long e, q, c = 0;
	if (!M->struct_off || M->nstruct <= 0) return 0;
	for (e = 1; e <= n; e++) for (q = M->struct_off[e]; q < M->struct_off[e + 1]; q++) out[c++] = (e - 1) * n + (M->struct_j[q] - 1);
	return c;
}

static long sf_unique(long *a, long m) {
	long i, w = 0;
	if (m == 0) return 0;
	qsort(a, (size_t)m, sizeof(long), sf_cmp_long);
	for (i = 0; i < m; i++) if (i == 0 || a[i] != a[i - 1]) a[w++] = a[i];
	return w;
}

static ST_retcode saom_sf_set(char *arg) {
	long n, P, nrows, r, pd, q;
	long *rpd, *ri, *rj, *rk;
	char *tok0;
	sf_mem_t *S;
	model_t *M = &batch_cur->M;
	long nbase, nall;
	long *keys, *k0;
	long m0;

	if (!batch_cur->ready) { SF_error("saom_sim: STRUCTSET needs a BATCHSETUP first\n"); return 198; }
	tok0 = strtok(arg, " \t");
	if (!tok0) { SF_error("saom_sim: STRUCTSET empty\n"); return 198; }
	n = (long)atof(tok0);
	P = next_long();
	nrows = next_long();
	if (n != M->n || P != batch_cur->P) { SF_error("saom_sim: STRUCTSET does not match the batch data\n"); return 198; }
	rpd = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	ri = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	rj = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	rk = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	for (r = 0; r < nrows; r++) {
		ST_double a, b, c, d;
		SF_vdata(1, r + 1, &a); SF_vdata(2, r + 1, &b); SF_vdata(3, r + 1, &c); SF_vdata(4, r + 1, &d);
		rpd[r] = (long)a; ri[r] = (long)b; rj[r] = (long)c; rk[r] = (long)d;
		if (ri[r] < 1 || ri[r] > n || rj[r] < 1 || rj[r] > n || ri[r] == rj[r] || rpd[r] < 0 || rpd[r] > P || rk[r] < 1 || rk[r] > 3) {
			free(rpd); free(ri); free(rj); free(rk);
			SF_error("saom_sim: STRUCTSET invalid row\n");
			return 198;
		}
	}
	saom_sf_free(&batch_cur->sfmem);
	S = (sf_mem_t *)calloc(1, sizeof(sf_mem_t));
	S->P = P;
	S->ovn = (long *)calloc((size_t)P, sizeof(long));
	S->ovi = (long **)calloc((size_t)P, sizeof(long *));
	S->ovj = (long **)calloc((size_t)P, sizeof(long *));
	S->ovv = (unsigned char **)calloc((size_t)P, sizeof(unsigned char *));
	S->csr = (sf_csr_t *)calloc((size_t)(P + 1), sizeof(sf_csr_t));
	/* csr[0]: the base (trailer) dyads and the dyads of every period */
	nbase = (M->struct_off && M->nstruct > 0) ? M->nstruct : 0;
	nall = nbase;
	for (r = 0; r < nrows; r++) if (rk[r] == 1 && rpd[r] == 0) nall++;
	k0 = (long *)malloc((size_t)(nall > 0 ? nall : 1) * sizeof(long));
	m0 = sf_base_keys(M, n, k0);
	for (r = 0; r < nrows; r++) if (rk[r] == 1 && rpd[r] == 0) k0[m0++] = (ri[r] - 1) * n + (rj[r] - 1);
	m0 = sf_unique(k0, m0);
	sf_csr_build(&S->csr[0], n, m0, k0);
	S->ncsr = 1;
	if (!batch_cur->Mpd) {
		batch_cur->Mpd = (model_t *)malloc((size_t)P * sizeof(model_t));
		for (pd = 0; pd < P; pd++) batch_cur->Mpd[pd] = *M;
	}
	keys = (long *)malloc((size_t)(m0 + nrows + 1) * sizeof(long));
	for (pd = 0; pd < P; pd++) {
		long nex = 0, nov = 0, m = 0;
		sf_csr_t *use = &S->csr[0];
		model_t *Mp = &batch_cur->Mpd[pd];
		for (r = 0; r < nrows; r++) {
			if (rpd[r] != pd + 1) continue;
			if (rk[r] == 1) nex++; else nov++;
		}
		if (nex > 0) {
			memcpy(keys, k0, (size_t)m0 * sizeof(long));
			m = m0;
			for (r = 0; r < nrows; r++) if (rpd[r] == pd + 1 && rk[r] == 1) keys[m++] = (ri[r] - 1) * n + (rj[r] - 1);
			m = sf_unique(keys, m);
			sf_csr_build(&S->csr[S->ncsr], n, m, keys);
			use = &S->csr[S->ncsr];
			S->ncsr++;
		}
		Mp->nstruct = use->cnt;
		Mp->struct_off = use->off;
		Mp->struct_j = use->j;
		Mp->fr_off = use->fro;
		Mp->fr_j = use->frj;
		Mp->sflag = 1;
		Mp->sov_n = nov;
		S->ovn[pd] = nov;
		if (nov > 0) {
			S->ovi[pd] = (long *)malloc((size_t)nov * sizeof(long));
			S->ovj[pd] = (long *)malloc((size_t)nov * sizeof(long));
			S->ovv[pd] = (unsigned char *)malloc((size_t)nov);
			q = 0;
			for (r = 0; r < nrows; r++) {
				if (rpd[r] != pd + 1 || rk[r] == 1) continue;
				S->ovi[pd][q] = ri[r]; S->ovj[pd][q] = rj[r]; S->ovv[pd][q] = (rk[r] == 3); q++;
			}
			Mp->sov_i = S->ovi[pd]; Mp->sov_j = S->ovj[pd]; Mp->sov_v = S->ovv[pd];
		}
		else { Mp->sov_i = NULL; Mp->sov_j = NULL; Mp->sov_v = NULL; }
	}
	batch_cur->sfmem = S;
	free(keys); free(k0); free(rpd); free(ri); free(rj); free(rk);
	return 0;
}

/* ---- single-call interface (estat gof / simulate / mems ...): STRUCTSET1|n nrows installs the fixed dyads (kind 1) and the end values (kind 2/3) of ONE period for the NEXT
   single simulation call, which consumes them.  Frame variables s_pd s_i s_j s_k as for STRUCTSET (s_pd ignored). ---- */
static struct {
	int active;
	long na, nb;
	long *akey;
	long *bi, *bj;
	unsigned char *bv;
	sf_csr_t csr;
	int hascsr;
} sf1;

static void sf1_release(void) {
	free(sf1.akey); free(sf1.bi); free(sf1.bj); free(sf1.bv);
	if (sf1.hascsr) sf_csr_free(&sf1.csr);
	memset(&sf1, 0, sizeof(sf1));
}

static ST_retcode saom_sf_set1(char *arg) {
	long n, nrows, r;
	char *tok0;
	sf1_release();
	tok0 = strtok(arg, " \t");
	if (!tok0) { SF_error("saom_sim: STRUCTSET1 empty\n"); return 198; }
	n = (long)atof(tok0);
	nrows = next_long();
	sf1.akey = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	sf1.bi = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	sf1.bj = (long *)malloc((size_t)(nrows > 0 ? nrows : 1) * sizeof(long));
	sf1.bv = (unsigned char *)malloc((size_t)(nrows > 0 ? nrows : 1));
	for (r = 0; r < nrows; r++) {
		ST_double a, b, c, d;
		long i, j, k;
		SF_vdata(1, r + 1, &a); SF_vdata(2, r + 1, &b); SF_vdata(3, r + 1, &c); SF_vdata(4, r + 1, &d);
		(void)a;
		i = (long)b; j = (long)c; k = (long)d;
		if (i < 1 || i > n || j < 1 || j > n || i == j || k < 1 || k > 3) { sf1_release(); SF_error("saom_sim: STRUCTSET1 invalid row\n"); return 198; }
		if (k == 1) sf1.akey[sf1.na++] = (i - 1) * n + (j - 1);
		else { sf1.bi[sf1.nb] = i; sf1.bj[sf1.nb] = j; sf1.bv[sf1.nb] = (k == 3); sf1.nb++; }
	}
	sf1.active = 1;
	return 0;
}

/* called by the single-call interface after the model is parsed: merge the installed sets into M (the model is local to the call) */
static void sf1_attach(model_t *M) {
	long n = M->n, m, nb0;
	long *keys;
	if (!sf1.active) return;
	nb0 = (M->struct_off && M->nstruct > 0) ? M->nstruct : 0;
	keys = (long *)malloc((size_t)(nb0 + sf1.na + 1) * sizeof(long));
	m = sf_base_keys(M, n, keys);
	memcpy(keys + m, sf1.akey, (size_t)sf1.na * sizeof(long));
	m = sf_unique(keys, m + sf1.na);
	sf_csr_build(&sf1.csr, n, m, keys);
	sf1.hascsr = 1;
	free(keys);
	/* the model's own lists (from the trailer) stay allocated and are freed by the caller; the merged ones are ours */
	M->struct_off = sf1.csr.off; M->struct_j = sf1.csr.j; M->fr_off = sf1.csr.fro; M->fr_j = sf1.csr.frj;
	M->nstruct = sf1.csr.cnt;
	M->sflag = 1;
	M->sov_n = sf1.nb; M->sov_i = sf1.bi; M->sov_j = sf1.bj; M->sov_v = sf1.bv;
}
