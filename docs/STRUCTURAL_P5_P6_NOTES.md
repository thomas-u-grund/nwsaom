# Structural codes: design notes for groups (P5) and ML/Bayes (P6). Not implemented.

## State after P0-P4 (structural130)
Sets: external `__nwsaom_sset` rows (wave, i, j, v); per period A_p (fixed), B_p (end values). Plugin: `STRUCTSET|` (batch, per-period model copies `Mpd`), `STRUCTSET1|` (single call). Eligibility rule `nfree > 0` over the ACTIVE actors, end overrides before the statistics, observed targets/distances from `SaomStructTargets` (and the Coev/MB variants).

## P5: groups() with codes
- Groups glue the groups into a chain of virtual waves (`SaomGroupsWave()`); actors of other groups are inactive in a period (presence matrix) and the plugin restricts alternatives to the own group (`gfr_*`).
- Each group's codes are the codes of its own wave networks. Build the raw store per VIRTUAL wave: for virtual wave k the block of group h is at its wave min(max(k - s_h, 1), nW_h) (the same rule as the networks), the off-block cells carry no codes. Then A_p/B_p of a virtual period are those of the active group only (other groups' dyads are never alternatives anyway).
- Alternative list of an ego = own-group alternatives minus fixed dyads: intersect `gfr` and the fixed CSR in `saom_struct.c` (`sf_csr_build` builds free lists over all n; for groups build them over the group members). `nfree` counts active alters of the own group.
- Targets: patch T_p/R_p per virtual period exactly as now (the hook is `SaomStructTargets`, which already works on the chain graphs). Distances: sum over the group's block.
- `_nwsaom_structural build` refuses `groups()` today; lift after `_nwsaom_groups build` has produced the virtual chain and the codes are mapped (the hook order in nwsaom.ado: structural build BEFORE groups build; it must run AFTER, with the mapped store).
- Validation: RSiena `sienaGroupCreate` of groups with codes vs the chain, as the 1.2.0 group tests (`dev/saom_rsiena_groups.R` feature `struct`).

## P6: ML and Bayes with codes (RSiena 7.11, 12.4.1)
- Forbidden patterns (stop with RSiena's "Impossible changes"): 10 -> 1, 11 -> 0, 10 -> NA -> 1, 11 -> NA -> 0 (also across several NAs); a period without change after mapping codes to values.
- Chain (`ml/Chain.cpp`): a difference between start and end that involves a dyad structural at the start (`structural(i,j,period)`) or at the end (`structural(i,j,period+1)`) creates no ministep; the option sets exclude S_p dyads; the Poisson term counts only ministeps that are not structurally determined.
- nwsaom: `native/saom_ml.c` / `saom_bayes.c` have their own setup: add the per-period A_p lists to their option sets (reuse `sf_csr_build`), skip the dyads of A_p and of S_{p+1} in the initial chain (they carry no difference), and count `nactive` ministeps over eligible egos. The Mata checker for the forbidden patterns belongs in `_nwsaom_structural.ado` (only for `ml`/`bayes`).
- Both estimators currently refuse via `SaomStructLastOn()` (nwsaom_ml.ado, nwsaom_bayes.ado) and `_nwsaom_structural.ado` (`ml()`).
