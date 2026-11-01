import concurrent.futures,json,re,subprocess
from pathlib import Path
out=Path('artifacts/battle-damage-v1');out.mkdir(parents=True,exist_ok=True)
suites=sorted(p for p in Path('tests').glob('*.gd') if p.name != 'render_performance.gd')
def run(p):
 cmd=['/Applications/Godot.app/Contents/MacOS/Godot','--headless','--log-file',f'/private/tmp/rpg-{p.stem}-engine.log','--path','.', '--script',f'res://{p}']
 r=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
 (out/(p.stem+'.log')).write_text(r.stdout)
 last=[l for l in r.stdout.splitlines() if 'verificações' in l or 'falhas' in l]
 if 'SCRIPT ERROR' in r.stdout or 'Failed to load script' in r.stdout: r.returncode=1
 counts=re.findall(r'(\d+) verificações, (\d+) falhas',r.stdout)
 item=dict(suite=p.name,exit_code=r.returncode,result=last[-1:] or r.stdout[-150:],checks=sum(int(c[0]) for c in counts),failures=sum(int(c[1]) for c in counts))
 print(json.dumps(item,ensure_ascii=False),flush=True)
 return item
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 rows=list(pool.map(run,suites))
summary=dict(suites=len(rows),checks=sum(r['checks'] for r in rows),failures=sum(r['failures'] for r in rows),all_passed=all(r['exit_code']==0 and not r['failures'] for r in rows),results=rows)
(out/'test-results.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='results'}),flush=True)
raise SystemExit(0 if summary['all_passed'] else 1)
