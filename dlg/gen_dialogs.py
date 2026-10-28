#!/usr/bin/env python3
"""Generate the nwsaom .dlg files from dlg/nwsaom_dialog_spec.py.

    python3 dlg/gen_dialogs.py            writes nwsaom.dlg, nwsaom_multinet.dlg, ... into the repository root
    python3 dlg/gen_dialogs.py --list     prints the dialogs, tabs and control counts

The same module builds the command text the way the dialog's PROGRAM command does (build_command), which the smoke test
(dlg/smoke_test.py) uses to run every entry in Stata.
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nwsaom_dialog_spec as S  # noqa: E402

ROOT = S.ROOT
TOP, PITCH, YMAX = 10, 21, 376       # first row, row pitch, last row start
RELATED = [('bt_bayes', 'Bayesian estimation...', 'nwsaom_bayes'), ('bt_multinet', 'Several networks (multinet)...', 'nwsaom_multinet'),
           ('bt_multiplex', 'Multiplex...', 'nwsaom_multiplex'), ('bt_estat', 'Postestimation...', 'nwsaom_estat'),
           ('bt_describe', 'Describe data...', 'nwsaom_describe'), ('bt_meta', 'Meta-analysis...', 'nwsaom_meta')]
CHW = 6.4                           # estimated pixels per character
OUT_NAME = {'nwsaom': 'nwsaom', 'multinet': 'nwsaom_multinet', 'bayes': 'nwsaom_bayes', 'meta': 'nwsaom_meta',
            'describe': 'nwsaom_describe', 'multiplex': 'nwsaom_multiplex', 'estat': 'nwsaom_estat'}
HAS_NETLIST = {'nwsaom', 'multinet', 'multiplex', 'describe'}


def san(s):
    return re.sub(r'\s+', ' ', s.replace('"', "'").replace('\\', '/').replace('`', "'").replace('$', 'S'))


def slug(t):
    return re.sub(r'[^a-z0-9]+', '_', t.lower()).strip('_')[:20] or 't'


class Ctl(dict):
    pass


class Page:
    def __init__(self, title):
        self.title = title
        self.ctrls = []
        self.y = TOP
        self.slug = None


# ------------------------------------------------------------------------------------------------ layout
class Layout:
    def __init__(self, d):
        self.d = d
        self.pages = []
        self.ctl_page = {}       # control id -> page
        self.ops = []            # command ops (filled in order)
        self.used_titles = set()
        self.lists = []
        self.warn = []
        self.W = d.width
        self.ymax = d.height - 104
        self.ncol = 4 if d.width >= 1000 else 3
        self.fw = (self.W - 20) // self.ncol
        self.xr = self.W // 2
        self.nf = 3 if d.width >= 1000 else 2
        self.colw = (self.W - 20) // self.nf
        self.halfpx = 185 if self.nf == 3 else 212

    # -- pages
    def newpage(self, title):
        n = 1
        t = title
        while t in self.used_titles:
            n += 1
            t = '%s %d' % (title, n)
        self.used_titles.add(t)
        p = Page(t)
        self.pages.append(p)
        self.page = p
        self.base_title = title
        return p

    def need(self, rows):
        if self.page.y + (rows - 1) * PITCH > self.ymax:
            self.newpage(self.cur_group)

    def add(self, kind, id_, x, w, label=None, opts=None, h='.'):
        p = self.page
        c = Ctl(kind=kind, id=id_, x=x, y=p.y, w=w, h=h, label=label, opts=list(opts or []))
        p.ctrls.append(c)
        self.ctl_page[id_] = p
        return c

    def row(self):
        self.page.y += PITCH

    # -- helpers
    def text(self, id_, x, w, label):
        self.add('TEXT', id_, x, w, label=label)
        need_w = len(label) * CHW
        if need_w > w + 2:
            self.warn.append('label too long for its box (%d chars in %dpx): %s' % (len(label), w, label))

    def put_flag(self, e):
        tip = tooltip(e)
        c = self.add('CHECKBOX', e['id'], self.cx, self.fw - 5, label=san(e['label']), opts=['tooltip("%s")' % tip] if tip else [])
        if len(e['label']) * CHW > self.fw - 15:
            self.warn.append('flag label too long: ' + e['label'])
        return c

    def put_field(self, e, item, x0, half, full_width=None):
        ctl = item['ctl']
        id_ = e['id']
        lab = san(e['label'])
        if half:
            if self.nf == 3:
                lw, cx, cw = 185, x0 + 190, 150
            else:
                lw, cx, cw = 215, x0 + 220, (self.xr - 245 if x0 < 400 else self.W - x0 - 245)
        else:
            lw, cx, cw = 430, 450, self.W - 470
        self.text('tx_' + id_[3:], x0, lw, lab)
        tip = tooltip(e)
        topt = ['tooltip("%s")' % tip] if tip else []
        if ctl == 'varlist':
            self.add('VARLIST', id_, cx, cw, opts=['nomem'] + topt)
        elif ctl == 'edit':
            self.add('EDIT', id_, cx, cw, opts=['nomem'] + topt)
        else:
            lst = item.get('lst')
            o = ['dropdown', 'contents(%s)' % lst]
            if lst in self.d.lists and isinstance(self.d.lists[lst][0], tuple):
                o.append('values(%s_v)' % lst)
            if ctl == 'append':
                o.append('append')
            self.add('COMBOBOX', id_, cx, cw, opts=o + ['nomem'] + topt)

    def is_half(self, e):
        return len(e['label']) * CHW <= self.halfpx

    def build(self):
        d = self.d
        first = True
        for title, items in d.tabs.items():
            self.cur_group = title
            flow = d.width >= 1000 and not first
            if not flow:
                self.newpage(title)
            if first and d.modes:
                self.put_modes()
            first = False
            i = 0
            while i < len(items):
                it = items[i]
                t = it['t']
                if t == 'hdr':
                    self.need(2)
                    if self.page.y > TOP:
                        self.page.y += 6
                    self.text('tx_h%d_%d' % (len(self.page.ctrls), len(self.pages)), 10, self.W - 40, '-- ' + san(it['text']) + ' --')
                    self.row()
                    i += 1
                elif t == 'note':
                    self.need(1)
                    self.text('tx_n%d_%d' % (len(self.page.ctrls), len(self.pages)), 10, self.W - 30, san(it['text']))
                    self.row()
                    i += 1
                elif t == 'flag':
                    run = []
                    while i < len(items) and items[i]['t'] == 'flag':
                        run.append(items[i])
                        i += 1
                    for k in range(0, len(run), self.ncol):
                        self.need(1)
                        for j, f in enumerate(run[k:k + self.ncol]):
                            self.cx = 10 + j * self.fw
                            self.put_flag(S.ENTRIES[f['e']])
                            self.ops_flag(S.ENTRIES[f['e']])
                        self.row()
                elif t == 'field':
                    run = []
                    while i < len(items) and items[i]['t'] == 'field':
                        run.append(items[i])
                        i += 1
                    j = 0
                    while j < len(run):
                        e = S.ENTRIES[run[j]['e']]
                        self.need(1)
                        if self.is_half(e) and not run[j].get('prefix'):
                            self.put_field(e, run[j], 10, True)
                            self.ops_field(e, run[j])
                            c_ = 1
                            while c_ < self.nf and j + 1 < len(run) and self.is_half(S.ENTRIES[run[j + 1]['e']]) and not run[j + 1].get('prefix'):
                                e2 = S.ENTRIES[run[j + 1]['e']]
                                self.put_field(e2, run[j + 1], 10 + c_ * self.colw if self.nf == 3 else self.xr, True)
                                self.ops_field(e2, run[j + 1])
                                j += 1
                                c_ += 1
                        else:
                            self.put_field(e, run[j], 10, False)
                            self.ops_field(e, run[j])
                        self.row()
                        j += 1
                elif t == 'family':
                    self.family(it['fam'])
                    i += 1
                elif t == 'pairs':
                    self.pairs(it)
                    i += 1
                else:
                    raise RuntimeError('item type ' + t)
        self.add_wrappers()
        self.add_related()
        return self

    def add_related(self):
        """Group box 'Related dialogs' with push buttons that open the other nwsaom dialogs (main dialog only), on the last tab."""
        if self.d.name != 'nwsaom':
            return
        p = self.pages[-1]
        y0 = p.y + 14
        self.related = RELATED
        c = Ctl(kind='GROUPBOX', id='gb_related', x=10, y=y0, w=self.W - 40, h=2 * 26 + 30, label=None,
                opts=['label("Related dialogs")'])
        p.ctrls.append(c)
        self.ctl_page['gb_related'] = p
        bw = (self.W - 40 - 40) // 3
        for i, (cid, lab, dn) in enumerate(RELATED):
            b = Ctl(kind='BUTTON', id=cid, x=22 + (i % 3) * (bw + 8), y=y0 + 22 + (i // 3) * 28, w=bw, h=22, label=None,
                    opts=['label("%s")' % lab, 'onpush(program open_%s)' % dn])
            p.ctrls.append(b)
            self.ctl_page[cid] = p
        p.y = y0 + 2 * 26 + 30

    # -- mode radios
    def put_modes(self):
        d = self.d
        modes = d.modes
        self.mode_ctl = {}
        per_row = 3 if len(modes) > 2 else 2
        for k, (m, lab) in enumerate(modes):
            if k and k % per_row == 0:
                self.row()
            kind = 'first' if k == 0 else ('last' if k == len(modes) - 1 else 'middle')
            cid = 'rb_%s_%s' % (d.name, m)
            self.mode_ctl[m] = cid
            x = 10 + (k % per_row) * (300 if per_row == 3 else self.xr - 10)
            self.add('RADIO', cid, x, 290 if per_row == 3 else self.xr - 20, label=san(lab), opts=[kind] + (['default(1)'] if k == 0 else []))
        self.row()
        self.page.y += 6

    # -- family of tokens
    def family(self, fam):
        d = self.d
        opt = fam['opt']
        pre = d.idp + opt
        flags = fam.get('flagnames', [])
        nsl = fam['slots']
        self.spr = 3 if self.nf == 3 else 2
        rows = 1 + math.ceil(len(flags) / self.ncol) + math.ceil(nsl / self.spr) + 1
        self.need(rows)
        argk = fam['arg']
        hint = {'var': 'box next to the effect: variable or tvcov stem',
                'matrix': 'box next to the effect: matrix name',
                'stem': 'box next to the effect: stem of matrices stem1 stem2 ...',
                'param': 'box next to the effect: parameter # (some need one)',
                'paren': 'box: argument of the *covar effects only',
                None: 'box next to the effect is not used',
                'auto': 'box next to the effect: variable / matrix / parameter after the colon'}.get(argk)
        self.text('tx_%s_t' % pre, 10, self.W - 30, '-- ' + san(fam['title']) + ' -- ' + hint)
        self.row()
        flag_ctls = []
        for k in range(0, len(flags), self.ncol):
            for j, nm in enumerate(flags[k:k + self.ncol]):
                self.cx = 10 + j * self.fw
                cid = 'cx_%s_%s' % (pre, nm)
                lab = nm + ((' (%s)' % S.ENTRIES['nm_%s_%s_%s' % (d.name, opt, nm)]['rsiena']) if S.ENTRIES['nm_%s_%s_%s' % (d.name, opt, nm)]['rsiena'] else '')
                self.add('CHECKBOX', cid, self.cx, self.fw - 5, label=san(lab), opts=(['default(1)'] if nm in fam.get('default_on', []) else []))
                flag_ctls.append((cid, nm))
            self.row()
        slots = []
        lst = fam['list']
        o = ['dropdown', 'contents(%s)' % lst, 'values(%s_v)' % lst, 'nomem']
        for k in range(nsl):
            if self.spr == 3:
                x0 = 10 + (k % 3) * self.colw
                cbw, edx, edw = 215, 220, 115
            else:
                x0 = 10 + (k % 2) * (self.xr - 10)
                cbw, edx, edw = self.xr - 190, self.xr - 185, 140
            if k and k % self.spr == 0:
                self.row()
            cb = 'cb_%s_%d' % (pre, k + 1)
            ar = 'ed_%s_%da' % (pre, k + 1)
            self.add('COMBOBOX', cb, x0, cbw, opts=o)
            self.add('EDIT', ar, x0 + edx, edw, opts=['nomem'])
            slots.append((cb, ar))
        self.row()
        more = 'ed_%s_more' % pre
        self.text('tx_%s_more' % pre, 10, 215, 'more tokens (typed)')
        self.add('EDIT', more, 230, self.W - 250, opts=['nomem'])
        self.row()
        self.page.y += 6
        self.ops.append(('family', opt, flag_ctls, slots, more, argk, None))
        # entries of the family get their control id
        for eid in fam['entry_ids']:
            e = S.ENTRIES[eid]
            nm = eid.split('_', 3)[-1] if False else e['label'].split(': ')[1]
            e['ctl'] = 'cx_%s_%s' % (pre, nm) if nm in flags else None

    def pairs(self, it):
        d = self.d
        opt = it['opt']
        n = it['n']
        lst = it['lst']
        self.need(2 + math.ceil(n / 2) + 1)
        self.text('tx_%s_t' % opt, 10, self.W - 30, '-- interact(): pick two effects of the model per line (product of the two) --')
        self.row()
        prs = []
        for k in range(n):
            x0 = 10 + (k % 2) * (self.xr - 10)
            if k and k % 2 == 0:
                self.row()
            c1, c2 = 'cb_%s_%da' % (opt, k + 1), 'cb_%s_%db' % (opt, k + 1)
            self.add('COMBOBOX', c1, x0, 200, opts=['dropdown', 'contents(%s)' % lst, 'nomem'])
            self.text('tx_%s_%dh' % (opt, k + 1), x0 + 205, 12, '#')
            self.add('COMBOBOX', c2, x0 + 220, 200, opts=['dropdown', 'contents(%s)' % lst, 'nomem'])
            prs.append((c1, c2))
        self.row()
        more = it['more']
        e = S.ENTRIES[more]
        self.text('tx_' + more[3:], 10, 430, san(e['label']))
        self.add('EDIT', more, 450, self.W - 470, opts=['nomem'])
        self.row()
        self.ops.append(('pairs', opt, prs, more))

    # -- ops for plain entries
    def ops_flag(self, e):
        if e['parent']:
            return
        self.ops.append(('flag', e['id'], e['cmd'], e['modes']))

    def ops_field(self, e, item):
        if e['parent']:
            return
        if e.get('arg') == 'names':
            self.ops.append(('raw', e['id'], e['modes']))
            return
        self.ops.append(('val', e['id'], e['opt'], e['modes']))

    def add_wrappers(self):
        for e in S.ENTRIES.values():
            if e['kind'] == 'wrapper' and e['dialog'] == self.d.name:
                ch = []
                for cid in e['children']:
                    c = S.ENTRIES[cid]
                    ch.append((cid, c['kind'], c['opt']))
                self.ops.append(('group', e['opt'], ch, e['modes']))


def tooltip(e):
    bits = []
    if e.get('tip'):
        bits.append(e['tip'])
    if e.get('rsiena'):
        bits.append('RSiena: %s' % e['rsiena'])
    if e.get('plugin'):
        bits.append('native plugin only')
    if e.get('cond'):
        bits.append('for: %s' % e['cond'])
    return san('. '.join(bits))[:150]


# ------------------------------------------------------------------------------------------------ command program
def mode_cond(d, lay, modes):
    if modes is None or not d.modes:
        return None
    ctls = ['%s.%s' % (lay.ctl_page[lay.mode_ctl[m]].slug, lay.mode_ctl[m]) for m in modes]
    return ' | '.join(ctls)


def q(lay, cid):
    return '%s.%s' % (lay.ctl_page[cid].slug, cid)


def render_ops(d, lay):
    L = []

    def emit(s, ind=1):
        L.append('\t' * ind + s)

    for op in lay.ops:
        kind = op[0]
        modes = op[-1] if kind in ('flag', 'val', 'raw', 'group') else None
        cond = mode_cond(d, lay, modes) if kind in ('flag', 'val', 'raw', 'group') else None
        ind = 3
        if cond:
            emit('if %s {' % cond, ind)
            ind += 1
        if kind == 'flag':
            emit('if %s {' % q(lay, op[1]), ind)
            emit('put "%s"' % op[2], ind + 1)
            emit('}', ind)
        elif kind == 'val':
            emit('if %s.isneq("") {' % q(lay, op[1]), ind)
            emit('put " %s(" %s ")"' % (op[2], q(lay, op[1])), ind + 1)
            emit('}', ind)
        elif kind == 'raw':
            emit('if %s.isneq("") {' % q(lay, op[1]), ind)
            emit('put " " %s' % q(lay, op[1]), ind + 1)
            emit('}', ind)
        elif kind == 'group':
            names = [(c[0]) for c in op[2]]
            anyc = ' | '.join(q(lay, c) for c in names)
            emit('if %s {' % anyc, ind)
            emit('put " %s("' % op[1], ind + 1)
            for cid, ck, nm in op[2]:
                if ck == 'flag':
                    emit('if %s {' % q(lay, cid), ind + 1)
                    emit('put "%s "' % nm, ind + 2)
                    emit('}', ind + 1)
                else:
                    emit('if %s.isneq("") {' % q(lay, cid), ind + 1)
                    emit('put "%s(" %s ") "' % (nm, q(lay, cid)), ind + 2)
                    emit('}', ind + 1)
            emit('put ")"', ind + 1)
            emit('}', ind)
        elif kind == 'family':
            _, opt, flags, slots, more, argk, _m = op
            anyc = ' | '.join([q(lay, c) for c, _n in flags] + [q(lay, cb) for cb, _a in slots] + [q(lay, more)])
            emit('if %s {' % anyc, ind)
            emit('put " %s("' % opt, ind + 1)
            for cid, nm in flags:
                emit('if %s {' % q(lay, cid), ind + 1)
                emit('put "%s "' % nm, ind + 2)
                emit('}', ind + 1)
            for cb, ar in slots:
                emit('if %s.isneq("") {' % q(lay, cb), ind + 1)
                emit('put %s' % q(lay, cb), ind + 2)
                emit('if %s.isneq("") {' % q(lay, ar), ind + 2)
                if argk == 'paren':
                    emit('put "(" %s ")"' % q(lay, ar), ind + 3)
                else:
                    emit('put ":" %s' % q(lay, ar), ind + 3)
                emit('}', ind + 2)
                emit('put " "', ind + 2)
                emit('}', ind + 1)
            emit('if %s.isneq("") {' % q(lay, more), ind + 1)
            emit('put %s' % q(lay, more), ind + 2)
            emit('}', ind + 1)
            emit('put ")"', ind + 1)
            emit('}', ind)
        elif kind == 'pairs':
            _, opt, prs, more = op
            anyc = ' | '.join(['%s.isneq("") & %s.isneq("")' % (q(lay, a), q(lay, b)) for a, b in prs] + ['%s.isneq("")' % q(lay, more)])
            emit('if %s {' % anyc, ind)
            emit('put " %s("' % opt, ind + 1)
            for a, b in prs:
                emit('if %s.isneq("") & %s.isneq("") {' % (q(lay, a), q(lay, b)), ind + 1)
                emit('put %s "#" %s " "' % (q(lay, a), q(lay, b)), ind + 2)
                emit('}', ind + 1)
            emit('if %s.isneq("") {' % q(lay, more), ind + 1)
            emit('put %s' % q(lay, more), ind + 2)
            emit('}', ind + 1)
            emit('put ")"', ind + 1)
            emit('}', ind)
        if cond:
            emit('}', ind - 1)
    return L


def command_program(d, lay):
    L = ['PROGRAM command', 'BEGIN']
    pre = None
    if d.modes:
        for m, _lab in d.modes:
            L.append('\tif %s {' % q(lay, lay.mode_ctl[m]))
            L.append('\t\tput "%s"' % d.sub_prefix[m])
            L.append('\t}')
    else:
        L.append('\tput "%s"' % d.prefix)
    # positional (names) entries come before the options
    raws = [op for op in lay.ops if op[0] == 'raw']
    rest = [op for op in lay.ops if op[0] != 'raw']
    for op in raws:
        L.append('\trequire %s' % q(lay, op[1]))
        L.append('\tput " " %s' % q(lay, op[1]))
    # The dialog engine rejects (r(1001)) a PROGRAM that is too long, so the option code is split into sub-programs of
    # at most ~100 lines each, called with `put /program` inside beginoptions.
    chunks = []
    cur = []
    for op in rest:
        lay_ops = lay.ops
        lay.ops = [op]
        ls = render_ops(d, lay)
        lay.ops = lay_ops
        if cur and len(cur) + len(ls) > 100:
            chunks.append(cur)
            cur = []
        cur.extend(ls)
    if cur:
        chunks.append(cur)
    L.append('\tbeginoptions')
    for k in range(len(chunks)):
        L.append('\t\tput /program opt_part%d' % (k + 1))
    L.append('\tendoptions')
    L.append('\tstata')
    L.append('END')
    for k, ch in enumerate(chunks):
        L += ['', 'PROGRAM opt_part%d' % (k + 1), 'BEGIN'] + ch + ['END']
    return L


# ------------------------------------------------------------------------------------------------ emitters
def dlg_text(d, lay):
    maxy = max(p.y for p in lay.pages)
    height = d.height if len(lay.pages) > 1 or maxy + 100 > d.height else int(min(d.height, max(260, maxy + 100)))
    if len(lay.pages) == 1:
        height = int(min(d.height, max(260, maxy + 100)))
    width = d.width
    # tab slugs
    seen = set()
    for p in lay.pages:
        s = slug(p.title)
        k = 1
        base = s
        while s in seen:
            k += 1
            s = '%s%d' % (base, k)
        seen.add(s)
        p.slug = s
    L = ['VERSION 10', '', '', 'SYNCHRONOUS_ONLY', 'INCLUDE _std_mlarge', 'DEFINE _dlgwd %d' % width, 'DEFINE _dlght %d' % height,
         'INCLUDE header', '', 'HELP hlp1, view("help %s")' % d.help, 'RESET res1', '']
    if d.name in HAS_NETLIST:
        L += ['SCRIPT PREINIT', 'BEGIN', '\tprogram initialize', 'END', '']
    for p in lay.pages:
        L.append('DIALOG %s, tabtitle("%s")' % (p.slug, san(p.title)))
        L.append('BEGIN')
        for c in p.ctrls:
            k = c['kind']
            opts = list(c['opts'])
            if c['label'] is not None and k in ('CHECKBOX', 'RADIO', 'TEXT'):
                opts.insert(0, 'label("%s")' % c['label'])
            L.append('  %s %s %d %d %d %s%s' % (k, c['id'], c['x'], c['y'], c['w'], c['h'], (', ' + ' '.join(opts)) if opts else ''))
        L.append('END')
        L.append('')
    # lists
    if d.name in HAS_NETLIST:
        L += ['LIST netlist', 'BEGIN', '\t// populated at runtime by _nwdialog.ado', 'END', '']
    for name, items in d.lists.items():
        if name == 'netlist':
            continue
        L += ['LIST %s' % name, 'BEGIN']
        for it in items:
            if isinstance(it, tuple):
                L.append('\t%s' % (san(it[0]) + (('  (%s)' % san(it[1])) if it[1] else '')))
            else:
                L.append('\t%s' % san(it))
        L += ['END', '']
        if items and isinstance(items[0], tuple):
            L += ['LIST %s_v' % name, 'BEGIN'] + ['\t%s' % san(it[0]) for it in items] + ['END', '']
    if d.name in HAS_NETLIST:
        L += ['PROGRAM initialize', 'BEGIN', '\tput "_nwdialog %s"' % OUT_NAME[d.name], '\tstata hidden immediate', 'END', '']
    if d.name == 'nwsaom':
        for cid, lab, dn in RELATED:
            L += ['PROGRAM open_%s' % dn, 'BEGIN', '\tput "db %s"' % dn, '\tstata hidden', 'END', '']
    L += command_program(d, lay)
    return '\n'.join(L) + '\n', width, height


def lab_ck(c):
    return ', label("%s")' % c['label']


# ------------------------------------------------------------------------------------------------ emulation
def build_command(d, lay, values):
    """The command text the dialog's PROGRAM command builds for `values` (control id -> str|0/1).  Mirrors command_program()."""
    def v(cid):
        x = values.get(cid, '')
        return x

    def nz(cid):
        x = v(cid)
        return bool(x) and x != '0'

    out = []
    if d.modes:
        sel = [m for m, _ in d.modes if nz(lay.mode_ctl[m])]
        sel = sel[:1] if sel else [d.modes[0][0]]
        mode = sel[0]
        out.append(d.sub_prefix[mode])
    else:
        mode = None
        out.append(d.prefix)
    ops = lay.ops

    def active(modes):
        return modes is None or not d.modes or mode in modes

    for op in ops:
        if op[0] == 'raw' and active(op[-1]) and v(op[1]) != '':
            out.append(' ' + v(op[1]))
    for op in ops:
        k = op[0]
        if k == 'flag' and active(op[3]) and nz(op[1]):
            out.append(op[2])
        elif k == 'val' and active(op[3]) and v(op[1]) != '':
            out.append(' %s(%s)' % (op[2], v(op[1])))
        elif k == 'group' and active(op[3]):
            names = [c[0] for c in op[2]]
            if any(nz(c) for c in names):
                s = ' %s(' % op[1]
                for cid, ck, nm in op[2]:
                    if ck == 'flag':
                        if nz(cid):
                            s += nm + ' '
                    elif v(cid) != '':
                        s += '%s(%s) ' % (nm, v(cid))
                out.append(s + ')')
        elif k == 'family':
            _, opt, flags, slots, more, argk, _m = op
            if any(nz(c) for c, _n in flags) or any(v(cb) != '' for cb, _a in slots) or v(more) != '':
                s = ' %s(' % opt
                for cid, nm in flags:
                    if nz(cid):
                        s += nm + ' '
                for cb, ar in slots:
                    if v(cb) != '':
                        s += v(cb)
                        if v(ar) != '':
                            s += ('(%s)' % v(ar)) if argk == 'paren' else (':' + v(ar))
                        s += ' '
                if v(more) != '':
                    s += v(more)
                out.append(s + ')')
        elif k == 'pairs':
            _, opt, prs, more = op
            if any(v(a) != '' and v(b) != '' for a, b in prs) or v(more) != '':
                s = ' %s(' % opt
                for a, b in prs:
                    if v(a) != '' and v(b) != '':
                        s += '%s#%s ' % (v(a), v(b))
                if v(more) != '':
                    s += v(more)
                out.append(s + ')')
    head = out[0]
    pos = ''.join(x for x in out[1:] if x.startswith(' ') and not re.match(r'^ [a-z0-9_]+(\(|$)', x))
    # positional text (raw entries) comes first in `out`; options have the form " name" or " name(...)"
    raws = []
    opts = []
    for op in ops:
        pass
    # rebuild cleanly: raws are the first entries appended before any option
    n_raw = sum(1 for op in ops if op[0] == 'raw' and active(op[-1]) and v(op[1]) != '')
    raws = out[1:1 + n_raw]
    opts = out[1 + n_raw:]
    text = head + ''.join(raws)
    if opts:
        text += ',' + ''.join(opts)
    return text


# ------------------------------------------------------------------------------------------------ driver
def build_all():
    res = {}
    for name, d in S.DIALOGS.items():
        lay = Layout(d).build()
        txt, w, h = dlg_text(d, lay)
        res[name] = (d, lay, txt, w, h)
    return res


def main(argv):
    res = build_all()
    if '--list' in argv:
        for name, (d, lay, txt, w, h) in res.items():
            n = sum(len(p.ctrls) for p in lay.pages)
            print('%-10s %dx%d  %d tabs  %d controls  %d lines' % (name, w, h, len(lay.pages), n, txt.count('\n')))
            for p in lay.pages:
                print('    %-26s %3d controls  y_end=%d' % (p.title, len(p.ctrls), p.y))
            for wmsg in lay.warn:
                print('    WARN', wmsg)
        return 0
    for name, (d, lay, txt, w, h) in res.items():
        fn = os.path.join(ROOT, OUT_NAME[name] + '.dlg')
        with open(fn, 'w', encoding='ascii', errors='replace', newline='\n') as f:
            f.write(txt)
        print('wrote', fn, '(%d tabs, %d controls)' % (len(lay.pages), sum(len(p.ctrls) for p in lay.pages)))
        for wmsg in lay.warn:
            print('  WARN', wmsg)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
