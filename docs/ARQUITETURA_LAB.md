# Arquitetura implementada — laboratório

**D159:** `encounter_perception.gd` usa `exploration_behavior.vision` e orientação do monstro para campos frontal/periférico; `encounter_motion.gd` atualiza `look_direction` somente no deslocamento real e guarda nas pausas. `vision_geometry.gd` cria contornos recortados apenas para F3, com sólidos próximos e cache local da vista por posição/olhar/configuração/revisão de obstáculos. Porta incrementa `obstacle_revision`; trocar área/sessão limpa cache. Detecção usa matemática/visão exatas, independente dos polígonos de depuração. Fixtures antigas sem `vision` preservam seu teste circular; catálogo jogável é todo direcional. Ver `VISAO_DIRECIONAL.md`.

**D158:** `encounter_roster.gd` expande `members` das áreas pelo elenco real dos presets atuais de `DamageV1Bridge`, mantendo `encounter_id` e `battle_actor_id`. `movement_behavior_data` vem do mesmo perfil de `lab.json`; `exploration_behavior` acrescenta apenas perseguição/sensores por tipo. Rotas usam a implementação comum de ritmos por semente, com fluxo próprio por representante. `encounter_perception.gd` testa círculo/cone estáticos e a sessão guarda `active_encounter_group_id` para remoção conjunta. A operação aditiva `RouteBehavior.relocate` reposiciona o progresso do ritmo ao retomar a patrulha; não altera execução de rotas na batalha. Ver `INIMIGOS_INDIVIDUAIS.md`.

**D157:** catálogo com seis áreas e dois pisos da dungeon. `patrol_territory.gd` fixa território pela rota; `wall_geometry.gd` fornece paredes convexas, volumes e visão no chão; `encounter_motion.gd` retoma segmento próximo sem origem obrigatória. Layouts em `dungeon.json`/`dungeon_upper.json`, transições reutilizadas, câmera e `BattleModel` compartilhado preservados. Fixtures de layouts históricos ficam restritas aos testes. Ver `DUNGEON_DOIS_ANDARES.md`.

**D155:** início de encontros atuais da exploração por contato automático do líder, com perseguição/percepção/retorno em módulos separados do combate e configuração central no catálogo de áreas. `ExplorationSession` conserva a mesma instância de `BattleModel`; a UI abre uma única cena ao mudar o estado. Fuga bem-sucedida remove o encontro da sessão. Matemática, aflições e rotas dentro da batalha não mudam. Ver `PERSEGUICAO_EXPLORACAO.md`.

**D149:** a cena principal da exploração passa por `DamageV1Bridge.exploration_definitions`, que reaproveita as definições completas do laboratório e adapta os quatro presets usados pelos seis encontros. `exploration_combat.json` associa movimentos a IDs das duas referências, sem copiar atributos ou ações. A sessão continua recebendo dados por injeção; fixtures históricas mantêm os catálogos antigos para regressão. Esta atualização supera o isolamento da exploração registrado em D126/D148 abaixo. Ver [COMBATE_EXPLORACAO_COMPARTILHADO.md](COMBATE_EXPLORACAO_COMPARTILHADO.md).

`GDD.md` é a fonte de regras; `DECISOES_TECNICAS.md` registra preenchimentos experimentais autorizados. `ARQUITETURA.md` permanece como proposta histórica anterior ao GDD consolidado.

**D126:** a UI independente acrescenta `data/battle_damage_v1.json` por `scripts/combat/damage_v1_bridge.gd`. O preset novo seleciona a calculadora/composição compartilhadas do laboratório de danos; o modelo temporal continua responsável por HP/MP, ATB e impacto. `scripts/ui/battle_preparation.gd` mantém equipamentos pendentes até o reinício. A exploração continua carregando apenas `data/lab.json`. Dados, limites e testes em [BATALHA_DANOS_V1.md](BATALHA_DANOS_V1.md).

**D147:** catálogo do Remédio e `item_ids` do preset em `battle_damage_v1.json`; ponte mescla definições, modelo separa disponibilidade/estoque por preset. Actor possui `affliction` como dicionário único, vazio por padrão. Item `cleanse` limpa esse estado no impacto, sem regravar naturais/HP/MP ou sortear; não há aplicação, modificadores ou ticks de aflição nesta etapa. UI lista os itens disponíveis pelo modelo, com teclado/mira/cancelamento existentes. Novo teste refaz estoque dos itens disponíveis; continuação preserva.

**D148:** `combat_reference.gd` lê as cinco fichas de `damage_reference_profiles.json` para ambos os laboratórios. `damage_v1_bridge.gd` monta o encontro por IDs e lê ações/equipamentos do catálogo comum; o arquivo de encontro não duplica fichas. `affliction_rules.gd` contém regras puras de INI, dano de Veneno e recuperação por INT; `BattleModel` administra estado/origem, clocks normalizados, exclusividade, cura, proteção dinâmica e limpeza por fim de batalha. Configurações para a migração posterior da exploração permanecem desacopladas do desenho/UI.

`affliction` contém `id`, `source_id`, `source_magic` e `elapsed` normalizado na referência Battle Speed 4. Naturais/equipamentos não são regravados: efeitos de INI/EVA são derivados do estado e cessam ao limpá-lo. RNG de recuperação e alvo confuso são separados dos quatro fluxos da calculadora e dos RNGs de rota. Confusão agenda ataque básico por participante pronto antes da seleção ordinária inimiga, sem fila de múltiplas ações. Mantém prioridade estável por ordem dos participantes como escolha técnica experimental do teste.

Na v0.2, a exploração compartilha `BattleModel` com esta cena através de `configure_encounter`, e recebe sinais de resultado. O núcleo e os presets não foram reimplementados. O laboratório é iniciado diretamente por sua cena/lançador; o projeto principal inicia `scenes/exploration_test.tscn`. Dependências e novos arquivos em [EXPLORACAO_V02.md](EXPLORACAO_V02.md).

```text
project.godot
scenes/combat_lab.tscn           entrada do laboratório
data/lab.json                    definições e parâmetros de teste
scripts/combat/battle_model.gd   estado e regras de batalha
scripts/combat/route_motion.gd   trajetórias e progresso
scripts/combat/attack_motion.gd  aproximação/impacto/retorno visual, separado da rota
scripts/combat/fullscreen_motion.gd  centro/execução/retorno conforme configuração individual
scripts/combat/target_policy.gd  pesos e sorteio controlável
scripts/ui/combat_lab.gd         comandos, painéis e relógio
scripts/ui/battlefield.gd        desenho e interação com o campo
tests/run_tests.gd               invariantes e simulações completas
tests/ui_smoke.gd                fluxos da interface
```

## Dados e estado

O JSON descreve fichas, habilidades, itens, perfis e presets. Presets referenciam tipos/perfis por ID e fornecem posições/rotas sem sorteio. O modelo copia fichas para criar estado mutável; não escreve HP/MP nas definições de conteúdo.

O modelo é a autoridade para recursos, alvos, prontidão e resultado. A interface solicita comandos, sem aplicar dano ou movimento diretamente. Ferramentas de depuração são a exceção explícita para estados de teste. `BattleModel` não depende de nós, desenho, cena ou teclado.

Cada combatente mantém `logical_position`, `visual_offset`, `route_state` e `facing`. Aliados recebem a coordenada lógica do slot. Movimento só atualiza inimigos vivos quando não há ação em execução e a seleção não pausa o tempo (D132). Animações alteram apenas o deslocamento visual. Ao finalizar, o modelo verifica que posição lógica e rota do ator permanecem idênticas ao início.

## Tempo e execução

A cena acumula tempo real multiplicado pela velocidade e chama o modelo em passos de 1/120 s. Pausa interrompe esses passos; avanço manual chama dois passos. Wait controla a pausa de seleção dentro do modelo. D132 pausa ATB, todas as rotas e `simulation_time` durante qualquer execução de ação, sem consumir esse tempo depois. A integração futura do Veneno usará esse mesmo tempo permitido, respeitando também a pausa manual da cena. Ações têm progresso próprio dentro dos passos recebidos, permitindo concluir animação iniciada ao mudar de Active para Wait.

Há uma execução por vez. Durante ela, todos conservam carga de ATB e estado completo de rota/RNG; a apresentação da ação avança pelo delta recebido, com efeito no impacto. Fora da execução, atores carregam ATB e movem-se conforme Wait/Active. O executor continua zerando sua barra ao concluir, e uma incapacitação pelo impacto continua eliminando prontidão normalmente. O modelo valida seleção/alvos, registra origem/rota, aplica efeito no impacto e retorna ao idle antes de zerar ATB e verificar resultado.

## IA e apresentação

O modelo seleciona ação acessível e filtra aliados vivos. `TargetPolicy` calcula pesos e sorteia com o RNG recebido, sem conhecer rotas ou cenas. Registros mantêm perfil, ação, probabilidades e escolha. Perfis não alteram navegação.

`RouteMotion` aceita o formato linear antigo e configurações opcionais de curva suave/elipse, amostradas deterministicamente. `AttackMotion` recebe origem/progresso/alvo e calcula apenas Δvisual; não recebe rotas nem recursos. O modelo congela o estado da rota do atacante, consulta o movimento visual, aplica o efeito na chegada e verifica retorno à origem. Presets A/B foram preservados e C demonstra as opções novas. Detalhes em [MOVIMENTO_E_MELEE.md](MOVIMENTO_E_MELEE.md).

`FullscreenMotion` é selecionado somente pela marca explícita de apresentação da habilidade e consulta a configuração efetiva por participante capturada pelo modelo. Pode mover ao centro comum do campo ou manter Δvisual zero. Alvos/área permanecem calculados pelas funções anteriores; alterações temporárias do participante não mudam uma execução já iniciada. Presets A/B/C permanecem iguais; D demonstra os casos. Ver [TELA_INTEIRA.md](TELA_INTEIRA.md).

O campo desenha formas, barras de HP e orientações. ATB aliado aparece nos cartões; ATB inimigo somente na depuração. Rotas e cruzes lógicas só aparecem com F3. Mira circular recebe o ID de um alvo central e projeta sua posição lógica/raio para o desenho; a mão acompanha a apresentação visual. `battle_hand.gd` é um desenho vetorial original compartilhado por cards, comandos e campo. O desenho é recortado para não cobrir o menu.

Testes de regras rodam sem renderização. Testes de UI instanciam a cena; o fluxo atual também recebe eventos reais de teclado/joypad simulados pela engine e rejeita cliques de gameplay. `combat_lab.gd` mantém foco por etapa separado do modelo. `BattleModel.target_candidates` centraliza o lado/elegibilidade; `targets_for` resolve o alvo central e `targets_in_radius` faz a consulta geométrica, compartilhada por prévia/impacto. Capturas em `artifacts/` são inspeção visual, não assets do jogo. Ver [INTERFACE_BATALHA.md](INTERFACE_BATALHA.md).

## Ritmos opcionais da batalha

`route_rhythm.gd` calcula distância/velocidade por um cronograma puro. `route_motion.gd` converte distância em segmento/progresso da curva aberta ou fechada, mantendo chamadas antigas sem ritmo. `battle_model.gd` resolve perfis de movimento e preserva o snapshot completo; `battlefield.gd` mantém apresentação separada; F3 mostra o ritmo em `combat_lab.gd`. Dados, limites e testes em [RITMOS_BATALHA.md](RITMOS_BATALHA.md). Nenhuma mudança no fluxo da exploração.

## Catálogo vigente e referências legadas

`data/dungeon.json` referencia quatro presets `exploration_*`, todos com os perfis refinados de movimento; formações e regras dos seis encontros foram preservadas. `BattleModel.default_preset_index()` resolve `default_preset_id` para inicialização do laboratório/sessão; a UI marca `legacy_preset_ids` como Legado, sem alterar índices históricos usados pelos testes. Nenhum encontro jogável usa legados. Mapeamento em [RITMOS_BATALHA.md](RITMOS_BATALHA.md); cobertura real em `tests/exploration_rhythm_tests.gd`.

## Versão atual por semente

`route_behavior.gd` planeja o próximo trecho/repouso com RNG por participante derivado da semente da batalha; estado primitivo fica inteiro no snapshot. `RouteMotion` delega opcionalmente ao comportamento e converte distância em coordenada na curva, mantendo a API antiga da exploração. `BattleModel` resolve `movement_behavior` pelo tipo, sem permitir que o preset sobrescreva pesos/tempos, e mantém foco visual independente da rota/alvo ponderado. Durante ação, orienta-se para o alvo efetivo ou referência válida em múltiplos alvos. Novos `lab_seeded`/`exploration_seeded_*` têm cinco formações; os dez presets anteriores são legados. Ver [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md).
