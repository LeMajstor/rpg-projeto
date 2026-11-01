"""Independent physical damage and survival audit; no changes to game data."""
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


def verify_step(config, variation, critical_roll, evasion_roll, damage, critical, evaded):
    mode=config['action']['physical_mode']
    attack=config['attacker']['ranged_attack' if mode=='ranged' else 'physical_attack']
    defense=config['target']['ranged_defense' if mode=='ranged' else 'physical_defense']
    expected_evade=config['action']['evasion_allowed'] and evasion_roll < config['target']['evasion_base']/100
    expected_crit=not expected_evade and config['settings']['critical_mode']!='off' and critical_roll < config['attacker']['critical_base']/100
    multiplier=config['attacker']['unarmed_critical_multiplier'] if expected_crit else 1
    raw=attack*attack/(attack+defense)*(.9+.2*variation)*multiplier
    expected_damage=0 if expected_evade else max(1,math.floor(raw+.5))
    check(evaded==expected_evade and critical==expected_crit and damage==expected_damage,'Independent damage/critical/evasion calculation')


def damage_distribution(attack, defense, multiplier=1):
    low=attack*attack/(attack+defense)*.9*multiplier
    high=attack*attack/(attack+defense)*1.1*multiplier
    result={d:max(0,min(high,d+.5)-max(low,d-.5))/(high-low) for d in range(math.floor(low+.5),math.floor(high+.5)+1)}
    check(close(sum(result.values()),1),'Exact uniform-rounding distribution')
    return result


def knockout_distribution(hp, distribution):
    states={hp:1.0}
    result={}
    for turn in range(1,300):
        next_states=collections.defaultdict(float)
        fallen=0
        for left,p in states.items():
            for damage,pd in distribution.items():
                if damage>=left:
                    fallen+=p*pd
                else:
                    next_states[left-damage]+=p*pd
        if fallen: result[turn]=fallen
        states=next_states
        if sum(states.values()) < 1e-14: break
    check(close(sum(result.values()),1),'First-passage distribution mass')
    return result


execution=json.loads((HERE/'execucao.json').read_text())
check(execution['failures']==0 and execution['presets_file_unchanged'],'Godot and library preservation')
check(len(execution['shot_rows'])==30 and len(execution['survival_rows'])==60,'Complete six-case matrix')
shots=collections.defaultdict(list)
configs={}
reference_rolls={}
for row in execution['shot_rows']:
    report=json.loads((HERE/row['report']).read_text())
    config=report['conditions']
    key=(row['character_id'],row['mode'])
    configs[key]=config
    check(config['attacker']['name']=='Monstro #1' and config['action']['mp_cost']==0 and config['action']['power']==1,'Basic physical attack')
    check(config['settings']['critical_mode']=='rolled' and config['attacker']['critical_base']==3 and config['attacker']['unarmed_critical_multiplier']==2,'Enemy critical source remains 3%/2x')
    check(config['damage_stats']['defense_stat']==('ranged_defense' if row['mode']=='ranged' else 'physical_defense'),'Correct physical defense')
    for s in report['samples']:
        verify_step(config,s['variation_roll'],s['critical_roll'],s['evasion_roll'],s['damage'],s['critical'],s['evaded'])
        check(s['hp_before']==config['target']['hp'] and s['hp_after']==max(0,s['hp_before']-s['damage']) and s['hp_removed']==min(s['hp_before'],s['damage']) and s['mp_before']==s['mp_after'],'Per-sample resources')
        roll_key=(row['seed'],s['index'])
        rolls=(s['variation_roll'],s['critical_roll'],s['evasion_roll'])
        if roll_key in reference_rolls:
            check(reference_rolls[roll_key]==rolls,'Paired RNG across six cases')
        else:
            reference_rolls[roll_key]=rolls
    check(sum(s['damage'] for s in report['samples'])==report['summary']['total'],'Exported total')
    shots[key].extend(report['samples'])

survival=collections.defaultdict(list)
for row in execution['survival_rows']:
    report=json.loads((HERE/row['report']).read_text())
    config=report['config']
    key=(row['character_id'],row['mode'],row['normal_only'])
    attempt_hist=collections.Counter()
    hit_hist=collections.Counter()
    total_attempts=total_hits=0
    for trial in report['trials']:
        left=report['hp']
        hits=crits=evades=0
        for index,step in enumerate(trial['steps']):
            variance,critical_roll,evasion_roll,damage,critical,evaded=step
            verify_step(config,variance,critical_roll,evasion_roll,damage,critical,evaded)
            check(left>0,'Stop trial at first incapacitation')
            left=max(0,left-damage)
            hits+=not evaded
            crits+=critical
            evades+=evaded
        check(left==0 and trial['attempts']==len(trial['steps']) and trial['hits']==hits and trial['criticals']==crits and trial['evasions']==evades,'Independent HP accumulation and trial counts')
        check(trial['last_damage']==trial['steps'][-1][3] and trial['last_critical']==trial['steps'][-1][4],'Last blow record')
        if row['normal_only']:
            check(evades==crits==0 and trial['attempts']==hits,'Normal-only diagnostic')
        attempt_hist[str(trial['attempts'])]+=1
        hit_hist[str(hits)]+=1
        total_attempts+=trial['attempts']
        total_hits+=hits
    check(dict(attempt_hist)==report['attempt_histogram'] and dict(hit_hist)==report['hit_histogram'],'Survival histograms')
    check(total_attempts==report['attempts_used'] and total_hits==report['hits_used'] and report['generated_samples']-total_attempts==report['unused_final_buffer'],'Generated/used/unused pool accounting')
    survival[key].extend([{k:v for k,v in t.items() if k!='steps'} for t in report['trials']])

summary=[]
for key,samples in shots.items():
    cid,mode=key
    config=configs[key]
    target=config['target']
    defense=target['ranged_defense' if mode=='ranged' else 'physical_defense']
    normal=damage_distribution(24,defense)
    critical=damage_distribution(24,defense,2)
    evade=target['evasion_base']/100
    hit_distribution=collections.defaultdict(float)
    for d,p in normal.items():hit_distribution[d]+=.97*p
    for d,p in critical.items():hit_distribution[d]+=.03*p
    distribution={0:evade}|{d:(1-evade)*p for d,p in hit_distribution.items()}
    normal_knockout=knockout_distribution(target['hp'],normal)
    mixed_knockout=knockout_distribution(target['hp'],distribution)
    hit_knockout=knockout_distribution(target['hp'],hit_distribution)
    normal_trials=survival[(cid,mode,True)]
    mixed_trials=survival[(cid,mode,False)]
    check(len(samples)==len(normal_trials)==len(mixed_trials)==5000,'5000 shots and trials per condition')
    observed_normal=[s['damage'] for s in samples if not s['evaded'] and not s['critical']]
    observed_critical=[s['damage'] for s in samples if s['critical']]
    row=dict(character_id=cid,target=target['name'],mode=mode,hp=target['hp'],defense=defense,evasion_percent=target['evasion_base'],normal_damage_bounds=[min(normal),max(normal)],critical_damage_bounds=[min(critical),max(critical)],normal_damage_mean_observed=sum(observed_normal)/len(observed_normal),critical_damage_mean_observed=sum(observed_critical)/len(observed_critical),normal_damage_bounds_observed=[min(observed_normal),max(observed_normal)],critical_damage_bounds_observed=[min(observed_critical),max(observed_critical)],damage_mean_observed=sum(s['damage'] for s in samples)/5000,damage_mean_theoretical=sum(d*p for d,p in distribution.items()),evasion_count=sum(s['evaded'] for s in samples),critical_count=sum(s['critical'] for s in samples),normal_count=len(observed_normal),normal_hits_mean_observed=sum(t['hits'] for t in normal_trials)/5000,normal_hits_mean_theoretical=sum(n*p for n,p in normal_knockout.items()),normal_hits_histogram=dict(collections.Counter(t['hits'] for t in normal_trials)),normal_hits_distribution_theoretical=normal_knockout,mixed_attempts_mean_observed=sum(t['attempts'] for t in mixed_trials)/5000,mixed_attempts_mean_theoretical=sum(n*p for n,p in mixed_knockout.items()),mixed_hits_mean_observed=sum(t['hits'] for t in mixed_trials)/5000,mixed_hits_mean_theoretical=sum(n*p for n,p in hit_knockout.items()),mixed_attempt_histogram=dict(collections.Counter(t['attempts'] for t in mixed_trials)),mixed_hit_histogram=dict(collections.Counter(t['hits'] for t in mixed_trials)),one_attempt_knockouts=sum(t['attempts']==1 for t in mixed_trials),one_hit_knockouts=sum(t['hits']==1 for t in mixed_trials),one_attempt_knockout_chance_theoretical=sum(p for d,p in distribution.items() if d>=target['hp']))
    summary.append(row)

check(sum(len(s) for s in shots.values())==30000,'30000 physical attacks')
check(sum(len(s) for s in survival.values())==60000,'60000 accumulated-damage trials')
result=dict(checks=checks,failures=0,shot_count=30000,survival_trial_count=60000,rows=summary)
(HERE/'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
fmt=lambda value:f'{value:.2f}'.replace('.',',')
lines=['# Monstro #1 — dano físico nos três aliados — 01/11/2026','','**Executado:** 30.000 ataques individuais e 60.000 sequências de dano acumulado, com zero falhas/divergências. Nenhum atributo, equipamento, preset ou fórmula foi alterado. Monstro #2 permanece apenas proposta.','','## Condições e método','','- Monstro #1: ATQ F 24, ATQ D 24, CRI 3%, multiplicador físico 2×. Ataque básico de potência 1, custo 0 MP, variação uniforme ±10%, esquiva habilitada.','- Três aliados com equipamentos iniciais: #1 HP 40/DEF F 55/DEF D 50/EVA 5%; #2 HP 36/DEF F 35/DEF D 40/EVA 12%; mago HP 30/DEF F 18/DEF D 18/EVA 3%.','- Contato usa ATQ F/DEF F; distância usa ATQ D/DEF D pelo override já existente no laboratório, sem criar ação inimiga nova.','- Cinco sementes iguais entre casos: 421, 733, 112, 2026, 31415. Cada um dos seis casos recebeu 5.000 golpes e duas condições de 5.000 sequências até 0 HP.','- Nos golpes individuais, o laboratório restaura HP/MP por amostra. Para sobrevivência, um observador separado acumula `damage` em HP local e encerra a sequência no primeiro 0 HP. A próxima começa com HP cheio. Sem cura, buffs, ações dos aliados, ATB, seleção de alvos ou efeitos contínuos.','- Diagnóstico normal: crítico desligado/esquiva desabilitada para contar acertos normais necessários. Condição mista: críticos 3% e EVA real habilitados, contando todas as tentativas, inclusive esquivas.','- Fluxos RNG continuam entre buffers de mil amostras. Amostras não usadas no último buffer são explicitamente contabilizadas; hashes e estado final referem-se ao buffer completo. Cada sequência guarda passos (variação, sorteio crítico, sorteio EVA, dano, crítico, esquiva), auditados independentemente em Python.','- Sorteios compartilhados permitem comparação pareada; não tratar repetições entre casos como observações estatisticamente independentes.','','## Dano por tentativa','','As faixas abaixo são limites da fórmula com variação; a média observada inclui dano normal, crítico e zeros de esquiva. Cada linha corresponde a 5.000 tentativas.','','| Ataque | Alvo | Normal | Crítico | Média recebida | Esquivas | Críticos |','| --- | --- | ---: | ---: | ---: | ---: | ---: |']
for r in summary:
    normal='–'.join(str(x) for x in r['normal_damage_bounds'])
    crit='–'.join(str(x) for x in r['critical_damage_bounds'])
    lines.append(f"| {'Contato' if r['mode']=='melee' else 'Distância'} | {r['target']} | {normal} | {crit} | {fmt(r['damage_mean_observed'])} | {r['evasion_count']} | {r['critical_count']} |")
lines+=['','## Até a incapacitação','','Resultados de 5.000 sequências por linha/condição. Acertos normais excluem crítico/esquiva; tentativas mistas incluem ambos. Médias não foram estimadas dividindo HP pelo dano médio: houve acumulação e encerramento no primeiro 0 HP. A teoria usa distribuição exata da variação arredondada e programação dinâmica.','','| Ataque | Alvo | Acertos normais para cair | Distribuição normal observada | Tentativas mistas médias (teoria) |','| --- | --- | ---: | --- | ---: |']
for r in summary:
    hist=r['normal_hits_histogram']
    ns=sorted(int(x) for x in hist)
    text=str(ns[0]) if len(ns)==1 else f'{ns[0]}–{ns[-1]}'
    detail='; '.join(f'{n}: {fmt(hist[n]/50)}%' for n in sorted(hist))
    lines.append(f"| {'Contato' if r['mode']=='melee' else 'Distância'} | {r['target']} | {text} | {detail} | {fmt(r['mixed_attempts_mean_observed'])} ({fmt(r['mixed_attempts_mean_theoretical'])}) |")
lines+=['','## Leitura dos resultados','','O mago é o mais frágil fisicamente nas duas modalidades. DEF F/DEF D e HP baixos pesam mais que a proteção mágica, que não participa desses golpes. Contato e distância produzem os mesmos resultados no mago porque o inimigo tem ATQ F/ATQ D iguais e a veste dá defesas físicas iguais. Essas duas linhas não são evidências estatísticas independentes.','']
for r in summary:
    if r['character_id']=='ally_3' and r['mode']=='melee':
        hist=r['normal_hits_histogram']
        lines.append(f"Com HP 30, o mago caiu em três acertos normais em {fmt(hist.get(3,0)/50)}% das sequências e em dois em {fmt(hist.get(2,0)/50)}%. Com críticos/esquivas, média {fmt(r['mixed_attempts_mean_observed'])} tentativas. Um crítico pode causar 30 e derrubá-lo com HP cheio: {r['one_attempt_knockouts']} de 5.000 sequências terminaram já na primeira tentativa ({fmt(r['one_attempt_knockouts']/50)}%); probabilidade teórica {fmt(r['one_attempt_knockout_chance_theoretical']*100)}%. Foram {r['one_hit_knockouts']} sequências encerradas no primeiro acerto, incluindo casos com esquivas antes dele.")
lines+=['','O primeiro aliado segue como o mais resistente. O traje do segundo favorece disparos: recebe menos dano de distância que de contato. Isso não o torna mais resistente que o primeiro, cujos HP e defesas totais continuam maiores.','','**Recomendação:** usar esta bateria como referência antes de adotar P16. A ficha atual do mago já permite uma queda rara por crítico do Monstro #1; a proposta de ATQ F 27 tornaria o risco maior. Definir a tolerância desejada antes de cadastrar Monstro #2. Nenhum ajuste automático foi realizado.','','## Evidência e reprodução','',f"Godot: {execution['checks']} verificações, zero falhas. Auditoria Python: {checks}, zero divergências; cada passo das sequências acumuladas recalculado. A distribuição teórica foi calculada separadamente, sem substituir a simulação executada.",'','Na raiz do projeto:','','```sh','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-physical-three.log --path . --script res://artifacts/monstro-fisico-tres-aliados-2026-11-01/executar.gd','python3 artifacts/monstro-fisico-tres-aliados-2026-11-01/analisar.py','```','','A execução usa os presets pessoais vigentes e verifica preservação integral do arquivo; a auditoria usa relatórios congelados. `execucao.json` registra presets, sementes, relatórios e hash. Arquivos `*-survival-normal.json`/`*-survival-mixed.json` guardam a observação acumulada, não batalhas com ATB.']
(HERE/'analise.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='rows'}))
for r in summary:
    print(r['mode'],r['target'],'normal',r['normal_damage_bounds'],'crítico',r['critical_damage_bounds'],'média',r['damage_mean_observed'],'acertos normais',r['normal_hits_histogram'],'tentativas',r['mixed_attempts_mean_observed'],'KO na primeira',r['one_attempt_knockouts'])
