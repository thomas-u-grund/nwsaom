# Replication files for "nwsaom: Stochastic actor-oriented models in Stata"

This folder lets a reader check every comparison in the article between `nwsaom` (Stata) and RSiena (R) on their own computer, and reproduce the article's listings, tables and figures. Both programs read the same data. The R scripts are plain RSiena calls with default settings, and each Stata do-file fits the same models with `nwsaom`. The results of our own runs are in `results/`, so that a reader can compare a fresh run with what the article reports.

All commands below are run from this folder, the folder that holds this README. The scripts use relative paths only.

## Software

| Program | Version used | How to install |
|---|---|---|
| R | 4.6.0 | <https://cran.r-project.org> |
| RSiena | 1.6.14 | `Rscript R/00_install.R` |
| Stata | 17 (the listings of the examples) and 18 BE (comparisons and benchmark); the article's examples give the same numbers under 18 and 19 | |
| nwcommands | 3.17.2 | see below |
| nwsaom | 1.5.11 | see below |
| Python | 3, standard library only | for the scripts in `tools/` |

RSiena 1.6.14 is newer than the version on CRAN (1.6.6). `R/00_install.R` installs it from its release tag in the RSiena repository on GitHub, which needs a C++ compiler. The script also installs ggplot2 4.0.3, jsonlite 2.0.0 and scales 1.4.0, which are needed for the benchmark figure only. On 8 November 2026, RSiena 1.6.14 was the newest release, and the development branch of the repository carried the same version, so there was no newer RSiena to run the comparisons against.

In Stata, install the versions used in the article from their release tags on GitHub:

```
. net install nwcommands, replace from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.17.2/)
. nwinstall, all from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.17.2)
. nwinstall, modelpkg(nwsaom) release(v1.5.11)
```

On 9 November 2026 we ran these three commands under Stata 18 with an empty PLUS folder; they installed nwsaom 1.5.11 with its compiled plugin (build 154), and `stata/01_check_data.do` then ran on the installed packages.

Every do-file runs `stata/setup.do` first. By default, `setup.do` uses these installed packages. To use git checkouts of the two packages instead, set the globals `NWCORE` and `NWSAOM` to the two trees before running a do-file. The optional global `NWPLUS` names an empty folder to use as PLUS, so that no other installed copy interferes. `setup.do` prints the version of `nwsaom` that it found.

Our runs were made on an Apple M5 Pro (18 cores) under macOS 26.5.1.

## What reproduces what

| Article | R | Stata | Result files | What to expect |
|---|---|---|---|---|
| Data: the CSV files equal both programs' copies | `R/01_check_data.R` | `stata/01_check_data.do` | | "All data identical." |
| Listings of Sections 5.2 to 5.8, 6 and the appendix; Figures 3 and 5 | | `article/gen_logs.do` | `results/article/glasgow_*.log`, `extras.log`, `extras2.log`, the two graphs | identical numbers on the same platform |
| Figure 1, the Glasgow networks | | `article/plot_glasgow.do` | `results/article/fig_glasgow_waves.pdf` | the same figure |
| Table 3, the examples against RSiena (Section 5.7) | `R/02_examples.R` | `stata/02_examples.do` | `results/examples/rs_examples.csv`, `val_examples.csv`, `rs_gof.txt` | see "How close"; largest difference 0.044 s.e. (`tools/compare_examples.py`) |
| Listings of Section 5.9, several groups | | `article/groups_joint.do`, `groups_meta_vs_joint.do`, `groups_behavior_unequal.do`, `groups_timetest_score.do` | `results/article/groups_*.log` | identical numbers on the same platform |
| Table 4 and the agreement paragraph of Section 5.9 | `R/03_groups_ex1.R`, `04_groups_ex3.R`, `05_groups_ex4.R`, then `06_groups_compare.R` | `stata/03_groups_ex1.do`, `04_groups_ex3.do`, `05_groups_ex4.do` | `results/groups/ex*_nwsaom.csv`, `ex*_rsiena.csv`, `compare.log` | largest difference of an effect 0.004 (four classes), 0.01 (co-evolution) and 0.005 (unequal waves); time test 37.5 against 38.7 |
| Section 6.3 and Table 5, the effect counts | | | `results/coverage/SAOM_EFFECTS_INVENTORY.csv` (`tools/count_effects.py`) | 1,201 rows: 1,058 implemented fully, 1 in part (`unspInt`), 142 not offered (80 of them not planned) |
| Table 6, Table 7, Figure 6 and the numbers of Section 7.2 | `R/07_bench_one.R`, `R/08_bench_figures.R` | `stata/07_bench_one.do` | `results/benchmark/raw/*.csv` (one row per fit), `results/benchmark/tables/`, `results/benchmark/figures/` | identical tables and figure from the raw files; a re-run: see "How close" |
| Section 7.1, the Mata engine against the plugin | | `stata/09_mata_engine.do` | `results/benchmark/mata_engine.csv` | about 51 seconds (40 to 53) against 0.22 seconds per fit on our machine |
| Section 7.2, the profile of RSiena | `R/09_profile.R` | | `results/profile/rsiena_profile.txt` | R code 17 to 22 percent of the time for N1 and 8 to 12 percent for N2 over three runs; more in the first fit of a new R session |
| Appendix, maximum likelihood | `R/10_ml.R` | `article/gen_logs.do` (`extras.log`) | `results/ml/rsiena_ml.txt` | RSiena: outdegree −2.66, −2.63, −2.65; reciprocity 2.22, 2.19, 2.22; transitive triplets 0.71, 0.70, 0.70 |
| How close: a seed reproduces within one session | | `stata/12_same_seed.do` | | "Same seed, same session: identical estimates and standard errors." |
| Section 6, appendix: the times of maximum likelihood and the Bayesian run | `R/10_ml.R` (prints the time of each fit) | `stata/13_ml_bayes_time.do` | | on our machine: `nwsaom` ML 47 seconds per fit, RSiena ML 159 to 172 seconds, Bayesian run 99 to 105 seconds |
| Manual, Appendix D: the cost of a Phase 2 step | | `stata/14_phase_cost.do` | | on our machine: a batched simulation 82 (N1) and 231 (N2) microseconds, a Phase 2 step at most 131 and 310 |
| Manual, Appendix D: simulations per phase | `R/11_phase_counts.R` | `stata/11_phase_counts.do` | `results/phases/rsiena_phases.csv`, `nwsaom_phases.csv` | Phases 1 and 3 equal; Phase 2 within the seed-to-seed range; RSiena repeats subphases on R1 only |
| Manual, Appendix D: the same simulation at fixed parameters | `R/15_fixed_sim.R` (first) | `stata/15_fixed_sim.do` | `results/fixedsim/theta.csv`, `rsiena_fixedsim.csv`, `nwsaom_fixedsim.csv` | t-ratios of every statistic within 0.07 of zero in both programs; the programs differ by at most 0.06 |
| Manual, Appendix D: time for a fixed workload | `R/16_fixed_workload.R` | `stata/16_fixed_workload.do` | `results/fixedsim/rsiena_workload.csv`, `nwsaom_workload.csv` | on our machine: RSiena 387, 965 and 2,208 microseconds per simulation (N1, N2, R1), `nwsaom` 83, 239 and 454 |

To check the data and build Table 3:

```
stata -e do stata/01_check_data.do         # "stata" is your Stata executable; seconds
Rscript R/01_check_data.R
stata -e do stata/02_examples.do           # about 1 minute
Rscript R/02_examples.R                    # about 1 minute
python3 tools/compare_examples.py          # prints every parameter of the four examples, both programs
```

To reproduce the listings and figures of the article (about 5 minutes, two of them for the Bayesian run):

```
stata -e do article/gen_logs.do
stata -e do article/plot_glasgow.do
stata -e do article/groups_joint.do        # and the three other groups_*.do files
```

The logs in `results/article` were made under Stata 17 with the files of `nwsaom` 1.5.11 (those of the tag) on the ado-path. In `extras.log`, the location of the plugin that `nwsaom version` prints is shortened to `<nwsaom>`.

With the Stata Journal's `sjlog` installed, `gen_logs.do` writes the listings as `.log.tex` files, as in the article; without it, it writes plain `.log` files with the same content.

For Table 4 (about 2 minutes in Stata and 2 minutes in R):

```
stata -e do stata/03_groups_ex1.do
stata -e do stata/04_groups_ex3.do
stata -e do stata/05_groups_ex4.do
Rscript R/03_groups_ex1.R
Rscript R/04_groups_ex3.R
Rscript R/05_groups_ex4.R
Rscript R/06_groups_compare.R              # writes results/groups/compare.log
```

RSiena 1.6.14 stops with an error for groups with different numbers of waves. `R/04_groups_ex3.R` explains the equivalent RSiena object that it uses for that model instead.

To rebuild the benchmark tables and figure from the raw results of the article:

```
python3 tools/build_tables.py              # writes results/benchmark/tables
Rscript R/08_bench_figures.R               # writes results/benchmark/figures
```

To repeat the benchmark fits (macOS or Linux; needs perl, which both provide):

```
python3 tools/run_benchmark.py main  --stata "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"
python3 tools/run_benchmark.py extra --stata "..."
python3 tools/run_benchmark.py cores --stata "..."
python3 tools/build_tables.py results/benchmark/raw_new results/benchmark/tables_new
Rscript R/08_bench_figures.R results/benchmark/tables_new results/benchmark/figures_new
```

The runner never writes the article's raw files; it writes to `results/benchmark/raw_new`. It starts every fit in its own process, one at a time, with the two programs alternating. Each process runs an untimed warm-up fit, and the timer covers the estimation command only. A model is fitted with seeds 1 to 7, or 1 to 5 if its first fit took more than a minute, or 1 to 3 if it took more than 200 seconds. On our machine `main` takes about one hour, `extra` ten minutes and `cores` half an hour. `--models N1,N2,R1 --reps 3` runs a subset in a few minutes. Run nothing else on the machine while timing. The model definitions are in `R/07_bench_specs.R`, `stata/07_bench_models.do` and `stata/07_bench_models_x.do`.

The effect counts:

```
python3 tools/count_effects.py
```

`results/coverage/SAOM_EFFECTS_INVENTORY.csv` is a copy of `docs/SAOM_EFFECTS_INVENTORY.csv` in the nwsaom repository at tag v1.5.11. It has one row per RSiena short name, variable type and context in the effects table of RSiena 1.6.6, giving the `nwsaom` option, its roles, and whether it was compared with `siena07`. The tools that built it from `getEffects()` are in `docs/inventory_tools` there.

Some statements of Sections 5.8 and 6 rest on comparisons in `nwsaom`'s test suite rather than in this folder, in the nwsaom repository at tag v1.5.11:

- `estat score` against RSiena's `score.Test`, eight seeds: `dev/saom_rsiena_score_*.csv`.
- `estat timetest` against `sienaTimeTest`: `cscripts/test_nwsaom_tt.do` and `dev/saom_rsiena_groups_tt.csv`.
- `estat importance` against `sienaRI`, to 1e-7: `cscripts/test_nwsaom_fixsim.do`.
- `nwsaom meta` against `siena08`: `cscripts/test_nwsaom_meta.do`.

## How close the numbers should be

With the same seed and the same software, each program reproduces its own results exactly: a re-run gives the same digits. We checked this for every result file in this folder, both by re-running in place and by running all scripts from a fresh copy of the folder under Stata 17. The only exceptions are timings, such as the Bayesian run in `extras.log`. A seed also reproduces within one Stata session: `stata/12_same_seed.do` fits two of the examples twice in a row with the same seed, and once more on one core, and all three fits give identical estimates and standard errors.

On another platform, or with a plugin built by another compiler, the estimates of `nwsaom` can differ in the last digits. The relative differences between the release plugin and a local build of the same source were below 1e-11, and every printed listing was unchanged.

The two programs cannot agree to the digit, because they use different random number generators. Their comparisons (Tables 3, 4 and 6) therefore report the mean over several seeds for each program and the difference of the means in units of RSiena's standard error. In the article the differences are at most 0.10 standard errors in all benchmark models (0.11 with the fits that did not converge), and the seed-to-seed spread of each program is of the same order (RSiena: a median of 0.03 and at most 0.11 standard errors). `tools/build_tables.py` also tests each difference against the Monte Carlo error of the two means (seed-to-seed standard deviation divided by the square root of the number of seeds, both programs combined): 21 of 216 exceed 1.96 times it, against about 11 that independent comparisons would give by chance (a reference, not a formal test, since the comparisons are not independent): small differences between the implementations remain in some models, but none of these is larger than 0.08 standard errors. A fresh run with other seeds should give differences of the same size.

Timings depend on the machine and its load; `results/benchmark/raw` records the one-minute load average before every fit (column `load1`). The ratio between the programs is more stable than the seconds. In the article it is a median of 3.8 over 27 models, on one thread in both programs. The Mata engine took a median of 43 seconds per fit of N1 in one run and 47 seconds in another, against the article's 47; its estimates were identical in both runs.

## Data

`data/glasgow` holds the excerpt of the Teenage Friends and Lifestyle Study (Michell and Amos 1997; Pearson and West 2003): 50 pupils, friendship at three waves, and alcohol use and smoking at each wave. It is the data that RSiena ships as `s501`, `s502`, `s503`, `s50a` and `s50s` and that nwcommands ships as `nwwebuse glasgow`, with tie codes above 1 set to 0 as in RSiena's examples. The article's Stata examples use nwcommands' copy and the RSiena scripts use RSiena's. The two data checks confirm that both copies equal these CSV files. nwcommands stores the pupils in the order of their labels as text (n1, n10, n11, ...), and the Stata check matches the pupils by label.

`data/groups` holds two data sets:

- `school1_wave1.csv` to `school4_wave2.csv`: the four Dutch school classes of Section 5.9 (RSiena's N3401, N3403, N3404, N3406 and HN3401 to HN3406; 45, 37, 33 and 36 pupils), from the Dutch Social Behavior Data Set of Chris Baerveldt (Snijders and Baerveldt 2003). `R/01_check_data.R` checks them against RSiena's copy.
- `s50g_*.csv`: the Glasgow excerpt cut into three artificial groups of 15, 20 and 15 pupils, with the ties between the groups removed. It is a demonstration, not a real multi-group study.

`data/benchmark` holds the data of the benchmark models X1 to X6, which both programs read: two two-mode networks, a second network for the models with two networks, and a non-directed network. The second network of X3 to X5 is generated in Stata by `stata/07_bench_models_x.do` (Mata, `rseed(99)`) and saved in `saom_rsiena_mb_b1.csv` to `b3.csv` for RSiena. The other benchmark models use the Glasgow excerpt, or 2, 4 or 10 disconnected copies of it.

## Where the speed comes from

Appendix D of the `nwsaom` manual explains (the manual is archived at Zenodo, <https://doi.org/10.5281/zenodo.23623807> (all versions), and is also in the `nwsaom` repository: <https://github.com/thomas-u-grund/nwsaom/blob/main/manual/nwsaom_manual.pdf>), with the measurements of the scripts named in the table above, why `nwsaom` is faster than RSiena although it runs the same algorithm with the same defaults.
