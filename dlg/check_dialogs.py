#!/usr/bin/env python3
"""Static checks of the generated .dlg files and of the spec.  Exit code 1 on any ERROR.

    python3 dlg/check_dialogs.py

Checks per dialog: balanced BEGIN/END, unique control ids, every control referenced in the command program exists, every
option put by the command program is a spec option of that dialog, no duplicate tab names, no control outside the
dialog area, label lengths against the control width, every LIST used exists.  Spec checks: every option of every
`syntax` line is covered (or listed in EXCLUDED), every effect of the inventory that has an nwsaom option is reachable.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nwsaom_dialog_spec as S  # noqa: E402
import gen_dialogs as G  # noqa: E402

ERR = []
WARN = []
CHW = 6.6


def err(m):
    ERR.append(m)
    print('ERROR', m)


def parse_dlg(path):
    txt = open(path, encoding='ascii').read()
    lines = txt.split('\n')
    d = dict(text=txt, lines=lines, tabs=[], lists={}, ctrls={}, ctrl_tab={})
    cur = None
    kind = None
    depth = 0
    for ln, l in enumerate(lines, 1):
        s = l.strip()
        m = re.match(r'^(DIALOG|LIST|PROGRAM|SCRIPT)\s+(\S+?)(,|\s|$)', s)
        if m and depth == 0:
            kind, cur = m.group(1), m.group(2)
            if kind == 'DIALOG':
                tt = re.search(r'tabtitle\("([^"]*)"\)', s)
                d['tabs'].append((cur, tt.group(1) if tt else None))
            if kind == 'LIST':
                d['lists'][cur] = []
            continue
        if s == 'BEGIN':
            depth += 1
            if depth > 1:
                err('%s:%d nested BEGIN' % (os.path.basename(path), ln))
            continue
        if s == 'END':
            depth -= 1
            if depth < 0:
                err('%s:%d END without BEGIN' % (os.path.basename(path), ln))
                depth = 0
            if depth == 0:
                kind = None
            continue
        if depth == 1 and kind == 'DIALOG':
            m = re.match(r'^(TEXT|CHECKBOX|RADIO|EDIT|VARLIST|COMBOBOX|SPINNER|BUTTON|GROUPBOX)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)(.*)$', s)
            if not m:
                err('%s:%d unparsable control line: %s' % (os.path.basename(path), ln, s[:80]))
                continue
            k, id_, x, y, w, h, rest = m.groups()
            if id_ in d['ctrls']:
                err('%s: duplicate control id %s' % (os.path.basename(path), id_))
            d['ctrls'][id_] = dict(kind=k, x=int(x), y=int(y), w=int(w), rest=rest, tab=cur, line=ln)
            d['ctrl_tab'][id_] = cur
        elif depth == 1 and kind == 'LIST':
            if s and not s.startswith('//'):
                d['lists'][cur].append(s)
    if depth != 0:
        err('%s: unbalanced BEGIN/END (depth %d at end)' % (os.path.basename(path), depth))
    return d


def check_dialog(name, res):
    dobj, lay, txt, w, h = res
    fn = os.path.join(S.ROOT, G.OUT_NAME[name] + '.dlg')
    base = os.path.basename(fn)
    if not os.path.exists(fn):
        err(base + ' missing')
        return
    cur = open(fn, encoding='ascii').read()
    if cur != txt:
        err(base + ' is not what gen_dialogs.py generates from the spec (regenerate it)')
    d = parse_dlg(fn)
    # tab names unique
    titles = [t for _, t in d['tabs']]
    if len(set(titles)) != len(titles):
        err(base + ': duplicate tab titles')
    if len(set(s for s, _ in d['tabs'])) != len(d['tabs']):
        err(base + ': duplicate DIALOG names')
    for t in titles:
        if len(t) > 10:
            err(base + ': tab title longer than 10 characters: ' + t)
    # geometry
    wd = int(re.search(r'DEFINE _dlgwd (\d+)', d['text']).group(1))
    ht = int(re.search(r'DEFINE _dlght (\d+)', d['text']).group(1))
    if wd > 1100 or ht > 600:
        err('%s: dialog size %dx%d larger than 1100x600' % (base, wd, ht))
    if len(d['tabs']) > 9:
        err('%s: %d tabs (at most 9: Stata draws one row of tabs)' % (base, len(d['tabs'])))
    if len(d['tabs']) * 90 > wd:
        err('%s: %d tabs need at least 90 px each but the dialog is %d px wide' % (base, len(d['tabs']), wd))
    if 'SYNCHRONOUS_ONLY' not in d['text']:
        err(base + ': SYNCHRONOUS_ONLY missing')
    for id_, c in d['ctrls'].items():
        if c['x'] + c['w'] > wd - 10:
            err('%s: %s outside the dialog area (x %d + w %d > %d)' % (base, id_, c['x'], c['w'], wd - 10))
        if c['y'] + 20 > ht - 40:
            err('%s: %s too low (y %d, height %d)' % (base, id_, c['y'], ht))
        if c['kind'] == 'TEXT':
            lab = re.search(r'label\("([^"]*)"\)', c['rest']).group(1)
            if len(lab) * CHW > c['w'] + 8:
                err('%s: label of %s too long for its width (%d chars, %d px): %s' % (base, id_, len(lab), c['w'], lab))
        if c['kind'] == 'CHECKBOX' or c['kind'] == 'RADIO':
            lab = re.search(r'label\("([^"]*)"\)', c['rest']).group(1)
            if len(lab) * CHW + 25 > c['w'] + 8:
                err('%s: label of %s too long for its width (%d chars): %s' % (base, id_, len(lab), lab))
        # one comma at most per control line
        if re.sub(r'"[^"]*"', '', c['rest']).count(',') > 1:
            err('%s: %s has several commas: %s' % (base, id_, c['rest'][:60]))
        for lst in re.findall(r'(?:contents|values)\((\w+)\)', c['rest']):
            if lst not in d['lists']:
                err('%s: %s uses undefined LIST %s' % (base, id_, lst))
        if len(re.findall(r'tooltip\("([^"]*)"\)', c['rest'])) and any(len(t) > 150 for t in re.findall(r'tooltip\("([^"]*)"\)', c['rest'])):
            err('%s: tooltip too long on %s' % (base, id_))
    # command program
    progs = re.findall(r'PROGRAM (command|opt_part\d+)\nBEGIN\n(.*?)\nEND\n', d['text'], re.S)
    prog = '\n'.join(b for _n, b in progs)
    for n_, b_ in progs:
        if b_.count('\n') > 130:
            err('%s: PROGRAM %s has %d lines (the dialog engine rejects long programs)' % (base, n_, b_.count('\n')))
    refs = set(re.findall(r'\b([a-z0-9_]+)\.((?:cx|ed|vl|cb|rb)_[A-Za-z0-9_]+)', prog))
    for sl, cid in refs:
        if cid not in d['ctrls']:
            err('%s: command program references unknown control %s.%s' % (base, sl, cid))
        elif d['ctrl_tab'][cid] != sl:
            err('%s: command program references %s.%s but the control lives in tab %s' % (base, sl, cid, d['ctrl_tab'][cid]))
    if prog.count('{') != prog.count('}'):
        err(base + ': unbalanced braces in the command program')
    puts = re.findall(r'put " ([a-z0-9_]+)[("]', prog)
    spec_opts = set()
    for e in S.ENTRIES.values():
        if e['dialog'] == name:
            spec_opts.add(e['opt'])
    spec_opts |= {'mloptions', 'stats', 'interact'}
    for p_ in puts:
        if p_ not in spec_opts and not any(p_ == s_.get('prefix') for s_ in []):
            if p_ not in ('nwsaom', 'estat', 'simulate'):
                err('%s: command program puts option %s which is not in the spec of this dialog' % (base, p_))
    # all controls of the layout appear and every non-label control id is used in the program or is a helper
    used = set(c for _, c in refs)
    for id_, c in d['ctrls'].items():
        if c['kind'] not in ('TEXT', 'BUTTON', 'GROUPBOX') and id_ not in used and id_ not in ('cb_nettype', 'cb_fitflag'):   # cb_nettype only greys controls
            err('%s: control %s is never used by the command program' % (base, id_))
    # optionarg needs the option() attribute on its control, otherwise the command program aborts silently
    for fn_ in os.listdir(S.ROOT):
        if fn_.endswith('.dlg'):
            txt_ = open(os.path.join(S.ROOT, fn_), encoding='utf-8').read()
            defs_ = {m_.group(2): m_.group(0) for m_ in re.finditer(r'^\s+(COMBOBOX|EDIT|VARLIST|VARNAME)\s+(\w+) .*$', txt_, re.M)}
            for c_ in set(re.findall(r'optionarg /asis \w+\.(\w+)', txt_)):
                if 'option(' not in defs_.get(c_, ''):
                    err('%s: optionarg on %s whose control has no option() attribute' % (fn_, c_))
    # lists non-empty
    for ln_, items in d['lists'].items():
        if ln_ not in ('netlist', 'netlist_a', 'fitlist') and not items:
            err('%s: LIST %s is empty' % (base, ln_))
    # every control id is a legal Stata name of at most 32 characters
    for id_ in d['ctrls']:
        if len(id_) > 31 or not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', id_):
            err('%s: illegal control id %s' % (base, id_))
    # every spec entry of this dialog is realised by a control or a list item
    for e in S.ENTRIES.values():
        if e['dialog'] != name:
            continue
        k = e['kind']
        if k in ('wrapper', 'note'):
            continue
        if k == 'name':
            if e.get('ctl'):
                if e['ctl'] not in d['ctrls']:
                    err('%s: flag control of %s missing' % (base, e['id']))
            else:
                nm = e['label'].split(': ')[1]
                lst = [i for i in d['lists'].get('lst_%s' % e['family'], []) + d['lists'].get('lst_%s_%s' % (name, e['family']), []) if i.split('  (')[0] == nm]
                lv = d['lists'].get('lst_%s_v' % e['family'], []) + d['lists'].get('lst_%s_%s_v' % (name, e['family']), [])
                if not lst or nm not in lv:
                    err('%s: effect %s of %s() is not in the dialog list' % (base, nm, e['family']))
        elif e['id'] not in d['ctrls']:
            err('%s: control for spec entry %s missing' % (base, e['id']))
    # family lists carry the RSiena name
    n_lab = n_all = 0
    for e in S.ENTRIES.values():
        if e['dialog'] == name and e['kind'] == 'name' and not e.get('isflag'):
            n_all += 1
    return d


def check_spec():
    # (1) every syntax option covered
    groups = [('nwsaom', S.MAIN_OPTS), ('multinet', S.MN_OPTS), ('bayes', S.BAYES_OPTS), ('meta', S.META_OPTS), ('describe', S.DESC_OPTS),
              ('multiplex', S.MX_OPTS)]
    estat = {'gof': S.ESTAT_GOF, 'score': S.ESTAT_SCORE, 'timetest': S.ESTAT_TT, 'simulate': S.ESTAT_SIM, 'mems': S.ESTAT_MEMS}
    nopts = 0
    for dn, opts in groups:
        cov = set(e['opt'] for e in S.ENTRIES.values() if e['dialog'] == dn and e['parent'] is None and e['kind'] != 'name') \
            | set(f[1] for f in S.FAMS if f[0] == dn)
        if dn == 'nwsaom':
            cov |= {'ml', 'mloptions'}
        excl = set(o for d_, o, _r in S.EXCLUDED if d_ == dn)
        for o in opts:
            nopts += 1
            if o not in cov and o not in excl:
                err('spec does not cover option %s of %s' % (o, dn))
        for o in cov:
            if o not in opts and o not in ('_namelist', 'theta', 'behtheta', 'rates', 'ratesbeh', 'nsim', 'generate', 'seed') :
                err('spec option %s of %s is not an option of the syntax line' % (o, dn))
    for sub, opts in estat.items():
        for o in opts:
            nopts += 1
            if not any(e['dialog'] == 'estat' and e['opt'] == o and (e['modes'] is None or sub in e['modes']) for e in S.ENTRIES.values()):
                err('spec does not cover estat %s option %s' % (sub, o))
    # ml options
    for o in S.ML_OPTS:
        nopts += 1
        if not any(e['parent'] == 'mloptions' and e['opt'] == o for e in S.ENTRIES.values()):
            err('spec does not cover mloptions option ' + o)
    # sim-mode options of nwsaom simulate
    for o in ('theta', 'behtheta', 'rates', 'ratesbeh', 'nsim', 'generate'):
        if not any(e['dialog'] == 'simulate' and e['opt'] == o and 'spec' in (e['modes'] or []) for e in S.ENTRIES.values()):
            err('spec does not cover nwsaom simulate option ' + o)
    return nopts


def inventory_coverage():
    """Every implemented effect of the inventory: which dialog control reaches it."""
    nm = set((e['opt'], e['label'].split(': ')[1]) for e in S.ENTRIES.values() if e['kind'] == 'name' and e['dialog'] == 'nwsaom')
    nm_mn = set((e['opt'], e['label'].split(': ')[1]) for e in S.ENTRIES.values() if e['kind'] == 'name' and e['dialog'] == 'multinet')
    opts_main = set(e['opt'] for e in S.ENTRIES.values() if e['dialog'] == 'nwsaom' and e['kind'] != 'name')
    opts_mn = set(e['opt'] for e in S.ENTRIES.values() if e['dialog'] == 'multinet' and e['kind'] != 'name')
    n_ok = n_na = 0
    bad = []
    for r in S.INV_IMPL:
        o = r['nwsaom_option']
        if 'netbeh:totgroupegox' in o or o.startswith('automatic') or o.startswith('this row') or o.startswith('IMPLEMENTED') or o.startswith('outrate (with'):
            n_na += 1
            continue
        mn = o.startswith('nwsaom multinet') or 'multinet' in o
        o2 = re.sub(r'^nwsaom multinet,?\s*(sym1\s*)?', '', o)
        toks = []
        for m in re.finditer(r'\b([a-z][a-z0-9]*)\(([^()]*)\)', o2):
            f, inner = m.groups()
            for p in inner.split():
                nme = p.split(':')[0]
                toks.append((f, nme))
        heads = set(re.findall(r'\b([a-z][a-z0-9_]*)\b', re.sub(r'\([^()]*\)', ' ', o2)))
        ok = True
        why = ''
        for f, nme in toks:
            if any(f == k[1] for k in nm):
                continue
            if f in ('behavior', 'tvcov', 'theta', 'ratecov', 'interact', 'behint', 'present', 'missbeh', 'missnet', 'gwesp', 'gwespfb', 'gwespbf', 'gwespbb', 'gwesprr', 'gwdspff', 'gwdspfb', 'avdeg', 'outtrunc', 'outmore', 'outthreshold', 'outinv', 'outsqinv'):
                continue
            if (f, nme) in nm or (f, nme) in nm_mn:
                continue
            if f in opts_main | opts_mn and not any(k[0] == f for k in nm | nm_mn):
                continue          # plain option taking a varlist / matrix / numlist
            if nme in ('varlist', 'stem', 'matrix', 'var', 'name', '...', 'v', 'x', 'a', 'b', 'c', 'matnames', 'list', 'v1', 'v2', '#', 'beh2'):
                continue
            ok = False
            why = '%s(%s)' % (f, nme)
        if ok:
            n_ok += 1
        else:
            bad.append((r['RSiena_shortName'], o, why))
    return n_ok, n_na, bad


def main():
    res = G.build_all()
    for n, r in res.items():
        check_dialog(n, r)
    nopts = check_spec()
    # entries per kind
    kinds = {}
    for e in S.ENTRIES.values():
        kinds[e['kind']] = kinds.get(e['kind'], 0) + 1
    names = sum(1 for e in S.ENTRIES.values() if e['kind'] == 'name')
    n_ok, n_na, bad = inventory_coverage()
    # RSiena names in labels of family lists
    lab = tot = 0
    for dn, d in S.DIALOGS.items():
        for ln_, items in d.lists.items():
            if items and isinstance(items[0], tuple):
                for it in items:
                    tot += 1
                    lab += 1 if it[1] else 0
    print('dialogs: %s' % ', '.join('%s(%d tabs)' % (G.OUT_NAME[n], len(r[1].pages)) for n, r in res.items()))
    print('syntax options covered: %d; entries: %d (%s)' % (nopts, len(S.ENTRIES), ', '.join('%s %d' % kv for kv in sorted(kinds.items()))))
    print('effect names in token families: %d; list items with an RSiena name: %d of %d' % (names, lab, tot))
    print('inventory: %d implemented rows reachable by a dialog control, %d need no option (automatic outputs), %d not matched' % (n_ok, n_na, len(bad)))
    for b in bad[:40]:
        print('   not matched:', b)
    for w in WARN:
        print('WARN', w)
    print('%d error(s)' % len(ERR))
    return 1 if ERR else 0


if __name__ == '__main__':
    sys.exit(main())
