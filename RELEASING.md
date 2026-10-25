# Releasing nwsaom

Versions follow semantic versioning, MAJOR.MINOR.PATCH: MAJOR for incompatible changes of syntax or results, MINOR for new
features that keep old do-files working, PATCH for bug fixes. The single source of truth is the file `VERSION` (line 1 the
version, line 2 the release date in Stata format, e.g. `24oct2026`).

1. Edit `VERSION`, or run `python3 tools/set_version.py X.Y.Z [date]` (this writes `VERSION` and updates every display: the
   first line of every .ado, the .sthlp headers and the version line at the bottom of every help file, `nwsaom.pkg`, `stata.toc`, README, NOTICE,
   CITATION.cff, the `e(version)`/`nwsaom version` literals).
2. Add a section `## [X.Y.Z] - YYYY-MM-DD` to `CHANGELOG.md` (Added / Changed / Fixed / Removed).
3. Run `python3 tools/check_version.py` (also the first step of `cscripts/run_tests.sh` and of CI) and the tests
   (`NWCORE=/path/to/nwcommands cscripts/run_tests.sh`).
4. Commit: `git commit -am "Release X.Y.Z"`.
5. Tag: `git tag -a vX.Y.Z -m "nwsaom X.Y.Z"`.
6. Push: `git push origin main --tags` (let the "Build native plugins" workflow finish and `git pull --rebase` before the next push, if the package has one).
7. Release: `gh release create vX.Y.Z --title "nwsaom X.Y.Z" --notes-file <excerpt of CHANGELOG>`.

Users install the latest release with `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/) replace`
and a specific one with `.../nwsaom/vX.Y.Z/`.

## Whenever the core library changes

The Mata libraries of this package (`lib/lnwsaom1.mlib`, `lib/lnwsaom2.mlib`) are compiled against the core's `lnwcommands.mlib`
(class `nw_def`). If the core library is rebuilt for a new core release and this package is not, a fresh install fails with
r(3021) "class compiled at different times". So for every core release that changes its Mata library:

1. Build the core library first (`do lib/build.do` in the core) and note the core version.
2. Rebuild these libraries against that exact core state, from the root of this repository, with a scratch PLUS folder so that no
   installed copy is seen: `NWCORE=/path/to/nwcommands StataBE -e do lib/build.do`. `NWCORE` must be the core checkout whose
   `lib/lnwcommands.mlib` is the final one of the core release.
3. Run `python3 tools/set_version.py`, the tests (above) and release this package in lockstep with the core: raise the "requires core
   X.Y.Z or later" statement in `README.md` and `nwsaom.pkg`, add a CHANGELOG entry, tag and release after the core release is out.

## Build the Mata libraries with the oldest supported Stata

Build every Mata library of this package with Stata 17, the OLDEST supported Stata, never with a newer one: a library built by a newer
Stata is ignored by older Stata versions (all functions "not found", r(3499)). `lib/build.do` stops when `c(stata_version)` is higher
than 17 (`NW_ALLOW_NEWER_STATA=1` overrides, for experiments only). The full rule is in the RELEASING.md of the core repository
(nwcommands).

## Lockstep check with the core Mata library

The Mata libraries of this package are compiled against the core's `lib/lnwcommands.mlib`. After every build of the libraries
(`lib/build.do`) record which core library they were built against:

    NWCORE=/path/to/nwcommands python3 tools/record_core_lib.py      # writes lib/core_mlib.sha256 (sha256 of the core library)

`tools/check_version.py` compares `lib/core_mlib.sha256` with `$NWCORE/lib/lnwcommands.mlib` when `NWCORE` is set and fails with
"the core Mata library changed since this package's libraries were built: run lib/build.do and release in step" when they differ.
Run `NWCORE=/path/to/nwcommands python3 tools/check_version.py` before every release (it is the first step of the tests when NWCORE is set).
