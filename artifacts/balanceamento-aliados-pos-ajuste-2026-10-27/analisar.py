"""Confere os últimos JSONs exportados e compara os aliados sem alterar presets."""
import json
import math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
entries=sorted([(json.loads(p.read_text())['exported_at_utc'],p,json.loads(p.read_text())) for p in (ROOT/'exports/damage-lab').glob('*.json')],reverse=True)[:2]
reports={d['conditions']['attacker']['character_id']:(p,d) for _,p,d in entries}
assert set(reports)=={'ally_1','ally_2'}

def sample(c,s):
 a,t,settings,action=(c[k] for k in ('attacker','target','settings','action'))
 assert action['damage_type']=='physical'
 attack=a['physical_attack'];defense=t['physical_defense']
 base=action['power']*attack**2/(attack+defense)
 span=settings['variation_percent']/100 if settings['variation_enabled'] else 0
 factor=1-span+2*span*s['variation_roll']
 evade_chance=t['evasion_base'] if action['evasion_allowed'] else 0
 evaded=s['evasion_roll']*100<evade_chance
 chance=min(100,max(0,a['critical_base']*settings['crit_per_point']+c['critical_source']['chance_bonus']+settings['item_bonus']+settings['buff_bonus']))
 critical=not evaded and action['critical_allowed'] and (settings['critical_mode']=='forced' or (settings['critical_mode']=='rolled' and s['critical_roll']*100<chance))
 mult=c['critical_source']['multiplier'] if critical else 1
 return (0 if evaded else max(1,math.floor(base*factor*mult+.5))),critical,evaded

def pmf(base,mult):
 lo,hi=base*.9*mult,base*1.1*mult
 out={n:max(0,min(hi,n+.5)-max(lo,n-.5))/(hi-lo) for n in range(math.floor(lo+.5),math.floor(hi+.5)+1)}
 assert math.isclose(sum(out.values()),1)
 return out

output={};verified=0
for char,(path,d) in sorted(reports.items()):
 c,samples,summary=d['conditions'],d['samples'],d['summary']
 for s in samples:
  damage,crit,evaded=sample(c,s)
  assert (damage,crit,evaded)==(s['damage'],s['critical'],s['evaded'])
  assert s['hp_after']==s['hp_before']-min(damage,s['hp_before'])
  assert s['mp_after']==s['mp_before']-c['action']['mp_cost']
  verified+=1
 normal=[s['damage'] for s in samples if not s['evaded'] and not s['critical']]
 critical=[s['damage'] for s in samples if s['critical']]
 count=len(samples);hit_count=len(normal)+len(critical)
 assert count==summary['count'] and sum(s['damage'] for s in samples)==summary['total']==summary['hp_removed_total']
 assert math.isclose(sum(normal)/len(normal),summary['normal_mean'])
 assert math.isclose(sum(critical)/len(critical),summary['critical_mean'])
 assert len(critical)==summary['critical_count'] and count-hit_count==summary['evasion_count']
 assert hit_count==summary['hit_count'] and len(normal)==summary['normal_count']
 assert math.isclose(sum(s['damage'] for s in samples)/count,summary['mean'])
 assert min(s['damage'] for s in samples)==summary['minimum'] and max(s['damage'] for s in samples)==summary['maximum']
 base=c['action']['power']*c['attacker']['physical_attack']**2/(c['attacker']['physical_attack']+c['target']['physical_defense'])
 normal_pmf=pmf(base,1);crit_pmf=pmf(base,c['critical_source']['multiplier'])
 expected=(1-summary['evasion_chance']/100)*((1-summary['chance']/100)*sum(n*p for n,p in normal_pmf.items())+summary['chance']/100*sum(n*p for n,p in crit_pmf.items()))
 mean=summary['mean'];sd=math.sqrt(sum((s['damage']-mean)**2 for s in samples)/(count-1))
 output[char]={'file':str(path.relative_to(ROOT)),'exported_at_utc':d['exported_at_utc'],'revision':c['presets']['attacker']['revision'],'preset_modified':c['presets']['attacker']['modified'],'own_attack':c['base_stats']['attacker']['physical_attack'],'effective_attack':c['attacker']['physical_attack'],'normal_range':[min(normal),max(normal)],'critical_range':[min(critical),max(critical)],'normal_mean':summary['normal_mean'],'critical_mean':summary['critical_mean'],'observed_mean':mean,'expected_mean':expected,'critical_count':len(critical),'critical_hit_percent':100*len(critical)/hit_count,'configured_critical_percent':summary['chance'],'evaded_count':count-hit_count,'observed_evasion_percent':100*(count-hit_count)/count,'configured_evasion_percent':summary['evasion_chance'],'sample_mean_standard_error':sd/math.sqrt(count),'seed':d['run']['seed'],'sequence':[d['run']['sequence_first'],d['run']['sequence_last']]}

a,b=(reports[k][1] for k in ['ally_1','ally_2'])
assert a['conditions']['target']==b['conditions']['target']
assert a['conditions']['action']==b['conditions']['action']
assert a['conditions']['settings']==b['conditions']['settings']
assert a['run']['rng_after']==b['run']['rng_before']
assert a['conditions']['base_stats']['attacker']['physical_attack']==23
assert a['conditions']['presets']['attacker']['revision']==2 and not a['conditions']['presets']['attacker']['modified']
assert b['conditions']['base_stats']['attacker']['physical_attack']==20
paired={}
for key,(_,d) in reports.items():
 means={char:sum(sample(other['conditions'],s)[0] for s in d['samples'])/len(d['samples']) for char,(_,other) in reports.items()}
 paired[key]={'means_with_same_draws':means,'ally1_advantage_percent':100*(means['ally_1']/means['ally_2']-1)}
result={'verified_samples':verified,'conditions_equal_except_allies':True,'runs_are_consecutive_rng_segments':True,'allies':output,'observed_advantage_percent':100*(output['ally_1']['observed_mean']/output['ally_2']['observed_mean']-1),'expected_advantage_percent':100*(output['ally_1']['expected_mean']/output['ally_2']['expected_mean']-1),'paired_checks':paired,'note':'Médias por tentativa incluem críticos/esquivas; dano por tempo/ATB não medido. Nenhum preset modificado.'}
Path(__file__).with_name('resultados.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
