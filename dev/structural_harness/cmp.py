import sys,re,csv,os
d=sys.argv[1]
R={}
for l in open(os.path.join(d,'r_targets.txt')):
    t=l.split()
    if t and t[0]=='TARGET':
        R.setdefault(int(t[1]),{})[t[2]]=float(t[3])
    if t and t[0]=='DISTANCES': R['dist']=[float(x) for x in t[1:]]
T=[list(map(float,r)) for r in csv.reader(open(os.path.join(d,'nws_target.csv')))]
D=[list(map(float,r)) for r in csv.reader(open(os.path.join(d,'nws_rate.csv')))][0]
tm=os.path.basename(d).startswith('tm')
if tm:
    names=[('outdegree_(density)',1.0),(None,None),('outdegree_-_activity',1.0),('4_cycles_(1)',1.0)]  # nwsaom: outdegree indegpop outact cycle4
    names=[('outdegree_(density)',1.0),('indegree_-_popularity_(sqrt)',1.0),('outdegree_-_activity',1.0),('4_cycles_(1)',1.0)]
else:
    names=[('outdegree_(density)',1.0),('reciprocity',0.5),('indegree_-_popularity_(sqrt)',1.0),('outdegree_-_activity',1.0),('transitive_triplets',1.0),('3-cycles',3.0)]
bad=0
for k,(nm,sc) in enumerate(names):
    r=R[0][nm]
    if nm=='reciprocity': r=r*0.5
    if nm=='3-cycles': r=r*3.0
    v=sum(row[k] for row in T)
    ok=abs(r-v)<1e-6*max(1,abs(r))
    if not ok: bad+=1
    print('total',nm,r,v,'OK' if ok else 'DIFF')
    for p in (1,2):
        if p in R and nm in R[p]:
            r=R[p][nm]
            if nm=='reciprocity': r=r*0.5
            if nm=='3-cycles': r=r*3.0
            v=T[p-1][k]
            ok=abs(r-v)<1e-6*max(1,abs(r))
            if not ok: bad+=1
            print(p,nm,r,v,'OK' if ok else 'DIFF')
for p in (1,2):
    ok=abs(R['dist'][p-1]-D[p-1])<1e-8
    if not ok: bad+=1
    print(p,'dist',R['dist'][p-1],D[p-1],'OK' if ok else 'DIFF')
print('BAD',bad)
