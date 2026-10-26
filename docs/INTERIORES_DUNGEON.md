# Exterior, casa e mini dungeon

**Distribuição atualizada:** o antigo exterior agora é uma vila com dois NPCs nas ruas, a casa mantém três NPCs e a dungeon fica no mundo aberto. A topologia atual é casa↔vila↔mundo↔dungeon; consulte [VILA_E_MUNDO.md](VILA_E_MUNDO.md). O texto abaixo registra a etapa anterior.

A visualização atual usa câmera seguindo o líder, com escala igual à casa anterior em todas as áreas. Mapas maiores aparecem parcialmente e são percorridos com a câmera; veja [CAMERA_EXPLORACAO.md](CAMERA_EXPLORACAO.md).

**Combates atualizados:** os seis encontros usam comportamento por semente, com formações variadas e atributos/regras preservados. A tabela A/B/C/D abaixo registra a etapa histórica; o mapeamento vigente está em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md). Os dez modelos anteriores são legados.

## Distribuição confirmada

Decisão de **24/10/2026**: NPCs e monstros ficam nos interiores; exterior somente com colisões e os acessos necessários. A distribuição anterior de NPCs/encontros no exterior foi substituída.

| Área jogável | Conteúdo |
| --- | --- |
| `lab_exterior` / `data/exploration.json` | Sólidos, árvores, pedras, blocos, corredores de teste, entrada da casa e entrada da dungeon. Sem NPCs, encontros ou objetos locais. |
| `test_house` / `data/house.json` | Cinco NPCs, seus diálogos, duas patrulhas, móveis sólidos, placa e saída. Sem monstros. |
| `test_dungeon` / `data/dungeon.json` | Seis encontros existentes com A/B/C/D, salas/corredores, baú, porta, alavanca e saída. Sem NPCs. |

A placa na casa e os outros três objetos na dungeon são escolhas técnicas provisórias de organização. Não há história, progressão, chefes definitivos, missões ou recompensas novas. A casa não cura o grupo. O exterior continua sendo um mapa de teste, sem criação de mapa-múndi.

## Executar e testar

Abra `Executar exploracao.command` no macOS ou execute o projeto no Godot com F5. O início permanece no exterior.

```sh
godot --path .
```

Os acessos ficam ao nordeste. A casa fica à esquerda e a entrada escura da dungeon à direita. A partir do início, ande para a direita pela faixa livre e suba pelo lado direito dos blocos. Aproxime-se de um acesso e use **E** ou o botão contextual. Dentro de cada área, a saída fica ao sul e usa E.

| Teste | Procedimento | Resultado esperado |
| --- | --- | --- |
| Exterior vazio | Percorra o mapa e os corredores; ative F3. | Somente o grupo, obstáculos e os dois acessos; sem NPCs, monstros ou baú/placa/porta/alavanca locais. |
| Casa | Converse com NPCs 1–5 por E; avance com E/Enter/Espaço ou botão. | Nome e múltiplas falas; fila e patrulhas pausam durante conversa. |
| Respostas | Converse com NPC 2 e escolha 1/2 ou clique. | Cada resposta leva ao ramo correspondente; nenhuma cria missão/recompensa. |
| Patrulhas | Observe NPCs 2 e 4; visite a dungeon e volte. | Rotas programadas, sem aleatoriedade; pausa enquanto a casa está inativa e retomada do mesmo ponto. |
| Placa | Use E perto da placa da casa. | Instruções dos testes atuais, com múltiplas falas. |
| Dungeon | Entre e siga pelo primeiro corredor, passando pela abertura à direita da parede horizontal. Suba até a alavanca junto da porta. | A fila acompanha as curvas e respeita sólidos. |
| Passagem | Acione a alavanca, termine a fala e atravesse a porta à direita. | A passagem fica livre para as outras salas. Porta e alavanca usam o mesmo mecanismo anterior. |
| Combate | Use E perto de M1–M6. | Combate existente com preset fixo; vitória/fuga retornam à mesma dungeon e fila, mantendo HP/MP. M2 impede fuga. |
| Baú | Abra o baú na parte inferior direita, repita a interação e revisite a área. | Estado aberto preservado, mensagem de repetição e nenhum item novo. |
| Revisita | Vença um monstro, visite a casa pelo exterior e volte à dungeon. | Somente o monstro vencido continua ausente, porta/baú conservam estado e recursos não são restaurados. |
| Reinício | Use Reiniciar teste. | Começa no exterior; todas as áreas, objetos, recursos e encontros voltam ao início. |

WASD/setas mantêm movimento cardinal. Tab/Esc abre o menu de liderança em qualquer área. Os quatro integrantes e o líder escolhido persistem nas viagens. F3 mostra rotas, trilha e colisões da área ativa. Diálogo, menu, transição e combate mantêm seus bloqueios anteriores.

## Mini dungeon provisória

A entrada/saída fica no sudoeste, em um trecho livre para os quatro integrantes. M1 fica na primeira sala. A alavanca, alcançável antes da porta fechada, abre a passagem para os setores central e direito. Há aberturas nas divisórias para todas as salas; o setor de M4 pode ser alcançado pela abertura na parede horizontal da direita.

| Encontro mantido | Preset | Movimento no mapa |
| --- | --- | --- |
| M1 / `test_map_enemy_01` | A / `lab_a` | Parado. |
| M2 / `test_map_enemy_02` | B / `lab_b` | Parado; fuga bloqueada pelo preset. |
| M3 / `test_map_enemy_03` | C / `lab_motion` | Rota retangular programada. |
| M4 / `test_map_enemy_04` | D / `lab_fullscreen` | Parado. |
| M5 / `test_map_enemy_05` | A / `lab_a` | Patrulha horizontal programada. |
| M6 / `test_map_enemy_06` | C / `lab_motion` | Parado. |

IDs, perfis, habilidades, custos e presets de combate foram mantidos. Somente posições/rotas de exploração foram realocadas. A movimentação do mapa continua independente das rotas e animações dentro da batalha. O baú, a porta e a alavanca mantêm seus IDs e comportamentos locais. A porta não fecha sobre integrantes da fila.

## Arquitetura e arquivos

A mini dungeon é outra definição no catálogo existente, não um sistema de aventura adicional. A sessão, o cache de estados, as entradas validadas, o fade, os diálogos e o combate compartilhado foram reutilizados. Não foi necessário alterar o algoritmo de transição ou o modelo de combate.

| Arquivo | Alteração |
| --- | --- |
| `data/dungeon.json` | Novo mapa interior com salas, seis encontros, rotas, três objetos e saída. |
| `data/areas.json` | Cadastro da terceira área. |
| `data/exploration.json` | Remove entidades internas do exterior, mantém colisões, adiciona acesso e entrada de retorno da dungeon. |
| `data/house.json` | Recebe os cinco NPCs, patrulhas, diálogos e placa; móveis/saída preservados. |
| `scripts/exploration/exploration_view.gd` | Cores opcionais por mapa e desenho provisório da entrada da dungeon. |
| `scripts/exploration/exploration_test.gd` | Legenda atual das três áreas. |
| `scripts/exploration/exploration_session.gd` | Mensagem inicial atualizada; regras preservadas. |
| `tests/internal_areas_tests.gd` | Cobertura dos dados reais, acessibilidade, fila, interações, seis vitórias, fuga, persistência entre três áreas e reinício. |
| `tests/internal_areas_ui_smoke.gd` | Controles e renderização das três áreas reais, conversa na casa, passagem e combate na dungeon. |
| `tests/fixtures/areas_before_internal_split.json` | Snapshot anterior, usado somente para regressões de mecanismos com percursos fixos. Não faz parte do catálogo jogável. |
| `tests/fixtures/legacy_exploration_screen.gd` | UI de teste que injeta esse snapshot nas suítes anteriores, sem alterar o carregamento do jogo. |
| Suítes anteriores de exploração/interações/áreas | Passam a ler as fixtures para conservar seus cenários de colisão, erros de destino e demais casos. As novas suítes verificam a distribuição jogável atual. |
| README, GDD, decisões, pendências, instruções e validação | Registro do requisito e roteiro atual. |

Geometria, dimensões, cores e disposição de salas/NPCs/objetos são escolhas técnicas de teste. Não são arte, narrativa ou balanceamento definitivos. A busca de acessibilidade existe apenas nos testes; não foi adicionada navegação ao jogo.

## Verificação automatizada

```sh
godot --headless --path . --script res://tests/internal_areas_tests.gd
godot --headless --path . --script res://tests/internal_areas_ui_smoke.gd
```

O README lista também as doze suítes anteriores. A cobertura atual verifica que o exterior não tem NPCs/encontros/objetos locais; todos os NPCs e seus ramos continuam utilizáveis na casa; a alavanca é acessível com a porta fechada; abrir a porta libera acesso a todos os encontros/objetos; rotas e entradas são livres; seis vitórias reais retornam à dungeon com os recursos e apenas o ID correto removido; fuga/revisitas/reinício preservam as regras existentes. A suíte de UI aceita `-- --visual-captures=/caminho/absoluto/existente` com renderização gráfica.

Resultados executados e limites em [VALIDACAO.md](VALIDACAO.md). O laboratório de combate continua acessível separadamente pelo lançador próprio ou `godot --path . --scene res://scenes/combat_lab.tscn`.
