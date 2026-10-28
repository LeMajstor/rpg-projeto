"""Análise local dos últimos relatórios; não altera presets nem dados de jogo."""
import json
import math
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[2]
paths = sorted(ROOT.joinpath('exports/damage-lab').glob('*.json'), key=lambda p: json.loads(p.read_text())['exported_at_utc'], reverse=True)[:2]
reports = {json.loads(p.read_text())['conditions']['attacker']['character_id']: (p, json.loads(p.read_text())) for p in paths}

def sample(c, s, attack=None, multiplier=None):
    a, t, cfg, act = (c[k] for k in ('attacker', 'target', 'settings', 'action'))
    physical = act['damage_type'] == 'physical'
    atk = a['physical_attack' if physical else 'magic_power'] if attack is None else attack
    defense = t['physical_defense' if physical else 'magic_defense']
    base = act['power'] * atk * atk / (atk + defense) if atk else 0
    span = cfg['variation_percent'] / 100 if cfg['variation_enabled'] else 0
    factor = 1 - span + 2 * span * s['variation_roll']
    evade_chance = t['evasion_base'] if act['evasion_allowed'] else 0
    evaded = s['evasion_roll'] * 100 < evade_chance
    chance = max(0, min(100, a['critical_base'] * cfg['crit_per_point'] + c['critical_source']['chance_bonus'] + cfg['item_bonus'] + cfg['buff_bonus']))
    critical = not evaded and act['critical_allowed'] and (cfg['critical_mode'] == 'forced' or (cfg['critical_mode'] == 'rolled' and s['critical_roll'] * 100 < chance))
    mul = (c['critical_source']['multiplier'] if multiplier is None else multiplier) if critical else 1
    damage = 0 if evaded else max(1, math.floor(base * factor * mul + .5))
    return damage, critical, evaded

verified = 0
observed = {}
for char, (path, report) in reports.items():
    c, samples, summary = report['conditions'], report['samples'], report['summary']
    for s in samples:
        damage, critical, evaded = sample(c, s)
        assert (damage, critical, evaded) == (s['damage'], s['critical'], s['evaded'])
        assert s['hp_after'] == s['hp_before'] - min(damage, s['hp_before'])
        assert s['mp_after'] == s['mp_before'] - c['action']['mp_cost']
        verified += 1
    hits = [s for s in samples if not s['evaded']]
    normal = [s['damage'] for s in hits if not s['critical']]
    crit = [s['damage'] for s in hits if s['critical']]
    assert sum(s['damage'] for s in samples) == summary['total']
    assert sum(s['damage'] for s in samples) / len(samples) == summary['mean']
    assert len(normal) == summary['normal_count'] and len(crit) == summary['critical_count']
    assert len(samples) - len(hits) == summary['evasion_count']
    assert math.isclose(sum(normal)/len(normal), summary['normal_mean'])
    assert math.isclose(sum(crit)/len(crit), summary['critical_mean'])
    observed[char] = {'source': str(path.relative_to(ROOT)), 'exported_at_utc': report['exported_at_utc'], 'seed': report['run']['seed'], 'count': len(samples), 'mean': summary['mean'], 'normal_mean': summary['normal_mean'], 'normal_range': [min(normal),max(normal)], 'critical_mean': summary['critical_mean'], 'critical_range': [min(crit),max(crit)], 'critical_count': len(crit), 'critical_percent_on_hits': len(crit)/len(hits)*100, 'evaded_count': len(samples)-len(hits)}

def pmf(base, multiplier=1):
    lo, hi = base * .9 * multiplier, base * 1.1 * multiplier
    result = {}
    for damage in range(max(1, math.floor(lo+.5)), math.floor(hi+.5)+1):
        p = max(0., min(hi, damage+.5)-max(lo, damage-.5))/(hi-lo)
        if p: result[damage] = p
    assert math.isclose(sum(result.values()),1)
    return result

def combine(normal, critical, chance, evade):
    result = Counter({0:evade})
    for outcome,p in normal.items(): result[outcome] += (1-evade)*(1-chance)*p
    for outcome,p in critical.items(): result[outcome] += (1-evade)*chance*p
    assert math.isclose(sum(result.values()),1)
    return dict(result)

def turns(pmf, hp):
    e = [0.] * (hp+1)
    for h in range(1,hp+1):
        e[h] = (1 + sum(p*e[max(0,h-d)] for d,p in pmf.items() if d > 0))/(1-pmf.get(0,0))
    return e[hp]

def kill_distribution(normal, hp):
    alive={0:1.}; kill={}
    for hit in range(1,10):
        following=Counter()
        for accum,p0 in alive.items():
            for damage,p1 in normal.items():
                total=accum+damage
                if total>=hp: kill[hit]=kill.get(hit,0)+p0*p1
                else: following[total]+=p0*p1
        alive=dict(following)
        if not alive:break
    assert math.isclose(sum(kill.values()),1)
    return kill

options=[]
for name,atk,crit,mult,char in [('Aliado #1 atual',30,.10,2.,'ally_1'),('Aliado #2 atual',30,.19,1.6,'ally_2'),('Proposta: ATQ próprio 19',29,.10,2.,'ally_1'),('Comparação: ATQ próprio 18',28,.10,2.,'ally_1'),('Alternativa: espada 1,6×',30,.10,1.6,'ally_1'),('P07 revisada: Aliado #1 ATQ próprio 23',33,.10,2.,'ally_1')]:
    normal=pmf(atk*atk/(atk+40))
    critical=pmf(atk*atk/(atk+40),mult)
    distribution=combine(normal,critical,crit,.03)
    mean=sum(d*p for d,p in distribution.items())
    c=reports[char][1]['conditions'];samples=reports[char][1]['samples']
    paired=sum(sample(c,s,atk,mult)[0] for s in samples)/len(samples)
    options.append({'name':name,'attack_effective':atk,'critical_chance':crit*100,'critical_multiplier':mult,'normal_range':[min(normal),max(normal)],'critical_range':[min(critical),max(critical)],'expected_mean_per_attempt':mean,'paired_mean_exported_draws':paired,'expected_attempts_to_defeat_hp45':turns(distribution,45),'normal_hits_to_defeat_hp45':kill_distribution(normal,45),'normal_hits_to_defeat_hp40':kill_distribution(normal,40)})

output={'status':'estudo e propostas; presets preservados', 'verified_samples':verified,'observed':observed,'options':options,'assumptions':'Variação uniforme ±10%, arredondamento ao inteiro mais próximo, alvo DEF40/EVA3/HP45; ataques independentes, dano acumulado sem cura/ATB. Médias por tentativa incluem críticos e esquivas. Propostas usam também os sorteios originais para comparação pareada.'}
Path(__file__).with_name('resultados.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(output,ensure_ascii=False,indent=2))
