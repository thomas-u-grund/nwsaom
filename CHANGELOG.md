# Changelog

All notable changes to nwsaom are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- **`estat simulate` and `nwsaom simulate` work after a two-mode fit of any size.** Beyond small networks (for example 24 actors and 10 events) they stopped with "options too long", r(3598). Results for networks that worked before are unchanged (same seed, same numbers).
- **Non-directed fits with `waves()` or with a behavior are simulated as non-directed models after the fit.** They now store `e(symtype)` and `e(modeltype)` and the per-actor rates (`e(rates_actor)`, one per period, or `e(rate_actor)` for a co-evolution fit with `wave1()`/`wave2()`), and `estat gof`, `estat simulate` and `estat mems` simulate them with the fit's model type at these rates, so the simulated networks are symmetric. Before, these fits were simulated with directed ministeps, and the goodness-of-fit tests and simulations were not those of the fitted model. The estimates do not change; non-directed network-only fits with `wave1()`/`wave2()` give the same results as before.

The Mata libraries are rebuilt (with Stata 17) and the plugin is updated.

## [1.5.17] - 2026-11-12

### Fixed
- **`estat mems` after a non-directed fit with `wave1()`/`wave2()`** (`symmetric` or undirected waves) simulates the fitted model: the model type of the fit (`e(symtype)`) at the per-actor rate `e(rate_actor)`, as `estat gof` and `estat simulate` do, and `macro()` receives undirected networks. Before, it simulated directed ministeps, so the simulated networks were not symmetric and the results were not those of the non-directed model. After a two-mode fit `estat mems` now stops with a message (as `estat gof`).
- **`nwsaom bayes`** names its real prior options in the note under the table and in `e(priors)`: `priormeaneta()`, `priorsigeta()`, `ratepriormean()`, `ratepriorsd()`, `gibbsrates`/`priorrate()`.
- **`nwsaom simulate`** accepts `generate()` abbreviated to `gen()`, as `estat simulate` does.
- **`nwsaom multiplex`**: `detail` lists the convergence t-ratios also without `theta01()`/`theta02()`, and the cross effects are named `net1_x_crprod` and `net2_x_crprod` with and without `theta01()`/`theta02()` (with them they were `net1_crprod` and `net2_crprod`).
- **`estat gof` after a fit with `groups()` and a behavior** tests `behavior` by default, as after a fit without groups.
- **`nwsaom meta, rates`** combines the rate of fits with `wave1()`/`wave2()` (the scalar `e(rate)` with `e(rate_se)`) as `rate_period1`; before, these fits silently added no rate rows.

## [1.5.16] - 2026-11-12

### Fixed
- **Help files checked against the code.** Abbreviations (`unconditional`, `detail`, `actormode()`), `nwsaom simulate, generate()` (must be typed in full) and `nsim()` (default 100); stored results completed for `nwsaom`, `nwsaom multinet`, `nwsaom bayes` and `estat` after `groups()`. The help of `estat` says which commands stop after `tvcov()`, several behaviors or `groups()`; `estat mems` is described as it runs (two waves via `wave1()`/`wave2()` or `waves()`; after an undirected fit it simulates directed ministeps). One "Network types" section and the common section order.
- **Help file layout.** Stored results are a proper table that wraps at the window width; the options of `nwsaom refit` have one row each; very long source lines, which lost words in the help Viewer, are broken up.
- **Messages printed by the Mata library wrap at word boundaries** (for example the error of `groups()` about ties between groups), like the notes and warnings of 1.5.15. The wording is unchanged.
- Console Stata on macOS finds the macOS plugin.
- **Help files describe the current behaviour only**: references to earlier versions and development notes are removed; deprecated commands that still work (`nwsaom multiplex`, `structural()`) are described by what they do. The help file showed the option `uncentered()` inside the text of `nocenter`.

Results do not change. The Mata libraries are rebuilt (with Stata 17); the core requirement is unchanged.

## [1.5.15] - 2026-11-11

### Fixed
- **Long notes, warnings and messages wrap at word boundaries instead of being cut in the middle of a word.** Stata breaks a displayed line that is longer than the line size at exactly that column (for example "Note: Jaccard < 0.3 in period 1->2; few ties stay, the data say little about chang" / "> e."); these messages are now SMCL paragraphs, which wrap between words. The wording is unchanged; tables are not affected. Messages printed by the Mata library (for example the error of `groups()` about ties between groups) are not yet changed. Results do not change. Tested in `cscripts/test_nwsaom_msgwrap.do` at line size 80.

## [1.5.14] - 2026-11-10

### Fixed
- **The hint to type `nwsaom refit` also follows the convergence table printed with `detail`.** After a fit that had not converged, the hint was printed only without `detail`. Results are unchanged.

## [1.5.13] - 2026-11-10

### Added
- **`nwsaom refit` after `nwsaom multinet`.** `nwsaom multinet` stores the command as typed in `e(cmdline)`, and `nwsaom refit` reruns it with `theta0()` set to all coefficients of `e(b)` (both networks and the behavior, in that order). `k3()`, `seed()` and `firstg()` given to `refit` replace those of the stored command; `cores()` is not an option of `multinet`. The result is the same as typing the estimates into `theta0()` (tested in `cscripts/test_nwsaom_refit.do`).
- When a `multinet` fit has not converged (overall ratio 0.25 or above), the output says to type `nwsaom refit`.

## [1.5.12] - 2026-11-10

### Added
- **`nwsaom refit`** runs the last fit again, starting from its estimates (RSiena's `prevAns`), without typing the estimates into `theta0()`. It reruns the stored command with `theta0()` and `behtheta0()` set to `e(b)`, `rate0()` to the rates of an unconditional network-only fit and `ratecovcoef()` to `e(ratecoefs)`; `k3()`, `seed()`, `cores()` and `firstg()` given to it replace those of the stored command. `maxruns(#)` repeats the refit until both convergence criteria are met (every |t| below 0.1, overall ratio below 0.25), at most # times; `nodisplay` shows one line per run. `e(refit_runs)` and `e(refit_converged)` report what happened. The result is the same as typing the estimates into `theta0()` with full precision (tested in `cscripts/test_nwsaom_refit.do`). Not available after `nwsaom multinet` or `nwsaom multiplex`.
- `e(cmdline)`: the command as typed.

### Changed
- When a fit has not converged, the note below the table says to type `nwsaom refit`.
- The parameters whose convergence t-ratio is too large are listed on lines of their own, broken between parameters (a long list was cut inside a name at 80 columns).
- `estat gof`: the header is on two lines and the names of the violin plots are broken between names, so that no line is cut inside a word at 80 columns; the note below the table says what "rejected" means ("P < 0.05 ...; the model does not reproduce this statistic").

### Documentation
- Help file (section "Refitting from the last estimates"), remarks and manual (Chapter 9) describe `nwsaom refit`.
- Manual (Chapters 10, 11 and 15): the note that joint estimates of several groups with missing behavior values and `behegox`/`behaltx` differ from RSiena is removed. The difference was fixed in 1.2.0 (a tie does not count in these statistics when its covariate value was missing at the start of the period, as in RSiena), and a new check with ten seeds on three groups with 20 missing values agrees with RSiena 1.6.14 within 0.04 standard errors.

## [1.5.11] - 2026-11-09

### Changed
- **Output tables: the top and bottom rules meet the column bar**, as in Stata's own tables (`{c TT}` and `{c BT}`), in `nwsaom describe`, `nwsaom meta`, `nwsaom bayes`, `estat score`, `estat timetest`, `estat simulate`, `estat gof`, `estat importance` and `estat mems`, and in the combined table of `estat gof` after a fit of several groups. The coefficient and rate tables already did.
- Display only: no estimate, test or stored result changes; in a text log the rules look as before.

## [1.5.10] - 2026-11-09

### Changed
- **Output tables, second pass of the Stata conventions of 1.5.8.** `nwsaom describe` starts with a header block (number of actors and waves, as `label = value`), its column headers are capitalised (Ties, Density, Avg. degree, Kept, Created, Dissolved; Mean, Std. dev., Missing; Up, Down, Same), and all its tables have one width. `nwsaom meta` starts with a header block (number of fits), and its four tables have one width of 78 characters (the first was 79) with `N` for the number of groups. Within `estat score` and `estat timetest` all tables have one width, and `estat simulate` uses the 12-character first column of every other table.
- Display only: no estimate, test or stored result changes.

### Documentation
- The listings of the manual show the new layout; four older coefficient tables in the manual now show the 12-character first column.

## [1.5.9] - 2026-11-09

### Changed
- The Windows plugin is compiled with optimisation (`/O2`), like those of the core and nwergm: fits on Windows take about half the time (the first example of the manual 2.0 s instead of 3.4 s, a Bayesian run 191 s instead of 436 s on the test PC). The results are the same numbers as with the previous Windows plugin; the macOS and Linux plugins are unchanged. The full test suite passes on Windows.
- Affiliation in `nwsaom.pkg`: RWTH Aachen University.

### Documentation
- The replication files of the Stata Journal article are in `replication/` (the benchmark comparison is also reported with every fit, converged or not).
- Manual and README: the Windows plugin passes the full test suite; macOS and Windows agree in every digit Stata displays.

## [1.5.8] - 2026-11-09

### Changed
- **Output tables follow Stata's conventions.** Every table of nwsaom is laid out like those of Stata's own commands: plain full-width rules above and below, a 12-character first column with a capitalised header (Effect, Statistic, Wave, Period, ...), names longer than 12 characters abbreviated as Stata does, `df` and `Prob > chi2` in tests. This covers `estat score`, `estat timetest`, `estat importance`, `estat gof` (also with groups), `estat simulate`, `estat mems`, `nwsaom describe`, `nwsaom meta` and `nwsaom bayes`. The rate tables after a fit have top and bottom rules (also after maximum likelihood and `nwsaom multinet`), and the header of a fit is set off by blank lines instead of rules.
- Titles no longer name RSiena functions (for example "Score-type test of fixed effects" instead of "... (as RSiena score.Test)"); the tests state their null hypothesis. `nwsaom bayes` labels its columns Mean, Std. dev. and the credible interval. Lines wider than 80 characters were wrapped.
- Display only: no estimate, test or stored result changes.

### Documentation
- The manual's listings show the new layout.

## [1.5.7] - 2026-11-09

### Fixed
- **The statistic of the quadratic shape effect is that of the centred behavior values, as in RSiena.** RSiena's statistic is the sum of (z - mean)^2, where mean is the overall mean of the observed behavior: its `StatisticCalculator` centres the values before `QuadraticShapeEffect` squares them. nwsaom summed the raw z^2 (except in models with several groups). The two differ by 2 * mean times the linear shape statistic plus a constant. Estimates, standard errors and the overall maximum convergence ratio do not depend on that, but since 1.5.3 Phase 2 applies RSiena's Dolby correction to each statistic separately, and that correction does: the raw statistic was almost uncorrelated with its score function (correlation 0.02 against 0.90 in RSiena on the article's 50-actor co-evolution model), so the correction did little for it and co-evolution fits with a quadratic effect converged less often than in RSiena. With the centred statistic, nwsaom and RSiena converge alike (7 of 7 seeds for that model in both). The convergence t-ratio of the quadratic effect, and `estat timetest` for it, now use the centred statistic directly; `estat timetest` converted it before.
- An audit of all behavior effects found no other statistic that disagrees with its ministep change contribution, apart from effects where RSiena itself has that form (totSim, avSimPopAlt, totSimPopAlt, avAltPop, totAltPop, quad_cc), which nwsaom keeps as in RSiena. New test: `test_nwsaom_quadcentre`.
- The plugin (protocol 154) computes the centred statistic. With an older plugin, a model with the quadratic effect runs in Mata (`nwsaom multinet` stops with a message), so that the observed and simulated statistics are always computed the same way.

### Documentation
- The help file and the manual describe the quadratic statistic correctly.
- The manual's output listings of co-evolution models were rerun with this version (chapters 3, 6, 8, 14 and 15); several fits that missed a convergence criterion with 1.5.5 now meet it. Network-only listings are unchanged.

## [1.5.6] - 2026-11-09

### Fixed
- **Starting values of co-evolution and multi-network models, as in RSiena.** Without `theta0()`, the outdegree effect of a co-evolution model started at 0 instead of RSiena's value computed from the data. A change of 1 October 2026 meant to do this, and the help text describes it, but a merge before version 1.0.0 restored the older condition that limited it to network-only models, so no release had it. `nwsaom multinet` started every effect at 0; each one-mode network's outdegree effect and the behavior's linear shape effect now start at RSiena's values (`getEffects()`), which agree with RSiena's to four digits on the article's models. A model with a two-mode network keeps 0.
- Why it matters since 1.5.3: Phase 1 estimates the coefficients of the Dolby correction of Phase 2. From a start at 0, the simulated networks are far too dense, and the coefficients came out far from those at the estimates. Phase 2 then ended farther from the solution: in the article's benchmark, fewer co-evolution and multi-network fits met the convergence criterion than in RSiena (for example 1 of 7 seeds for the 200-actor co-evolution model, against 4 of 7 for RSiena). With the new starting values, nwsaom and RSiena converge alike. Network-only models are unchanged, to the last digit.

### Documentation
- The manual (PDF) is still that of 1.5.5. Its listings of co-evolution and multi-network models come from 1.5.5; with 1.5.6 their estimates differ within simulation error.

## [1.5.5] - 2026-11-08

### Fixed
- Co-evolution with several behaviors: in the rate table of the output, the rows of standard errors of the behavior rates were labelled with the names of the rates (for example `rate_alcohol` twice), so that they looked like a second set of rates. Each rate row is now followed by its `se` row, as in the other models. `e(rates_beh_se)` is unchanged.

### Documentation
- The manual's output listings were rerun with this version, and the text that quotes them was updated; fits that miss a convergence criterion now show it, with the advice to restart. Algorithm and estimates are unchanged from 1.5.4.

## [1.5.4] - 2026-11-08

### Changed
- **Phase 1 with finite differences, as in RSiena.** When the score-function estimate of the derivative matrix still has a non-positive diagonal element for a free parameter after Phase 1 has been doubled up to at least 200 simulations, Phase 1 is run again with finite differences at the same length (RSiena's `CalculateDerivative` and `FiniteDifferences`): each simulation at the current values is repeated with each free parameter increased by a small step (0.1, or a tenth of a rate), with the same random numbers, and the step is enlarged, restarting Phase 1 at most four times, when it changes a statistic in fewer than 5 of the first 10 simulations. Only a parameter whose derivative is still not positive is then kept at its starting value. Before, the co-evolution estimator ran one longer score-function Phase 1 (at least 400 simulations) instead, and the network estimators none. The output says when this happens. Fits that do not need it are unchanged, to the last digit.
- The check that doubles Phase 1 ignores parameters fixed with `fix()`, and in co-evolution models includes the rate parameters, as in RSiena.

## [1.5.3] - 2026-11-08

The estimation algorithm now follows RSiena's defaults in every respect that a comparison with the source of RSiena 1.6.14 found to differ. The model, the statistics and the estimates are the same; the steps of the Robbins-Monro algorithm that lead to them are now RSiena's.

### Results that change (read before you re-run old analyses)
Estimates and standard errors of the method of moments change within simulation error: the same seed gives a different, equally valid path to the same estimates. On the four examples of the article, five seeds each, the largest difference between the means of `nwsaom` and RSiena is 0.073 of RSiena's standard error (1.5.2: 0.077). `nwsaom multinet` and `nwsaom multiplex` now run 1,000 Phase 3 simulations by default instead of 200, so their standard errors and convergence statistics are more precise and their fits take longer. Maximum likelihood and the Bayesian estimator are unchanged. Fits take longer, because Phase 2 now computes the scores and repeats oscillating subphases, as RSiena does: on three models of the article's benchmark, 10 percent (2 parameters), 17 percent (3) and 29 percent (10) on one thread.

### Changed
- **Noise reduction in Phase 2 (RSiena's `dolby = TRUE`, its default).** Each simulated statistic is corrected by its regression on its own score, with the coefficients estimated from the Phase 1 simulations. The correction has expectation zero, so it removes noise from the Robbins-Monro steps without changing what is estimated. Phase 2 now computes the scores of each simulation, as RSiena does.
- **A Phase 2 subphase whose steps oscillate is run again** (RSiena's `proc2subphase`): when, after at least 50 iterations, the autocorrelation of a free parameter's deviations falls below -0.8, the subphase ends and starts again from the current values with the same gain, at most four times.
- **Phase 1 grows with the model.** The default number of Phase 1 simulations is RSiena's max(50, 7 + 3p), with p the number of estimated parameters; it was 50 for every model. `k0()` still sets it.
- **Rates stay positive as in RSiena:** a step that would take a rate below zero sets it to half of its running average. Before, any step that more than halved a rate was cut back.
- Parameters fixed with `fix()`, or kept at their starting values because their derivative is not positive, no longer enter the autocorrelation criterion that ends a subphase, nor the truncation of large steps, as in RSiena.
- `nwsaom multinet` and `nwsaom multiplex`: defaults `k0()` as above and `k3(1000)`, as in RSiena (before 30 and 200).

## [1.5.2] - 2026-11-08

Faster estimation and goodness of fit. The computations are the same as in 1.5.1: compiled from the same source on the same machine, the new plugin gives every estimate, standard error and goodness-of-fit result of 1.5.1 to the last digit. The macOS plugin of the release is built on a newer build machine (see Build), whose compiler changes the last digits: relative differences below 1e-11, far below anything displayed.

### Changed
- **Faster fits with closure effects.** The compiled plugin computes the two-path counts of the ego with all other actors in one pass, and the kernel of the geometrically weighted effects from a table, instead of one count and one `exp()`/`pow()` per alternative. Affected: `gwesp()` and its variants, `gwdspff()`/`gwdspfb()`, `transrectrip`, `transmedtrip`, `transties`, `balance`; the degree and covariate effects without a fast path before (`outpopularity`, `inactivity`, `inpop`, `outactsqrt`, `outtrunc()` ..., `absdiffx()`, `egoxaltx()`, `diffx()` ..., `dyadcov()`) skip the per-alternative dispatch. Fits are 2 to 3.5 times faster with these effects (RSiena benchmark of the article: R1 3.2 to 1.3 seconds, R4 with 200 actors 56 to 16 seconds), with the same numbers.
- Less overhead per Robbins-Monro step: the number of threads was looked up with `findexternal()` on every call of the plugin, which slows down with the number of Mata globals (about 0.4 ms per step after a fit with 200 actors, a tenth of such a fit); it is now read from a Stata scalar.
- **Faster `estat gof`.** The geodesic distribution is computed with matrix products instead of a breadth-first search in interpreted Mata (the same counts), and the simulation loop runs in one Mata function instead of an ado-file loop (the same simulations). `estat gof` after a fit with 200 actors takes a quarter of the time, with the same results.

### Build
- The macOS plugin is built on the `macos-15` runners of GitHub Actions (the `macos-14` runners were retired). Its compiler gives results that differ from those of the 1.5.1 plugin in the last digits (relative differences below 1e-11; the displayed results of the article and of the test suite are unchanged).

### Changed (documentation)
- Tested with Stata 17, 18 and 19 (StataNow 19.5): the quick test suite and the examples of the article give the same results in all three. README, manual and website say so.
- The manual describes the series 1.5 (`uncentered()`, `groups()` with `netbeh()`, large joint models, `nwsaom meta` with `fix()`, `nwinstall, buildmata()`).

### Fixed
- The help file listed `uncentered(varlist)` twice.

## [1.5.1] - 2026-11-04

### Fixed
- **A model that names no variable of the data leaves the data in memory alone.** Fitting a network whose nodes have other names than the rows of the data (one class of a stacked data set, say) used to extend the data by the nodes of that network and re-sort them, so that a later fit of the whole stacked network ran on rows with missing attributes. The rows are now aligned to the network only when the command names a variable (an attribute, a behavior, a group variable, ...).

## [1.5.0] - 2026-11-03

### Added
- `uncentered(varlist)`: keep the raw values of single covariates of `egox()`, `altx()`, `samex()` and `nodecov()` (RSiena's `coCovar(..., centered = FALSE)`); `nocenter` still applies to all covariates.
- `groups()` can be combined with `netbeh()`, the network effects of the dependent behavior as the covariate (for example `netbeh(egoxaltx)`, RSiena's egoXaltX of the behavior). The behavior is centered by the mean of its own group, as RSiena does for the data objects of a joint model. Checked against `siena07` on five classes of the Dutch school data (Baerveldt; Snijders's multi-group example), largest difference of an estimate in units of its standard error 0.08.
- Documentation of `nwinstall, buildmata(nwsaom)` (nwcommands 3.14 and later): a Mata library that does not load in the user's Stata (built by a newer Stata, r(3499)) is rebuilt from the source in this repository with the Stata that runs. README and help file describe it. No change of the Mata library, the plugin or the estimators.

### Changed
- The option checks of `structural()`, `joinat()`/`leaveat()`, `missnet()` and `missbeh()` moved from `nwsaom.ado` to the new helper `_nwsaom_precheck.ado`. Stata refuses to load an ado program above a fixed size, and `nwsaom.ado` had no room left for new options. Behavior and messages are unchanged.

### Fixed
- Joint models with `groups()` and many actors (about 800 or more) and a per-actor behavior covariate such as `behfrom()` stopped with "too many options": the model description handed to the compiled plugin exceeded Stata's limit for the options of a plugin call (about 4,000 characters). It is now handed over in pieces. This needs the plugin of this release; with an older plugin only these long descriptions fail, as before.
- Joint models were slow to start: the observed statistic of `behfrom()` effects was a Mata loop of one call per actor (about 20 ms per call, once per group). It is now one vector product. A 15-group, 810-actor model started after about 4.5 minutes before and starts after about 3 seconds now; the whole fit takes about 2 minutes on a laptop.
- `nwsaom meta`: an effect that a group fitted with `fix()` has a standard error of 0 and is no longer counted as an estimate. Before, such a group raised the number of groups `n` of that effect and the degrees of freedom of its tests, although it did not enter the weights; siena08 leaves it out (NA), and now so does `nwsaom meta`. Estimates and heterogeneity statistics of the other effects are unchanged.

## [1.4.3] - 2026-11-03

Patch release: layout of one table. Works with nwcommands 3.6.0 and later. No change to the compiled plugin, the Mata libraries or any number.

### Changed
- `estat simulate` and `nwsaom simulate` print one table with a single header row (`statistic | Sim Obs`), a block per period and one line per statistic (ties, mutual dyads, transitive triples, mean behavior), and the explanation of Sim and Obs as a note below the table, as the other Stata-style tables of the package. `r(sim)`, `r(obs)` and `r(nsim)` are unchanged. The manual and the help show the new layout.

## [1.4.2] - 2026-10-31

Patch release. Works with nwcommands 3.6.0 and later; the build routine `nwinstall, buildplugin(nwsaom)` needs nwcommands 3.13.0. The compiled plugin is unchanged.

### Added
- The C source of the native plugin (`native/*.c`, the `Makefile`, StataCorp's plugin interface files and a build note `saom_native_readme.txt`) is listed in `nwsaom.pkg` as ancillary files: `net get nwsaom, from(...)` copies it; `net install` still installs the compiled plugins only.
- If the shipped plugin does not work on a computer, `nwinstall, buildplugin(nwsaom)` (nwcommands 3.13.0 or later) fetches the source, compiles it there and installs the plugin (macOS and Linux). The help file, the manual and the article say so.

### Changed
- `estat score`, `estat timetest`, `estat importance`, `estat gof` (also the combined test over groups) and `estat simulate` / `nwsaom simulate` print Stata-style tables (label column, `|` separator, rules, `Prob>chi2`, `Std. err.`). The numbers and the `r()` results are unchanged. The manual, the tutorials and the article show the new layout.
- `nwsaom meta` prints Stata-style tables (label column, `|` separator, rules; `Mean`, `Std. err.`, `P>|t|`, `P>Q`); the maximum-likelihood and Fisher results are separate tables. The numbers and `r()` results are unchanged. The manual, help file and tutorials show the new layout.

## [1.4.1] - 2026-10-31

Patch release: names and layout. Works with nwcommands 3.6.0 and later. No change to the compiled plugin or the Mata libraries.

### Added
- `waves()` (and `nwsaom describe, waves()`) takes a netlist of nwcommands: patterns such as `glasgow*`, `w1-w3` and `_all` expand in the order in which the networks were created. The help and the manual call the argument `netlist`; `wave1()`/`wave2()` stay as the older spelling for exactly two waves, and `waves(a b)` gives the same results.
- `degree` and `density`, RSiena's names of the outdegree effect (the effect is the degree of an actor in a non-directed network). The coefficient is labelled as typed; `outdegree` works as before.

### Changed
- `nwsaom describe` prints Stata-style tables (label column, `|` separator, rules); the Jaccard warning is a note below the tables.
- The dialog labels `waves()` as the way to give the waves and `wave1()`/`wave2()` as the older spelling for two waves; `degree` and `density` are flags of the baseline tab.
- The manual and the tutorials use `waves(a b)` also for two waves.

### Fixed
- `estat mems` accepted only a fit made with `wave1()`/`wave2()`; it now also accepts a fit with two waves given in `waves()` (more than two waves are still refused).

## [1.4.0] - 2026-10-30

Minor release: joint estimation of several groups with several co-evolving behaviors. Works with nwcommands 3.6.0 and later. The Mata libraries `lnwsaom1.mlib` and `lnwsaom2.mlib` are rebuilt (Stata 17); the compiled plugin of this release is needed for this feature (an older plugin gives a clear message). Fits without this feature are unchanged.

### Added
- `groups()` now works with several co-evolving behaviors (`behavior(a1 a2 a3 : ... | b1 b2 b3 : ...)`): the constants RSiena keeps per group (mean, similarity mean) are per group for every behavior, each period of each group has its own network rate and its own rate for every behavior. Needs the compiled plugin of this release (protocol 152). Not with `estat` after such a fit. Validated against `siena07` (three groups, alcohol and smoking, 10 seeds): effects and all rates agree; test `test_nwsaom_groups_mb.do`.

## [1.3.4] - 2026-10-28

Patch release (dialogs only). The Mata libraries and the plugin are unchanged.

### Added
- **Dialog box.** New dialog `db nwsaom_simulate`, opened by the button "Simulate..." under Related dialogs (new last tab "Related" of the main dialog). Its first choice is "Use the model of the last nwsaom fit" (`estat simulate`; chosen at opening when the last estimation was nwsaom, otherwise the second choice is). The second choice, "Specify the model" (`nwsaom simulate`), has fields for waves(), the effects in command syntax, theta(), behtheta(), rates(), ratesbeh() and a free field for other model options; nsim(), seed() and generate() serve both; nsim() is prefilled with 1 and generate() with sim (clear generate() to only print the summary, no networks are created; the simulate part of the postestimation dialog has the same defaults). The fields of the second choice are greyed out while the first is chosen.
- **Dialog box.** The main dialog has a drop-down "Network type" (auto / directed / undirected / two-mode), set from the wave1 network, that greys out (never hides) the options that do not apply to the type, for example reciprocity-type effects on undirected networks, symtype() on directed ones, actormode() on one-mode ones. Which options apply is taken from the effects inventory; "auto" switches everything on again. A helper `_nwsaom_dlgprep.ado` supplies the network types when a dialog opens (works with core 3.12.1).

### Changed
- **Dialog box.** The main dialog no longer has a simulate-only mode (it could not take theta()); use the new simulate dialog.
- **Dialog box.** The buttons that open the related dialogs gave a Stata error message ("Wait until Stata has completed the current command..."). They now queue the command, so the related dialog opens.
- **Dialog box.** The command built by the dialogs no longer has a blank before a closing bracket, and options that come from different parts of a dialog are always separated by a blank.
- **Dialog box.** The "append" drop-down fields (waves(), endow(), creation()) carry the option name like all other fields.

## [1.3.3] - 2026-10-28

Hotfix for the dialog boxes. The Mata libraries and the plugin are unchanged.

### Fixed
- The OK button of the main nwsaom dialog did nothing (no command, no message) since the dialogs were introduced: the interact() part of the command program used parentheses in a condition, which the dialog engine cannot evaluate, so it silently stopped building the command. The condition is rewritten without parentheses.
- New test `dlg/cmd_assembly_test.py` runs the command program of every dialog in Stata and compares the command it builds.

## [1.3.2] - 2026-10-28

Patch release. The Mata libraries and the plugin are unchanged.

### Changed
- **Dialog box.** The main dialog (`db nwsaom`) has a group "Related dialogs" on its last tab (Estimate 2) with buttons that open the dialogs for Bayesian estimation, several networks (multinet), multiplex networks, postestimation, describing the data and meta-analysis. The commands the dialogs build are unchanged.
- The main dialog has fields for `groups()` and `gwaves()` (several groups estimated together) on the last tab (Estimate 2). The postestimation dialog has a `grp()` field for `estat gof`, `estat simulate` and `estat importance` after a fit with groups.
- The dialog for `nwsaom describe` now has the `actormode()` field that the command already had.

## [1.3.1] - 2026-10-28

Patch release. Works with nwcommands 3.6.0 and later; the Mata libraries and the plugin are unchanged.

### Fixed
- With structural zeros and ones (the codes 10 and 11 in the wave networks) `nwsaom` printed one stray line with the number of fixed dyads per wave (for example 1250) before the results header. Nothing is printed now.

## [1.3.0] - 2026-10-28

Minor release: more of the joint estimation of several groups, and structural zeros and ones. Works with nwcommands 3.6.0 and later. The Mata libraries `lnwsaom1.mlib` and `lnwsaom2.mlib` are rebuilt (Stata 17); the compiled plugin of this release (protocol 151) is needed for groups and for the codes (an older plugin gives a clear message). Structural zeros and ones: RSiena's codes 10 and 11 in the wave networks. Needs the compiled plugin of this release (an older plugin gives a clear message; there is no Mata implementation of the new part). Fits that use neither the codes nor `structural()` are unchanged.

### Added
- `groups()` now also works with `joinat()`/`leaveat()` (times on the scale of the waves of the actor's group), `behrate()` and non-directed networks (`symmetric`, `symtype()`). `gwaves()` without `groups()` stops with an error (it used to run silently).
- Postestimation after a fit with `groups()`: `estat gof` (per group, option `group(#)`, the p-values of the groups are combined by the inverse-normal method; RSiena's `sienaGOF(groupName=)`), `estat simulate` and `nwsaom simulate` (per group, `group(#)`, `generate()` saves the networks of each group as `<stub>_g#`, `rates()` takes one rate per period of all groups), `estat importance` (per group). Also for fits with one behavior, `ratecov()` and `present()` (`estat importance` not with `present()`).
- **The values 10 and 11 in a wave network are structural zeros and ones, as in RSiena (1.6.14).** `nwsaom` detects them (no option). They are accepted in the networks of `wave1()`/`wave2()`/`waves()` of a directed one-mode network or a two-mode network, for any number of waves, in the method of moments (conditional and unconditional). The codes may differ from wave to wave. Rules, all checked against RSiena 1.6.14: a dyad that is structural at the start of a period keeps its start value (11 is a tie) and is not among the alternatives of the actors; a dyad that is structural at the end of a period only is free during the period and takes its end value before the statistics; the targets are those of the end network with the dyads that were structural at the start set to their start value; the observed distance (rate target, conditional estimation) leaves out the dyads that are structural or missing at either end while the conditional simulation counts every change of a dyad that is not missing (RSiena's behavior); an actor with no free alternative among the active actors has rate 0; a dyad that is missing at a wave takes the code of the previous wave. They combine with covariates, interactions, missing network data (`missnet()`), composition change (`present()`, `joinat()`/`leaveat()`), network endowment/creation, covariate rate effects and the structural rate effects.
- Validation: the observed statistics and distances agree with `siena07` exactly on five coded data sets (constant and changing sets, frozen actors, missing data, composition change, endowment/creation, a two-mode network, one co-evolving behavior), simulation at fixed parameters agrees with `siena07` within Monte Carlo error (unconditional and conditional), and 8-seed estimates agree. Test `test_nwsaom_structural_codes.do`.
- `nwsaom multinet` takes the codes in its one-mode directed networks (cross-network effects included): targets and 8-seed estimates agree with `siena07`.
- Non-directed relations (`symmetric`, all model types): the codes must be given for both directions of a dyad with the same value (otherwise an error). Fixed-parameter simulation (joint, forcing, confirmation), the rates and the targets agree with `siena07` (modelType 6, 2, 3).
- With co-evolving behaviors (one or several, also with covariate rate effects of the network) the codes work for the network (targets and estimates agree with `siena07`, 8 seeds; one behavior, and two behaviors alcohol/smoking); behaviors have no structural values in RSiena.
- Not yet with the codes (each refused with a message): `groups()`, `nwsaom multiplex`, `nwsaom multinet` with a two-mode or non-directed member or a behavior, `ml`, `nwsaom bayes`.
- Postestimation after a fit with codes: `nwsaom describe` (counts of the codes per wave, RSiena's print01Report numbers; the distance leaves out the structural dyads, the kept/created/dissolved table and the Jaccard index include them as RSiena's), `estat gof` (observed network with the start-structural dyads at their start value), `estat simulate`/`nwsaom simulate` and `estat mems` (new single-call command of the plugin), `estat importance` (structural choices excluded), `estat score`, `estat timetest`. `estat simulate` agrees with `siena07` simulations (tie counts and mutual dyads after each period).

### Changed
- The constants that RSiena keeps per group are now per group for the centred degree effects (`inpopc`, `outpopc`, `outactc`, `inactc`, `degplus`, `degplusc`: average degree of the group) and for the `ownx()` effects (average degrees, structural-equivalence mean, size of the group in `instructeq`), so these effects can be used with `groups()`. Needs the compiled plugin of this release (protocol 144).
- `structural(matname)` (a 0/1 matrix) is deprecated: it is converted to the per-wave lists of the codes 10 and 11 (a note is printed), so it now works with `waves()`, behaviors, `ratecov()`, endowment/creation and the other options; the value of a marked dyad is its value in the data and must be the same at every wave. The two-mode structure of the program itself still uses its internal mask. Removal planned for 2.0.
- The check of the tie values (`_nwsaom_chkbin`) accepts 1, 10 and 11 and names the offending value and dyad otherwise. The 1.0.10 text above that the program "does not accept 10 and 11 yet" described its state then; the comment in `_nwsaom_chkbin.ado` that quoted RSiena's message as if both were accepted is corrected.

### Not yet implemented with `groups()`
- Two-mode networks, `nwsaom multinet`/`multiplex`, several behaviors in `behavior()`, `ml`, `nwsaom bayes`, `structural()` and the structural codes 10/11 (refused with a message).

## [1.2.0] - 2026-10-27

Minor release: joint estimation of several groups. Works with nwcommands 3.6.0 and later. The Mata libraries `lnwsaom1.mlib` and `lnwsaom2.mlib` are rebuilt (Stata 17) against the unchanged core library; the compiled plugin of this release is needed for groups (an older plugin gives a clear message), and everything else works with an older plugin, only slower where the new code paths apply.

### Added
- Joint estimation of several groups: option `groups(varname)` (RSiena's `sienaGroupCreate()` + `siena07()`). The actors of all groups are the rows of the data set, `varname` gives the group, the wave networks have no ties between groups. One set of effect parameters for all groups, one rate per period of each group (also of a behavior), named with RSiena's period numbering (`period1 period2 period4 ...`); `e(rates_group)`, `e(rates_period)`, `e(ngroups)`, `e(groupn)`, `e(groupwaves)`, `e(groupvar)`. Conditional and unconditional method of moments.
- `gwaves()`: groups with different numbers of waves.
- Works with actor covariates (centred over all groups), dyadic covariates (centred within the group), changing covariates, rate covariates, interactions, composition change (`present()`), missing network and behavior data, and a co-evolving behavior (linear, quadratic, average alter, average similarity, egoX/altX/simX of the behavior, behavior rate covariates).
- The constants that RSiena keeps per group are per group here: similarity mean of a covariate, balance mean, mean/similarity mean/variance of a behavior, centring of dyadic covariates. `simx()` and `balance` therefore work with groups.
- `estat timetest` after a fit with groups: joint, effect-wise, per-group and per-period tests; `estat score` after such a fit.
- The compiled plugin restricts the alternatives of an actor to its own group and takes per-period constants (needs the plugin of this release; there is no Mata fallback for groups).
- Not yet with groups: `estat gof`/`simulate`/`importance`, `nwsaom bayes`, `ml`, `structural()`, `joinat()`/`leaveat()`, two-mode and non-directed networks, several behaviors, the centred degree effects, `avdeg`, `transtriads`.

### Fixed
- `present()`: an actor who leaves at an observation now acts in the period that starts at its last wave, as RSiena's `sienaCompositionChange()` does (RSiena: active at the START of a period; a leave event at the integer time of the wave is dropped). Before, an actor was active in a period only if present at BOTH its waves, so leavers were switched off one period too early. Joiners are unchanged. Checked against RSiena 1.6.14 in one group and in groups (10 runs each, all z-scores below 1.6).
- Network effects of the dependent behavior as covariate (`behegox`, `behaltx`, `behegoplusalt`, `behsim`) skip, in the statistic, a tie whose covariate value was missing at the start of the period (RSiena's `CovariateDependentNetworkEffect::missing()` / `tieStatistic()`); the ministep contributions use the imputed value, as before. With missing behavior values this changes the estimates of these effects slightly in one group and clearly in groups (plugin protocol 143 for the native part).

### Changed
- The checks of `symmetric`/`symtype()` live in `_nwsaom_symcheck.ado` (nwsaom.ado is at the size limit of one ado program).

### Fixed (continued)
- `nwsaom describe` on a two-mode network counted the cells within the modes (it reported an undirected network with all 32 nodes of an 18 x 14 network); it now reports the actors, events, attendances, density over the actors-by-events cells and the average number of events per actor, also in `r()`. New option `actormode()`.
- `estat simulate` and `nwsaom simulate` work after / for a two-mode model (the simulation runs on the actors-by-events network; `generate()` saves two-mode networks). A `theta()` matrix of the wrong shape gives a message instead of a conformability error.
- `nwsaom meta, rates` took the standard errors of the rates from a row that does not exist, so every rate had a missing standard error and was silently excluded; it now uses `e(rates_se)`. `r(theta)` and `r(se)` carry the names of the stored estimates (rows) and of the effects (columns).
- The refusal of `reciprocity` for a non-directed network no longer prints a second line "invalid syntax".

## [1.1.1] - 2026-10-27

Patch release. Works with nwcommands 3.6.0 and later (the Mata library `lnwsaom1.mlib` is rebuilt with Stata 17 against the unchanged core library). Results are unchanged: with a fixed seed every estimate, standard error and statistic is identical to the last digit to that of 1.1.0.

### Changed
- Faster estimation with the compiled plugin, most for two-mode networks and for fits that need many Robbins-Monro steps. The check of the plugin version (a look-up of the plugin file on the search path) was made once per step of phase 2; it is now made only where a rate covariate needs it. For the two-mode benchmark model (40 x 30, six effects) this alone halves the running time.
- Two-mode networks in the plugin: an actor's free alternatives (the other mode) are kept as a list, and the degree effects (indegpopularity, outactivity, outiso, antiiniso, antiiniso2, in3plus) are evaluated directly, so a ministep no longer loops over the whole node set and no longer goes through the general effect dispatch. The random stream is unchanged.
- The argument string of each plugin call is built with one vectorised conversion per block.
- An older plugin binary (for example a Linux or Windows file that has not yet been rebuilt) works with the new library and gives the same numbers, only more slowly.

## [1.1.0] - 2026-10-26

Minor release. Works with nwcommands 3.6.0 and later. The Mata library `lnwsaom1.mlib` is rebuilt (Stata 17) against the unchanged core library of 3.6.0.

### Added
- A visible warning when a fit runs on the slow Mata fallback instead of the compiled plugin. One line is printed once, before the estimation starts, and says why: the plugin file for the platform was not found, the installed plugin is older than the model needs, the model is outside the capacity of the plugin, or the testing switch `NWSAOM_NONATIVE` is set. The results do not change; `quietly` suppresses the line; `e(engine)` and `e(engine_why)` are set as before. Before, the fit ran without any message until the note after the table. New test `cscripts/test_nwsaom_fallbackwarn.do`.

### Changed
- The manual is relabelled "Manual for version 1.1" (it holds for all versions 1.1.x) and brought up to date: installation (`net install nwcommands, from(https://nwcommands.org/net/) replace`, then `nwinstall, all` and `nwinstall, modelpkg(nwsaom)`, or `nwinstall, everything`), Stata 17 or later (tested with 17 and 18), the rule for the tie values (0, 1, 10 and 11; real shares are refused), the engine warning, and the changes of the releases 1.0.4 to 1.0.11. The manual is archived at Zenodo under the all-versions DOI 10.5281/zenodo.23623807.
- Help text: the pages say that the Mata fallback gives a warning and how to check which engine ran.

## [1.0.11] - 2026-10-26

Patch release. Works with nwcommands 3.6.0 and later; no change of the Mata library.

### Changed
- Help text corrected: the provenance line no longer calls the package an independent reimplementation (it was developed from RSiena and is distributed under the GPL-3); references to development scripts removed from the help; the README install lines start with nwinstall. No change in code or results; the Mata libraries are unchanged.

## [1.0.10] - 2026-10-26

Patch release. Works with nwcommands 3.6.0 and later (the Mata libraries are rebuilt, with Stata 17, against the unchanged core library of 3.6.0).

### Results that change (read before you re-run old analyses)
- **`nwsaom` refuses a network that holds real shares or any value other than 0 and 1, whatever its Valued flag says.** The wave networks are judged by their tie values, as RSiena does. (RSiena also accepts the values 10 and 11 for structural zeros and ones; `nwsaom` does not accept them yet and stops with "binary ties only". Until then use `structural()`.) A network of shares that was saved as not valued by an earlier release used to be turned into ties silently; it now stops the command. `nwsaom multiplex` and `nwsaom multinet` check their networks in the same way (before they did not check at all). Ties that are all 1 are accepted, also in a network created with a value variable (which nwcommands 3.6.0 flags as valued and which was refused as "valued").

### Fixed
- With nwcommands 3.6.0 the Valued flag is set when a network is created, so a 0/1 network made with a value variable (`nwfromedge a b one`, every value 1) is valued and was refused as "valued"; see above.

### Changed
- The help file no longer quotes plugin protocol numbers, and `nwsaom version` prints "plugin build N" instead of "plugin protocol N".
- The error messages that said "native plugin (protocol N or later)" now say "a newer native plugin is needed (update nwcommands and nwsaom)".

## [1.0.9] - 2026-10-26

### Changed
- Rebuilt for nwcommands (core) 3.6.0: the Mata library libraries are compiled against the core library of 3.6.0 (built with Stata 17) and the package needs nwcommands 3.6.0 or later. No change in results.
- Install lines and the README: `nwinstall, everything` installs the core and the four model packages in one step. Supported Stata versions: 17 or later, tested with Stata 17 and 18.

## [1.0.8] - 2026-10-25

### Fixed
- The Mata libraries were built with Stata 18 and could not be used in Stata 17; they are now built with Stata 17 (works in Stata 17 and 18). Needs nwcommands 3.5.1 or later.

### Changed
- Requirements stated plainly: Stata 17 or later; tested with Stata 17 and Stata 18.


## [1.0.7] - 2026-10-25

### Fixed
- `nwsaom version` as the first command of a fresh session no longer reports the native plugin as "missing": the Mata library is indexed before the plugin path is looked up.

## [1.0.6] - 2026-10-25

### Changed
- Rebuilt for nwcommands 3.4.0; requires core 3.4.0 or later.
- Help: the ML point estimates come from phase 2 and do not change with `n3()` (only the standard errors and the convergence check do); a p-value of 0.000 in `estat gof` means none of the simulated distances reached the observed one.

### Fixed
- `nwsaom multinet` with a behavior no longer prints the effect list ("linear quadratic avalt") and three blank lines before the results table.

## [1.0.5] - 2026-10-25

### Fixed
- Works right after a fresh install: the Mata libraries are indexed automatically. Before, the first call in a new Stata session could stop with r(3499) "... not found" (or, for nwergm, "class ErgmGraph undefined") until `mata mlib index` was run by hand.

## [1.0.4] - 2026-10-25

### Changed
- Rebuilt for nwcommands 3.3.0. nwsaom now requires the core nwcommands 3.3.0 or later.
- A clear message if the core and nwsaom libraries do not match: instead of the raw error r(3021) ("class compiled at different times"), nwsaom, `nwsaom multinet` and `nwsaom describe` say that the installed core nwcommands and nwsaom were built for different versions and how to reinstall the model package (`nwinstall, models`).
- `lib/build.do` now compiles the Mata libraries against the core's finished library `lnwcommands.mlib` instead of recompiling the core source.

## [1.0.3] - 2026-10-25

### Fixed
- A co-evolution fit with a behavior rate effect (`behrate()`, for example `avexposure` or `avtinexposuredist2`) could run for hours: when the data do not fit such an effect, its coefficient and the behavior rate grow without bound, and one simulated period then needs ever more ministeps. The `thetaBound` safeguard of phase 2 (as RSiena, 50 in absolute value) now covers every free parameter, the rates and the rate-effect coefficients included, and the plugin abandons a simulated period of more than max(1000000, 500 n) ministeps. Both stop the fit within seconds with r(498) and a message; RSiena stops the same models with "thetaBound should be set higher". Test `cscripts/test_nwsaom_behratediv.do`. The Linux and Windows plugins need a rebuild (CI) for the ministep guard; the `thetaBound` part works with any plugin.
### Changed
- Dialog boxes: every option and every effect of `nwsaom` can be set from a dialog (`db nwsaom`, `db nwsaom_multinet`, `db nwsaom_bayes`, `db nwsaom_meta`, `db nwsaom_describe`, `db nwsaom_estat`); the dialogs are generated from a specification (`dlg/`).
- The version is shown at the bottom of each help file.

## [1.0.2] - 2026-10-24

### Fixed
- Behavior centring with missing behavior data (`missbeh()`): every behavior effect is now centred by the mean of the wave means of the observed values, as in RSiena (it was the pooled mean of the imputed values). Identical without missing data. New stored result `e(behmean)`; test `cscripts/test_nwsaom_behcentre.do`.

### Changed
- The convergence message prints RSiena's two criteria on separate lines (overall maximum ratio below 0.25; every t-ratio below 0.1 in absolute value), each marked met or not met, instead of one combined "good" remark.
- `tools/set_version.py` leaves the manual citation line of NOTICE.md unchanged.

## [1.0.1] - 2026-10-24

### Changed
- The help file documents the `nwsaom version` subcommand and the stored results `r(version)`, `r(date)`, `r(core)`, `r(license)` and `e(version)`.

## [1.0.0] - 2026-10-24

First release of nwsaom as a package of its own.

### Added
- Stochastic actor-oriented models (SAOM) for network and network-behavior panels declared with `nwset`: all network effect families, including two-mode, non-directed and multi-network (`nwsaom multinet`, `multiplex`) models.
- Rate effects (structural, covariate and behavior rate effects), co-evolution of networks and behavior, composition change, missing data, time-varying and dyadic covariates.
- Endowment and creation effects, interactions of effects, `structural()` effects.
- Estimators: method of moments, maximum likelihood (`nwsaom ml`) and Bayesian (`nwsaom bayes`).
- Post-estimation: `estat gof`, `estat simulate` and `nwsaom simulate`, `estat score`, `estat timetest`, `estat importance`.
- `nwsaom describe` (data description before estimation) and `nwsaom meta` (multi-group meta-analysis).
- Native C plugin (macOS, Linux, Windows) for simulation, estimation and post-estimation; Mata reference engine.
- `nwsaom version`: package, core and plugin versions; `e(version)` in the results.
- Compared with and validated against RSiena 1.6.6 and 1.6.14 and multiSiena 1.2.40.
