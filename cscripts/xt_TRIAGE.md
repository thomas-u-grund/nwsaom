# nwsaom extended tests: triage (2026-11-12, Stata 17 BE, nwsaom 1.5.19 + core of the same date)

Repro do-files and logs: `$S/xtrun/models/repro/nwsaom/` (`frame.do`, `frame2.do` frame hunt, `stub.do` long
generate() stub, `s5.do` + `multibeh.do` groups + behavior fit, `longname.do` core nwset name length, `symref.do` refused call vs estat simulate). The probes themselves are in
`cscripts/xt_suspects.do` (each probe is a minimal standalone block). Test logs: `$S/xtrun/models/nwsaom_xt_*.log`.

## Suspects and new findings

| Id | Verdict | Severity | One-line repro | Cause |
|---|---|---|---|---|
| S2 | CONFIRMED (wider than suspected) | wrong results silently | actor 1 absent at waves 1-2 (`present(p1 p2 p3)`, no ties): `estat simulate, generate()` gives it 3-5 ties in period 1. Holds for `waves(a b)` (S2a), 3 waves (S2b), `joinat()` (S2d) AND for `wave1() wave2()` (xt_shapes_directed.do block 5; non-directed too, xt_shapes_undirected.do block 6), so estat simulate/gof/mems ignore presence on every path | `__nwsaom_last_present` set only at nwsaom.ado:3085 (non-multi, non-coev), simulation reads it at unw_saom.do:15963; on the wave1/wave2 path it is still not applied |
| S1 | CONFIRMED | wrong results silently | groups(grp) + present(): `e(present)` empty; absent actor 1 of group 1 gets 3-5 ties in every simulation; `estat importance` runs | `e(present)` is never posted, but read at nwsaom_estat.ado:502, 537, nwsaom_estat_simulate.ado:209, nwsaom_estat_impgroups.ado:12, gofgroups.ado:38, simgroups.ado:50 |
| S2c | CONFIRMED | wrong results (help says not available) | 3-wave present() fit, `estat importance` runs | guard nwsaom_estat_importance.ado:37 reads the empty `__nwsaom_last_present` |
| S3 | CONFIRMED | wrong results (help says not available) | `nwsaom, wave1(dn1) wave2(dn2) ... missnet(M1 M2)`; `estat importance` runs | guard nwsaom_estat_importance.ado:37 checks endowment effects and present only |
| S11b | CONFIRMED (worse than suspected) | data loss (session's network set unusable) | fit, then `estat simulate, nsim(2) generate(abcdefghijabcdefghijabcdefgh)` (28 characters): r(482) "Network abcdefghijabcdefghijabcdefgh_1_p1 not found"; a 0-node network with that 33-character name is left current; afterwards `nwds` -> "Network _all not found", `nwsummarize dn1` -> "not found", `nwsaom, waves(dn1 ...)` -> "invalid varname" | nwsaom_estat_simulate.ado:217-225 builds `stub_s_pP` without a length check; core `nwset, name()` accepts a name over 32 characters and corrupts the network list |
| N7 (new) | CONFIRMED | wrong results silently | fit `waves(dn1 dn2 dn3)`; refused `nwsaom, waves(sn1 sn2) outdegree transtrip` (r(198); also symtype(bogus), reciprocity on undirected waves); e() unchanged, but `estat simulate, nsim(2) seed(5)` now gives 165 ties / 63 mutual instead of 112 / 8 (mreldif .88); refusals before :834 (e.g. `symmetric` on directed waves) leave it intact | nwsaom.ado:834-835 overwrite the stored wave graphs `__nwsaom_last_G#` before the symcheck refusal (:925); same class as nwergm E2 |
| N8 (new) | CONFIRMED | error only (raw Mata error) | `nwsaom, waves(dl1 dl2 dl3) outdegree reciprocity ratecov(<16 variables>)` fits; `estat simulate` -> "too many options", `SaomSimulateIntervalNative(): 3598` | unw_saom.do:14971-14997 put the K x n rate-covariate values into the plugin argument string, which exceeds Stata's limit (ratecov() allows 16, nwsaom.ado:786) |
| N9 (new, core) | CONFIRMED | data loss (all networks unreachable) | `nwset, mat(A) directed name(<33 characters>)` -> r(482) "not found"; afterwards `nwds` -> "Network _all not found", `nwsummarize ok1` -> not found | core nwset.ado: no check of the name length (Stata names <= 32); this is the root cause of S11b |
| N10 (new) | CONFIRMED | error only (results posted, table fails) | two waves named `a_rather_long_network_name_w1/_w2` (29 characters): `nwsaom, waves(...) outdegree reciprocity` -> "<w1>_to_<w2> invalid name", `_b_table` r(3598); e() is posted | the period equation name `<wave>_to_<wave>` exceeds 32 characters (built in nwsaom.ado for 2-wave fits); RSiena has no such limit |
| S7b | CONFIRMED (different from suspected) | session broken | fit A, `estimates store xa`, fit B (adds egox(x)), `estimates restore xa`, `estat simulate`: raw `SaomSimulateIntervalNative(): 3301 subscript invalid`, and the user is left in frame `__saom_native`; every later `estat simulate` stops with "may not drop current frame" r(3598) | no guard that the Mata state belongs to the e() in memory; the native simulation does not restore the frame on error |
| S6 | CONFIRMED | error only | `nwsaom, waves(g1 g2 g3) groups(grp) gwaves(2: 1 2) ...`, then `estat simulate, rates(<the fit's 5 rates>)` -> group 2: "rates() needs one rate per period (2)" | nwsaom_estat_simulate.ado:118 compares with the fit's number of periods before the group's own is set (:149) |
| S5 | CONFIRMED (code reading; runtime probe blocked) | error only | `estat simulate, ratesbeh()` after groups() + behavior() | nwsaom_estat_simgroups.ado:10 syntax has no RATESBEH(); the probe's groups + behavior fit itself stops with r(505) (phase-3 covariance singular) on the random behavior data, also with k3(200)/seed(2) |
| S14 | CONFIRMED | cosmetic | `estat mems, effect(outdegree) macro(nosuchprogram)` -> r(498) as wanted, but networks 6 -> 7 and the current network becomes `__nwsaom_mems_tmpnet` | nwsaom_estat.ado:1253 calls nwsaom_mems_callmacro under capture; its nwdrop (:1351-1355) is skipped when the macro fails |
| S10 | CONFIRMED | error only | `nwsaom, waves(su1 sd2)` (undirected + tie-symmetric directed) fits; `nwsaom describe, waves(su1 sd2)` -> r(198) | nwsaom_describe.ado ~:43 |
| S8 | CONFIRMED (help) | cosmetic (help) | `nwsaom simulate, ... nsim(0)` -> r(198) and e() has been replaced by the set-up fit | undocumented; see also the ratecov / pairwise rate-scale items in the notes (not probed) |
| S9 | CONFIRMED (help) | error only | `estat simulate, nsim(401)` on 2 periods -> r(915) (Stata BE matsize 800) | r(sim) is a Stata matrix; not documented |
| S11a | POLICY | - | second `estat simulate, generate(dup)` -> r(483) "already exists. Specify option replace", but there is no replace option | owner decides: add `replace` or change the message |
| S4 | NOT A BUG | - | `fix(reciprocity)` then `estat mems`: runs, MEMS 3.15 | cholesky of the reduced V works |
| S7a | NOT A BUG | - | a late refused nwsaom call (transtrip transtriads) leaves estat simulate identical | - |
| S12 | UNCLEAR (not probed) | - | multiplex estat gof codes 301 vs 321 | code reading only |
| S13 | POLICY (help sentence) | - | two-mode actormode(1) generated networks | not probed |
| minor: persistence column | CONFIRMED (help) | cosmetic | `nwsaom describe` r(periods) column `persistence` | nwsaom_describe.ado:166, not in the help |
| N1 replay | DECIDED: fix (owner 2026-11-12: add estimates replay to all four packages, low priority) | - | no replay, as in the other model commands | - |

Counts: CONFIRMED 18 (S1, S2 (a, b, d + wave1/wave2 counted once), S2c, S3, S5, S6, S7b, S8, S9, S10, S11b, S14,
persistence, N7, N8, N9 (core), N10), NOT A BUG 3 (S4, S7a, groups + behavior r(505) = test data), POLICY 2 (S11a, S13), DECIDED: fix 1
(replay), UNCLEAR 1 (S12).

Groups + behavior r(505) (xt_shapes_multi block 2, S5 probe): NOT A BUG. The generated behavior has no change at all in
group 3, period 1 (changes per group/period: 3/2, 6/2, 0/1; `multibeh.do`), so that behavior rate is not identified; the
same data without groups() fit fine.

## Test-code fixes

- xt_suspects.do: verdict/note helpers print `c(frame)` and return to the default frame (S7b leaves the user in
  `__saom_native`); rc saved before `capture drop`; S1 uses block-diagonal group networks (between-group ties zeroed);
  S7b counts a raw Mata rc or a left frame as confirmed; networks rebuilt after S11b (it corrupts the network set);
  S5 fit with seed 2 / k3(200) (still r(505): test data, see above); S14 prints its details.
- xt_errors.do: `xt_err` no longer stops at the first failed state assert; records failures in `$XT_EFAILS` (rc, e(),
  data/networks, frame, baseline estat simulate) and prints what changed; ends with exit 9 on failures. N7 marked.
- xt_rsiena_ref.do: `mreldif` on a 3x3 submatrix of W (r(509) conformability).
- xt_shapes_directed.do: the present() check on the wave1/wave2 path records S2 and goes on.
- xt_shapes_multi.do: r(sim_g#) / r(obs_g#) stored before `xt_simcheck` (an r-class helper clobbers r()); the
  groups + behavior block is skipped on r(505) (test data).
- xt_shapes_undirected.do / xt_determinism.do: fits that diverge on the random data (r(498), RSiena's thetaBound stop)
  are captured and skipped (block 1 and the mems block after joint unconditional wave1/wave2; the seed(8) fit).
- xt_longopts.do: Stata 17 Mata outer comparison `col :!= row'` rewritten with `J()`; N8 and N10 recorded instead of
  stopping; failure tally `$XT_LFAILS`.
- xt_shapes_undirected.do: present() check on the wave1/wave2 path records S2 and goes on (`$XT_UFAILS`).
- xt_shapes_multi.do: `nwclear` in block 5 drops the behavior variables -> recreated before the two-behavior fit.

## Remaining failures per file

| File | Result |
|---|---|
| xt_rsiena_ref.do | ALL PASS |
| xt_shapes_twomode.do | ALL PASS |
| xt_shapes_multi.do | ALL PASS (groups + behavior block SKIP: r(505) on the test data) |
| xt_determinism.do | ALL PASS (seed(8) fit diverges, NOTE) |
| xt_shapes_directed.do | r(9): CONFIRMED BUG S2 (wave1/wave2 path) only |
| xt_shapes_undirected.do | r(9): CONFIRMED BUG S2 (non-directed, wave1/wave2) only; 3 SKIP (unconditional wave1/wave2 fits diverge, r(498)) |
| xt_longopts.do | r(9): CONFIRMED BUG N8 (simulate and gof), N10 only |
| xt_errors.do | r(9): CONFIRMED BUG N7 only (3 refusals on undirected waves change estat simulate); all other rc/e()/data/frame checks pass |
| xt_suspects.do | ends r(9) by design: S1, S2a-d, S3, S6, S7b, S10, S11b, S14 confirmed; S8, S9, S11a notes hold; S4, S7a not confirmed; S5 probe blocked (r(505)) |
