# Versão 0.2 — exploração integrada

Este documento registra a entrega original da v0.2 e sua arquitetura. A ampliação atual do mesmo mapa, os controles de diálogo e os seis encontros estão em [EXPLORACAO_INTERACOES.md](EXPLORACAO_INTERACOES.md). Dimensões, sólidos e encontro único descritos abaixo são o estado anterior; movimento, fila e integração continuam preservados.

## Requisitos confirmados pelo usuário

Mapa top-down pequeno; movimento contínuo em quatro direções sem diagonais; quatro personagens em fila; seguidores reproduzem o caminho do líder; líder respeita sólidos e integrantes não colidem entre si; troca de líder pelo menu; inimigo visível inicia o combate existente; retorno após vitória/fuga preserva HP/MP. O laboratório permanece independente. Sem história, missões, cidades, habilidades especiais de exploração, níveis ou técnicas conjuntas.

## Executar

- **Exploração:** abra `Executar exploracao.command` no macOS, ou importe `project.godot` no Godot 4.7.2 Standard e execute o projeto (F5).
- **Laboratório:** abra `Executar laboratorio.command`, ou abra `scenes/combat_lab.tscn` no editor e execute essa cena (F6).
- Ambos usam a mesma instalação de Godot. Os lançadores procuram instalação local, `GODOT_BIN` opcional ou a cópia temporária utilizada na validação; consulte o README.

```sh
godot --path .
godot --path . --scene res://scenes/combat_lab.tscn
```

## Controles

| Contexto | Controle | Resultado |
| --- | --- | --- |
| Mapa | WASD ou setas | Movimento contínuo cardinal. Se dois eixos estiverem pressionados, prevalece o mais recentemente pressionado ainda ativo. Opostos do mesmo eixo se anulam. |
| Mapa | Tab / Esc ou botão Equipe | Abre/fecha menu e pausa movimento. Clique em um dos quatro para torná-lo líder. |
| Mapa | E ou Iniciar combate | Interage somente perto do inimigo visível. Aproxime-se pelo lado direito dos blocos, por exemplo andando primeiro à direita e depois para cima. |
| Mapa | F3 | Mostra trilha registrada e contorno de colisão do líder. |
| Mapa | Reiniciar teste | Restaura condições iniciais, explicitamente. Não é descanso ou salvamento da aventura. |
| Batalha | Controles existentes | 1–4, A/H/I/F, seleção de alvo, Esc, modos Wait/Active, Espaço e F3. A luta começa com o tempo ativo, sem pausa manual inicial. |

Os comandos de reinício de combate do laboratório não ficam disponíveis durante um encontro do mapa. F5 não restaura o grupo nesse contexto. Após Game Over há um botão explícito para reiniciar todo o percurso de teste. O laboratório separado conserva seu F5, presets e demais ferramentas.

## Decisões técnicas provisórias adotadas

Estas escolhas permitem testar o recorte; não definem conteúdo final, balanceamento ou respawn da aventura.

1. Mapa/câmera fixos em área lógica de 1120×640; retângulos sólidos configurados em `data/exploration.json`. Velocidade, espaçamento e colisão são dados experimentais.
2. Colisão analítica varrida por eixo: volume quadrado do líder contra retângulos e limites. Não depende de física/navegação. Mesmo um deslocamento grande não atravessa uma parede. Só o caminho realmente percorrido é registrado.
3. Histórico de polilinha com amostragem por distância: seguidores ocupam pontos a 34, 68 e 102 unidades atrás do líder. Mantém curvas sem interpolar diretamente rumo ao personagem da frente. Ao parar, todos param mantendo o espaçamento. Segmentos retos são comprimidos e trechos anteriores à cauda descartados.
4. Na troca de líder, o escolhido assume o slot da frente; os outros preservam ordem relativa. Coordenadas dos slots e histórico não mudam. Evita teletransporte/reorganização através de sólidos. A ordem de identidades da batalha permanece independente da liderança do mapa, preservando os quatro ativos e o protagonista.
5. Os quatro continuam visíveis na exploração mesmo se algum estiver incapacitado. Não foi inventada uma restrição de liderança por HP; incapacitação conserva seus efeitos aprovados no combate. O grupo totalmente derrotado não volta ao mapa.
6. Interação explícita por E a até 72 unidades do inimigo; sem disparo automático por contato ou seguidor. Referência fixa ao preset `lab_a` em `lab.json`, sem copiar seus dados. Menu aberto bloqueia a interação.
7. Vitória remove o inimigo apenas nessa sessão; fuga bem-sucedida o mantém, exigindo nova interação. Não há reencontro automático ao reaparecer no mesmo lugar. Reiniciar teste restaura o inimigo. Isso não aprova uma regra de respawn para o jogo definitivo.
8. A sessão mantém uma única instância de `BattleModel`, suas fichas e estoque. Cada encontro chama `start(..., preserve_party=true)` e entrega a mesma instância à cena de combate. HP, MP, incapacitação e inventário não são reconstruídos na transição. O modo Wait/Active também permanece.
9. O mapa fica congelado/oculto na batalha e conserva posição, trilha e líder. A cena comunica seu resultado após concluir a animação; vitória/fuga liberam a cena e mostram o mapa novamente. Derrota conserva Game Over, sem cura ou retorno automático.
10. Sprites provisórios de 16×24 pixels criados em memória e coloridos com as fichas existentes; obstáculos e inimigo de teste desenhados em código. Sem dependência de assets/importação. Não define estilo final.

## Arquivos criados

| Arquivo | Responsabilidade |
| --- | --- |
| `data/exploration.json` | Limites, sólidos, spawn, movimento, espaçamento e referência ao encontro. |
| `scenes/exploration_test.tscn` | Entrada da exploração, nova cena principal do projeto. |
| `scripts/exploration/exploration_model.gd` | Movimento cardinal, colisões, histórico, fila, liderança e proximidade. |
| `scripts/exploration/exploration_session.gd` | Estado exploração/batalha/derrota e compartilhamento do modelo existente. |
| `scripts/exploration/exploration_view.gd` | Mapa, sprites, trilha e marcação visual de encontro. |
| `scripts/exploration/exploration_test.gd` | Entrada, menu, HUD e ciclo de vida da cena de combate. |
| `tests/exploration_tests.gd` | Testes de movimento, colisão, caminho, liderança e resultados reais do combate. |
| `tests/exploration_ui_smoke.gd` | Teclado, menu, cena integrada, vitória/fuga, derrota e reinício. |
| `Executar exploracao.command` | Acesso direto à exploração no macOS. |

## Alterações no laboratório e dependências verificadas

`battle_model.gd`, `data/lab.json` e `combat_lab.tscn` foram preservados integralmente. A análise prévia identificou dependência de `combat_lab.gd` sobre o modelo, `battlefield.gd` e os testes existentes.

Esse registro descreve a entrega original da exploração v0.2. No aprimoramento posterior autorizado de [rotas/melee](MOVIMENTO_E_MELEE.md), o núcleo e os dados receberam as extensões descritas naquele documento; a integração e os presets A/B continuam preservados, com suas regressões executadas.

`combat_lab.gd` ganhou `configure_encounter(shared_model)` (antes de entrar na árvore), sinais de resultado/reinício e modo integrado que não recria o grupo nem oferece reinício de batalha pelo laboratório. O comportamento padrão continua independente. `battlefield.gd` ganhou apenas uma mensagem de resultado configurável, mantendo desenho, mira e posição lógica.

`project.godot` aponta para a exploração. O lançador do laboratório agora especifica sua cena explicitamente; o lançador da exploração seleciona a nova cena. README, GDD, decisões, pendências e instruções do projeto registram o recorte autorizado.

## Verificação manual sugerida

1. Ande, pressione duas direções e confirme que nunca há diagonal. Encoste nos blocos e contorne-os; volte sobre a própria fila sem colisão entre integrantes.
2. Ative F3 e faça curvas. Confira que cada seguidor percorre o caminho, sem cortar quinas. Pare e observe espaçamento.
3. Abra Tab, escolha outro líder e confira sprite, ordem e HUD. Protagonista continua na equipe.
4. Aproxime-se do inimigo e pressione E. Confira quatro aliados e o ATB existente. Gaste MP e receba dano.
5. Vença ou fuja. Confira retorno ao mesmo lugar/líder, com os mesmos recursos. Após fuga, interaja novamente e confira a persistência.
6. No laboratório separado, repita seleção de aliados, Wait/Active, habilidades, itens, fuga, presets e depuração.

## Testes automatizados

```sh
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/exploration_tests.gd
godot --headless --path . --script res://tests/exploration_ui_smoke.gd
```

Os dois primeiros são regressões do laboratório; os dois últimos validam a v0.2. Resultados efetivamente executados em `VALIDACAO.md`.
