import csv,collections,re,json
rows=list(csv.DictReader(open('raw.csv')))
nets={'fr','net2','net3','bip','n1','sfr','sfr2'}; behs={'beh','beh2','bh'}; sde={'sde','cont'}
cov={'cc':'coCovar','vc':'varCovar','dc':'coDyadCovar','vdc':'varDyadCovar','ccA':'coCovar','ccB':'coCovar','vcA':'varCovar','dcAB':'coDyadCovar'}
def kind(n):
    if not n: return ''
    if n in cov: return cov[n]
    if n in nets: return 'network'
    if n in behs: return 'behavior'
    if n in sde: return 'continuous'
    return '?'+n
agg=collections.OrderedDict()
for r in rows:
    nt=r['netType']
    if r['config'].startswith('SYM') and nt=='oneMode': nt='oneModeSym'
    if r['config'].startswith('SYM') and nt=='behavior': nt='behSym'
    vt={'oneMode':'one-mode network','oneModeSym':'non-directed network','behSym':'behavior (non-directed network)','bipartite':'two-mode network','behavior':'behavior','continuous':'continuous behavior'}[nt]
    typ=r['type']
    if typ=='rate': vt='rate ('+vt+')'
    if typ=='gmm': vt='gmm ('+vt+')'
    k1,k2=kind(r['interaction1']),kind(r['interaction2'])
    key=(vt,r['shortName'],k1,k2)
    a=agg.setdefault(key,dict(types=set(),names=set(),parms=set(),itypes=set(),cfgs=set(),dep=set(),inter=set()))
    a['types'].add(typ)
    en=r['effectName']
    for nm,rep in [(r['interaction1'],'<v1>'),(r['interaction2'],'<v2>'),(r['name'],'<dep>')]:
        if nm: en=re.sub(r'(?<![A-Za-z0-9_])'+re.escape(nm)+r'(?![A-Za-z0-9_])',rep,en)
    a['names'].add(en)
    a['parms'].add(r['parm']); a['itypes'].add(r['interactionType']); a['cfgs'].add(r['config'])
    a['inter'].add((r['interaction1'],r['interaction2']))
print(len(agg))
out=[]
for k,a in agg.items():
    out.append(dict(vt=k[0],short=k[1],k1=k[2],k2=k[3],types='/'.join(sorted(a['types'])),names=' || '.join(sorted(a['names'])),parms='/'.join(sorted(a['parms'])),itypes='/'.join(sorted(a['itypes']))))
json.dump(out,open('agg.json','w'),indent=0)
c=collections.Counter(o['vt'] for o in out); print(c)
print(collections.Counter((o['k1'],o['k2']) for o in out))
