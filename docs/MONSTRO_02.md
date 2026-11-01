# Monstro #2 — Distância, preset do laboratório

**Data:** 01/11/2026. **Status:** P16 adotada, criada e cadastrada por D122 após autorização do usuário. Preset pessoal **Monstro #2 — Distância**; receita em `data/damage_lab_enemy_02.json`. Valores experimentais; mesmo patamar geral de Monstro #1 é a meta, sem curva de níveis/XP ou balanceamento temporal definitivo.

## Direção confirmada — D120/D121/D122

Novo inimigo mais ágil, com EVA ligeiramente maior e proteção contra ataques físicos à distância. Ataque exclusivamente físico à distância; sem contato ou lançamento de magias. HP e DEF F menores compensam as vantagens propostas. Sem espécie/identidade narrativa, equipamento de monstro, encontro novo ou migração ao combate integrado.

A proposta inicial de maior força (HP60/ATQ27) foi descartada. A cópia de atributos de Monstro #1 também foi descartada. D122 adotou a ficha diferenciada abaixo para testes.

## Ficha adotada — atributos diretos

| Atributo | Monstro #1 | Monstro #2 — Distância |
| --- | ---: | ---: |
| HP | 45 | 40 |
| MP | 8 | 8 |
| INI | 7 | 9 |
| ATQ F | 24 | 24 (sem uso ofensivo) |
| ATQ D | 24 | 24 |
| DEF F | 40 | 32 |
| DEF D | 40 | 50 |
| MAG | 25 | 25 (sem uso ofensivo) |
| DEF M | 28 | 28 |
| INT | 15 | 15 |
| VIG | 20 | 20 |
| CRI | 3% | 3% |
| EVA | 3% | 5% |
| Multiplicador crítico físico | 2× | 2× |

Todos os atributos são diretos, sem bônus de equipamento. MP não é consumido pelo básico. ATQ F/MAG na ficha não concedem ações. DEF M/INT/VIG continuam contribuindo para resistência às magias e aflições recebidas do mago. EVA maior evita ações elegíveis; DEF D reduz dano de disparos que acertam.

## Modalidade exclusiva e persistência

O tipo canônico `enemy_ranged` em `data/damage_lab.json` tem `offensive_policy` com somente a ação `basic` e modalidade `ranged`. `damage_action_policy.gd` consulta essa política pelo tipo, sem confiar em metadados editados de uma cópia. Modelo e calculadora recusam contato, técnica física e magias como ações desse atacante. Padrão `weapon` resolve para distância nesse tipo; o monstro não precisa de arma.

Carregar/trocar lados para colocá-lo como atacante ajusta uma ação incompatível para básico de distância, sem consumir RNG ou modificar histórico. Interface mostra distância fixa e desabilita ações indisponíveis. Quando ele é alvo, a restrição não afeta o repertório do aliado atacante. Tipos legados conservam os overrides genéricos do laboratório; nenhum novo sistema de acesso a magia dos aliados foi introduzido.

Biblioteca pessoal reaberta com cinco presets. Cadastro explícito uma vez, com backup, gravação atômica e preservação integral dos quatro registros anteriores. Não há importação/reinstalação automática ao iniciar. Receita em `data/damage_lab_enemy_02.json`; instalador explícito em `artifacts/damage-lab-enemy02/instalar.py`, com argumentos `--library` e `--backup-dir`.

## Uso

Abra `Executar laboratorio de danos.command`, carregue **Monstro #2 — Distância** no seletor do inimigo e um dos aliados no outro seletor. Use **Trocar lados** para o monstro atacar: a ação passa para básico à distância e usa ATQ D/DEF D. Invertendo novamente, compare espada, arco e cajado físico; no mago, magias de dano/aflição já disponíveis podem ser testadas separadamente. Aliados #1/#2 normalmente não usam magia (D116).

## Bateria nos dois sentidos

**110 mil tentativas e 130 mil sequências acumuladas**, metade para Monstro #2 e metade para Monstro #1 de referência. Cinco sementes, 5.000 tentativas por caso, mesmos aliados/equipamentos/sorteios. Dano individual inclui crítico/esquiva; sobrevivência acumula HP e MP localmente até a incapacitação, sem cura, buffs, ATB ou ações de resposta. Quatro aflições recebidas do mago são testes de aplicação, sem duração/efeitos contínuos.

Principais resultados do novo inimigo:

- Recebido por #1: normal7–9/crítico14–17, média7,56, média5,92 tentativas até cair.
- Recebido por #2: normal8–10/crítico16–20, média8,16, média4,83 tentativas até cair.
- Recebido pelo mago: normal12–15/crítico25–30, média13,74, média2,98 tentativas até cair.
- Espada contra ele: normal15–18/crítico30–37, média17,43, vitória em2,96 tentativas médias.
- Arco contra ele: normal10–12/crítico16–20, média11,86, vitória em3,83 tentativas médias.
- Cajado físico contra ele: normal4–5/crítico6–7, média4,07, vitória em10,26 tentativas médias.
- Magia de dano do mago: normal32–39, média35,27; sempre dois usos/14MP.
- Aplicações do mago: Veneno/Lentidão42,88%; Confusão/Medo45,78%, incluindo EVA.

**Interpretação:** fraqueza a contato e proteção contra o arco aparecem. HP40 limita o ganho total de sobrevivência ao arco:3,69 tentativas em Monstro #1 contra3,83 no novo; a espada cai de3,29 para2,96. A modalidade de distância valoriza o couro do segundo aliado. O mago conserva fragilidade física, e DEF M28/INT15/VIG20 iguais preservam resistência mágica condicional; EVA5% reduz a aplicação total de aflições. A magia de dano atual ignora EVA e mantém o dano. INI9 está registrada, mas o laboratório de danos não mede ATB; a agilidade e o mesmo patamar ainda exigem validação temporal.

[Análise detalhada, dados e reprodução](../artifacts/monstro02-bateria-2026-11-01/analise.md). Nenhum número foi ajustado depois dos testes.

## Validação

23 suítes headless, **34.675 verificações, zero falhas**. Teste gráfico Compatibility:19 verificações, duas capturas inspecionadas. Cobertura do tipo, ação canônica, rejeição de contato/magia, alvo sem restrição, cópia/recarga, inversão, RNG/histórico, dados/exportação e regressões. Bateria Godot:1.422.397 verificações; auditoria Python independente:1.996.484, zero divergências. Relatórios volumosos compactados sem perda em JSON gzip; manifesto e análises em JSON/Markdown.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-enemy02-test.log --path . --script res://tests/damage_enemy_02_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-enemy02-ui.log --path . --script res://tests/damage_enemy_02_ui_smoke.gd
```

Evidências em `artifacts/damage-lab-enemy02/`; estudo completo em `artifacts/monstro02-bateria-2026-11-01/`. Fórmulas, presets anteriores, combate integrado e relatórios históricos preservados.
