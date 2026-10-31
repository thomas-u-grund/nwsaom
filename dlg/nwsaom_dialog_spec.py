"""Specification of the nwsaom dialog boxes (single source of truth).

The spec is BUILT at import time from
  * the `syntax` lines of the ado files (every option of every command),
  * docs/SAOM_EFFECTS_INVENTORY.csv (every implemented effect and its nwsaom option),
  * the {synopt} paragraphs of the help files (native-plugin remarks),
plus the curated layout tables in this file (tab, group, label, companion options).

An ENTRY is one thing the user can set:
    id        unique id; also the control id (prefix cx_ flag, ed_ edit, vl_ varlist, cb_ combo, sl_ token slot)
    dialog    nwsaom | multinet | bayes | meta | describe | multiplex | estat
    tab       tab title (the generator paginates a tab that does not fit)
    kind      flag | edit | varlist | combo | appendlist | wrapped | name   (name = one effect name inside a token family)
    label     text in the dialog; carries the nwsaom option AND the RSiena name
    opt       the command-line option the entry feeds
    cmd       exact command text produced (template, {v} = the value)
    rsiena    RSiena effect name(s)
    plugin    needs the native plugin
    cond      condition under which the entry is valid (symmetric / directed / twomode / behavior ...)
    companion options that must be given as well for the entry to run on its own (used by the smoke test)
    ctx       data context for the smoke test (dir, sym, two, beh, mn ...)
    help      help anchor (help file name)

Families (token lists) are `FAMILIES`: an option such as netx(altdist2:x totdist2:x) is a list of tokens; the dialog has
slot rows (a combobox with all effect names, labelled with the RSiena name, plus an argument field) and one free-text field.
Each effect name of a family is an entry of kind `name` and is tested separately.
"""
import csv
import os
import re
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


# --------------------------------------------------------------------------------------------------- parsing
def read(p):
    with open(os.path.join(ROOT, p), encoding='utf-8', errors='replace') as f:
        return f.read()


def syntax_options(ado, after=None):
    """Options of the `syntax` command of an ado file as OrderedDict name -> kind (flag|string|numlist|integer|real|name|cilevel)."""
    lines = read(ado).split('\n')
    start = None
    for i, l in enumerate(lines):
        if re.match(r'^\s*syntax\b', l) and (after is None or after in l or True):
            if after and after not in ''.join(lines[i:i + 3]):
                continue
            start = i
            break
    if start is None:
        raise RuntimeError('no syntax line in ' + ado)
    txt = []
    i = start
    while True:
        l = lines[i]
        txt.append(l.replace('///', ' '))
        if not l.rstrip().endswith('///'):
            break
        i += 1
    s = ' '.join(txt)
    s = re.sub(r'^\s*syntax', '', s)
    pre, _, opts = s.partition(',')
    out = OrderedDict()
    # tokens NAME or NAME(type...) ; a type may contain a nested blank-separated spec
    for m in re.finditer(r'([A-Za-z][A-Za-z0-9_]*)\s*(\(([^)]*)\))?', opts):
        name, _, typ = m.group(1), m.group(2), m.group(3)
        if name in ('lower', 'upper'):
            continue
        low = name.lower()
        if typ is None:
            kind = 'flag'
        else:
            t = typ.split()[0] if typ.split() else 'string'
            kind = {'string': 'string', 'numlist': 'numlist', 'integer': 'integer', 'real': 'real',
                    'name': 'name', 'cilevel': 'cilevel'}.get(t, 'string')
        out[low] = (kind, typ)
    return out, pre.strip()


def help_paragraphs(sthlp):
    """Map option name -> text of its {synopt} paragraph (first words only needed: native plugin remark)."""
    t = read(sthlp)
    res = {}
    for m in re.finditer(r'\{synopt:(.*?)\{p_end\}', t, re.S):
        para = m.group(1)
        head = para.split('}}', 1)[0]
        for o in re.findall(r'\{opth? ([a-z0-9_]+)', head) + re.findall(r'\{opt ([a-z0-9_]+)', head):
            res.setdefault(o, '')
            res[o] += ' ' + para
    return res


def load_inventory():
    rows = list(csv.DictReader(open(os.path.join(ROOT, 'docs', 'SAOM_EFFECTS_INVENTORY.csv'), encoding='utf-8')))
    return rows


INV = load_inventory()
INV_IMPL = [r for r in INV if r['nwsaom_status'].startswith('IMPL')]
CTXMAP = {'one-mode network': 'dir', 'non-directed network': 'sym', 'two-mode network': 'two', 'behavior': 'beh',
          'behavior (non-directed network)': 'beh', 'rate (one-mode network)': 'dir', 'rate (behavior)': 'beh',
          'rate (non-directed network)': 'sym', 'rate (two-mode network)': 'two', 'rate (behavior (non-directed network))': 'beh'}
ARGKIND = {'var': 'var', 'beh2': 'var', 'tvstem': 'var', 'varlist': 'var', 'behavior': 'var', 'stem': 'stem', 'matrix': 'matrix'}


def inventory_families():
    """fam -> OrderedDict name -> dict(rsiena=set, args=set, ctx=set)"""
    fam = OrderedDict()
    for r in INV_IMPL:
        o = r['nwsaom_option']
        o = re.sub(r'^nwsaom multinet,?\s*(sym1\s*)?', '', o)
        for m in re.finditer(r'\b([a-z][a-z0-9]*)\(([^()]*)\)', o):
            f, inner = m.groups()
            inner = inner.strip()
            if not inner:
                continue
            parts = inner.split()
            for p in parts:
                if ':' in p:
                    nm, _, a = p.partition(':')
                else:
                    nm, a = p, ''
                if not re.match(r'^[a-z][a-z0-9_]*$', nm) or nm in ('varlist', 'stem', 'matrix', 'var', 'name'):
                    continue
                d = fam.setdefault(f, OrderedDict()).setdefault(nm, dict(rsiena=set(), args=set(), ctx=set()))
                d['rsiena'].add(r['RSiena_shortName'])
                d['args'].add(a)
                d['ctx'].add(CTXMAP.get(r['variable_type'], 'dir'))
    return fam


INVFAM = inventory_families()

# ---------------------------------------------------------------------------------------------- option tables
MAIN_OPTS, _ = syntax_options('nwsaom.ado')
BAYES_OPTS, _ = syntax_options('nwsaom_bayes.ado')
META_OPTS, _ = syntax_options('nwsaom_meta.ado')
ML_OPTS, _ = syntax_options('nwsaom_ml.ado')
MN_OPTS, _ = syntax_options('nwsaom_multinet.ado')
MX_OPTS, _ = syntax_options('nwsaom_multiplex.ado')
DESC_OPTS, _ = syntax_options('nwsaom_describe.ado')
ESTAT_GOF, _ = syntax_options('nwsaom_estat.ado', 'NSIM')
ESTAT_SCORE, _ = syntax_options('nwsaom_estat_score.ado')
ESTAT_TT, _ = syntax_options('nwsaom_estat_timetest.ado')
ESTAT_SIM, _ = syntax_options('nwsaom_estat_simulate.ado')


def mems_opts():
    lines = read('nwsaom_estat.ado').split('\n')
    for l in lines:
        if re.match(r'^\s*syntax , EFFECT', l):
            # reuse the parser on a synthetic one-line file
            s = re.sub(r'^\s*syntax', '', l)
            pre, _, o = s.partition(',')
            res = OrderedDict()
            for m in re.finditer(r'([A-Za-z]+)\s*(\(([^)]*)\))?', o):
                res[m.group(1).lower()] = ('flag' if m.group(2) is None else m.group(3).split()[0], m.group(3))
            return res
    raise RuntimeError('mems syntax not found')


ESTAT_MEMS = mems_opts()
HELP_MAIN = help_paragraphs('nwsaom.sthlp')

RS = {}   # flag/option head -> RSiena name
for r in INV_IMPL:
    o = r['nwsaom_option']
    m = re.fullmatch(r'([a-z][a-z0-9]*)(\((varlist|var|#|c|matrix|matnames|stem|matname|list)?\))?', o.strip())
    if m and m.group(1) not in RS:
        RS[m.group(1)] = r['RSiena_shortName']
RS.update({'outdegree': 'density', 'reciprocity': 'recip', 'nodematch': 'sameX', 'nodecov': 'altX+egoX', 'nodeicov': 'altX',
           'nodeocov': 'egoX', 'simcov': 'simX', 'egox': 'egoX', 'altx': 'altX', 'samex': 'sameX', 'simx': 'simX',
           'indegpopularity': 'inPopSqrt', 'outpopularity': 'outPopSqrt', 'outactivity': 'outAct', 'inactivity': 'inActSqrt',
           'gwesp': 'gwesp', 'transties': 'transTies', 'balance': 'balance', 'transtrip': 'transTrip', 'cycle3': 'cycle3',
           'inplus3': 'in3Plus', 'dyadcov': 'X', 'dyadcovrecip': 'XRecip', 'tvdyadcov': 'X (changing)',
           'tvdyadcovrecip': 'XRecip (changing)', 'behsim': 'simX (beh)', 'behegox': 'egoX (beh)',
           'behaltx': 'altX (beh)', 'behegoplusalt': 'egoPlusAltX (beh)', 'linear': 'linear', 'quadratic': 'quad',
           'avalt': 'avAlt', 'avsim': 'avSim', 'behfrom': 'effFrom', 'outrate': 'outRate', 'inrate': 'inRate',
           'reciprate': 'recipRate', 'ratecov': 'RateX'})


# network types an option applies to (D directed, U undirected, B two-mode), derived from the effects inventory: RSiena lists
# effects per variable type ("one-mode network" = directed, "non-directed network", "two-mode network"); behavior, rate-of-behavior
# and gmm rows apply to every network type. An option with no row of its own (setup options) applies to all types.
TYPE_LETTER = {'one-mode network': 'D', 'non-directed network': 'U', 'two-mode network': 'B',
               'rate (one-mode network)': 'D', 'rate (non-directed network)': 'U', 'rate (two-mode network)': 'B',
               'gmm (one-mode network)': 'D', 'gmm (non-directed network)': 'U', 'gmm (two-mode network)': 'B',
               'behavior (non-directed network)': 'U', 'rate (behavior (non-directed network))': 'U'}


def option_nets():
    """option head -> set of letters; options that also occur in a row of a type-free variable (behavior ...) get UDB."""
    out = {}
    for r in INV_IMPL:
        letter = TYPE_LETTER.get(r['variable_type'], 'UDB')
        for part in r['nwsaom_option'].split(','):
            m = re.match(r'^\s*([a-z][a-z0-9]*)\s*(\(.*\))?\s*(\(.*\))?$', part)
            if m and not r['nwsaom_option'].startswith('nwsaom multinet'):
                out.setdefault(m.group(1), set()).update(letter)
    return out


OPTION_NETS = option_nets()
COND_NETS = {'twomode': 'B', 'symmetric': 'U', 'directed': 'D'}


def nets_of(opt, cond, dialog):
    if dialog != 'nwsaom':
        return 'UDB'
    if cond in COND_NETS:
        return COND_NETS[cond]
    if opt in FAMILY_DEF or opt not in OPTION_NETS:
        return 'UDB'
    return ''.join(c for c in 'UDB' if c in OPTION_NETS[opt])


def rs(opt):
    return RS.get(opt, '')


def plugin_only(opt):
    t = HELP_MAIN.get(opt, '').lower()
    return ('native plugin only' in t) or ('native only' in t) or ('there is no mata implementation' in t)


# ---------------------------------------------------------------------------------------------- families
# slot families of the main dialog: option -> (argument kind, label, group of names)
FAMILY_DEF = OrderedDict([
    # opt        arg      title                                          slots
    ('ownx',     ('param', 'ownx() - own-network effects (RSiena effects without covariate)', 6)),
    ('netx',     ('var',   'netx() - network effects of a covariate: effect:variable', 6)),
    ('netbeh',   (None,    'netbeh() - network effects with the dependent behavior as covariate', 6)),
    ('dyadx',    ('matrix', 'dyadx() - effects of a constant dyadic covariate: effect:matrix', 6)),
    ('tvdyadx',  ('stem',  'tvdyadx() - changing dyadic covariate: effect:stem (matrices stem1 stem2 ...)', 4)),
    ('beheff',   (None,    'beheff() - behavior effects of network position, alters and similarity', 6)),
    ('behshape', ('param', 'behshape() - further behavior shape effects: effect[:#]', 4)),
    ('behnet2',  ('param', 'behnet2() - further behavior effects of the network: effect[:#]', 6)),
    ('behx',     ('var',   'behx() - behavior effects of network x covariate: effect:variable', 6)),
    ('behw',     ('matrix', 'behw() - behavior effects of network x dyadic covariate: effect:matrix', 4)),
    ('tvbehw',   ('stem',  'tvbehw() - the same with a changing dyadic covariate: effect:stem', 4)),
    ('behrate',  ('paren', 'behrate() - network-dependent rate effects of the behavior', 4)),
])
# alias options that are only a list-valued synonym
EXTRA_NAMES = {
    'behrate': ['susceptavcovar', 'infectcovar'],
}
# names in the inventory that are not names of the family (parsing noise)
DROP_NAMES = {'...', 'x', 'v', 'a', 'b', 'c', 'stem', 'beh2'}

PARAM_REQUIRED = {}  # name -> True if the parameter after ':' is required


def family_names(opt):
    d = INVFAM.get(opt, OrderedDict())
    names = OrderedDict()
    for nm, v in d.items():
        if nm in DROP_NAMES:
            continue
        names[nm] = v
    for nm in EXTRA_NAMES.get(opt, []):
        names.setdefault(nm, dict(rsiena=set(), args=set(), ctx={'dir'}))
    return OrderedDict(sorted(names.items()))


def pick_ctx(ctxs):
    for c in ('dir', 'beh', 'sym', 'two'):
        if c in ctxs:
            return c
    return 'dir'


# cross-network (multinet) vocabulary
CROSS_BEHAVIOR_ARG = {'var'}


# ================================================================================================= entries
ENTRIES = OrderedDict()
DIALOGS = OrderedDict()
EXCLUDED = []       # (dialog, option, reason): options deliberately not offered


def default_of(typ):
    if not typ:
        return None
    w = typ.split()
    if len(w) >= 2 and w[0] in ('integer', 'real'):
        return w[1]
    return None


def E(id, dialog, kind, opt, label, tab=None, **kw):
    if id in ENTRIES:
        raise RuntimeError('duplicate entry id ' + id)
    e = dict(id=id, dialog=dialog, kind=kind, opt=opt, label=label, tab=tab, rsiena=kw.pop('rsiena', rs(opt)),
             plugin=kw.pop('plugin', plugin_only(opt) if dialog == 'nwsaom' else False), cond=kw.pop('cond', ''),
             companion=kw.pop('companion', ''), ctx=kw.pop('ctx', 'dir'), help=kw.pop('help', 'nwsaom'),
             modes=kw.pop('modes', None), parent=kw.pop('parent', None), value=kw.pop('value', None),
             family=kw.pop('family', None), arg=kw.pop('arg', None), tip=kw.pop('tip', ''))
    e['nets'] = kw.pop('nets', None) or nets_of(opt, e['cond'], dialog)
    e.update(kw)
    ENTRIES[id] = e
    return e


class Dlg:
    def __init__(self, name, title, helpname, prefix, width=940, height=480):
        self.name, self.title, self.help, self.prefix = name, title, helpname, prefix
        self.tabs = OrderedDict()
        self.modes = None          # list of (mode, label) -> radio group on the first tab
        self.lists = OrderedDict()
        self.width, self.height = width, height
        self.idp = '' if name == 'nwsaom' else name + '_'
        self.sub_prefix = {}       # mode -> command prefix
        DIALOGS[name] = self

    def tab(self, title):
        return self.tabs.setdefault(title, [])


def short_label(opt, extra=''):
    r = rs(opt)
    lab = opt
    if extra:
        lab += extra
    if r and r.lower() != opt:
        lab += ' (' + r + ')'
    return lab


def flag(d, tab, id_, opt, label=None, **kw):
    kw.setdefault('help', d.help)
    e = E('cx_' + d.idp + id_, d.name, 'flag', opt, label or short_label(opt), tab, cmd=' ' + opt, **kw)
    d.tab(tab).append(dict(t='flag', e=e['id']))
    return e


def field(d, tab, id_, opt, label=None, ctl='edit', lst=None, pre='', **kw):
    kw.setdefault('help', d.help)
    pfx = {'edit': 'ed_', 'varlist': 'vl_', 'combo': 'cb_', 'append': 'cb_'}[ctl]
    e = E(pfx + d.idp + id_, d.name, ctl if ctl != 'append' else 'appendlist', opt, label or (short_label(opt, '()')), tab,
          cmd=' ' + opt + '({v})', lst=lst, **kw)
    d.tab(tab).append(dict(t='field', e=e['id'], ctl=ctl, lst=lst))
    return e


def hdr(d, tab, text):
    d.tab(tab).append(dict(t='hdr', text=text))


def note(d, tab, text, lines=1):
    d.tab(tab).append(dict(t='note', text=text, lines=lines))


# ------------------------------------------------------------------------------------ the main dialog
M = Dlg('nwsaom', 'nwsaom - stochastic actor-oriented model (SAOM) estimation', 'nwsaom', 'nwsaom', 1080, 600)
EST = ['est']
MN = M.name
T = 'Waves'
hdr(M, T, 'Observed waves (a dependent network per wave: waves() with two or more networks, or the older wave1()/wave2() for exactly two)')
field(M, T, 'wave1', 'wave1', 'wave1() - first wave (older spelling for two waves)', 'combo', 'netlist', ctx='dir')
field(M, T, 'wave2', 'wave2', 'wave2() - second wave (with wave1())', 'combo', 'netlist')
field(M, T, 'waves', 'waves', 'waves() - netlist, 2+ networks in time order', 'append', 'netlist')
field(M, T, 'tvcov', 'tvcov', 'tvcov() - changing covariates a1 a2 a3 | s1 s2 s3')
field(M, T, 'actormode', 'actormode', 'actormode() - two-mode actor mode (1|2)', cond='twomode', ctx='two')
hdr(M, T, 'Baseline: outdegree is required unless split into endowment + creation (reciprocity is optional)')
for o in ('outdegree', 'degree', 'density', 'reciprocity', 'outdegreeendow', 'outdegreecreation', 'reciprocityendow', 'reciprocitycreation',
          'transtiesendow', 'transtiescreation'):
    flag(M, T, o, o, modes=None)
M.lists['endow_list'] = ['outdegree', 'reciprocity', 'transties', 'cycle4', 'gwesp', 'balance', 'transtrip', 'cycle3',
                         'transmedtrip', 'transrectrip', 'linear', 'quadratic', 'avalt', 'avsim', 'indegpopularity',
                         'outpopularity', 'outactivity', 'inactivity', 'inpop', 'outpop', 'inact', 'outactsqrt']
field(M, T, 'endow', 'endow', 'endow() - effects split into endowment', 'append', 'endow_list',
      tip='Name the same effect in endow() and creation(); covariate effects as altx:var')
field(M, T, 'creation', 'creation', 'creation() - the same effects, creation role', 'append', 'endow_list')
hdr(M, T, 'Undirected networks')
flag(M, T, 'symmetric', 'symmetric', 'symmetric (non-directed network)')
M.lists['symtype_list'] = ['forcing', 'confirmation', 'force', 'agree', 'joint']
field(M, T, 'symtype', 'symtype', 'symtype() - model type for undirected ties', 'combo', 'symtype_list', cond='symmetric',
      companion='symmetric', ctx='sym')

T = 'Structure'
hdr(M, T, 'Degree-based effects (flags)')
for o in ('indegpopularity', 'outpopularity', 'outactivity', 'inactivity', 'inpop', 'outpop', 'inact', 'outactsqrt',
          'inpopc', 'outpopc', 'outactc', 'inactc', 'degplus', 'degplusc', 'recipop', 'recipopsqrt', 'reciact', 'reciactsqrt',
          'between'):
    flag(M, T, o, o)
hdr(M, T, 'Degree effects with a parameter (number or numlist)')
for o in ('outtrunc', 'outmore', 'outthreshold', 'outinv', 'outsqinv', 'avdeg'):
    field(M, T, o, o)

T = 'Structure'
hdr(M, T, 'Triadic closure, cycles, balance (flags)')
for o in ('transtrip', 'transmedtrip', 'transrectrip', 'cycle3', 'cycle4', 'sqrtcycle4', 'dblnbrdist2', 'nbrdist2',
          'transties', 'balance', 'transtriads'):
    flag(M, T, o, o)
hdr(M, T, 'Geometrically weighted effects: give the decay parameter')
for o in ('gwesp', 'gwespfb', 'gwespbf', 'gwespbb', 'gwesprr', 'gwdspff', 'gwdspfb'):
    field(M, T, o, o)
hdr(M, T, 'Isolates and assortativity')
for o in ('isolatenet', 'outiso', 'antiiso', 'antiiniso', 'antiiniso2', 'inplus3', 'isolatepop', 'outoutass', 'ininass',
          'outinass', 'inoutass'):
    flag(M, T, o, o)

T = 'Covariates'
hdr(M, T, 'Node covariate effects: one effect per variable (Statnet name = RSiena alias)')
for o in ('nodematch', 'samex', 'nodecov', 'nodeicov', 'altx', 'nodeocov', 'egox', 'simcov', 'simx', 'absdiffx', 'egoxaltx',
          'diffx', 'higher', 'egosqx', 'altsqx', 'samexrecip', 'simrecipx'):
    field(M, T, o, o, None, 'varlist')
flag(M, T, 'nocenter', 'nocenter', 'nocenter - raw covariate values')

T = 'Covariates'
hdr(M, T, 'Contrast and threshold covariate effects')
for o in ('egoplusaltsqx', 'diffsqx', 'egodiffx', 'althigheregox', 'unequalx', 'egolthresholdx', 'egorthresholdx',
          'altlthresholdx', 'altrthresholdx', 'degabsdiffx', 'degposdiffx', 'degnegdiffx'):
    field(M, T, o, o, None, 'varlist')
field(M, T, 'covthreshold', 'covthreshold', 'covthreshold() - threshold of the 4 threshold effects (default 0)',
      companion='egolthresholdx(c2)')
field(M, T, 'xparam', 'xparam', 'xparam() - parameter of netx() effects (default 1)', companion='netx(outxmore:c2)')

T = 'Covariates'
hdr(M, T, 'Covariate x triad / popularity / activity effects (directed one-mode networks)')
for o in ('samextranstrip', 'diffxtranstrip', 'simxtranstrip', 'homxtranstrip', 'samexoutact', 'diffxoutact',
          'samexreciact', 'diffxreciact', 'homxoutact', 'altxoutact', 'inpopx', 'outpopx', 'inactx', 'outactx',
          'samexinpop', 'diffxinpop'):
    field(M, T, o, o, None, 'varlist')

T = 'Dyadic'
hdr(M, T, 'Dyadic covariates: names of Stata n x n matrices (tv...: the stem of matrices stem1 stem2 ...)')
for o in ('dyadcov', 'dyadcovrecip', 'tvdyadcov', 'tvdyadcovrecip'):
    field(M, T, o, o, None, 'edit', ctx='dir')
FAMS = OrderedDict()


def family(d, tab, opt, title=None, slots=None, names=None, arg=None, ctxdefault='dir'):
    argk, ttl, nslots = FAMILY_DEF[opt] if opt in FAMILY_DEF else (arg, title, slots)
    names = names if names is not None else family_names(opt)
    lst = 'lst_' + opt
    d.lists[lst] = [(n, (sorted(v['rsiena'])[0] if v['rsiena'] else '')) for n, v in names.items()]
    fam = dict(opt=opt, arg=argk, title=title or ttl, slots=slots or nslots, list=lst, dialog=d.name,
               names=list(names))
    FAMS[(d.name, opt)] = fam
    d.tab(tab).append(dict(t='family', opt=opt, fam=fam))
    return fam


def family_entries(d, fam, ctx_of=None, tab=None):
    """one entry per effect name of the family"""
    opt = fam['opt']
    names = family_names(opt) if (d.name, opt) in FAMS and opt in FAMILY_DEF else None
    return names


family(M, 'Dyadic', 'dyadx')
family(M, 'Dyadic', 'tvdyadx')

T = 'Dyadic'
family(M, T, 'netx')
family(M, T, 'ownx')
family(M, T, 'netbeh')

T = 'Rates'
hdr(M, T, 'Interaction effects: products of two effects already in the model (coefficient names, e.g. nodematch_smoke1)')
M.lists['interact_list'] = ['outdegree', 'reciprocity', 'nodematch', 'nodecov', 'nodeicov', 'nodeocov', 'transtrip', 'cycle3',
                            'simcov', 'transrectrip', 'outoutass', 'ininass', 'outinass', 'inoutass', 'cycle4',
                            'transmedtrip', 'gwesp', 'transties', 'balance']
d_ = M.tab(T)
d_.append(dict(t='pairs', opt='interact', n=6, lst='interact_list', sep='#'))
E('ed_interact', 'nwsaom', 'edit', 'interact', 'interact() - more interactions, typed: a#b c#d#e', T, cmd=' interact({v})',
  ctx='dir', companion='transtrip cycle3', help='nwsaom', lst=None)
d_[-1]['more'] = 'ed_interact'

T = 'Rates'
hdr(M, T, 'Structural rate effects (the actor rate depends on the actor degree in the current network)')
for o in ('outrate', 'inrate', 'reciprate', 'outrateinv', 'inrateinv', 'reciprateinv', 'outratelog', 'inratelog',
          'recipratelog'):
    flag(M, T, o, o)
hdr(M, T, 'Covariates of the rate')
field(M, T, 'ratecov', 'ratecov', None, 'varlist')
field(M, T, 'ratecovcoef', 'ratecovcoef', 'ratecovcoef() - start values', companion='ratecov(c2)')
field(M, T, 'behratecov', 'behratecov', 'behratecov() - covariates of the behavior rate', 'varlist',
      companion='behavior(b1 b2 b3) linear', ctx='beh')
field(M, T, 'behratecoef', 'behratecoef', 'behratecoef() - start values (behavior rate)', companion='behavior(b1 b2 b3) linear behratecov(c2)', ctx='beh')
family(M, T, 'behrate')

T = 'Behavior'
hdr(M, T, 'Co-evolving behavior (one variable per wave, same order as the waves; at least linear)')
field(M, T, 'behavior', 'behavior', 'behavior() - variable per wave', 'varlist', ctx='beh', companion='linear')
for o in ('linear', 'linearendow', 'linearcreation', 'quadratic', 'quadraticendow', 'quadraticcreation', 'avalt', 'avaltendow',
          'avaltcreation', 'avsim', 'avsimendow', 'avsimcreation'):
    flag(M, T, o, o, companion='behavior(b1 b2 b3)', ctx='beh')
hdr(M, T, 'Network selection effects of the behavior (the behavior as covariate of tie choice)')
for o in ('behsim', 'behegox', 'behaltx', 'behegoplusalt'):
    flag(M, T, o, o, companion='behavior(b1 b2 b3) linear', ctx='beh')
field(M, T, 'behtheta0', 'behtheta0', 'behtheta0() - start values of behavior effects', companion='behavior(b1 b2 b3) linear', ctx='beh')
field(M, T, 'behfrom', 'behfrom', 'behfrom() - covariate main effects', 'varlist', companion='behavior(b1 b2 b3) linear', ctx='beh')
for o in ('behavxalt', 'behavsamexalt', 'behtotxalt', 'behtotsamexalt'):
    field(M, T, o, o, None, 'varlist', companion='behavior(b1 b2 b3) linear', ctx='beh')

T = 'Behavior'
family(M, T, 'beheff')
family(M, T, 'behshape')
family(M, T, 'behnet2')

T = 'Behavior'
hdr(M, T, 'Behavior effects of the network x a covariate or a dyadic covariate')
field(M, T, 'behwparam', 'behwparam', 'behwparam() - parameter of avAltW/avInAltW/avSimW (1|2)', companion='behavior(b1 b2 b3) linear behw(avsimw:DM)', ctx='beh')
family(M, T, 'behx')
family(M, T, 'behw')
family(M, T, 'tvbehw')

T = 'Rates'
hdr(M, T, 'Composition change: joiners and leavers')
field(M, T, 'present', 'present', 'present() - 0/1 variable per wave', 'varlist')
field(M, T, 'joinat', 'joinat', 'joinat() - time of joining', 'varlist', companion='leaveat(lv)')
field(M, T, 'leaveat', 'leaveat', 'leaveat() - time of leaving', 'varlist')
hdr(M, T, 'Missing data and structural zeros/ones')
field(M, T, 'missnet', 'missnet', 'missnet() - one 0/1 matrix per wave')
field(M, T, 'missbeh', 'missbeh', 'missbeh() - 0/1 variable per wave', 'varlist', companion='behavior(b1 b2 b3) linear', ctx='beh')
field(M, T, 'structural', 'structural', 'structural() - 0/1 matrix of fixed dyads')

T = 'Estimate'
hdr(M, T, 'Method of moments: replicates, start values, fixed effects')
field(M, T, 'k0', 'k0', 'k0() - Phase 1 replicates (default 50)')
field(M, T, 'k3', 'k3', 'k3() - Phase 3 replicates (default 1000)')
field(M, T, 'firstg', 'firstg', 'firstg() - initial gain (default 0.2)')
field(M, T, 'seed', 'seed', 'seed()')
field(M, T, 'cores', 'cores', 'cores() - threads of the plugin (default all)')
field(M, T, 'theta0', 'theta0', 'theta0() - start values', modes=EST)
field(M, T, 'rate0', 'rate0', 'rate0() - start rates')
field(M, T, 'fix', 'fix', 'fix() - fixed effects (names or _all)', modes=EST)
flag(M, T, 'unconditional', 'unconditional', 'unconditional estimation', help='nwsaom')
hdr(M, T, 'Maximum likelihood instead of the method of moments (ml; options go to mloptions())')
flag(M, T, 'ml', 'ml', 'ml - maximum likelihood estimation', modes=EST)
ML_CHILDREN = []
for o, kind in ML_OPTS.items():
    lab = {'n1': 'n1() - phase 1 steps (default 50)', 'nsub': 'nsub() - phase 2 subphases (default 4)',
           'nstart2': 'nstart2() - phase 2 first steps (default 100)', 'n3': 'n3() - phase 3 steps (default 1000)',
           'mult': 'mult() - multiplier (default 5)', 'nmh': 'nmh() - MH steps per ministep (default 0)',
           'gain': 'gain() - gain (default 0.2)', 'mhgeom': 'mhgeom() - geometric MH (default 0)',
           'seed': 'seed() - ML seed', 'theta0': 'theta0() - ML start values', 'rate0': 'rate0() - ML start rates',
           'notable': 'notable - suppress the ML table'}[o]
    if kind[0] == 'flag':
        e = E('cx_ml_' + o, 'nwsaom', 'flag', o, lab, T, cmd=o, parent='mloptions', companion='ml', modes=EST, help='nwsaom_remarks')
        M.tab(T).append(dict(t='flag', e=e['id']))
    else:
        e = E('ed_ml_' + o, 'nwsaom', 'edit', o, lab, T, cmd=o + '({v})', parent='mloptions', companion='ml', modes=EST, help='nwsaom_remarks')
        M.tab(T).append(dict(t='field', e=e['id'], ctl='edit', lst=None))
    ML_CHILDREN.append(e['id'])
hdr(M, T, 'Output')
flag(M, T, 'detail', 'detail', 'detail - RSiena names, means')

T = 'Estimate'
note(M, T, 'To simulate without estimating, press "Simulate..." on the Related tab (nwsaom simulate / estat simulate).', 1)
hdr(M, T, 'Several groups estimated jointly (RSiena sienaGroupCreate): a group variable, one network series per group')
field(M, T, 'groups', 'groups', 'groups() - variable that identifies the group of each node', 'varlist', modes=EST, companion='gwaves(1 2 3)')
field(M, T, 'gwaves', 'gwaves', 'gwaves() - number of waves of each group', modes=EST, companion='groups(grp)')

# options that exist in the syntax line but are not offered as a separate control
EXCLUDED_MAIN = {}

# parent entry of the mloptions() wrapper
E('wr_mloptions', 'nwsaom', 'wrapper', 'mloptions', 'mloptions() - options of the maximum likelihood estimator', 'Estimate',
  cmd=' mloptions({v})', children=ML_CHILDREN, companion='ml', modes=EST, help='nwsaom_remarks')

BEH_FAMS = {'beheff', 'behshape', 'behnet2', 'behx', 'behw', 'tvbehw', 'behrate', 'netbeh'}
SPECIAL_ARG = {('netx', 'samexv'): '@var:@var2', ('netx', 'samexvinpop'): '@var:@var2', ('netx', 'samexvinpop2'): '@var:@var2', ('dyadx', 'wxzx'): '@matrix:@matrix2'}


def family_name_entries(dlg, fam):
    opt = fam['opt']
    vocab = family_names(opt)
    argk = fam['arg']
    out = []
    for nm, v in vocab.items():
        args = v['args'] - {''}
        if (opt, nm) in SPECIAL_ARG:
            a = SPECIAL_ARG[(opt, nm)]
        elif argk in ('var', 'matrix', 'stem'):
            a = '@' + argk
        elif argk == 'param':
            a = '@param' if (args and '' not in v['args']) else ''
        elif argk == 'paren':
            a = '@var' if nm in ('susceptavcovar', 'infectcovar') else ''
        else:
            a = ''
        if argk == 'paren' and a:
            cmd = '%s(%s(%s))' % (opt, nm, a)
        elif a:
            cmd = '%s(%s:%s)' % (opt, nm, a)
        else:
            cmd = '%s(%s)' % (opt, nm)
        ctx = pick_ctx(v['ctx'])
        comp = ''
        if opt in BEH_FAMS:
            if opt != 'netbeh' or True:
                comp = 'behavior(b1 b2 b3) linear'
            ctx = 'beh' if ctx in ('dir', 'beh') else ctx
            if ctx == 'sym':
                ctx = 'symbeh'
        rsn = '/'.join(sorted(x for x in v['rsiena'] if x))
        e = E('nm_%s_%s' % (opt, nm), dlg.name, 'name', opt, '%s: %s' % (opt, nm), None, cmd=cmd, family=opt, arg=a,
              rsiena=rsn, plugin=True if opt in BEH_FAMS or opt in ('netx', 'ownx', 'dyadx', 'tvdyadx') else False,
              ctx=ctx, companion=comp, help='nwsaom', ctxs=sorted(v['ctx']))
        out.append(e['id'])
    fam['entry_ids'] = out


for (dn, op), fam in list(FAMS.items()):
    if dn == 'nwsaom':
        family_name_entries(M, fam)


# ------------------------------------------------------------------------------------ generic families with flags / auto args
def mn_lists():
    t = read('_nwsaom_mnbeh.ado')
    d = {}
    for k in ('bxfam', 'xfam', 'shfam', 'bufam'):
        m = re.search(r'local %s "([^"]*)"' % k, t)
        d[k] = m.group(1).split()
    return d


MNL = mn_lists()


def auto_arg(v):
    a = v['args'] - {''}
    if a & {'var', 'beh2', 'behavior', 'tvstem', 'varlist'}:
        return '@var'
    if 'matrix' in a:
        return '@matrix'
    if 'stem' in a:
        return '@stem'
    if a & {'#'} or any(x.isdigit() for x in a):
        return '@param?'
    return ''


def family2(d, tab, opt, title, slots, names, argmap, flagnames=(), default_on=(), ctx='dir', companion='', plugin=True, help_='nwsaom',
            maxlabel=None):
    """Generic token family. names: OrderedDict name -> info(rsiena set, ctx set); argmap name -> '@var' | '@matrix' | '@param?' | ''"""
    lst = 'lst_%s_%s' % (d.name, opt)
    d.lists[lst] = [(n, (sorted(v['rsiena'])[0] if v['rsiena'] else '')) for n, v in names.items() if n not in flagnames]
    fam = dict(opt=opt, title=title, slots=slots, list=lst, dialog=d.name, arg='auto', flagnames=list(flagnames),
               default_on=list(default_on))
    FAMS[(d.name, opt)] = fam
    d.tab(tab).append(dict(t='family', opt=opt, fam=fam))
    ids = []
    for nm, v in names.items():
        a = argmap.get(nm, '')
        optional = a.endswith('?')
        a = a.rstrip('?')
        if a:
            cmd = '%s(%s:%s)' % (opt, nm, a)
        else:
            cmd = '%s(%s)' % (opt, nm)
        rsn = '/'.join(sorted(x for x in v['rsiena'] if x))
        e = E('nm_%s_%s_%s' % (d.name, opt, nm.replace(':', '_')), d.name, 'name', opt, '%s: %s' % (opt, nm), None, cmd=cmd, family=opt, arg=a,
              rsiena=rsn, plugin=plugin, ctx=ctx, companion=companion, help=help_, isflag=(nm in flagnames))
        ids.append(e['id'])
    fam['entry_ids'] = ids
    return fam


def mkinfo(names, rs=None):
    return OrderedDict((n, dict(rsiena=set([(rs or {}).get(n, '')]) - {''}, args=set(), ctx={'dir'})) for n in names)


# ------------------------------------------------------------------------------------ multinet
X = Dlg('multinet', 'nwsaom multinet - several dependent networks (and a behavior)', 'nwsaom', 'nwsaom multinet', 1080, 600)
XN = 'multinet'
T = 'Networks'
hdr(X, T, 'Two networks that change together on the same actors (the waves of each, same number, at least two)')
field(X, T, 'net1', 'net1', 'net1() - waves of network 1', 'append', 'netlist', help='nwsaom', ctx='mn')
field(X, T, 'net2', 'net2', 'net2() - waves of network 2', 'append', 'netlist', help='nwsaom', ctx='mn')
flag(X, T, 'sym1', 'sym1', 'sym1 - network 1 is non-directed', help='nwsaom', ctx='mnsym')
flag(X, T, 'sym2', 'sym2', 'sym2 - network 2 is non-directed', help='nwsaom', ctx='mnsym')
field(X, T, 'actormode', 'actormode', 'actormode() - two-mode network: actor mode (1|2)', help='nwsaom', ctx='mn2')
field(X, T, 'tvcov', 'tvcov', 'tvcov() - changing covariates a1 a2 a3', help='nwsaom', ctx='mn')
EFFVOC = OrderedDict((n, dict(rsiena=set(), args=set(), ctx={'dir'})) for n in
                     ['outdegree', 'reciprocity', 'transtrip', 'cycle3', 'transmedtrip', 'cycle4', 'indegpop', 'outact',
                      'behsim', 'behegox', 'behaltx', 'behegoplusalt', 'egox', 'altx', 'samex', 'simx',
                      'netbeh:avgroupegox', 'netbeh:totgroupegox'])
for n, r in {'outdegree': 'density', 'reciprocity': 'recip', 'transtrip': 'transTrip', 'cycle3': 'cycle3',
             'transmedtrip': 'transMedTrip', 'cycle4': 'cycle4', 'indegpop': 'inPop', 'outact': 'outAct',
             'behsim': 'simX (beh)', 'behegox': 'egoX (beh)', 'behaltx': 'altX (beh)',
             'behegoplusalt': 'egoPlusAltX (beh)', 'egox': 'egoX', 'altx': 'altX', 'samex': 'sameX', 'simx': 'simX',
             'netbeh:avgroupegox': 'avGroupEgoX (beh)', 'netbeh:totgroupegox': 'totGroupEgoX (beh)'}.items():
    EFFVOC[n]['rsiena'] = {r}
FLAGEFF = ['outdegree', 'reciprocity', 'transtrip', 'cycle3', 'transmedtrip', 'cycle4', 'indegpop', 'outact']
for k in (1, 2):
    T = 'Networks'
    family2(X, T, 'eff%d' % k, 'eff%d() - effects within network %d (default outdegree reciprocity)' % (k, k), 4, EFFVOC,
            {'egox': '@var', 'altx': '@var', 'samex': '@var', 'simx': '@var'}, flagnames=FLAGEFF + ['behsim', 'behegox', 'behaltx', 'behegoplusalt'][:0],
            default_on=['outdegree', 'reciprocity'], ctx='mn', companion='net1(w1 w2 w3) net2(v1 v2 v3)')
CROSS = family_names('cross1')
CROSS_ARG = {n: auto_arg(v) for n, v in CROSS.items()}
for n in ('tou', 'sharedtou', 'avaltutie'):
    CROSS.setdefault(n, dict(rsiena={'toU' if n == 'tou' else ('sharedToU' if n == 'sharedtou' else 'avAltU.2M.tie')}, args={'matrix'}, ctx={'dir'}))
    CROSS_ARG[n] = '@matrix'
CROSS = OrderedDict(sorted(CROSS.items()))
for k in (1, 2):
    T = 'Cross-net'
    note(X, T, 'cross%d() - effects of network %d that depend on the other network. Name[:var] for covariate versions (variable or tvcov stem),' % (k, k), 1)
    note(X, T, 'name:matrix for dyadic ones, name:# for a parameter. Native plugin only.', 1)
    family2(X, T, 'cross%d' % k, 'cross%d() - cross-network effects' % k, 10, CROSS, CROSS_ARG, ctx='mn',
            companion='net1(w1 w2 w3) net2(v1 v2 v3)')
T = 'Behavior'
hdr(X, T, 'A behavior that co-evolves with both networks (one variable per wave)')
field(X, T, 'behavior', 'behavior', 'behavior() - variable per wave', 'varlist', help='nwsaom', ctx='mnb')
field(X, T, 'missbeh', 'missbeh', 'missbeh() - 0/1 variable per wave', 'varlist', help='nwsaom', ctx='mnb', companion='behavior(b1 b2 b3)')
field(X, T, 'behint', 'behint', 'behint() - interactions a#b of behavior effects', help='nwsaom', ctx='mnb',
      companion='behavior(b1 b2 b3) beheff1(linear quadratic avalt)')
BEHB = OrderedDict()
for n in ['linear', 'quadratic', 'avalt', 'avsim'] + list(family_names('beheff')) + MNL['bxfam'] + MNL['xfam'] + MNL['shfam'] + MNL['bufam']:
    v = (family_names('beheff').get(n) or family_names('behx').get(n) or family_names('behshape').get(n) or family_names('behnet2').get(n)
         or dict(rsiena=set(), args=set(), ctx={'dir'}))
    BEHB[n] = dict(rsiena=set(v['rsiena']), args=set(), ctx={'dir'})
BEHB['linear']['rsiena'] = {'linear'}
BEHB['quadratic']['rsiena'] = {'quad'}
BEHB['avalt']['rsiena'] = {'avAlt'}
BEHB['avsim']['rsiena'] = {'avSim'}
BARG = {}
for n in BEHB:
    if n in MNL['bxfam'] or n in MNL['xfam']:
        BARG[n] = '@var'
    elif n in ('threshold',):
        BARG[n] = '@param'
    elif n in ('constant', 'quad_cc', 'quad_nc'):
        BARG[n] = ''
    elif n in MNL['shfam'] or n in MNL['bufam']:
        BARG[n] = '@param?'
    else:
        BARG[n] = ''
BEHB = OrderedDict(sorted(BEHB.items()))
for k, ttl in (('beheff1', 'beheff1() - behavior effects driven by network 1'), ('beheff2', 'beheff2() - behavior effects driven by network 2')):
    family2(X, 'Behavior', k, ttl, 8, BEHB, BARG, flagnames=['linear', 'quadratic', 'avalt', 'avsim'], default_on=[],
            ctx='mnb', companion='behavior(b1 b2 b3)')
B12 = OrderedDict((n, dict(rsiena=set(), args=set(), ctx={'dir'})) for n in ['ffdeg', 'bbdeg', 'fbdeg', 'bfdeg', 'frdeg', 'brdeg', 'indegmixedpop', 'outdegmixedpop'])
for k, ttl in (('beheff12', 'beheff12() - behavior effects of network 1 (as 1st) and network 2 (as 2nd)'),
               ('beheff21', 'beheff21() - the same with the networks exchanged')):
    family2(X, 'Behavior', k, ttl, 6, B12, {}, ctx='mnb', companion='behavior(b1 b2 b3)')
T = 'Estimate'
field(X, T, 'theta0', 'theta0', 'theta0() - start values of all effects (net1_*, net2_*, behavior)', help='nwsaom', ctx='mn')
field(X, T, 'fix', 'fix', 'fix() - fixed effects (coefficient names or _all)', help='nwsaom', ctx='mn')
field(X, T, 'k0', 'k0', 'k0() - Phase 1 replicates (default 30)', help='nwsaom', ctx='mn')
field(X, T, 'k3', 'k3', 'k3() - Phase 3 replicates (default 200)', help='nwsaom', ctx='mn')
field(X, T, 'firstg', 'firstg', 'firstg() - initial gain (default 0.2)', help='nwsaom', ctx='mn')
field(X, T, 'seed', 'seed', 'seed()', help='nwsaom', ctx='mn')


# ------------------------------------------------------------------------------------ simple dialogs from the syntax line
def auto_dialog(d, opts, tabs, labels, ctx, companion='', help_='nwsaom', ctlmap=None, skip=()):
    """tabs: OrderedDict title -> [option names]; labels: opt -> label; every option of `opts` must be placed"""
    placed = set()
    for title, names in tabs.items():
        for o in names:
            kind, typ = opts[o]
            dflt = default_of(typ)
            lab = labels.get(o) or (o + ('()' if kind != 'flag' else '') + (' (default %s)' % dflt if dflt else ''))
            if kind == 'flag':
                flag(d, title, o, o, lab, help=help_, ctx=ctx, companion=companion)
            else:
                ctl = (ctlmap or {}).get(o, 'edit')
                lst = 'netlist' if ctl in ('append', 'combo') else None
                field(d, title, o, o, lab, ctl, lst, help=help_, ctx=ctx, companion=companion)
            placed.add(o)
    miss = [o for o in opts if o not in placed and o not in skip]
    if miss:
        raise RuntimeError('options not placed in %s: %s' % (d.name, miss))


# --- bayes
BY = Dlg('bayes', 'nwsaom bayes - Bayesian estimation of the last nwsaom model', 'nwsaom_bayes', 'nwsaom bayes')
auto_dialog(BY, BAYES_OPTS, OrderedDict([
    ('Sampler', ['nprewarm', 'nwarm', 'nmain', 'nrunmh', 'nimprovemh', 'mhgeom', 'mult', 'targetmh', 'nmh', 'nsampconst', 'nsamprates']),
    ('Priors', ['theta0', 'rate0', 'fixrates', 'priormeaneta', 'priorsigeta', 'rateprior' + 'mean', 'ratepriorsd', 'gibbsrates', 'priorrate']),
    ('Output', ['seed', 'frame', 'level', 'notable', 'noheader'])]),
    {'nprewarm': 'nprewarm() - pre-warming steps (default 50)', 'nwarm': 'nwarm() - warming steps (default 50)',
     'nmain': 'nmain() - main sampling steps (default 250)', 'nrunmh': 'nrunmh() - MH tuning runs (default 20)',
     'nimprovemh': 'nimprovemh() - steps per MH tuning (default 100)', 'targetmh': 'targetmh() - target MH acceptance (0.25)',
     'priormeaneta': 'priormeaneta() - prior means of the effects', 'priorsigeta': 'priorsigeta() - prior sd of the effects',
     'ratepriormean': 'ratepriormean() - prior means of the rates', 'ratepriorsd': 'ratepriorsd() - prior sd of the rates (default 1)',
     'priorrate': 'priorrate() - gamma prior of the rates: shape rate', 'frame': 'frame() - frame for the posterior draws',
     'level': 'level() - confidence level (default 95)'}, ctx='bayes', help_='nwsaom_bayes')

# --- meta
MT = Dlg('meta', 'nwsaom meta - meta-analysis of several nwsaom fits (siena08)', 'nwsaom_meta', 'nwsaom meta')
E('ed_meta_names', 'meta', 'edit', '_namelist', 'Stored estimates (2 or more, same model)', 'Meta', cmd=' {v}', help='nwsaom_meta',
  ctx='meta', arg='names')
MT.tab('Meta').append(dict(t='hdr', text='Combine the stored estimates (estimates store) of the same model fitted to several groups'))
MT.tab('Meta').append(dict(t='field', e='ed_meta_names', ctl='edit', lst=None, prefix=True))
auto_dialog(MT, META_OPTS, OrderedDict([('Meta', ['bound', 'alpha', 'maxit', 'rates', 'notable'])]),
            {'bound': 'bound() - exclude groups with se >= bound (default 10)', 'alpha': 'alpha() - level of the profile intervals (default 0.05)',
             'maxit': 'maxit() - maximum IWLS iterations (default 20)', 'rates': 'rates - also combine the rate parameters',
             'notable': 'notable - suppress the output'}, ctx='meta', help_='nwsaom_meta')

# --- describe
DS = Dlg('describe', 'nwsaom describe - data description before a SAOM fit', 'nwsaom', 'nwsaom describe')
auto_dialog(DS, DESC_OPTS, OrderedDict([('Data', ['waves', 'behavior', 'actormode'])]),
            {'actormode': 'actormode() - two-mode actor mode (1|2)', 'waves': 'waves() - networks in time order', 'behavior': 'behavior() - behavior variable per wave'},
            ctx='dir', ctlmap={'waves': 'append', 'behavior': 'varlist', 'actormode': 'edit'})

# --- multiplex (deprecated, forwards to multinet)
MX = Dlg('multiplex', 'nwsaom multiplex (deprecated: use nwsaom multinet)', 'nwsaom', 'nwsaom multiplex')
auto_dialog(MX, MX_OPTS, OrderedDict([('Networks', ['netawave1', 'netawave2', 'netbwave1', 'netbwave2', 'crprod', 'crprodb']),
                                      ('Estimate', ['theta01', 'theta02', 'k0', 'k3', 'firstg', 'seed', 'detail'])]),
            {}, ctx='mx', ctlmap={'netawave1': 'combo', 'netawave2': 'combo', 'netbwave1': 'combo', 'netbwave2': 'combo'})

# --- simulate (nwsaom simulate / estat simulate)
SM = Dlg('simulate', 'nwsaom simulate - simulate a SAOM (the last fit, or a model you specify)', 'nwsaom', 'nwsaom simulate')
SM.modes = [('last', 'Use the model of the last nwsaom fit (estat simulate)'), ('spec', 'Specify the model (nwsaom simulate)')]
SM.sub_prefix = {'last': 'estat simulate', 'spec': 'nwsaom simulate'}
T = 'Simulate'
SPEC = ['spec']
BOTH = ['last', 'spec']
note(SM, T, 'The first choice simulates the model of the last nwsaom fit in memory. The second needs the waves, the effects and theta() (no estimation).', 1)
hdr(SM, T, 'Specify the model (only with the second choice)')
field(SM, T, 'waves', 'waves', 'waves() - networks in time order', 'append', 'netlist', modes=SPEC, ctx='dir')
e = E('ed_simulate_effects', 'simulate', 'edit', '_text', 'Effects, in command syntax (as in nwsaom)', T, cmd=' {v}', modes=SPEC, help='nwsaom', ctx='dir', arg='text',
      tip='for example: outdegree reciprocity transtrip')
SM.tab(T).append(dict(t='field', e=e['id'], ctl='edit', lst=None))
field(SM, T, 'theta', 'theta', 'theta() - one value per network effect (table order)', modes=SPEC, help='nwsaom', rsiena='simOnly')
field(SM, T, 'behtheta', 'behtheta', 'behtheta() - one value per behavior effect', modes=SPEC, companion='behavior(b1 b2 b3) linear', ctx='beh')
field(SM, T, 'rates', 'rates', 'rates() - rate of every period', modes=SPEC)
field(SM, T, 'ratesbeh', 'ratesbeh', 'ratesbeh() - behavior rates', modes=SPEC, companion='behavior(b1 b2 b3) linear', ctx='beh')
e = E('ed_simulate_other', 'simulate', 'edit', '_text', 'Other model options, in command syntax', T, cmd=' {v}', modes=SPEC, help='nwsaom', ctx='dir', arg='text',
      tip='for example: behavior(b1 b2 b3) linear tvcov(a1 a2 a3)')
SM.tab(T).append(dict(t='field', e=e['id'], ctl='edit', lst=None))
hdr(SM, T, 'Simulation')
field(SM, T, 'nsim', 'nsim', 'nsim() - number of simulations', modes=BOTH, default='1')
field(SM, T, 'seed', 'seed', 'seed() - random-number seed', modes=BOTH)
field(SM, T, 'generate', 'generate', 'generate() - stub of the networks created', modes=BOTH, default='sim')
note(SM, T, 'Clear generate() to only print the summary (no networks are created); increase nsim() for more simulated networks', 1)
field(SM, T, 'grp', 'grp', 'grp() - one group of a groups() fit (0 = all)', modes=['last'], ctx='est')

# --- estat
ES = Dlg('estat', 'nwsaom postestimation - estat', 'nwsaom_estat', 'estat')
ES.modes = [('gof', 'gof - goodness of fit'), ('mems', 'mems - Mahalanobis/moment contributions'), ('score', 'score - score-type test'),
            ('timetest', 'timetest - time heterogeneity'), ('importance', 'importance - effect importance'),
            ('simulate', 'simulate - the last fit')]
ES.sub_prefix = {m: 'estat ' + m for m, _ in ES.modes}
T = 'Statistic'
note(ES, T, 'Operates on the nwsaom fit currently in memory - no network is selected here. Choose the statistic on the first tab.', 1)
hdr(ES, T, 'Auxiliary statistics (stats(); default outdegree indegree geodesic)')
for s_, lab in (('outdegree', 'outdegree - out-degree distribution'), ('indegree', 'indegree - in-degree distribution'),
                ('geodesic', 'geodesic - geodesic distances'), ('triad', 'triad - 16-category triad census'),
                ('behavior', 'behavior - co-evolution fits only')):
    e = E('cx_estat_stat_' + s_, 'estat', 'flag', s_, lab, T, cmd=s_, parent='stats', modes=['gof'], help='nwsaom_estat', ctx='est')
    ES.tab(T).append(dict(t='flag', e=e['id']))
E('wr_stats', 'estat', 'wrapper', 'stats', 'stats() - auxiliary statistics', T, cmd=' stats({v})', children=['cx_estat_stat_' + s for s in
  ('outdegree', 'indegree', 'geodesic', 'triad', 'behavior')], modes=['gof'], help='nwsaom_estat', ctx='est')
for o, lab, ctl in (('nsim', 'nsim() - replicates (default 50)', 'edit'), ('seed', 'seed()', 'edit'), ('maxdeg', 'maxdeg() - degree cap (default 15)', 'edit'),
                    ('maxdist', 'maxdist() - geodesic cap (default 6)', 'edit'), ('name', 'name() - graph name stub', 'edit')):
    field(ES, T, 'gof_' + o, o, lab, ctl, modes=['gof'], help='nwsaom_estat', ctx='est')
field(ES, T, 'gof_grp', 'grp', 'grp() - one group of a groups() fit (0 = all)', modes=['gof', 'simulate', 'importance'], help='nwsaom_estat', ctx='est')
flag(ES, T, 'gof_twotailed', 'twotailed', 'twotailed - two-tailed test', modes=['gof'], help='nwsaom_estat', ctx='est')
e = E('cx_estat_joinoff', 'estat', 'flag', 'join', 'join(off) - separate test per wave-period', T, cmd=' join(off)', modes=['gof'], help='nwsaom_estat', ctx='est')
ES.tab(T).append(dict(t='flag', e=e['id']))
T = 'Mems, sim'
hdr(ES, T, 'estat mems: effect() and macro() are required')
for o, lab in (('effect', 'effect() - coefficient name'), ('macro', 'macro() - name of the macro receiving the result'),
               ('nsim', 'nsim() - replicates (default 500)'), ('seed', 'seed()'), ('interval', 'interval() - numlist'), ):
    field(ES, T, 'mems_' + o, o, lab, modes=['mems'], help='nwsaom_estat', ctx='est', companion='effect(outdegree) macro(mm)' if o not in ('effect', 'macro') else '')
flag(ES, T, 'mems_nodots', 'nodots', 'nodots - suppress progress dots', modes=['mems'], help='nwsaom_estat', ctx='est', companion='effect(outdegree) macro(mm)')
hdr(ES, T, 'estat simulate: the model of the last nwsaom fit; theta() and rates() (optional) simulate at other coefficients instead')
for o, lab in (('nsim', 'nsim() - replicates'), ('seed', 'seed()'), ('theta', 'theta() - matrix of coefficients'),
               ('rates', 'rates() - rate of each period'), ('ratesbeh', 'ratesbeh() - behavior rates'), ('generate', 'generate() - stub of new networks')):
    field(ES, T, 'sim_' + o, o, lab, modes=['simulate'], help='nwsaom_estat', ctx='est', default={'nsim': '1', 'generate': 'sim'}.get(o))
note(ES, T, 'Clear generate() to only print the summary (no networks are created); increase nsim() for more simulated networks', 1)
T = 'Score, tt'
hdr(ES, T, 'estat score')
field(ES, T, 'score_tested', 'tested', 'tested() - effects of the full model to test', modes=['score'], help='nwsaom_estat', ctx='est')
hdr(ES, T, 'estat timetest')
field(ES, T, 'tt_effects', 'effects', 'effects() - effects to test (default all)', modes=['timetest'], help='nwsaom_estat', ctx='est')
flag(ES, T, 'tt_fixrates', 'fixrates', 'fixrates - keep the rates fixed', modes=['timetest'], help='nwsaom_estat', ctx='est')
hdr(ES, T, 'estat importance has only the option grp() (first tab)')
E('rb_estat_importance_note', 'estat', 'note', 'importance', 'importance - option grp() on the first tab only', None, cmd='', modes=['importance'], help='nwsaom_estat', ctx='est')


# ================================================================================================= smoke-test fixtures
# value: what the smoke test types into the control; companion: further command text the option needs to run (the tiny test
# model is waves(w1 w2 w3) outdegree reciprocity; behavior models add behavior(b1 b2 b3) linear); ctx: data context;
# drop: base-model controls removed for this entry.
FIX_VALUE = {
    'wave1': 'w1', 'wave2': 'w2', 'waves': 'w1 w2 w3', 'tvcov': 'a1 a2 a3', 'actormode': '2',
    'endow': 'transties', 'creation': 'transties', 'symtype': 'forcing',
    'outtrunc': '3', 'outmore': '2', 'outthreshold': '2', 'outinv': '2', 'outsqinv': '2', 'avdeg': '2',
    'gwesp': '0.5', 'gwespfb': '0.5', 'gwespbf': '0.5', 'gwespbb': '0.5', 'gwesprr': '0.5', 'gwdspff': '0.5', 'gwdspfb': '0.5',
    'dyadcov': 'DM', 'dyadcovrecip': 'DM', 'tvdyadcov': 'DM', 'tvdyadcovrecip': 'DM',
    'interact': 'outdegree#reciprocity', 'ratecovcoef': '0', 'behtheta0': '0 0', 'covthreshold': '1', 'xparam': '2',
    'missnet': 'MN1 MN2 MN3', 'structural': 'ST', 'present': 'p1 p2 p3', 'joinat': 'jn', 'leaveat': 'lv', 'missbeh': 'mb1 mb2 mb3',
    'behavior': 'b1 b2 b3', 'behwparam': '1', 'theta0': '0 0', 'rate0': '5 5', 'fix': 'outdegree', 'k0': '10', 'k3': '40',
    'firstg': '0.1', 'seed': '5', 'cores': '1',
    'theta': '0 0', 'behtheta': '0', 'rates': '5 5', 'ratesbeh': '5 5', 'nsim': '5', 'generate': 'gsim',
    'ratecov': 'c2', 'behratecov': 'c2', 'behratecoef': '0', 'behfrom': 'c2',
}
FIX_COMP = {
    'wave1': '', 'wave2': '', 'tvcov': 'nodeocov(a)', 'actormode': '', 'creation': 'endow(transties)', 'endow': 'creation(transties)',
    'symtype': 'symmetric', 'ratecovcoef': 'ratecov(c2)', 'covthreshold': 'egolthresholdx(c2)', 'xparam': 'netx(outxmore:c2)',
    'tvdyadcov': '', 'interact': '', 'behtheta0': 'behavior(b1 b2 b3) linear', 'joinat': 'leaveat(lv)',
}
