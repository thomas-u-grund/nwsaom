# Changelog

All notable changes to nwsaom are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

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
