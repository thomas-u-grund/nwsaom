# Changelog

All notable changes to nwsaom are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- The help file no longer quotes plugin protocol numbers, and `nwsaom version` prints "plugin build N" instead of "plugin protocol N". (Some error messages of the Mata source still say "protocol N or later"; they are to be reworded together with the next source change.)

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
