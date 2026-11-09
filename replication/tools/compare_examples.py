"""Compare nwsaom (val_examples.csv) with RSiena (rs_examples.csv): means over five seeds, in RSiena standard errors."""
import csv, collections, statistics as st, sys, os
# Run from the replication folder: python3 tools/compare_examples.py  (defaults: the files in results/examples)
if len(sys.argv) < 3: sys.argv[1:] = [os.path.join("results", "examples", f) for f in ("val_examples.csv", "rs_examples.csv")]
nw = collections.defaultdict(lambda: collections.defaultdict(list)); rs = collections.defaultdict(lambda: collections.defaultdict(list))
for r in csv.DictReader(open(sys.argv[1])): nw[r['model']][r['param']].append((float(r['est']), float(r['se'])))
for r in csv.DictReader(open(sys.argv[2])): rs[r['model']][r['param']].append((float(r['est']), float(r['se'])))
MAP = {  # nwsaom parameter -> RSiena parameter
 'E1': {'outdegree':'outdegree (density) [eval]','reciprocity':'reciprocity [eval]','nodematch_smoke1':'same smoke1 [eval]','cycle3':'3-cycles [eval]'},
 'E3': {'outdegree':'outdegree (density) [eval]','reciprocity':'reciprocity [eval]','transtrip':'transitive triplets [eval]'},
 'E4': {'outdegree':'outdegree (density) [eval]','reciprocity':'reciprocity [eval]','behsim':'drinking similarity [eval]','beh_linear':'drinking linear shape [eval]','beh_avalt':'drinking average alter [eval]',
        'netrate1':'constant friendship rate (period 1) [rate]','netrate2':'constant friendship rate (period 2) [rate]','behrate1':'rate drinking (period 1) [rate]','behrate2':'rate drinking (period 2) [rate]'},
 'E5': {'outdegree':'outdegree (density) [eval]','reciprocity':'reciprocity [eval]','beh_linear':'drinking linear shape [eval]','beh_quadratic_endow':'drinking quadratic shape [endow]','beh_quadratic_creation':'drinking quadratic shape [creation]',
        'netrate1':'basic rate parameter friendship [rate]','behrate1':'rate drinking period 1 [rate]'},
}
worst = 0; worst_se = 0
for m in MAP:
    for a, b in MAP[m].items():
        if a not in nw[m] or b not in rs[m]: print(m, 'MISSING', a, b, list(nw[m])); continue
        n = nw[m][a]; r = rs[m][b]
        mn = st.mean(x[0] for x in n); mr = st.mean(x[0] for x in r); sn = st.mean(x[1] for x in n); sr = st.mean(x[1] for x in r)
        d = (mn - mr) / sr; worst = max(worst, abs(d)); rat = sn / sr
        print(f'{m} {a:24s} nw {mn:8.3f} ({sn:.3f})  rs {mr:8.3f} ({sr:.3f})  diff {d:6.3f} se  se-ratio {rat:5.2f}')
print('max |diff| in RSiena s.e.:', round(worst, 3))
