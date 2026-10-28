"""Confere os quatro lotes Godot e calcula a resistência sem ATB."""
import json
import math
from collections import Counter
from pathlib import Path
HERE=Path(__file__).resolve().parent
manifest=json.loads(HERE.joinpath('execucao.json').read_text())
assert manifest['failures']==0 and manifest['paired_rolls']

def distribution(base,mult):
 low,high=.9*base*mult,1.1*base*mult
 out={n:max(0,min(high,n+.5)-max(low,n-.5))/(high-low) for n in range(math.floor(low+.5),math.floor(high+.5)+1)}
 assert math.isclose(sum(out.values()),1)
 return out

def expected_attempts(pmf,hp):
 values=[0.]*(hp+1)
 for h in range(1,hp+1):values[h]=(1+sum(p*values[max(0,h-d)] for d,p in pmf.items() if d>0))/(1-pmf.get(0,0))
 return values[hp]

def kill_distribution(pmf,hp):
 alive={0:1.};out=Counter()
 for turn in range(1,20):
  following=Counter()
  for total,p0 in alive.items():
   for damage,p1 in pmf.items():
    if total+damage>=hp:out[turn]+=p0*p1
    else:following[total+damage]+=p0*p1
  alive=dict(following)
  if not alive:break
 assert math.isclose(sum(out.values()),1)
 return dict(out)

results=[];verified=0;reference=None
for case in manifest['cases']:
 d=json.loads(HERE.joinpath(case['file']).read_text());c=d['conditions'];samples=d['samples'];summary=d['summary']
 a,t,action,settings=(c[k] for k in ('attacker','target','action','settings'))
 atk_key='ranged_attack' if case['mode']=='ranged' else 'physical_attack'
 defense_key='ranged_defense' if case['mode']=='ranged' else 'physical_defense'
 attack=a[atk_key];defense=t[defense_key];base=action['power']*attack*attack/(attack+defense)
 assert attack==24 and a['critical_base']==3 and c['critical_source']['multiplier']==2
 assert action['power']==1 and settings['variation_percent']==10 and settings['variation_enabled']
 assert settings['critical_mode']=='rolled' and settings['item_bonus']==settings['buff_bonus']==0
 assert c['damage_stats']['attack_stat']==atk_key and c['damage_stats']['defense_stat']==defense_key
 if reference is None:reference=samples
 for s,ref in zip(samples,reference):
  assert all(s[key]==ref[key] for key in ['variation_roll','critical_roll','evasion_roll'])
  evaded=s['evasion_roll']*100<t['evasion_base']
  crit=not evaded and s['critical_roll']*100<3
  damage=0 if evaded else max(1,math.floor(base*(.9+.2*s['variation_roll'])*(2 if crit else 1)+.5))
  assert (damage,evaded,crit)==(s['damage'],s['evaded'],s['critical'])
  assert s['base']['attack_stat']==atk_key and s['base']['defense_stat']==defense_key and math.isclose(s['base']['base'],base)
  assert s['hp_before']==t['hp'] and s['hp_after']==t['hp']-min(damage,t['hp'])
  assert s['mp_before']==a['mp'] and s['mp_after']==a['mp']-action['mp_cost']
  verified+=1
 normal=[s['damage'] for s in samples if not s['evaded'] and not s['critical']]
 critical=[s['damage'] for s in samples if s['critical']]
 assert len(samples)==summary['count']==1000
 assert sum(s['damage'] for s in samples)==summary['total']==summary['hp_removed_total']
 assert math.isclose(summary['mean'],summary['total']/1000)
 assert len(critical)==summary['critical_count'] and 1000-len(normal)-len(critical)==summary['evasion_count']
 assert math.isclose(sum(normal)/len(normal),summary['normal_mean']) and math.isclose(sum(critical)/len(critical),summary['critical_mean'])
 np=distribution(base,1);cp=distribution(base,2);ev=t['evasion_base']/100
 all_pmf=Counter({0:ev})
 for damage,p in np.items():all_pmf[damage]+=(1-ev)*.97*p
 for damage,p in cp.items():all_pmf[damage]+=(1-ev)*.03*p
 theoretical_mean=sum(damage*p for damage,p in all_pmf.items())
 results.append({'mode':case['mode'],'ally':case['ally'],'hp':t['hp'],'attack':attack,'defense':defense,'base_damage':base,'normal_range':[min(normal),max(normal)],'normal_mean':summary['normal_mean'],'critical_range':[min(critical),max(critical)],'observed_mean':summary['mean'],'expected_mean':theoretical_mean,'evasion_count':summary['evasion_count'],'evasion_percent_configured':t['evasion_base'],'critical_count':summary['critical_count'],'normal_hits_until_incapacitated':kill_distribution(np,int(t['hp'])),'expected_attempts_until_incapacitated':expected_attempts(all_pmf,int(t['hp']))})
assert verified==4000
output={'verified_samples':verified,'cases':results,'note':'Lotes Godot restauram HP/MP a cada ataque; resistência acumulada calculada por distribuição exata e programação dinâmica, sem cura/ATB. Nenhum preset alterado.'}
HERE.joinpath('analise.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(output,ensure_ascii=False,indent=2))
