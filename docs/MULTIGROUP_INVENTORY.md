# Multi-group estimation: RSiena 1.6.14 inventory and nwsaom status

Sources read (RSiena 1.6.14 tree): `docs/manual/RSiena_Manual.tex` (multi-group section, options 1-4 for combining networks, covariate centring, constraints, GOF, ML/multi_siena),
`man/make_group_rsiena.Rd`, `R/sienaDataCreate.r` (`sienaGroupCreate`, `groupRangeAndSimilarityAndMean`, `calcBalmeanGroup`), `R/effects.r`, `R/initializeFRAN.r`,
`R/sienaTimeTest.r`, `R/sienaGOF.r`, `src/data/BehaviorLongitudinalData.cpp`, `src/siena07internals.cpp`.
Design in nwsaom: the groups are glued into one chain of "virtual waves" (see GOTCHA.md); the effects are shared, every period of every group has its own rate; the plugin restricts the
alternatives of an actor to its own group. Status = state at the last commit of branch `multigroup` (validation: RSiena 1.6.14, 10 runs against 3 runs of nwsaom, estimates, standard errors and rates; `cscripts/test_nwsaom_groups.do`).

| # | Feature | RSiena 1.6.14 behaviour | nwsaom | Status |
|---|---|---|---|---|
| 1 | Declaring groups | `sienaGroupCreate(objlist, singleOK = FALSE)`: list of data objects; at least 2 unless `singleOK`; one object is wrapped as a group of length 1 internally | `groups(var)` on a stacked data set (block-diagonal wave networks); one value is refused (an ordinary fit is the single-group case) | done |
| 2 | Same variables in all groups | same names/types of networks, behaviours, actor and dyadic covariates | by construction (one data set) | done |
| 3 | Actor sets differ | number of actors may differ; combined data have max n actors | any sizes (groups of >= 3 actors) | done |
| 4 | Different numbers of waves | allowed in the manual and `.Rd`, but RSiena 1.6.14 stops with `INTEGER() ... not a 'list'` for such a group object (checked with and without covariates) | `gwaves()`; checked against the equivalent object of two-wave groups (uncentred covariates, no group constants) | done; RSiena itself fails in 1.6.14 |
| 5 | Switching steps | step from last wave of group g to first wave of g+1 is not simulated, not counted; `periodNos` | done; rate names and `e(rates_period)` use RSiena's numbering | done |
| 6 | Basic rate parameters | one per period of each group, per dependent variable; not common across groups | done for the network and the behavior (`e(rates)`, `e(rates_beh)`) | done |
| 7 | Common rate across groups | not an option of `siena07` (only through option 1 or rate effects on group dummies) | not offered, as in RSiena; `ratecov()` with group dummies | same as RSiena |
| 8 | Effect parameters | shared; group-specific only through interactions/dummies | done (`interact()`, group indicators in `egox()`) | done |
| 9 | Actor covariate centring | overall mean over all groups | done | done |
| 10 | Dyadic covariate centring | within-group mean | done (`SaomDyadPrep()`); validated with `dyadcov()` | done |
| 11 | Covariate range / similarity mean | range over all groups; `simMean` per group (own range, own pairs; a changing covariate pooled over the group's periods) | done (`simx()`, also with `tvcov()`); validated | done |
| 12 | Balance mean | `balmean` per group (`calcBalmean()` of the group's data), `n` of the group in the effect | done (`balance`; plugin uses the size of the ego's group); validated | done |
| 13 | Other group constants | `averageIn/OutDegree`, `structmean` per group; effects with `n` | centred degree effects (`inpopc`, `outpopc`, `outactc`, `inactc`, `degplus`, `degplusc`), `ownx()` effects (average degrees, `instructeq`: structmean and the size of the group): per group, validated (RSiena 1.6.14: constants of the data objects; estimates over 10 seeds); `avdeg`, `transtriads` have no data constant; multinet cross effects: see C | done (one-mode); two-mode and multinet: C |
| 14 | Behaviour as dependent variable | range pooled; `overallMean`, `simMean`, variance per group; behaviour rate per period of each group; quadratic statistic of the centred values | done: linear, quadratic, avAlt, avSim, behavior egoX/altX/simX in the network, rate covariates of the behavior; validated | done (one behavior) |
| 15 | Several dependent networks / behaviours | allowed | `multinet`, `multiplex` and several behaviors have no `groups()` | remaining |
| 16 | Conditional estimation | default for one dependent variable without composition change | done (network only); validated | done |
| 17 | Unconditional estimation | yes | done; validated | done |
| 18 | Composition change per group | allowed | `present()` (joiners and leavers at the waves, RSiena's activeStart rule) done and validated; `joinat()`/`leaveat()` (fractional times) refused | partly: fractional times (`joinat`/`leaveat`) remaining |
| 19 | Missing data per group | as single group | `missnet()`, `missbeh()` done and validated (ties, behavior effects, behegox/behaltx with missing behavior) | done |
| 20 | Changing covariates | centring over all values of all groups | `tvcov()` done; validated | done |
| 21 | Interactions | `includeInteraction` as usual | `interact()` done; validated (egoX x reciprocity) | done |
| 22 | Rate covariates | `RateX`: one shared parameter | `ratecov()` done; validated | done |
| 23 | Behaviour-based rate effects | as single group | `behratecov()` done and validated; `behrate()` (diffusion rate effects) refused | partly |
| 24 | Constraints (`higher`, `disjoint`, `atLeastOne`) | not supported with groups | not offered | same as RSiena |
| 25 | `allowOnly` | `FALSE` recommended | nwsaom has no up/down-only restriction | n/a |
| 26 | Maximum likelihood | allowed; checks per group; `mult` per period | `ml` refused | remaining: needs the ML plugin path (saom_ml.c) with groups |
| 27 | Bayesian (`sienaBayes`, `multi_siena`) | uses the group object; rates per group | `nwsaom bayes` refuses fits with groups | remaining: separate project |
| 28 | Meta-analysis (`siena08`) | separate fits pooled | `nwsaom meta` | exists |
| 29 | Time heterogeneity (`sienaTimeTest`) | period dummies over the glued periods; group test | `estat timetest` after a grouped fit: joint, effect, per-group and per-period tests; validated against sienaTimeTest | done |
| 30 | Goodness of fit (`sienaGOF`) | per group via `groupName`; no pooled version | `estat gof` per group (`group(#)`; Liptak-combined p); | done, incl. behavior, ratecov, present; validated vs sienaGOF (network 9 means, behavior 6 means, within MC error) |
| 31 | Score tests / importance / simulate | via `sienaFit` objects | `estat score` done and validated; `estat importance`, `estat simulate`, `nwsaom simulate` work per group (network-only); importance checked against the group fitted alone (sienaRI has no group version) | partly |
| 32 | Output | rate rows numbered by period of the glued series | done | done |
| 33 | Effects object | `sienaGroupEffects`, `group`/`groupName`/`period` columns for rate rows | `e(rates_group)`, `e(rates_period)`, `e(groupn)`, `e(groupwaves)` | done |
| 34 | Two-mode networks | allowed | refused | remaining |
| 35 | Non-directed (symmetric) networks | allowed | refused | remaining |
| 36 | `structural` values | per group | `structural()` is not available for one-mode networks with `waves()` in nwsaom at all | remaining (not specific to groups) |
| 37 | Continuous behaviour | new in 1.6.14 | nwsaom has no continuous behaviour | n/a |
| 38 | Parallel estimation | by period x group | threads over replicates and periods | automatic |

## Final status: what is not implemented, and why
- Estimation: maximum likelihood and Bayesian estimation with groups (rows 26, 27): the ML and Bayes samplers run in separate plugin files with their own data layout; they need the same per-group alternatives and presence handling.
- Post-estimation: `estat gof`, `estat simulate`, `estat importance` (rows 30, 31): they simulate the whole network from the saved waves; for groups the simulation has to run on the actors of one group with that group's constants.
- Model types: two-mode and non-directed networks, several dependent networks or behaviors (rows 15, 34, 35): each has its own engine path (embedding, pairwise ministeps, multinet slots) that does not yet know the group chain.
- Row 13, established from RSiena 1.6.14: `siena07` builds one C++ data object per group (`initializeFRAN()`: `lapply(f, ...)` over the groups) and `setupOneModeGroup()` reads `balmean`, `structmean`, `averageInDegree`, `averageOutDegree` from the data object of each group; `NetworkLongitudinalData::calculateProperties()` then recomputes the average (reciprocal, squared) degrees from the group's own networks over all its waves. The group-level attributes of `sienaGroupCreate()` (`balmean`, `structmean`, `averageOutDegree`) are only used in the data report. So all of these are per group; the 1.2.0 text (pooled) was a deviation. `avDeg` and `transTriads` have no data constant. Here: the average degrees travel as per-period constants (`p1` table) or, for the `ownx()` effects, as a per-period dummy column; the plugin uses the number of actors of the ego's group in `inStructEq` and `nonPCompress`.
- `joinat()`/`leaveat()`, `behrate()`, `structural()` (rows 18, 23, 36).
