# Releasing nwsaom

## Master procedure: https://github.com/thomas-u-grund/nwcommands/blob/main/RELEASING.md

All release procedures and policies of the five packages (steps, order, test launch, tags, GitHub release, website update, Zenodo, lockstep with the core
Mata library, building libraries with Stata 17, known traps) are in the master document above. Follow it; this file only holds what is specific to nwsaom.
Two rules from there that are easy to miss: push the release tag by name (`git push origin vX.Y.Z`), never `git push origin main --tags`
(old local tags of this clone never existed on GitHub); and build `lib/*.mlib` with Stata 17, not 18.

## Version files and checks

- Single source of truth: `VERSION` (line 1 the version, line 2 the release date in Stata format, e.g. `25oct2026`). Semantic versioning (master B.4, C4).
- `python3 tools/set_version.py X.Y.Z [date]` writes it into every display (first line of every `.ado`, help headers and the footer of every help file, `nwsaom.pkg`, `stata.toc`,
  `README.md`, `NOTICE.md`, `CITATION.cff`, the `e(version)` / `nwsaom version` literals, the manual's `\pkgversion`/`\pkgdate`); `--check` changes nothing.
- Add `## [X.Y.Z] - YYYY-MM-DD` to `CHANGELOG.md` (Added / Changed / Fixed / Removed); its text is the GitHub release notes.
- `NWCORE=/path/to/nwcommands python3 tools/check_version.py` = version check plus the core-library hash check (below).
- Install lines: latest `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/) replace`; a given release `.../nwsaom/vX.Y.Z/`.
  `nwsaom.pkg` states `Requires nwcommands (core), version A.B.C or later`; raise it (and `README.md`) only when this release needs a newer core.

## Library and lockstep with the core

`lib/build.do` builds `lib/lnwsaom1.mlib` and `lib/lnwsaom2.mlib` from `unw_saom.do` against the core's finished `lib/lnwcommands.mlib` (class `nw_def`): run it from the repository root with the Stata 17 binary,
`NWCORE=/path/to/nwcommands "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do lib/build.do`, then `NWCORE=/path/to/nwcommands python3 tools/record_core_lib.py`
(writes `lib/core_mlib.sha256`). Whenever the core library changes, rebuild, record, test and release this package in the same batch as the core (master B.5, C3), core first.
Without that, a fresh install fails with r(3021) "class compiled at different times".

## Tests

`NWCORE=/path/to/nwcommands cscripts/run_tests.sh quick|full [plugin_dir] [jobs]` (first step: `tools/check_version.py`; each test runs in its own `-e` Stata process; set `STATA` to the Stata 17 binary, then repeat with 18).
Most tests print no PASS marker: failure is an `r()` error and a missing log is NOT RUN (master C0).
`quick` (about a minute with jobs; run after every change) covers the newer features and the ado checks; `full` adds the RSiena regression tests (35 minutes serial, 10-15 in parallel); run `full` before a MINOR or lockstep release.
`plugin_dir` puts a freshly built `saom_sim_macos.plugin` ahead of any installed copy on the adopath (a repo copy with its own `lib/plugins/` shadows it: copy the plugin there too).

## Plugin

`native/saom_sim.c` (+ `saom_ml.c`, `saom_bayes.c`) builds `saom_sim` for macOS, Windows and Linux; the workflow "Build native plugins" commits the three binaries to `lib/plugins/` on `main` after a push that touches `native/`.
`pull --rebase` and tag after the bot commit. The plugin reports its protocol number (`SAOM_NATIVE_VERSION`, scalar `__saom_native_version`); new effects are native-only and stop with a clear message on an older plugin. Protocol numbers never appear in user-facing text.
Never copy a rebuilt plugin over a loaded one (`rm` first); test through a scratch `adopath`.

## Effects inventory, counts, manual and Zenodo

- After each new effect: update the inventory (`docs/inventory_tools/update_inventory.py`) and `docs/SAOM_EFFECTS_TODO.md` (master B.11). Counts quoted publicly name the RSiena version they come from (1.6.6 for the 1,201 / 1,121 rows).
- The manual (`manual/`, PDF `manual/nwsaom_manual.pdf`) is archived at Zenodo, all-versions DOI `10.5281/zenodo.23623807`; the record of nwsaom 1.1.0 is "Manual for version 1.1" (metadata in `manual/ZENODO.md`). Per master B.10 a new Zenodo version is uploaded (by the owner) only for a new minor/major whose documented behaviour changed (then change `\manualseries` in `manual/nwsaom_manual.tex` and the citation texts);
  patch releases (1.1.x) and lockstep rebuilds get no upload: only `\pkgversion` and `\pkgdate` change (`tools/set_version.py`).
- `nwsaom.ado` and `unw_saom.do` are near Stata's per-program size limit; helper programs return values through `r()`; subcommands live in their own ado files (GOTCHA.md).
