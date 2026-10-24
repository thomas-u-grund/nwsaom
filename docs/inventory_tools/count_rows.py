import csv,json,sys,collections
d=sys.argv[1]
recs=json.load(open(d+'/agg.json'))
raw=list(csv.DictReader(open(d+'/raw.csv')))
have=set(r['shortName'] for r in raw)
allr=list(csv.DictReader(open(d+'/all.csv')))
ex=[];seen=set()
for r in allr:
    if r['shortName'] not in have and r['shortName'] not in seen:
        seen.add(r['shortName']); ex.append(r)
print('extras',len(ex),[r['shortName'] for r in ex])
for r in ex:
    g=r['effectGroup']; s=r['shortName']
    if g=='behaviorOneModeSymObjective': vt,k1,k2='behavior (non-directed network)','network','network'
    elif g=='doubleCovarNetObjective': vt,k1,k2='one-mode network','coCovar','coCovar'
    elif g=='settingsObjective': vt,k1,k2='one-mode network','',''
    elif g=='dyadANetNetObjective': vt,k1,k2='one-mode network','network','coDyadCovar'
    else: vt,k1,k2='?'+g,'',''
    recs.append(dict(vt=vt,short=s,k1=k1,k2=k2,types=r['type'],names=r['effectName'],extra=g))
plain=set((x['short'],x['k1'],x['k2']) for x in recs if x['vt']=='behavior')
out=[]
for x in recs:
    if x['vt']=='behavior (non-directed network)' and (x['short'],x['k1'],x['k2']) in plain: continue
    if x['vt']=='rate (behavior (non-directed network))':
        if any(y['vt']=='rate (behavior)' and (y['short'],y['k1'],y['k2'])==(x['short'],x['k1'],x['k2']) for y in recs): continue
    out.append(x)
print('rows',len(out),'continuous',sum(1 for x in out if 'continuous' in x['vt']),'remaining',len(out)-sum(1 for x in out if 'continuous' in x['vt']))
json.dump(out,open(d+'/final.json','w'))
print('shortNames distinct (all rows)',len(set(x['short'] for x in out)))
