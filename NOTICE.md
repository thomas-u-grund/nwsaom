# NOTICE

nwsaom is Copyright (C) 2026 Thomas U. Grund and is distributed under the GNU General Public License, version 3 (file `LICENSE`).

## What this package is derived from

`nwsaom` implements the stochastic actor-oriented model (Snijders 2001) and was developed from the R packages `RSiena` (model, effect definitions and their statistics, simulation, method-of-moments estimation; versions 1.6.6 and 1.6.14 were compared) and `multiSiena` (Bayesian estimation, version 1.2.40) as the reference implementations; RSiena is licensed under GPL-2 | GPL-3 and multiSiena under GPL-3, so `nwsaom` is distributed under the GNU General Public License version 3.
* **RSiena** (R package, version compared: 1.6.6 and 1.6.14). Authors: Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors. License: GPL-2 | GPL-3.
  https://cran.r-project.org/package=RSiena
  Reference: Snijders, T. A. B. (2001). The statistical evaluation of social network dynamics. Sociological Methodology 31, 361-395; Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A. and Preciado, P. (2026). Manual for RSiena. University of Oxford, Department of Statistics; Nuffield College.
* **multiSiena** (R package, version compared: 1.2.40). Authors: Snijders, T. A. B., Koskinen, J. and Ripley, R. M.. License: GPL-3.
  https://www.stats.ox.ac.uk/~snijders/siena/ (multiSiena, used for the Bayesian estimation)
  Reference: Koskinen, J. H. and Snijders, T. A. B. (2007). Bayesian inference for dynamic social network data. Journal of Statistical Planning and Inference 137, 3930-3938.

## Validation

Estimates, standard errors, rate parameters, target statistics, score tests, simulated statistics and Bayesian/maximum-likelihood posterior summaries were compared with RSiena (versions 1.6.6 and 1.6.14) and multiSiena 1.2.40 on the RSiena example data (s50, s501-s503) and on simulated and made-up data; the R scripts and data are in `dev/`, the regression tests in `cscripts/test_nwsaom_*.do` (see `cscripts/test_nwsaom_rsiena.do` and `test_nwsaom_coev_rsiena.do` for the reference numbers) and the benchmarks in `manual/` (chapter on validation and benchmark). The native plugin is certified against the Mata reference implementation.

## AI assistance (PLACEHOLDER: the owner confirms or rewrites this paragraph)

Parts of the code, tests, documentation and build tooling of this package were written with the help of an AI assistant (Claude, Anthropic) working under the direction of the author, who reviewed and is responsible for the result. [Wording to be confirmed by the author before release.]

## How to cite

Grund, T. U. (2026). nwsaom: a Stata package. Zenodo. https://doi.org/10.5281/zenodo.XXXXXXX
(placeholder DOI; the owner replaces it when the Zenodo record exists).
Please also cite the core package (Grund, T. U., nwcommands) and the work this package is derived from (see above).
