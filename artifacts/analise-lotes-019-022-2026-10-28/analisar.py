"""Análise independente dos quatro relatórios recentes, sem alterar o laboratório."""
import json
import math
from collections import Counter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
reports=sorted([(json.loads(p.read_text())['exported_at_utc'],p,json.loads(p.read_text())) for p in (ROOT/'exports/damage-lab').glob('*.json')],reverse=True)[:4]
assert len(reports)==4

def distribution(base,mult):
    low,high=.9*base*mult,1.1*base*mult
    out={damage:max(0,min(high,damage+.5)-max(low,damage-.5))/(high-low) for damage in range(math.floor(low+.5),math.floor(high+.5)+1)}
    assert math.isclose(sum(out.values()),1)
    return out

def expectations(pmf,hp):
    values=[0.]*(hp+1)
    for h in range(1,hp+1):
        values[h]=(1+sum(p*values[max(0,h-d)] for d,p in pmf.items() if d>0))/(1-pmf.get(0,0))
    return values[hp]

def kill_normal(pmf,hp):
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

rows=[];count=0
for _,path,d in reversed(reports):
    c,samples,summary=d['conditions'],d['samples'],d['summary']
    a,t,settings,action=(c[k] for k in ('attacker','target','settings','action'))
    assert action['damage_type']=='physical' and settings['variation_percent']==10 and settings['variation_enabled']
    base=action['power']*a['physical_attack']**2/(a['physical_attack']+t['physical_defense'])
    chance=min(100,max(0,a['critical_base']*settings['crit_per_point']+c['critical_source']['chance_bonus']+settings['item_bonus']+settings['buff_bonus']))
    evasion=t['evasion_base'] if action['evasion_allowed'] else 0
    for role,itemset in c['equipment'].items():
        own=c['base_stats'][role];actor=c[role]
        assert itemset['owner_id']==own['character_id']
        for stat,item,bonus,limit in [('physical_attack','weapon','attack_bonus',999),('physical_defense','armor','defense_bonus',999),('evasion_base','armor','evasion_bonus',100)]:
            assert actor[stat]==min(limit,own[stat]+itemset[item][bonus])
            assert c['composition'][role]['base'][stat]==own[stat]
            assert c['composition'][role]['bonuses'][stat]==itemset[item][bonus]
            assert c['composition'][role]['effective'][stat]==actor[stat]
    for s in samples:
        evaded=s['evasion_roll']*100<evasion
        critical=not evaded and action['critical_allowed'] and (settings['critical_mode']=='forced' or (settings['critical_mode']=='rolled' and s['critical_roll']*100<chance))
        mult=c['critical_source']['multiplier'] if critical else 1
        factor=.9+.2*s['variation_roll']
        damage=0 if evaded else max(1,math.floor(base*factor*mult+.5))
        assert (damage,critical,evaded)==(s['damage'],s['critical'],s['evaded'])
        assert s['hp_before']==t['hp'] and s['hp_after']==s['hp_before']-min(damage,s['hp_before'])
        assert s['mp_before']==a['mp'] and s['mp_after']==s['mp_before']-action['mp_cost']
        assert math.isclose(s['base']['base'],base)
        count+=1
    normal=[s['damage'] for s in samples if not s['evaded'] and not s['critical']]
    critical=[s['damage'] for s in samples if s['critical']]
    evaded_count=sum(s['evaded'] for s in samples)
    assert summary['count']==len(samples)==1000
    assert summary['normal_count']==len(normal) and summary['critical_count']==len(critical) and summary['evasion_count']==evaded_count
    assert summary['total']==sum(s['damage'] for s in samples)==summary['hp_removed_total']
    assert math.isclose(summary['mean'],summary['total']/len(samples))
    assert math.isclose(summary['normal_mean'],sum(normal)/len(normal)) and math.isclose(summary['critical_mean'],sum(critical)/len(critical))
    for bucket in summary['histogram']:
        subset=[s for s in samples if bucket['from']<=s['damage']<=bucket['to']]
        assert bucket['count']==len(subset)
        assert bucket['evaded']==sum(s['evaded'] for s in subset)
        assert bucket['critical']==sum(s['critical'] for s in subset)
        assert bucket['normal']==sum(not s['evaded'] and not s['critical'] for s in subset)
    normal_pmf=distribution(base,1);critical_pmf=distribution(base,c['critical_source']['multiplier'])
    all_pmf=Counter({0:evasion/100})
    for damage,p in normal_pmf.items():all_pmf[damage]+=(1-evasion/100)*(1-chance/100)*p
    for damage,p in critical_pmf.items():all_pmf[damage]+=(1-evasion/100)*chance/100*p
    mean=sum(damage*p for damage,p in all_pmf.items())
    ally_role='attacker' if a['side']=='ally' else 'target'
    rows.append({'file':str(path.relative_to(ROOT)),'run':d['run']['number'],'direction':'ally_to_monster' if a['side']=='ally' else 'monster_to_ally','ally':c[ally_role]['character_id'],'preset_revision':c['presets'][ally_role]['revision'],'modified':c['presets'][ally_role]['modified'],'equipment_ids':[c['equipment'][ally_role]['weapon']['id'],c['equipment'][ally_role]['armor']['id']],'normal_range':[min(normal),max(normal)],'critical_range':[min(critical),max(critical)],'normal_mean':summary['normal_mean'],'critical_count':len(critical),'critical_hit_percent':len(critical)/(len(normal)+len(critical))*100,'configured_critical_percent':chance,'evaded_count':evaded_count,'configured_evasion_percent':evasion,'observed_mean':summary['mean'],'expected_mean':mean,'normal_hits_to_defeat_target':kill_normal(normal_pmf,int(t['hp'])),'expected_attempts_to_defeat_target':expectations(all_pmf,int(t['hp'])),'sequence':[d['run']['sequence_first'],d['run']['sequence_last']]})
chronological=list(reversed(reports))
for first,second in zip(chronological,chronological[1:]):
    assert first[2]['run']['rng_after']==second[2]['run']['rng_before']
assert len({json.dumps(d['conditions']['settings'],sort_keys=True) for _,_,d in reports})==1
outgoing={r['ally']:r for r in rows if r['direction']=='ally_to_monster'}
incoming={r['ally']:r for r in rows if r['direction']=='monster_to_ally'}
result={'verified_samples':count,'rows':rows,'outgoing_observed_ally1_advantage_percent':100*(outgoing['ally_1']['observed_mean']/outgoing['ally_2']['observed_mean']-1),'outgoing_expected_ally1_advantage_percent':100*(outgoing['ally_1']['expected_mean']/outgoing['ally_2']['expected_mean']-1),'incoming_observed_extra_damage_ally2_percent':100*(incoming['ally_2']['observed_mean']/incoming['ally_1']['observed_mean']-1),'rng_segments_consecutive':True,'higher_equipment_tiers_present':False,'note':'Tentativas médias são estimativas matemáticas com dano acumulado sem cura/ATB; o laboratório restaura HP/MP por amostra. Presets preservados.'}
Path(__file__).with_name('resultados.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
