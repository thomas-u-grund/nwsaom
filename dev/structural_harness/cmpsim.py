import sys,os,math
d,cond,K=sys.argv[1],sys.argv[2],int(sys.argv[3])
R={}
for l in open(os.path.join(d,'r_sim_c%s.txt'%cond)):
    t=l.split(); R[t[0]]=list(map(float,t[1:]))
rm,rs=R['MEAN'],R['SE']
nm=[float(x) for x in open(os.path.join(d,'nws_sim_c%s.txt'%cond)).read().split('\n')[0].split()]
ns=[float(x) for x in open(os.path.join(d,'nws_sim_c%s.txt'%cond)).read().split('\n')[1].split()]
tn=[a/b for a,b in zip(nm,ns)]
cond=(cond=='1')
# map nwsaom -> R order [rate1, rate2, outdeg, recip, transTrip, cycle3, inPopSqrt, outAct]
idx=[6,7,0,1,4,5,2,3]
names=['rate1','rate2','outdegree','recip','transTrip','cycle3','inPopSqrt','outAct']
if cond:
    idx=[0,1,4,5,2,3]
    names=['outdegree','recip','transTrip','cycle3','inPopSqrt','outAct']
if os.environ.get('MODEL','')=='ratecov':
    idx=[6,7,8,0,1,4,5,2,3]
    names=['rate1','rate2','rateX','outdegree','recip','transTrip','cycle3','inPopSqrt','outAct']
    if cond:
        idx=[6,0,1,4,5,2,3]
        names=['rateX','outdegree','recip','transTrip','cycle3','inPopSqrt','outAct']
if os.environ.get('MODEL','')=='endow':
    idx=[4,5,0,1,2,3]
    names=['rate1','rate2','outdegree','recipEndow','recipCreation','transTrip']
    if cond:
        idx=[0,1,2,3]
        names=['outdegree','recipEndow','recipCreation','transTrip']
if os.path.basename(d).startswith('sy'):
    # R: [rate1, rate2, density, transTies, inPopSqrt]; nwsaom: [outdegree, transties, inpop, rate1, rate2]
    idx=[3,4,0,1,2]
    names=['rate1','rate2','outdegree','transTies','inPopSqrt']
if os.path.basename(d).startswith('tm'):
    # R: [rate1, rate2, outdegree, cycle4, inPopSqrt, outAct]; nwsaom: [outdegree, inpop, outact, cycle4, rate1, rate2]
    idx=[4,5,0,3,1,2]
    names=['rate1','rate2','outdegree','cycle4','inPopSqrt','outAct']
    if cond:
        idx=[0,3,1,2]
        names=['outdegree','cycle4','inPopSqrt','outAct']
bad=0
for k,nmx in enumerate(names):
    a=rm[k]; b=tn[idx[k]]
    se=math.sqrt(rs[k]**2+((1.0+b*b/2.0)/K))
    z=(a-b)/se
    flag='' if abs(z)<3 else '  <<<'
    if flag: bad+=1
    print('%-10s R %8.3f  nwsaom %8.3f  diff %7.3f  se %.3f  z %6.2f%s'%(nmx,a,b,a-b,se,z,flag))
print('BAD',bad)
