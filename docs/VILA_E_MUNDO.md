# Vila de testes e mundo aberto

## Requisitos confirmados

O antigo exterior passa a representar uma vila/cidade. A casa permanece na vila, e NPCs podem ficar dentro dela e nas ruas/praças. Essa decisão substitui as restrições anteriores de NPCs apenas nos interiores e exterior somente com colisões.

A vila possui uma saída para um mundo aberto provisório, e esse mundo tem uma interação para entrar na vila novamente. A mini dungeon fica no mundo aberto e retorna a ele. O fluxo vigente é:

**Duas casas ⇄ Vila ⇄ Mundo aberto ⇄ Mini dungeon**

O mundo contém florestas, montanhas, colinas, mar e caminhos simples. Manter os gráficos provisórios, a câmera seguindo o líder, profundidade, colisões, fila, combate e estados entre áreas. Sem monstros comuns/encontros aleatórios no mundo aberto. Não há história, missões, progressão, economia, navegação marítima ou salvamento novos.

## Executar e controlar

Abra `Executar exploracao.command` ou execute o projeto no Godot com F5. O início agora representa a **Vila de testes**, mantendo a posição inicial anterior.

```sh
godot --path .
```

| Contexto | Procedimento |
| --- | --- |
| Vila → casa | Vá à casa ao norte e use E / Entrar na casa. |
| Casa → vila | Aproxime-se da saída ao sul e use E. |
| Vila → mundo | Vá ao portão a nordeste, à direita da casa, e use E / Sair da vila. A faixa livre à direita do início permite chegar andando e depois subir pelo lado direito dos blocos. |
| Mundo → vila | Aproxime-se do marcador da vila no sudoeste e use E / Entrar na vila. Não basta encostar ou esperar. |
| Mundo → dungeon | Siga o caminho para leste, depois norte e novamente leste até a entrada de pedra. Use E / Entrar na dungeon. |
| Dungeon → mundo | Use a saída no sudoeste da dungeon. O destino é o mundo, não a vila. |

WASD/setas movem o grupo em quatro direções; Tab/Esc abre o menu de liderança. E também inicia falas/interações. E/Enter/Espaço ou botão avançam diálogo, e números/clique escolhem respostas. F3 mantém colisões, profundidade, rotas e câmera. Reiniciar teste restaura todas as áreas e volta à vila. O laboratório de combate continua no lançador independente.

## NPCs e conteúdo preservado

Os mesmos cinco NPCs de teste foram distribuídos, como escolha provisória, entre **três na casa e dois nas ruas**:

| NPC | Local atual | Comportamento |
| --- | --- | --- |
| NPC 1 | Casa | Parado, múltiplas falas. |
| NPC 2 | Casa | Patrulha e diálogo com duas respostas. |
| NPC 3 | Casa | Parado, instruções de colisão/depuração. |
| NPC 4 | Praça de dia / segunda casa à noite | Patrulha diurna e posição noturna fixa; morador de O Segredo da Casa; reconhece descoberta. |
| NPC 5 | Rua perto do portão | Parado, instruções diurnas e comentário noturno sobre as luzes. |

Não são habitantes definitivos nem personagens narrativos. As falas foram atualizadas para descrever os acessos atuais. A placa permanece na casa. Os seis encontros, baú, porta e alavanca permanecem na dungeon. Todos os encontros usam o comportamento atual por semente, com formações variadas; os dez modelos anteriores são legados. Ver [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md). M2 continua impedindo fuga. A casa e a vila não restauram HP/MP.

## Paisagem provisória

O relógio global agora **avança automaticamente somente no mapa-múndi**, o mundo aberto `test_world`, classificado explicitamente como `overworld`. O ciclo completo dura **2 minutos reais** e não depende de F3. Vila, casa e dungeon pausam o horário; as viagens o preservam. Vila/mundo exibem iluminação do horário global, casa/dungeon usam luz fixa. Configuração em [CICLO_DIA_NOITE.md](CICLO_DIA_NOITE.md).

O mundo é uma área estática de teste de 1920×1280, com o mesmo zoom da casa e câmera móvel. Não há geração procedural. Os elementos são configurados em dados e desenhados com retângulos, elipses, triângulos e as árvores provisórias existentes.

- Florestas/bosques: massas inteiras sólidas, sem passagem entre árvores; desenho simples de copas. Essa regra do mundo não muda a colisão de árvores isoladas da vila.
- Montanhas: bases sólidas e silhuetas elevadas com ordenação por profundidade.
- Colinas: barreiras sólidas; um platô tem rampa ao sul para testar subida/descida gradual dos quatro. Outra colina permanece inacessível. Ver [RELEVO_E_FLORESTAS.md](RELEVO_E_FLORESTAS.md).
- Mar: retângulos sólidos na costa leste/sudeste com linhas simples representando água. Sem nado, barcos ou travessia neste teste.
- Caminhos/faixas de areia: indicações caminháveis para localizar os acessos; não mudam a velocidade.
- Vila no mundo: marcador simples de construções, base sólida e ponto explícito para entrar.

Dimensões, posições, cores e distribuição dos NPCs são escolhas técnicas provisórias. Bloqueio de colinas/florestas e subida por rampas são requisitos confirmados. O caminho principal da vila à dungeon não exige passar pelo mar nem pelas montanhas.

## Arquitetura e dados

O ID técnico `lab_exterior` e o arquivo `data/exploration.json` foram preservados para a vila. O nome mostrado ao jogador é **Vila de testes**. A nova área `test_world` está em `data/world.json`, cadastrada em `data/areas.json`.

| Acesso | Origem → destino/entrada |
| --- | --- |
| `house_entrance` | Vila → casa / `from_lab` |
| `house_exit` | Casa → vila / `from_house` |
| `town_exit` | Vila → mundo / `from_town` |
| `enter_town` | Mundo → vila / `from_world` |
| `dungeon_entrance` | Mundo → dungeon / `from_exterior` |
| `dungeon_exit` | Dungeon → mundo / `from_dungeon` |

`terrain` contém elementos com `kind`, `rect` e `label` opcional. Caminhos/areia são visuais; florestas geram sólidos e colinas geram barreiras ou bordas com abertura para a rampa. `terrain_geometry.gd` fornece colisões/altura para o modelo existente. Demais sólidos continuam em `obstacles`. O mar usa `ground_only: true`: permanece sólido, mas é desenhado no chão e não entra na ordenação dos corpos. Montanhas e marcador da vila reutilizam `rect` e `visual_height`. Os dados recebem validação básica antes de carregar um destino.

A sessão e seu cache de áreas, validação da entrada para os quatro, fade, proteção de reentrada e modelo único de combate foram reutilizados. Não houve reimplementação de transições ou batalha. Fila, ordem, líder, HP/MP, incapacitação, estoque, baús/portas/alavancas e resultados de encontros permanecem entre viagens. Áreas inativas conservam suas patrulhas pausadas. O resultado de combate retorna à dungeon antes de qualquer viagem pelo mundo.

## Arquivos criados e alterados

| Arquivo | Alteração |
| --- | --- |
| `data/world.json` | Novo mundo com paisagem, sólidos, entradas e acessos de vila/dungeon. |
| `data/areas.json` | Quarta área no catálogo; câmera e duração mantidas. |
| `data/exploration.json` | Antigo exterior como vila, dois NPCs, ruas/praça, portão e retorno do mundo. |
| `data/house.json` | Três NPCs e falas/placa adaptadas aos acessos atuais. |
| `data/dungeon.json` | Apenas destino da saída e instrução de retorno atualizados; encontros e geometria preservados. |
| `exploration_view.gd` | Desenho de terreno, mar, montanhas e marcador da vila, mantendo a câmera/profundidade existentes. |
| `exploration_depth.gd` | Sólidos `ground_only` ficam fora da fila de corpos. |
| `area_catalog.gd` | Validação de terreno e metadado de chão. |
| `exploration_session.gd`, `exploration_test.gd` | Mensagem inicial e legenda atualizadas; algoritmos preservados. |
| `tests/world_map_tests.gd`, `tests/world_map_ui_smoke.gd` | Novos testes dos requisitos e percurso entre quatro áreas. |
| Suítes `internal_areas`, `camera_ui_smoke` e `depth_ui_smoke` | Usam os acessos reais adicionais vila↔mundo e a distribuição atual; sem nova fixture jogável. |
| Documentação | Autorizações, limites, dados e roteiro atual. |

Os scripts/dados de combate, os modelos puros de rota/câmera/diálogo, cenas e configuração do projeto foram preservados. A atualização de relevo adiciona geometria ao modelo de exploração e segue visualmente a altura do líder. As fixtures anteriores continuam exclusivas das regressões históricas.

## Roteiro de aceite

1. Converse com NPCs nas ruas e na casa. Confirme pausa de fila/patrulha e respostas do NPC 2.
2. Saia pelo portão e confirme paisagem, mesma escala e fila segura. Passe algum tempo andando: não deve iniciar combate.
3. Tente atravessar colinas, florestas e mar: devem bloquear. Contorne o marcador da vila pelo leste, siga ao norte e vire à esquerda no desvio até a rampa. Suba com W/↑ e desça com S/↓; cada integrante muda de altura ao passar. Confira bordas/altura em F3.
4. Volte ao marcador da vila e use E. Confirme retorno ao portão com líder e recursos preservados.
5. Saia novamente, siga o caminho até a dungeon e entre. Combata, gaste MP, abra porta/baú e saia pelo sudoeste.
6. Confirme retorno ao mundo; visite vila/casa e depois volte à dungeon. Resultados, objetos, HP/MP e ordem da equipe devem permanecer.
7. Reinicie: volte à vila inicial com recursos e estados restaurados.

## Testes

```sh
godot --headless --path . --script res://tests/world_map_tests.gd
godot --headless --path . --script res://tests/world_map_ui_smoke.gd
```

O README contém as dezoito regressões anteriores. As suítes atuais de interiores, câmera e profundidade foram adaptadas à topologia real de quatro áreas, conservando seus casos. Para capturas, execute a suíte de UI com renderização gráfica e `-- --visual-captures=/caminho/absoluto/existente`. Resultados executados em [VALIDACAO.md](VALIDACAO.md).

A segunda casa fica ao sul da praça, com pedra à direita e poste no caminho. Os estados diurnos/noturnos e a descoberta única estão documentados em [EVENTOS_DIA_NOITE.md](EVENTOS_DIA_NOITE.md). A casa original e os acessos ao mapa-múndi/dungeon permanecem.
