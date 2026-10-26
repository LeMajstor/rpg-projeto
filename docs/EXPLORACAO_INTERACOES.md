# Laboratório de exploração ampliado

Distribuição substituída: NPCs agora ficam na casa e encontros na mini dungeon, com o exterior reservado a colisões e acessos. Consulte [INTERIORES_DUNGEON.md](INTERIORES_DUNGEON.md) para os mapas atuais. Este documento conserva o registro da entrega anterior e a arquitetura dos mecanismos reutilizados.

Atualização posterior: o exterior descrito aqui agora também conecta uma casa de teste por um ponto de transição adicional. O sistema, a preservação de estados entre áreas e os novos testes estão em [TRANSICOES_AREAS.md](TRANSICOES_AREAS.md). As seis batalhas, cinco NPCs e quatro objetos locais permanecem.

## Confirmado e implementado

Ampliação autorizada em **24/10/2026** do mapa existente, na mesma cena `scenes/exploration_test.tscn`. São seis encontros, cinco NPCs, quatro objetos e mais obstáculos. Gráficos originais provisórios. Sem mapa-múndi, vila, história, missões, inventário definitivo ou progressão narrativa. As falas descrevem os testes; não são conteúdo aprovado da aventura.

## Executar e controlar

Abra `Executar exploracao.command` no macOS ou execute o projeto pelo Godot (F5). No terminal:

```sh
godot --path .
```

O laboratório independente permanece em `Executar laboratorio.command`, ou `godot --path . --scene res://scenes/combat_lab.tscn`.

| Controle | Uso |
| --- | --- |
| WASD / setas | Movimento contínuo em quatro direções. A fila reproduz o caminho real do líder. |
| Tab / Esc / botão Equipe | Menu para trocar o líder; pausa o mapa. |
| E / botão contextual no alto | Interage com o elemento mais próximo ao alcance, sem parede no caminho. O botão informa qual será selecionado. Monstros só iniciam batalha por interação explícita. |
| E / Enter / Espaço / botão Avançar | Avança uma fala; na última, encerra. Não escolhe uma resposta automaticamente. |
| 1 / 2 ou clique na resposta | Escolhe o ramo na conversa do NPC 2. |
| F3 no mapa | Mostra trilha da fila, volumes sólidos e rotas programadas de NPCs/monstros. |
| Reiniciar teste | Restaura grupo, recursos, encontros, objetos e patrulhas; não é um sistema de salvamento. |

Durante o diálogo, movimento, menu da equipe, patrulhas e outras interações ficam bloqueados. Esc não descarta a conversa; avance até encerrá-la. O mapa também pausa durante menu e combate. Não há encontros automáticos ao encerrar uma conversa ou retornar da luta.

## Regiões e roteiro manual

| Região no mesmo mapa | Como testar | Resultado esperado |
| --- | --- | --- |
| Norte: NPCs 1, 2 e 3 | Aproxime-se, pressione E e avance por botão/tecla. No NPC 2, teste ambas as respostas em conversas separadas. | Nome e falas corretos; cada opção abre seu ramo. Não há missão ou recompensa. A fila e as patrulhas param durante a conversa. |
| Sudoeste: NPC 4; centro: NPC 5 | Observe a patrulha do NPC 4 e converse com ele enquanto anda. | Para no ponto exato e retoma ao encerrar. NPC 5 permanece imóvel. NPC 2 também patrulha ao norte. |
| Centro e sul: colisões | Contorne blocos, árvores e pedras. Entre entre as duas paredes horizontais e depois no corredor vertical à direita. Ative F3, faça curvas e volte sobre a fila. | Líder respeita sólidos; seguidores percorrem o mesmo caminho sem cortar quinas nem colidir entre si. |
| Sudeste: objetos | Abra o baú duas vezes, leia as duas falas da placa, acione a alavanca e atravesse a porta. Interaja também diretamente com a porta. | Baú muda visual/estado sem adicionar item. Placa tem múltiplas falas. Alavanca e porta alternam a colisão e seus indicadores. |
| Passagem da porta | Atravesse e tente fechar enquanto algum seguidor estiver nela; depois afaste a fila. | Fechamento recusado enquanto qualquer integrante ocupa o volume; funciona com a passagem livre. |
| Leste: seis monstros | Use E perto de cada monstro, observe preset e vença/fuja quando permitido. | Mesma cena/modelo do combate; retorno ao mesmo mapa/fila, preservando HP/MP e estados dos objetos. Vitória remove somente aquele encontro; fuga o mantém. |

O ponto inicial e os três blocos originais foram mantidos. Para chegar ao primeiro encontro, ande à direita pela faixa inicial e depois ao norte. Para ir aos NPCs do norte, contorne a árvore antes de subir. Para os corredores, desça a partir do início e siga à direita entre as paredes. Os NPCs e monstros não são sólidos neste laboratório; os sólidos são obstáculos e porta fechada.

| Monstro | Preset existente | No mapa |
| --- | --- | --- |
| M1 | A / `lab_a` | Parado; encontro original preservado. |
| M2 | B / `lab_b` | Parado. **B impede fuga**, como no laboratório. |
| M3 | C / `lab_motion` | Rota retangular simples. |
| M4 | D / `lab_fullscreen` | Parado. Demonstra apresentação de tela inteira no combate. |
| M5 | A / `lab_a` | Patrulha horizontal de ida e volta. |
| M6 | C / `lab_motion` | Parado. |

As rotas do mapa são independentes das rotas de batalha. Repetir um encontro após fuga reinicia o mesmo preset, mantendo os recursos gastos. Não há cura entre encontros; para restaurar tudo, use o reinício explícito. As regras de respawn da aventura continuam pendentes.

## Arquitetura e escolhas técnicas experimentais

- **Dados:** `data/exploration.json` mantém limites, spawn, sólidos, espaçamento e velocidades; acrescenta `regions`, `encounters`, `npcs`, `objects` e `dialogues`. Cada entidade tem ID estável. `encounters` substitui o campo singular anterior; as referências e testes foram migrados.
- **Mapa:** área lógica de 1440×900, exibida inteira pela mesma vista fixa; não há nova cena, câmera, estrutura de aventura ou transição entre mapas. Paredes, troncos e pedras usam retângulos sólidos; F3 revela o volume real. Corredores de 44 unidades permitem testar o volume de 24 unidades do líder. Todos os números são provisórios.
- **Entidades:** o modelo clona definições para estado de sessão (`present`, `position`, `route_state`, `open`, `active`). NPCs/encontros compartilham o módulo puro `route_motion.gd`, sem alterá-lo; somente rotas lineares de waypoints no mapa. Um ponto/velocidade zero representa uma entidade imóvel. Não há sorteio, perseguição, física ou navegação.
- **Interação:** menor distância entre os candidatos válidos; empate mantém ordem dos dados. Alcance padrão 64, encontros 72 unidades. Segmentos contra sólidos impedem interação através de paredes/porta fechada. A própria porta continua selecionável. Só o líder inicia interação.
- **Diálogo:** `dialogue_model.gd` é RefCounted e independente da interface. Cada definição tem `start` e `nodes`; cada fala contém `text`, `next` ou `choices` (`text`, `next`). Destino vazio encerra. Sem avaliador de código, sistema de condições narrativas ou missões. O nome vem da entidade; o NPC 2 demonstra dois ramos que convergem ao encerramento.
- **Objetos:** `object_type` seleciona efeito simples: `chest` abre uma vez e usa fala alternativa na repetição; `sign` só conversa; `door` alterna colisão; `lever` aponta ao ID da porta por `target_id`. O indicador da alavanca acompanha a porta mesmo quando ela é acionada diretamente. Fechar verifica os quatro slots da fila para não criar um sólido sobre eles. Não altera HP/MP ou inventário.
- **Sessão:** coordena interação, pausa de diálogo e encontro ativo por ID. Uma vitória remove apenas esse ID. A mesma instância de BattleModel e a mesma cena de combate continuam sendo usadas. Objetos e rotas permanecem em memória durante a luta. Nenhum estado novo é salvo em disco.
- **Apresentação:** interface usa o mesmo painel para falas de NPCs e objetos, com opções geradas em botões. Desenho provisório diferencia monstros, NPCs, árvores, pedras, paredes, baú, placa, porta e alavanca. Efeitos/estados não definem conteúdo final.

Para reutilizar, adicione uma entidade à coleção correspondente no JSON, use um ID único e referencie um diálogo ou preset existente. Uma rota opcional é uma lista de coordenadas absolutas; `speed` controla o avanço. Novas falas/respostas exigem apenas nós no JSON. Um novo efeito de objeto requer um comportamento explícito na sessão; os dados não executam comandos arbitrários.

## Arquivos criados e alterados

| Arquivo | Alteração |
| --- | --- |
| `scripts/exploration/dialogue_model.gd` | Novo modelo de falas, avanço e escolhas. |
| `data/exploration.json` | Mesmo mapa ampliado, regiões, entidades e falas de teste. |
| `scripts/exploration/exploration_model.gd` | Coleções por ID, rotas, seleção por proximidade/visibilidade e sólidos dinâmicos; movimento/fila preservados. |
| `scripts/exploration/exploration_session.gd` | Interação genérica, pausa de diálogo, efeitos simples e encontro ativo individual. |
| `scripts/exploration/exploration_test.gd` | Botão contextual, painel de diálogo/respostas e entrada de teclado. |
| `scripts/exploration/exploration_view.gd` | Regiões e sprites provisórios, estados dos objetos e depuração ampliada. |
| `tests/interaction_tests.gd` | Novos testes de dados, acessibilidade, rotas, colisões, diálogos, escolhas, objetos e seis combates reais. |
| `tests/interaction_ui_smoke.gd` | Novos testes de teclado/botões, pausa, UI, corredor, objetos, reinício e integração com D; capturas opcionais. |
| `tests/exploration_tests.gd`, `tests/exploration_ui_smoke.gd` | Migração das consultas de encontro único para ID/lista, mantendo os casos anteriores. |
| `AGENTS.md`, README, GDD, decisões, pendências e documentação técnica | Registro de autorização, uso, arquitetura e validação. |

O combate foi inspecionado antes da mudança. Todos os arquivos de `scripts/combat/`, `scripts/ui/`, `data/lab.json` e `scenes/combat_lab.tscn` permaneceram idênticos à versão anterior, assim como a cena principal, a configuração do projeto e os lançadores. A ampliação ocorre somente nos componentes e dados da exploração.

## Testes

```sh
godot --headless --path . --script res://tests/interaction_tests.gd
godot --headless --path . --script res://tests/interaction_ui_smoke.gd
```

A lista completa das regressões continua no README. Para repetir a inspeção gráfica opcional, passe `-- --visual-captures=/caminho/absoluto/existente` à suíte de UI, sem `--headless`. Capturas são ferramentas de teste, não assets necessários ao jogo. Resultados efetivamente executados em [VALIDACAO.md](VALIDACAO.md).
