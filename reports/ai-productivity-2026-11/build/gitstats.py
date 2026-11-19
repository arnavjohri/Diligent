import subprocess, json, collections, datetime, re, sys
REPO='/home/user/Diligent'
out = subprocess.run(['git','-C',REPO,'log','--all','--no-merges','--date=iso-strict','--format=@@@%H|%ad|%an|%s','--name-only'],capture_output=True,text=True).stdout
bodies = subprocess.run(['git','-C',REPO,'log','--all','--no-merges','--format=@@@%H%n%B'],capture_output=True,text=True).stdout
co = {}
for blk in bodies.split('@@@')[1:]:
    h, _, b = blk.partition('\n')
    co[h.strip()] = ('Co-Authored-By: Claude' in b) 
commits=[]
for blk in out.split('@@@')[1:]:
    lines = blk.strip('\n').split('\n')
    h,ad,an,s = lines[0].split('|',3)
    files=[l for l in lines[1:] if l.strip()]
    commits.append(dict(h=h,t=datetime.datetime.fromisoformat(ad),an=an,s=s,files=files,claude=co.get(h,False) or an=='Claude'))
def key(p):
    parts=p.split('/')
    if parts[0] in ('kpmg','ovl','pal','tools','research') and len(parts)>1:
        return parts[0]+'/'+parts[1]
    if parts[0] in ('gail','mwc','rws','sandbox','incoming','FSD'): return parts[0]
    return '(repo tooling)'
commits.sort(key=lambda c:c['t'])
# IST conversion
IST=datetime.timezone(datetime.timedelta(hours=5,minutes=30))
for c in commits:
    c['t']=c['t'].astimezone(IST)
    c['keys']=collections.Counter(key(f) for f in c['files'])
# global work blocks: gap<=GAP minutes
GAP=75; LEAD=20
blocks=[]; cur=[commits[0]]
for c in commits[1:]:
    if (c['t']-cur[-1]['t']).total_seconds()/60<=GAP: cur.append(c)
    else: blocks.append(cur); cur=[c]
blocks.append(cur)
tot=0; per=collections.Counter(); perday=collections.defaultdict(collections.Counter)

for b in blocks:
    dur=(b[-1]['t']-b[0]['t']).total_seconds()/3600+LEAD/60
    tot+=dur
    # allocate by commit count share per key (each commit weight 1 split across its keys by file share)
    w=collections.Counter()
    for c in b:
        n=sum(c['keys'].values()) or 1
        for k,v in c['keys'].items(): w[k]+=v/n
        if not c['keys']: w['(repo tooling)']+=1
    s=sum(w.values())
    for k,v in w.items():
        per[k]+=dur*v/s; perday[b[0]['t'].date().isoformat()][k]+=dur*v/s
st=collections.defaultdict(lambda: dict(commits=0,claude=0,days=set(),first=None,last=None))
for c in commits:
    for k in (c['keys'] or {'(repo tooling)':1}):
        d=st[k]; d['commits']+=1; d['claude']+=c['claude']; d['days'].add(c['t'].date())
        d['first']=min(d['first'],c['t']) if d['first'] else c['t']; d['last']=max(d['last'],c['t']) if d['last'] else c['t']
res={}
for k,d in st.items():
    res[k]=dict(commits=d['commits'],claude_commits=d['claude'],active_days=len(d['days']),first=d['first'].date().isoformat(),last=d['last'].date().isoformat(),session_hours=round(per[k],2))
json.dump(dict(perday={d:{k:round(v,3) for k,v in x.items()} for d,x in perday.items()},total_block_hours=round(tot,1),blocks=len(blocks),commits=len(commits),claude=sum(c['claude'] for c in commits),per=res,
   days=sorted({c['t'].date().isoformat() for c in commits}),
   hours_by_day={d:round(sum(((b[-1]['t']-b[0]['t']).total_seconds()/3600+LEAD/60) for b in blocks if b[0]['t'].date().isoformat()==d),2) for d in sorted({b[0]['t'].date().isoformat() for b in blocks})}),
   open(sys.argv[1],'w'),indent=1)
print('total block hours',round(tot,1),'blocks',len(blocks),'commits',len(commits))
for k,v in []: print(f"{k:45s} {v['commits']:4d} c  {v['active_days']:3d} d  {v['session_hours']:7.2f} h  {v['first']} → {v['last']}")
