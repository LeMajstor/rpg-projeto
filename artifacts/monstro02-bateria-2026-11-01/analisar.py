"""Audit samples, accumulated damage and exact distributions for both monsters."""
import argparse
import collections
import gzip
import hashlib
import json
import math
from pathlib import Path

HERE=Path(__file__).resolve().parent
checks=0


def check(ok,message):
    global checks
    checks+=1
    if not ok: raise AssertionError(message)


def read(name):
    path=HERE/name
    raw=path.read_bytes() if path.exists() else gzip.decompress(Path(str(path)+'.gz').read_bytes())
    return json.loads(raw)


def close(a,b): return math.isclose(a,b,rel_tol=1e-12,abs_tol=1e-12)


def parameters(c):
    mode=c['damage_stats']['mode']
    if mode=='affliction':
        resistance=c['target']['magic_defense']+c['target'][c['action']['resistance_stat']]
        return c['attacker']['magic_power'],resistance,0,0,0
    attack=c['attacker'][c['damage_stats']['attack_stat']]
    defense=c['target'][c['damage_stats']['defense_stat']]
    chance=0
    multiplier=1
    if c['action']['damage_type']=='physical' and c['action']['critical_allowed']:
        if c['attacker']['side']=='ally':
            weapon=c['equipment']['attacker']['weapon']
            bonus=weapon['critical_chance'];multiplier=weapon['critical_multiplier']
        else:
            bonus=0;multiplier=c['attacker']['unarmed_critical_multiplier']
        chance=max(0,min(100,c['attacker']['critical_base']*c['settings']['crit_per_point']+bonus+c['settings']['item_bonus']+c['settings']['buff_bonus']))/100
    if c['settings']['critical_mode']=='off': chance=0
    if c['settings']['critical_mode']=='forced' and chance: chance=1
    return attack,defense,c['action']['power'],chance,multiplier


def verify(c,variance,crit_roll,eva_roll,damage,critical,evaded):
    ev=c['action']['evasion_allowed'] and eva_roll<c['target']['evasion_base']/100
    a,d,p,ch,mult=parameters(c)
    crit=not ev and ch>0 and crit_roll<ch
    span=c['settings']['variation_percent']/100 if c['settings']['variation_enabled'] else 0
    raw=p*a*a/(a+d)*(1-span+2*span*variance)*(mult if crit else 1)
    expected=0 if ev else max(1,math.floor(raw+.5))
    check(evaded==ev and critical==crit and damage==expected,'Independent damage, critical and EVA')


def distribution(c,normal_only=False):
    a,d,p,ch,mult=parameters(c)
    if normal_only:ch=0
    span=c['settings']['variation_percent']/100 if c['settings']['variation_enabled'] else 0
    def integral(m):
        lo=p*a*a/(a+d)*(1-span)*m;hi=p*a*a/(a+d)*(1+span)*m
        if close(lo,hi):return {max(1,math.floor(lo+.5)):1.0}
        return {v:max(0,min(hi,v+.5)-max(lo,v-.5))/(hi-lo) for v in range(max(1,math.floor(lo+.5)),max(1,math.floor(hi+.5))+1)}
    normal=integral(1)
    crit=integral(mult) if ch else {}
    ev=c['target']['evasion_base']/100 if c['action']['evasion_allowed'] and not normal_only else 0
    dist=collections.defaultdict(float,{0:ev})
    for v,pv in normal.items(): dist[v]+=(1-ev)*(1-ch)*pv
    for v,pv in crit.items(): dist[v]+=(1-ev)*ch*pv
    check(close(sum(dist.values()),1),'Exact damage distribution mass')
    return dict(dist),normal,crit


def first_passage(hp,dist):
    state={hp:1.0};result={}
    for n in range(1,300):
        next_state=collections.defaultdict(float);dead=0
        for left,pr in state.items():
            for damage,pd in dist.items():
                if damage>=left:dead+=pr*pd
                else:next_state[left-damage]+=pr*pd
        if dead:result[n]=dead
        state=next_state
        if sum(state.values())<1e-14:break
    check(close(sum(result.values()),1),'Exact first-passage distribution mass')
    return result


execution=read('execucao.json')
check(execution['failures']==0 and execution['presets_file_unchanged'],'Execution and preservation')
check(len(execution['shot_rows'])==110 and len(execution['survival_rows'])==130,'Complete study matrix')
configs={};samples_by_case=collections.defaultdict(list);case_meta={};reference_rng={};reference_rolls={}
for row in execution['shot_rows']:
    report=read(row['report']);c=report['conditions'];case=row['case_id']
    case_meta[case]=row;configs[case]=c
    check(c['action']['id']==row['action_id'] and c['attacker']['side']==('ally' if row['outgoing'] else 'enemy'),'Action and direction')
    if c['attacker']['id']=='enemy_ranged':
        check(row['action_id']=='basic' and c['damage_stats']['mode']=='ranged' and c['action']['damage_type']=='physical','New enemy only physical ranged')
    if row['outgoing'] and row['ally_id'] in ['ally_1','ally_2']:
        check(row['action_id']=='basic' and c['action']['damage_type']=='physical','First two allies do not cast spells')
    key=row['seed']
    states=(report['run']['rng_before'],report['run']['rng_after'])
    if key in reference_rng:check(states==reference_rng[key],'Same four RNG streams across cases')
    else:reference_rng[key]=states
    for s in report['samples']:
        evaded=c['action']['evasion_allowed'] and s['evasion_roll']<c['target']['evasion_base']/100
        if c['action'].get('effect_type')=='affliction':
            a,d,_,_,_=parameters(c);ch=a/(a+d)
            applied=not evaded and s['affliction']['roll']<ch
            check(s['evaded']==evaded and s['affliction']['tested']==(not evaded) and s['affliction']['applied']==applied and s['affliction']['resisted']==(not evaded and not applied),'Independent application/EVA')
            check(s['damage']==s['hp_removed']==0 and not s['critical'] and close(s['affliction']['chance'],ch*100),'Affliction scope')
        else:
            verify(c,s['variation_roll'],s['critical_roll'],s['evasion_roll'],s['damage'],s['critical'],s['evaded'])
        check(s['hp_before']==c['target']['hp'] and s['hp_after']==max(0,s['hp_before']-s['damage']) and s['hp_removed']==min(s['hp_before'],s['damage']) and s['mp_before']-s['mp_after']==c['action']['mp_cost'],'Individual HP/MP restoration')
        roll_key=(row['seed'],s['index'])
        rolls=(s['variation_roll'],s['critical_roll'],s['evasion_roll'])
        if roll_key in reference_rolls:check(rolls==reference_rolls[roll_key],'Paired rolls')
        else:reference_rolls[roll_key]=rolls
    check(sum(s['damage'] for s in report['samples'])==report['summary']['total'],'Damage summary')
    samples_by_case[case].extend(report['samples'])

trials_by_case=collections.defaultdict(list)
for row in execution['survival_rows']:
    report=read(row['report']);c=report['config']
    counts=collections.Counter();hits_hist=collections.Counter();total_attempts=total_hits=0
    for t in report['trials']:
        left=report['hp'];hits=crits=evades=0
        for variance,crit_roll,eva_roll,damage,crit,evaded in t['steps']:
            verify(c,variance,crit_roll,eva_roll,damage,crit,evaded)
            check(left>0,'Stop at first zero HP')
            left=max(0,left-damage);hits+=not evaded;crits+=crit;evades+=evaded
        check(left==0 and len(t['steps'])==t['attempts'] and hits==t['hits'] and crits==t['criticals'] and evades==t['evasions'],'Independent accumulated-damage observer')
        check(t['mp_spent']==t['attempts']*c['action']['mp_cost'] and t['mp_remaining']==c['attacker']['mp']-t['mp_spent'] and t['mp_remaining']>=0,'MP accumulated per sequence')
        if row['normal_only']:check(evades==crits==0 and hits==t['attempts'],'Normal-hit diagnostic')
        counts[str(t['attempts'])]+=1;hits_hist[str(hits)]+=1
        total_attempts+=t['attempts'];total_hits+=hits
    check(dict(counts)==report['attempt_histogram'] and dict(hits_hist)==report['hit_histogram'],'Sequence histograms')
    check(total_attempts==report['attempts_used'] and total_hits==report['hits_used'] and report['generated_samples']-total_attempts==report['unused_final_buffer'],'Buffer accounting')
    trials_by_case[(row['case_id'],row['normal_only'])].extend([{k:v for k,v in t.items() if k!='steps'} for t in report['trials']])

summary=[]
for case,samples in samples_by_case.items():
    c=configs[case];meta=case_meta[case]
    result={k:meta[k] for k in ['case_id','enemy','ally','ally_id','outgoing','action_id','mode']}
    result.update(count=len(samples),attacker=c['attacker']['name'],target=c['target']['name'],hp=c['target']['hp'],mp_cost=c['action']['mp_cost'],evasion_percent=c['target']['evasion_base'] if c['action']['evasion_allowed'] else 0,evasion_count=sum(s['evaded'] for s in samples),critical_count=sum(s['critical'] for s in samples))
    check(len(samples)==5000,'Five thousand attempts per case')
    if c['action'].get('effect_type')=='affliction':
        a,d,_,_,_=parameters(c)
        result.update(applied_count=sum(s['affliction']['applied'] for s in samples),resisted_count=sum(s['affliction']['resisted'] for s in samples),chance_conditional=a/(a+d)*100,chance_total=(1-result['evasion_percent']/100)*a/(a+d)*100)
        result['applied_percent']=result['applied_count']/50
    else:
        dist,normal,crit=distribution(c)
        mixed=trials_by_case[(case,False)]
        normal_trials=trials_by_case.get((case,True),mixed)
        normal_dist,_,_=distribution(c,True)
        normal_pmf=first_passage(c['target']['hp'],normal_dist)
        mixed_pmf=first_passage(c['target']['hp'],dist)
        ns=[s['damage'] for s in samples if not s['evaded'] and not s['critical']]
        cs=[s['damage'] for s in samples if s['critical']]
        result.update(normal_bounds=[min(normal),max(normal)],critical_bounds=[min(crit),max(crit)] if crit else None,mean_damage=sum(s['damage'] for s in samples)/5000,theoretical_mean_damage=sum(d*p for d,p in dist.items()),normal_mean=sum(ns)/len(ns),critical_mean=sum(cs)/len(cs) if cs else None,normal_count=len(ns),normal_hits_histogram=dict(collections.Counter(t['hits'] for t in normal_trials)),normal_hits_theory=normal_pmf,mixed_attempts_histogram=dict(collections.Counter(t['attempts'] for t in mixed)),mixed_hits_histogram=dict(collections.Counter(t['hits'] for t in mixed)),mean_attempts_to_zero=sum(t['attempts'] for t in mixed)/len(mixed),theoretical_attempts_to_zero=sum(n*p for n,p in mixed_pmf.items()),one_attempt_ko=sum(t['attempts']==1 for t in mixed),trial_count=len(mixed),mp_spent_bounds=[min(t['mp_spent'] for t in mixed),max(t['mp_spent'] for t in mixed)])
        check(len(mixed)==len(normal_trials)==5000,'Five thousand sequences per condition')
    summary.append(result)
check(sum(len(v) for v in samples_by_case.values())==110000,'110000 individual attempts')
check(sum(len(v) for v in trials_by_case.values())==130000,'130000 sequences')
result=dict(checks=checks,failures=0,attempts=110000,new_enemy_attempts=55000,survival_trials=130000,new_enemy_survival_trials=65000,rows=summary)
(HERE/'analise.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
fmt=lambda x:f'{x:.2f}'.replace('.',',')
bounds=lambda value:'–'.join(str(x) for x in value) if value else '—'
get=lambda case:next(r for r in summary if r['case_id']==case)
normal_hits=lambda r:'–'.join(str(n) for n in [min(r['normal_hits_histogram']),max(r['normal_hits_histogram'])]) if len(r['normal_hits_histogram'])>1 else str(next(iter(r['normal_hits_histogram'])))
lines=['# Monstro #2 — bateria nos dois sentidos — 01/11/2026','','**Resultado:** preset criado e salvo; 110.000 tentativas individuais e 130.000 sequências acumuladas executadas, sem falhas ou divergências. Metade de cada conjunto pertence ao novo monstro, metade ao Monstro #1 de referência. Nenhum atributo foi ajustado depois da bateria.','','## Ficha e escopo','','Monstro #2 — Distância: HP40, MP8, INI9, ATQ F24/ATQ D24, DEF F32/DEF D50, MAG25/DEF M28, INT15/VIG20, CRI3%, EVA5%, multiplicador físico2×. Seu único ataque permitido é básico físico à distância (ATQ D contra DEF D), sem contato ou magias. A restrição é canônica pelo tipo `enemy_ranged`, preservada ao salvar/copiar/carregar e aplicada na UI/modelo/calculadora.','','Aliados com equipamentos iniciais: #1 espada/Bronze (ATQ F33/DEF F55/DEF D50/HP40/EVA5%/CRI10%/2×); #2 arco/traje inicial (ATQ D30/DEF F35/DEF D40/HP36/EVA12%/CRI19%/1,6×); mago cajado/veste iniciais (ATQ F14/MAG40/DEF M40/DEF F18/DEF D18/HP30/MP24/EVA3%/CRI3%/1,5×).','','## Método','','- Cinco sementes:421/733/112/2026/31415, reiniciadas por caso; 5.000 tentativas em cada uma das22 combinações. Sorteios iguais permitem comparar condições, sem tratar repetições entre casos como dados estatisticamente independentes.','- Cada monstro ataca os três aliados com seu padrão: Monstro #1 em contato; Monstro #2 exclusivamente à distância. Os três atacam de volta com ataque básico próprio (espada, arco, cajado físico).','- Resultados separados do mago: magia de dano já existente (potência1,5/7MP, sem crítico ou esquiva) e quatro aflições já existentes (4MP/EVA antes de resistência). Não foram criadas magias. #1/#2 não lançaram magias; novo monstro também não.','- Variação física/mágica ±10%. Médias de dano incluem esquivas e críticos quando permitidos. Lotes individuais restauram HP/MP por amostra.','- Sequências acumuladas começam com HP/MP cheios e terminam no primeiro 0HP. Sem cura, buffs, ações de resposta, ATB ou efeitos contínuos. Há diagnóstico só de normais (sem crítico/EVA) e mistura real; a magia de dano só requer a condição real, pois já ignora ambos. MP é acumulado no observador e foi suficiente em todas as sequências.','- Estados/hashes dos buffers são registrados; passos usados são preservados e auditados por fórmula independente em Python. Excedente não usado do último buffer é contabilizado. INI9 está preservada, mas não é usada temporalmente nesta ferramenta.','','## Novo monstro atacando os três','','Cada linha:5.000 ataques. Acertos normais para cair vêm da condição sem crítico/esquiva; tentativas médias incluem ambos.','','| Alvo | Normal | Crítico | Dano médio/tentativa | Esquivas | Críticos | Normais para cair (observados) | Tentativas médias até cair |','| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
for aid in ['ally_1','ally_2','ally_3']:
    r=get('m2-incoming-'+aid)
    lines.append(f"| {r['ally']} | {bounds(r['normal_bounds'])} | {bounds(r['critical_bounds'])} | {fmt(r['mean_damage'])} | {r['evasion_count']} | {r['critical_count']} | {normal_hits(r)} | {fmt(r['mean_attempts_to_zero'])} |")
lines+=['','## Os três atacando o novo monstro — físico básico','','Cada linha:5.000 ataques, sem MP; HP40 do inimigo.','','| Atacante | Modalidade | Normal | Crítico | Dano médio/tentativa | Esquivas do monstro | Críticos | Normais para vencer (observados) | Tentativas médias para vencer |','| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
for aid in ['ally_1','ally_2','ally_3']:
    r=get('m2-physical-'+aid)
    lines.append(f"| {r['ally']} | {'Distância' if r['mode']=='ranged' else 'Contato'} | {bounds(r['normal_bounds'])} | {bounds(r['critical_bounds'])} | {fmt(r['mean_damage'])} | {r['evasion_count']} | {r['critical_count']} | {normal_hits(r)} | {fmt(r['mean_attempts_to_zero'])} |")
lines+=['','Os intervalos de dano são limites da fórmula. As contagens de acertos normais são as observadas nos ensaios: para o cajado físico, teoricamente também é possível vencer em8 normais, com probabilidade aproximada0,00054%, mas isso não apareceu nas5.000 sequências (observado9–10).','','## Magia e aflições do mago — separadas do cajado físico','']
r=get('m2-mage-magic_skill')
lines.append(f"Magia de dano: normal **{bounds(r['normal_bounds'])}**, média **{fmt(r['mean_damage'])}**, sem crítico/esquiva. O inimigo caiu sempre em **dois acertos**, gastando **14MP** por sequência (7MP por uso, MP inicial24). O mago não executa simultaneamente cajado e magia: são cenários separados.")
lines+=['','| Aflição | Resistência | Aplicou | Resistiu | Esquivou | Aplicação observada | Teórica incluindo EVA |','| --- | --- | ---: | ---: | ---: | ---: | ---: |']
names=dict(poison='Veneno',slow='Lentidão',confusion='Confusão',fear='Medo')
for action,name in names.items():
    r=get('m2-mage-'+action)
    lines.append(f"| {name} | DEF M28 + {'VIG20' if action in ['poison','slow'] else 'INT15'} | {r['applied_count']} | {r['resisted_count']} | {r['evasion_count']} | {fmt(r['applied_percent'])}% | {fmt(r['chance_total'])}% |")
lines+=['','## Comparação direta com Monstro #1','','Monstro #1 ataca por contato; Monstro #2 ataca à distância. A diferença recebida pelos aliados reflete a modalidade/defesa usada, além de qualquer número da ficha.','','| Caso | Média de dano #1 → #2 | Variação da média | Tentativas médias até 0HP #1 → #2 |','| --- | ---: | ---: | ---: |']
for suffix in ['incoming-ally_1','incoming-ally_2','incoming-ally_3','physical-ally_1','physical-ally_2','physical-ally_3','mage-magic_skill']:
    a=get('m1-'+suffix);b=get('m2-'+suffix)
    label=('Inimigo → '+b['ally']) if not b['outgoing'] else (b['ally']+' → inimigo'+(' (magia)' if b['action_id']=='magic_skill' else ' (físico)'))
    variation=(b['mean_damage']/a['mean_damage']-1)*100
    lines.append(f"| {label} | {fmt(a['mean_damage'])} → {fmt(b['mean_damage'])} | {fmt(variation)}% | {fmt(a['mean_attempts_to_zero'])} → {fmt(b['mean_attempts_to_zero'])} |")
lines+=['','## Interpretação','','1. **A fraqueza a contato aparece.** A DEF F32 e HP40 facilitam a espada do primeiro aliado. A EVA5% reduz alguns acertos, mas não elimina essa vulnerabilidade.','2. **A defesa contra o arco funciona.** DEF D50 reduz o dano recebido em relação à DEF D40 de Monstro #1. O HP40 compensa parte dessa proteção; a média para vencê-lo aumenta apenas de3,69 para3,83 tentativas. É mais resistente ao arco por tentativa, com ganho modesto de sobrevivência total.','3. **O traje do segundo aliado é valorizado.** Ele sofre menos dano do novo monstro à distância do que do contato de Monstro #1. O primeiro aliado ainda tem a maior resistência total pela combinação HP/defesas.','4. **O mago continua frágil fisicamente.** Recebe os mesmos danos dos dois inimigos porque suas DEF F/DEF D são iguais e os ataques têm ambos24. O novo inimigo mantém a possibilidade rara de derrubá-lo num crítico de30.','5. **O cajado físico é uma alternativa fraca de ataque.** A DEF F menor melhora seu dano, mas a magia continua resolvendo o alvo em duas ações com custo14MP. A comparação de ritmo precisa incluir ATB e recursos antes de concluir qual estratégia é melhor em uma luta completa.','6. **A resistência mágica não mudou.** DEF M28/INT15/VIG20 iguais mantêm a chance condicional de aflição. A EVA5% em vez de3% reduz a aplicação total das quatro magias; a magia de dano atual ignora EVA, portanto mantém o dano por acerto.','7. **Mesmo patamar é intenção de design, ainda sem validação temporal.** INI9 contra7 pode aumentar a frequência de ações na batalha integrada. Esta bateria mede dano e tentativas, não tempo, vitória em duelos, respostas do grupo, rotina de alvos ou custos de cura. Não afirmar equilíbrio definitivo com base só nesses lotes.','','**Recomendação:** manter a ficha como ponto experimental para avaliar o papel desejado. Se a intenção for obter uma diferença de sobrevivência contra o arco mais pronunciada, reavaliar HP/DEF D; o aumento atual de3,69 para3,83 tentativas é pequeno. Nada foi ajustado automaticamente. Validar a INI no laboratório de batalha antes de fechar o patamar de dificuldade.','','## Validação e reprodução','',f"Godot: {execution['checks']} verificações, zero falhas. Auditoria Python: {checks}, zero divergências. Biblioteca pessoal preservada integralmente pelo hash/conteúdo; quatro presets anteriores preservados no cadastro. Históricos anteriores não recalculados.",'','```sh','/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-enemy02-battery.log --path . --script res://artifacts/monstro02-bateria-2026-11-01/executar.gd','python3 artifacts/monstro02-bateria-2026-11-01/analisar.py --compact','```','','`execucao.json` registra os presets, casos e sementes. JSONs volumosos podem ser compactados em `.json.gz` após a auditoria; o analisador lê ambos os formatos. Reexecutar o Godot gera JSONs novos; a confirmação usa as condições congeladas para a auditoria. Não foram introduzidas ações novas de magia, efeitos contínuos, níveis, encontros ou alterações no combate integrado.']
(HERE/'analise.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='rows'}))
for r in summary:
    if r['enemy']=='Monstro #2 — Distância':
        print(r['case_id'],r.get('normal_bounds'),r.get('critical_bounds'),r.get('mean_damage'),r.get('mean_attempts_to_zero'),r.get('normal_hits_histogram'),r.get('applied_percent'))
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--compact',action='store_true');args=parser.parse_args()
if args.compact:
    for row in execution['shot_rows']+execution['survival_rows']:
        path=HERE/row['report']
        if path.exists():
            raw=path.read_bytes();compressed=gzip.compress(raw,compresslevel=6,mtime=0)
            check(gzip.decompress(compressed)==raw,'Lossless compression')
            Path(str(path)+'.gz').write_bytes(compressed);path.unlink()
    print('Relatórios volumosos compactados sem perda; manifesto e análises permanecem JSON/Markdown.')
