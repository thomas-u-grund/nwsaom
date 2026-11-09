"""Re-runs the benchmark of the article: nwsaom against RSiena 1.6.14 on the same models and data.

Run from the replication folder (macOS or Linux; needs Stata, R with RSiena 1.6.14, perl and Python 3):

    python3 tools/run_benchmark.py main  --stata "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"
    python3 tools/run_benchmark.py extra --stata ...
    python3 tools/run_benchmark.py cores --stata ...

main   the single-thread comparison of N1 to T200 (Table "nwsaom and RSiena 1.6.14 on the same models")
extra  the further models X1 to X7 (same table)
cores  R1, R4, R5 with 1, 2, 5, 10 threads in nwsaom and 1, 5, 10 R processes in RSiena (table of several cores)
all    all three

Options:
  --stata PATH     the Stata executable (or the environment variable STATA)
  --rscript PATH   Rscript (default: Rscript on the PATH)
  --models A,B,..  only these models (for example --models N1,N2,R1)
  --reps N         at most N fits per model and program (default: the article's rule below)
  --impl both|nwsaom|rsiena   only one program (default both)
  --out DIR        folder of the raw CSVs (default results/benchmark/raw_new; results/benchmark/raw holds the
                   article's runs and is never written)

Every fit runs in its own process (Rscript R/07_bench_one.R, or Stata on stata/07_bench_one.do), one at a
time, the programs alternating, after an untimed warm-up fit in the same process; the timer covers the
estimation command only. Seeds are 1, 2, 3, ...; the number of fits per model follows the article's rule:
7, or 5 if the first fit took more than 60 seconds, 3 if more than 200 seconds. A fit is killed after 600
seconds. The one-minute load average is recorded before each fit; the runner waits (at most a minute) while
other R or Stata processes are running. nwsaom uses the installed packages, or the source trees named by the
environment variables NWCORE, NWSAOM and NWPLUS (see stata/setup.do).

Then:  python3 tools/build_tables.py results/benchmark/raw_new results/benchmark/tables_new
"""
import argparse, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import benchlib

REP = os.path.dirname(HERE)
MAIN = "N1 N2 N4 N5 N6 N7 U1 U2 C1 C2 C3 R1 R2 R3 S100 S200 S500 T200 R4 R5".split()
EXTRA = "X1 X2 X3 X4 X5 X6 X7".split()
CORES = "R1 R4 R5".split()


def stata_impl(stata, name, model, cores=1):
    # the path is quoted for Stata, so that a folder name with spaces works
    return dict(name=name, argv=[stata, "-e", "do", '"%s"' % os.path.join(REP, "stata", "07_bench_one.do")],
                env=dict(MODEL=model, SEED="{seed}", CORES=str(cores), REP=REP))


def r_impl(rscript, name, model, nodes=1):
    return dict(name=name, argv=[rscript, os.path.join(REP, "R", "07_bench_one.R"), model, "{seed}", "{out}", str(nodes)],
                env=dict(REP=REP))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("what", choices=["main", "extra", "cores", "all"])
    ap.add_argument("--stata", default=os.environ.get("STATA", ""))
    ap.add_argument("--rscript", default="Rscript")
    ap.add_argument("--models", default="")
    ap.add_argument("--reps", type=int, default=7)
    ap.add_argument("--impl", choices=["both", "nwsaom", "rsiena"], default="both")
    ap.add_argument("--out", default=os.path.join("results", "benchmark", "raw_new"))
    a = ap.parse_args()
    if a.impl != "rsiena" and not a.stata:
        ap.error("give the Stata executable with --stata (or set STATA)")
    out = os.path.abspath(a.out)
    if os.path.abspath(os.path.join(REP, "results", "benchmark", "raw")) == out:
        ap.error("results/benchmark/raw holds the article's runs; choose another --out")
    os.makedirs(out, exist_ok=True)
    work = os.path.join(out, "work")
    only = set(a.models.split(",")) if a.models else None
    pick = lambda ms: [m for m in ms if only is None or m in only]

    def single(models):
        cells = []
        for i, m in enumerate(pick(models)):
            impls = []
            if a.impl in ("both", "rsiena"): impls.append(r_impl(a.rscript, "RSiena", m))
            if a.impl in ("both", "nwsaom"): impls.append(stata_impl(a.stata, "nwsaom", m))
            cells.append(dict(cell=m, group="saom_" + m, rank=i, impls=impls, maxreps=a.reps))
        return cells

    def cores():
        cells = []
        for i, m in enumerate(pick(CORES)):
            impls = []
            if a.impl in ("both", "nwsaom"): impls += [stata_impl(a.stata, "nwsaom_c%d" % c, m, cores=c) for c in (1, 2, 5, 10)]
            if a.impl in ("both", "rsiena"): impls += [r_impl(a.rscript, "RSiena_%d" % k, m, nodes=k) for k in (1, 5, 10)]
            cells.append(dict(cell=m, group="saomcores", rank=i, impls=impls, maxreps=min(a.reps, 3)))
        return cells

    if a.what in ("main", "all"): benchlib.run_plan("saom", single(MAIN), os.path.join(out, "saom_main.csv"), work)
    if a.what in ("extra", "all"): benchlib.run_plan("saom", single(EXTRA), os.path.join(out, "saom_extra.csv"), work)
    if a.what in ("cores", "all"): benchlib.run_plan("saom", cores(), os.path.join(out, "saom_cores.csv"), work)


if __name__ == "__main__":
    main()
