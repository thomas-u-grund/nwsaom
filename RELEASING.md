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
