# RPG — Protótipo v0.2: exploração e combate

Protótipo jogável em **Godot + GDScript**, com cinco áreas conectadas por E e fade:

**Duas casas ⇄ Vila de testes ⇄ Mundo aberto ⇄ Mini dungeon**

- **Vila/cidade de testes:** antigo mapa externo, agora com ruas, praça, dois NPCs, duas casas e portão para sair ao mundo.
- **Casa original:** três NPCs, diálogos com respostas, móveis sólidos, placa e saída para a vila.
- **Segunda casa:** interior separado, móveis sólidos e saída; pedra e evento noturno na rua próxima.
- **Mundo aberto:** florestas, árvores, montanhas, colinas, caminhos, costa e mar provisórios. Interações para entrar na vila e na dungeon. Sem monstros comuns.
- **Mini dungeon:** os seis encontros com os ritmos atuais de batalha, salas, corredores, baú, porta e alavanca; sua saída retorna ao mundo aberto.

Os mesmos cinco NPCs estão distribuídos na casa e na vila. Quatro personagens seguem o líder, trocado pelo menu. HP/MP, objetos e encontros vencidos persistem entre áreas; patrulhas inativas pausam. **Reiniciar teste** restaura tudo. Gráficos simples, sem história, missões ou progressão.

A **câmera acompanha o líder** e mantém a mesma escala da casa em todas as áreas. Dungeon e exterior deixam de ser reduzidos para mostrar o mapa inteiro; o enquadramento acompanha o grupo e respeita as bordas. HUD e diálogos ficam fixos.

O cenário agora tem **profundidade visual**: árvores, casas e paredes encobrem quem passa atrás; quem passa à frente aparece sobre elas. A colisão usa a base no chão, separada da copa e da altura desenhada. Em F3, vermelho mostra os sólidos e azul marca a base de profundidade.

O **laboratório de combate continua separado**, iniciando em **Atual · comportamento por semente**: quatro aliados, Wait/Active, Atacar/Habilidades/Itens/Fugir, três formas de alvo, ritmos programados por tipo, IA ponderada e depuração. Ataques melee aproximam o sprite, mostram impacto e retornam à origem. Todos os encontros da exploração usam os ritmos atuais; todos os dez modelos anteriores são referências legadas.

## Executar

Validado com **Godot 4.7.2 Standard**, sem .NET ou plugins externos.

1. **Exploração:** abra `Executar exploracao.command` no macOS, ou importe `project.godot` no Godot e pressione **F5**.
2. **Laboratório independente:** abra `Executar laboratorio.command`, ou abra `scenes/combat_lab.tscn` no editor e pressione **F6**.

Os lançadores procuram uma instalação local, a variável opcional `GODOT_BIN` e, por último, a cópia temporária usada nesta validação. Essa cópia pode ser removida pelo sistema; instalar o Godot mantém o acesso independente dela.

Se necessário, obtenha a edição Standard no [site oficial do Godot](https://godotengine.org/download/). Não é preciso instalar Python, Node, dependências ou export templates para jogar pelo editor.

```sh
godot --path .
godot --path . --scene res://scenes/combat_lab.tscn
```

## Controles da exploração

| Controle | Ação |
| --- | --- |
| WASD / setas | Andar sem diagonais; eixo mais recente tem prioridade. |
| Tab / Esc / Equipe | Menu de liderança; escolha um dos quatro integrantes. |
| E / botão contextual | Interagir com NPC, objeto, monstro ou entrada/saída mais próxima ao alcance. |
| E / Enter / Espaço / Avançar | Avançar ou encerrar falas. |
| 1 / 2 ou clique | Escolher resposta no diálogo do NPC 2. |
| F3 | Ver trilha, sólidos, rotas, alturas e painel de depuração do relógio. |
| Reiniciar teste | Restaurar explicitamente todas as áreas e os recursos iniciais. |

O jogo inicia na **vila**. A casa fica ao norte; o **portão a nordeste** usa E para sair ao mundo aberto. Ande à direita pela faixa inicial e depois suba pelo lado direito dos blocos. NPCs 4 e 5 estão nas ruas; NPCs 1–3 permanecem na casa. NPC 2 oferece duas respostas.

No **mundo aberto**, a interação **Entrar na vila** permite voltar. Para a dungeon, siga o caminho para leste, depois norte e novamente leste até a entrada de pedra. Use E para entrar. Mar, montanhas, colinas e massas florestais bloqueiam passagem. Um platô ao norte do marcador da vila tem **rampa**: contorne a vila pelo leste e siga o desvio à esquerda. **W/↑ sobe; S/↓ desce**, com altura gradual para cada integrante. Caminhos continuam livres; não há encontros no mundo. Detalhes em [RELEVO_E_FLORESTAS.md](docs/RELEVO_E_FLORESTAS.md).

Na **dungeon**, acione a alavanca junto da porta e atravesse para as outras salas. E perto de um monstro inicia combate; **M2 continua impedindo fuga**. Vitória remove só aquele encontro, fuga o mantém. Ao sair, você retorna ao mundo aberto. A casa não recupera HP/MP.

Roteiro e arquivos atuais em [VILA_E_MUNDO.md](docs/VILA_E_MUNDO.md). Câmera, profundidade e transições conservam os controles existentes.

## Relógio e dia/noite

As quatro áreas compartilham o horário, inicialmente **10:00**. **O tempo corre automaticamente somente no mapa-múndi** (mundo aberto fora da vila), sem ativar nenhuma opção. Um ciclo completo de 24 horas dura **2 minutos reais**. Vila, casa e dungeon mantêm o relógio pausado; viagens preservam o horário. Vila/mundo exibem luz cíclica; casa/dungeon usam luz fixa.

Abra **F3** para consultar horário/período e testar eventos **+180 min / 08:00** e **descanso → 07:00**. A antiga prévia automática foi removida. Clique nos campos para editar; confirmar/Enter libera o foco. Tab mantém o menu da equipe fora da edição. O descanso de teste só muda a hora.

O avanço depende de `area_type: "overworld"` e `time_advances: true`, fora das pausas de menu/diálogo/batalha/transição. Limites de períodos e apresentação são provisórios; duração de 120 segundos é a configuração aprovada agora. APIs e roteiro em [CICLO_DIA_NOITE.md](docs/CICLO_DIA_NOITE.md).

## O Segredo da Casa — dia e noite na vila

Há uma **segunda casa ao sul da praça**, com entrada e interior separados, e uma **pedra à direita dela**. De dia a pedra parece comum; à noite brilha e revela uma inscrição ao usar E. O **NPC 4** dá a dica, patrulha a praça de dia e fica perto da segunda casa à noite. Após descobrir, ele reconhece o segredo em qualquer horário. NPC 5 também muda sua fala. As janelas das duas casas e o poste acendem à noite.

Para testar naturalmente, saia ao mapa-múndi, espere a noite e volte à vila. De 10:00 a 19:00 são 45 segundos reais permitidos; a cidade pausa o relógio. Investigue a pedra, volte ao mundo até o dia e retorne: a descoberta permanece. **Reiniciar teste** limpa a sessão; não há save em disco nem recompensa. A casa original, seus NPCs e os demais sistemas continuam funcionando.

Configuração, arquivos e regras reutilizáveis em [EVENTOS_DIA_NOITE.md](docs/EVENTOS_DIA_NOITE.md).

## Controles do combate

Espere as barras carregarem, clique em um aliado **PRONTO** e escolha um comando. Em **Habilidades**, experimente alvo único, círculo e todos os inimigos. Use **F3** para observar a simulação e deixar aliados prontos imediatamente. **Atual · cantos / sem fuga** mantém o bloqueio para testar essa regra.

A nova versão já está em **todos os seis encontros da exploração**. O laboratório separado abre em **Atual · comportamento por semente**: terrestres sorteiam continuar ou inverter no mesmo caminho, freando e pausando antes de voltar; voadores também param para pairar; quantidade/duração de pausas variam pela semente. Inimigos mantêm atenção em um aliado e olham para o alvo durante o ataque. As outras quatro opções **Atual · …** têm formações diferentes, incluindo cantos, lados opostos e linha superior. Controles, tabela e dados em [COMBATE_SEMENTE.md](docs/COMBATE_SEMENTE.md).

As **dez opções anteriores** aparecem como **Legado**, incluindo F e as primeiras formações da dungeon. Nenhum encontro jogável as utiliza. Em **Active**, com **Pausa desligada**, observe o comportamento; F3 mostra semente, foco visual, fases, pausas e sorteios. Para comparar variações, mude **Semente** (por exemplo, 421 ou 733) e clique **Novo teste**. A mesma configuração/semente/comandos reproduz a simulação. O movimento dos monstros no mapa antes da batalha permanece igual.

Para testar habilidades de tela inteira com movimento atual, selecione **Atual · linha superior** e use **Habilidades → Onda**. Em F3, a linha **Centro** permite escolher qualquer participante e usar o padrão ou forçar centro/imobilidade. E1 móvel vai ao centro, E2 estático fica, E3 estático possui exceção habilitada. Efeito e alvos são independentes do deslocamento. Roteiro em [TELA_INTEIRA.md](docs/TELA_INTEIRA.md).

| Controle | Ação |
| --- | --- |
| Cartões / 1–4 | Escolher aliado pronto; durante seleção de item, escolher destinatário. |
| A / H / I / F | Atacar / Habilidades / Itens / Fugir. |
| Clique no campo ou nos botões de alvo | Escolher alvo; para área, fixar o centro do círculo. |
| Esc | Cancelar seleção sem gastar ação. |
| F3 | Depuração: ATB inimigo, coordenadas, rotas e decisões. |
| Espaço | Pausar/retomar manualmente. |
| Velocidade / Passo | Entre 0,25× e 4× ou avançar 1/60 s. O passo respeita Wait. |
| F5 na janela do jogo | Novo teste: restaurar recursos e reiniciar o preset escolhido. |

No **laboratório separado**, após vitória/fuga, **Próxima luta · manter HP/MP** inicia o preset escolhido sem restaurar recursos/estoque. **Novo teste/F5** restaura o laboratório; mudar o menu de preset só tem efeito ao iniciar uma luta. No **encontro da exploração**, o retorno é automático e esses controles de reinício ficam desativados. Nenhuma transição recupera recursos automaticamente.

## Documentação atual

- [Vila, mundo aberto, NPCs nas ruas e acessos da dungeon](docs/VILA_E_MUNDO.md).

- [Distribuição atual: exterior, casa com NPCs e mini dungeon](docs/INTERIORES_DUNGEON.md).
- [Câmera seguindo o líder e escala comum](docs/CAMERA_EXPLORACAO.md).
- [Profundidade, oclusão e bases sólidas do cenário](docs/PROFUNDIDADE_EXPLORACAO.md).
- [GDD](docs/GDD.md), [decisões confirmadas](docs/DECISOES.md) e [pendências](docs/PENDENCIAS.md).
- [Laboratório e roteiro de aceite](docs/LABORATORIO.md).
- [Exploração v0.2: arquivos, arquitetura, integração e testes](docs/EXPLORACAO_V02.md).
- [Mapa ampliado: encontros, NPCs, diálogos, objetos e roteiro de teste](docs/EXPLORACAO_INTERACOES.md).
- [Casa e exterior: transições reutilizáveis, estado por área e testes](docs/TRANSICOES_AREAS.md).
- [Escolhas técnicas experimentais](docs/DECISOES_TECNICAS.md).
- [Arquitetura implementada](docs/ARQUITETURA_LAB.md).
- [Curvas, aproximação melee e testes](docs/MOVIMENTO_E_MELEE.md).
- [Apresentação de tela inteira por participante](docs/TELA_INTEIRA.md).
- [Combate atual por semente, orientação e formações](docs/COMBATE_SEMENTE.md).
- [Dados editáveis](data/lab.json): valores provisórios, presets, perfis, itens e ações.

O pacote `RPG_Codex_Pacote/` é uma fotografia da importação. As fontes atuais ficam em `docs/` na raiz. O contexto original e a primeira arquitetura foram preservados como histórico; pendências antigas não substituem o GDD atual.

## Testes automatizados

Na pasta do projeto, com o executável Godot disponível como `godot`:

```sh
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/exploration_tests.gd
godot --headless --path . --script res://tests/exploration_ui_smoke.gd
godot --headless --path . --script res://tests/motion_tests.gd
godot --headless --path . --script res://tests/motion_ui_smoke.gd
godot --headless --path . --script res://tests/rhythm_tests.gd
godot --headless --path . --script res://tests/rhythm_ui_smoke.gd
godot --headless --path . --script res://tests/exploration_rhythm_tests.gd
godot --headless --path . --script res://tests/seeded_behavior_tests.gd
godot --headless --path . --script res://tests/seeded_behavior_ui_smoke.gd
godot --headless --path . --script res://tests/fullscreen_tests.gd
godot --headless --path . --script res://tests/fullscreen_ui_smoke.gd
godot --headless --path . --script res://tests/interaction_tests.gd
godot --headless --path . --script res://tests/interaction_ui_smoke.gd
godot --headless --path . --script res://tests/area_tests.gd
godot --headless --path . --script res://tests/area_ui_smoke.gd
godot --headless --path . --script res://tests/internal_areas_tests.gd
godot --headless --path . --script res://tests/internal_areas_ui_smoke.gd
godot --headless --path . --script res://tests/camera_tests.gd
godot --headless --path . --script res://tests/camera_ui_smoke.gd
godot --headless --path . --script res://tests/depth_tests.gd
godot --headless --path . --script res://tests/depth_ui_smoke.gd
godot --headless --path . --script res://tests/world_map_tests.gd
godot --headless --path . --script res://tests/world_map_ui_smoke.gd
godot --headless --path . --script res://tests/terrain_tests.gd
godot --headless --path . --script res://tests/terrain_ui_smoke.gd
godot --headless --path . --script res://tests/world_clock_tests.gd
godot --headless --path . --script res://tests/world_time_tests.gd
godot --headless --path . --script res://tests/day_lighting_tests.gd
godot --headless --path . --script res://tests/world_clock_ui_smoke.gd
godot --headless --path . --script res://tests/town_events_tests.gd
godot --headless --path . --script res://tests/town_events_ui_smoke.gd
```

As suítes validam laboratório, exploração/integração, curvas/melee, tela inteira, interações, transições e a distribuição atual das cinco áreas. As regressões de layouts anteriores usam fixtures exclusivas de teste; as suítes `internal_areas` e `world_map` usam os mapas reais do catálogo. Encerram com código diferente de zero se uma verificação falhar. Resultados em [VALIDACAO.md](docs/VALIDACAO.md). Validação em macOS; outras plataformas não foram verificadas.

História, missões, cidades completas, habilidades especiais de exploração, níveis, técnicas conjuntas e salvamento da aventura ficam fora desta versão.

Para verificar o custo do desenho e a transição em tempo real (com janela gráfica):

```sh
godot --path . --audio-driver Dummy --script res://tests/render_performance.gd
```

O teste reporta tempos e verifica que a origem da câmera é consultada apenas uma vez por desenho. Resultados da correção de lentidão em [VALIDACAO.md](docs/VALIDACAO.md).
