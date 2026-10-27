# Changelog

All notable changes to nwsaom are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Joint estimation of several groups: option `groups(varname)` (RSiena's `sienaGroupCreate()` + `siena07()`). The actors of all groups are the rows of the data set, `varname` gives the group, the wave networks have no ties between groups; the groups need the same number of waves. One set of effect parameters for all groups, one rate per period of each group, named with RSiena's period numbering (`period1 period2 period4 ...`); `e(rates_group)`, `e(rates_period)`, `e(ngroups)`, `e(groupn)`, `e(groupvar)`. Network-only method of moments, conditional and unconditional, with actor covariates. The compiled plugin restricts the alternatives of an actor to its own group (needs the plugin of this release; there is no Mata fallback). Not yet with a behavior, time-varying covariates, composition change, missing data, `structural()`, rate covariates, non-directed or two-mode networks, dyadic covariates, `balance`, `simx()`, `interact()`, `ml`, `estat` and `nwsaom bayes`.

## [1.1.1] - 2026-10-27

Patch release in preparation (proposed 1.1.1). Works with nwcommands 3.6.0 and later (the Mata library `lnwsaom1.mlib` is rebuilt with Stata 17 against the unchanged core library). Results are unchanged: with a fixed seed every estimate, standard error and statistic is identical to the last digit to that of 1.1.0.

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
- **`nwsaom` refuses a network that holds real shares or other values than 0, 1, 10 and 11, whatever its Valued flag says.** The wave networks are judged by their tie values, as RSiena does ("entries in networks must be 0, 1, 10 or 11"). A network of shares that was saved as not valued by an earlier release used to be turned into ties silently; it now stops the command. `nwsaom multiplex` and `nwsaom multinet` check their networks in the same way (before they did not check at all). Ties that are all 1 are accepted, also in a network created with a value variable (which nwcommands 3.6.0 flags as valued and which was refused as "valued").

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
