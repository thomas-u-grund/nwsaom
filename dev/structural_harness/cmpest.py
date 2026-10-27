import sys,os,math,re
d,cond=sys.argv[1],sys.argv[2]
rows=[]
for l in open(os.path.join(d,'r_est_c%s.txt'%cond)):
    m=re.match(r'^\s*\[\d+,\]\s+(.*)$',l)
    if m: rows.append([float(x) for x in m.group(1).split()])
nrate=0 if cond=='1' else 2
tag='cond' if cond=='1' else 'uncond'
N=[[float(x) for x in l.split()] for l in open(os.path.join(d,'nws_est_%s.csv'%tag)) if l.strip()]
names=['outdegree','recip','transTrip','cycle3','inPopSqrt','outAct']
if os.environ.get('MODEL','')=='ratecov': names=names+['rateX']
# R columns: [rates (uncond: ans$theta has rates first), 6 effects, tconv]
if cond=='0' and os.environ.get('MODEL','')=='ratecov': R=[r[3:9]+[r[2],r[-1]] for r in rows]
elif cond=='0': R=[r[2:] for r in rows]
else: R=rows
# nwsaom columns: outdegree reciprocity indegpop outact transtrip cycle3 tconv
idx=[0,1,4,5,2,3]
if os.environ.get('MODEL','')=='ratecov': idx=idx+[6]
def ms(x):
    m=sum(x)/len(x); sd=math.sqrt(sum((a-m)**2 for a in x)/(len(x)-1)); return m,sd/math.sqrt(len(x))
bad=0
for k,nm in enumerate(names):
    a,sa=ms([r[k] for r in R]); b,sb=ms([r[idx[k]] for r in N])
    z=(a-b)/math.sqrt(sa**2+sb**2)
    fl='' if abs(z)<3 else '  <<<'
    if fl: bad+=1
    print('%-10s R %8.3f (se %.3f)  nwsaom %8.3f (se %.3f)  z %6.2f%s'%(nm,a,sa,b,sb,z,fl))
tc=[r[-1] for r in R]; tn=[r[-1] for r in N]
print('tconv.max  R %.3f nwsaom %.3f'%(sum(tc)/len(tc),sum(tn)/len(tn)))
print('BAD',bad)
