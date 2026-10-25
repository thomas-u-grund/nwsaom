# Gotchas of nwsaom

Known, already diagnosed pitfalls. Entries copied from the nwcommands notes at the time of the split; some mention the core package.

## Mata libraries must be built with the OLDEST supported Stata (Stata 17), never a newer one

The 2026-10-25 releases (core 3.5.0, nwsaom 1.0.7, nwergm 1.2.0, nwdynam 1.1.0, nwrem 1.0.5) shipped `.mlib` files built with Stata 18.
A Stata 17 user got `nwwebuse florentine` -> `<istmt>: 3499 nws_create() not found`, even from a clean install: Stata 17 lists the
library (`mata mlib query`, `mata describe using lnwcommands` work) but silently ignores its contents. The only trace is
`mata which nws_create()`: "(nws_create() in lnwcommands, compiled by Stata 18.0, is too new to be run by this version of Stata and so
was ignored)". The reverse is fine: Stata 18 reads libraries built by Stata 17. So build with the oldest supported Stata (currently 17).
`lib/build.do` of every package stops when `c(stata_version)` is higher than 17 (`NW_ALLOW_NEWER_STATA=1` overrides, for libraries that
are never released). The only reliable check of a release candidate is to run a
command in Stata 17 against the built library. The core has `_nwlibcheck.ado` (called by `unw_defs` and the commands that do not call it) which turns the
failure into a readable message with exit 3499. An OLD library in the user's PLUS folder (for example from a Sep 2026 install) shadows
the new one and gives r(3021) or other class errors; the message tells the user to `ado uninstall nwcommands` first.

## `nwsaom`'s native backend can leave state that crashes a later, unrelated `nwsaom` call

Found while building the SAOM chapter's own convergence-workflow example: in one continuous Stata
session, fitting a multi-wave structural model (`nwsaom, waves(...) outdegree reciprocity transtrip
nodematch(...)`), then running `estat gof` on it, then attempting an unrelated co-evolution fit
(`nwsaom, wave1(...) wave2(...) ... behavior(...) linear avsim`) crashes the co-evolution call with
`variable vbeh not found` / `st_store(): invalid Stata variable name` — a raw Mata-level error, not
the clean, documented `SAOM estimation diverged during phase 2...` message the identical
co-evolution command produces when run in a fresh Stata process, or even in the same process
without that specific `estat gof` call first.

Bisected across roughly a dozen isolated repro attempts (see the SAOM chapter's own build session
for the trail): the trigger needs *both* a preceding `estat gof` call on a multi-wave/structural
fit *and* a distinct-shaped `nwsaom` call afterward — plain repeated `nwsaom` calls alone (even
five or six in a row, even using `theta0()` restarts) never reproduce it; nor does `estat gof` on a
plain two-effect model followed by co-evolution. Confirmed the corruption isn't one-directional
either: running the co-evolution call (even one that only reaches the clean divergence path) before
a later plain multi-wave `nwsaom` call can *also* poison that later call instead (`variable a1 not
found`). `nwsaom.ado` documents a deliberate "one persistent Mata object per wave" convention
(around its own line ~1490) for performance, backed by a compiled `native/saom_sim.c` plugin; the
most likely mechanism is that this persistent per-wave object isn't fully invalidated/rebuilt when
the *shape* of the fit changes (network-only vs. co-evolution) between calls, especially after a
call that takes a non-standard exit path like `estat gof`'s own simulation or a divergence.

**Not fixed** — the root cause almost certainly lives in the native C plugin, not the `.ado` layer,
and wasn't chased further given the scope of the task that found it (writing the book chapter, not
debugging the native backend). **Workaround that IS verified to work**: never run `estat gof` and a
`behavior()`/co-evolution `nwsaom` call in the same Stata session with anything else `nwsaom`-shaped
between them — if a chapter, script, or analysis needs both, do the co-evolution work in its own
process (or before any `estat gof` call), never after. The SAOM chapter's own do-file structures
its command order specifically to route around this: every clean/successful demonstration runs
first, and the (intentionally diverging) co-evolution attempt runs last, with no `estat gof` call
anywhere in the same script.

**For whoever picks this up next**: start from `dev/`'s own existing SAOM cross-check scripts
(`dev/dynam_unit*_crosscheck.*` show the pattern used elsewhere in this codebase for isolating a
native-backend discrepancy) and reproduce the minimal repro above (`waves()` fit with `transtrip`
+ `nodematch()`, then `estat gof`, then any `behavior()` fit) as a permanent regression test before
touching `native/saom_sim.c` itself.

## `nwsaom` co-evolution: rates were never estimated; cross statistics must be lagged (fixed 2026-09-30)

With `behavior()` there are two dependent variables, so RSiena uses UNCONDITIONAL Method of
Moments: every period's network rate and behavior rate is an ordinary MoM parameter, estimated
with the others in phases 1-3. The rate statistics are DISTANCES from the period's starting
observation: differing dyads (network), sum of |z_end - z_start| (behavior). `nwsaom` instead kept
both rates at their closed-form starting values (the conditional shortcut that is fine for a
network-only fit) and only reported t-ratios on the number of toggles, which is not the distance.
On s50 the behavior parameters ran away (linear shape -40, SE 274). The help text even claimed
this was RSiena's default for 2+ dependent variables; it is not. Now `SaomEstimateRMCoevMulti()`
estimates `(thetaNet, thetaBeh, net rates, behavior rates)` jointly, rate score =
ministeps/rate - active actors; `SaomEstimateRMCoev()` is a one-period wrapper.

Three further RSiena mismatches surfaced while matching RSiena's per-period targets
(`ans$targets2`) on s50, each invisible without that comparison:
- Statistics linking the two variables are LAGGED: a behavior-dependent network effect uses the
  START-of-period behavior, a network-dependent behavior effect (avAlt, avSim) the START-of-period
  network, for targets and simulated statistics alike. We used end-of-period values.
- avAlt is CENTERED in RSiena (statistic and ministep change): `(z_i - zbar) * avg_j (z_j - zbar)`.
  The uncentered version is a different model, not a reparametrization.
- There was no selection effect on the co-evolving behavior: `simcov()` reads a fixed covariate.
  New `behsim` = RSiena's simX(behavior), centered by the behavior's similarity mean, reading the
  CURRENT simulated behavior (the simulators keep `td.attr` in step: `SaomBehSimSync()`).

After the fix nwsaom matches RSiena on s50 within a fraction of an SE for every parameter, 3 and 2
waves (`cscripts/test_nwsaom_coev_rsiena.do`). **Lesson:** compare per-period TARGET statistics
with RSiena before comparing estimates; a target that differs pins the bug to a definition, not to
the optimizer.

Network-only fits had the same flaw in a milder form; fixed 2026-10-01, see "`nwsaom` network-only
rates" below.

## The saom_sim plugin: a stale installed copy in PLUS used to win over the repo's own (fixed 2026-09-30)

`SaomNativePluginPath()` used to try `findfile("saom_sim_macos.plugin")` first, which finds a `net
install`ed copy in PLUS before the checkout's `lib/plugins/<os>/` one. Running from a checkout then
silently exercised an OLD binary. Two real consequences on 2026-09-30: the baseline
`test_nwsaom_native.do` run hung in `saom_test_native_cycle4_equiv`, and the new co-evolution
estimator, which needs plugin protocol >= 3 (`__saom_native_version`, checked by
`SaomNativePluginVersion()`), fell back to the pure-Mata simulator: the s50 three-wave model took
over 10 minutes (two waves: 1,038 s) instead of 5 s. The lookup now prefers the plugin next to the
`nwsaom.ado` being run and only then `findfile()`; after a real net install there is no
`lib/plugins/` next to `nwsaom.ado`, so nothing changes there. The unix/windows binaries are rebuilt
by CI, not locally: until then they report an older protocol and co-evolution runs (correctly, but
slowly) in Mata on those platforms. Other plugins (`ergm_mcmc`, `nwgraph`, `dynam_sim`) still use
the old findfile-first order.

Timing, s50 three-wave model (`outdegree reciprocity transtrip behsim` / `linear quadratic
avalt`), native path: 5.0 s (phase 1 0.07 s, phase 2 3.2 s, phase 3 1.6 s; 6,014 simulated periods
at 0.7 ms each, almost all of it the C ministep loop; a plugin call itself costs about 0.01 ms).
The lagged behavior statistics were computed in Mata at first (0.5 ms per period, 3 s per fit) and
now come from the plugin (`__saom_native_statbehlag%d`).

## `nwsaom` multiplex: rates fixed, crprod not lagged (fixed 2026-10-01)

`SaomEstimateRMCoevNetNet()` held both rates at their closed-form starting values, like the
network+behavior estimator before 2026-09-30, and evaluated `crprod` (a tie of network 1 where
network 2 has one) with the other network's END state. RSiena estimates both rates by unconditional
MoM and lags the cross-network statistic: its targets on a two-network s50 example are
`sum(x1(t2) * x2(t1))` (43) and `sum(x2(t2) * x1(t1))` (66). Now the estimator runs on
`SaomRMCore()` with `(theta1, theta2, rate1, rate2)`; the NN branch of `native/saom_sim.c` returns
per-network ministep counts, end-vs-start distances and lagged crprod statistics (protocol 5). On
that example (`cscripts/test_nwsaom_multiplex.do`) every parameter agrees with RSiena within 0.06
SE. The 6-actor toy networks the ado-level test used before cannot identify the model.

## Plugin programs defined inside nwsaom are not the ones a do-file defines (found 2026-10-01)

`program saomnativesim, plugin using("other.plugin")` typed in a do-file does NOT make nwsaom use
`other.plugin`: the plugin program nwsaom's own Mata code defines (via `stata("capture program
saomnativesim, plugin using(...)")` while the ado-file runs) is a separate definition, and a
`plugin call saomnativesim` from the do-file afterwards even reports "unrecognized command". Two
"old vs new plugin" comparisons and a pinned-baseline benchmark silently ran the checkout plugin
before this was noticed (a static call counter in a profiling build showed calls=1). To choose a
plugin file for testing or benchmarking, set the Mata external `__nwsaom_saom_plugin` to its path;
`SaomNativePluginPath()` returns it when set. Likewise, a diagnostic `plugin call` (e.g. a
profiling dump) must be issued from inside the same Mata code path, not from the do-file.

## nwsaom threads: results must not depend on the number of cores (2026-10-01)

The batch entry points (`BATCHSETUP|`/`BATCHRUN|`/`BATCHCLEAN|` in `native/saom_sim.c`) keep the
periods' starting data resident in the plugin between calls (static `batch_state`; freed by
`SaomBatchCleanup()`), and run K replicates x P periods on worker threads. Unit (k, pd) seeds its
own RNG from (seed, k, pd), and per-replicate sums over periods are formed after the join in a
fixed order, so `cores(1)` and the default give bit-identical results (checked on six benchmark
models). Worker threads call only `simulate_period()`, which touches no Stata API and no mutable
statics (`saom_behsim_range` is set before the threads start). Keep it that way: any new term
that caches state in a static breaks thread safety. Outputs come back through a frame
(`__saom_batch_out`), not a Stata matrix: Stata/BE matrices are limited to 800 rows, below k3 =
1000. For small networks, phase-2 steps run single-threaded (waking threads costs more than a
50-actor simulation); that choice does not affect results. The new random streams changed results
for a given seed relative to 2332434: the 6-model RSiena validation moved from max |diff|/SE 0.19
to 0.17 (mean 0.06 both). Only the macOS plugin is rebuilt locally; the Windows build uses Win32
threads (`#if defined(_WIN32)`), untested here until CI builds it.

## `nwsaom` network-only rates: fixed during estimation, refined afterwards (fixed 2026-10-01)

`SaomEstimateRM()`/`SaomEstimateRMMulti()` held the rate at RSiena's closed-form STARTING value
(`n*(0.2 + 2*distance)/(n*(n-1)+1)`) throughout phases 1-3 and only replaced the REPORTED rate
afterwards by a conditional-simulation estimate. The effects were thus estimated from simulations
with about 14% too few ministeps, 0.3-0.6 SE off RSiena (reciprocity too small, gwesp too large),
stable across seeds. Now both, and the multiplex estimator, call `SaomRMCore()` with the rates as
ordinary MoM parameters (statistic: dyads in which the simulated end network differs from the
period's start; score: ministeps/rate - active actors), RSiena's `cond = FALSE`. Validation (six
models on s50, five seeds each; reference numbers in `cscripts/test_nwsaom_rsiena.do`): every
parameter within 0.06 SE of RSiena's unconditional estimates. Things found on the way:

- **RSiena's DEFAULT for a single network is conditional estimation, and its conditional and
  unconditional estimates differ by up to 0.3 SE** (outdegree more negative, reciprocity larger
  under `cond = TRUE`; seed-to-seed SD about 0.005). Matching RSiena "default output" and matching
  RSiena "unconditional" are not the same target; nwsaom matches the latter.
- **Simulation seeds were passed to the plugin as `strofreal(seed)`, i.e. `%9.0g`, four
  significant digits.** With K=1 batch calls in phase 2 the simulated distances came out biased
  (mean deviation -1.2 instead of +0.35 over 5000 calls at fixed parameters, 7 SE), which pushed
  the estimated rate up by 0.1 (rate t-ratio +0.13 on average). All seed arguments now use
  `%12.0f`. nwergm had the same bug (`unw_ergm.do`, the MCMC seed, and theta, term parameters and
  observed statistics sent with the default `%9.0g`); fixed the same way on 2026-10-01 (seed
  `%12.0f`, reals `%25.17g`).
- **Starting values matter more once the rate moves.** RSiena starts outdegree at a data-derived
  value (`getNetworkStartingVals()`, now `SaomOutdegreeStart()`) and ends phase 1 with a partial
  quasi-Newton step (`phase1.2`); nwsaom did neither. From outdegree = 0 the network explodes in
  phase 1 and the Jacobian is useless; outdegree + isolatenet on the isoiso data diverged. Both are
  in now (network-only; co-evolution unchanged).
- **Network endowment/creation statistics were not RSiena's.** The statistic was the effect's
  statistic on the lost-/gained-ties network, which for reciprocity counts dyads lost/gained in
  BOTH directions (14/10 on s50) instead of RSiena's lost ties reciprocated at the start (-35) and
  gained ties reciprocated at the end (27); the endowment sign was also flipped (its phase-1
  derivative came out negative - the "persistently negative outdegreeendow diagonal" of unit 169).
  With a fixed rate the fits "converged" anyway; with the rate estimated they diverged.
  `outdegreeendow`+`outdegreecreation` cannot be estimated with the rate at all (lost + gained ties
  = the rate's distance statistic, RSiena: singular covariance) and are now refused.
- The non-positive-derivative safeguard now FIXES the parameter (no updates, SE 0), as RSiena
  does; a decoupled but still-updated parameter drifted and, with the rates estimated, dragged a
  rate to 70+ (glacially slow simulations).
- `cscripts/test_nwsaom_multiplex.do` did `cd` to the main checkout and so tested that checkout's
  Mata code from any worktree; it now runs from the repository root like the other cscripts.
- The ado smoke tests ran on 6-actor toy networks that cannot identify a model once the rate is
  estimated (RSiena stops with thetaBound on them under both estimators); they now use glasgow.


## `nwsaom, symmetric`: BAGREE rule, symmetric scores, ratecov actor draw (fixed 2026-10-01)

Checked against RSiena's pairwise model types on symmetrized s50 (joint = modelType 6, force = 4,
agree = 5). Three things were off in the B-family branch of `native/saom_sim.c`: (1) BAGREE used
`sigma(-u_alter)` for the alter; RSiena's `calculateSymmetricTieFlipProbabilities()` computes
`1/(1+exp(u))` for u > 0 and `exp(u)/(1+exp(u))` otherwise, i.e. `sigma(-|u|)` - reproduced as is
(density -2.44 before, RSiena -1.08, now -1.08); (2) the ministep scores used only the initiating
actor's change statistic, so BJOINT standard errors were twice RSiena's; the scores are now RSiena's
(`accumulateSymmetricModelScores()`); (3) with `ratecov()` the acting actor was drawn uniformly,
so the covariate only rescaled the rate - with the rate estimated the two raced off together.
Effects and SEs now agree with RSiena within 0.01 SE. The rate is per actor in nwsaom and per pair
in RSiena (ratio about 27-29 on these data, depending on the rule - not a clean constant; not
chased).

## `nwsaom` e(tratio) was not on RSiena's scale (changed 2026-10-01)

`e(tratio)`, `e(rate_tratio(s))` and the co-evolution/multiplex t-ratios were mean / (sd/sqrt(k3)),
i.e. about 31.6 times RSiena's convergence t-ratio (mean / sd) with k3(1000). Compared with
RSiena's 0.1 threshold (a book example did) they flagged every converged fit. All of them are now on
RSiena's scale (`e(tratio)` = the effect columns of `e(tconv)`), and every fit prints the whole
`e(tconv)` table plus `e(tconv_max)` below the coefficients.

## `nwsaom` conditional estimation is the default for network-only models (2026-10-01)

RSiena's `initializeFRAN()`: `cconditional <- !maxlike && (number of dependent variables == 1)`,
and not with composition change. nwsaom follows that: network-only fits are conditional unless
`unconditional` is given; co-evolution and multiplex fits are always unconditional; `present()`
that restricts an actor switches a network-only fit to unconditional. Conditional mode simulates
each period at rate 1 until the distance from the start reaches the observed distance
(`EpochSimulation::runEpoch()`: checked after every step, so at least one step; missing dyads not
counted; symmetric networks in steps of two); the rate is the mean phase-3 time and its reported
"SE" the SD of those times (`terminateFRAN()`). Details that matter for matching RSiena:
- The distance must exclude missing dyads and count symmetric changes twice in the plugin's
  conditional mode too (protocol 6); protocol 5 counted every toggle.
- RSiena's conditional and unconditional estimates differ by up to 0.3 SE on s50; each nwsaom mode
  matches its RSiena counterpart within 0.07 SE (`cscripts/test_nwsaom_rsiena.do`).
- For the symmetric (pairwise) model types RSiena's conditional rate is per pair: nwsaom's
  per-actor rate divided by n - 1. RSiena's UNCONDITIONAL pairwise rates are on yet another scale
  (about 1.8 times its conditional ones on s50); not chased.
- `outdegreeendow`+`outdegreecreation` stays refused: lost + gained ties is the distance that
  conditional estimation holds fixed, and RSiena's covariance is singular under both estimators.
  `linearendow`+`linearcreation` (co-evolution) is refused for the same reason (behavior distance).

## nwsaom: everything runs in the plugin (protocol 11, 2026-10-01)

Formerly Mata-only, now native (and threaded), certified against the Mata simulator at fixed
parameters (test_nwsaom_native.do) and against RSiena (5 seeds, cond/uncond, within 0.1 SE):
network endowment/creation (gating + RSiena's endowment/creation statistics computed in C),
structural() fixed dyads (excluded from the actor's alternatives), three-way interact()
(TERMCODE_INTERACT3), behavior endowment/creation (gating + statistics as Mata), the threaded batch
path for ratecov() (statistic and score per covariate in C) and non-directed models, estat gof for
co-evolution (before always Mata) and for endowment/creation/structural/ratecov/present/non-directed
fits (before, network gof simulated the plain model). Limits MAXTERMS 256, MAXATTR 128, MAXBEHTERMS 64.
Timings on glasgow (seed 1, before -> after): reciprocity endowment/creation 58.6 -> 0.21 s;
structural() 42.1 -> 0.17 s; three-way interaction 227 -> 0.29 s; co-evolution with quadratic
endowment/creation 118 -> 0.45 s; ratecov() two covariates 3.5 -> 0.27 s; joint + ratecov() 3.3 ->
0.21 s. Mata remains only as the fallback (no plugin for the platform, an older plugin, more than 256
effects); e(engine) shows which ran.
estat mems now simulates the fitted model the same way. Open: the multiplex command offers only
outdegree/reciprocity/crprod (all native already, not threaded). Pre-existing, found while porting (C reproduces
Mata): the behavior endowment/creation STATISTIC was the linear one for every term - fixed, see
"behavior endowment/creation splits" below.

## nwsaom two-way interactions had the wrong sign on tie withdrawals (fixed 2026-10-01)

RSiena's interaction contribution is the product of the components' contributions for creating the
tie (NetworkInteractionEffect::calculateContribution()), negated once when the tie exists
(NetworkVariable::calculateTieFlipContributions()). nwsaom multiplied the components' SIGNED
changes, so for two components a withdrawal got +c_A*c_B instead of -c_A*c_B (Mata
change_saom_interact() and the plugin's saom_eval_change(); three-way products happened to have the
right sign). On glasgow, `samex(smoke1) interact(samex#reciprocity)` then stopped in phase 3
(r(505)) while RSiena estimates it (interaction 0.07, SE 0.53), and `egox#reciprocity` was off.
Fixed in both; the plugin's interaction runs natively from protocol 10 only (older plugins: Mata).
Validated: sameX x recip and egoX x recip, 5 seeds, cond/uncond, all within 0.05 SE of RSiena.

## nwsaom covariate effects take varlists; simx() centred (changed 2026-10-01)

`samex()/nodematch()`, `egox()/nodeocov()`, `altx()/nodeicov()`, `nodecov()`, `simx()/simcov()` and
`ratecov()` took ONE variable each, which made realistic models (homophily on several attributes,
ego/alter/similarity on several covariates) impossible. Each now takes a varlist: one term and one
coefficient per variable, named `<effect>_<variable>` with the option's spelling (`samex_smoke1`);
single-variable names are unchanged. Order in e(b)/theta0(): effect types in their fixed order,
variables as listed. `ratecov(varlist)`: one coefficient per variable (w_i = exp(sum b_k x_ik)),
`ratecovcoef(numlist)`, e(ratecoefs)/e(ratecoefs_se)/... matrices (scalars e(ratecoef) etc. kept for
one variable); plugin protocol 9 passes K covariates (K = 1 is the old layout).
`interact()` resolves components by coefficient name (`samex_smoke1#transtrip`); the instance index
is stored in the interaction's td.levels, so SaomNativeSetup() finds the right term when an effect
type occurs several times (before, the first instance by type name). An effect type that occurs
several times must be named by variable (error otherwise).
`simx()` is now centred by the similarity mean over all ordered pairs, as RSiena's simX
(`rangeAndSimilarity()`); this changes the outdegree coefficient of simx models (simx's own
coefficient is unchanged). The plugin gets x/range and the mean (protocol 9; older plugins: Mata).
Plugin limits raised: MAXTERMS 32, MAXATTR 24 (larger models fall back to Mata).
Validated against RSiena (5 seeds, cond/uncond) - see nwsaom_remarks "Covariate effects for
several variables": all within 0.07 SE. (Covariates are now centred by default, see "covariates are
centred" below.)

## nwsaom conditional estimation could run forever; e(engine) (changed 2026-10-01)

A conditional simulation runs until the simulated distance reaches the observed one. When the
Robbins-Monro estimates diverge (e.g. `interact(samex#transtrip)` on glasgow, an interaction RSiena
itself rejects - "must be at least one ego or both dyadic effects"), that distance may never be
reached and the native plugin (or Mata) looped indefinitely at 100% of one core. This looked like
a silent fallback to Mata, but the model ran natively. Now, as RSiena ("Unlikely to terminate this
epoch: more than 1000000 steps"), a period is abandoned after 10^6 ministeps and nwsaom stops
with a clear error (r(498)) - within 2 seconds for that model.
To make the simulator visible: e(engine) is "native" or "mata", e(engine_why) gives the reason, and
a note follows the output when it is Mata. `antiiso` and `isolatepop` had no termcode and ran in
Mata; they are now native (protocol 9). cscripts/test_nwsaom_engine.do asserts e(engine)=="native"
for one model per effect family and path.

## nwsaom: undirected / tie-symmetric waves are a non-directed relation; default model type forcing (changed 2026-10-01)

nwsaom refused networks declared undirected ("store the data as directed ... and use symmetric").
RSiena treats a symmetric one-mode dependent network as non-directed automatically, and its default
model type for it is 2, AFORCE (`initializeFRAN()`: `z$modelType[(z$modelType == 1) & symms] <- 2`),
a unilateral-initiative type nwsaom did not have (it had only the pairwise B types 4-6, default
joint = 6). Now:
- undirected waves, or directed waves that are all tie-symmetric, are modeled as non-directed
  without `symmetric` (tie-symmetric directed waves stay directed with `reciprocity`, `waves()`,
  `behavior()` or endowment/creation effects, with a note); undirected waves mixed with asymmetric
  directed ones, and `symmetric` with asymmetric directed waves, are errors;
- `symtype()` adds `forcing` (modelType 2, AFORCE, the new default also for `symmetric`) and
  `confirmation` (3, AAGREE), and accepts RSiena's modelType numbers; `e(modeltype)` is returned.
  Both follow `NetworkVariable::makeChange()`: the directed multinomial choice, then the tie changes
  in both directions; AAGREE: a new tie only if the alter confirms, probability sigma(alter's utility),
  scores as `addAlterAgreementScores()` (RSiena's confirmation step for the no-change option, which
  changes nothing, is left out). Rate: per-actor, RSiena's. Plugin protocol 8 (native only, as the
  B types).
- Validated (glasgow 1-2 symmetrized, declared undirected; density; density + sameX(smoke1);
  cond/uncond; 5 seeds): all within 0.06 RSiena SE. RSiena's default run equals modelType 2.
- Plain `symmetric` without `symtype()` now gives forcing, not joint: results of earlier
  `symmetric` fits change unless `symtype(joint)` is added.

## Symmetric nwsaom models report the rate on RSiena's scale (changed 2026-10-01)

`e(rate)` of a `symmetric` fit used to be the per-actor rate rho (about 14.7 on glasgow waves 1-2
symmetrized). RSiena's pairwise model types give each actor the basic rate lambda and pairs the rate
lambda^2 (total rate (sum lambda_i)^2 - sum lambda_i^2, `DependentVariable::calculateRates()`), so
lambda^2 = rho/(n-1). `e(rate)` is now RSiena's: unconditional lambda = sqrt(rho/(n-1)) (0.55; SE by
the delta method), conditional the mean time at basic rate 1, nwsaom's time/(n-1) (0.30; RSiena's
`terminateFRAN()` reports the time, which is on the lambda^2 scale). `e(rate_actor)` keeps rho,
`rate0()` takes RSiena's scale, `estat gof` simulates with `e(rate_actor)` and the pairwise ministep
(`e(symtype)`). With `ratecov()` the alter is now drawn by the covariate as in RSiena (it was
uniform), with RSiena's total rate (plugin protocol 7). Validated for joint/force/agree, conditional
and unconditional, 5 seeds: all within 0.1 RSiena SE except one conditional ratecov coefficient
(0.13). RSiena's own default start for these rates is on the per-actor scale (5.6) and its
unconditional estimation then often fails; the references start the rate at 0.5.

## nwsaom covariates are centred by default; RSiena's effect names (changed 2026-10-01)

RSiena's `coCovar()` is `centered = TRUE` by default: the values are stored minus their mean
(missing values imputed by the mean), so egoX, altX, egoPlusAltX and RateX use centred values (sameX
is unaffected, simX has its own similarity mean). nwsaom used the raw values, so with an uncentred
covariate the outdegree coefficient (and the rate) differed from RSiena's although the covariate
coefficients agreed. nwsaom now centres egox/altx/nodecov/ratecov covariates (`SaomCovPrep()`),
`nocenter` keeps the raw values; `e(covmeans)` and `e(centered)` are returned and the means are
listed under the table, with RSiena's effect names for the covariate, interaction and behavior
effects (`e(rsiena_labels)`, all coefficients in e(b) order). Results of earlier fits with an
uncentred egox/altx/nodecov/ratecov variable change in outdegree (and rate/ratecov intercepts);
the coefficient names are unchanged. Validated with raw variables (glasgow, realistic model with
gwesp, transrectrip, inPopSqrt, outAct, sameX, egoX/altX/simX of alcohol1; cond/uncond, 5 seeds):
all coefficients including outdegree within 0.07 RSiena SE; RateX of two raw covariates within 0.03.

## nwsaom behavior endowment/creation splits were not RSiena's (fixed 2026-10-01)

`SaomBehaviorPatchEndowCreation()` gave every split the linear statistic (sum of decreases or
increases). RSiena (`StatisticCalculator::calculateBehaviorStatistics()`): with c = current -
overall mean and d = initial - current (0 if missing), endowment = sum over actors with d_i > 0 of
the effect's egoEndowmentStatistic, creation = -endowment(-d). linear: -d_i; quadratic:
c_i^2 - (c_i + d_i)^2; avAlt: (c_i sum_j c_j - (c_i + d_i) sum_j (c_j + d_j)) / outdeg_i; avSim:
(sum_j |c_j - c_i| - sum_j |c_j + d_j - c_i - d_i|) / n_i over non-missing alters, all on the
period's starting network. Mata and the plugin (protocol 12) now compute these. Co-evolution phase 1
also follows RSiena's rule for a non-positive derivative (repeat with more runs, then fix the
parameter): RSiena fixes avSim endowment/creation (not estimable), and so does nwsaom now. Validated
(glasgow alcohol co-evolution, 5 seeds): linear + quadratic endow/creation + avAlt within 0.03 SE;
linear + quadratic + avAlt endow/creation within 0.02 SE; avSim endow/creation fixed by both, the
rest within 0.07 SE.

## nwsaom interact(): RSiena's rule and RSiena's interaction statistic (changed 2026-10-01)

interact() accepted only "dyadic" effects, with its own list. It now follows RSiena
(`R/sienaeffects.r`): each effect is ego, dyadic or other (interactionType); two effects need an ego
effect or two dyadic ones, three effects two ego effects or only ego and dyadic ones; RSiena's
messages. Interactions RSiena accepts but its C++ cannot compute (no tieStatistic: isolateNet and
outIso unless every other effect is egoX/outdegree, and the anti-isolate effects, whose statistic
RSiena gives to the first actor) are refused. The statistic is RSiena's
`NetworkInteractionEffect::egoStatistic()`: with all effects but one C++ ego effects (egoX,
density) the product of their values and the other's egoStatistic, otherwise the sum over ties of
the product of tie statistics. Two tie statistics were wrong (only their sum over all ties was
right, so the main effects were unaffected): transtrip used in-shared partners (RSiena: two-paths
ego -> h -> alter), cycle3 all reverse two-paths (RSiena: a third). Checked against RSiena on 581
combinations: same accept/reject decision and message, and for the 119 computable ones the same
statistic (exact). New in interactions: indegpopularity, outpopularity, outactivity, inactivity,
outiso, isolatenet, isolatepop (plugin protocol 12). Note: RSiena 1.6.6 gives inActSqrt and
outPopSqrt the internal parameter 0, with which their STATISTIC uses the period's starting degrees
(outPopSqrt then without the square root) while the ministep uses current degrees; nwsaom uses the
documented statistic, which is RSiena's with `setEffect(..., parameter = 1)`.

## A stale installed plugin in PLUS shadows the repo's freshly built native plugin

`findfile()` finds `saom_sim_macos.plugin` (and the other native plugins) in the user's
`~/Library/Application Support/Stata/ado/plus/s/` ahead of `lib/plugins/<platform>/`. After
`make macos-saom_sim` a Stata test can keep running the OLD binary. Don't overwrite the user's
installed copy; copy the new plugin into a scratch dir and `adopath ++ <that dir>` at the top of the
test do-file. `lib/plugins/unix` and `lib/plugins/windows` are built by CI and are stale locally
until it runs.

## `SaomNativePluginVersion()` is a plugin CALL: never call it between a batch setup and the batch runs

The version probe runs `plugin call saomnativesim` in the single-call mode, which re-initialises state that lives in
the plugin process (before 2026-10-22 it reset the process-wide `saom_behsim_range` to 1, silently corrupting every
`behsim` statistic of a batch model set up earlier - the symptom was a co-evolution fit with `behsim` whose
outdegree and behsim estimates ran away with standard errors of 1e6 while everything else looked normal). The result
is now cached per plugin path (external Mata scalars `__saom_ver_path/_val`) and the single-call parser only sets
the range when the model has behsim. Read the version once in a context's init (`C.perok`, `C.use_batch`, ...) and
keep it in the context.

## RSiena composition change: what "exactly as RSiena" means

See DECISIONS 42 in `the development notes`. The three non-obvious rules, each found by comparing fixed-parameter simulations with
`siena07` (dev/saom_rsiena_tc_scen.R): an inactive actor stays among the alters of an active ego (ties made to it are real until the
end of the period); `setLeaversBack` runs only for periods that have join/leave events; a joiner only switches ON its start-network ties.

## A copy of the repo with its own `lib/plugins/` shadows a scratch `adopath` plugin

`SaomNativePluginPath()` finds `lib/plugins/<platform>/` next to the loaded code before it looks at the adopath, so `adopath ++ scratch`
only works for copies that have no plugin of their own. When testing a rebuilt plugin in a development copy, copy it to that copy's
`lib/plugins/macos/` too (symptom: the `TRACE ctx: ver ...` line of `NWSAOM_TRACE 4` still shows the old protocol).

## Size limits (Stata editions, native engine) and the silent Mata fallback

See `the development notes` (not tracked) and the "Size limits" section of `nwsaom_remarks.sthlp`. In short: Stata/BE matrices are 800 x 800 and a frame has at most 2,048 variables;
a dyadic covariate takes n covariate arrays in the plugin (limit 1,023); a model that exceeds a native limit runs in Mata without an error - check `e(engine)`. Fit time (plain model, k3 200): n = 1,000
10 s, 2,000 67 s, 4,000 520 s.

## A new native behavior term code must be added in TWO places in `native/saom_sim.c`

`saom_beh_stat_term()` / `saom_beh_change_term()` handle the term in the simulation, but the
LAGGED behavior statistic (end behavior on the starting network) is computed by a separate switch in
`beh_stats_on_edges()`. A code missing there gets a silent 0: the native fit then shows the new
coefficient as omitted or diverges (rc 498) while the Mata engine is fine (seen 2026-10-22 with the
`beheff()` terms, protocol 35). If native and Mata disagree for a new behavior term, check that switch first.

## Big text blobs do not go through `plugin call ..., "string"`; and a scratch run uses the plugin NEXT TO the first nwsaom.ado on the adopath

1. A BATCHSETUP argument string of about 46,000 characters (a 50 x 50 dyadic matrix as text) fails with `too many options` (rc 3598). Bulk numbers
   go in frame columns that the plugin reads after the last other column (protocol 48: `dy<k>_<j>`), the argument string carries only counts.
2. `SaomNativePluginPath()` looks for `lib/plugins/<os>/` next to the `nwsaom.ado` that `findfile` finds first. A scratch directory that has its
   own `nwsaom.ado` plus an old `lib/plugins` copy silently runs the OLD plugin (symptom: `wire-protocol argument string ran out of fields` for
   a term code the new plugin knows). Copy the rebuilt plugin into that `lib/plugins/macos/` too, or set the Mata external `__nwsaom_saom_plugin`.

## A `stata -e` run that just stops (no error, no r() code) is a plugin crash: read the macOS crash report

A segmentation fault in the plugin ends the Stata process without any message in the log. `~/Library/Logs/DiagnosticReports/StataBE-<date>.ips` has the
crashing thread with the function names (the plugin is not stripped): parse it with `json.loads(text.split("\n", 1)[1])`, take the thread with
`"triggered": true` and print its `frames[*].symbol` (seen 2026-10-23: `xt_value` called through `saom_stat_term`, a dangling pointer to a freed graph).

## A Mata `external` declaration CREATES the external

`external real scalar x` at the top of a function creates `x` (missing) if it does not exist, so a following `findexternal("x") == NULL` test is never true. To test for an optional
external use `pointer(real scalar) scalar p; p = findexternal("x")` without a declaration. (2026-10-23: `SaomBatchSlotTag()` declared `__saom_bslot`, returned "." and every
batch setup sent `BATCHSETUP.|...`, which the plugin sent to its legacy parser: the whole co-evolution suite hung at 100% CPU.) A struct used in a function must be defined EARLIER in the file.

## Do not name a new option `<existing>0` / `<existing>2`: Stata's `syntax` routes the SHORTER name to the first declared option

With `NETX0(string)` declared before `NETX(string)` in nwsaom's `syntax`, the existing option `netx(homxtransrectrip:xa)` was parsed as `netx0` (the error showed "netx0(): ... is not an effect",
two tests failed). Exact matches do not take precedence over abbreviations of an option declared earlier. Pick names that are not prefixes of each other (`ownx` for the own-network effects).

## nwsaom.ado: the `nwsaom` program is capped at ~141 KB of code ("system limit exceeded - see manual (error occurred while loading nwsaom.ado)")

UPDATE (the cause): Stata refuses to load ONE ado program larger than about 141,000 bytes of code (comments and blank lines are not counted; the same program with 6 extra trivial lines failed). The earlier text below describes the symptom; the fix is to keep `program nwsaom` under the cap by moving blocks into SEPARATE ado files / programs: the native-only network options (netx ownx dyadx tvdyadcov tvdyadcovrecip tvdyadx) now live in `_nwsaom_nx.ado`, `nwsaom_multiplex.ado`, `nwsaom_multinet.ado`, `_nwsaom_postengine.ado`, `_nwsaom_rsnotes.ado`, `_nwsaom_tconvtable.ado` are their own files. Rules learnt: (1) a program that another ado-file calls MUST have its own file (programs defined inside nwsaom.ado are evicted without a trace when Stata's 1000 KB adosize fills up); (2) Mata functions defined in an ado-file are private to that file - helpers shared between ado-files go in unw_saom.do; (3) subprograms receive the caller's locals only through options (tv covariate variable lists travel in the globals NWSAOM_TVV_<stem>), results come back in r(efflist). Check the size with: python: sum(len(l) for code lines of `program nwsaom` ...) - keep it below ~140,000.

(Old symptom notes:)

Adding a nested `if ... { ... }` / `else mata: ...` (about 10 lines) inside the big `behavior` block of `nwsaom.ado` (the `foreach __e of local netbeh` loop, ~line 3080) made the ado fail to LOAD with r(1000) once the Mata library was loaded - while the same file loaded fine in an empty Stata. It is not the file size (comments stripped: still failing) but the nesting/compile complexity of that block. Fix used: no new nested braces there; put the decision in a Mata helper (`SaomNbSim`) and call it with one `mata: st_local(...)` line. If `nwsaom` suddenly reports r(1000) at load after an edit of that region, move logic into Mata instead of adding Stata control flow. (A Mata function that uses a class must be placed AFTER the class definition in unw_saom.do, or `do unw_saom.do` fails with r(3000).)

## Copying a rebuilt plugin over a loaded one kills Stata with no message (macOS)

Symptom: `cp new.plugin scratch/lib/plugins/macos/saom_sim_macos.plugin` over an existing copy, then the next
Stata run simply ends in the middle of a command - no error, no `end of do-file` in the log. The crash report
in `~/Library/Logs/DiagnosticReports/StataBE-*.ips` says `SIGKILL (Code Signature Invalid)`.
Cause: macOS caches the code signature of the file; overwriting it in place leaves a stale signature.
Fix: `rm` the old file first, then `cp` (or `cp` to a new name and `mv`). Applies to every scratch directory used for testing.
This is a deliberate
divergence, decided 2026-10-01: the RSiena default looks like a bug (introduced in 1.6.1, commit
1155e31, which moved only outPop/inAct to default 1 and left outPop.c, outPopSqrt, outPopMore,
outPopSqrtMore, outPopThreshold, inAct.c, inActSqrt at 0) and was reported as
https://github.com/stocnet/rsiena/issues/151. Do NOT "fix" nwsaom to match RSiena's default; when
validating against RSiena, set parameter = 1 for these effects. Revisit if the issue is resolved.

## Never store a Mata object under a Stata `tempname` in nwsaom code

`nwsaom.ado` keeps each effect's term data in Mata variables named with Stata `tempname`s
(`__td_*`), referenced by pointer from `__nwsaom_last_M`. Stata reissues a tempname string once
the program that created it returns, so any later program that does
`tempname x` + `mata: \`x' = ...` (or `mata drop \`x'`) can overwrite or delete the fitted model's
term data. Symptom: the NEXT command that reads the model fails, e.g. a second `estat gof` with
`SaomNativeSetup(): 3261 non class/struct found where class/struct required`, or
`[6,6] found where scalar required` in a change function. Found 2026-10-01 in `estat gof`'s
violin-plot routine (`__gv_summ`, `__gv_stack`); fixed by using fixed names (`__nwsaom_gv_*`).
Rule: in any code that runs after an nwsaom fit, name Mata objects explicitly with a `__nwsaom_`
prefix; `tempname` is fine only for Stata matrices and scalars.

## `nwsaom multinet` with a two-mode member: embedding, RSiena index quirks, and a test-script trap

A two-mode network is embedded in the graph on ALL its nodes with the actors first (`SaomMNAddWave()`), the one-mode network gets isolated event nodes, and
structural dyads (plugin protocol 90) keep each member to its own dyads. Constants of the cross terms (average in/out degree, number of receivers) are
RSiena's own for each network (`SaomMNDeg()`), not `ties / n`. Three things cost time and are not obvious:
- Several RSiena effects index the OTHER network (or the own one) with the node number of an EVENT (divInAltIntn, JoutMix, gwespFBMix of a two-mode dependent
  network; outOutActIntn, outOutAvIntn of a one-mode network that depends on a two-mode one). siena07 reads the actor with the same number (outside the network
  when there are more events than actors). Copied (graph field `off`), and refused in the ado when events > actors.
- RSiena's `toU` takes the first step i -> q in the DEPENDENT network and q -> j in the other network, the reverse of its effect description. Found by brute force
  against siena07 targets; the other dyadic-covariate effects (sharedToU, avAltU.2M.tie) follow their description.
- `cscript` clears global macros: a do-file run by `cscript` cannot be parameterised with `global` lines written before it; read OS environment variables with
  `local x : environment NAME` after `cscript`. (The dev/saom_rsiena_mn*.do harnesses do this.)
Also: a network whose model has exactly one parameter used to start from a missing theta0 in `multinet` (the placeholder `(.)` has one column); fixed.
## `nwsaom multinet` with a behavior: state shared between the BATCHSETUP slots of the plugin

Three things looked like model bugs and were plugin / wire-format state (found while adding covariate effects of the behavior to multinet):

- The covariate arrays of the behavior covariate effects (effFrom, avXAlt, behx ..., from the `BATCHSETUP` trailer) are global staging arrays, and every `BATCHSETUP` call used to
  free the previous ones. Multinet sets up one slot per network, so the second slot freed the arrays that slot 0 (the behavior) points into. With one covariate the freed memory happened to be
  reallocated with identical values, with two covariates the fit diverged (thetaBound, rc 498). The old arrays are now kept until `BATCHCLEAN`.
- `MNOBS` (the observed statistics of the networks) did not set the thread-local similarity scale (`saom_tl_behscale`) of the terms that use the dependent behavior as covariate, so all
  similarity-type observed statistics (simdist2, simrecipx, ... and the 4000+ cross-network terms) were off while the simulated ones were right. Any new thread-local that a term reads
  has to be set in `simulate_period_mn()` AND in `mn_obs()`.
- `__nwsaom_mn_post()` receives "no starting values" as the 1 x 1 missing `(.)`. A model with exactly ONE coefficient in a network (or in the behavior) has `cols((.)) == nparam()`, so the missing
  value was taken as the starting value and the fit ended with "estimates post: matrix has missing values" (rc 504), e.g. `eff2(outdegree)` for a non-directed second network. The test is now
  `& !missing(theta)`.
## `nwsaom.ado` is at Stata's program-size limit; helper programs return values through `r()`, not `c_local`

`nwsaom.ado` stops loading with `system limit exceeded - see manual (error occurred while loading nwsaom.ado)` once the
program grows past about 207-213 KB; deleting comment lines does not help (it is the compiled program that counts), and
the failure shows up on the first `nwsaom` call, not at build time. Put new Stata-side code into a helper file
(`_nwsaom_rates.ado` is the pattern: one dispatcher program plus sub-programs, called as `_nwsaom_rates <sub>, ...`).
A `c_local` inside a sub-program lands in the *dispatcher*, not in `nwsaom` - the sub-programs are `rclass`, the dispatcher
does `return add`, and `nwsaom` reads `r(...)` right after the call.

## A two-mode fit left `__nwsaom_coev_struct` behind and corrupted the next co-evolution fit (fixed)

The structural-dyad mask of a two-mode fit lives in the Mata external `__nwsaom_coev_struct`. It was only set (never
cleared) by `nwsaom.ado`, so the next *co-evolution* fit of a different network applied the old mask (`SaomCfgStruct()`)
to its own, smaller node set: heap corruption inside `simulate_period()` and a Stata crash (exit code 133, no message).
Reproduce with a two-mode `waves()` fit followed by any `behavior()` fit in the same session. `SaomClearStruct()` now
clears both masks when a fit has no structural dyads. Any other "set only when the option is given" Mata external is the
same trap: clear it at the start of the fit.

## RSiena: `includeEffects(..., parameter =)` does nothing; the internal parameter of a rate effect needs `setEffect()`

`includeEffects(e, totExposure, ..., parameter = 3)` only warns ("argument 'parameter' has no effect"); the observed statistic
then equals the unthresholded one. Use `setEffect(e, totExposure, name = ..., type = "rate", interaction1 = ..., parameter = 3,
include = TRUE)` when validating the thresholds of the diffusion rate effects.

## Mata functions and programs defined inside an .ado file are private to that file

`mata: nwergm_estat_bridge_from_netobj(...)` called from a *different* .ado file fails with "not found" (3499): functions
(and `program`s) defined in an .ado are namespaced `file.name` and only callable from programs of the same file. Anything two
helper files need (observed-network bridge, summary functions) belongs in `unw_ergm.do` (the Mata library), as
`ergm_bridge_obs()`. Likewise `estat gof` plots call `_nwergm_gofplot`, a file of its own.

## Stata `syntax` flag options that start with "no" lose the prefix

`syntax [, NOMPLECHECK]` creates the local `mplecheck`, not `nomplecheck`; testing `"`nomplecheck'" == ""` is then always true.
Use a string option (`mplecheck(on|off)`) or a name that does not start with "no".

## The RSiena reference is version 1.6.14 now (1.6.6 numbers can silently differ)

The installed RSiena was updated from 1.6.6 to 1.6.14 (2026-10-22). Reference numbers written into the cscripts before that date
came from 1.6.6; the effect statistics (targets) of everything checked equal in both versions, with these exceptions that were
changed in the code and tests:
- `toU` (cross1(tou:matrix)): RSiena 1.6.12 swapped the two networks in `WeightedMixedTwoPathFunction`. 1.6.6 took the first step in
  the dependent network (the reverse of the name); 1.6.14 takes it in the other network. nwsaom follows 1.6.14 (plugin protocol 130);
  a plugin older than 130 would silently compute the 1.6.6 value, hence the version gate in `SaomMNRun`.
- `outPop.c`, `outPopSqrt`, `inAct.c`, `inActSqrt` and the `*More`/`Threshold` forms: the DEFAULT internal parameter became 1
  (end-of-period degrees; a value below 1 is an error for the `*More`/`Threshold` forms). Up to 1.6.6 the default 0 gave the
  START-of-period degrees in the target (outPopSqrt then did not even take the square root).
- `sienaRI` is `interpret_size` (class `siena_sizes`, a list with one object per dependent variable) and needs a sienaFit; the old
  call `sienaRI(data, theta = , effects = )` is gone. To get the importance at a given theta run siena07 with `nsub = 0` and
  `initialValue = theta`.
- A dev R script that writes data files (`saom_rsiena_r1614_dyadx.R`) is deterministic (`set.seed`), rerunning it rewrites the same CSVs.

## estat timetest vs RSiena: sienaTimeTest holds the rates fixed, score.Test does not

`sienaTimeTest()` leaves the basic rate parameters out of the test (rates known). A fixed-time-dummy model tested with `score.Test()` estimates them.
For an effect whose statistic is strongly correlated with its rate (outdegree of a nearly random network, e.g. the second network of the multinet benchmark)
the two differ a lot: net2 outdegree, Glasgow + random net2, 3 waves, seeds 1-3: sienaTimeTest 0.29/0.28/0.33, fixed-dummy score.Test 1.16/1.26/1.10,
nwsaom 1.23/1.30/1.12 (default, rates estimated) and 0.29/0.23/0.20 with `estat timetest, fixrates`. Other effects agree within noise either way.
Trap when building the RSiena reference: `includeTimeDummy()` only marks the BASE effect row (timeDummy column); `siena07` creates the dummy rows itself
(and regenerates them, so a fix set on them is lost). Setting fix/test on the marked base row tests the base effect = 0 (gave 3.14), not the dummy.
Build the fixed-dummy model by hand: a varCovar `cbind(0,1)` + `includeEffects(egoX, interaction1="dm")` (density) or
`includeInteraction(e, "<short>", "egoX", character=TRUE, interaction1=c(<eff cov>, "dm"), interaction2=c("",""), name=<dv>)`, then fix=TRUE, test=TRUE.

## One ado program cannot be larger than about 133 KB of code: "system limit exceeded - see manual" at load (2026-10-24)

After the nwsaom branches were merged, `nwsaom.ado` (208 KB on disk) failed to load with `system limit exceeded - see manual (error occurred while loading nwsaom.ado)` and nearly every test failed. The limit counts CODE, not comments: stripping all comment lines and even all indentation did not help, but each of the branches alone (up to 132.5 KB of non-comment, non-blank code, measured as the sum of the stripped line lengths) loaded and the merge (134.3 KB) did not; adding 3 KB to a loading file made it fail, 20 short lines did not. Remedy used: the internal local macros that no other file uses were renamed `__nwsaom_x` -> `__ns_x` (about 5 KB). Headroom is a few KB: **put all new Stata-side code of nwsaom into helper ado files** (`nwsaom_*.ado`, `_nwsaom_*.ado`; the main program only dispatches with a few lines, as for `meta`, `bayes`, `describe`). Measure with: sum of `len(stripped line)+1` over lines that are neither blank nor start with `//`, `*` or `/*`. nwergm.ado is at about 107 KB by the same measure.

## The .dlg files are generated; Stata rejects a long PROGRAM (r(1001)) (found 2026-10-25)

`nwsaom*.dlg` are written by `dlg/gen_dialogs.py` from `dlg/nwsaom_dialog_spec.py`; never edit them by hand (the checker fails if a
`.dlg` differs from what the generator writes). Stata's dialog engine silently refuses (`db name` returns r(1001); a missing dialog
looks the same) a `PROGRAM command` of a few hundred lines, so the generator splits the option code into sub-programs
(`put /program opt_partN` inside `beginoptions`). A dialog can be tested in batch: `capture db nwsaom_multinet` and display `_rc`
(0 = loads; run `NWCORE=... dlg/db_load_check.sh`). A dialog window cannot be opened in batch mode, so its looks must be checked by hand.

## A behavior rate effect that "hangs": runaway rate, not an infinite loop (2026-10-25)

`nwsaom ..., behavior(...) behrate(avexposure)` or `behrate(avtinexposuredist2)` seemed to run for 30+ minutes on the dialog smoke-test model. `sample` shows the
main thread inside `simulate_period` (plugin): the rate-effect coefficient and the behavior rate drift upwards in phase 2, the total rate explodes, and one period
needs 10^7+ ministeps. Not a Mata loop and not specific to the token (any behrate effect on data it does not fit). RSiena stops such fits with "thetaBound
should be set higher" because its phase-2 check covers every free parameter, the rates included (rate beh period 2 = 50.07 was the offender, seeds 1 and 2).
The coev estimator checked only the first `p` (non-rate) parameters. Now: all free parameters, and the plugin abandons a period of more than
max(1000000, 500 n) ministeps (scalar `__saom_native_stepcap`, `SaomStepCapCheck()`). Trap while debugging: `pgrep -n StataBE` can pick another session's
Stata; match on the do-file name. A Mata `exit()` inside a function that switched frames must restore the frame first (the check runs after `st_framecurrent(origframe)`).
Consequence: a coev fit whose behavior rate really exceeds 50 (as in the smoke-test data, rate 120 before) now stops with r(498), as it does in RSiena.

## `mata mlib index` does not persist: a library installed by net install can be missing from a session's Mata library list

Stata builds its list of Mata libraries (.mlib) once, early in a session; `mata mlib index` rebuilds it for the running session only
and nothing is saved. A library that `net install` put into PLUS/l/ can be absent from the list (`mata mlib query` shows `lnwcommands`
but not `lnwsaom1/lnwsaom2`). The first Mata call then stops with r(3499) "<function>() not found", and a Mata block that mentions a class of
the library stops the whole ado file with r(3000) "class ... undefined (error occurred while loading ...)". Running `mata mlib index`
by hand "fixes" it for that session only, which hid the bug in every manual test.
- Every entry program starts with `_nwsaom_libcheck` (which runs `mata mlib index` once when a library function is not visible); do not
  call Mata before it.
- A **file-scope** `mata:` block in an .ado file is compiled when the file is auto-loaded, i.e. before any program of the file runs:
  `_nwsaom_libcheck` is therefore also called at file scope (`capture quietly ...`, as in nwsaom_multinet.ado) in front of such a block.
- Reproduce: `SMOKE_STALE=1 tools/smoke_fresh_install.sh <core> <models>` in the core repo builds exactly this state (the session's Mata
  index is made while only the core library is visible). Without `SMOKE_STALE` a plain new session usually finds all libraries,
  which is why a simple "install, restart, run" test passes.
