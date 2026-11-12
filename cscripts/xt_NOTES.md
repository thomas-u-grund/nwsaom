# Extended nwsaom tests (xt_*) - notes

Drafted 2026-11-12 against nwsaom 1.5.19 (branch tests-extended off main). **None of these files has been run.** Expect
first-run fixes (typos, a stored-result name, a column order). The runtimes below are estimates.

Run from the repo root like the other cscripts (the runner adds `sysdir`/`adopath` lines; `NWCORE` must point to the core).
`xt_common.do` is an include, not a test: every other xt file runs `do cscripts/xt_common.do` after its setup lines.

## Files

| File | Est. runtime | Coverage |
|---|---|---|
| xt_common.do | - | Mata data makers (xt_dir, xt_sym, xt_tm, xt_grp, xt_perm, xt_beh) and helpers: xt_netinfo, xt_masked, xt_esnap/xt_esame (e() unchanged), xt_dsnap/xt_dsame (data + networks unchanged), xt_rclist, xt_samerates, xt_simcheck, xt_rowcol, xt_mties (macro() for mems), xt_pcheck |
| xt_shapes_directed.do | 3-5 min | wave1/wave2, waves(a b), 3 and 4 waves x every postestimation; 5- and 6-actor hand matrices; structural 10/11 kept in sims, describe counts; missnet; present / joinat / leaveat; covariates, tvcov (estat 198), ratecov; co-evolution |
| xt_shapes_undirected.do | 5-7 min | 5 symtypes x cond/uncond x wave1/2 and waves; rate relations; symmetric sims; rates() round trip; nwsaom simulate == estat simulate; gof/triad/join(off)/importance/timetest/mems (macro gets symmetric matrices); tie-symmetric directed waves; mixed declarations; structural codes; behavior; present/ratecov/missnet |
| xt_shapes_twomode.do | 2-3 min | describe hand counts; 2/3 waves x 1/6 effects; ties = cells; gof/mems 198; importance, timetest, rates() round trip, nwsaom simulate == estat simulate; actormode(1); ratecov; structural codes; behavior (tolerant rc); 5 x 3 network |
| xt_shapes_multi.do | 4-6 min | groups() (gof/simulate/generate/importance/timetest/mems 198, per-group rates()); groups + behavior; groups undirected; gwaves(); several behaviors; multinet (timetest, refused estat, refit, score, two-mode member); multiplex both paths |
| xt_errors.do | 1-2 min | ~60 error paths with exact r() codes (102/111/125/198/301/321/482/498) and file:line; after each: e(), data, networks and (where meaningful) a baseline estat simulate unchanged |
| xt_longopts.do | 4-6 min | plugin option-string length: 120 x 40 two-mode, 100 actors with 5,000 structural zeros (directed, undirected), 42 covariate effects with 22-char names, 10 interactions (names <= 32), 16 rate covariates (17 refused), full-precision theta()/rates(), long net names and stub |
| xt_determinism.do | 5-8 min | same seed identical (incl. cores(1)/(2)), other seed differs; estat simulate/gof/mems/nwsaom simulate/refit determinism; set seed equivalence; actor-permutation invariance (describe and r(obs) exact; Monte-Carlo means z < 4; estimates within 0.5 max s.e. at k3(500); conditional rates mreldif < 0.05) |
| xt_rsiena_ref.do | < 1 min | 6-actor 3-wave data checked in R (base R + RSiena 1.6.14 sienaDataCreate): describe ties/density/avg degree, kept/created/dissolved/Jaccard/Hamming/persistence; observed statistics (outdegree, transTrip, cycle3); estat simulate r(obs). TODO-R blocks for estimates |
| xt_suspects.do | 3-4 min | one probe per suspected bug below; prints CONFIRMED / NOT CONFIRMED; **fails by design** while a suspect is real |

Tolerances are stated next to each stochastic assertion (xt_determinism.do mainly); they are deliberately loose.

## Suspected bugs and code/help mismatches (from reading; probed in xt_suspects.do unless marked "not probed")

- **S1** `e(present)` is never posted (no `ereturn` of it anywhere) but is read by nwsaom_estat_impgroups.ado:12, nwsaom_estat_gofgroups.ado:38, nwsaom_estat_simgroups.ado:50, nwsaom_estat.ado:502/537, nwsaom_estat_simulate.ado:209. So groups() + present(): gof/simulate ignore presence and the importance guard is dead.
- **S2** `__nwsaom_last_present` is set only for non-multi, non-coev fits (nwsaom.ado:3085) and, per earlier reading, only on the two-wave wave1/wave2 path; waves() (even `waves(a b)`), joinat/leaveat and co-evolution present fits are then simulated by estat simulate/gof/mems with all actors present (SaomGofSimNet unw_saom.do:15950; SaomGofSimCoev takes no presence). The importance guard (nwsaom_estat_importance.ado:37) misses them. Contradicts help ("waves(a b) is an equivalent spelling"; gof "present() included").
- **S3** estat importance does not refuse missnet() fits (guard at nwsaom_estat_importance.ado:37 checks endowment effects and present only), though its own message and the help say missing-data options are excluded.
- **S4** estat mems after fix(): e(V) gets a zero row/column for the fixed parameter (unw_saom.do:9204-9211); `cholesky(V)` in saom_mems_draw_theta (nwsaom_estat.ado:1383) then returns missing, so all draws are missing.
- **S5** nwsaom_estat_simgroups.ado:10 has no RATESBEH() option: `estat simulate ..., ratesbeh()` after groups() + behavior() is a syntax error although the help lists ratesbeh().
- **S6** estat simulate rates() after groups() with gwaves(): simgroups slices the rates per group correctly, but the count check in nwsaom_estat_simulate.ado:118 compares with the fit's overall number of periods before the group's own number is set (:149), so a group with fewer waves gets r(198).
- **S7** A late nwsaom error overwrites Mata state (graphs nwsaom.ado:834, model :1089, fixmask/score ~:2967) while e() keeps the old fit; SaomRatesReset (nwsaom.ado:154) runs before validation. Also `estimates restore` of an older fit silently uses the latest Mata state (no guard). nwsaom_multinet.ado (~:158) drops __nwsaom_fixmask/score.
- **S8** (help) nwsaom simulate replaces e() with its set-up fit (undocumented); an error after the set-up fit (e.g. nsim(0)) leaves e() changed. ratecov coefficients come from the short set-up fit, not from the user (fix(_all) covers effects only, nwsaom.ado:2984). The scale of rates() for pairwise symtypes depends on `unconditional` (nwsaom_estat_simulate.ado:122); help should say so.
- **S9** (help) r(sim) is a Stata matrix: nsim x periods > 800 fails on BE (matsize; GOTCHA), not documented.
- **S10** nwsaom describe refuses waves mixing an undirected and a tie-symmetric directed declaration (nwsaom_describe.ado ~:43) that nwsaom accepts.
- **S11** generate() with an existing stub stops with an nwset name clash (core nwset.ado:521), no replace option; a stub near 28 characters makes names > 32 (probe checks for partial leftovers).
- **S12** (not probed) estat gof after multiplex returns different codes on the two paths: the multinet-backed path posts e(estat_cmd) and gives 301, the theta01() path (nwsaom_multiplex.ado:129) posts none, so Stata's generic 321.
- **S13** (not probed, help) two-mode actormode(1): generated networks put the actors in the rows, so a generated network cannot be refitted with the same actormode(1) call (worth one help sentence).
- **S14** estat mems with a failing macro(): nwsaom_mems_callmacro (nwsaom_estat.ado:1351-1355) is called under `capture`; the macro error exits before the `nwdrop`, leaving `__nwsaom_mems_tmpnet` as the current network.
- Minor: covariate names > 27 characters make coefficient names > 32 (egox_/altx_ prefix) - check how nwsaom shortens them; nwsaom_describe.ado has a dangling `else` branch (harmless); the `persistence` column of r(periods) (nwsaom_describe.ado:125, kept/(kept+dissolved)) is not in the help.

## TODO-R (need an RSiena run; assertions are commented out until the numbers are in)

All in xt_rsiena_ref.do, with the exact R code:
1. RSiena's default initial rates for the 6-actor data (getEffects()$initialValue).
2. siena07 estimates and s.e. for the 6-actor model (outdegree, reciprocity, transTrip, cycle3), seed 1, n3 = 1000; compare within 2 s.e.
3. 40-actor directed model with egoX/altX and transTrip (data exported from xt_dir seed 4242); rate and estimates within 2 s.e.
4. Undirected data: print(sienaDataCreate()) counts and simOnly rates for modelType 2-6 at density -1.6, to pin down the pairwise rate scale (conditional RA/(n-1), unconditional sqrt(RA/(n-1))).
5. In xt_rsiena_ref.do the reciprocity statistic accepts 3 (mutual pairs) or 6 (reciprocated arcs, RSiena's target) because sn_stat_mutual() is in the core Mata library and its convention was not read from source; tighten once known.
