# Zenodo record for the nwsaom manual, Manual for version 1.1

Metadata for ONE new version of the existing Zenodo record. Nothing has been uploaded.

**Record.** All-versions ("Cite all versions") DOI `10.5281/zenodo.23623807`; the last published version is record 23626696 (version field "1.0.2", file labelled "Manual for version 1.0.3", published 2026-10-24). On zenodo.org open the record 10.5281/zenodo.23623807, choose **New version**, replace the file, and change the fields below. The all-versions DOI does not change; the DOI printed on the title page of the PDF (`\manualdoi` in `nwsaom_manual.tex`) and in all citation texts is this all-versions DOI.

**Labelling (master RELEASING.md B.10).** The manual is labelled by the minor series ("Manual for version 1.1", valid for all 1.1.x, `\manualseries`). The exact package version of the listings (1.1.0) is on the title page (`\pkgversion`) and in the Zenodo version field. This is the one new Zenodo version of the 1.1 series: for patch releases (1.1.1, ...) nothing is uploaded; only `\pkgversion`/`\pkgdate` change (`tools/set_version.py`) and the PDF is committed. A new version again only for 1.2 or 2.0 with changed documented behaviour (then change `\manualseries`).

## Metadata (mirrored from record 23626696, read-only on zenodo.org, 2026-10-26)

**Resource type.** Publication, sub-type Software documentation (as the existing record).

**Title.** nwsaom: Stochastic actor-oriented models in Stata. Manual for version 1.1

**Version.** 1.1.0

**Publication date.** 2026-10-26 (or the day of the upload)

**Creators.** Grund, Thomas; ORCID 0000-0001-6751-5429 (as in the existing record; no affiliation is given there; add RWTH Aachen University if wanted, the title page of the PDF names it).

**License.** Creative Commons Attribution 4.0 International (CC-BY-4.0), as the existing record. The code stays under GPL-3.0-only.

**Access.** Open.

**Description** (HTML, three paragraphs):

> <p>This is the manual for nwsaom, series 1.1 (listings checked with version 1.1.0), a Stata package that estimates stochastic actor-oriented models (SAOMs, also called Siena models) for panel network data. nwsaom follows the R package RSiena: it uses the same model, effects, method-of-moments algorithm, defaults and output, and it adds maximum-likelihood and Bayesian estimation following multiSiena. Everything runs inside Stata, with the simulations in a compiled, multithreaded plugin.</p>
> <p>The manual describes the installation, the syntax and every option, the effect library with its RSiena names (&gt; 90% of the effects of RSiena's effects table that fall within what nwsaom covers), network-behavior co-evolution, undirected and two-mode networks, several networks and behaviors, rate effects, missing data and composition change, goodness of fit, score tests, tests for time heterogeneity, effect importance and meta-analysis of separate groups. It documents the validation against RSiena, the behaviors of RSiena that nwsaom reproduces, the stored results, and worked examples with the Glasgow friendship data. This version describes the rule that tie values must be 0 or 1 (real shares are refused, as in RSiena), the warning that nwsaom prints when it has to use the slow Mata fallback instead of the compiled plugin, the installation with nwinstall, and the requirements (Stata 17 or later, tested with Stata 17 and 18; nwcommands 3.6.0 or later).</p>
> <p>nwsaom requires the nwcommands core package. It is meant for researchers who work in Stata or prefer it to R. It is not a replacement for RSiena, which remains the reference implementation and the more complete program, and it is not affiliated with or endorsed by the Siena project. The software is free software under the GNU General Public License, version 3. The package and the manual were prepared with the help of an AI coding assistant working under the author's direction, as stated in the manual. Please cite this manual (all-versions DOI) and report the exact version printed by nwsaom version.</p>

**Keywords.** Stata; nwcommands; nwsaom; stochastic actor-oriented model; SAOM; Siena; RSiena; social network analysis; longitudinal network data; network dynamics; co-evolution of networks and behavior; multiSiena

**Language.** English

**Related identifiers.**

| Relation | Identifier | Type |
|---|---|---|
| Is supplement to | https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.1.0 | URL |
| Is supplement to | https://github.com/thomas-u-grund/nwsaom | URL |
| Requires | https://github.com/thomas-u-grund/nwcommands | URL |
| Is related to | 10.5281/zenodo.23661332 (manual of nwergm, reserved DOI, if published by then) | DOI |

Check the first row only after the GitHub release v1.1.0 exists; drop the last row if the nwergm record is not published. Zenodo adds "is new version of" for the earlier versions by itself.

**Other fields.** Funding: none. Communities: none.

## Steps for the owner (after the release v1.1.0 is on GitHub)

1. On zenodo.org open 10.5281/zenodo.23623807, **New version**; delete the old file, upload `manual/nwsaom_manual.pdf` (also kept as `nwsaom_manual_1.1.pdf` in the SJ folder); fill the fields above; publish.
2. Check that the all-versions DOI on the record page is still 10.5281/zenodo.23623807 (the new version gets its own version DOI, not used in any citation text).
3. Nothing else changes: the PDF, `CITATION.cff`, `NOTICE.md`, `README.md` and the website already carry the all-versions DOI and the label "Manual for version 1.1".
