# Multi-group 1.3.0: handoff

Branch `multigroup130` (from origin/main cdfd677), worktree
`/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/mg130/nwsaom`.
Nothing pushed, tagged or released. Stata 17 only, one process at a time.

## Done and validated (commits in `git log`)
- A: `estat gof`, `estat simulate`, `nwsaom simulate`, `estat importance` per group (b170499), also with one behavior, `ratecov()`, `present()` (37fefd2; importance not with `present()`). Validated against sienaGOF (network 9 means, behavior 6 means). Tests `test_nwsaom_groups_post`, `test_nwsaom_groups_post2`.
- B: RSiena keeps averageIn/OutDegree, structmean, balmean per group (R `setupOneModeGroup`, C++ `calculateProperties`); the 1.2.0 "pooled" text was a deviation. Per group now: inpopc/outpopc/outactc/inactc/degplus(c), ownx() effects (avg degrees, instructeq structmean and group size). Plugin protocol 144 (macOS build committed). f6b6368.
- C: `gwaves()` without `groups()` error; `joinat()/leaveat()` with groups; `behrate()` with groups (2f892b3 and the following commit); non-directed networks (symmetric, symtype 2, 3, 6) with groups. Validated with 10-seed RSiena references in `dev/saom_rsiena_groups_*_cond0.csv`; test `test_nwsaom_groups` (last run: all PASS markers incl. symmetric). modelType 6 is validated only with wide tolerance (RSiena runs partly non-converged).
- Quick suite (49 tests) run after B: no r() errors. Not re-run after C.

## Half-done / uncommitted state
- Last commit of this session contains the symmetric-groups change, CHANGELOG and this file. Help files (nwsaom.sthlp / nwsaom_remarks.sthlp), GOTCHA and `docs/MULTIGROUP_INVENTORY.md` rows for C (joinat, behrate, symmetric, gwaves) are NOT yet updated.
- `nwsaom.ado` size: check with `python3 ../../mg/work/sz.py` (was 132,297 vs limit about 134.4 KB).
- Mata libs not rebuilt (must be built with Stata 17 via `lib/build.do`, `record_core_lib.py`, `check_version.py`; NWCORE=.../scratchpad/r3100). Plugin saom_ml.c / saom_bayes.c unchanged.

## Not started
- C: two-mode with groups, multinet/multiplex with groups, several behaviors with groups (SaomEstimateRMCoevMB engine; needs per-behavior constants in the plugin trailer).
- D: `docs/MULTIGROUP_ML_BAYES_DESIGN.md` not written. Findings: RSiena ML with groups = pooled theta, callGrid over (group, period) (maxlikec.r). The chain machinery (saom_bayes.c: bctx_t, n actors, options h<n) needs an actor/option set per period (group members), n_g in the density and in the move proposals, per-period model copies (Mpd). RSiena sienaBayes with several groups is hierarchical (random effects across groups, mu, Sigma, inverse Wishart; multi_siena.r sampleMuSigma), not a pooled model: much larger.

## Resume
`cd <worktree>; git status; NWCORE=.../scratchpad/r3100 ../work/run.sh x test_nwsaom_groups 60` (scripts in `../work/`, `quick.sh <tag>` runs the quick suite sequentially under Stata 17).
