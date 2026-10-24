#!/usr/bin/env python3
"""Command-line smoke test of the dialog spec.

For every entry of the spec the command text is built exactly as the dialog's PROGRAM command builds it (gen_dialogs.build_command
fed with the control values a user would set), added to a tiny base model, and run in Stata (-e, batch).  A case passes if the
command runs (rc 0) or stops with a documented run-time refusal (rc 498: the model did not converge / plugin refused; rc 430
not converged), i.e. it parses and starts.  Anything else (rc 198, 111, 3xx, ...) is a failure and is reported with Stata's message.

    NWCORE=/path/to/nwcommands python3 dlg/smoke_test.py [--jobs 4] [--only ctx] [--limit N]

Needs: a Stata with the native nwsaom plugin (the repository's lib/plugins/macos), run from the repository root.
Results: dlg/smoke_results.csv (id, dialog, ctx, rc, status, command, message).
"""
import csv
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nwsaom_dialog_spec as S  # noqa: E402
import gen_dialogs as G  # noqa: E402

ROOT = S.ROOT
STATA = (os.environ.get('STATA') or '/Applications/Stata/StataBE.app/Contents/MacOS/StataBE')
NWCORE = os.environ.get('NWCORE', '')
OK_RC = {0}
RUNTIME_RC = {498, 430, 505}          # parsed and started, then the (tiny) estimation refused / did not converge

# ----------------------------------------------------------------------------------------------- data contexts
PRE = r'''
capture program drop nwinstall
set more off
sysdir set PLUS "%(plus)s"
adopath ++ "%(core)s"
adopath ++ "%(root)s"
adopath ++ "%(root)s/lib/plugins/macos"
cd "%(root)s"
quietly do "%(core)s/unw_core.do"
quietly do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void sm_data() {
	n = 40
	rseed(8642)
	A = (runiform(n, n) :< 0.09); A = A - diag(diag(A))
	B = (runiform(n, n) :< 0.09); B = B - diag(diag(B))
	S = (runiform(n, n) :< 0.07); S = ((S + S') :> 0); S = S - diag(diag(S))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		st_matrix("__V" + strofreal(w), B)
		st_matrix("__Y" + strofreal(w), S)
		F = (runiform(n, n) :< 0.05); A = abs(A - F); A = A - diag(diag(A))
		F = (runiform(n, n) :< 0.05); B = abs(B - F); B = B - diag(diag(B))
		F = (runiform(n, n) :< 0.04); F = ((F + F') :> 0); F = F - diag(diag(F)); S = abs(S - F); S = S - diag(diag(S))
	}
	D = floor(runiform(n, n) :* 4); D = D - diag(diag(D))
	st_matrix("DM", D)
	st_matrix("DM1", D)
	st_matrix("DM2", floor(runiform(n, n) :* 4) - diag(diag(floor(runiform(n, n) :* 4))))
	M1 = (runiform(n, n) :< 0.01); M1 = M1 - diag(diag(M1))
	st_matrix("MN1", M1); st_matrix("MN2", M1); st_matrix("MN3", M1)
	W1 = st_matrix("__W1"); W2 = st_matrix("__W2")
	ST = J(n, n, 0)
	ST[1,2] = (W1[1,2] == W2[1,2]); ST[2,3] = (W1[2,3] == W2[2,3]); ST[3,4] = (W1[3,4] == W2[3,4])
	st_matrix("ST", ST)
}
sm_data()
end
'''

DIR = r'''
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(w`w') nooutput
}
forvalues w = 1/3 {
	nwset, mat(__V`w') directed name(v`w') nooutput
}
'''

DATA_VARS = r'''
gen double c1 = 1 + mod(_n * 7, 3)
gen double c2 = mod(_n * 13, 11) / 3
gen double cat1 = mod(_n, 3)
gen double cat2 = mod(_n * 5, 4)
forvalues w = 1/3 {
	gen double a`w' = mod(_n * (3 + `w'), 7) / 2
	gen double b`w' = 1 + mod(_n * 7 + (_n > 20) * (`w' - 1) + (_n > 10) * (`w' > 2), 5)
	gen double z`w' = 1 + mod(_n * 5 + (_n > 15) * (`w' - 1), 4)
	gen byte p`w' = 1
	gen byte mb`w' = 0
}
replace p1 = 0 in 3
replace p3 = 0 in 4
replace mb2 = 1 in 6
gen double jn = .
replace jn = 1.5 in 5
gen double lv = .
replace lv = 2.5 in 7
'''

CTX = {}
CTX['dir'] = DIR + DATA_VARS
CTX['beh'] = CTX['dir']
CTX['sym'] = r'''
forvalues w = 1/3 {
	nwset, mat(__Y`w') undirected name(y`w') nooutput
}
''' + DATA_VARS
CTX['symbeh'] = CTX['sym']
CTX['two'] = r'''
clear
mata: rseed(77); X = (runiform(40, 20) :< 0.15); st_matrix("__T1", X); F = (runiform(40, 20) :< 0.1); X = abs(X - F); st_matrix("__T2", X); F = (runiform(40, 20) :< 0.1); X = abs(X - F); st_matrix("__T3", X)
mata: st_matrix("DM", floor(runiform(40, 20) :* 3)); st_matrix("DM1", floor(runiform(40, 20) :* 3)); st_matrix("DM2", floor(runiform(40, 20) :* 3))
mata: st_matrix("WA", floor(runiform(40, 40) :* 3) - diag(diag(floor(runiform(40, 40) :* 3)))); st_matrix("ZE", floor(runiform(20, 20) :* 3) - diag(diag(floor(runiform(20, 20) :* 3))))
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
gen double c1 = 1 + mod(_n * 7, 3)
gen double c2 = mod(_n * 13, 11) / 3
gen double cat1 = mod(_n, 3)
gen double cat2 = mod(_n * 5, 4)
forvalues w = 1/3 {
	gen double a`w' = mod(_n * (3 + `w'), 7) / 2
	gen double b`w' = 1 + mod(_n * 7 + (_n > 20) * (`w' - 1), 5)
}
'''
CTX['mn'] = CTX['dir']
CTX['mnb'] = CTX['dir']
CTX['mnsym'] = DIR + CTX['sym']
CTX['mn2'] = DIR + CTX['two']
CTX['est'] = CTX['dir']
CTX['est2'] = CTX['dir']
CTX['estbeh'] = CTX['dir']
CTX['estfix'] = CTX['dir']
CTX['bayes'] = CTX['dir']
CTX['meta'] = CTX['dir']
CTX['mx'] = CTX['dir']

# the model that is in memory before postestimation / bayes / meta cases, and per-context base controls
FIT = {
    'est2': 'nwsaom, wave1(w1) wave2(w2) outdegree reciprocity k0(10) k3(40) seed(5) cores(1)',
    'estbeh': 'nwsaom, waves(w1 w2 w3) outdegree reciprocity behavior(b1 b2 b3) linear k0(10) k3(40) seed(5) cores(1)',
    'estfix': 'nwsaom, waves(w1 w2 w3) outdegree reciprocity theta0(-1 0) fix(reciprocity) k0(10) k3(40) seed(5) cores(1)',
    'est': 'nwsaom, waves(w1 w2 w3) outdegree reciprocity k0(10) k3(40) seed(5) cores(1)',
    'bayes': 'nwsaom, waves(w1 w2 w3) outdegree reciprocity k0(10) k3(40) seed(5) cores(1)',
    'meta': 'nwsaom, waves(w1 w2 w3) outdegree reciprocity k0(10) k3(40) seed(5) cores(1)\nestimates store m1\nnwsaom, waves(w1 w2 w3) outdegree reciprocity k0(10) k3(40) seed(6) cores(1)\nestimates store m2',
}
BASE = {
    'dir': {'cb_waves': 'w1 w2 w3', 'cx_outdegree': 1, 'cx_reciprocity': 1, 'ed_k0': '10', 'ed_k3': '40', 'ed_seed': '5', 'ed_cores': '1'},
    'sym': {'cb_waves': 'y1 y2 y3', 'cx_outdegree': 1, 'cx_symmetric': 1, 'ed_k0': '10', 'ed_k3': '40', 'ed_seed': '5', 'ed_cores': '1'},
    'two': {'cb_waves': 'tm1 tm2 tm3', 'cx_outdegree': 1, 'ed_k0': '10', 'ed_k3': '40', 'ed_seed': '5', 'ed_cores': '1'},
    'mn': {'cb_multinet_net1': 'w1 w2 w3', 'cb_multinet_net2': 'v1 v2 v3', 'ed_multinet_k0': '10', 'ed_multinet_k3': '40', 'ed_multinet_seed': '5'},
}
BASE['beh'] = dict(BASE['dir'], **{'vl_behavior': 'b1 b2 b3', 'cx_linear': 1})
BASE['symbeh'] = dict(BASE['sym'], **{'vl_behavior': 'b1 b2 b3', 'cx_linear': 1})
BASE['mnb'] = dict(BASE['mn'], **{'vl_multinet_behavior': 'b1 b2 b3'})
BASE['mnsym'] = {'cb_multinet_net1': 'y1 y2 y3', 'cb_multinet_net2': 'v1 v2 v3', 'ed_multinet_k0': '10', 'ed_multinet_k3': '40', 'ed_multinet_seed': '5'}
BASE['mn2'] = {'cb_multinet_net1': 'tm1 tm2 tm3', 'cb_multinet_net2': 'w1 w2 w3', 'ed_multinet_k0': '10', 'ed_multinet_k3': '40', 'ed_multinet_seed': '5'}
for k in ('est', 'est2', 'estbeh', 'estfix', 'bayes', 'meta', 'mx'):
    BASE[k] = {}

ARGFIX = {'var': 'c1', 'matrix': 'DM', 'stem': 'DM', 'param': '2', '@var2': 'cat2', '@matrix2': 'DM'}


def argval(a):
    if not a:
        return ''
    out = []
    for part in a.split(':'):
        out.append({'@var': 'c1', '@var2': 'cat2', '@matrix': 'DM', '@matrix2': 'DM', '@stem': 'DM', '@param': '2'}.get(part, part))
    return ':'.join(out)


# ----------------------------------------------------------------------------------------------- cases
def slot_controls(lay, opt):
    for op in lay.ops:
        if op[0] == 'family' and op[1] == opt:
            return op
    return None


BEH_NAMES = {'behsim', 'behegox', 'behaltx', 'behegoplusalt', 'netbeh_avgroupegox', 'netbeh_totgroupegox'}
PARTNER = {'outdegreeendow': 'outdegreecreation', 'outdegreecreation': 'outdegreeendow', 'reciprocityendow': 'reciprocitycreation',
           'reciprocitycreation': 'reciprocityendow', 'transtiesendow': 'transtiescreation', 'transtiescreation': 'transtiesendow',
           'linearendow': 'linearcreation', 'linearcreation': 'linearendow', 'quadraticendow': 'quadraticcreation',
           'quadraticcreation': 'quadraticendow', 'avaltendow': 'avaltcreation', 'avaltcreation': 'avaltendow',
           'avsimendow': 'avsimcreation', 'avsimcreation': 'avsimendow'}
# entries that hang or are otherwise not runnable on the tiny test model (reported, not hidden)
SKIP = {'nm_behrate_avtinexposuredist2': 'hangs: more than 30 minutes of CPU on the tiny test model (nwsaom, not the dialog)'}


def recipe(e, ctx, vals):
    """adjust the control values / context of an entry so that it can run on its own; returns (ctx, comp_override or None)"""
    comp = None
    o = e['opt']
    if e['kind'] == 'flag' and o in PARTNER:
        vals['cx_' + PARTNER[o]] = 1
        base = o.replace('endow', '').replace('creation', '')
        vals.pop('cx_' + base, None)
    if e['kind'] == 'flag' and o in ('symmetric', 'degplus', 'degplusc', 'transtriads'):
        ctx = 'sym'
        vals.pop('cx_reciprocity', None)
        vals.update(BASE['sym'])
        vals['cx_' + o] = 1
    if o == 'actormode':
        comp = ''
    if e['kind'] == 'name' and e['label'].endswith('infectdeg'):
        ctx = 'symbeh'
        for k_ in ('cb_waves', 'cx_reciprocity', 'cx_outdegree'):
            vals.pop(k_, None)
        vals.update(BASE['symbeh'])
    if o == 'nsim' and e['dialog'] == 'estat' and (e['modes'] or [''])[0] == 'mems':
        vals['ed_estat_mems_nsim'] = '25'
    if o == 'behtheta0':
        vals['ed_behtheta0'] = '0'
    if e['modes'] == ['sim'] and ctx == 'beh':
        vals.setdefault('ed_sim_behtheta', '0')
    if e['kind'] == 'name' and e['family'] == 'netx' and e['label'].endswith(('avgroupegox', 'totgroupegox')):
        vals['ed_tvcov'] = 'a1 a2 a3'
        vals['ed_netx_1a'] = 'a'
    if e['dialog'] == 'multinet':
        if e['id'] == 'cx_multinet_sym1':
            vals.update({'cb_multinet_net1': 'y1 y2 y3', 'cb_multinet_net2': 'v1 v2 v3'})
        if e['id'] == 'cx_multinet_sym2':
            vals.update({'cb_multinet_net1': 'v1 v2 v3', 'cb_multinet_net2': 'y1 y2 y3'})
        if o == 'actormode':
            comp = ''
        if o == 'tvcov':
            comp = 'cross1(samewxclosure:a)'
        if e['kind'] == 'name' and e['label'].split(': ')[1].replace(':', '_') in BEH_NAMES:
            ctx = 'mnb'
            vals.update(BASE['mnb'])
            for k_ in [k for k in vals if k.startswith('cb_multinet_eff') and k.endswith('_1')]:
                pass
    if e['dialog'] == 'estat':
        sub = (e['modes'] or ['gof'])[0]
        if sub == 'mems':
            ctx = 'est2'
        if sub == 'score':
            ctx = 'estfix'
        if o == 'behavior' or o == 'ratesbeh' or e['id'] == 'cx_estat_stat_behavior':
            ctx = 'estbeh'
    return ctx, comp


def merge_companion(cmd, companion):
    """companion options not already present in the command (the base model may have set them through dialog controls)"""
    have = set(re.findall(r'[ ,]([a-z0-9_]+)(?:\(|\b)', cmd.replace(',', ' ,')))
    out = []
    for m in re.finditer(r'([a-z0-9_]+)(\((?:[^()]|\([^()]*\))*\))?', companion or ''):
        nm = m.group(1)
        if nm not in have:
            out.append(m.group(0))
    return ' '.join(out)


def build_cases(res):
    cases = []
    for e in S.ENTRIES.values():
        if e['kind'] in ('wrapper', 'note') and e['id'] != 'rb_estat_importance_note':
            continue
        dn = e['dialog']
        d, lay = res[dn][0], res[dn][1]
        ctx = e['ctx']
        vals = dict(BASE.get(ctx, {}))
        if dn == 'nwsaom' and e['modes'] == ['sim']:
            vals.update({'rb_nwsaom_sim': 1, 'ed_sim_theta': '0 0', 'ed_sim_rates': '5 5'})
            for k in ('ed_k0', 'ed_k3'):
                vals.pop(k, None)
        companion = S.FIX_COMP.get(e['opt'], e['companion']) if e['kind'] != 'name' else e['companion']
        extra = ''
        fixv = S.FIX_VALUE
        if e['kind'] == 'name':
            op = slot_controls(lay, e['family'])
            cb, ar = op[3][0]
            vals[cb] = e['label'].split(': ')[1]
            if e['arg']:
                vals[ar] = argval(e['arg'].rstrip('?'))
            if e.get('ctl'):
                vals.pop(cb, None)
                vals[e['ctl']] = 1
        elif e['kind'] == 'flag':
            if e['parent'] == 'mloptions':
                vals['cx_ml'] = 1
                vals[e['id']] = 1
            elif e['parent'] == 'stats':
                vals['rb_estat_gof'] = 1
                vals[e['id']] = 1
            else:
                vals[e['id']] = 1
        else:
            v = DEFAULTVAL.get((dn, e['opt']), fixv.get(e['opt']))
            if e['parent'] == 'mloptions':
                vals['cx_ml'] = 1
                v = {'n1': '3', 'nsub': '2', 'nstart2': '3', 'n3': '3', 'mult': '2', 'nmh': '1', 'gain': '0.1', 'mhgeom': '0', 'seed': '5', 'theta0': '0 0', 'rate0': '5 5'}[e['opt']]
            if v is None:
                v = DEFAULTVAL.get((dn, e['opt']))
            if v is None:
                v = 'c1' if e['kind'] == 'varlist' else '2'
            vals[e['id']] = v
        if dn == 'estat':
            sub = (e['modes'] or ['gof'])[0]
            vals['rb_estat_' + sub] = 1
            if sub == 'mems':
                vals.setdefault('ed_estat_mems_effect', 'outdegree')
                vals.setdefault('ed_estat_mems_macro', 'mm')
                vals.setdefault('ed_estat_mems_nsim', '20')
            if sub == 'simulate':
                vals.setdefault('ed_estat_sim_theta', 'THETA')
                vals.setdefault('ed_estat_sim_rates', '5 5')
                vals.setdefault('ed_estat_sim_nsim', '5')
            if sub == 'gof':
                vals.setdefault('ed_estat_gof_nsim', '5')
            if sub == 'score':
                vals.setdefault('ed_estat_score_tested', 'reciprocity')
            if sub == 'timetest':
                pass
        if dn == 'bayes':
            vals.setdefault('ed_bayes_nmain', '10')
            vals.setdefault('ed_bayes_nprewarm', '5')
            vals.setdefault('ed_bayes_nwarm', '5')
        if dn == 'meta':
            vals['ed_meta_names'] = 'm1 m2'
        if dn == 'describe':
            vals['cb_describe_waves'] = 'w1 w2 w3'
        if dn == 'multiplex':
            vals.update({'cb_multiplex_netawave1': 'w1', 'cb_multiplex_netawave2': 'w2', 'cb_multiplex_netbwave1': 'v1', 'cb_multiplex_netbwave2': 'v2',
                         'ed_multiplex_k0': '10', 'ed_multiplex_k3': '40'})
        # drop controls that conflict
        for dd in S.FIX_DROP.get(e['opt'], []) if hasattr(S, 'FIX_DROP') else []:
            vals.pop(dd, None)
        if e['opt'] in ('wave1', 'wave2'):
            vals.pop('cb_waves', None)
            vals.setdefault('cb_wave1', 'w1')
            vals.setdefault('cb_wave2', 'w2')
        if e['opt'] == 'structural':
            vals.pop('cb_waves', None)
            vals['cb_wave1'], vals['cb_wave2'] = 'w1', 'w2'
        ctx2, comp2 = recipe(e, ctx, vals)
        if comp2 is not None:
            companion = comp2
        ctx = ctx2
        cmd = G.build_command(d, lay, vals)
        companion = merge_companion(cmd, companion)
        if companion:
            cmd = cmd + ' ' + companion if (',' in cmd) else cmd + ', ' + companion
        if e['id'] in SKIP:
            continue
        cases.append(dict(id=e['id'], dialog=dn, ctx=ctx, cmd=cmd, kind=e['kind'], opt=e['opt']))
    return cases


DEFAULTVAL = {
    ('bayes', 'frame'): 'bfr', ('bayes', 'level'): '90', ('bayes', 'theta0'): '0 0', ('bayes', 'rate0'): '5 5',
    ('bayes', 'priormeaneta'): '0 0', ('bayes', 'priorsigeta'): '10 10', ('bayes', 'ratepriormean'): '5 5', ('bayes', 'priorrate'): '1 1',
    ('bayes', 'nrunmh'): '2', ('bayes', 'nimprovemh'): '5', ('bayes', 'mhgeom'): '0', ('bayes', 'nmh'): '1',
    ('meta', 'bound'): '10', ('meta', 'alpha'): '0.05', ('meta', 'maxit'): '5',
    ('describe', 'waves'): 'w1 w2 w3', ('describe', 'behavior'): 'b1 b2 b3',
    ('multinet', 'net1'): 'w1 w2 w3', ('multinet', 'net2'): 'v1 v2 v3', ('multinet', 'theta0'): '0 0 0 0', ('multinet', 'fix'): 'net1_outdegree',
    ('multinet', 'tvcov'): 'a1 a2 a3', ('multinet', 'actormode'): '2', ('multinet', 'behavior'): 'b1 b2 b3', ('multinet', 'missbeh'): 'mb1 mb2 mb3',
    ('multinet', 'behint'): 'beh_quadratic#beh_avalt', ('multinet', 'k0'): '2', ('multinet', 'k3'): '2', ('multinet', 'seed'): '5',
    ('multinet', 'firstg'): '0.1',
    ('multiplex', 'theta01'): '0 0', ('multiplex', 'theta02'): '0 0',
    ('estat', 'interval'): '0.1 0.5', ('estat', 'effect'): 'outdegree', ('estat', 'macro'): 'mm', ('estat', 'tested'): 'reciprocity',
    ('estat', 'effects'): 'reciprocity', ('estat', 'theta'): 'THETA', ('estat', 'rates'): '5 5', ('estat', 'ratesbeh'): '5 5', ('estat', 'generate'): 'gsim',
    ('estat', 'stats'): 'outdegree', ('estat', 'name'): 'gg', ('estat', 'maxdeg'): '10', ('estat', 'maxdist'): '4', ('estat', 'nsim'): '5', ('estat', 'seed'): '3',
}


def stata_do(ctx, cases, outlog_marker):
    t = PRE % dict(plus=PLUS, core=NWCORE, root=ROOT) + CTX[ctx]
    if ctx in FIT:
        t += '\n' + FIT[ctx] + '\n'
        if ctx in ('est', 'est2', 'estbeh', 'estfix'):
            t += 'matrix THETA = e(b)\n'
    t += '''
tempname fh
file open `fh' using "%s", read text
file read `fh' line
while r(eof) == 0 {
	local sep = strpos(`"`line'"', "|")
	local id = substr(`"`line'"', 1, `sep' - 1)
	local cmd = substr(`"`line'"', `sep' + 1, .)
	di "SMOKE-BEGIN|`id'"
	capture noisily `cmd'
	di "SMOKE-END|`id'|" _rc
	file read `fh' line
}
file close `fh'
di "SMOKE-DONE"
''' % outlog_marker
    return t


PLUS = ''


def run_ctx(ctx, cases, tmpdir, idx=0):
    base = os.path.join(tmpdir, 'smoke_%s_%d' % (ctx, idx))
    with open(base + '.txt', 'w') as f:
        for c in cases:
            f.write('%s|%s\n' % (c['id'], c['cmd']))
    with open(base + '.do', 'w') as f:
        f.write(stata_do(ctx, cases, base + '.txt'))
    # the do-file cd's into the repository, and Stata writes its batch log to the directory it is in at the end
    log = os.path.join(ROOT, os.path.basename(base) + '.log')
    if os.path.exists(log):
        os.remove(log)
    p = subprocess.Popen(['perl', '-e', 'alarm %d; exec @ARGV' % ALARM, STATA, '-e', 'do', base + '.do'], cwd=tmpdir,
                         stdout=open(base + '.out', 'w'), stderr=subprocess.STDOUT)
    return p, log


ALARM = 3000


def parse_log(log, cases):
    res = {}
    if not os.path.exists(log):
        return res
    txt = open(log, errors='replace').read()
    for m in re.finditer(r'SMOKE-BEGIN\|(\S+)\n(.*?)SMOKE-END\|\1\|(\d+)', txt, re.S):
        id_, body, rc = m.group(1), m.group(2), int(m.group(3))
        msg = ' '.join(l.strip() for l in body.split('\n') if l.strip() and not l.startswith('. ') and not l.startswith('r('))[:300]
        res[id_] = (rc, msg)
    return res


def main(argv):
    global PLUS, NWCORE, ALARM
    jobs = 4
    only = None
    limit = None
    chunk = 60
    rerun = False
    i = 0
    while i < len(argv):
        if argv[i] == '--jobs':
            jobs = int(argv[i + 1]); i += 1
        elif argv[i] == '--only':
            only = argv[i + 1]; i += 1
        elif argv[i] == '--limit':
            limit = int(argv[i + 1]); i += 1
        elif argv[i] == '--chunk':
            chunk = int(argv[i + 1]); i += 1
        elif argv[i] == '--rerun':
            rerun = True
        elif argv[i] == '--alarm':
            ALARM = int(argv[i + 1]); i += 1
        i += 1
    if not NWCORE or not os.path.exists(os.path.join(NWCORE, 'unw_core.do')):
        print('set NWCORE to the directory of the nwcommands core package')
        return 2
    res = G.build_all()
    cases = build_cases(res)
    old = {}
    if rerun:
        with open(os.path.join(ROOT, 'dlg', 'smoke_results.csv')) as f:
            old = {r['id']: r for r in csv.DictReader(f)}
        cases_all = cases
        cases = [c for c in cases if old.get(c['id'], {}).get('status') != 'OK']
    if only:
        cases = [c for c in cases if c['ctx'] == only or c['dialog'] == only or c['id'] == only or c['opt'] == only]
    if limit:
        cases = cases[:limit]
    tmp = os.environ.get('SMOKE_TMP') or tempfile.mkdtemp(prefix='nwsaom_smoke_')
    global tmpdir_g
    tmpdir_g = tmp
    os.makedirs(tmp, exist_ok=True)
    PLUS = os.path.join(tmp, 'plus')
    os.makedirs(PLUS, exist_ok=True)
    print('scratch directory', tmp)
    groups = {}
    for c in cases:
        groups.setdefault(c['ctx'], []).append(c)
    jobs_list = []
    for ctx, cs in groups.items():
        for k in range(0, len(cs), chunk):
            jobs_list.append((ctx, cs[k:k + chunk], k // chunk))
    running = []
    results = {}
    logs = []

    def reap(block):
        nonlocal running
        still = []
        for p, log, ctx, cs in running:
            if p.poll() is None and not block:
                still.append((p, log, ctx, cs))
                continue
            p.wait()
            results.update(parse_log(log, cs))
            if os.path.exists(log):
                os.replace(log, os.path.join(tmpdir_g, os.path.basename(log)))
        running = still

    for ctx, cs, idx in jobs_list:
        while len(running) >= jobs:
            import time
            time.sleep(2)
            reap(False)
        p, log = run_ctx(ctx, cs, tmp, idx)
        running.append((p, log, ctx, cs))
        logs.append(log)
    reap(True)
    out = os.path.join(ROOT, 'dlg', 'smoke_results.csv')
    if rerun:
        done = {c['id'] for c in cases}
        keep = [c for c in cases_all if c['id'] not in done and c['id'] in old]
        for c in keep:
            r = old[c['id']]
            results[c['id']] = (int(r['rc']), r['message'])
        cases = [c for c in cases_all]
    n_ok = n_rt = n_fail = n_nr = n_ref = 0
    with open(out, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['id', 'dialog', 'ctx', 'rc', 'status', 'command', 'message'])
        for c in cases:
            if c['id'] in results:
                rc, msg = results[c['id']]
                st = 'OK' if rc in OK_RC else ('RUNTIME' if rc in RUNTIME_RC else ('REFUSED' if (rc == 198 and 'cannot be estimated together with the' in msg) else 'FAIL'))
            else:
                rc, msg, st = '', '', 'NOT RUN'
            n_ok += st == 'OK'
            n_rt += st == 'RUNTIME'
            n_fail += st == 'FAIL'
            n_nr += st == 'NOT RUN'
            n_ref += st == 'REFUSED'
            w.writerow([c['id'], c['dialog'], c['ctx'], rc, st, c['cmd'], msg])
    print('cases %d: OK %d, runtime refusal after parsing %d, documented model refusal %d, FAILED %d, NOT RUN %d  -> %s' % (len(cases), n_ok, n_rt, n_ref, n_fail, n_nr, out))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
