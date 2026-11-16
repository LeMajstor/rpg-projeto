# Combate da exploração com a referência compartilhada

**D158 — representação individual:** o mapa lê cada participante do mesmo preset compartilhado, com seu perfil real de movimento e ficha de referência.18 representantes nos seis encontros; qualquer membro inicia a batalha completa, vitória/fuga bem-sucedida remove o grupo inteiro. Nenhuma duplicação de fórmulas/ações/aflições. Ver [INIMIGOS_INDIVIDUAIS.md](INIMIGOS_INDIVIDUAIS.md).

**D157 — distribuição atual:** mesmos seis encontros e referências de combate agora distribuídos em dois andares, três por piso. O mapa da dungeon foi refeito com patrulhas territoriais e paredes irregulares; escadas/combates preservam recursos e estados. Dados e regras de batalha continuam comuns aos três ambientes. Ver [DUNGEON_DOIS_ANDARES.md](DUNGEON_DOIS_ANDARES.md).

**D149 — autorizado e implementado em 15/11/2026.** A exploração passa a usar os mesmos dados e regras do cenário atual do laboratório de combate. Completa a sequência solicitada em D148; não reabre atributos, custos, fórmulas ou definições das aflições.

## Resultado jogável

Os três aliados aprovados — espada, arco e mago — são os mesmos na fila, no menu, no HUD e no combate. O quarto integrante provisório anterior não recebe uma ficha inventada; o sistema continua aceitando até quatro integrantes. As posições de batalha dos três aliados são os três primeiros slots de cada formação existente. Liderança continua exclusiva do menu e não muda a ordem dos slots do combate.

Os seis encontros da dungeon conservam identidade, quantidade de inimigos, cenário, posições iniciais, rotas, perfis ponderados de alvo e fuga; M2 continua impedindo fuga. Os quatro tipos de movimento reutilizam os dois monstros aprovados. A associação abaixo é uma **configuração técnica de teste**, em dados, sem criar espécies ou balanceamento definitivo:

| Movimento existente | Ficha e repertório |
| --- | --- |
| Pesado / estático | Monstro #1: básico e quatro aflições, mesmos pesos experimentais do laboratório |
| Ágil / voador | Monstro #2: somente básico físico à distância |

Movimento não define INI, atributos ou ataque: um Monstro #2 voador continua atacando à distância. O Mago possui magia ofensiva de 7 MP e quatro aflições de 4 MP; aliados físicos mantêm seus básicos. As ondas e técnicas antigas não são concedidas aos participantes atuais. M4 conserva a formação superior, com o repertório compartilhado; seu ID técnico histórico `exploration_seeded_fullscreen` permanece para preservar referências.

Fórmulas, equipamentos iniciais, esquiva, crítico, INT/VIG, aplicação e efeitos de Veneno/Lentidão/Confusão/Medo, exclusividade e cura seguem D124 e D127–D148. ATB, rotas e Veneno congelam durante execução das ações e pausa manual; Wait pausa durante seleção de comandos, Active permite progressão. Battle Speed mantém a proporção do Veneno.

## Recursos e continuidade

**D155 — implementado em 15/11/2026:** fuga bem-sucedida remove o encontro visível do mapa, com mesma persistência na sessão que a vitória; não permite reencontro na mesma sessão. Início por contato com líder e perseguição descritos em [PERSEGUICAO_EXPLORACAO.md](PERSEGUICAO_EXPLORACAO.md). Recursos, aflições e regras compartilhadas permanecem iguais.

- **Reiniciar teste:** cria nova sessão, HP/MP iniciais, três Remédios, áreas/horário/flags iniciais.
- **Encontros e viagens:** preservam HP/MP, incapacitação, equipamentos carregados e estoque restante; sem recuperação automática.
- **Vitória/fuga:** limpam aflições e retornam ao mesmo ponto da mesma área, conservando fila/liderança e estados das áreas. Vitória ou fuga bem-sucedida removem somente o encontro encerrado. Fuga falha mantém a batalha.
- **Derrota:** Game Over existente; limpa aflições, sem retorno de grupo curado ao mapa.

Remédio é o único consumível disponível nos encontros atuais. Itens anteriores permanecem nas referências históricas. Nenhuma magia de cura ou ação jogável de reviver foi adicionada. O mundo aberto continua sem monstros comuns; as batalhas continuam nos seis encontros da dungeon.

## Arquitetura e fontes

`ExplorationTest._new_session` monta as definições por `DamageV1Bridge.exploration_definitions`. Essa função usa a mesma montagem do laboratório e reaproveita suas definições completas de aliados, monstros, repertórios e itens. `data/exploration_combat.json` contém somente IDs de presets e associação de movimentos às referências. Não duplica atributos, equipamentos, ações ou regras.

Fontes comuns: `damage_reference_profiles.json` / `combat_reference.gd`, `damage_lab.json`, `battle_damage_v1.json`, `damage_equipment.gd`, `damage_calculator.gd`, `affliction_rules.gd` e o mesmo `BattleModel`. A UI recebe a instância existente por `configure_encounter`, sem iniciar outro combate ou restaurar o grupo.

`ExplorationSession` continua recebendo definições por injeção. Fixtures históricas podem fornecer o catálogo antigo para testar seus percursos e ações anteriores; isso não representa o fluxo da cena principal. No laboratório independente, as quinze demonstrações históricas continuam acessíveis como Legado. Experimentos da calculadora, biblioteca pessoal e preparação local de equipamentos não alteram automaticamente a referência aprovada nem outras sessões.

## Validação

**71 suítes headless: 351.952 verificações, zero falhas.** Inclui 838 verificações novas de paridade/continuidade e 22 de interface integrada. Comparações abrangem os seis encontros, fichas/equipamentos/repertórios, resultados exatos de básicos/magia/quatro aflições contra o laboratório com a mesma semente, consumo/impacto, Veneno e Remédio reais, estoque entre lutas, incapacitação, liderança, trilha, horário, flags, vitória/fuga/derrota e reinício. Regressões de áreas, câmera, fila, movimento e laboratórios preservadas.

Teste gráfico Compatibility: **26 verificações, zero falhas**, quatro capturas inspecionadas: equipe/menu, aflições no encontro, alvo do Remédio e retorno ao mapa. A bateria não substitui avaliação de ritmo e balanceamento pelo diretor criativo.

```sh
godot --headless --path . --script res://tests/exploration_combat_parity_tests.gd
godot --headless --path . --script res://tests/exploration_combat_parity_ui_smoke.gd
```

Relatório completo, executor e logs em `artifacts/exploration-shared-combat-2026-11-15/`; imagens em `visual/`.
