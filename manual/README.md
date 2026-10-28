# The nwsaom manual

`nwsaom_manual.pdf` is the user manual and reference of nwsaom (title "Manual", no version number in the citation). The LaTeX source is `nwsaom_manual.tex` with one file per chapter (`ch*.tex`, `app_*.tex`). `gen_*.tex` and `build_effects.py` generate the effect tables and counts from the effects inventory; do not edit the `gen_*.tex` files by hand.

## Bumping the version

The manual's title and citation carry no version number; the title page states the series it describes (`\manualseries`, valid for 1.3.x). The exact version and date of the release that produced the listings are two more macros in `nwsaom_manual.tex` (written by `tools/set_version.py`):

    \newcommand{\manualseries}{1.3}
    \newcommand{\pkgversion}{1.2.0}
    \newcommand{\pkgdate}{26 October 2026}

Change `\manualseries` only for a new minor or major release whose documented behaviour changed (and then upload a new Zenodo version, see `ZENODO.md`). For a patch release only the last two lines change. The tag in the installation example of `ch01_intro.tex` (`nwsaom/v1.1.0/`, inside a listing) is the only other place with the exact number.

## Building

    pdflatex nwsaom_manual.tex   # three passes
    
The listings are pasted from runs of the Glasgow examples (and abridged by hand in places). The PDF is committed with `git add -f manual/nwsaom_manual.pdf` (the LaTeX build files are ignored).

## The DOI

`\manualdoi` holds 10.5281/zenodo.23623807, the DOI of all versions of the Zenodo record. `ZENODO.md` holds the metadata of the record and the steps for the upload.
