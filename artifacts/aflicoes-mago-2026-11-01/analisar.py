"""Audit exported samples and summarize the five-seed mage comparison."""
import collections
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
checks = 0


def check(ok, label):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(label)


def close(a, b):
    return math.isclose(a, b, rel_tol=1e-12, abs_tol=1e-12)


def equivalent(a, b):
    if isinstance(a, bool) or isinstance(b, bool):
        return a is b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return close(a, b)
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(equivalent(a[k], b[k]) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(equivalent(x, y) for x, y in zip(a, b))
    return a == b


execution = json.loads((HERE/'execucao.json').read_text())
confirmation = json.loads((HERE/'confirmacao.json').read_text())
check(execution['failures'] == confirmation['failures'] == 0, 'Godot failures')
check(len(execution['rows']) == 24 and len(confirmation['rows']) == 96, '120 lots')
check(execution['presets_file_unchanged'], 'Library unchanged by study')

baseline = json.loads((ROOT/'artifacts/damage-lab-mage/presets-baseline.json').read_text())
installed = json.loads((ROOT/'artifacts/damage-lab-mage/installed-inventory.json').read_text())
check(len(installed) == 4, 'Four presets reopen')
for old in baseline['presets']:
    current = next(e for e in execution['preset_inventory'] if e['id'] == old['id'])
    check(current['revision'] == old['revision'], 'Existing revision unchanged')
    for stat, value in old['actor'].items():
        check(current['actor'][stat] == value, 'Existing own stat unchanged')
    for category, item in old.get('equipment', {}).items():
        for key, value in item.items():
            if key != 'name':  # Display names are upgraded by the legacy loader.
                check(current['equipment'][category][key] == value, 'Existing equipment unchanged')

old_dir = ROOT/'artifacts/aflicoes-presets-defm-2026-10-29'
old_execution = json.loads((old_dir/'execucao.json').read_text())
old_rows = {(r['attacker'], r['target'], r['action_id']): r for r in old_execution['rows']}
old_confirmation = json.loads((old_dir/'confirmacao.json').read_text())
old_extra = {(r['attacker'],r['target'],r['action_id'],r['seed']): r for r in old_confirmation['rows']}
agg = collections.defaultdict(lambda: dict(count=0,applied=0,resisted=0,evaded=0))
expected = {}
old_compared = 0
for row in execution['rows']:
    report = json.loads((HERE/row['report']).read_text())
    c = report['conditions']
    a, t = c['attacker'], c['target']
    resistance = t['magic_defense'] + t[c['action']['resistance_stat']]
    chance = a['magic_power']/(a['magic_power']+resistance)
    chance_total = (1-t['evasion_base']/100)*chance*100
    key = (row['attacker'],row['target'],row['action_id'])
    expected[key] = chance_total
    check(close(row['total_application_chance'],chance_total), 'Theoretical chance')
    check(report['formula']['id'] == 'affliction_application_v2', 'Formula preserved')
    counts = collections.Counter()
    for sample in report['samples']:
        evaded = sample['evasion_roll'] < t['evasion_base']/100
        applied = not evaded and sample['affliction']['roll'] < chance
        outcome = 'evaded' if evaded else 'applied' if applied else 'resisted'
        counts[outcome] += 1
        check(sample['outcome'] == outcome and sample['evaded'] == evaded, 'Outcome from rolls')
        check(sample['affliction']['applied'] == applied and sample['affliction']['tested'] == (not evaded), 'EVA before resistance')
        check(sample['affliction']['combined_resistance'] == resistance and close(sample['affliction']['chance'],chance*100), 'Effective resistance and MAG')
        check(sample['hp_before'] == sample['hp_after'] and sample['damage'] == sample['hp_removed'] == 0 and not sample['critical'], 'Zero damage and no critical')
        check(sample['mp_before']-sample['mp_after'] == 4, 'MP cost')
    check(counts['applied'] == row['applied_count'] and counts['evaded'] == row['evasion_count'] and counts['resisted'] == row['resisted_count'], 'Summary totals')
    if key in old_rows:
        old_report = json.loads((old_dir/old_rows[key]['report']).read_text())
        check(equivalent(report['samples'], old_report['samples']), 'All legacy samples preserved')
        check(report['run']['rng_before'] == old_report['run']['rng_before'] and report['run']['rng_after'] == old_report['run']['rng_after'], 'Legacy RNG states exact')
        old_compared += len(report['samples'])
    rows = [row] + [r for r in confirmation['rows'] if r['case_index'] == row['index']]
    for r in rows:
        check(r['applied_count']+r['resisted_count']+r['evasion_count'] == 1000, 'Five-seed counts')
        check(close(r['total_application_chance'], chance_total), 'Five-seed theory')
        if (key + (r['seed'],)) in old_extra:
            old = old_extra[key + (r['seed'],)]
            check(all(r[k] == old[k] for k in ['applied_count','resisted_count','evasion_count']), 'Legacy extra-seed counts preserved')
        for name, field in [('count','count'),('applied','applied_count'),('resisted','resisted_count'),('evaded','evasion_count')]:
            agg[key][name] += r[field]

summary = []
for key, counts in agg.items():
    observed = 100*counts['applied']/counts['count']
    summary.append(dict(attacker=key[0],target=key[1],action=key[2],**counts,observed_percent=observed,expected_percent=expected[key],deviation_pp=observed-expected[key]))
check(sum(r['count'] for r in summary) == 120000, '120000 attempts')
for r in summary:
    if r['action'] in ['poison','confusion']:
        other_action = 'slow' if r['action']=='poison' else 'fear'
        other = agg[(r['attacker'],r['target'],other_action)]
        check(all(r[k] == other[k] for k in ['count','applied','resisted','evaded']), 'Equal-formula pair and shared seeds')
result=dict(checks=checks,failures=0,attempts=120000,legacy_primary_samples_compared=old_compared,rows=summary,max_deviation_pp=max(abs(r['deviation_pp']) for r in summary))
(HERE/'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=['# Aflições com o mago — 01/11/2026','','**Resultado:** 120.000 tentativas da versão D111 com três aliados e um monstro, quatro magias, dois sentidos e cinco sementes. Zero falhas nas execuções e na auditoria.','','## Condições','','MAG/DEF M naturais do mago30/30; Cajado de Madeira/Veste Simples somam10 cada, resultando40/40. HP30, MP24, INI7, VIG15, INT25, EVA3%; defesas físicas16+2=18. Aliados #1/#2 e Monstro #1 preservados.','','Cada caso recebeu5.000 tentativas: sementes421/733/112/2026/31415 e mil amostras por semente. Mesmo fluxo RNG entre magias/confrontos para comparação; o conjunto não representa120 mil observações estatisticamente independentes. Recursos restaurados por amostra: o estudo não mede autonomia de MP, ATB ou duração/efeitos das aflições.','','## Aplicações por tentativa, incluindo EVA','','| Atacante → alvo | Veneno/Lentidão observado (teórico) | Confusão/Medo observado (teórico) |','| --- | ---: | ---: |']
for attacker,target in dict.fromkeys((r['attacker'],r['target']) for r in summary):
    a=next(r for r in summary if r['attacker']==attacker and r['target']==target and r['action']=='poison')
    b=next(r for r in summary if r['attacker']==attacker and r['target']==target and r['action']=='confusion')
    f=lambda x: f"{x:.2f}".replace('.',',')
    lines.append(f"| {attacker} → {target} | {f(a['observed_percent'])}% ({f(a['expected_percent'])}%) | {f(b['observed_percent'])}% ({f(b['expected_percent'])}%) |")
lines += ['', '## Leitura dos resultados','', 'O mago aplica aflições com mais frequência graças à MAG equipada40, contra20 dos demais aliados. A DEF M equipada40 reduz a aplicação inimiga; INT25 protege mais contra Confusão/Medo do que VIG15 contra Veneno/Lentidão. EVA3% mantém menor esquiva. Isso não substitui o teste futuro de fragilidade física e ritmo em batalha.', '', f"As16.000 amostras primárias anteriores mantiveram resultados e sorteios na precisão decimal dos JSONs (tolerância relativa1e-12); estados RNG textuais idênticos. Contagens das outras sementes anteriores também preservadas. Auditoria Python: {checks} verificações, zero divergências. Maior desvio observado/teórico: {result['max_deviation_pp']:.2f} ponto percentual.", '', '## Reprodução','', 'Na raiz do projeto, com a biblioteca pessoal contendo os quatro presets:', '', '```sh','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-study.log --path . --script res://artifacts/aflicoes-mago-2026-11-01/executar.gd','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-confirm.log --path . --script res://artifacts/aflicoes-mago-2026-11-01/confirmar_sementes.gd','python3 artifacts/aflicoes-mago-2026-11-01/analisar.py','```','', 'As condições congeladas estão nos24 JSONs primários; a confirmação usa essas condições, sem precisar da biblioteca pessoal. Relatórios anteriores permanecem intactos.']
(HERE/'analise.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='rows'},ensure_ascii=False))
