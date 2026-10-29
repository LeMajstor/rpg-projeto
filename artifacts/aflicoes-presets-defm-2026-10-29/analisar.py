"""Auditoria da matriz D111 e comparação pareada com os mesmos sorteios da versão D110."""
from pathlib import Path
import json, math
from collections import defaultdict

P = Path(__file__).resolve().parent
OLD = P.parent/'aflicoes-presets-2026-10-28'
execution = json.loads((P/'execucao.json').read_text())
extra = json.loads((P/'confirmacao.json').read_text())
old_execution = json.loads((OLD/'execucao.json').read_text())
old_analysis = json.loads((OLD/'analise.json').read_text())
old_confirmation = json.loads((OLD/'confirmacao.json').read_text())
checks = 0

def check(ok, reason):
    global checks
    checks += 1
    assert ok, reason

def key(row):
    return row['attacker'], row['target'], row['action_id']

check(execution['failures'] == extra['failures'] == 0, 'Execuções sem falhas')
check(execution['presets_file_unchanged'], 'Arquivo pessoal preservado')
check(execution['presets_sha256'] == old_execution['presets_sha256'], 'Mesmos presets brutos nas duas versões')
old_cases = {key(r): r for r in old_analysis['cases']}
old_primary = {key(r): r for r in old_execution['rows']}
old_seeds = {(r['attacker'],r['target'],r['action_id'],r['seed']): r for r in old_confirmation['rows']}
additional = defaultdict(list)
for row in extra['rows']:
    additional[row['case_index']].append(row)
    previous = old_seeds[(row['attacker'],row['target'],row['action_id'],row['seed'])]
    check(row['rng_before'] == previous['rng_before'] and row['rng_after'] == previous['rng_after'], 'Mesmos estados RNG por semente/caso')
    check(row['evasion_count'] == previous['evasion_count'], 'Mesmo número de esquivas na confirmação')
cases = []
for row in execution['rows']:
    report = json.loads((P/row['report']).read_text())
    before = old_primary[key(row)]
    old_report = json.loads((OLD/before['report']).read_text())
    config = report['conditions']
    stat = 'vigor' if row['action_id'] in ('poison','slow') else 'intelligence'
    mag = config['attacker']['magic_power']
    specific = config['target'][stat]
    md = config['target']['magic_defense']
    resistance = md + specific
    eva = config['target']['evasion_base'] if config['action']['evasion_allowed'] else 0
    probability = mag/(mag+resistance)
    total_probability = (1-eva/100)*probability
    check(report['formula']['id'] == 'affliction_application_v2', 'Versão atual da fórmula')
    check(config['attacker'] == old_report['conditions']['attacker'] and config['target'] == old_report['conditions']['target'], 'Fichas efetivas idênticas nas duas versões')
    check(config['action']['mp_cost'] == 4 and config['action']['resistance_stat'] == stat, 'Ação e custo definidos')
    check(math.isclose(report['summary']['application_chance'],100*probability) and math.isclose(report['summary']['total_application_chance'],100*total_probability), 'Probabilidades calculadas')
    check(report['run']['rng_before'] == old_report['run']['rng_before'] and report['run']['rng_after'] == old_report['run']['rng_after'], 'Mesmos estados RNG primários')
    counts = defaultdict(int)
    switched = 0
    for i,(sample,old_sample) in enumerate(zip(report['samples'],old_report['samples']),1):
        check(sample['index'] == sample['sequence_index'] == i, 'Índices corretos')
        evaded = sample['evasion_roll']*100 < eva
        applied = not evaded and sample['affliction']['roll'] < probability
        outcome = 'evaded' if evaded else 'applied' if applied else 'resisted'
        check(sample['outcome'] == outcome and sample['affliction']['applied'] == applied and sample['affliction']['resisted'] == (not evaded and not applied), 'Resultado independente dos sorteios')
        check(sample['affliction']['tested'] == (not evaded), 'EVA anterior')
        check(sample['affliction']['magic_defense'] == md and sample['affliction']['specific_resistance'] == specific and sample['affliction']['combined_resistance'] == resistance and sample['affliction']['resistance'] == resistance and sample['base']['defense'] == resistance, 'Parcelas e soma da resistência')
        check(math.isclose(sample['affliction']['chance'],100*probability) and math.isclose(sample['affliction']['total_chance'],100*total_probability), 'Probabilidades por amostra')
        check(sample['damage'] == sample['hp_removed'] == 0 and not sample['critical'], 'Sem dano/crítico')
        check(sample['hp_before'] == sample['hp_after'] == config['target']['hp'] and sample['mp_before'] == config['attacker']['mp'] and sample['mp_after'] == config['attacker']['mp']-4, 'Recursos restaurados e custo4MP')
        check(all(sample[r] == old_sample[r] for r in ('variation_roll','critical_roll','evasion_roll')) and sample['affliction']['roll'] == old_sample['affliction']['roll'], 'Mesmos quatro sorteios por tentativa')
        check(sample['evaded'] == old_sample['evaded'], 'Esquiva idêntica nas duas versões')
        if sample['outcome'] != old_sample['outcome']:
            switched += 1
            check(old_sample['outcome'] == 'applied' and sample['outcome'] == 'resisted', 'Mudança somente de aplicação para resistência')
        counts[outcome] += 1
    for outcome,field in [('applied','applied_count'),('resisted','resisted_count'),('evaded','evasion_count')]:
        check(counts[outcome] == report['summary'][field] == row[field], 'Resumo coincide com as amostras')
    records = [row] + additional[row['index']]
    check(len(records) == 5 and len({r['seed'] for r in records}) == 5, 'Cinco sementes por caso')
    n = sum(r['count'] for r in records)
    applications = sum(r['applied_count'] for r in records)
    evasions = sum(r['evasion_count'] for r in records)
    resistances = sum(r['resisted_count'] for r in records)
    check(n == applications+evasions+resistances == 5000, 'Contagens combinadas')
    previous = old_cases[key(row)]
    check(evasions == previous['combined_evaded'], 'Mesmas esquivas combinadas')
    check(applications <= previous['combined_applied'], 'Adicionar DEF M não aumenta aplicações')
    observed = 100*applications/n
    cases.append({**row,'combined_count':n,'combined_applied':applications,'combined_evaded':evasions,'combined_resisted':resistances,'observed_application_pct':observed,'expected_application_pct':100*total_probability,'delta_percentage_points':observed-100*total_probability,'observed_evasion_pct':100*evasions/n,'previous_observed_pct':previous['observed_application_pct'],'previous_expected_pct':previous['expected_application_pct'],'change_from_previous_percentage_points':observed-previous['observed_application_pct'],'primary_switched_to_resisted':switched,'seeds':[r['seed'] for r in records]})
check(len(cases) == 16 and len(execution['blocked_pairs']) == 2, 'Cobertura dos confrontos válidos e bloqueios')
lookup = {key(r):r for r in cases}
for row in cases:
    twin = {'poison':'slow','slow':'poison','confusion':'fear','fear':'confusion'}[row['action_id']]
    check(row['combined_applied'] == lookup[(row['attacker'],row['target'],twin)]['combined_applied'], 'Simetria entre magias com mesma fórmula/resistência')
max_delta = max(abs(r['delta_percentage_points']) for r in cases)
summary = {'date':'2026-10-29','formula_id':'affliction_application_v2','analyzed_attempts':sum(r['combined_count'] for r in cases),'primary_attempts':16000,'confirmation_attempts':64000,'audit_checks':checks,'divergences':0,'presets_unchanged':True,'presets_identical_to_previous_study':True,'max_abs_delta_percentage_points':max_delta,'cases':cases,'blocked_pairs':execution['blocked_pairs'],'method':'Cinco sementes por caso; mesmos sorteios entre casos e versões. Não agregar as80.000 tentativas como observações independentes.'}
(P/'analise.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
fmt=lambda x:f'{x:.2f}'.replace('.',',')
lines=['# Aflições com DEF M entre todos os presets — 29/10/2026','', '**Resultado:** 80.000 tentativas da versão D111, em80 lotes de1.000. As16 combinações de confronto/magia tiveram5.000 tentativas cada. Zero falhas funcionais ou divergências na conferência dos cálculos/sorteios. Nenhum atributo, preset ou código do jogo foi alterado por este estudo.','', '## Método e referências','', 'Três presets atuais da biblioteca pessoal; dois aliados e um monstro. Quatro confrontos válidos, nos dois sentidos, com Veneno/Lentidão/Confusão/Medo. Aliado #1↔Aliado #2 permanece bloqueado pela regra sem fogo amigo. Sementes421,733,112,2026 e31415, reiniciadas a cada caso, iguais às do estudo anterior. Os16 lotes primários foram exportados completos em JSONv5 com fórmula `affliction_application_v2`; as outras sementes possuem resumos, estados e hashes reproduzíveis.','', '| Preset | MAG | DEF M | VIG | INT | EVA efetiva | MP |','| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for p in sorted(json.loads((P/'inventario.json').read_text()), key=lambda p:p['name']):
    e=p['effective'];lines.append(f"| {p['name']} | {int(e['magic_power'])} | {int(e['magic_defense'])} | {int(e['vigor'])} | {int(e['intelligence'])} | {int(e['evasion_base'])}% | {int(e['mp'])} |")
lines += ['', 'Fórmula: `P(aplicar | sem esquiva) = MAG / (MAG + DEF M + VIG ou INT)`. Chance por tentativa = `(1 − EVA/100) × chance após EVA`. Mesmos4MP, HP/MP restaurados por amostra, sem dano direto/crítico e sem limites artificiais.','', '## Resultados atuais','', 'Cada célula mostra **observado / esperado**, incluindo EVA. Ambas as magias de cada grupo foram executadas e obtiveram resultados idênticos com a mesma fórmula, resistência e sorteios.','', '| Atacante → alvo | Veneno / Lentidão | Confusão / Medo |','| --- | ---: | ---: | ---: |'.replace('| --- | ---: | ---: | ---: |','| --- | ---: | ---: |')]
pairs=[('Aliado #1','Monstro #1'),('Aliado #2','Monstro #1'),('Monstro #1','Aliado #1'),('Monstro #1','Aliado #2')]
for attacker,target in pairs:
    a=lookup[(attacker,target,'poison')];b=lookup[(attacker,target,'confusion')]
    lines.append(f"| {attacker} → {target} | {fmt(a['observed_application_pct'])}% / {fmt(a['expected_application_pct'])}% | {fmt(b['observed_application_pct'])}% / {fmt(b['expected_application_pct'])}% |")
lines += ['', f'Maior desvio absoluto observado/esperado: **{fmt(max_delta)} ponto percentual** após5.000 tentativas por caso.','', '## Antes e depois de incluir DEF M','', 'Valores observados, já com EVA, usando os mesmos presets e sorteios nas duas versões.','', '| Atacante → alvo | Veneno / Lentidão: antes → agora | Confusão / Medo: antes → agora |','| --- | ---: | ---: |']
for attacker,target in pairs:
    a=lookup[(attacker,target,'poison')];b=lookup[(attacker,target,'confusion')]
    lines.append(f"| {attacker} → {target} | {fmt(a['previous_observed_pct'])}% → {fmt(a['observed_application_pct'])}% | {fmt(b['previous_observed_pct'])}% → {fmt(b['observed_application_pct'])}% |")
lines += ['', 'As esquivas foram idênticas nas mesmas posições dos sorteios. A única mudança de resultado foi Aplicou→Resistiu. O hash do arquivo de presets coincide com o estudo anterior.','', '## Análise','', '1. **DEF M reduziu a frequência de todas as aflições conforme esperado.** Contra o monstro, aplicações dos aliados passaram de48,42% para28,86% em Veneno/Lentidão e de55,14% para31,06% em Confusão/Medo. A DEF M28 do monstro passou a contribuir junto de VIG20/INT15.','2. **Os aliados continuam iguais ao lançar as magias.** Ambos têm MAG20 e enfrentam o mesmo alvo. Armas e crítico não influenciam o teste; mesma semente produz resultados idênticos.','3. **O monstro agora aplica com mais facilidade nesses confrontos.** Sua MAG25 enfrenta DEF M21 dos aliados, enquanto MAG20 dos aliados enfrenta DEF M28 do monstro. A maior MAG e as resistências dos alvos explicam os resultados; não se trata de bônus oculto.','4. **Aliado #1 e #2 estão quase empatados contra Veneno/Lentidão.** Chances teóricas33,45% e33,33%: EVA12% de #2 compensa VIG20 contra VIG25/EVA5% de #1. As taxas observadas33,74% e33,32% variam pelos sorteios. Em Confusão/Medo, #2 segue mais protegido pela EVA maior, com a mesma INT20 dos dois.','5. **A diferença entre aflições corporais e mentais ficou menor no monstro.** A vantagem teórica de aplicar Confusão/Medo em relação a Veneno/Lentidão passou de6,93 para2,26 pontos, pois DEF M28 agora compõe as duas resistências.','6. **Falhas têm mais peso mantendo4MP por tentativa.** A taxa por tentativa ficou próxima de30% a36% nesses presets. Isso não determina sozinho se o custo está equilibrado: duração e impacto das aflições em batalha continuam fora deste laboratório.','', '**Recomendação:** usar estes resultados como referência da versão aceita D111, sem alterar automaticamente atributos ou custo. O cálculo está coerente e reproduzível; a avaliação dos efeitos em batalha permanece posterior.','', '## Evidência e reprodução','', f"- Execução primária: {execution['checks']} verificações, zero falhas;16.000 tentativas e reprodução exata da semente.",f"- Confirmação nas outras sementes: {extra['checks']} verificações, zero falhas;64.000 tentativas.",f'- Auditoria independente em Python: {checks} verificações, zero divergências sobre as16.000 amostras primárias, seus sorteios, recursos, resistência combinada e comparação com os registros antigos.','- `execucao.json`, `confirmacao.json` e `analise.json`: condições, resumos por caso/semente, comparações e auditoria.','- `01-poison.json` a `16-fear.json`: amostras primárias completas, chances e parcelas DEF M+VIG/INT.','- Sorteios são compartilhados entre magias, confrontos e versões para comparação. As80.000 tentativas não foram tratadas como um único conjunto de observações estatisticamente independentes.','', 'Na raiz do projeto:','', '```sh','godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/inventario.gd','godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/executar.gd','godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/confirmar_sementes.gd','python3 artifacts/aflicoes-presets-defm-2026-10-29/analisar.py','```','', 'Os scripts de execução usam a biblioteca pessoal e a implementação vigentes. A confirmação pode ser reproduzida a partir das condições congeladas nos JSONs primários. A análise pareada usa os arquivos preservados da versão anterior em `artifacts/aflicoes-presets-2026-10-28/`.','']
(P/'analise.md').write_text('\n'.join(lines))
print('AUDITORIA:',checks,'verificações, zero divergências;80.000 tentativas; maior desvio',fmt(max_delta),'p.p.')
for attacker,target in pairs:
    a=lookup[(attacker,target,'poison')];b=lookup[(attacker,target,'confusion')]
    print(attacker,'→',target,'Veneno/Lentidão',fmt(a['observed_application_pct']),'%; Confusão/Medo',fmt(b['observed_application_pct']),'%')
