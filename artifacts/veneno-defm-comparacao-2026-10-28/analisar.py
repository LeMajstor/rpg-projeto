from pathlib import Path
import json, math
P=Path(__file__).resolve().parent
meta=json.loads((P/'execucao.json').read_text())
a=json.loads((P/'01-atual-vig-1000x.json').read_text())
b=json.loads((P/'02-proposta-defm-vig-1000x.json').read_text())
assert meta['failures']==0 and meta['presets_unchanged'] and meta['calculator_unchanged']
config=meta['config'];mag=config['attacker']['magic_power'];vig=config['target']['vigor'];md=config['target']['magic_defense'];eva=config['target']['evasion_base']
checks=0

def check(ok,message):
    global checks
    checks+=1
    assert ok,message

check(len(a['samples'])==len(b['samples'])==1000,'Duas rodadas completas')
check(a['run']['seed']==b['run']['seed']==421,'Mesma semente')
check(a['run']['rng_before']==b['run']['rng_before'] and a['run']['rng_after']==b['run']['rng_after'],'Mesmos estados dos quatro RNGs')
changed=[]
for index,(sa,sb) in enumerate(zip(a['samples'],b['samples']),1):
    for key in ('variation_roll','critical_roll','evasion_roll'):
        check(sa[key]==sb[key], 'Sorteios preservados')
    check(sa['affliction']['roll']==sb['affliction']['roll'],'Sorteios de aplicação preservados')
    for doc,sample,res in [(a,sa,vig),(b,sb,vig+md)]:
        chance=mag/(mag+res)
        dodged=sample['evasion_roll']*100<eva
        applied=not dodged and sample['affliction']['roll']<chance
        expected='evaded' if dodged else 'applied' if applied else 'resisted'
        check(sample['outcome']==expected,'Resultado confere com fórmula e sorteios')
        check(sample['affliction']['tested']==(not dodged),'EVA ocorre antes da resistência')
        check(math.isclose(sample['affliction']['chance'],100*chance),'Chance registrada')
        check(math.isclose(sample['affliction']['total_chance'],(1-eva/100)*100*chance),'Chance por tentativa registrada')
        check(sample['affliction']['resistance']==res and sample['base']['defense']==res,'Resistência registrada')
        check(sample['damage']==sample['hp_removed']==0 and not sample['critical'],'Sem dano nem crítico')
        check(sample['hp_before']==sample['hp_after']==config['target']['hp'],'HP preservado')
        check(sample['mp_before']==config['attacker']['mp'] and sample['mp_after']==config['attacker']['mp']-4,'Recursos restaurados e4MP por tentativa')
    if sa['outcome']!=sb['outcome']:
        check(sa['outcome']=='applied' and sb['outcome']=='resisted','Apenas aplicação virou resistência')
        changed.append(index)
for doc in (a,b):
    counts={outcome:sum(s['outcome']==outcome for s in doc['samples']) for outcome in ('applied','resisted','evaded')}
    check(counts['applied']==doc['summary']['applied_count'],'Aplicações resumidas')
    check(counts['resisted']==doc['summary']['resisted_count'],'Resistências resumidas')
    check(counts['evaded']==doc['summary']['evasion_count'],'Esquivas resumidas')
check(len(changed)==meta['applications_changed_to_resisted']==135,'Transições resumidas')
actual_reduction=(a['summary']['applied_count']-b['summary']['applied_count'])/10
relative_reduction=100*(1-b['summary']['applied_count']/a['summary']['applied_count'])
result={'parameters':{'magic_power':mag,'vigor':vig,'magic_defense':md,'evasion':eva,'mp_cost':4,'seed':421,'attempts_per_round':1000},'rounds':[a['summary'],b['summary']],'changed_indices':changed,'observed_reduction_percentage_points':actual_reduction,'observed_relative_reduction_pct':relative_reduction,'python_audit_checks':checks,'divergences':0,'presets_unchanged':True,'production_calculator_unchanged':True}
(P/'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
fmt=lambda n:f'{n:.2f}'.replace('.',',')
lines=['# Veneno: VIG versus DEF M + VIG — 28/10/2026','', 'Experimento solicitado: duas rodadas de1.000 tentativas com Monstro #1 atacando Aliado #1 usando Veneno. Presets atuais da biblioteca pessoal carregados pelo modelo real. Semente421 reiniciada nas duas rodadas, preservando os mesmos quatro sorteios por tentativa.','',f"Parâmetros: MAG do monstro **{int(mag)}**; VIG do aliado **{int(vig)}**; DEF M **{int(md)}**; EVA efetiva **{int(eva)}%**. Veneno custa4MP; HP/MP restaurados em cada amostra. Revisões e fichas originais preservadas.",'', '## Rodadas','', '| Medida | Atual: VIG | Proposta: DEF M + VIG |','| --- | ---: | ---: |',f'| Resistência usada | {int(vig)} | {int(vig+md)} |',f'| Chance de aplicação após passar por EVA | {fmt(a["summary"]["application_chance"])}% | {fmt(b["summary"]["application_chance"])}% |',f'| Chance calculada por tentativa, incluindo EVA | {fmt(a["summary"]["total_application_chance"])}% | {fmt(b["summary"]["total_application_chance"])}% |',f'| Aplicou | {a["summary"]["applied_count"]} | {b["summary"]["applied_count"]} |',f'| Resistiu | {a["summary"]["resisted_count"]} | {b["summary"]["resisted_count"]} |',f'| Esquivou | {a["summary"]["evasion_count"]} | {b["summary"]["evasion_count"]} |',f'| Aplicação observada por tentativa | {fmt(a["summary"]["application_frequency"])}% | {fmt(b["summary"]["application_frequency"])}% |','', 'Fórmula atual: `25 / (25 + 25) = 50%` após EVA; por tentativa `0,95 × 50% = 47,50%`.','', 'Fórmula proposta: `25 / (25 + 21 + 25) ≈ 35,21%` após EVA; por tentativa `0,95 × 35,21% ≈ 33,45%`.','', '## Comparação','', f'- A soma de DEF M21 à VIG25 elevou a resistência total de25 para46.',f'- Nos mesmos sorteios, **135 tentativas passaram de Aplicou para Resistiu**. Nenhuma mudou de esquiva nem de resistência para aplicação.',f'- Redução observada: **{fmt(actual_reduction)} pontos percentuais**, ou **{fmt(relative_reduction)}% menos aplicações** em relação à rodada atual.','- As44 esquivas ocorreram nas mesmas posições; a mudança veio exclusivamente do teste de resistência.','- Os percentuais observados não são a probabilidade exata da fórmula: cada rodada contém1.000 sorteios e pode ficar acima ou abaixo do esperado. Não foram adicionadas outras rodadas.','', '## Escopo e verificação','', 'A proposta foi executada por uma cópia experimental isolada do calculador em `calculator_proposta.gd`, derivada do calculador vigente e alterando somente a soma de DEF M no cálculo da chance e no registro da resistência. O laboratório jogável e a biblioteca de presets não foram alterados. O segundo JSON identifica explicitamente a fórmula experimental e registra VIG, DEF M e resistência combinada; não confunde o experimento com a fórmula vigente.','',f'Godot: **{meta["checks"]} verificações, zero falhas**. Auditoria independente em Python: **{checks} verificações, zero divergências** sobre as2.000 amostras, fórmulas, sorteios, resultados e recursos. Nenhum dano, crítico ou efeito contínuo foi aplicado.','', 'A adoção da nova fórmula permanece pendente de decisão do usuário. Este experimento não substitui a regra vigente D109/D110.','', '## Arquivos e reprodução','', '- `01-atual-vig-1000x.json`: rodada atual completa.','- `02-proposta-defm-vig-1000x.json`: rodada experimental completa.','- `execucao.json`: condições, resumo, hashes e verificações.','- `analise.json`: comparação, auditoria e índices das135 mudanças.','', '```sh','godot --headless --path . --script res://artifacts/veneno-defm-comparacao-2026-10-28/executar.gd','python3 artifacts/veneno-defm-comparacao-2026-10-28/analisar.py','```','']
(P/'analise.md').write_text('\n'.join(lines))
print('AUDITORIA:',checks,'verificações, zero divergências')
print('Aplicações:',a['summary']['applied_count'],'→',b['summary']['applied_count'],'| queda',fmt(actual_reduction),'p.p. |',fmt(relative_reduction),'% menos')
