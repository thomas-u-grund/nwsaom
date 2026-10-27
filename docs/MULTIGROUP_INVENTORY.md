# Multi-group estimation: RSiena 1.6.14 inventory and nwsaom status

Sources read (RSiena 1.6.14 tree): `docs/manual/RSiena_Manual.tex` (multi-group section, options 1-4 for combining networks, covariate centring, constraints, GOF, ML/multi_siena),
`man/make_group_rsiena.Rd`, `R/sienaDataCreate.r` (`sienaGroupCreate`, `groupRangeAndSimilarityAndMean`, `calcBalmeanGroup`), `R/effects.r`, `R/initializeFRAN.r`,
`R/sienaTimeTest.r`, `R/sienaGOF.r`, `src/data/BehaviorLongitudinalData.cpp`, `src/siena07internals.cpp`.
Design in nwsaom: the groups are glued into one chain of "virtual waves" (see GOTCHA.md); the effects are shared, every period of every group has its own rate; the plugin restricts the
alternatives of an actor to its own group. Status column = state at the last commit of branch `multigroup`; "no" entries are listed with the reason at the end.

| # | Feature | RSiena behaviour (source) | nwsaom status | Plan / reason |
|---|---|---|---|---|
| 1 | Declaring groups | `sienaGroupCreate(objlist, singleOK = FALSE)`: list of data objects; at least 2 unless `singleOK`; one object is wrapped as a group of length 1 internally | `groups(var)` on a stacked data set (block-diagonal wave networks); a single value is refused | keep; `singleOK` = an ordinary fit (no option needed) |
| 2 | Same variables in all groups | same names/types of networks, behaviours, actor and dyadic covariates | by construction (one data set) | - |
| 3 | Actor sets differ | number of actors may differ; combined data have max n actors | yes (any sizes, groups of >= 3 actors) | - |
| 4 | Equal number of waves | NOT required: waves may differ per group (a 2-wave group may be combined with more-wave groups) | v1 required equal waves | implement: `gwaves()` |
| 5 | Switching steps | step from last wave of group g to first wave of g+1 is not simulated, not counted; `periodNos` | yes | - |
| 6 | Basic rate parameters | one per period of each group (per dependent variable); NOT common across groups; period numbered over the glued series (gaps at switches) | yes (network); behaviour rates with co-evolution | behaviour: implement |
| 7 | Common rate across groups | not an option of `siena07` (only via option 1: one large network with structural zeros, or rate effects on group dummies) | not offered | RSiena has no such option; use `ratecov()` with group dummies |
| 8 | Effect parameters | shared by all groups; group-specific only via interactions/dummies | yes | - |
| 9 | Actor covariate centring | centred at the overall mean over all groups (non-missing observations) | yes | - |
| 10 | Dyadic covariate centring | centred at the WITHIN-group mean | no (refused) | implement |
| 11 | Covariate range / similarity mean | range over all groups; `simMean` pooled over the pairs within groups of all groups (`groupRangeAndSimilarityAndMean`) | simx / simcov: yes | - |
| 12 | Balance mean | `calcBalmeanGroup`: pooled over base waves of all groups with each group's own n | yes (balance, endow/creation of it) | - |
| 13 | Other group-pooled constants | `averageIn/OutDegree`, `structmean` pooled over groups; effects with n use the group's n | centred degree effects (`inpopc`, `outpopc`, `outactc`, `inactc`, `degplus`, `degplusc`), `avdeg`, `transtriads`, structural equivalence: refused | implement pooled averages where the term is in the plugin |
| 14 | Behaviour as dependent variable | range pooled (`behRange`), `simMean` pooled (`bSim`), variance pooled; `overallMean` computed per group (`BehaviorLongitudinalData`), behaviour rate per period of each group | no (refused) | implement |
| 15 | Several dependent networks / behaviours | allowed | multinet / multiplex have no `groups()` | list as remaining |
| 16 | Conditional estimation | default for one dependent variable, no composition change; recommended for groups | yes | - |
| 17 | Unconditional estimation | yes | yes | - |
| 18 | Composition change per group | allowed (`sienaCompositionChange` per data object; conditional estimation off) | no (refused) | implement via `present()` |
| 19 | Missing data per group | as single group; imputation per group | no (refused) | implement |
| 20 | Changing covariates | all groups must give changing covariates if one does; centring over all values of all groups | no (refused) | implement |
| 21 | Interactions | `includeInteraction` works as usual, group dummies as covariates | `interact()` refused | implement |
| 22 | Rate covariates | `RateX` effects: one shared parameter | refused | implement |
| 23 | Behaviour-based rate effects | as single group | refused | implement with behaviour |
| 24 | Constraints (`higher`, `disjoint`, `atLeastOne`) | NOT supported with groups | not offered | same as RSiena |
| 25 | `allowOnly` | recommended `FALSE` for groups (up-only/down-only change constrains the simulation) | nwsaom has no up/down-only restriction | - |
| 26 | Maximum likelihood | allowed; checks impossible changes and zero-change periods per group; `mult` per period of each group | refused (`ml`) | feasible only through `nwsaom_ml` plugin path; see remaining |
| 27 | Bayesian (`sienaBayes` / `multi_siena`) | uses the group object; rates per group, selected parameters random | `nwsaom bayes` works on one fitted model | remaining (separate project) |
| 28 | Meta-analysis (`siena08`) | separate fits pooled | `nwsaom meta` | exists |
| 29 | Time heterogeneity (`sienaTimeTest`) | group object: additional `GroupTest` by group; period dummies over the glued periods | `estat timetest` refused after a grouped fit | implement |
| 30 | Goodness of fit (`sienaGOF`) | per group via `groupName`; no pooled version | `estat gof` refused | implement `group(#)` |
| 31 | Score tests / `estat score`, `importance`, `simulate` | via `sienaFit` objects / `sienaTimeTest` | refused after a grouped fit | implement where possible |
| 32 | Output | rate rows numbered by period of the glued series; one table of all parameters | yes; plus `e(rates_group)`, `e(rates_period)`, `e(groupn)` | - |
| 33 | Effects object | `sienaGroupEffects` from the first data object; `group`/`groupName`/`period` columns for rate rows | `e(rates_group)`, `e(rates_period)` | - |
| 34 | Two-mode networks | allowed | refused | remaining |
| 35 | Non-directed (symmetric) networks | allowed; `symmetric` attribute must agree | refused | remaining |
| 36 | `structural` values | per group, `structural` group attribute | refused | implement |
| 37 | Continuous behaviour | new in 1.6.14, scale parameter per period | nwsaom has no continuous behaviour | not applicable |
| 38 | Parallel estimation | by period x group | nwsaom threads over periods x replicates | automatic |

Final status of every row is in the section "Final status" at the end of this file (updated when the work of the round is complete).
