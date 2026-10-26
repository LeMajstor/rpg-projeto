# Combate atual — comportamento por semente

## Escopo confirmado e implementado

Esta versão implementa D44–D46 e a autorização posterior de aplicar o conjunto no laboratório independente e em todos os encontros da exploração. Dez opções anteriores são **legadas**, inclusive F e as quatro primeiras versões `exploration_*`. Permanecem para regressão/consulta manual, sem referências pelos encontros jogáveis.

- Terrestres seguem sua curva autorada e sorteiam continuar ou inverter o sentido. Para inverter, freiam, permanecem parados e aceleram no novo sentido.
- Quantidade/duração das pausas e duração/velocidade dos trechos variam por comportamento e semente. Voadores também têm paradas em que ficam pairando, mantendo somente a flutuação visual.
- O preset fornece geometria, formação, composição, cenário e regras do encontro. Pesos, faixas e sorteios de movimento pertencem ao comportamento do tipo; não recebem override pelo preset.
- Inimigos comuns mantêm atenção em algum aliado válido, sem obrigação de trocar sempre para o mais próximo. Durante o ataque, olham para o alvo efetivo. A orientação é independente da rota e da escolha ponderada de ações/alvos.
- As posições aliadas variam entre presets e permanecem fixas durante cada batalha. Animações retornam ao mesmo repouso. Rotas foram adaptadas aos espaços livres dessas formações.
- ATB, Wait/Active, perfis de alvo, HP/MP, comandos, fuga e apresentações melee/tela inteira permanecem. Repouso de comportamento não pausa ATB; Wait/pausa manual e ações preservam estado exato.

Não há novas rotas livres, perseguição, navegação procedural, arte definitiva ou inimigos comuns no mapa-múndi. O movimento dos monstros antes do combate não foi alterado.

## Opções atuais e integração

| Opção / ID | Formação e uso |
| --- | --- |
| Atual · comportamento por semente / `lab_seeded` | Padrão do laboratório separado; grupo mais espaçado, três móveis e um estático. |
| Atual · dungeon aberta / `exploration_seeded_open` | M1/M5: formação aberta, pesado, voador e estático. |
| Atual · cantos / sem fuga / `exploration_seeded_corners` | M2: aliados nos quatro cantos, ágil/pesado/estático no campo central; fuga continua bloqueada. |
| Atual · lados opostos / `exploration_seeded_sides` | M3/M6: aliados dos dois lados, ágil e voador com caminho adaptado, mais um estático. |
| Atual · linha superior / `exploration_seeded_fullscreen` | M4: aliados distribuídos na parte superior; pesado e dois estáticos, com as ações/exceções de tela inteira anteriores. |

`data/dungeon.json` referencia somente os quatro presets atuais. Os seis IDs de encontro, posições/patrulhas no mapa, quantidade de participantes, atributos, perfis de alvo, habilidades, cenário e permissão de fuga permanecem. As novas posições de repouso são uma escolha técnica de teste autorizada pela variação de formações; não definem mapas ou formações definitivas da aventura.

## Executar e testar

1. Reabra `Executar laboratorio.command`. Ele inicia automaticamente em **Atual · comportamento por semente**.
2. Use **Active** e deixe **Pausa desligada**. Observe os terrestres continuando/recuando, as paradas variáveis e o olhar voltado ao grupo.
3. Abra **F3**: semente, comportamento, etapa, velocidade, sentido atual/planejado, pausa restante, contadores, último sorteio e foco visual. Valores de inversão incluem decisões já planejadas que ainda aguardam a pausa.
4. Observe o voador: em `pause`, sua coordenada lógica fica parada e a flutuação continua. ATB segue carregando. **Espaço** congela tudo; **Passo +1/60 s** avança dois ticks configurados de 1/120 s, respeitando Wait.
5. Mantenha a velocidade global em **1×** ao comparar tipos. **0,25×** ajuda a inspecionar frenagem, pausa e retomada. O slider global escala também ATB e ações.
6. Para comparar sorteios, escolha uma semente, por exemplo **421**, e clique **Novo teste**. Repita com **733**. Voltar à mesma semente/configuração e repetir os comandos no mesmo tempo reproduz a simulação. Editar o campo só é aplicado ao iniciar novo teste/próxima luta.
7. Selecione outras opções **Atual · … → Novo teste** para comparar formações. Os modelos anteriores aparecem como **Legado · …**.
8. Use Atacar/Onda para testar aproximação/impacto/retorno e retomada da pausa/rota. Em Wait, selecionar um aliado pronto congela as decisões; cancelar retoma. Uma ação já iniciada pode concluir ao mudar para Wait, conforme a política anterior.
9. Na exploração, reabra `Executar exploracao.command`, entre na dungeon e interaja com qualquer M1–M6 usando **E**. A nova versão é automática, sem forçar preset. Vitória/fuga retornam ao mapa com recursos preservados; M2 bloqueia fuga. **Reiniciar teste** restaura os encontros.

Inicialização direta do laboratório:

```sh
godot --path . --scene res://scenes/combat_lab.tscn -- --preset=lab_seeded
```

A exploração mantém a semente experimental em `settings.seed` de `data/lab.json`, atualmente 421. Não foi acrescentado sorteio automático de semente ou novo painel no mapa. As posições iniciais nunca são sorteadas.

## Dados e escolhas técnicas experimentais

`movement_behaviors` em `data/lab.json` fornece quatro comportamentos (`heavy`, `agile`, `flying`, `static`). Novos tipos referenciam `movement_behavior`, com `facing_policy: "focus"`. Fichas de atributos/ações foram copiadas dos tipos anteriores; não houve balanceamento de HP/MP/INI/dano/custos.

| Campo do comportamento | Uso |
| --- | --- |
| `kind`, `speed` | Terrestre/voador/estático e velocidade de referência. Estático tem velocidade zero. |
| `speed_scale: [min,max]` | Faixa sorteada para velocidade do trecho. |
| `travel_seconds: [min,max]` | Duração de referência sorteada para calcular a distância do próximo trecho. |
| `pause_chance` | Chance de inserir repouso entre trechos quando não há inversão. |
| `pause_seconds: [min,max]` | Duração sorteada do repouso. Inversão sempre exige uma pausa. |
| `initial_pause: [min,max]` | Espera inicial sorteada, evitando sincronização do grupo. |
| `reverse_chance` | Chance de trocar de sentido para terrestres, limitada pela geometria. Voadores percorrem a curva fechada sem inverter. |
| `acceleration`, `deceleration` | Durações das transições suaves de velocidade, comprimidas em trechos muito curtos. |
| `presentation` | Inclinação e flutuação puramente visuais. |

Exemplos de faixas adotadas para testar: velocidade de referência 32/72/90 para pesado/ágil/voador; repousos 0,9–2,8 s, 0,4–1,5 s e 0,7–2,3 s, respectivamente. Esses números e as probabilidades no JSON são **experimentais**, não balanceamento definitivo.

O encontro pode configurar a curva, pontos/resolução, elipse e sua geometria. Para os tipos novos, campos de velocidade, perfil ou política de comportamento na entrada do preset não substituem `movement_behaviors`. Escolher um tipo naturalmente escolhe seu comportamento; o preset não controla os resultados dos sorteios.

Nos extremos de uma curva aberta, o terrestre precisa retornar para permanecer no caminho. Essa restrição geométrica força inversão com pausa, sem teleporte. Fora dos extremos, a decisão é sorteada. A quantidade de paradas efetivas varia porque trechos podem continuar sem repouso; a mudança de velocidade continua suave mesmo nesses casos.

## Estado, determinismo e orientação

`route_behavior.gd` planeja apenas o próximo conjunto de fases, em vez de repetir um cronograma inteiro. Usa a integral de velocidade suavizada de `route_rhythm.gd`, mantendo distância independente da quantidade de frames. O avanço é por distância na polilinha de `route_motion.gd`, nunca por desvio de alvo/pathfinding.

Cada participante possui um fluxo de aleatoriedade derivado da semente da batalha e do seu ID, sem usar ID/cenário do preset ou o RNG de ações/alvos. O estado guarda semente, estado inteiro do RNG, fase/tempo, distância, velocidade, sentido atual/planejado, contadores e as últimas 32 decisões. Não há objeto RNG compartilhado dentro do snapshot. Sortear para um inimigo não altera os demais.

O modelo congela a rota inteira durante a ação do participante, incluindo decisões já sorteadas e pausa restante. O próximo tick permitido retoma exatamente o snapshot. Wait e pausa manual também impedem consumir aleatoriedade. Outros participantes continuam sob a política de tempo já existente.

Políticas visuais disponíveis, sem criar conteúdo especial:

- `focus`: inicia olhando para um adversário vivo próximo e conserva esse foco enquanto válido, atualizando a direção conforme se move. Ao perder o foco por incapacitação/ausência, escolhe outro válido. Não usa nem altera os pesos da IA de combate.
- `travel`: exceção configurável para orientar repouso/movimento pela rota.
- `fixed`: exceção configurável para conservar a direção de repouso.

Durante qualquer ação inimiga atual, a orientação acompanha o alvo individual. Para ações sem alvo individual, usa o adversário vivo mais próximo da posição visual como referência; isso não restringe os atingidos. Na volta ao repouso, `focus` retoma seu foco válido. Políticas são configuráveis no tipo e individualmente na entrada do encontro. Valores antigos sem essa política conservam o comportamento legado.

Flutuação do voador usa relógio visual separado da posição lógica. Durante a ação, cede suavemente à apresentação para chegar ao centro/contato exatos e retorna à mesma fase congelada. Áreas continuam usando apenas posições lógicas. Rótulos foram centralizados para melhorar leitura em formações com participantes dos dois lados.

## Arquivos e validação

- Novo `scripts/combat/route_behavior.gd`: comportamento, RNG por participante, pausas e inversões.
- `route_motion.gd`: geometria aberta/fechada e delegação opcional ao comportamento, preservando API antiga da exploração.
- `battle_model.gd`: resolução por tipo, injeção da semente e atenção visual/ação, sem reimplementar comandos ou ATB.
- `combat_lab.gd` e `battlefield.gd`: depuração, olhar, flutuação e rótulos de formações variadas.
- `data/lab.json` e `data/dungeon.json`: nova versão, comportamentos, cinco formações e seis referências atuais.
- `tests/seeded_behavior_tests.gd` e `seeded_behavior_ui_smoke.gd`: regras e controles novos.
- `tests/exploration_rhythm_tests.gd`, `internal_areas_tests.gd`, `internal_areas_ui_smoke.gd`, `world_map_ui_smoke.gd`: expectativas do catálogo atual. Não exigem mais as posições aliadas anteriores, pois a variação foi autorizada; atributos, composição, recursos e regras permanecem verificados.
- `tests/fixtures/pre_behavior_combat.json`: registro das dez opções anteriores, comprovando que ficaram intactas como legados.

```sh
godot --headless --path . --script res://tests/seeded_behavior_tests.gd
godot --headless --path . --script res://tests/seeded_behavior_ui_smoke.gd
godot --headless --path . --script res://tests/exploration_rhythm_tests.gd
```

Capturas opcionais:

```sh
godot --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/seeded_behavior_ui_smoke.gd -- --visual-captures=res://artifacts/seeded-behavior
```

Resultados executados em [VALIDACAO.md](VALIDACAO.md). Semente/configuração permitem reproduzir testes na engine validada; não há novo sistema de replay/salvamento. Direção de arte e parâmetros definitivos permanecem abertos.
