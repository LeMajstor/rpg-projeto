# Registro de decisões — RPG digital

**Atualizado em:** 25/10/2026. Use como índice rápido; detalhes completos em `GDD.md`.

## Confirmado para primeira versão / direção atual

| ID | Decisão |
|---|---|
| D01 | RPG digital de fantasia medieval; inspirações Breath of Fire **I** e Chrono Trigger, com identidade original. |
| D02 | Protagonista humano, homem ou mulher; jogador escolhe o nome, não cria um avatar livremente. |
| D03 | Elenco de companheiros fixos, recrutados ao longo da aventura. |
| D04 | Até quatro personagens ativos, mesmos na exploração e batalha. |
| D05 | Exploração com quatro sprites em fila; líder de exploração à frente. |
| D06 | Troca de líder somente pelo menu, persistente; sprite à frente muda. Habilidade de cenário exige personagem na equipe ativa e liderando a exploração. |
| D07 | Protagonista é foco narrativo e integrante obrigatório da equipe ativa na primeira versão; outros podem liderar a exploração. |
| D08 | Troca de membros ativos/reservas apenas em ponto especial de reunião. |
| D09 | Mapa-múndi sem inimigos comuns; masmorras/áreas de aventura com inimigos visíveis, parados ou móveis. Sem encontros aleatórios. |
| D10 | Batalha em tela separada para facilitar primeira versão; visual adequado à região/dungeon. |
| D11 | Cada encontro tem preset determinístico de cenário e posições iniciais, repetido quando encontro é refeito. Cenários podem ter várias variações por dungeon. |
| D12 | Posições lógicas dos aliados fixas por batalha (mudam conforme preset, não durante a luta); animações podem mover sprite temporariamente e devolvê-lo ao idle. Aliados podem girar para acompanhar inimigos. |
| D13 | Inimigos podem movimentar-se continuamente enquanto ATB enche em loops programados no preset; não navegam aleatoriamente; imóvel/móvel conforme tipo. |
| D14 | Ao agir, inimigo pausa e guarda ponto exato da rota; anima e retorna ao mesmo ponto para retomar deslocamento. |
| D15 | ATB com atributo INI: base fixa por personagem, não cresce a cada nível; modificadores temporários e acessórios/equipamentos. |
| D16 | ATB estaciona em 100% sem acúmulo de ações; jogador escolhe quem age entre aliados prontos; inimigos têm ATB oculto. |
| D17 | Modos Wait (pausa durante menus) e Active (tempo continua) selecionáveis e alteráveis pelo menu. |
| D18 | Comandos básicos Atacar, Habilidades, Itens e Fugir. Defender excluído. |
| D19 | HP e MP persistentes; habilidades físicas especiais também consomem MP; ataques comuns não. |
| D20 | Fuga é uma ação de um aliado, aplicável ao grupo inteiro; falha consome ação; certas batalhas impedem fuga. |
| D21 | Aliado com 0 HP não age e permanece incapacitado após vitória, até receber recuperação apropriada. |
| D22 | Game Over quando a equipe inteira é derrotada; carregar save. Salvamento apenas em pousadas e lugares especiais. |
| D23 | Habilidades terão alvos variados, inclusive áreas; posição dos inimigos importa. Geometrias específicas por definir. |
| D24 | IA de inimigos **sem agentes**, com regras e sorteio ponderado; perfis representam preferências, não escolhas estritas. |
| D25 | Godot + GDScript, aprovados explicitamente pelo usuário em 23/10/2026. |
| D26 | Primeira entrega jogável: laboratório de combate, priorizando mecânicas, quatro aliados, Wait/Active, comandos completos, três tipos de alvo, IA ponderada, rotas, dois presets e depuração. Sem exploração, missões, níveis ou técnicas conjuntas. Pedido explícito do usuário em 23/10/2026; recorte em `LABORATORIO.md`. |
| D27 | Versão jogável 0.2 autorizada: exploração top-down com movimento cardinal contínuo, sem diagonais, quatro integrantes seguindo o caminho do líder, sem colisão entre integrantes e com obstáculos sólidos para o líder; menu reorganiza liderança/fila. Inimigo visível inicia o combate existente; vitória/fuga devolvem ao mapa preservando HP/MP. Laboratório separado e testes de regressão obrigatórios. Sem história, missões, cidades completas, habilidades especiais de exploração ou sistemas adicionais. |
| D28 | Aprimorar o laboratório com rotas programadas suaves/amplas (terrestres coerentes, voadores rápidos/sinuosos/circulares e estáticos) e deslocamento temporário melee com chegada, efeito, retorno e retomada exata da rota. Movimento de rota e ataque separados; preservar posições lógicas, ATB, perfis e presets existentes. Somente representação visual provisória. |
| D29 | Técnicas de tela inteira podem levar o participante ao centro e retornar, conforme configuração individual. Personagens/móveis normalmente habilitados; estáticos normalmente não, com exceções. Preservar repouso, rota e melee; efeito independente da apresentação. Permitir alterações futuras por condição/estado, sem criar agora uma restrição narrativa para o protagonista. Somente apresentação provisória e testes configuráveis. |
| D30 | Ampliar o mesmo laboratório de exploração com cerca de 5–8 encontros visíveis usando presets existentes, estáticos/móveis; mais obstáculos e corredores estreitos; 4–5 NPCs estáticos/móveis; diálogos reutilizáveis com nome, múltiplas falas e respostas, bloqueando movimento; baú, placa, porta e alavanca com efeitos simples. Organizar pequenas regiões e testar interações e regressões. Sem mapa-múndi, vila completa, missões, inventário definitivo ou progressão narrativa. Autorizado em 24/10/2026; implementação de seis encontros e cinco NPCs em `EXPLORACAO_INTERACOES.md`. |
| D31 | Conectar pequena casa de teste ao laboratório externo por pontos de transição reutilizáveis em dados. Usar E/botão, fade simples, bloqueio de entrada durante transição e proteção contra retorno involuntário; validar destino/fila antes de abandonar origem. Preservar equipe, líder, ordem, recursos, objetos e encontros; reconstruir trilha local livre na chegada e retornar do combate à área correta. Para este protótipo, estados só em memória, reinício global explícito e patrulhas inativas pausadas. Manter porta local e laboratório independente. Sem mapa-múndi, vila, narrativa ou salvamento. Autorizado em 24/10/2026; ver `TRANSICOES_AREAS.md`. |
| D32 | NPCs e monstros somente em partes internas do protótipo; exterior com colisões e acessos. Transferir cinco NPCs para a casa e seis encontros existentes para uma mini dungeon ligada ao exterior, preservando os sistemas atuais. Placa na casa e baú/porta/alavanca na dungeon são escolhas provisórias de organização. A nova distribuição substitui a ocupação anterior do exterior; sem história, progressão ou mapa-múndi. Autorizado em 24/10/2026; ver `INTERIORES_DUNGEON.md`. |
| D33 | Câmera de exploração acompanha o líder da party, com escala comum à casa anterior, inclusive na dungeon. Substitui o ajuste para mostrar cada mapa inteiro. Limites de mapa, centralização de eixos curtos e seguimento imediato são escolhas técnicas provisórias; preservar HUD fixo, lógica e sistemas atuais. Autorizado em 24/10/2026; ver `CAMERA_EXPLORACAO.md`. |
| D34 | Exploração com profundidade: cenário pode encobrir quem passa atrás; personagens na frente aparecem sobre estruturas. Ordenar estruturas e atores pela base no chão, separando desenho elevado e colisão física; árvore usa base do tronco, não a copa. Preservar fila, câmera, interações, transições e combate. Dimensões, alturas e arte permanecem provisórias. Autorizado em 24/10/2026; ver `PROFUNDIDADE_EXPLORACAO.md`. |
| D35 | Antigo exterior torna-se vila/cidade de testes com casa e NPCs também nas ruas. Criar mundo aberto provisório com florestas, montanhas, colinas, mar e outros elementos simples, acessível ao sair da vila e com interação para reentrar nela. Dungeon acessada pelo mundo e retorna a ele. Fluxo casa↔vila↔mundo↔dungeon; sem acesso direto vila↔dungeon e sem monstros comuns no mundo aberto. Preservar sistemas, estados e gráficos provisórios. Substitui restrições anteriores de NPCs apenas em interiores/exterior só com colisões. Autorizado em 24/10/2026; ver `VILA_E_MUNDO.md`. |
| D36 | Colinas do mundo são barreiras para orientar/bloquear caminhos, com acesso apenas onde houver rampa e sensação gradual de subida/descida. Florestas são massas inteiras inacessíveis, sem passagem entre árvores. Preservar gráficos provisórios, fila e sistemas existentes. Substitui colinas livremente caminháveis e florestas permeáveis anteriores. Platô/rampa de teste, dimensões e projeção são escolhas técnicas experimentais. Autorizado em 24/10/2026; ver `RELEVO_E_FLORESTAS.md`. |
| D37 | Um relógio global preservado entre áreas; avanço natural somente em mapa-múndi explicitamente classificado/habilitado, pausado nas demais áreas. Períodos configuráveis, mudanças arbitrárias por eventos mesmo pausado, avanço em minutos, sinais e iluminação gradual separada da lógica. Início/limites/paleta são provisórios; a integração do mapa atual e a duração vigente estão em D39. Sem nova aventura, calendário, clima ou rotina complexa. Ver `CICLO_DIA_NOITE.md`. |
| D38 | Descansar em pousada sempre define 07:00 no relógio global, independentemente do horário anterior. Disponibilizar API temporal reutilizável, sem implementar pousada completa, pagamento, recuperação ou calendário nesta tarefa. Ver `CICLO_DIA_NOITE.md`. |
| D39 | O mundo aberto existente (`test_world`) passa a ser o mapa-múndi de testes, com avanço natural automático, sem ativar F3. Somente nele o tempo corre; vila, casa, dungeon e demais áreas não habilitadas permanecem pausadas. Ciclo completo de 24 horas em **2 minutos reais permitidos (120 segundos)**. Remover a prévia automática de F3 que permitia simular avanço em outras áreas; conservar consultas e operações explícitas de evento/descanso. Substitui a configuração inicial de 24 minutos e mapas todos pausados. |
| D40 | Eventos de horário na vila existente: preservar casa original e adicionar segunda casa/interior; pedra comum de dia, brilho/inscrição descoberta uma única vez à noite; morador reconhece a descoberta posteriormente em qualquer horário. NPCs existentes mudam posição e diálogo com segurança; janelas de ambas as casas e poste acendem à noite. Persistir descoberta entre horas/áreas/interações; regras declarativas separadas do relógio. Manter ciclo de 2 minutos só no mapa-múndi, câmera, controles e sistemas. Sem novos sprites, recompensas, combates, missões completas ou pathfinding. Ver `EVENTOS_DIA_NOITE.md`. |
| D41 | Ritmos programados dos inimigos dentro da batalha: aceleração/desaceleração suaves, pausas, ida e volta e velocidades por perfil de movimento do tipo com ajustes por encontro. ATB/INI e escolha ponderada de alvos independentes. Preservar A–D, exploração, melee/tela inteira e snapshot completo para retorno/retomada exatos. Novo preset E comparativo e depuração de velocidade/etapa/sentido/pausa; apresentação geométrica discreta. Parâmetros/tipos demonstrativos, sem navegação aleatória, perseguição ou reações a HP/dano. Autorizado em 25/10/2026; ver `RITMOS_BATALHA.md`. |
| D42 | Refinar ritmos com velocidades menores por tipo, mais repouso, retornos parciais e ritmo de volta diferente. Autorizar aproximações programadas dos inimigos aos aliados em alguns presets, com voadores em trajetórias mais amplas. E atualizado e F demonstra aproximações; manter A–D, exploração, posições aliadas, ATB/INI, alvos ponderados e retomada exata. Sem perseguição, dano por contato ou navegação aleatória; números e trajetórias são provisórios. Ver `RITMOS_BATALHA.md`. |
| D43 | Aplicar o modelo refinado de F a todos os seis encontros de batalha da exploração. Usar presets atuais com os perfis de movimento, preservando formações, composição/atributos, perfis de alvo, habilidades, cenário, estáticos/exceções e fuga. A–E são legados, sem referência pelos encontros jogáveis; laboratório independente inicia em F. Patrulhas no mapa permanecem inalteradas. Substitui a preservação anterior dos modelos legados na dungeon. Ver `RITMOS_BATALHA.md`. |
| D44 | Orientação visual: durante movimento/repouso, inimigos comuns buscam olhar para algum aliado válido; o mais próximo é referência flexível, sem regra absoluta de troca. Durante o ataque, olhar para o alvo da ação. Separar orientação de rota e seleção ponderada de alvos; permitir exceções configuráveis para casos/inimigos especiais, sem inventá-los. Implementado na versão por semente; escolhas técnicas em `COMBATE_SEMENTE.md`. |
| D45 | Terrestres podem sortear continuar ou inverter o sentido no mesmo caminho, por comportamento independente do preset. Inversão com desaceleração, pausa e retomada suave; orientação visual separada e ataques preservam progresso. Preset mantém rota/posições iniciais; sem navegação livre aleatória. Substitui a obrigação de sequência determinística para essa escolha de sentido. Implementado com pesos/tempos experimentais em dados. |
| D46 | Quantidade e duração das pausas de comportamento podem variar por sorteio determinado pela semente da batalha. Manter política no comportamento, independente do preset, e permitir reprodução nos testes sob mesma configuração/entradas. Não sortear formação/rotas. Preservar ATB e estado nas interrupções; implementado com faixas/limites experimentais em dados. |
| D47 | Implementar D44–D46 no laboratório e em todos os encontros de exploração. Todos os presets anteriores passam a legados; novas opções `lab_seeded` e `exploration_seeded_*` com formações variadas e fixas por luta. Comportamento por tipo, RNG de movimento por participante derivado da semente, voadores com repouso/pairar, inversões terrestres suaves e atenção visual independente da rota. Preservar ATB, perfis, recursos, regras de fuga, melee/tela inteira e retomada exata; parâmetros técnicos experimentais. Ver `COMBATE_SEMENTE.md`. |

Os parâmetros experimentais e escolhas técnicas do laboratório estão em `DECISOES_TECNICAS.md`. Sua adoção para testar não confirma balanceamento, perfis por inimigo definitivo ou direção artística.

## Propostas discutidas — precisam de especificação/aprovação fina

| ID | Proposta / observação |
|---|---|
| P01 | Seis perfis-base: Instintivo, Predador, Implacável, Retaliador, Caçador de Magos, Tático. A arquitetura por pesos está aceita; pesos/uso por inimigo não estão definidos. |
| P02 | Aproximadamente 3–4 variações visuais de campo por dungeon, vinculadas coerentemente a subáreas. |
| P03 | Habilidades de área circular, linha/faixa, alvo único e todos — formatos, raio e mira ainda a desenhar. |
| P04 | Implementar rota como waypoints/interpolação, sem exigir esta representação específica da engine. |

## Explicitamente para o FUTURO (não implementar agora)

| ID | Ideia adiada |
|---|---|
| F01 | No final da história, liberar formação ativa sem protagonista. |
| F02 | Missão especial opcional de cada companheiro (apenas com dono na equipe), conclusão do arco e recompensa. |
| F03 | Habilidades/técnicas conjuntas de 2+ integrantes com ATB cheio. |
| F04 | Combate diretamente no mapa da exploração. |
| F05 | IA de inimigos com mudanças de estado/reação à evolução da luta (medo, fúria etc.). |

## Exemplos NÃO definitivos

- Guerreiro, ladino, mago, bárbaro e possíveis raças humano, elfo, anão, orc.
- Slime, lobo, feiticeiro etc. são ilustrações de personalidades, não fichas de monstros.
- Números, velocidades, posições demonstrativas e porcentagens usadas em conversas não são valores aprovados.
