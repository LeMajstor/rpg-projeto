# Rotas suaves e aproximação melee — laboratório

## Requisitos confirmados

O usuário autorizou melhorar a movimentação programada, permitir curvas/percursos amplos, diferenciar possibilidades terrestres/voadoras/estáticas e implementar aproximação temporária corpo a corpo. Deve haver chegada, representação provisória, efeito e retorno, preservando posição lógica e progresso exato da rota. ATB, perfis, laboratório e presets existentes devem continuar funcionando. Não há animação artística definitiva nem navegação aleatória.

A evolução posterior dos ritmos de batalha está em [RITMOS_BATALHA.md](RITMOS_BATALHA.md): preset E com aceleração/desaceleração, pausas e ida e volta. As opções antigas abaixo continuam compatíveis; A/B/C/D permanecem intactos.

## Testar no laboratório

1. Abra `Executar laboratorio.command` ou `scenes/combat_lab.tscn` com F6 no editor.
2. Selecione **C · terrestre / voo / estático** e clique **Novo teste**. A/B permanecem disponíveis e integralmente iguais aos dados anteriores.
3. Em Active, com Pausa desligada, observe E1 em curva terrestre na região inimiga, E2 em voo amplo/rápido e E3 estático. Abra F3 para ver trajetórias, coordenadas e progresso.
4. Escolha qualquer aliado pronto → Atacar → E2. O sprite segue visualmente o alvo durante a aproximação, chega perto, produz um traço/anel provisório, aplica o dano e volta ao idle.
5. Observe também ataques inimigos. Na depuração, a posição lógica e o segmento/progresso do atacante ficam constantes durante toda a execução; apenas Δvisual muda. Depois do retorno, a rota avança do ponto preservado.
6. Use velocidade 0,25×, Pausa e Passo para observar as fases. Em Wait, escolher um aliado pronto continua pausando ATB/rotas. Active mantém movimento durante seleção. A pausa manual congela também as animações. A política anterior de permitir concluir uma animação já iniciada ao mudar Active → Wait foi preservada.

É possível iniciar diretamente a demonstração, sem mudar a cena principal da exploração:

```sh
godot --path . --scene res://scenes/combat_lab.tscn -- --preset=lab_motion
```

## Rotas: dados compatíveis e opções novas

Entradas antigas `route: [[x,y], ...]` e `speed` continuam produzindo o mesmo percurso linear e o mesmo início. `RouteMotion.create(points, speed)` mantém sua assinatura anterior, com um terceiro argumento opcional de configuração.

O novo campo opcional `motion` do preset contém:

| Campo | Opções e significado |
| --- | --- |
| `kind` | `ground`, `air`, `static`: identificação de movimento, separada do perfil de alvo. |
| `curve` | `linear` (padrão antigo), `smooth` (curva fechada pelos pontos) ou `ellipse`. |
| `samples_per_segment` | Resolução da curva suave. Demonstração usa 24. |
| `center`, `radii` | Centro e semieixos da elipse. Raios iguais produzem círculo. |
| `samples` | Resolução da elipse; demonstração usa 128. |
| `start_angle`, `direction` | Ângulo inicial em radianos e sentido da elipse; padrão zero e +1. |

`kind` não impõe uma rota automática nem muda a IA. Um voador também pode usar uma curva sinuosa por pontos. Um inimigo estático usa rota vazia/velocidade zero; a mesma possibilidade serve a futuros chefes sem criar conteúdo de chefe agora.

Escolha técnica experimental: curvas Catmull–Rom fechadas e elipses são amostradas deterministicamente ao criar o encontro. O avanço usa distância ao longo dessa polilinha, preservando velocidade aproximadamente constante e continuidade visual, inclusive no fechamento. Não há sorteio, física ou perseguição de aliados. No preset C, a rota terrestre fica na região inimiga; o voo ocupa uma área mais ampla, sem envolver o grupo inteiro em círculos.

O estado guarda pontos amostrados, controles, comprimento, tipo de curva, segmento, progresso e velocidade. Ataques não recebem autorização para alterá-lo. A resolução e os percursos são parâmetros de teste, não conteúdo/balanceamento definitivos.

## Ataques: aproximação separada da rota

`attack_motion.gd` não conhece rotas, HP, MP, ATB ou perfis. Apenas calcula deslocamento visual e fase a partir do progresso da ação e da posição do alvo.

| Fase melee | Comportamento |
| --- | --- |
| Aproximação | Interpolação suave desde a origem até perto da posição atual do alvo. O alvo pode continuar sua própria rota. |
| Impacto | Congela o ponto visual de contato; o modelo aplica o efeito uma única vez e registra os pontos realmente atingidos. O campo desenha traços/anel simples. |
| Retorno | Interpolação desde o contato até deslocamento exatamente zero. A origem e o estado da rota permanecem iguais ao snapshot. |
| Conclusão | ATB zera conforme a regra anterior; a rota retoma no próximo passo permitido pelo relógio. |

Escolhas técnicas provisórias:

- Atacar, Impacto físico e Varredura de teste recebem `delivery: melee`. Categorias físicas/básicas sem esse campo também mantêm fallback melee. Magias e itens conservam seu gesto visual anterior, exceto habilidades marcadas com `presentation: fullscreen`, como Onda, que agora usam a [apresentação configurável de tela inteira](TELA_INTEIRA.md).
- A duração total de 0,8 s e o impacto aos 50% foram preservados. Distância de parada de 44 unidades e sustentação de impacto por 15% da ação são novos parâmetros experimentais em `lab.json`.
- O dano ocorre na chegada. Depois disso, o ponto de contato fica fixo para o retorno, mesmo se o alvo continuar se movendo. Não há deslocamento da posição lógica do atacante nem arrasto do alvo.
- Em ataque múltiplo melee, o integrante válido mais próximo serve apenas como referência visual para aproximação. A lista de atingidos continua sendo a da habilidade; não muda seleção ponderada, probabilidade, potência ou custo. O perfil não filtra os alvos de uma ação em todos.
- Alvo incapacitado antes do impacto mantém o tratamento anterior: o efeito só considera alvos elegíveis, mas o atacante conclui seu retorno. Reinício explícito de teste limpa a ação e qualquer deslocamento residual.
- Não há colisão física no trajeto de ataque; as formas são provisórias. Os efeitos de área continuam usando coordenadas lógicas, nunca Δvisual.

## Arquivos e preservação

| Arquivo | Alteração |
| --- | --- |
| `scripts/combat/route_motion.gd` | Opções de curvas, amostragem determinística e avanço por distância, compatíveis com rotas antigas. |
| `scripts/combat/attack_motion.gd` | Novo componente exclusivo do movimento visual de ataque. |
| `scripts/combat/battle_model.gd` | Conecta as duas responsabilidades, preserva snapshots e aplica efeito na chegada. |
| `scripts/ui/battlefield.gd` | Desenha curvas, fases e impacto provisório. |
| `scripts/ui/combat_lab.gd` | Depuração de tipo/curva/fase/contato e argumento opcional de preset. |
| `data/lab.json` | Acrescenta C, indicação de melee e dois parâmetros visuais, sem alterar A/B, fichas, perfis ou valores anteriores de combate. |
| `tests/motion_tests.gd` | Curvas, contato, efeito, retorno, pausas e retomada exata. |
| `tests/motion_ui_smoke.gd` | Pausa, passo, velocidade, depuração e comando pela interface. |
| `tests/fixtures/legacy_presets.json` | Fotografia dos presets A/B para teste de preservação. |

A política em `target_policy.gd` não foi modificada. As cenas da exploração e do laboratório continuam as mesmas; a exploração usa seu preset anterior e recebe o novo melee por reutilizar o mesmo combate.

## Testes

```sh
godot --headless --path . --script res://tests/motion_tests.gd
godot --headless --path . --script res://tests/motion_ui_smoke.gd
```

As quatro suítes anteriores do laboratório/exploração também foram executadas. Resultados efetivamente obtidos em [VALIDACAO.md](VALIDACAO.md).
