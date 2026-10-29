"""Audita os JSONs do Godot e resume os cinco conjuntos de sorteios por caso."""
from pathlib import Path
import json, math
from collections import defaultdict

DIRECTORY = Path(__file__).resolve().parent
base = json.loads((DIRECTORY / 'execucao.json').read_text())
confirmation = json.loads((DIRECTORY / 'confirmacao.json').read_text())
assert base['failures'] == confirmation['failures'] == 0
assert base['presets_file_unchanged']
assert len(base['preset_inventory']) == 3
additional = defaultdict(list)
for row in confirmation['rows']:
    additional[row['case_index']].append(row)
checks = 0
cases = []

def verify(condition, message):
    global checks
    checks += 1
    assert condition, message

def wilson(successes, count):
    z = 1.959963984540054
    phat = successes / count
    denom = 1 + z*z/count
    center = (phat + z*z/(2*count)) / denom
    margin = z * math.sqrt(phat*(1-phat)/count + z*z/(4*count*count)) / denom
    return [100*(center-margin), 100*(center+margin)]

for row in base['rows']:
    report = json.loads((DIRECTORY / row['report']).read_text())
    config = report['conditions']
    stat = 'vigor' if row['action_id'] in ('poison', 'slow') else 'intelligence'
    magic = config['attacker']['magic_power']
    resistance = config['target'][stat]
    eva = config['target']['evasion_base'] if config['action']['evasion_allowed'] else 0
    p = magic / (magic + resistance)
    ptotal = (1 - eva/100) * p
    verify(config['action']['resistance_stat'] == stat, 'Resistência usada')
    verify(config['action']['mp_cost'] == 4 and config['action']['evasion_allowed'], 'Custo e permissão')
    verify(math.isclose(report['summary']['application_chance'], 100*p), 'Chance condicional')
    verify(math.isclose(report['summary']['total_application_chance'], 100*ptotal), 'Chance total')
    counts = defaultdict(int)
    for index, sample in enumerate(report['samples'], 1):
        evaded = sample['evasion_roll']*100 < eva
        applied = not evaded and sample['affliction']['roll'] < p
        outcome = 'evaded' if evaded else 'applied' if applied else 'resisted'
        verify(sample['outcome'] == outcome, 'Resultado do sorteio')
        verify(sample['affliction']['tested'] == (not evaded), 'EVA anterior')
        verify(sample['affliction']['applied'] == applied, 'Aplicação correta')
        verify(sample['affliction']['resisted'] == (not evaded and not applied), 'Resistência correta')
        verify(sample['damage'] == sample['hp_removed'] == 0 and not sample['critical'], 'Sem dano/crítico')
        verify(sample['hp_before'] == sample['hp_after'] == config['target']['hp'], 'HP restaurado/preservado')
        verify(sample['mp_before'] == config['attacker']['mp'] and sample['mp_after'] == config['attacker']['mp']-4, 'MP inicial/custo')
        verify(sample['index'] == sample['sequence_index'] == index, 'Índices')
        counts[outcome] += 1
    for outcome, summary in [('evaded','evasion_count'),('applied','applied_count'),('resisted','resisted_count')]:
        verify(counts[outcome] == report['summary'][summary] == row[summary], 'Resumo confere com amostras')
    records = [row] + additional[row['index']]
    verify(len(records) == 5 and len({r['seed'] for r in records}) == 5, 'Cinco sementes distintas')
    count = sum(r['count'] for r in records)
    applied = sum(r['applied_count'] for r in records)
    evaded = sum(r['evasion_count'] for r in records)
    resisted = sum(r['resisted_count'] for r in records)
    verify(count == applied+evaded+resisted == 5000, 'Contagem combinada')
    observed = 100*applied/count
    cases.append({**row, 'combined_count':count,'combined_applied':applied,'combined_evaded':evaded,'combined_resisted':resisted,'observed_application_pct':observed,'expected_application_pct':100*ptotal,'delta_percentage_points':observed-100*ptotal,'observed_conditional_pct':100*applied/(count-evaded),'observed_evasion_pct':100*evaded/count,'wilson_95_pct':wilson(applied,count),'seeds':[r['seed'] for r in records]})

verify(len(cases) == 16, 'Todos os confrontos e magias válidos')
verify(len(base['blocked_pairs']) == 2, 'Dois sentidos entre aliados bloqueados')
# Mesma MAG/alvo e mesma resistência/fórmula/semente dão resultados idênticos.
lookup = {(r['attacker'], r['target'], r['action_id']): r for r in cases}
for r in cases:
    twin = {'poison':'slow','slow':'poison','confusion':'fear','fear':'confusion'}[r['action_id']]
    other = lookup[(r['attacker'],r['target'],twin)]
    verify(r['combined_applied'] == other['combined_applied'], 'Simetria esperada entre magias equivalentes')

max_delta = max(abs(r['delta_percentage_points']) for r in cases)
result = {'primary_attempts':sum(r['count'] for r in base['rows']),'confirmation_attempts':sum(r['count'] for r in confirmation['rows']),'analyzed_attempts':sum(r['combined_count'] for r in cases),'primary_json_audit_checks':checks,'max_abs_delta_percentage_points':max_delta,'presets_file_unchanged':base['presets_file_unchanged'],'cases':cases,'blocked_pairs':base['blocked_pairs'],'method':'Cinco sementes por caso. Sorteios compartilhados entre confrontos/magias para comparação; não agregar casos equivalentes como experimentos independentes.'}
(DIRECTORY / 'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')

fmt = lambda n: f'{n:.2f}'.replace('.',',')
lines = ['# Aflições entre todos os presets salvos — 28/10/2026','', '**Resultado:** 80 lotes de1.000 tentativas,80.000 tentativas analisadas. As16 combinações válidas de confronto/magia foram testadas com5.000 tentativas cada. Zero falhas de execução ou divergências na conferência dos sorteios. Presets e parâmetros do jogo não foram alterados.','', '## Configuração e cobertura','', 'Presets reais da biblioteca pessoal, carregados pelo mesmo modelo do laboratório. Dois aliados e um monstro; confronto nos dois sentidos. Os dois sentidos Aliado #1↔Aliado #2 foram recusados pela regra vigente sem fogo amigo. Não houve mudança de facção, nem simulação de Confusão ativa para contornar essa regra.','', '| Preset | MAG | VIG | INT | EVA própria | EVA efetiva | MP | Revisão |','| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
inv = json.loads((DIRECTORY / 'inventario.json').read_text())
for p in sorted(inv,key=lambda x:x['name']):
    a,e=p['own'],p['effective']
    lines.append(f"| {p['name']} | {int(e['magic_power'])} | {int(e['vigor'])} | {int(e['intelligence'])} | {int(a['evasion_base'])} | {int(e['evasion_base'])}% | {int(e['mp'])} | {int(p['revision'])} |")
lines += ['', 'Semente primária421:16 lotes/16.000 tentativas, exportados integralmente em JSONv5. Confirmação com sementes733,112,2026 e31415:64 lotes/64.000 tentativas. Mesma semente reiniciada em cada caso para comparar as mesmas posições dos sorteios. A repetição exata da semente primária também foi conferida, sem somá-la como nova observação estatística.','', 'Fórmula pura: `P(aplicar | sem esquiva) = MAG / (MAG + VIG ou INT)`. Chance por tentativa: `(1 − EVA efetiva / 100) × P(aplicar | sem esquiva)`. Veneno/Lentidão usam VIG; Confusão/Medo usam INT. Custo4MP, HP/MP restaurados por tentativa; sem dano direto ou crítico.','', '## Resultados combinados','', 'Cada célula mostra **observado / esperado**, já incluindo EVA. Veneno/Lentidão compartilham as mesmas chances e sorteios; o mesmo vale para Confusão/Medo. As duas magias de cada grupo foram efetivamente executadas.','', '| Atacante → alvo | Veneno / Lentidão | Confusão / Medo |','| --- | ---: | ---: |']
for attacker,target in [('Aliado #1','Monstro #1'),('Aliado #2','Monstro #1'),('Monstro #1','Aliado #1'),('Monstro #1','Aliado #2')]:
    a=lookup[(attacker,target,'poison')];b=lookup[(attacker,target,'confusion')]
    lines.append(f"| {attacker} → {target} | {fmt(a['observed_application_pct'])}% / {fmt(a['expected_application_pct'])}% | {fmt(b['observed_application_pct'])}% / {fmt(b['expected_application_pct'])}% |")
lines += ['',f'O maior desvio absoluto entre observado e esperado foi **{fmt(max_delta)} ponto percentual** após5.000 tentativas por caso. Na semente421 isolada houve desvios negativos de2,43 a3,69 pontos; a confirmação nas outras sementes aproxima os resultados da fórmula, sem alterar atributos ou filtrar resultados.','', '## Análise','', '1. **A fórmula e a ordem EVA→resistência estão coerentes.** A conferência independente dos16.000 registros primários recalculou resultado, chance, custo e estado de HP/MP. As64.000 amostras de confirmação também tiveram os sorteios e recursos conferidos.','2. **Os aliados têm o mesmo desempenho ofensivo de aflição.** Ambos usam MAG20 contra o mesmo monstro. Arco/espada, ATQ F/ATQ D e crítico não entram nesse teste; os resultados idênticos com sorteios compartilhados são esperados.','3. **O monstro é mais vulnerável a Confusão/Medo:** INT15 contra VIG20. A probabilidade por tentativa sobe de48,50% para55,43%, diferença teórica de6,93 pontos. Isso é uma consequência dos valores provisórios, sem concluir que os efeitos mentais são mais fortes no jogo.','4. **EVA compensa parte da VIG menor do Aliado #2.** Contra MAG25 do monstro, #1 tem VIG25/EVA5% e chance corporal47,50%; #2 tem VIG20/EVA12% e48,89%. A diferença teórica fica em1,39 ponto. Em aflições mentais os dois têm INT20, então EVA12% torna #2 mais resistente:48,89% de aplicação contra52,78% de #1.','5. **MAG25 do monstro não garante vantagem em qualquer confronto.** MAG maior melhora chance contra o mesmo alvo; entre alvos diferentes, VIG/INT e EVA também mudam. Os resultados próximos de50% são coerentes com atributos iniciais da mesma ordem de grandeza.','6. **4MP é relevante para as reservas atuais.** Sem recuperar MP, #1 com12MP e #2 com14MP comportam3 tentativas cada; Monstro #1 com8MP comporta2. Isso é uma leitura das fichas, não uma simulação de batalha: no laboratório, os recursos são restaurados por amostra.','', '**Recomendação:** manter estes valores como referência inicial para a avaliação do usuário. Os testes não apontam necessidade de corrigir a fórmula ou alterar atributos automaticamente. A eficácia de cada efeito em combate, duração e ticks continuam fora deste estudo.','', '## Evidência e reprodução','', f'- Auditoria independente em Python: {checks:,} verificações sobre relatórios/contagens e16.000 amostras primárias, sem divergências.'.replace(',','.'),'- Modelo Godot:32.149 verificações na execução primária,128.128 na confirmação, zero falhas.','- `execucao.json`: inventário, hash do arquivo de presets, resultados primários e pares bloqueados.','- `01-poison.json` a `16-fear.json`: todas as amostras primárias, condições e estados de RNG.','- `confirmacao.json`: contagens por semente/caso, estados e hashes das amostras de confirmação; os scripts permitem regenerá-las.','- `analise.json`: resultados combinados, desvios e intervalos de Wilson95% por caso.','- Intervalos por caso não representam intervalos independentes entre magias/confrontos: estes compartilham sorteios. Não foi feito agrupamento estatístico das80.000 tentativas como se fossem um único teste independente.','', 'Na raiz do projeto, execute nesta ordem:','', '```sh','godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/inventario.gd','godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/executar.gd','godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/confirmar_sementes.gd','python3 artifacts/aflicoes-presets-2026-10-28/analisar.py','```','', 'A execução utiliza a biblioteca pessoal disponível no momento. Para reproduzir somente a confirmação histórica, mantenha os JSONs primários e rode `confirmar_sementes.gd`, que lê as condições congeladas desses relatórios.','']
(DIRECTORY / 'analise.md').write_text('\n'.join(lines))
print('Auditoria independente:',checks,'verificações;0 divergências')
print('Tentativas analisadas:',result['analyzed_attempts'],'; maior desvio:',fmt(max_delta),'p.p.')
for r in cases:
    if r['action_id'] in ('poison','confusion'):
        print(r['attacker'],'→',r['target'],r['action_id'],fmt(r['observed_application_pct']),'/ esperado',fmt(r['expected_application_pct']))
