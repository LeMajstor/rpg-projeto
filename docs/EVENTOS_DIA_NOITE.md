# Eventos de horário na vila — O Segredo da Casa

## Requisitos confirmados e recorte

A vila existente recebe uma segunda casa com interior separado e uma pedra próxima. Durante o dia a pedra é comum; durante a noite brilha e permite descobrir uma inscrição uma única vez. O morador reconhece a descoberta depois, independentemente do horário. Não há recompensa, missão completa ou combate novo.

NPCs existentes demonstram mudança de posição e de diálogo. Janelas das duas casas e um poste acendem à noite. As representações são geométricas e provisórias; nenhum sprite foi criado/importado para esta tarefa.

O relógio anterior permanece: **ciclo completo em 2 minutos**, avanço automático somente no mapa-múndi, pausa na vila e nas duas casas/dungeon, eventos podendo alterar a hora, descanso temporal às 07:00. Câmera, fila, liderança, combate separado e acessos existentes foram preservados.

## Onde testar

Abra **Executar exploracao.command** ou F5 no projeto. WASD/setas movem, E/botão contextual interagem, E/Enter/Espaço avançam falas, Tab troca líder pelo menu e F3 mostra a depuração/horário.

- A casa original fica ao norte e mantém seus três NPCs, placa e diálogos.
- A segunda casa fica **ao sul da praça, na região direita da vila**. Siga a rua para a direita, desça pelo lado direito e aproxime-se da entrada pela frente. Seu interior tem paredes/móveis simples e saída ao sul.
- A pedra fica **à direita da segunda casa**. Aproxime-se pelo lado direito/sul para examiná-la, sem atravessar as paredes.
- O NPC 4 é o morador: de dia patrulha a praça e mantém as instruções anteriores, acrescentando a dica da luz estranha; à noite fica parado perto da segunda casa.
- O NPC 5 mantém suas instruções diurnas e comenta as luzes durante a noite. NPCs 1–3 e respostas do NPC 2 permanecem na casa original.
- Um poste fica junto do caminho entre as casas. Não possui interação.

Para observar naturalmente: saia pelo portão existente, aguarde a noite no mapa-múndi e volte pelo marcador da vila. Partindo de 10:00, a noite às 19:00 chega após 45 segundos reais permitidos. Ao entrar, o relógio pausa e o cenário já mostra os estados noturnos. Examine a pedra e converse com o morador. Volte ao mundo, aguarde o dia e retorne: a descoberta continua registrada. F3 permite testar também mudanças explícitas de hora sem viajar.

## Dados e responsabilidades

| Componente | Responsabilidade |
| --- | --- |
| `world_clock.gd` — preservado | Somente horário, períodos e sinais. Não conhece pedra ou NPC. |
| `area_rules.gd` — novo | Condições declarativas e seleção da primeira regra de interação válida; validação do esquema. |
| `exploration_model.gd` | Posições/rotas de NPCs, disponibilidade, validação de destinos e adiamento seguro. |
| `exploration_session.gd` | Coordena notificações, diálogos, flags compartilhadas e transições já existentes. |
| `exploration_view.gd` | Janelas, poste/halo e pedra/riscos luminosos conforme a noite; sem afetar lógica. |
| `dialogue_model.gd` — preservado | Continua exibindo o grafo selecionado, sem linguagem de condições ou efeitos próprios. |

Não existia um gerenciador narrativo independente: a extensão mínima é `session.story_flags`, ao lado dos estados já compartilhados, com API idempotente e sinal. Não foi criado um framework de missões/cutscenes.

### Posições por período

No NPC 4 de `data/exploration.json`:

```json
"placement_by_period": {
  "night": {"position": [970, 780]}
}
```

A definição normal (`position`, `route`, `speed`) continua sendo o posicionamento padrão. Noite seleciona o override; sem rota/velocidade no override, o NPC fica estático. Amanhecer/dia/entardecer usam o padrão neste experimento. Um override também pode definir rota e velocidade, com primeiro waypoint igual à posição inicial. Não há pathfinding ou deslocamento simulado entre os dois locais.

Ao mudar de posicionamento, a rota começa no ponto configurado. Permanecer no mesmo posicionamento conserva o progresso exato: mudanças de minuto, flags ou dia→entardecer não reiniciam patrulhas. Posições/rotas são verificadas contra limites e sólidos. Se o destino está ocupado por integrante ou outro NPC, o deslocamento fica pendente e o NPC aguarda no ponto anterior até o destino ficar livre.

Conversas, menus e estados que bloqueiam exploração adiam a troca de posição. O diálogo aberto é mantido; ao encerrar, aplica-se a atualização. Uma futura cutscene pode usar o estado de bloqueio da sessão; nenhum sistema de cutscene novo foi criado. Áreas inativas não simulam patrulhas; suas condições são atualizadas na chegada, sob o fade, sem recarregar todos os mapas.

### Condições, diálogos e disponibilidade

As condições aceitam somente:

- `periods`: lista de IDs de período aceitos; ausente/vazia significa qualquer período.
- `flags_set`: todas precisam estar registradas.
- `flags_unset`: todas precisam estar ausentes/falsas.

As três partes são combinadas por **E**. Não há execução de expressões/scripts em JSON.

`interaction_rules` é uma lista ordenada; **a primeira regra correspondente vence**. Exemplo resumido da pedra:

```json
"interaction_rules": [
  {"when": {"flags_set": ["house_secret_discovered"]}, "dialogue_id": "stone_known"},
  {"when": {"periods": ["night"], "flags_unset": ["house_secret_discovered"]},
   "dialogue_id": "stone_discover", "set_flag": "house_secret_discovered"},
  {"when": {}, "dialogue_id": "stone_day"}
]
```

A regra da flag já registrada vem antes da condição de noite, portanto a pedra e o morador reconhecem a flag em qualquer período. Sem regra correspondente, o diálogo normal continua, incluindo o fallback anterior `dialogue_by_period`. As referências devem apontar a diálogos existentes.

`available_when` usa o mesmo esquema e controla **se a entidade pode ser selecionada/interagida**, independentemente do diálogo e do desenho. A pedra do experimento fica disponível de dia e de noite; só a descoberta é noturna. Ela tem `solid: true` e `rect`, para colidir sem bloquear a própria interação através do seu volume. Outras paredes/pedra continuam bloqueando interações do outro lado.

### Flags de descoberta

```gdscript
if session.story_flags.get("house_secret_discovered", false):
    pass # Consultar em futuras interações autorizadas.

var changed = session.set_story_flag_once("house_secret_discovered")
session.story_flag_changed.connect(func(flag): print(flag))
```

O setter retorna `true` e notifica apenas na primeira vez. Repetições retornam `false`. Use a API para que disponibilidade/posições possam reagir; não escreva diretamente no dicionário.

Uma regra `set_flag` só é aplicada depois que seu diálogo iniciou com sucesso. Interação bloqueada ou grafo inválido não registra descoberta. A escolha do diálogo é capturada no início; alterar hora/flag durante a conversa não substitui a fala em andamento.

**Persistência atual:** a flag permanece na mesma sessão entre horários, áreas, visitas, casas e batalhas. Reiniciar teste cria uma sessão limpa. Não há salvamento em disco; isso não define o sistema de save da aventura final.

### Iluminação provisória

Obstáculos de casa usam `night_windows: true`; o poste usa `kind: "lamp"` e `night_light: true`. A vista desenha janelas apagadas/acessas e um halo discreto no chão. A pedra usa `object_type: "mysterious_stone"`, com brilho e marcas simples à noite. A noite é consultada uma vez por desenho e segue o período global; amanhecer/entardecer usam o estado apagado neste teste.

São formas e cores desenhadas pelo renderizador existente, sem assets novos, iluminação física ou sombras dinâmicas. A coloração global e o HUD continuam separados; câmera otimizada e ordenação por profundidade permanecem.

## Arquivos alterados

- Novo `scripts/exploration/area_rules.gd` e integração em `area_catalog.gd`, `exploration_model.gd` e `exploration_session.gd`.
- `exploration_view.gd`: luzes provisórias e pedra; coordenadas lógicas preservadas.
- `data/exploration.json`: segunda casa/poste/pedra, regras e diálogos de teste nos NPCs 4/5.
- Novo `data/secret_house.json`, cadastrado em `data/areas.json`; interior separado com retorno à vila.
- Novos `tests/town_events_tests.gd` e `tests/town_events_ui_smoke.gd`.
- Suítes de interiores/mundo/tempo/relevo atualizadas para a quinta área e a pedra sólida, preservando os casos anteriores. Fixtures históricas não foram alteradas nem adicionadas para esconder mudanças.
- Documentação, README e instruções permanentes atualizados.

O controlador de entrada `exploration_test.gd`, cena principal, relógio/paleta, scripts/dados/cena de combate, movimento de rota e mapa-múndi foram preservados. Não houve nova conexão artificial entre vila e mundo: a segunda casa usa os mesmos portais/entradas por dados.

## Testes e limites

```sh
godot --headless --path . --script res://tests/town_events_tests.gd
godot --headless --path . --script res://tests/town_events_ui_smoke.gd
```

Execute a suíte de UI com janela e `-- --visual-captures=/caminho/absoluto/existente` para capturas e comparações reais de pixels de janelas/poste/pedra/halo. As regressões do projeto e o teste gráfico de desempenho continuam no README. Resultados executados em [VALIDACAO.md](VALIDACAO.md).

Limites: coordenadas/formas/falas são provisórias. Não há rotinas entre mapas, animação de deslocamento entre posicionamentos, agenda por minuto, calendário, clima, recompensas, combates/quests novos, cutscenes completas ou save em disco. A descoberta é o único acontecimento narrativo explicitamente autorizado neste recorte.
