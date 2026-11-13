# nwsaom

<!--version-->**Version 1.7.0** (released 13 November 2026)<!--/version-->

`nwsaom` fits stochastic actor-oriented models (SAOM, Snijders 2001) to longitudinal network panels declared with `nwset`: network-only and network-behavior co-evolution, one-mode, two-mode and multiplex/multi-network data, covariates, rate effects, composition change, method of moments (conditional and unconditional), maximum likelihood and Bayesian estimation, meta-analysis over several groups, joint estimation of several groups (`groups()`, with a co-evolving behavior, composition change and missing data), goodness of fit and time-heterogeneity tests. The simulation and estimation engine runs in a native plugin. A manual (PDF in `manual/`, archived at Zenodo: <https://doi.org/10.5281/zenodo.23623807>, all versions) and an inventory of the RSiena effects with their status in `docs/`.

Part of the nwcommands family of Stata packages for network analysis. nwsaom is a separate package with its
own repository; it needs the core package nwcommands but no other model package.

## Install

1. Install the core package first (Stata): `net install nwcommands, from(https://nwcommands.org/net/) replace`
   (alternative: `from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/)`). Required: nwcommands (core), version 3.23.0 or later.
2. Install this package from the core: `nwinstall, modelpkg(nwsaom)`.
   `nwinstall, everything` installs the core and all four model packages in one step; `nwinstall, all` installs the core only and `nwinstall, models` adds the model packages to it.

`nwinstall` installs the latest release (the state of the main branch). Without `nwinstall`, the package can be installed directly from GitHub:

       net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/) replace

To install a specific version, point `from()` at the release tag (GitHub serves every tag under its own raw URL), for example version 1.0.10:

       net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.7.0/) replace

`net describe nwsaom` shows the version and distribution date, `nwsaom version` the package, core and plugin versions, and `e(version)`
holds the package version in the stored results. Release history: `CHANGELOG.md`; how releases are made: `RELEASING.md`.


## Requirements

* Stata 17 or later. Tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19 (Stata/BE is enough). The Mata libraries are built with Stata 17, the oldest tested version, because a library built by a newer Stata is ignored by older ones; Stata 16 and older have not been tested and are not expected to work.
* The core nwcommands package (see above), including its Mata library `lnwcommands.mlib`.
* Platform plugins are shipped for macOS, Linux and Windows.

## Tests

The tests run against an installed or checked-out core. Point the environment variable NWCORE to the
directory of the nwcommands (core) package (the directory that contains `unw_core.do` and the core `.ado`
files) and run, from the root of this repository:

    NWCORE=/path/to/nwcommands cscripts/run_tests.sh

Each test is a do-file in `cscripts/` that prints `PASS` or `ALL OK` lines; the runner prints the number of PASS
lines and any Stata error per test. Stata is run with `-e`. Validation scripts that compare with the R
reference implementation are in `dev/`.

## Native plugin

The package ships a native Stata plugin (saom_sim.c) for macOS (universal), Linux and Windows (built by the GitHub Actions workflow `.github/workflows/build-plugins.yml`; the macOS build can be reproduced with `make -C native macos`). The Windows plugin passes the full test suite (Stata 19 MP, 9 November 2026), and the examples of the Stata Journal article give the same numbers on Windows as on macOS; the Linux plugin has not been tested on a Linux machine. Platform without a plugin: see the help file. The C source is part of the package (`net get nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main)` copies it into the current directory, with `saom_native_readme.txt` explaining the build) and is in `native/` of this repository. If the shipped plugin does not work on your computer (missing for the platform, older than the `.ado` files, does not load), `nwinstall, buildplugin(nwsaom)` compiles it there (macOS and Linux; needs a C compiler and `make`; restart Stata afterwards).

## Rebuilding the Mata library

`lib/build.do` rebuilds `lib/lnwsaom1.mlib` and `lib/lnwsaom2.mlib` from `unw_saom.do` (run it from the repository root: `NWCORE=/path/to/nwcommands StataBE -e do lib/build.do`).

## Acknowledgments

nwsaom follows the Siena project. The stochastic actor-oriented model is due to Tom Snijders, and RSiena (Ripley, Snijders, Boda, Voros, Preciado and contributors) and multiSiena (Snijders, Koskinen, Ripley) are the reference implementations: effect definitions, estimation algorithms, defaults and output are modeled on them, and every result is compared with them. nwsaom is not affiliated with or endorsed by the Siena project; errors in nwsaom are the author's.

## License

GNU General Public License version 3 (see `LICENSE`); see `NOTICE.md` for what the package is derived from and
how to cite it.

## If the Mata library does not load

The Mata library (lnwsaom1.mlib and lnwsaom2.mlib) is built with Stata 17. A library built by an older Stata loads in every later Stata; one built by a newer Stata is ignored by an older one (r(3499), "too new to be run by this version of Stata"). Build it with your own Stata: `nwinstall, buildmata(nwsaom)` (or `nwinstall, buildmata(all)` for the core and every installed package). The command fetches the Mata source from this repository, compiles it, installs the library and keeps the old file as `.prev`. It clears the data and the Mata objects in memory, so save first; restart Stata afterwards. Needs nwcommands 3.14 or later.
