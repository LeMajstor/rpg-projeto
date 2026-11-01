"""Audit Monstro #1 -> the three allies, without changing presets."""
import collections
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
checks = 0


def check(ok, message):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(message)


def close(a, b):
    return math.isclose(a, b, rel_tol=1e-12, abs_tol=1e-12)


execution = json.loads((HERE/'execucao.json').read_text())
confirmation = json.loads((HERE/'confirmacao.json').read_text())
previous = json.loads((ROOT/'artifacts/aflicoes-mago-2026-11-01/analise.json').read_text())
check(execution['failures'] == confirmation['failures'] == 0, 'No Godot failures')
check(len(execution['rows']) == 12 and len(confirmation['rows']) == 48, '60 lots')
check(execution['presets_file_unchanged'], 'Personal library unchanged')
summary = []
raw_configs = {}
for row in execution['rows']:
    report = json.loads((HERE/row['report']).read_text())
    c = report['conditions']
    a,t = c['attacker'],c['target']
    stat = c['action']['resistance_stat']
    resistance = t['magic_defense'] + t[stat]
    chance = a['magic_power']/(a['magic_power']+resistance)
    total_chance = chance*(1-t['evasion_base']/100)*100
    check(a['name'] == 'Monstro #1' and a['magic_power'] == 25 and t['side'] == 'ally', 'Correct attacker and target')
    check(c['action']['mp_cost'] == 4 and c['action']['evasion_allowed'] and not c['action']['critical_allowed'], 'Rules preserved')
    check(close(row['total_application_chance'],total_chance), 'Chance includes EVA')
    counts = collections.Counter()
    for s in report['samples']:
        evaded = s['evasion_roll'] < t['evasion_base']/100
        applied = not evaded and s['affliction']['roll'] < chance
        outcome = 'evaded' if evaded else 'applied' if applied else 'resisted'
        counts[outcome] += 1
        check(s['outcome'] == outcome and s['evaded'] == evaded, 'Outcome matches independent threshold test')
        check(s['affliction']['tested'] == (not evaded) and s['affliction']['applied'] == applied, 'EVA precedes resistance')
        check(s['affliction']['combined_resistance'] == resistance and close(s['affliction']['chance'],chance*100), 'Effective DEF M plus INT/VIG')
        check(s['mp_before']-s['mp_after'] == 4 and s['hp_before'] == s['hp_after'] and s['damage'] == s['hp_removed'] == 0 and not s['critical'], 'Resources and scope')
    check(counts['applied'] == row['applied_count'] and counts['resisted'] == row['resisted_count'] and counts['evaded'] == row['evasion_count'], 'Primary totals')
    seeds = [row] + [r for r in confirmation['rows'] if r['case_index'] == row['index']]
    check({r['seed'] for r in seeds} == {421,733,112,2026,31415}, 'Five common seeds')
    totals = {name:sum(r[field] for r in seeds) for name,field in [('count','count'),('applied','applied_count'),('resisted','resisted_count'),('evaded','evasion_count')]}
    for r in seeds:
        check(r['applied_count']+r['resisted_count']+r['evasion_count'] == 1000 and close(r['total_application_chance'],total_chance), 'Five-seed totals and formula')
    observed=totals['applied']/totals['count']*100
    old=next(r for r in previous['rows'] if r['attacker']=='Monstro #1' and r['target']==row['target'] and r['action']==row['action_id'])
    check(all(totals[k] == old[k] for k in totals), 'Previous study reproduced')
    summary.append(dict(target=row['target'],action=row['action_id'],magic_defense=t['magic_defense'],vigor=t['vigor'],intelligence=t['intelligence'],effective_evasion=t['evasion_base'],combined_resistance=resistance,**totals,conditional_chance_percent=chance*100,expected_percent=total_chance,observed_percent=observed,resisted_percent=totals['resisted']/50,evaded_percent=totals['evaded']/50,deviation_pp=observed-total_chance))
    # Same rolls isolate attribute differences in this paired experiment.
    raw_configs[(row['target'],row['action_id'])]=report

reference=next(iter(raw_configs.values()))
for report in raw_configs.values():
    check(report['run']['rng_before'] == reference['run']['rng_before'] and report['run']['rng_after'] == reference['run']['rng_after'], 'Same complete RNG streams')
    for actual,ref in zip(report['samples'],reference['samples']):
        check(actual['evasion_roll'] == ref['evasion_roll'] and actual['affliction']['roll'] == ref['affliction']['roll'], 'Paired evasion and application rolls')
check(sum(r['count'] for r in summary)==60000, '60000 attempts')
max_deviation=max(abs(r['deviation_pp']) for r in summary)
result=dict(checks=checks,failures=0,attempts=60000,rows=summary,max_deviation_pp=max_deviation)
(HERE/'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
fmt=lambda v:f'{v:.2f}'.replace('.',',')
lines=['# Monstro #1 aplicando aflições nos três aliados — 01/11/2026','','**Resultado:** 60.000 tentativas executadas agora, com zero falhas e zero divergências na auditoria. Somente Monstro #1 como atacante; Aliados #1, #2 e #3 — Mago como alvos. Nenhum atributo, equipamento ou preset alterado.','','## Método','','Quatro magias de 4 MP: Veneno/Lentidão contra DEF M + VIG; Confusão/Medo contra DEF M + INT. EVA anterior ao teste de resistência. Monstro #1 usa MAG 25, MP 8. Cada um dos 12 casos recebeu 5.000 tentativas: cinco sementes (421, 733, 112, 2026 e 31415), mil amostras por semente. Recursos restaurados por amostra; sem duração, ticks, efeitos contínuos, ATB ou autonomia de MP.','','Mesmos sorteios entre alvos e magias, para isolar os atributos. Cada par de magias tem a mesma fórmula e obteve resultados idênticos; não tratar as cópias como observações estatisticamente independentes.','','## Resistências com equipamentos iniciais','','| Alvo | DEF M efetiva | VIG | INT | EVA efetiva | DEF M + VIG | DEF M + INT |','| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for target in dict.fromkeys(r['target'] for r in summary):
    a=next(r for r in summary if r['target']==target and r['action']=='poison')
    lines.append(f"| {target} | {int(a['magic_defense'])} | {int(a['vigor'])} | {int(a['intelligence'])} | {int(a['effective_evasion'])}% | {int(a['magic_defense']+a['vigor'])} | {int(a['magic_defense']+a['intelligence'])} |")
lines+=['','## Aplicações por tentativa, incluindo EVA','','| Alvo | Veneno/Lentidão observados (teóricos) | Confusão/Medo observados (teóricos) |','| --- | ---: | ---: |']
for target in dict.fromkeys(r['target'] for r in summary):
    a=next(r for r in summary if r['target']==target and r['action']=='poison')
    b=next(r for r in summary if r['target']==target and r['action']=='confusion')
    lines.append(f"| {target} | {fmt(a['observed_percent'])}% ({fmt(a['expected_percent'])}%) | {fmt(b['observed_percent'])}% ({fmt(b['expected_percent'])}%) |")
lines+=['','## Resultados completos por magia','','| Alvo | Magia | Aplicou | Resistiu | Esquivou |','| --- | --- | ---: | ---: | ---: |']
names=dict(poison='Veneno',slow='Lentidão',confusion='Confusão',fear='Medo')
for r in summary:
    lines.append(f"| {r['target']} | {names[r['action']]} | {r['applied']} | {r['resisted']} | {r['evaded']} |")
lines+=['','## Interpretação','','- O mago é o mais protegido contra as quatro aflições com o equipamento inicial. Sua DEF M 40 compensa VIG 15 e EVA 3% menores; contra Confusão/Medo, soma também INT 25. Isso preserva a distinção entre fragilidade física e resistência a aflições mágicas.','- #1 e #2 quase empatam contra Veneno/Lentidão: VIG 25/EVA 5% do primeiro contra VIG 20/EVA 12% do segundo. A EVA maior compensa a resistência específica menor.','- #2 evita melhor Confusão/Medo que #1 pela EVA maior, com a mesma DEF M 21 e INT 20.','- No mago, Confusão/Medo aplicam menos que Veneno/Lentidão porque INT 25 supera VIG 15. A diferença observada é de 3,62 pontos percentuais.','',f'Maior desvio entre observado e teórico: {fmt(max_deviation)} ponto percentual. Auditoria Python: {checks} verificações, zero divergências. Todos os resultados agregados reproduzem o estudo anterior quando condições e sementes são as mesmas.','','## Acesso a magia — D116','','Os dois primeiros aliados normalmente não usam magias no desenho do jogo. Condições/itens especiais que poderiam permitir isso pertencem a uma versão futura e ainda serão definidos. Seus atributos MAG/MP permanecem nas fichas; MP também serve a técnicas físicas especiais. Estudos anteriores com esses aliados lançando magias são comparações hipotéticas da ferramenta e não concessão dessa capacidade. Este estudo contém apenas o monstro lançando aflições nos três.','','## Evidência e reprodução','','- `execucao.json`: condições dos quatro presets, resumo dos 12 casos e hash da biblioteca preservada.','- `01-poison.json` a `12-fear.json`: 12.000 amostras primárias completas.','- `confirmacao.json`: 48.000 tentativas nas outras quatro sementes, resumos e estados RNG textuais.','- `analise.json`: auditoria independente e totais dos 60 lotes.','','Na raiz do projeto:','','```sh','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-monster-afflictions.log --path . --script res://artifacts/monstro-aflicoes-tres-aliados-2026-11-01/executar.gd','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-monster-afflictions-confirm.log --path . --script res://artifacts/monstro-aflicoes-tres-aliados-2026-11-01/confirmar_sementes.gd','python3 artifacts/monstro-aflicoes-tres-aliados-2026-11-01/analisar.py','```','','A execução primária usa a biblioteca pessoal vigente; a confirmação e auditoria usam as condições congeladas nos relatórios.']
(HERE/'analise.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='rows'},ensure_ascii=False))
for r in summary:
    if r['action'] in ['poison','confusion']:
        print(r['target'],r['action'],r['applied'],r['resisted'],r['evaded'],r['observed_percent'])
