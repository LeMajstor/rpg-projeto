# Instruções permanentes para o Codex — projeto RPG digital

## Papel

Trabalhe como parceiro de implementação e arquitetura de um RPG digital de fantasia medieval. O usuário é o diretor criativo e valida as decisões de design. Não converta sugestões em requisitos definitivos.

## Fontes do projeto

Antes de propor ou alterar sistemas, leia:
- `docs/GDD.md` — regras de jogo e comportamento esperado.
- `docs/DECISOES.md` — status das decisões.
- `docs/PENDENCIAS.md` — escolhas não resolvidas e ideias adiadas.

Ao receber novas decisões do usuário, atualize os documentos afetados junto com o código relevante. Em caso de conflito, explique o conflito e solicite uma decisão antes de implementar comportamento incompatível.

## Regras de trabalho

1. **Não comece a programar um jogo inteiro por conta própria.** Primeiro examine o repositório. Se for novo, proponha uma estrutura mínima e peça uma decisão sobre engine/linguagem, plataforma-alvo e escopo do primeiro protótipo.
2. Distinga sempre: **confirmado**, **recomendação**, **exemplo**, **pendente** e **futuro/fora de escopo**.
3. Priorize separação entre dados e lógica: personagens, inimigos, perfis de seleção de alvos, encontros, presets de batalha e trajetórias devem ser preferencialmente configuráveis em dados.
4. Prefira código determinístico/testável para presets de encontro. Para sorteios ponderados de comportamento, use uma fonte de aleatoriedade controlável por semente durante testes.
5. Evite complexidade extra: sem agentes de IA, aprendizado de máquina, redes, geração procedural, simuladores de física ou sistemas de combate tático por grade, salvo decisão posterior expressa.
6. Não inclua mecânicas de versões futuras como requisito da primeira versão (técnicas conjuntas, arcos finais de companheiros, equipe sem protagonista etc.).
7. Para cada sistema implementado, produza testes úteis e descreva como executar/verificar. Não afirme que testes passaram se não foram executados.
8. Quando surgir uma lacuna essencial, apresente opções curtas com consequências. Não assuma números definitivos de atributos, custos de MP, fórmulas, duração, coordenadas ou porcentagens.
9. Preserve a distinção entre **posição lógica da batalha**, **posição visual durante animação** e **progresso em trajetória**.
10. Use assets originais/provisórios licenciados; não copie sprites, mapas, músicas ou conteúdo de jogos de referência.

## Invariantes aprovados

- Equipe ativa: até 4 integrantes; são os mesmos que combatem e aparecem na exploração.
- Protagonista humano, nome e gênero escolhidos, obrigatório na equipe durante a história principal nesta primeira versão.
- Companheiros fixos recrutados pela história; reservas só são trocadas no local especial de reunião.
- Exploração em fila; troca de líder de exploração **somente pelo menu**, persistente até nova escolha; troca o sprite da frente. Para executar habilidade de cenário, personagem deve estar ativo e ser líder da exploração.
- Protagonista permanece foco narrativo das cenas principais, mesmo que outro personagem lidere o mapa.
- Sem encontros aleatórios. Mapa-múndi não tem inimigos comuns; áreas exploráveis/masmorras têm inimigos visíveis, alguns móveis, alguns parados; batalhas narrativas podem ser obrigatórias.
- Primeira versão: combate em **tela separada**, com cenário coerente com a dungeon e **preset determinístico por encontro**. Um reencontro com o mesmo encontro reproduz cenário e posições iniciais.
- Aliados têm posições lógicas fixas por batalha, definidas pelo preset. Podem orientar-se visualmente para inimigos e deslocar sprites durante animações, mas devem voltar à mesma posição lógica/idle. Nenhuma ação ou efeito do cenário muda a posição lógica dos aliados.
- Inimigos móveis seguem rotas definidas pelo preset enquanto ATB enche, sem navegação livre aleatória; D45/D46 permitem sorteio de sentido e pausas dentro dessas rotas. Movimentos podem ser estáticos, terrestres curtos ou mais amplos (ex.: voadores). Ações pausam a rota, preservam segmento e progresso exatos, permitem animação e retornam ao ponto para retomada.
- ATB individual, velocidade derivada da INI efetiva. INI base fixa por personagem, **não cresce com nível**; equipamentos/acessórios e efeitos temporários podem alterá-la. Barra para em 100%; sem múltiplas ações acumuladas; jogador escolhe entre aliados prontos. ATB de inimigos oculto.
- Configuração Wait/Active alterável no menu. Wait pausa progressão temporal e movimento durante seleção de comandos; Active mantém progressão e movimento durante a seleção. Detalhes finos ainda carecem de desenho.
- Comandos: Atacar, Habilidades, Itens e Fugir. **Não há comando Defender** na primeira versão.
- HP e MP persistem entre batalhas. Habilidades mágicas **e físicas especiais** consomem MP; ataques básicos não. Com 0 HP, personagem fica incapacitado e continua assim após a vitória até ser revivido/recuperado.
- Fugir: ação individual que tenta retirar o grupo inteiro; falha consome ação do personagem. Certas batalhas impedem fuga. Probabilidade ainda indefinida.
- Equipe toda em 0 HP: Game Over tradicional, recarregar salvamento. Salvar só em pousadas e pontos específicos de progresso, eventualmente antes de chefes, não obrigatoriamente.
- IA de inimigos **programática baseada em regras/pesos**, sem agentes de IA. Preferências de alvo não são escolhas absolutas. Perfis candidatos em `docs/GDD.md`; pesos/fórmulas não definidos.

## Escopo excluído agora

- Grupo ativo sem protagonista, desbloqueado apenas perto do fim narrativo; missões pessoais opcionais dos companheiros, recompensas especiais e técnicas combinadas em dupla/grupo são ideias para depois, não parte da primeira entrega.
- Não inventar classes, raças, inimigos definitivos, história, balanceamento ou regras de progressão não discutidas.

## Autorização e estágio atual

Godot + GDScript e o laboratório de combate foram autorizados pelo usuário em 23/10/2026. O recorte vigente está em `docs/LABORATORIO.md`; escolhas técnicas experimentais estão em `docs/DECISOES_TECNICAS.md`. O pacote `RPG_Codex_Pacote/` é uma fotografia de importação; as fontes atuais ficam em `docs/` na raiz. Não voltar a pedir aprovação para o escopo já autorizado.

A versão jogável 0.2 também foi autorizada: mapa pequeno com movimento cardinal contínuo, quatro integrantes em fila reproduzindo o caminho do líder, colisão do líder, troca de liderança no menu, encontro visível e ida/retorno ao combate existente mantendo HP/MP. Ver `docs/EXPLORACAO_V02.md`. Preservar acesso independente ao laboratório. Sem história, missões, cidades, habilidades especiais de exploração ou sistemas adicionais.

O usuário também autorizou curvas/percursos amplos programados e aproximação/impacto/retorno melee provisórios no laboratório, com preservação exata de posições lógicas e progresso de rota. Ver `docs/MOVIMENTO_E_MELEE.md`. Manter os dois movimentos separados, sem navegação aleatória nem animação artística definitiva; preservar ATB, perfis e presets A/B.

Técnicas de tela inteira têm apresentação ao centro controlada individualmente por `move_to_center_for_fullscreen_skill`, com alteração temporária opcional. Ver `docs/TELA_INTEIRA.md`. Preservar efeito independente da apresentação, retorno/rota exatos e melee. Não criar a condição narrativa futura do protagonista nem conteúdo de chefe definitivo.

O laboratório de exploração foi ampliado por autorização de 24/10/2026: seis encontros usando presets existentes, cinco NPCs, diálogos com respostas e pausa do mapa, obstáculos/corredores e baú/placa/porta/alavanca. Ver `docs/EXPLORACAO_INTERACOES.md`. Manter no mesmo mapa/cena; efeitos e falas de teste, sem missão, inventário definitivo, vila ou progressão narrativa. Preservar fila, liderança pelo menu, recursos e combate compartilhado.

Também foi autorizada a conexão de uma pequena casa de teste ao mapa externo, com transições por E, fade, entradas reutilizáveis em dados e validação de espaço para os quatro. Ver `docs/TRANSICOES_AREAS.md`. Preservar estados por área em memória, recursos/equipe globais e retorno do combate na área correta; pausar patrulhas inativas, reconstruir trilha local segura e impedir transições duplicadas/retorno involuntário. Reinício restaura todas as áreas. A porta/alavanca locais permanecem; sem mapa-múndi, vila, conteúdo narrativo ou salvamento.

Distribuição atual autorizada em 24/10/2026: NPCs e monstros apenas nos interiores. Exterior só com colisões e acessos; cinco NPCs na casa de testes e seis encontros existentes na mini dungeon. Ver `docs/INTERIORES_DUNGEON.md`. Isso substitui a distribuição anterior no exterior; preservar diálogos, rotas, combate, equipe e estados por área. Placa na casa e baú/porta/alavanca na dungeon são organização técnica provisória. Fixtures antigas existem somente em testes, nunca no catálogo jogável.

Câmera da exploração acompanha o líder, com escala comum baseada na distância anterior da casa; não reduzir dungeon/mapas maiores para mostrar tudo. Ver `docs/CAMERA_EXPLORACAO.md`. Manter HUD/diálogos fixos, recorte da área de desenho e separação entre câmera visual e posição lógica. Limites de mapa e centralização de eixos que cabem são escolhas provisórias.

Profundidade na exploração: estruturas encobrem quem passa atrás e ficam atrás de quem passa à frente. Ver `docs/PROFUNDIDADE_EXPLORACAO.md`. Separar base sólida no chão de copa/altura visual; ordenar cenário e cada ator pela base, preservando câmera, fila e sistemas anteriores. Árvores usam colisão do tronco; dimensões/alturas e formas permanecem provisórias. Não transformar esse efeito visual em mudanças de posição lógica ou de combate.

Escopo vigente autorizado em 24/10/2026: o antigo exterior representa uma vila/cidade de testes, com NPCs na casa e nas ruas. Fluxo casa↔vila↔mundo aberto↔mini dungeon; saída/retorno à vila por interação, dungeon somente acessada pelo mundo e retorna a ele. Ver `docs/VILA_E_MUNDO.md`. Isso substitui as restrições anteriores de NPCs só em interiores/exterior só com colisões. Paisagem do mundo com florestas, montanhas, colinas, mar e caminhos simples, sem monstros comuns. Manter gráficos provisórios e sistemas existentes; sem história, economia, missões ou salvamento adicionais.

Relevo do mundo autorizado em 24/10/2026: colinas bloqueiam passagem pelas bordas; rampas explícitas dão subida/descida gradual aos quatro integrantes. Florestas do mundo são massas inteiras inacessíveis; árvores isoladas continuam com base do tronco. Ver `docs/RELEVO_E_FLORESTAS.md`. Isso substitui colinas caminháveis e florestas permeáveis. Geometria/alturas/rampa sul são escolhas técnicas provisórias; não implementar salto/queda, travessia por habilidades ou arte definitiva. Preservar trilha lógica, câmera, transições e combate.

Ciclo de dia/noite autorizado em 24/10/2026: um relógio por sessão, preservado entre áreas/combate, com avanço natural somente em área explicitamente `overworld` e `time_advances: true`. O usuário agora autorizou classificar `test_world` (mundo aberto fora da vila) como mapa-múndi: nele o tempo corre automaticamente, sem F3. Vila, casa e dungeon permanecem pausadas. Ciclo completo de 24 horas dura **120 segundos reais permitidos (2 minutos)**, por decisão expressa. A antiga prévia automática de F3 foi removida para não fazer o tempo correr nas outras áreas. Eventos podem definir/avançar horário mesmo pausado; descanso sempre define 07:00, sem cura/pagamento/pousada completa. Ver `docs/CICLO_DIA_NOITE.md`. Início 10:00 e limites/paleta são provisórios; duração de 2 minutos está confirmada para a configuração atual. Preservar iluminação separada da lógica, sinais, foco/controles, câmera otimizada e combate; sem calendário, clima, rotina complexa ou nova aventura.

Autorizados eventos diurnos/noturnos na vila existente: segunda casa com interior separado e evento O Segredo da Casa. Pedra só revela inscrição à noite, registra flag uma vez e morador reconhece depois em qualquer horário. NPC 4 tem posicionamento por período e diálogo por flag; NPC 5 mantém diálogo por horário; casa original/funções anteriores preservadas. Duas casas com janelas noturnas e poste com halo, somente geometria, sem novos sprites. Ver `docs/EVENTOS_DIA_NOITE.md`. Regras em dados e flags na sessão; adiar reposicionamento durante diálogo/menu/cutscene ou destino ocupado/inválido. Descoberta persiste em memória entre áreas/horários até Reiniciar teste; não implementar save, recompensa, missão completa, rotina complexa, pathfinding ou combate novo. Relógio/mapa-múndi/ciclo de 2 minutos permanecem iguais. O catálogo agora tem cinco áreas.

Ritmos de movimento dos inimigos **somente dentro da batalha** autorizados em 25/10/2026: aceleração/desaceleração suaves, pausas com ATB ativo, ida e volta e velocidades por perfil do tipo, ajustáveis por encontro. Ver `docs/RITMOS_BATALHA.md`. Novo preset E compara pesado/ágil/voador/estático; A–D, exploração, perfis de alvo e INI permanecem. Snapshot preserva ritmo completo e fase visual durante melee/tela inteira, com retorno e retomada exatos. Inclinação/flutuação são provisórias e independentes dos efeitos de área. Sem navegação aleatória, perseguição, reações a HP/dano ou arte definitiva.

Refinamento dos ritmos autorizado: velocidades menores por tipo, mais repousos, sequências com retornos parciais e ida/volta com ritmos diferentes. Alguns presets podem aproximar inimigos dos aliados; voadores podem percorrer trajetórias amplas próximas ao grupo. E atualizado; novo F (`lab_approach`) demonstra aproximações, mantendo A–D e exploração. Ver `docs/RITMOS_BATALHA.md`. Preservar aliados fixos, ATB/INI e snapshot completo; sem perseguição, movimento aleatório ou dano automático por contato. Coordenadas, velocidades e durações seguem provisórias.

Etapa anterior, substituída pela versão por semente descrita ao final: aplicar o modelo refinado de F a **todos os encontros de batalha da exploração**. Os seis encontros da dungeon usam `exploration_open`, `exploration_clustered`, `exploration_motion` e `exploration_fullscreen`, com ritmos por tipo e voos amplos. Preservar formações iniciais, quantidade/atributos, perfis de alvo, habilidades, cenário, estáticos/exceções de centro e fuga (M2 bloqueada). A–E são referências **legadas**, sem uso pelos encontros do catálogo jogável; início do laboratório independente em F por `default_preset_id`, identificação por `legacy_preset_ids`. Isso substitui a exigência anterior de manter A–D nos encontros atuais. Patrulhas do mapa não mudam. Ver `docs/RITMOS_BATALHA.md`.

Orientação visual confirmada, implementada na versão por semente: inimigos comuns buscam manter a atenção em algum aliado válido no movimento/repouso, independentemente do deslocamento. O mais próximo é referência flexível, sem obrigação de troca constante. Durante o ataque, olhar para o alvo da ação. Orientação não muda a escolha ponderada do alvo; permitir exceções configuráveis para casos/inimigos especiais sem criar conteúdo novo. Foco estável enquanto válido; ações sem alvo individual usam referência viva próxima da posição visual, sem limitar atingidos. Ver D44 e `docs/RITMOS_BATALHA.md`.

D45 confirmado e implementado: terrestres em batalha podem sortear continuar ou inverter o sentido no mesmo caminho; decisão pertence ao comportamento, independente do preset (não colocar pesos/gatilhos de escolha no encontro). Inverter com desaceleração, pausa e aceleração suave. Preset continua definindo rota e formação inicial; permitir esse sorteio não autoriza navegação livre aleatória, novos caminhos ou perseguição. Isso substitui a sequência obrigatoriamente programada apenas para essa escolha. Olhar segue D44, separado do deslocamento; preservar progresso/estado durante ataques. Pesos, intervalos e durações são parâmetros técnicos experimentais da versão por semente.

D46 confirmado e implementado: quantidade e duração das pausas de comportamento podem variar por sorteio determinado pela semente da batalha. Política no comportamento, independente do preset. Preservar geometria/formação, ATB e estado nas interrupções; mesma semente/configuração/entradas deve permitir reprodução nos testes. Faixas, frequência e limites por tipo são parâmetros técnicos experimentais, sem números definitivos.

Versão vigente autorizada e implementada: `lab_seeded` é o padrão; todos os dez presets anteriores são legados. Todos os seis encontros da exploração usam `exploration_seeded_*`, com formações diferentes (aberta, cantos, lados opostos e linha superior) e posições fixas por batalha. D44–D46 implementados: atenção visual em aliado, alvo efetivo durante ação, sorteios de sentido/pausas por comportamento do tipo e semente, desaceleração/pausa/aceleração, voadores pairando. RNG de movimento por participante em estado copiável separado do RNG de ações/alvos; snapshots preservam tudo. Preset não sobrescreve política/pesos de movimento. Parâmetros experimentais em dados; sem navegação livre, conteúdo especial novo ou mudanças nas patrulhas do mapa. Ver `docs/COMBATE_SEMENTE.md`.
