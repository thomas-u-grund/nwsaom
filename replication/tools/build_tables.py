"""Builds the benchmark tables of the article (Table "nwsaom and RSiena 1.6.14 on the same models", the table of
several cores) and the numbers quoted in the text (bench_numbers.tex) from the raw benchmark CSVs.
Run from the replication folder:
    python3 tools/build_tables.py [RAW_DIR [OUT_DIR]]
Defaults: RAW_DIR = results/benchmark/raw (the runs of the article), OUT_DIR = results/benchmark/tables.
For a new run: python3 tools/build_tables.py results/benchmark/raw_new results/benchmark/tables_new"""
import csv, json, os, re, sys, statistics as st
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
if len(sys.argv) > 1: os.environ["BENCH_RAW"] = sys.argv[1]
import summarize as S
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join("results", "benchmark", "tables")
os.makedirs(OUT, exist_ok=True)

# model specifications as printed in the table (column "Specification", n, waves)
_SP = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "bench_model_specs.json")))
SP_MAIN = {k: tuple(v) for k, v in _SP["main"].items()}; SP_X = {k: tuple(v) for k, v in _SP["extra"].items()}
GROUPS = [("Network", "N1 N2 N4 N5 N6 N7"), ("Undirected", "U1 U2"), ("Co-evolution", "C1 C2 C3"), ("Realistic", "R1 R2 R3 R4 R5"), ("Larger networks", "S100 S200 S500 T200")]
GROUPS_X = [("Two-mode", "X1 X2"), ("Two networks", "X3 X4 X5 X6"), ("Single network", "X7")]
def secs(x): return f"{x:.2f}" if x < 10 else f"{x:.1f}" if x < 100 else f"{x:.0f}"

def cellinfo(files):
    R = S.rows(*files); g = S.group(R); out = {}
    for c, impls in g.items():
        a = S.cellstats(impls.get("RSiena", [])); b = S.cellstats(impls.get("nwsaom", []))
        ag, an = S.agreement(c, impls.get("RSiena", []), impls.get("nwsaom", []))
        out[c] = dict(rs=a, nw=b, ag=ag, an=an, impls=impls)
    return out, R
main, Rm = cellinfo(["saom_main.csv"]); extra, Rx = cellinfo(["saom_extra.csv"])

def table(groups, info, spec, caption, label, colspec, note):
    lines = []
    for gi, (gname, ids) in enumerate(groups):
        if gi: lines.append(r"\addlinespace")
        lines.append(rf"\multicolumn{{8}}{{l}}{{\textit{{{gname}}}}} \\")
        for i in ids.split():
            if i not in info or not info[i]["nw"]["med"]: continue
            c = info[i]; sp, n, w = spec[i]
            lines.append(f"{i} & {sp} & {n} & {w} & {c['ag']:.2f} & {secs(c['nw']['med'])} & {secs(c['rs']['med'])} & {c['rs']['med']/c['nw']['med']:.1f} \\\\")
    return rf"""{{\footnotesize
\begin{{longtable}}{{l>{{\raggedright\arraybackslash}}p{{{colspec}\textwidth}}rrrrrr}}
\caption{{{caption}}}\label{{{label}}}\\
\toprule
 & Specification & $n$ & Waves & Max diff & \texttt{{nwsaom}} & RSiena & Speed-up \\
\midrule
\endfirsthead
\multicolumn{{8}}{{l}}{{\textit{{Table \thetable{{}} continued}}}}\\
\toprule
 & Specification & $n$ & Waves & Max diff & \texttt{{nwsaom}} & RSiena & Speed-up \\
\midrule
\endhead
\midrule
\multicolumn{{8}}{{r}}{{\textit{{continued on the next page}}}}\\
\endfoot
\bottomrule
\endlastfoot
{chr(10).join(lines)}
\end{{longtable}}
}}
{{{note}\par}}
"""
ALLINFO = {**main, **extra}; SPEC = {**SP_MAIN, **SP_X}
ALLGROUPS = GROUPS + GROUPS_X
note_all = (r"\par\smallskip\footnotesize Medians over seven fits (seeds 1--7; five above one minute, three above three minutes) per program (RSiena 1.6.14: 8 November 2026; \texttt{nwsaom} 1.5.7: 9 November 2026; same seeds). Max diff includes the rate parameters and uses the fits that converged (overall convergence ratio $<0.25$) in both programs. N7, X1, X2: unconditional estimation in both programs (\texttt{unconditional}; \texttt{cond = FALSE}); X3--X6: \texttt{nwsaom multinet} with \texttt{k0(100) k3(1000)} against RSiena \texttt{n3 = 1000, nsub = 4}. Fits that converged, RSiena / \texttt{nwsaom}, for the models with at least one that did not: " +
   "; ".join(f"{i} {ALLINFO[i]['rs']['conv']}/{ALLINFO[i]['rs']['n']}, {ALLINFO[i]['nw']['conv']}/{ALLINFO[i]['nw']['n']}" for g, ids in ALLGROUPS for i in ids.split() if i in ALLINFO and (ALLINFO[i]['rs']['conv'] < ALLINFO[i]['rs']['n'] or ALLINFO[i]['nw']['conv'] < ALLINFO[i]['nw']['n'])) + ".")
open(f"{OUT}/bench_rsiena.tex", "w").write(table(ALLGROUPS, ALLINFO, SPEC,
 r"\texttt{nwsaom} and RSiena 1.6.14 on the same models and data, both single-threaded: largest difference in a mean estimate (in RSiena standard errors) and median seconds per fit",
 "tab:bench", "0.26", note_all))

# ---- per-parameter agreement for main models
def pairs_for(m, rs_rows, nw_rows):
    rs_p = [S.params(r) for r in rs_rows if r["status"] == "ok" and r["converged"] == "1"]
    nw_p = [S.params(r) for r in nw_rows if r["status"] == "ok" and r["converged"] == "1"]
    if not rs_p or not nw_p: return []
    if m.startswith("X"):
        prs = list({**S.EFF[m], **S.rate_map(m)}.items())
    else:
        nwn = {S.canon_nw(k): k for k in nw_p[0]}
        prs = [(k, nwn[k]) for k in rs_p[0] if k in nwn]
    res = []
    for k, b in prs:
        try:
            er = [p[k][0] for p in rs_p]; sr = [p[k][1] for p in rs_p]; en = [p[b][0] for p in nw_p]; sn = [p[b][1] for p in nw_p]
        except KeyError: continue
        if None in er or None in en or None in sr or None in sn: continue
        ser = st.mean(sr)
        res.append(dict(param=k, nw=st.mean(en), rs=st.mean(er), d=(st.mean(en)-st.mean(er))/ser, se_ratio=st.median(sn)/st.median(sr),
                        rs_sd=(st.stdev(er)/ser if len(er) > 1 else None)))
    return res
models = []
allp = []
for gname, ids in ALLGROUPS:
    for i in ids.split():
        if i not in ALLINFO: continue
        c = ALLINFO[i]; pr = pairs_for(i, c["impls"].get("RSiena", []), c["impls"].get("nwsaom", []))
        allp += pr
        models.append(dict(id=i, group=gname, time_nw_1core=c["nw"]["med"], time_rs=c["rs"]["med"], rows=[dict(param=p["param"], d=p["d"]) for p in pr]))
json.dump(dict(models=models), open(f"{OUT}/bench_results.json", "w"))
sp = [m["time_rs"]/m["time_nw_1core"] for m in models]
mac = {}
mac["benchnmodels"] = str(len(models)); mac["benchnmain"] = str(len(main)); mac["benchnextra"] = str(len(extra)); mac["benchnparams"] = str(len(allp))
mac["benchmaxdiff"] = f"{max(abs(p['d']) for p in allp):.2f}"; mac["benchmeandiff"] = f"{st.mean(abs(p['d']) for p in allp):.2f}"
# the largest difference of each model, and the largest and second-largest model (the article names the model with the largest)
mdiff = sorted(((max(abs(r["d"]) for r in m["rows"]), m["id"]) for m in models if m["rows"]), reverse=True)
mac["benchmaxdiffmodel"] = mdiff[0][1]
mac["benchmaxdiffnext"] = f"{mdiff[1][0]:.2f}"
mac["benchspmed"] = f"{st.median(sp):.1f}"; mac["benchspmin"] = f"{min(sp):.1f}"; mac["benchspmax"] = f"{max(sp):.1f}"
mac["benchserlo"] = f"{min(p['se_ratio'] for p in allp):.2f}"; mac["benchserhi"] = f"{max(p['se_ratio'] for p in allp):.2f}"
_co = [pp for i in "C1 C2 C3 R2 R5 T200".split() if i in main for pp in pairs_for(i, main[i]["impls"]["RSiena"], main[i]["impls"]["nwsaom"])]
_no = [pp for i in "N1 N2 N4 N5 N6 N7 U1 U2 R1 R3 R4 S100 S200 S500".split() if i in main for pp in pairs_for(i, main[i]["impls"]["RSiena"], main[i]["impls"]["nwsaom"])]
mac["benchcoevlo"] = f"{min(p['se_ratio'] for p in _co):.2f}"; mac["benchcoevhi"] = f"{max(p['se_ratio'] for p in _co):.2f}"
import math
mac["benchnetsepct"] = str(math.ceil(max(abs(p['se_ratio'] - 1) for p in _no) * 100 - 1e-9))
rsd = [p["rs_sd"] for p in allp if p["rs_sd"] is not None]
mac["benchseedsd"] = f"{st.median(rsd):.2f}"; mac["benchseedsdmax"] = f"{max(rsd):.2f}"
mac["benchfits"] = str(sum(ALLINFO[i]["nw"]["n"] for i in ALLINFO)); mac["benchrsfits"] = str(sum(ALLINFO[i]["rs"]["n"] for i in ALLINFO))
mac["benchnwconv"] = str(sum(ALLINFO[i]["nw"]["conv"] for i in ALLINFO)); mac["benchrsconv"] = str(sum(ALLINFO[i]["rs"]["conv"] for i in ALLINFO))
if "N2" in main: mac["benchNtwoSp"] = f"{main['N2']['rs']['med']/main['N2']['nw']['med']:.1f}"
if "R4" in main:
    a, b = main["R4"]["nw"]["med"], main["R4"]["rs"]["med"]
    mac["benchRfourNw"] = f"{a:.0f}"; mac["benchRfourRs"] = f"{b:.0f}"; mac["benchRfourSaveTwelve"] = f"{12*(b-a)/60:.0f}"
gw = [i for i in ("N2 N4 N5 N6 N7 R1 R2 R3 R4 R5 S100 S200 S500 T200 C1 C2".split())]
nogw = "N1 U1 U2 C3".split()
def rng(ids):
    v = [main[i]["rs"]["med"]/main[i]["nw"]["med"] for i in ids if i in main]; return f"{min(v):.1f}", f"{max(v):.1f}"
mac["benchnogwlo"], mac["benchnogwhi"] = rng(nogw)
mac["benchgwlo"], mac["benchgwhi"] = rng("N2 N4 N5 N6 N7".split())
mac["benchlargelo"], mac["benchlargehi"] = rng("R4 R5 S100 S200 S500 T200".split())
mac["benchlargeslo"], mac["benchlargeshi"] = rng("R4 R5 S100 S200 S500".split())
mac["benchnslower"] = str(sum(1 for s in sp if s < 1))
for k, w in (("X2", "Xtwo"), ("X1", "Xone")):
    if k in extra: mac["bench" + w + "nw"] = secs(extra[k]["nw"]["med"]); mac["bench" + w + "rs"] = secs(extra[k]["rs"]["med"]); mac["bench" + w + "sp"] = f"{extra[k]['rs']['med']/extra[k]['nw']['med']:.1f}"
mac["benchTsp"] = f"{main['T200']['rs']['med']/main['T200']['nw']['med']:.1f}"
# benchmataNone: the Mata engine on N1 (stata/09_mata_engine.do), measured separately; not in the raw CSVs
mac["benchmataNone"] = "51"; mac["benchnwNone"] = secs(main["N1"]["nw"]["med"]) if "N1" in main else ""
xs = [extra[i]["rs"]["med"]/extra[i]["nw"]["med"] for i in extra]
mac["benchxmin"] = f"{min(xs):.1f}"; mac["benchxmax"] = f"{max(xs):.1f}"
mac["benchxmaxdiff"] = f"{max(extra[i]['ag'] for i in extra):.2f}"
mn = [extra[i]["rs"]["med"]/extra[i]["nw"]["med"] for i in "X3 X4 X5 X6".split() if i in extra]
mac["benchxnetlo"], mac["benchxnethi"] = f"{min(mn):.1f}", f"{max(mn):.1f}"
mac["benchxsinglelo"] = f"{min(extra[i]['rs']['med']/extra[i]['nw']['med'] for i in ('X7',)):.1f}"
mac["benchxsinglehi"] = f"{max(extra[i]['rs']['med']/extra[i]['nw']['med'] for i in ('X7',)):.1f}"
# load statistics
alr = [r for r in Rm + Rx if r["status"] != "skipped"]
# cores
Rc = S.rows("saom_cores.csv"); gc = S.group(Rc)
if gc:
    cm = {}
    for c, impls in gc.items():
        cm[c] = {k: S.cellstats(v) for k, v in impls.items()}
    order = [c for c in ["R1", "R4", "R5", "S500"] if c in cm and all(k in cm[c] and cm[c][k]["med"] for k in ("nwsaom_c1","nwsaom_c2","nwsaom_c5","nwsaom_c10","RSiena_1","RSiena_5","RSiena_10"))]
    body = []; vs = {}
    nof = {"R1": 50, "R4": 200, "R5": 200, "S500": 500}
    for c in order:
        t = cm[c]; base = t["nwsaom_c1"]["med"]
        cells = " & ".join(f"{secs(t[k]['med'])} ({base/t[k]['med']:.1f})" for k in ("nwsaom_c1", "nwsaom_c2", "nwsaom_c5", "nwsaom_c10"))
        rcells = " & ".join(secs(t[k]["med"]) if t[k]["med"] else "--" for k in ("RSiena_1", "RSiena_5", "RSiena_10"))
        body.append(f"{c} & {nof[c]} & {cells} & {rcells} \\\\")
        W = {"R1": "Rone", "R4": "Rfour", "R5": "Rfive", "S500": "Sfivezerozero"}[c]
        mac["cores" + W] = f"{base/t['nwsaom_c10']['med']:.1f}"
        vs[c] = t["RSiena_1"]["med"]/t["nwsaom_c10"]["med"]
        best = min(t["RSiena_1"]["med"], t["RSiena_5"]["med"], t["RSiena_10"]["med"])
        mac["cores" + W + "rsbest"] = secs(best)
        mac["cores" + W + "vsrsbest"] = f"{best/t['nwsaom_c10']['med']:.1f}"
        mac["cores" + W + "nwten"] = secs(t["nwsaom_c10"]["med"])
        mac["cores" + W + "rsfive"] = secs(t["RSiena_5"]["med"]); mac["cores" + W + "rsten"] = secs(t["RSiena_10"]["med"])
        mac["cores" + W + "rsone"] = secs(t["RSiena_1"]["med"])
    mac["coresvsrsmin"] = f"{min(vs.values()):.1f}"; mac["coresvsrsmax"] = f"{max(vs.values()):.1f}"
    bv = [float(mac["cores" + {"R1": "Rone", "R4": "Rfour", "R5": "Rfive", "S500": "Sfivezerozero"}[c] + "vsrsbest"]) for c in order]
    mac["coresvsbestmin"] = f"{min(bv):.1f}"; mac["coresvsbestmax"] = f"{max(bv):.1f}"
    mac["coresmaxthreads"] = "10"; mac["coresmaxdiff"] = "0"
    open(f"{OUT}/bench_cores.tex", "w").write(r"""\begin{table}[htbp]
\centering
\caption{\texttt{nwsaom} with 1 to 10 threads (in parentheses, speed-up over one thread) and RSiena with 1, 5 and 10 R processes: median seconds per fit over three seeds. The estimates of \texttt{nwsaom} are identical for every number of threads.}
\label{tab:cores}
\footnotesize
\begin{tabular}{lrrrrrrrr}
\toprule
 & & \multicolumn{4}{c}{\texttt{nwsaom}} & \multicolumn{3}{c}{RSiena, processes} \\
\cmidrule(lr){3-6}\cmidrule(lr){7-9}
Model & $n$ & \texttt{cores(1)} & \texttt{cores(2)} & \texttt{cores(5)} & \texttt{cores(10)} & 1 & 5 & 10 \\
\midrule
""" + "\n".join(body) + r"""
\bottomrule
\end{tabular}
\end{table}
""")
open(f"{OUT}/bench_numbers.tex", "w").write("% generated by tools/build_tables.py - do not edit\n" + "".join(f"\\newcommand{{\\{k}}}{{{v}}}\n" for k, v in sorted(mac.items())))
# summary csv for notes
for name, info in (("main", main), ("extra", extra)):
    with open(f"{OUT}/sum_{name}.csv", "w", newline="") as fh:
        w = csv.writer(fh); w.writerow(["model", "rs_n", "nw_n", "rs_med", "nw_med", "ratio", "rs_conv", "nw_conv", "maxdiff", "nw_lo", "nw_hi"])
        for i, c in info.items():
            if c["nw"]["med"]: w.writerow([i, c["rs"]["n"], c["nw"]["n"], f"{c['rs']['med']:.3f}", f"{c['nw']['med']:.3f}", f"{c['rs']['med']/c['nw']['med']:.2f}", c["rs"]["conv"], c["nw"]["conv"], f"{c['ag']:.2f}" if c["ag"] is not None else "", f"{c['nw']['lo']:.3f}", f"{c['nw']['hi']:.3f}"])
# load stats
def lstats(rs):
    l = sorted(float(r["load1"]) for r in rs if r["load1"] not in ("", "nan"))
    return len(l), l[0], st.median(l), st.mean(l), l[int(.9*len(l))-1], l[-1], sum(1 for r in rs if r["n_other"] not in ("0", ""))
allr = [r for r in Rm + Rx + Rc if r["status"] != "skipped"]
_l = sorted(float(r["load1"]) for r in allr)
mac["benchloadmed"] = f"{st.median(_l):.1f}"; mac["benchloadmax"] = f"{_l[-1]:.1f}"
# load during all fits of each program (single-thread comparison and the runs with several cores)
for prog, k in (("RSiena", "rs"), ("nwsaom", "nw")):
    _p = sorted(float(r["load1"]) for r in Rm + Rx + Rc if r["status"] != "skipped" and r["impl"].startswith(prog) and r["load1"] not in ("", "nan"))
    mac["benchloadmed" + k] = f"{st.median(_p):.1f}"; mac["benchloadmax" + k] = f"{_p[-1]:.1f}"
open(f"{OUT}/bench_numbers.tex", "a").write("".join("\\newcommand{\\%s}{%s}\n" % (k, mac[k]) for k in ("benchloadmed", "benchloadmax", "benchloadmedrs", "benchloadmaxrs", "benchloadmednw", "benchloadmaxnw")))
print("fits, min, med, mean, p90, max, with_other:", lstats(allr))
print("\n".join(f"{k}={v}" for k, v in sorted(mac.items())))
