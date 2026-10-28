#!/usr/bin/env python3
"""Command-assembly test: does the PROGRAM command of every generated dialog build a command in the real dialog engine?

Why: the engine silently aborts a PROGRAM whose `if` condition it cannot evaluate (e.g. parentheses in a condition): the OK
button then does nothing and no message appears. check_dialogs.py cannot see that (db only loads the dialog).

For each dialog this copies the .dlg, turns the body of PROGRAM command into a PROGRAM that POSTINIT runs after setting some
controls, and makes it call a stub `nwdlgcap` instead of the real command; Stata (-e, batch) prints the assembled string.
Usage:  python3 dlg/cmd_assembly_test.py --nwcore <core dir> [--stata <StataBE>] [--work <scratch dir>]
Exit status 1 if any case is missing or differs. Needs Stata 17 or 18 (batch, one process).
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
STATA = "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE"

# dialog -> [(case id, setup statements, expected command)]; the expected text is compared after collapsing blanks
CASES = {
    "nwsaom": [
        ("default", [], "nwsaom"),
        ("two waves, effects", ['call waves.cb_wave1.setvalue "w1"', 'call waves.cb_wave2.setvalue "w2"',
                                "call waves.cx_outdegree.seton", "call waves.cx_reciprocity.seton"],
         "nwsaom, wave1(w1) wave2(w2) outdegree reciprocity"),
        ("waves list", ['call waves.cb_waves.setvalue "w1 w2 w3"', "call waves.cx_outdegree.seton"],
         "nwsaom, waves(w1 w2 w3) outdegree"),
        ("interact pair", ['call rates.cb_interact_1a.setvalue "outdegree"', 'call rates.cb_interact_1b.setvalue "reciprocity"'],
         "nwsaom, interact(outdegree#reciprocity )"),
    ],
    "nwsaom_simulate": [
        ("last fit", ["call simulate.rb_simulate_last.seton", 'call simulate.ed_simulate_nsim.setvalue "5"', 'call simulate.ed_simulate_seed.setvalue "3"'],
         "estat simulate, nsim(5) seed(3) generate(sim)"),
        ("last fit, defaults", ["call simulate.rb_simulate_last.seton"], "estat simulate, nsim(1) generate(sim)"),
        ("last fit, generate cleared", ["call simulate.rb_simulate_last.seton", 'call simulate.ed_simulate_generate.setvalue ""'],
         "estat simulate, nsim(1)"),
        ("specify the model", ["call simulate.rb_simulate_spec.seton", 'call simulate.cb_simulate_waves.setvalue "w1 w2 w3"',
                               'call simulate.ed_simulate_effects.setvalue "outdegree reciprocity"',
                               'call simulate.ed_simulate_theta.setvalue "-1 0.5"', 'call simulate.ed_simulate_rates.setvalue "5 5"',
                               'call simulate.ed_simulate_other.setvalue "behavior(b1 b2 b3) linear"'],
         "nwsaom simulate, waves(w1 w2 w3) outdegree reciprocity theta(-1 0.5) rates(5 5) behavior(b1 b2 b3) linear nsim(1) generate(sim)"),
    ],
    "nwsaom_multinet": [("default", [], "nwsaom multinet, eff1(outdegree reciprocity ) eff2(outdegree reciprocity )")],
    "nwsaom_describe": [("default", [], "nwsaom describe")],
    "nwsaom_bayes": [("default", [], "nwsaom bayes")],
    "nwsaom_meta": [("names", ['call meta.ed_meta_names.setvalue "a b"'], "nwsaom meta a b")],
    "nwsaom_multiplex": [("default", [], "nwsaom multiplex")],
    "nwsaom_estat": [("default", [], "estat gof"),
                     ("importance", ["call statistic.rb_estat_importance.seton"], "estat importance"),
                     ("simulate defaults", ["call statistic.rb_estat_simulate.seton"], "estat simulate, nsim(1) generate(sim)")],
}


def build(dlgname, setup, outdir):
    s = open(os.path.join(ROOT, dlgname + ".dlg"), encoding="utf-8").read()
    i = s.index("PROGRAM command\nBEGIN\n")
    j = s.index("\nEND", i)
    body = s[i + len("PROGRAM command\nBEGIN\n"):j].rstrip("\n")
    body = re.sub(r"(?m)^(\s*)stata\s*$", r"\1stata hidden immediate", body)
    assert "stata hidden immediate" in body, dlgname + ": PROGRAM command has no stata statement"
    run = "PROGRAM zzrun\nBEGIN\n" + "".join("\t%s\n" % x for x in setup) + '\tput "nwdlgcap "\n' + body + "\nEND\n\n"
    if "SCRIPT POSTINIT\nBEGIN\n" in s:
        s = s.replace("SCRIPT POSTINIT\nBEGIN\n", "SCRIPT POSTINIT\nBEGIN\n\tprogram zzrun\n", 1)
    else:
        k = s.index("\nDIALOG ") + 1
        s = s[:k] + "SCRIPT POSTINIT\nBEGIN\n\tprogram zzrun\nEND\n\n" + s[k:]
    s = s.replace("PROGRAM command\nBEGIN", "PROGRAM command_orig\nBEGIN", 1)
    os.makedirs(outdir, exist_ok=True)
    open(os.path.join(outdir, dlgname + ".dlg"), "w", encoding="utf-8").write(s + "\n" + run)


def main(argv):
    nwcore = None
    work = None
    stata = STATA
    i = 0
    while i < len(argv):
        if argv[i] == "--nwcore":
            nwcore = argv[i + 1]; i += 1
        elif argv[i] == "--work":
            work = argv[i + 1]; i += 1
        elif argv[i] == "--stata":
            stata = argv[i + 1]; i += 1
        i += 1
    if not nwcore:
        print("usage: cmd_assembly_test.py --nwcore <core dir> [--work <dir>] [--stata <StataBE>]")
        return 2
    work = work or tempfile.mkdtemp(prefix="dlg_cmdasm_")
    os.makedirs(os.path.join(work, "plus"), exist_ok=True)
    os.makedirs(os.path.join(work, "stub"), exist_ok=True)
    open(os.path.join(work, "stub", "nwdlgcap.ado"), "w").write('program nwdlgcap\n\tdi "CAP|$CASE|`0\'"\nend\n')
    pkg_lib = os.path.join(ROOT, "lib")
    bad = 0
    todo = [d for d in CASES if os.path.exists(os.path.join(ROOT, d + ".dlg"))]
    do = ["capture program drop nwinstall", "clear all", "set linesize 250", 'sysdir set PLUS "%s/plus"' % work,
          'adopath ++ "%s"' % nwcore, 'adopath ++ "%s/lib"' % nwcore, 'adopath ++ "%s"' % ROOT, 'adopath ++ "%s"' % pkg_lib,
          'adopath ++ "%s/stub"' % work, "nwclear",
          "nwrandom 8, prob(.3) name(w1)", "nwrandom 8, prob(.3) name(w2)", "nwrandom 8, prob(.3) name(w3)"]
    # a minimal fit is not needed: the stub replaces the command
    ids = []
    for d in todo:
        for k, (cid, setup, exp) in enumerate(CASES[d]):
            dd = os.path.join(work, "t_%s_%d" % (d, k))
            build(d, setup, dd)
            ids.append((d, cid, exp))
            do += ['global CASE "%s|%s"' % (d, cid), 'adopath ++ "%s"' % dd, "discard", "capture noisily db %s" % d]
    open(os.path.join(work, "run.do"), "w").write("\n".join(do) + "\n")
    subprocess.run(["perl", "-e", "alarm 600; exec @ARGV", stata, "-e", "do", "run.do"], cwd=work,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log = open(os.path.join(work, "run.log"), encoding="utf-8", errors="replace").read() if os.path.exists(os.path.join(work, "run.log")) else ""
    got = {}
    for m in re.finditer(r"^CAP\|([^|]*)\|([^|]*)\|(.*)$", log, re.M):
        got[(m.group(1), m.group(2))] = " ".join(m.group(3).split())
    for d, cid, exp in ids:
        g = got.get((d, cid))
        if g is None:
            print("FAIL %-18s %-20s no command was built (the engine aborted silently?)" % (d, cid)); bad += 1
        elif g != exp:
            print("FAIL %-18s %-20s got %r, expected %r" % (d, cid, g, exp)); bad += 1
        else:
            print("ok   %-18s %-20s %s" % (d, cid, g))
    print("%d case(s), %d failed" % (len(ids), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
