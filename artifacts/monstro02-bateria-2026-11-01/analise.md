# Monstro #2 — bateria nos dois sentidos — 01/11/2026

**Resultado:** preset criado e salvo; 110.000 tentativas individuais e 130.000 sequências acumuladas executadas, sem falhas ou divergências. Metade de cada conjunto pertence ao novo monstro, metade ao Monstro #1 de referência. Nenhum atributo foi ajustado depois da bateria.

## Ficha e escopo

Monstro #2 — Distância: HP40, MP8, INI9, ATQ F24/ATQ D24, DEF F32/DEF D50, MAG25/DEF M28, INT15/VIG20, CRI3%, EVA5%, multiplicador físico2×. Seu único ataque permitido é básico físico à distância (ATQ D contra DEF D), sem contato ou magias. A restrição é canônica pelo tipo `enemy_ranged`, preservada ao salvar/copiar/carregar e aplicada na UI/modelo/calculadora.

Aliados com equipamentos iniciais: #1 espada/Bronze (ATQ F33/DEF F55/DEF D50/HP40/EVA5%/CRI10%/2×); #2 arco/traje inicial (ATQ D30/DEF F35/DEF D40/HP36/EVA12%/CRI19%/1,6×); mago cajado/veste iniciais (ATQ F14/MAG40/DEF M40/DEF F18/DEF D18/HP30/MP24/EVA3%/CRI3%/1,5×).

## Método

- Cinco sementes:421/733/112/2026/31415, reiniciadas por caso; 5.000 tentativas em cada uma das22 combinações. Sorteios iguais permitem comparar condições, sem tratar repetições entre casos como dados estatisticamente independentes.
- Cada monstro ataca os três aliados com seu padrão: Monstro #1 em contato; Monstro #2 exclusivamente à distância. Os três atacam de volta com ataque básico próprio (espada, arco, cajado físico).
- Resultados separados do mago: magia de dano já existente (potência1,5/7MP, sem crítico ou esquiva) e quatro aflições já existentes (4MP/EVA antes de resistência). Não foram criadas magias. #1/#2 não lançaram magias; novo monstro também não.
- Variação física/mágica ±10%. Médias de dano incluem esquivas e críticos quando permitidos. Lotes individuais restauram HP/MP por amostra.
- Sequências acumuladas começam com HP/MP cheios e terminam no primeiro 0HP. Sem cura, buffs, ações de resposta, ATB ou efeitos contínuos. Há diagnóstico só de normais (sem crítico/EVA) e mistura real; a magia de dano só requer a condição real, pois já ignora ambos. MP é acumulado no observador e foi suficiente em todas as sequências.
- Estados/hashes dos buffers são registrados; passos usados são preservados e auditados por fórmula independente em Python. Excedente não usado do último buffer é contabilizado. INI9 está preservada, mas não é usada temporalmente nesta ferramenta.

## Novo monstro atacando os três

Cada linha:5.000 ataques. Acertos normais para cair vêm da condição sem crítico/esquiva; tentativas médias incluem ambos.

| Alvo | Normal | Crítico | Dano médio/tentativa | Esquivas | Críticos | Normais para cair (observados) | Tentativas médias até cair |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Aliado #1 | 7–9 | 14–17 | 7,56 | 247 | 141 | 5–6 | 5,92 |
| Aliado #2 | 8–10 | 16–20 | 8,16 | 597 | 132 | 4–5 | 4,83 |
| Aliado #3 — Mago | 12–15 | 25–30 | 13,74 | 140 | 144 | 2–3 | 2,98 |

## Os três atacando o novo monstro — físico básico

Cada linha:5.000 ataques, sem MP; HP40 do inimigo.

| Atacante | Modalidade | Normal | Crítico | Dano médio/tentativa | Esquivas do monstro | Críticos | Normais para vencer (observados) | Tentativas médias para vencer |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Aliado #1 | Contato | 15–18 | 30–37 | 17,43 | 247 | 458 | 3 | 2,96 |
| Aliado #2 | Distância | 10–12 | 16–20 | 11,86 | 247 | 880 | 4 | 3,83 |
| Aliado #3 — Mago | Contato | 4–5 | 6–7 | 4,07 | 247 | 141 | 9–10 | 10,26 |

Os intervalos de dano são limites da fórmula. As contagens de acertos normais são as observadas nos ensaios: para o cajado físico, teoricamente também é possível vencer em8 normais, com probabilidade aproximada0,00054%, mas isso não apareceu nas5.000 sequências (observado9–10).

## Magia e aflições do mago — separadas do cajado físico

Magia de dano: normal **32–39**, média **35,27**, sem crítico/esquiva. O inimigo caiu sempre em **dois acertos**, gastando **14MP** por sequência (7MP por uso, MP inicial24). O mago não executa simultaneamente cajado e magia: são cenários separados.

| Aflição | Resistência | Aplicou | Resistiu | Esquivou | Aplicação observada | Teórica incluindo EVA |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Veneno | DEF M28 + VIG20 | 2144 | 2609 | 247 | 42,88% | 43,18% |
| Lentidão | DEF M28 + VIG20 | 2144 | 2609 | 247 | 42,88% | 43,18% |
| Confusão | DEF M28 + INT15 | 2289 | 2464 | 247 | 45,78% | 45,78% |
| Medo | DEF M28 + INT15 | 2289 | 2464 | 247 | 45,78% | 45,78% |

## Comparação direta com Monstro #1

Monstro #1 ataca por contato; Monstro #2 ataca à distância. A diferença recebida pelos aliados reflete a modalidade/defesa usada, além de qualquer número da ficha.

| Caso | Média de dano #1 → #2 | Variação da média | Tentativas médias até 0HP #1 → #2 |
| --- | ---: | ---: | ---: |
| Inimigo → Aliado #1 | 7,20 → 7,56 | 4,95% | 6,16 → 5,92 |
| Inimigo → Aliado #2 | 8,84 → 8,16 | -7,72% | 4,44 → 4,83 |
| Inimigo → Aliado #3 — Mago | 13,74 → 13,74 | 0,00% | 2,98 → 2,98 |
| Aliado #1 → inimigo (físico) | 15,90 → 17,43 | 9,65% | 3,29 → 2,96 |
| Aliado #2 → inimigo (físico) | 13,90 → 11,86 | -14,66% | 3,69 → 3,83 |
| Aliado #3 — Mago → inimigo (físico) | 3,62 → 4,07 | 12,43% | 12,82 → 10,26 |
| Aliado #3 — Mago → inimigo (magia) | 35,27 → 35,27 | 0,00% | 2,00 → 2,00 |

## Interpretação

1. **A fraqueza a contato aparece.** A DEF F32 e HP40 facilitam a espada do primeiro aliado. A EVA5% reduz alguns acertos, mas não elimina essa vulnerabilidade.
2. **A defesa contra o arco funciona.** DEF D50 reduz o dano recebido em relação à DEF D40 de Monstro #1. O HP40 compensa parte dessa proteção; a média para vencê-lo aumenta apenas de3,69 para3,83 tentativas. É mais resistente ao arco por tentativa, com ganho modesto de sobrevivência total.
3. **O traje do segundo aliado é valorizado.** Ele sofre menos dano do novo monstro à distância do que do contato de Monstro #1. O primeiro aliado ainda tem a maior resistência total pela combinação HP/defesas.
4. **O mago continua frágil fisicamente.** Recebe os mesmos danos dos dois inimigos porque suas DEF F/DEF D são iguais e os ataques têm ambos24. O novo inimigo mantém a possibilidade rara de derrubá-lo num crítico de30.
5. **O cajado físico é uma alternativa fraca de ataque.** A DEF F menor melhora seu dano, mas a magia continua resolvendo o alvo em duas ações com custo14MP. A comparação de ritmo precisa incluir ATB e recursos antes de concluir qual estratégia é melhor em uma luta completa.
6. **A resistência mágica não mudou.** DEF M28/INT15/VIG20 iguais mantêm a chance condicional de aflição. A EVA5% em vez de3% reduz a aplicação total das quatro magias; a magia de dano atual ignora EVA, portanto mantém o dano por acerto.
7. **Mesmo patamar é intenção de design, ainda sem validação temporal.** INI9 contra7 pode aumentar a frequência de ações na batalha integrada. Esta bateria mede dano e tentativas, não tempo, vitória em duelos, respostas do grupo, rotina de alvos ou custos de cura. Não afirmar equilíbrio definitivo com base só nesses lotes.

**Recomendação:** manter a ficha como ponto experimental para avaliar o papel desejado. Se a intenção for obter uma diferença de sobrevivência contra o arco mais pronunciada, reavaliar HP/DEF D; o aumento atual de3,69 para3,83 tentativas é pequeno. Nada foi ajustado automaticamente. Validar a INI no laboratório de batalha antes de fechar o patamar de dificuldade.

## Validação e reprodução

Godot: 1422397 verificações, zero falhas. Auditoria Python: 1996484, zero divergências. Biblioteca pessoal preservada integralmente pelo hash/conteúdo; quatro presets anteriores preservados no cadastro. Históricos anteriores não recalculados.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-enemy02-battery.log --path . --script res://artifacts/monstro02-bateria-2026-11-01/executar.gd
python3 artifacts/monstro02-bateria-2026-11-01/analisar.py --compact
```

`execucao.json` registra os presets, casos e sementes. JSONs volumosos podem ser compactados em `.json.gz` após a auditoria; o analisador lê ambos os formatos. Reexecutar o Godot gera JSONs novos; a confirmação usa as condições congeladas para a auditoria. Não foram introduzidas ações novas de magia, efeitos contínuos, níveis, encontros ou alterações no combate integrado.
