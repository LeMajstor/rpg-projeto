# Arquitetura implementada — laboratório

`GDD.md` é a fonte de regras; `DECISOES_TECNICAS.md` registra preenchimentos experimentais autorizados. `ARQUITETURA.md` permanece como proposta histórica anterior ao GDD consolidado.

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

Cada combatente mantém `logical_position`, `visual_offset`, `route_state` e `facing`. Aliados recebem a coordenada lógica do slot. Movimento só atualiza inimigos vivos que não estejam em execução. Animações alteram apenas o deslocamento visual. Ao finalizar, o modelo verifica que posição lógica e rota do ator permanecem idênticas ao início.

## Tempo e execução

A cena acumula tempo real multiplicado pela velocidade e chama o modelo em passos de 1/120 s. Pausa interrompe esses passos; avanço manual chama dois passos. Wait controla ATB e rotas dentro do modelo. Ações têm progresso próprio dentro dos passos recebidos, permitindo concluir animação iniciada ao mudar de Active para Wait.

Há uma execução por vez. Atores que aguardam podem carregar ATB e mover-se, sujeitos ao modo de tempo. O modelo valida seleção/alvos, registra origem/rota, aplica efeito no impacto e retorna ao idle antes de zerar ATB e verificar resultado.

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
