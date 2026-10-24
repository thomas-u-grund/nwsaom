#!/usr/bin/env python3
"""set_version.py - single source of truth for the version of a Stata package repo.

Usage (run from anywhere; the repo is the parent of the tools/ directory this file sits in):
    python3 tools/set_version.py 1.2.0 [24oct2026]   write VERSION, then rewrite every version display
    python3 tools/set_version.py                     rewrite every display from the current VERSION
    python3 tools/set_version.py --check             change nothing, list displays that differ (exit 1)
VERSION holds two lines: X.Y.Z and the release date in Stata format (e.g. 24oct2026).
Displays kept in sync: first line of every .ado (*! version), .sthlp header + visible version line,
<name>.pkg (Distribution-Date, Version), stata.toc, README.md / NOTICE.md (version markers),
CITATION.cff, manual/*.tex (\\pkgversion, \\pkgdate), ereturn local version and local __pkgver/__pkgdate
literals in .ado files. check also requires a matching CHANGELOG.md entry.
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MON = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
LONG = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December']


def read(p):
    with open(p, encoding='utf-8', newline='') as f:
        return f.read()


def write(p, s):
    with open(p, 'w', encoding='utf-8', newline='') as f:
        f.write(s)


def load():
    lines = read(os.path.join(ROOT, 'VERSION')).split()
    if len(lines) != 2 or not re.fullmatch(r'\d+\.\d+\.\d+', lines[0]) or not re.fullmatch(r'\d{1,2}[a-z]{3}\d{4}', lines[1]):
        sys.exit('VERSION must hold "X.Y.Z" and a Stata date such as 24oct2026, one per line')
    return lines[0], lines[1]


def name():
    m = re.search(r'^p (\S+)', read(os.path.join(ROOT, 'stata.toc')), re.M)
    return m.group(1)


def dates(d):
    day, mon, year = re.fullmatch(r'(\d{1,2})([a-z]{3})(\d{4})', d).groups()
    i = MON.index(mon)
    return int(day), i + 1, LONG[i], int(year)


def ado(t, v, d, nm, fn):
    nl = '\r\n' if '\r\n' in t[:2000] else '\n'
    first, _, rest = t.partition(nl)
    m = re.match(r'\*! (?:version \S+\s+\d{1,2}[a-z]{3}\d{4}\s*)?(.*)$', first)
    if m:
        txt = m.group(1).strip()
        t = '*! version %s  %s %s%s%s' % (v, d, txt, nl, rest)
    else:  # no *! line yet: add one in front
        t = '*! version %s  %s %s%s%s' % (v, d, os.path.basename(fn)[:-4], nl, t)
    t = re.sub(r'(ereturn local version ")[^"]*(")', r'\g<1>%s\2' % v, t)
    t = re.sub(r'(local __pkgver ")[^"]*(")', r'\g<1>%s\2' % v, t)
    t = re.sub(r'(local __pkgdate ")[^"]*(")', r'\g<1>%s\2' % d, t)
    return t


def sthlp(t, v, d, nm, fn):
    day, mo, lm, yr = dates(d)
    L = t.split('\n')
    hdr = '{* *! version %s  %s %%s}{...}' % (v, d)
    L = [x for x in L if '{* nwversion}' not in x]
    # header comment (line 2)
    m = re.match(r'\{\* \*! (?:version \S+\s+\d{1,2}[a-z]{3}\d{4}\s*)?(.*?)\}\{\.\.\.\}$', L[1]) if len(L) > 1 else None
    if m:
        L[1] = hdr % (m.group(1).strip() or 'author: Thomas Grund')
    else:
        L.insert(1, hdr % 'author: Thomas Grund')
    vis = '{pstd}{it:%s version %s, %d %s %d}{p_end}{* nwversion}' % (nm, v, day, lm, yr)
    # visible line after the title block ({title:Title} ... {p2colreset}{...}); else after the header
    pos = 2
    for i, x in enumerate(L):
        if x.startswith('{title:'):
            pos = i + 1
            for j in range(i, min(i + 12, len(L))):
                if L[j].startswith('{p2colreset}'):
                    pos = j + 1
                    break
            break
    L.insert(pos, vis)
    return '\n'.join(L)


def pkg(t, v, d, nm, fn):
    L = [x for x in t.split('\n') if not x.startswith('d Version:')]
    out = []
    for x in L:
        if x.startswith('d Distribution-Date:'):
            out.append('d Version: %s' % v)
            x = 'd Distribution-Date: %s' % d
        out.append(x)
    return '\n'.join(out)


def toc(t, v, d, nm, fn):
    def f(m):
        rest = re.sub(r'\s*v\d+\.\d+\.\d+\s*$', '', m.group(2))
        return 'p %s%s v%s' % (m.group(1), rest, v)
    return re.sub(r'^p (\S+)(.*)$', f, t, count=1, flags=re.M)


def md(t, v, d, nm, fn):
    day, mo, lm, yr = dates(d)
    t = re.sub(r'<!--version-->.*?<!--/version-->',
               '<!--version-->**Version %s** (released %d %s %d)<!--/version-->' % (v, day, lm, yr), t)
    t = re.sub(r'(Grund, T\. U\. \()\d{4}(\)\. %s: [^.(]*?)(?: \(version [^)]*\))?\.' % nm,
               r'\g<1>%d\2 (version %s).' % (yr, v), t)
    t = re.sub(r'(thomas-u-grund/%s/)v\d+\.\d+\.\d+(/)' % nm, r'\g<1>v%s\2' % v, t)
    return t


def cff(t, v, d, nm, fn):
    day, mo, lm, yr = dates(d)
    t = re.sub(r'^version:.*$', 'version: %s' % v, t, flags=re.M)
    t = re.sub(r'^date-released:.*$', "date-released: '%04d-%02d-%02d'" % (yr, mo, day), t, flags=re.M)
    return t


def tex(t, v, d, nm, fn):
    day, mo, lm, yr = dates(d)
    t = re.sub(r'(\\newcommand\{\\pkgversion\}\{)[^}]*(\})', r'\g<1>%s\2' % v, t)
    t = re.sub(r'(\\newcommand\{\\pkgdate\}\{)[^}]*(\})', r'\g<1>%d %s %d\2' % (day, lm, yr), t)
    return t


def targets():
    r = lambda p: os.path.join(ROOT, p)
    for f in sorted(glob.glob(r('*.ado'))): yield f, ado
    for f in sorted(glob.glob(r('*.sthlp'))): yield f, sthlp
    for f in sorted(glob.glob(r('*.pkg'))): yield f, pkg
    yield r('stata.toc'), toc
    for p in ('README.md', 'NOTICE.md'):
        if os.path.exists(r(p)): yield r(p), md
    if os.path.exists(r('CITATION.cff')): yield r('CITATION.cff'), cff
    for f in sorted(glob.glob(r('manual/*.tex'))): yield f, tex


def main(argv):
    check = '--check' in argv
    args = [a for a in argv if a != '--check']
    vp = os.path.join(ROOT, 'VERSION')
    if args and not check:
        write(vp, '%s\n%s\n' % (args[0], args[1] if len(args) > 1 else load()[1]))
    v, d = load()
    nm = name()
    bad = []
    for fn, fun in targets():
        old = read(fn)
        new = fun(old, v, d, nm, fn)
        if new != old:
            bad.append(os.path.relpath(fn, ROOT))
            if not check:
                write(fn, new)
    # CHANGELOG must have an entry for this version
    day, mo, lm, yr = dates(d)
    cl = os.path.join(ROOT, 'CHANGELOG.md')
    if not os.path.exists(cl) or not re.search(r'^## \[%s\] - %04d-%02d-%02d' % (re.escape(v), yr, mo, day), read(cl), re.M):
        print('CHANGELOG.md has no entry "## [%s] - %04d-%02d-%02d"' % (v, yr, mo, day))
        if check: bad.append('CHANGELOG.md')
    if check:
        if bad:
            print('version displays out of step with VERSION (%s %s): %s' % (v, d, ', '.join(bad)))
            return 1
        print('version check passed: %s %s (%s)' % (nm, v, d))
        return 0
    print('%s %s %s: %d files updated' % (nm, v, d, len(bad)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
