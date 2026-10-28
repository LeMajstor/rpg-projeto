"""Proposta de bônus dos arcos, sem gravar dados de jogo ou presets."""
import json
import math
from pathlib import Path

def expected_damage(attack, defense, chance, multiplier):
    base=attack*attack/(attack+defense)
    def rounded_mean(mult):
        low,high=base*.9*mult,base*1.1*mult
        distribution={damage:max(0,min(high,damage+.5)-max(low,damage-.5))/(high-low) for damage in range(math.floor(low+.5),math.floor(high+.5)+1)}
        assert math.isclose(sum(distribution.values()),1)
        return sum(damage*probability for damage,probability in distribution.items())
    return .97*((1-chance)*rounded_mean(1)+chance*rounded_mean(multiplier))

rows=[]
for stage,sword_bonus in enumerate([10,16,24,34,48,65],1):
    sword_mean=expected_damage(23+sword_bonus,40,.1,2)
    bow_bonus=min(range(1,90),key=lambda bonus:abs(expected_damage(20+bonus,40,.19,1.6)-sword_mean/1.15))
    bow_mean=expected_damage(20+bow_bonus,40,.19,1.6)
    advantage=(sword_mean/bow_mean-1)*100
    assert 13 < advantage < 17
    rows.append({'stage':stage,'sword_bonus':sword_bonus,'bow_bonus_proposed':bow_bonus,'bow_effective_attack':20+bow_bonus,'expected_mean_ally1':sword_mean,'expected_mean_ally2':bow_mean,'ally1_advantage_percent':advantage})
assert [r['bow_bonus_proposed'] for r in rows]==[10,15,22,31,44,58]
assert math.isclose(rows[0]['expected_mean_ally1'],15.919223140495868)
assert math.isclose(rows[0]['expected_mean_ally2'],13.920308333333335)
result={'status':'proposta P08B, sem implementação','assumptions':'ATQ próprios23/20, crítico10%/19%, multiplicadores2/1.6, DEF do alvo40/EVA3%, variação±10%, arredondamento; sem níveis/ATB. Escolha do bônus inteiro cujo dano médio fica mais próximo da média da espada/1.15.','rows':rows}
Path(__file__).with_name('resultados.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
for r in rows: print(r['stage'],r['sword_bonus'],r['bow_bonus_proposed'],round(r['ally1_advantage_percent'],2))
