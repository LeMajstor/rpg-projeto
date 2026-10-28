# Game Design Document (GDD) — RPG digital

**Versão:** 0.2 (laboratório e protótipo integrado de exploração)  
**Data:** 27/10/2026

**Status:** Godot + GDScript confirmados. Laboratório de combate e protótipo integrado de exploração v0.2 autorizados; detalhes em [LABORATORIO.md](LABORATORIO.md) e [EXPLORACAO_V02.md](EXPLORACAO_V02.md). Plataforma comercial, orçamento e arte definitiva continuam abertos. Testes locais em desktop são uma escolha operacional.

## 1. Visão e pilares

RPG digital de fantasia medieval, magia, raças e classes, inspirado na sensação de aventura de *Breath of Fire I* e *Chrono Trigger*; não será cópia das obras. A história existe como premissa inicial, mas seu conteúdo ainda será refinado.

**Pilares de experiência:**
1. Companheiros **fazem diferença na exploração**, abrindo caminhos a partir de capacidades próprias.
2. Elenco fixo recrutado ao longo da história, com motivações e importância narrativa próprias.
3. Batalhas por ATB com decisões significativas, posicionamento de inimigos e habilidades com alvos/áreas.
4. Gestão clássica de recursos (HP/MP), salvamentos limitados e encontros desenhados intencionalmente.
5. Mecânicas simples inicialmente, com espaço para expansão futura.

## 2. Mundo, elenco e progressão do grupo

### 2.1 Ambientação
- Fantasia medieval com magia e classes.
- Classes **mencionadas como possibilidades**, não confirmadas: guerreiro, ladino, mago e bárbaro.
- Raças **mencionadas como possibilidades**, não elenco definido: humano, elfo, anão e talvez orc.
- História, nomes, mundo, facções, mapa, arte e tamanho do elenco **não definidos**.

### 2.2 Protagonista
- Humano, com escolha de nome e gênero (homem ou mulher); sem criação livre de personagem.
- É o **líder narrativo** durante a história principal: cenas e diálogos importantes devem dar-lhe destaque, mesmo se outro estiver à frente no mapa.
- **Obrigatório na equipe ativa** durante a história principal na primeira versão.

### 2.3 Companheiros e equipe
- **Direção confirmada para o segundo aliado (D81, 27/10/2026):** usar **arco composto** e **conjunto de couro**, favorecendo críticos, INI maior e esquiva, com menor proteção física/resistência ao ser atingido que o Aliado #1. D82 refina: CRI/EVA próprios levemente maiores, HP menor e MP levemente maior; arco com maior chance de crítico e multiplicador 1,6× (D83). D84 autoriza e implementa a ficha discutida em P06 como preset de teste **Aliado #2**, descrito em [ALIADO_02.md](ALIADO_02.md), com arco/couro e EVA própria + bônus separados. Técnicas/progressão continuam pendentes. Não definir automaticamente classe, raça, identidade, regras de alcance/munição ou novos atributos; implementação restrita ao laboratório de danos, sem migração à exploração.
- Companheiros são personagens fixos, recrutados gradualmente conforme a história.
- Equipe ativa tem **até quatro** membros; estes são os quatro que participam das batalhas.
- **D70 (27/10/2026):** no início da aventura, o protagonista estará sozinho. Com apenas um integrante ativo, chegar a 0 HP significa derrota de toda a equipe e Game Over pela regra geral. Essa definição da aventura não altera automaticamente a equipe de quatro do protótipo atual.
- Os mesmos integrantes aparecem em fila na exploração: líder de exploração à frente; os demais atrás.
- Personagens fora da equipe ativa permanecem na reserva e **somente podem substituir ativos num local especial de reunião**, ainda sem identidade narrativa, aparência ou nome aprovado. A referência conceitual é o Fim dos Tempos de Chrono Trigger, sem copiá-lo.
- O protagonista pode futuramente deixar de ser obrigatório em um segmento final da história; **fora do escopo da primeira versão**.

## 3. Exploração e habilidades de cenário

- O jogador controla diretamente o **líder de exploração**, representado por seu próprio sprite à frente da fila.
- Na v0.2, os três seguidores reproduzem o caminho percorrido pelo líder. Movimento contínuo em quatro direções, sem diagonais. O líder respeita obstáculos sólidos; integrantes não colidem entre si. A implementação experimental usa histórico de caminho e distância, detalhada em `EXPLORACAO_V02.md`.
- Troca de líder **apenas pelo menu**, não por botão rápido. Depois de escolhido, ele permanece à frente até outra troca.
- Para usar uma capacidade única que afeta o cenário, seu personagem precisa (a) estar entre os quatro ativos e (b) ser líder de exploração.
- Exemplo inspirador: Bo de *Breath of Fire I* consegue atravessar determinadas florestas. Não copiar literalmente esse personagem.
- Habilidades podem abrir caminhos, segredos e obstáculos; concretizações por classe/personagem ainda não aprovadas.
- Diferenciar ao projetar mapas o uso de habilidades para progresso obrigatório e para exploração opcional, de modo a reduzir retorno frustrante ao ponto de troca de equipe.
- O protótipo v0.2 não implementa habilidades especiais de exploração, história, missões ou cidades completas. A expansão atual inclui uma vila de testes, mundo aberto provisório, casa e mini dungeon. Encontros visíveis iniciam a batalha existente; vitória/fuga bem-sucedida devolvem ao mapa com HP/MP preservados. O laboratório continua acessível separadamente.

### 3.1 Ampliação autorizada do laboratório de exploração

O mesmo mapa de testes recebe aproximadamente 5–8 encontros visíveis com diferentes presets existentes, alguns parados e outros em rotas simples; paredes, árvores, pedras e corredores estreitos; 4–5 NPCs de teste, imóveis e móveis; diálogos com nome, múltiplas falas, avanço por botão e opções de resposta; baú, placa, porta e alavanca com efeitos simples.

Movimento bloqueado durante diálogos. NPCs, falas e objetos devem ser reutilizáveis, com gráficos provisórios e testes. Regiões pequenas permitem testar os sistemas separadamente. Não há mapa-múndi, vila completa, missões, inventário definitivo ou progressão narrativa. A implementação usa seis encontros e cinco NPCs; detalhes e escolhas técnicas experimentais em [EXPLORACAO_INTERACOES.md](EXPLORACAO_INTERACOES.md).

### 3.2 Transições entre áreas de teste

Autorizado conectar uma pequena casa provisória ao laboratório externo existente. Entrada e saída por E/botão contextual; pontos reutilizáveis em dados referenciam área e entrada de destino, com posição e direção de chegada. Transição visual simples bloqueia movimento e interações, com proteção contra retorno imediato involuntário.

Preservar integrantes, líder, ordem, HP/MP e recursos compartilhados, estados de objetos e encontros vencidos. Na chegada, reconstruir a fila inteira em trecho local livre, sem reutilizar coordenadas da área anterior. Combate retorna à área onde começou. Validar destino antes de sair; erro não perde estado nem prende controles. Menu, diálogo e batalha bloqueiam transições.

Neste protótipo, estados ficam em memória até reinício explícito e patrulhas de áreas inativas ficam pausadas com progresso preservado. São escolhas técnicas provisórias. A porta/alavanca existentes continuam com colisão local. Não há mapa-múndi, vila, narrativa ou salvamento em disco. Dados e testes em [TRANSICOES_AREAS.md](TRANSICOES_AREAS.md).

### 3.3 Distribuição anterior dos laboratórios por área

Na etapa anterior, NPCs e monstros ficavam em interiores, e o exterior continha apenas obstáculos sólidos e acessos. Essa distribuição foi substituída pela seção 3.6: o exterior atual representa uma vila, NPCs podem estar nas ruas e a dungeon fica no mundo aberto.

Preservar diálogos, rotas programadas, fila, liderança, HP/MP, combate e estados por área. Como escolha técnica provisória, a placa foi colocada na casa e baú/porta/alavanca na dungeon. A dungeon usa salas e corredores de teste; não define história, vila, mapa-múndi, progressão ou conteúdo definitivo. A distribuição anterior no exterior foi substituída. Roteiro em [INTERIORES_DUNGEON.md](INTERIORES_DUNGEON.md).

### 3.4 Câmera da exploração

A câmera acompanha o personagem que lidera a fila. Dungeon, casa e exterior usam a mesma escala visual, tomando como referência a distância anterior da casa; mapas maiores não devem ser reduzidos para caber inteiros na tela.

Na implementação provisória, o enquadramento respeita as bordas do mapa; eixos que cabem inteiros na janela permanecem centralizados. HUD e diálogos ficam fixos. Câmera e projeção não alteram coordenadas lógicas, colisões, fila, rotas ou combate. Configuração, escolhas técnicas e testes em [CAMERA_EXPLORACAO.md](CAMERA_EXPLORACAO.md).

### 3.5 Profundidade visual na exploração

Árvores, casas, paredes e outras estruturas devem ter volume visual e encobrir personagens que passam atrás, enquanto quem passa à frente aparece sobre elas. O cenário e cada integrante da fila compartilham uma ordenação por base no chão; NPCs, monstros e objetos locais seguem a mesma regra.

Separar a base física ocupada no chão da parte visual elevada. A copa não é uma parede invisível: a colisão da árvore corresponde ao tronco/base. Fundações, paredes e portas mantêm seus volumes sólidos. Alturas, larguras e desenhos são provisórios, sem arte definitiva ou mudança nas regras do combate. Configuração e testes em [PROFUNDIDADE_EXPLORACAO.md](PROFUNDIDADE_EXPLORACAO.md).

### 3.6 Vila de testes e mundo aberto

O antigo mapa externo passa a representar uma vila/cidade de testes. A casa permanece na vila; NPCs podem ficar tanto dentro dela quanto nas ruas e praças. Essa autorização substitui a restrição anterior de NPCs apenas nos interiores.

Sair da vila leva ao mundo aberto, que possui uma interação para retornar à vila. A mini dungeon passa a ser acessada pelo mundo aberto, e sua saída retorna para esse mundo. Fluxo: **casa ↔ vila ↔ mundo aberto ↔ mini dungeon**. Não há acesso direto vila↔dungeon.

O mundo aberto usa representações simples de florestas, montanhas, colinas, mar e outros elementos de paisagem. Manter a pegada provisória dos gráficos, sem sprites elaborados. Preservar câmera, profundidade, movimento cardinal, fila, liderança, diálogos, combate e estados entre áreas. O mundo aberto permanece sem monstros comuns e sem encontros aleatórios.

Na implementação de teste, os mesmos cinco NPCs foram distribuídos entre três na casa e dois na vila. Caminhos são caminháveis; mar/montanhas são sólidos. Colinas e massas florestais seguem a seção 3.7, que substitui a travessia livre anterior. São escolhas técnicas provisórias; sem habilidades de navegação, história, missões, economia, progressão ou salvamento novos. Configuração e testes em [VILA_E_MUNDO.md](VILA_E_MUNDO.md).

### 3.7 Colinas, rampas e massas florestais

**Confirmado:** colinas são obstáculos que guiam/bloqueiam o acesso a regiões do mundo; não se atravessa o paredão. Acesso por rampa deve dar sensação gradual de subida e permitir descer. Florestas do mapa-múndi são regiões inteiras inacessíveis, incluindo os espaços entre árvores. Árvores isoladas da vila continuam colidindo apenas na base. Preservar gráficos provisórios, controles, câmera e os quatro integrantes na trilha.

**Escolha técnica experimental:** um platô com rampa ao sul e uma colina sem acesso demonstram os dois casos. Bordas e laterais da rampa são sólidas; cada integrante recebe altura visual conforme sua posição no mesmo caminho. Não há salto/queda nem travessia sob o relevo. Coordenadas, alturas e dimensões são ajustáveis, sem definir geografia final ou habilidades futuras. Detalhes em [RELEVO_E_FLORESTAS.md](RELEVO_E_FLORESTAS.md).


### 3.8 Relógio global e ciclo de dia/noite

**Confirmado:** um horário global compartilhado entre áreas; avanço automático exclusivamente em mapa-múndi explicitamente classificado/habilitado. Cidades/vilas, interiores, castelos, cavernas, dungeons e áreas não classificadas mantêm o relógio pausado, mesmo quando visualmente externas. Eventos/cutscenes podem definir qualquer horário ou avançar minutos enquanto estiver pausado, notificando interessados. Horário atravessa meia-noite, períodos e viagens; amanhecer/dia/entardecer/noite são configuráveis. Iluminação varia gradualmente na camada visual com interface legível.

**Descanso confirmado:** toda operação de pousada define **07:00**, independentemente da hora anterior. Nesta entrega a API é apenas temporal; cura, pagamento, pousada completa, narrativa completa, calendário e salvamento continuam fora do recorte.

**Atualização confirmada:** o mundo aberto de testes (`test_world`) agora é o mapa-múndi do protótipo, com avanço natural automático, sem ativar F3. O ciclo completo de 24 horas dura **2 minutos reais permitidos (120 segundos)**. Vila, casa e dungeon continuam pausadas. A prévia automática de F3 foi removida; o painel mantém consultas e operações explícitas de teste. **Parâmetros ainda provisórios:** início 10:00; amanhecer 05–07, dia 07–17, entardecer 17–19, noite 19–05. A sessão possui a instância única; cidade/mundo de teste usam luz cíclica e interiores luz fixa como escolha técnica. APIs, configurações e testes em [CICLO_DIA_NOITE.md](CICLO_DIA_NOITE.md).


### 3.9 Eventos de horário na vila — O Segredo da Casa

**Confirmado:** preservar a casa original e acrescentar uma segunda casa com interior separado, paredes/móveis provisórios, entrada/saída por E/botão. Uma pedra próxima é comum de dia e brilha à noite; só à noite revela uma inscrição. A descoberta é única e permanece entre horários, áreas e novas interações. O morador reconhece a descoberta em qualquer período. Sem recompensa, missão completa ou combate novo.

NPCs existentes demonstram posição diurna/noturna e diálogos diferentes, preservando funções anteriores. Mudanças de horário atualizam com segurança, sem duplicação, posições inválidas ou troca do interlocutor durante conversa/cutscene. Janelas das duas casas e um poste acendem à noite, com formas geométricas e halo discreto. Sem novos sprites, pathfinding, rotinas complexas, calendário ou clima.

**Escolhas técnicas provisórias:** NPC 4 patrulha a praça de dia e fica próximo da segunda casa à noite; NPC 5 mantém a função de diálogo por horário. `story_flags` na sessão registra a descoberta até Reiniciar teste, coerente com a persistência em memória já existente. Regras declarativas ficam nos dados; relógio e modelo de diálogo não recebem regras específicas da pedra. Topologia passa a cinco áreas: duas casas↔vila↔mapa-múndi↔dungeon. Câmera, combate, relógio de 2 minutos e pausas continuam iguais. Configuração e roteiro em [EVENTOS_DIA_NOITE.md](EVENTOS_DIA_NOITE.md).

## 4. Estrutura de encontros

- **Não haverá encontros aleatórios** no mapa-múndi nem nas dungeons.
- Mapa-múndi: sem inimigos comuns, salvo conflitos iniciados por eventos narrativos.
- Dungeons e áreas exploráveis como florestas/cavernas: inimigos visíveis no cenário; podem estar imóveis ou se movimentar.
- O jogador em geral pode evitá-los, mas alguns podem bloquear passagens e confrontos narrativos podem ser obrigatórios.
- A transição leva a uma **tela de batalha separada** na primeira versão. Combate diretamente no mapa é desejo futuro, não compromisso atual.

### 4.1 Cenários e presets por encontro

- Cada dungeon tem identidade ambiental. Deseja-se **aproximadamente 3 a 4 variações visuais** de cenário de batalha por dungeon, idealmente coerentes com suas subáreas. Esse número é uma meta aproximada, não obrigação universal.
- Cada encontro no mapa aponta para um **preset específico**, que determina cenário e posições iniciais de aliados e inimigos, além da composição inimiga.
- **Determinismo:** ao retornar e repetir o mesmo encontro, o cenário e a formação inicial são os mesmos. Não sortear um preset novo nesse caso.
- Um preset pode ser reutilizado em múltiplos encontros. Nenhuma distribuição aleatória de posições iniciais é necessária.
- As posições dos quatro aliados **podem variar entre diferentes presets**, mas ficam fixas durante **aquela batalha**.
- Preset também pode incluir trajetórias dos inimigos e outros dados próprios do encontro.

**Exemplo de modelo de dados (proposta técnica, não contrato de engine):**

```yaml
encounter_id: dungeon_a_enemy_group_b
battle_preset_id: dungeon_a_corridor_02
battle_scene: dungeon_a_corridor
allied_slots: # coordenadas de idle próprias deste encontro
  - {slot: 1, x: 10, y: 30}
  - {slot: 2, x: 15, y: 45}
  - {slot: 3, x: 9, y: 60}
  - {slot: 4, x: 18, y: 75}
enemies:
  - {enemy_type: wolf, spawn: [75, 35], movement_path_id: wolf_short_patrol}
  - {enemy_type: wolf, spawn: [82, 58], movement_path_id: wolf_short_patrol_2}
```

As coordenadas e nomes acima são **fictícios**, incluídos apenas para ilustrar a associação encontro→preset.

## 5. Campo de batalha, movimento e animação

### 5.1 Personagens jogáveis

- Cada aliado tem uma **posição lógica de repouso (idle) fixa** durante aquela batalha, definida pelo preset.
- Nenhum inimigo, ataque ou cenário pode alterar as coordenadas lógicas x/y de um aliado.
- O sprite pode deslocar-se **visualmente durante uma animação** (por exemplo, ataque corpo a corpo), mas deve retornar à posição original ao final.
- Sprites aliados podem **girar/virar** para acompanhar o inimigo mais próximo; isso não altera sua coordenada lógica.
- Não haverá movimentação livre dos personagens do jogador durante o combate nesta versão.

### 5.2 Inimigos

**Horizonte confirmado em 26/10/2026 (D48):** manter o modelo atual de rotas predefinidas, com variações de sentido, ritmo e pausas por comportamento e semente, até a pré-alfa, inclusive. Movimentação mais orgânica sem rota fixa é apenas uma possibilidade para depois desse marco; nenhuma alternativa foi escolhida ou autorizada para implementação.

- Alguns imóveis, outros móveis conforme o tipo e o preset. Chefes podem ficar estáticos.
- Enquanto a barra ATB enche, um inimigo móvel pode seguir continuamente uma **rota programada em loop no preset**.
- **Não usar deslocamento aleatório de navegação**: não queremos inimigos terrestres circulando desordenadamente entre os aliados.
- Exemplos de padrões possíveis: terrestre com percurso curto/coerente, voador com arcos ou círculos maiores, estático com idle e animações.
- Aprimoramento autorizado: permitir curvas suaves e percursos mais amplos definidos pelo preset, com terrestres mantendo rotas coerentes sem circundar constantemente os aliados e voadores podendo usar percursos mais rápidos, sinuosos e circulares. Alguns inimigos/chefes podem permanecer estáticos. A/B foram preservados e C demonstra os movimentos; não há novos inimigos definitivos.
- Quando o inimigo vai executar ação, a progressão na rota é pausada e guardada exatamente — segmento, fator interpolado/posição e demais dados necessários. A animação pode deslocar o sprite temporariamente. Depois, o sprite volta ao ponto e retoma a rota de onde parou.
- Essa regra vale tanto para ataque em alvo único quanto em múltiplos alvos.

**Ritmos autorizados em 25/10/2026:** dentro da batalha, rotas podem incluir aceleração/desaceleração, pausas programadas, ida e volta e sequências com velocidades diferentes. Perfis de movimento por tipo admitem ajustes por encontro, independentes da INI e da escolha de alvos. Pausas de deslocamento não pausam ATB. Ataques preservam também velocidade, etapa, sentido e relógios do ritmo. Presets A–D e movimento de exploração permanecem; E demonstra pesado/ágil/voador/estático com formas provisórias. Dados e escolhas de implementação em [RITMOS_BATALHA.md](RITMOS_BATALHA.md); valores e tipos são experimentais.

**Refinamento aprovado:** velocidades menores por tipo e mais repouso; sequências com retornos parciais e ritmos diferentes de ida/volta. Alguns presets podem aproximar inimigos dos aliados, especialmente voadores com trajetórias mais amplas. Essas aproximações continuam programadas e não deslocam aliados nem causam dano por contato. E foi refinado e F demonstra aproximações/voo amplo, preservando A–D e o mapa de exploração. Parâmetros permanecem experimentais.

**Adoção anterior à versão por semente:** o modelo refinado de F foi aprovado para todos os encontros do laboratório de exploração. A–E passam a referências legadas; os seis encontros usam quatro presets atuais com ritmos por tipo, retornos parciais, repousos e voos amplos próximos ao grupo. Preservar formações iniciais, quantidade/atributos, perfis de alvo, habilidades, estáticos/exceções, cenário e fuga de cada encontro. O laboratório independente inicia no F. Movimento dos monstros no mapa permanece separado e inalterado. Isso substitui a manutenção anterior de A–D nos encontros jogáveis; ver [RITMOS_BATALHA.md](RITMOS_BATALHA.md).

**Orientação visual confirmada e implementada:** inimigos comuns devem buscar manter a atenção em algum aliado válido durante movimento/repouso, com orientação independente da direção da rota. O aliado mais próximo é uma referência possível, sem obrigação de escolhê-lo sempre ou trocar o olhar a cada mudança de distância. Durante o ataque, olhar para o alvo da ação. A orientação visual não determina o alvo escolhido pela IA ponderada. Casos/inimigos especiais podem ter exceções configuráveis, sem criar agora conteúdo especial. A implementação mantém foco válido estável; ações sem alvo individual usam um adversário vivo próximo da posição visual como referência, sem limitar atingidos. Políticas e parâmetros são técnicos e estão em `COMBATE_SEMENTE.md`.

**Sentido dos terrestres confirmado e implementado:** em batalha, um inimigo terrestre pode sortear entre continuar no sentido atual e inverter o deslocamento ao longo do mesmo caminho. Essa decisão pertence ao comportamento do inimigo e não deve ser determinada/configurada pelo preset do encontro. Ao inverter, desacelerar, pausar e retomar suavemente no novo sentido; preservar o progresso exato durante ataques. O preset continua definindo a geometria da rota e a formação inicial. Isso autoriza aleatoriedade na decisão de sentido, mantendo proibida navegação livre aleatória, criação de caminhos ou perseguição. A orientação visual segue D44 e permanece separada do sentido do deslocamento. Pesos, intervalos e durações usam parâmetros experimentais em dados, sem valores definitivos de balanceamento.

**Pausas variáveis confirmadas e implementadas:** a quantidade e a duração das pausas de comportamento dos inimigos podem variar por sorteio determinado pela semente da batalha, em vez de repetir sempre os mesmos valores. A política pertence ao comportamento, não ao preset. Preservar geometria/posições iniciais, ATB durante repouso e congelamento/retomada do estado durante ações e pausas do sistema. A mesma semente, configuração e sequência de entradas deve permitir reproduzir a simulação nos testes; a formação não é sorteada. Faixas de duração, frequência e limites por tipo são parâmetros técnicos experimentais, sem números definitivos aprovados.

**Versão vigente por semente:** todos os presets anteriores, inclusive F e os quatro primeiros `exploration_*`, são legados. O laboratório inicia em `lab_seeded`; todos os seis encontros usam os quatro presets `exploration_seeded_*`. Formações agora variam entre encontros (aberta, cantos, lados opostos e linha superior), permanecendo fixas dentro da luta. Voadores podem pairar, terrestres sorteiam continuar/inverter, pausas variam pela semente e orientação acompanha aliados/alvo da ação. Os demais atributos, comandos, perfis, cenário e permissões de fuga foram preservados. O mapa-múndi continua sem monstros comuns; patrulhas de exploração não mudam. Arquitetura, configuração e controles em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md).

### 5.3 Separação técnica desejada

Separar:
1. `logical_position` — posição usada em distância/área e estado de combate;
2. `visual_offset` / posição de animação — transformação temporária do sprite;
3. `route_state` — caminho, segmento atual, progresso no segmento e sentido;
4. `facing` — direção visual do sprite.

Para personagens aliados, o valor lógico de posição é fixo enquanto a batalha durar; para inimigos, pode evoluir ao longo da rota e congela durante suas animações de ação.

### 5.4 Aproximação melee provisória

Ataques corpo a corpo deslocam somente o sprite até perto do alvo. Na chegada, mostram uma representação simples e aplicam o efeito; depois retornam à origem. Posição lógica original e progresso exato da rota são preservados durante todas as fases. O sistema de deslocamento de ataque é separado do avanço de rota. Não há animações artísticas definitivas. Escolhas técnicas e roteiro de teste em [MOVIMENTO_E_MELEE.md](MOVIMENTO_E_MELEE.md).

### 5.5 Técnicas de tela inteira: deslocamento individual

Habilidades com apresentação de tela inteira podem levar o participante ao centro visual do campo, executar e retornar. A propriedade individual `move_to_center_for_fullscreen_skill` controla o deslocamento: personagens e móveis normalmente habilitados; estáticos normalmente desabilitados, com exceções configuráveis, inclusive para futuros chefes. Uma condição futura poderá impedir esse movimento no protagonista; essa condição não foi criada agora.

Posição lógica/repouso e progresso exato da rota são preservados. A área de efeito independe do movimento visual; melee permanece separado. Há suporte a alteração temporária por participante sem reescrever a ficha. O laboratório usa representação provisória, com configurações e testes em [TELA_INTEIRA.md](TELA_INTEIRA.md).

## 6. ATB e Iniciativa (INI)

- Cada combatente (aliado e inimigo) tem barra ATB e atributo **INI**.
- A **INI base do personagem é fixa**: não sobe a cada nível.
- **INI efetiva** pode variar com equipamentos/acessórios e buffs/debuffs temporários.
- A velocidade de preenchimento depende da INI efetiva. Fórmula, escala e limites **não definidos**.
- Ao atingir 100%, a barra **para**: nenhuma segunda carga ou ação é acumulada.
- Quando há mais de um aliado pronto, o jogador pode escolher **qual utilizar primeiro**; aliado pronto pode aguardar.
- Após executar uma ação, o ATB volta a zero e retoma novo ciclo. A definição fina de quando a ação passa a ser considerada executada ainda poderá ser refinada na implementação.
- Inimigos seguem ATB, mas suas barras ficam **ocultas** para o jogador.
- INI não define automaticamente probabilidade de fuga.

**Variação confirmada em 26/10/2026 (D49):** os quatro tipos atuais de inimigo (Ágil, Pesado, Voador e Estático) recebem INIs distintas para testar ritmos de ação no laboratório e encontros integrados. Futuramente a INI será definida por inimigo; a categoria de movimento não impõe uma INI universal. Valores experimentais atuais: Ágil 12, Voador 10, Pesado 7 e Estático 5. Aliados mantêm 9/12/7/10. A fórmula e o atendimento de vários inimigos prontos continuam nas escolhas técnicas anteriores, sem regra nova de desempate.

### 6.1 Modos de tempo

**Battle Speed confirmado em 26/10/2026 (D50, atualizado por D51):** menu do jogo com níveis 1..8, sendo **1 mais lento e 8 mais rápido**, **padrão 4**. A escala anterior foi deslocada uma posição acima (antigo 3 → novo 4, antigo 4 → novo 5 etc.); o nível **6 mantém os tempos originais anteriores ao Battle Speed**. Escala somente a carga de ATB dos dois lados, preservando INI individual, movimento e animações. Alterar o nível não zera barras. Escolha mantida na sessão entre áreas/batalhas; persistência em disco continua fora do escopo. Multiplicadores experimentais, uso e tempos em [BATTLE_SPEED.md](BATTLE_SPEED.md). Esse ajuste é independente de Wait/Active e do slider de simulação da depuração.

- **Wait/Espera:** pausa progressão do combate e movimentação dos inimigos **durante a seleção de comandos** quando um personagem está pronto. Fora da seleção, o combate avança normalmente.
- **Active/Ativo:** progressão de ATB e movimento dos inimigos continua enquanto o jogador seleciona comandos.
- Jogador pode configurar o modo no início e alterá-lo mais tarde pelo menu. São estilos de combate; não há decisão de chamá-los formalmente de Fácil/Difícil.
- Pontos finos — como resolver comandos simultâneos e o momento de congelar/descongelar áreas visadas — permanecem pendentes.

## 7. Comandos e recursos

### 7.1 Comandos básicos (confirmados)

| Comando | Efeito |
|---|---|
| **Atacar** | Ataque básico com arma; sem custo de MP. |
| **Habilidades** | Magias e técnicas especiais, físicas ou mágicas; **consomem MP**. |
| **Itens** | Uso de itens do inventário; não consomem MP por padrão. |
| **Fugir** | Tentativa de escapar com **todo o grupo** usando a ação de um aliado pronto. |

**Defender NÃO é um comando da primeira versão.** Habilidades defensivas específicas podem existir futuramente.

### 7.2 Fuga

- Um aliado pronto escolhe Fugir, valendo para toda a equipe.
- Sucesso: termina o combate com a equipe escapando.
- Falha: consome aquela ação, ATB do personagem volta a zero, combate continua.
- Algumas lutas narrativas/chefes podem bloquear fuga.
- Cálculo de chance, mensagens, regras de experiência/loot e estados associados ainda não definidos.

### 7.3 HP / MP

- HP e MP clássicos; permanecem entre batalhas (sem recuperação automática por vitória).
- Técnicas especiais físicas **também gastam MP**, não apenas magias.
- Itens, magias e repouso em locais apropriados poderão restaurar recursos. Valores e economia pendentes.
- Ao chegar a 0 HP, personagem fica incapacitado, não age e sua barra deixa de avançar.
- Ao vencer, continua incapacitado até recuperação por item, magia apropriada ou descanso. Não volta automaticamente com 1 HP.

### 7.4 Atributos físicos e mágicos

**Confirmado em 26/10/2026 (D54):** aliados e inimigos terão quatro atributos distintos, além de HP, MP e INI:

**Siglas de interface confirmadas (D57, ampliadas por D74/D94):**

| Atributo | Sigla | Função |
| --- | --- | --- |
| Vida | HP | Vida atual e máxima. |
| Recurso para habilidades | MP | Recurso atual e máximo para habilidades físicas especiais e magias. |
| Iniciativa | INI | Preenchimento do ATB conforme as regras anteriores. |
| Ataque Físico | ATQ F | Poder ofensivo de contato/corpo a corpo (D94 no laboratório). |
| Defesa Física | DEF F | Proteção contra contato/corpo a corpo (D94 no laboratório). |
| Ataque à Distância | ATQ D | Poder ofensivo de disparos físicos. |
| Defesa à Distância | DEF D | Proteção contra disparos físicos que acertam. |
| Poder Mágico | MAG | Poder ofensivo das ações mágicas. |
| Defesa Mágica | DEF M | Proteção contra dano mágico. |
| Chance-base de crítico | CRI | Chance própria do personagem, conforme D56. |
| Esquiva | EVA | Chance própria de evitar um golpe; crescimento natural lento e aumentos permanentes raros conforme D95. Edição/composição implementadas no laboratório por D75/D84. |

**D94 — ATQ D/DEF D implementados no laboratório (28/10/2026):** usuário autoriza separar contato ATQ F/DEF F, disparos físicos ATQ D/DEF D e magia MAG/DEF M. DEF D própria escolhida45/30 para #1/#2; referência ATQ D10/20 adotada no teste. Espada soma somente ATQ F; arco somente ATQ D. Arma determina modo padrão do aliado; monstro permanece contato por padrão e um seletor permite override físico. As proteções passam a fornecer os dois bônus espelhados de D93, mantendo DEF F e EVA anteriores. Campos de distância usam as faixas existentes de ATQ/DEF. Presets antigos são atualizados em memória por ID e atributos próprios, sem mudar revisões/arquivo ao ler; novas exportações JSONv4 identificam modalidade e atributos usados. Monstro #1 recebe DEF D40 por compatibilidade, preservando o dano do arco. Danos já calibrados e três RNGs preservados; **combate integrado continua com o sistema anterior**. Especificação em [ATQ_DISTANCIA.md](ATQ_DISTANCIA.md).

**D93 — prioridade das proteções no desenho de DEF D (28/10/2026):** usuário define que armaduras de metal e trajes de couro devem aumentar **DEF F e DEF D**. Metal prioriza o bônus de DEF F; couro prioriza o bônus de DEF D. Isso não determina a ordem dos totais dos aliados, pois as bases ainda não foram escolhidas. A proposta numérica espelhada foi posteriormente adotada e implementada por D94; ver `ATQ_DISTANCIA.md`.

O rótulo aprovado é **CRI**, sem o sufixo B. A abreviação não muda a distinção entre chance-base, modificadores, chance da arma e multiplicador crítico.

**D73 — manter os atributos atuais (27/10/2026):** após comparar com Chrono Trigger, manter HP, MP, INI, ATQ F, DEF F, MAG, DEF M e CRI por enquanto. Não acrescentar agora uma nova camada de atributos-base e ATQ/DEF derivados nos moldes da referência. A composição já aprovada de atributos próprios com bônus de equipamentos (D64/D66, seção 7.5) continua vigente; nenhuma alteração de código ou fórmula decorre deste registro.

**D74 — definição original de base fixa (27/10/2026), crescimento revisado por D95:** acrescentar EVA ao desenho dos atributos. A chance de esquiva tem uma base própria por personagem, que **não aumenta naturalmente ao subir de nível**; equipamentos, buffs e itens podem modificá-la. Segue a estrutura de chance-base e modificadores discutida para CRI, sem exigir os mesmos valores ou probabilidades. Esta decisão amplia o conjunto registrado em D73, preservando os oito atributos anteriores e a composição de equipamentos existente. Valores iniciais, escala/conversão percentual, composição/limites dos modificadores, duração/acúmulo e quais ataques permitem esquiva continuam pendentes. A ordem e elegibilidade definitivas do jogo continuam abertas; a implementação experimental posterior está em D75. Sem mudança no combate integrado.

**D95 — crescimento lento e aumentos permanentes de EVA (28/10/2026):** usuário revisa a restrição de D74. EVA própria poderá crescer pouco naturalmente: referência de **+1 a cada10 ou15 níveis**, ainda sem escolha do intervalo ou marcos. Equipamentos e magias também podem alterar EVA. **Itens especiais raros encontrados na campanha poderão aumentar a EVA própria em+1 permanentemente.** Não confundir esse ganho permanente com o bônus enquanto um equipamento está equipado. Limites finais, duração/acúmulo dos efeitos mágicos, quantidade/obtenção dos itens e curva definitiva ainda para desenho. **INI permanece com a regra vigente de não crescer por nível.** Sem implementar progressão, novos itens ou efeitos nesta etapa; valores/presets atuais permanecem.

**Recomendação de organização, ainda sem implementação:** separar EVA inicial, ganho por nível e aumentos permanentes na ficha, somando contribuições de equipamentos e efeitos de magia para obter EVA efetiva. Isso preserva a origem dos ganhos e evita perder um aumento permanente ao trocar equipamento. Não acrescenta agora novos campos ao laboratório ou ao JSON.

**D75 — EVA autorizada e implementada no laboratório de danos (27/10/2026):** editar a EVA base de aliado/monstro, registrar esquivas em ação única, lotes, histórico, presets e exportação. Naquela etapa, equipamentos, itens e buffs que modificam EVA ficaram para depois; D84 acrescenta posteriormente o bônus de armadura do couro. Escolhas experimentais: EVA inteira 0..100, 1 ponto = 1%, padrão zero; permissão por ação, inicialmente ligada nas físicas e desligada na magia; verificar esquiva antes de aplicar crítico/dano. Esquiva gera dano/HP removido zero, sem crítico, mas consome ação e MP; mínimo 1 vale somente nos acertos. RNG de esquiva separado, sem alterar os fluxos de crítico/variação. Presets antigos sem EVA recebem zero em memória; relatório passa a JSON v3. Valores e regras definitivos continuam pendentes. Detalhes em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

**Escalas vigentes (D59/D69/D76, 27/10/2026):** aliados: **HP, MP, ATQ F, DEF F, MAG e DEF M em 0..999**; monstros: **HP em 1..99999** e **MP, ATQ F, DEF F, MAG e DEF M em 1..9999**, permitindo chefes com mais de 10 mil HP. **INI e CRI continuam em 1..99 para ambos.** A escala numérica não define sozinha fórmulas, progressão, distribuição inicial nem curvas de conversão. A faixa de INI mantém a escala pequena, sem solicitar reescala do ATB atual; conversão/fórmula definitiva continua pendente. Conversão de CRI confirmada posteriormente em D63: 1 ponto = 1% de chance-base, somado à chance da arma e aos bônus de itens/buffs. Alcance dos modificadores e eventual limitação de valores efetivos continuam por definir. Registro de desenho, sem alterar automaticamente as fichas ou a simulação atuais.

**Dano mínimo confirmado em 26/10/2026 (D55):** dano mínimo de 1 para um ataque que atinge um alvo válido.

**Críticos — origem confirmada em 26/10/2026 (D56):** as armas definem chance de crítico e multiplicador. Cada personagem também possui uma chance-base de crítico. **Esclarecimento confirmado:** o valor-base do personagem influencia somente a chance, nunca o multiplicador. A chance pode ser modificada por itens ou buffs de magia. O multiplicador permanece definido pela arma; não há multiplicador global 2× ou 3× escolhido. D63 confirma a conversão de 1 ponto de CRI em 1% e a soma da chance da arma e dos bônus de itens/buffs em pontos percentuais. Valores por arma/modificador, limites finais, acúmulo e duração continuam pendentes.

**Pendente para o jogo definitivo:** valores das fichas, progressão/modificadores, fórmula e arredondamento de dano, distribuição de variação, chances por arma/bônus e multiplicadores críticos, elegibilidade de ações e casos sem arma. Conversão percentual de CRI e composição aditiva aprovadas em D63. A existência dos atributos não aprova automaticamente as fórmulas do guia de referência de Chrono Trigger.

**D60 — laboratório separado autorizado e implementado em 26/10/2026:** o usuário decidiu experimentar com o que temos e ajustar pelos testes. Duelo manual com fichas de atacante/alvo editáveis e ações **1× / 10× / 100× / 1000×** (D58), resumo, histograma, amostras e histórico com condições. Fórmula proporcional experimental: `potência × ofensiva² / (ofensiva + defesa)`, usando ATQ F/DEF F ou MAG/DEF M; ofensiva zero gera base zero. Aplicar variação, crítico da arma, arredondar e mínimo 1. Parâmetros ajustáveis, incluindo chance-base, arma, item/buff e permissão da ação; números não são balanceamento definitivo.

O laboratório restaura HP/MP antes de cada amostra para comparar resultados, com sequência por semente reproduzível. Essa política pertence ao teste; a persistência de recursos do jogo permanece. **O combate integrado e o laboratório de combate continuam com o cálculo anterior**; não houve migração de fichas, equipamentos ou buffs. Fórmulas, controles, dados e limites em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

**D61 — exportação confirmada e implementada em 26/10/2026:** o laboratório de danos exporta a tabela completa da execução selecionada em JSON, junto de resumo, fichas/configurações originais, fórmula e Seed/posição da sequência. Exportar um resultado do histórico mantém suas condições, sem novo cálculo ou avanço dos sorteios. Arquivo local escolhido pelo usuário; formato em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

**D62 — referência de balanceamento inicial (26/10/2026):** o usuário imagina o cenário exportado do laboratório para os inimigos iniciais, levando aproximadamente **3 a 4 ataques básicos normais para derrotar cada inimigo**. É uma referência de resistência por inimigo para testar; críticos podem reduzir a quantidade de golpes. No exemplo analisado: ATQ F 30, DEF F do alvo 35, HP do alvo 40, potência 1× e variação ±10%, produzindo 12–15 de dano normal. Esses atributos/fichas continuam exemplos experimentais, sem fixar todos os inimigos iniciais nos mesmos números ou definir o balanceamento das fases seguintes. A referência conta golpes individuais, não rodadas de toda a equipe; frequência de ações, quantidade de inimigos e dano recebido ainda precisam ser avaliados em batalha.

**D63 — chance de crítico confirmada (26/10/2026):** manter 1 ponto de CRI = 1% de chance-base; somar chance da arma e bônus de itens/buffs em pontos percentuais. Exemplo: CRI 5 + arma 5% = 10%. CRI e bônus não alteram o multiplicador, que permanece da arma (D56). O laboratório já usa conversão padrão 1%; seu ajuste de conversão serve apenas à experimentação. Limites finais, valores por arma/modificador, duração/acúmulo e integração ao combate continuam pendentes.

**D78 — referência de resistência no primeiro nível (27/10/2026):** o usuário deseja **3–4 golpes para derrotar os monstros iniciais e 5–6 para o protagonista cair**. A segunda meta atualiza os 4–5 golpes de D70. Para estudo, separar acertos normais, críticos e tentativas evitadas; a referência de golpes normais que acertam continua sendo a base de comparação, com críticos encurtando e esquivas aumentando a quantidade de tentativas. Números das fichas e fórmulas não foram aprovados por essa meta. Comparação dos dois JSONs e alternativas experimentais em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md); nenhuma alteração automática de dados/presets.

**D79 — HP e direção do dano inicial (27/10/2026):** aliado começa com **40 HP**; monstros iniciais ficam em **35–45 HP**. O dano normal causado pelo aliado deve ficar aproximadamente em **9–15**. Esclarecimento confirmado pelo usuário: essa faixa é ofensiva; inimigos causam menos para manter **5–6 acertos normais até a queda do aliado**, preservando **3–4 para derrotar monstros**. Críticos/esquivas seguem separados dessa referência. A faixa de monstros substitui a preferência histórica de 30 HP de D68 para este cenário inicial. ATQ/DEF, dano recebido exato e demais atributos ainda para estudo; exemplo calculado em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md), sem alteração automática dos dados/presets.

**D87 — diferença ofensiva entre aliados (27/10/2026):** usuário esclarece que deseja média de dano do **Aliado #1 cerca de 15% maior** que a do Aliado #2, invertendo o sentido anterior da discussão P07. O estudo compara dano por ataque contra o mesmo alvo, incluindo críticos/esquivas; INI e frequência de ações devem ser avaliadas separadamente. ATQ próprio23/total33 para o primeiro foi posteriormente adotado e aplicado por D88. Essa alternativa produz normal13–16, ligeiramente acima do teto aproximado9–15 de D79, e preserva3–4 acertos normais contra HP35–45. Números adotados para teste, sem fechar balanceamento definitivo.

**D88 — ajuste aplicado aos presets (27/10/2026):** autorizado após apresentação dos resultados de D87. Biblioteca pessoal atualizada: **Aliado #1 com ATQ próprio23 + espada10 =33**, revisão2. Aliado #2 permanece próprio20 + arco10 =30; Monstro #1 preservado. Contra DEF40/EVA3%, médias teóricas por tentativa15,919 contra13,920 (+14,36% para #1); normal13–16 e crítico27–33. A adoção inclui o máximo normal16 apresentado na proposta, ampliando levemente a faixa aproximada inicial de D79 e preservando3–4 acertos normais contra monstros35–45HP. Demais atributos e equipamentos permanecem iguais. Somente o preset pessoal foi atualizado; ficha manual, fórmulas e combate integrado não mudam.

**D80 — papel da ficha de nível 1 (27/10/2026):** o usuário está construindo **Aliado #1** como referência inicial do personagem no **nível 1**, para futuramente progredir ao subir de nível. Os valores atuais são ponto de partida de estudo, sem fechar o balanceamento definitivo ou a ficha de todos os companheiros. Preservar atributos próprios separados dos bônus de Bronze: os totais equipados não devem virar atributos-base da progressão. Desenho de ganhos/curvas por atributo, XP, nível máximo e tratamento de CRI fica para uma próxima etapa. INI continua sem crescimento natural por nível conforme D15; EVA passou a admitir crescimento muito lento e ganhos permanentes por D95. Esta definição não autoriza implementar agora níveis, XP ou progressão.

**D84 — preset do segundo aliado implementado (27/10/2026):** Aliado #2 salvo no laboratório com HP36, MP14, INI11, ATQ F próprio20, DEF F própria30, MAG20, DEF M21, CRI/EVA próprios7; arco composto +10 ATQ F, +12 p.p. CRI e 1,6×; couro +5 DEF F e +5 EVA. Totais ATQ30, DEF35, CRI19%, EVA12%. Equipamento permanece separado de atributos próprios, inclusive EVA. A EVA efetiva usa limite experimental 100%, preservando soma bruta; históricos/JSON e recarga mantêm a composição. D86 torna a armadura obrigatória. Esta etapa amplia D75 apenas para o bônus de armadura necessário ao preset; itens/buffs de EVA continuam futuros. Presets existentes preservados. Dados adotados para teste, sem balanceamento definitivo, níveis ou migração ao combate integrado.

**D76 — ampliar HP dos inimigos (27/10/2026):** HP inicial/máximo dos inimigos no laboratório passa de 1..9999 para **1..99999**, permitindo testar chefes acima de 10 mil HP. Demais atributos mantêm suas faixas, incluindo aliados, INI, CRI e EVA. Editor, validação, inversão dos lados, presets e metadados/valores do JSON respeitam o novo limite, sem alterar fichas iniciais, fórmulas ou criar conteúdo de chefe. HP após receber dano pode chegar a zero.

### 7.5 Contribuição de armas e armaduras

**D64 confirmado em 26/10/2026:** armas somam um bônus ao ATQ F do personagem; armaduras seguem a mesma lógica, somando bônus à DEF F. Preservar a distinção entre atributo próprio e contribuição do equipamento:

```text
ATQ F efetivo = ATQ F próprio + bônus da arma + outros modificadores
DEF F efetiva = DEF F própria + bônus da armadura + outros modificadores
```

Os valores efetivos entram no cálculo de dano. A potência continua pertencendo à ação; melhorar a arma aumenta o dano de ataques básicos e técnicas físicas que usam ATQ F. Melhorar a armadura reduz o dano físico recebido conforme a fórmula, sem subtrair seu bônus diretamente do dano final. Regras de crítico das armas permanecem conforme D56/D63.

**D85 — exclusividade por personagem (27/10/2026):** arco composto e conjunto de couro só podem ser equipados pelo **Aliado #2**. A regra acompanha sua identidade estável, independentemente do nome ou ID de uma cópia de preset. Filtrar seletores e validar seleção, salvamento/carga e execução; não aceitar uso por outro aliado ao remover metadados de uma cópia do item. Separar personagem do modelo reutilizável da ficha e manter equipamento/identidade ao trocar lados. Presets locais atualizados sem mudança de atributos/bônus/revisões. D86 amplia a exclusividade aos equipamentos do primeiro aliado e torna ambos os slots obrigatórios.

**D86 — exclusividade nos dois sentidos e equipamento obrigatório (27/10/2026):** Aliado #1 usa somente espadas/armaduras de metal; Aliado #2 usa somente arco composto/couro. Todo aliado mantém uma arma e uma armadura equipadas, com seletores sem opções vazias. Validar também salvamento/carga e execução, preservando o equipamento ao recusar uma troca inválida. Padrões por personagem: Bronze/Bronze para #1 e arco/couro para #2. Presets antigos com `id: none` recebem padrões compatíveis em memória; equipamento ausente, desligado ou incompatível é recusado. Monstros continuam com atributos diretos. Sem mudança nos números dos presets salvos, progressão ou combate integrado.


**D89 — manter os valores e desenhar escalas (27/10/2026):** usuário aceita o balanceamento inicial atual após D88 e solicita uma escala de arcos paralela às espadas e uma escala de proteção leve paralela às armaduras, com liberdade para outro nome além de “armadura de couro”. **Criar a proposta antes de implementar.** Tabela de seis estágios, nomes e bônus em [ESCALA_ARCOS_E_TRAJES.md](ESCALA_ARCOS_E_TRAJES.md), todos ainda propostos. Não altera catálogo, presets ou progressão por nível. A manutenção da vantagem aproximada15% entre estágios superiores ainda precisa de decisão; a escala numérica igual das armas não a garante.

**D90 — arcos de madeira (28/10/2026):** usuário esclarece que precisa de arcos de madeira para a escala de D89. Substituir no desenho os nomes que associavam os arcos aos metais das espadas. Tipos de madeira, nomes dos itens e valores concretos permanecem propostas em `ESCALA_ARCOS_E_TRAJES.md`; não há implementação nem alteração dos presets. A decisão anterior D67 sobre remover equipamentos de Madeira do catálogo de espadas/armaduras não impede essa família de arcos.

**D91 — arcos adotados provisoriamente (28/10/2026):** usuário aceita por enquanto a curva P08B: bônus de ATQ10/15/22/31/44/58, mantendo bônus de CRI12p.p. e multiplicador1,6×, com a sequência de nomes de madeira proposta. Referência provisória para o laboratório, sem implementação nesta etapa. A vantagem aproximada15% foi comparada nos pares contra o alvo atual; não é garantia universal nem regra definitiva de progressão. A escala de proteção leve passa à discussão: DEF+5/8/12/17/24/33 e EVA+5 constante são recomendações ainda não aprovadas.

**D92 — escalas implementadas no laboratório de danos (28/10/2026):** após desenho e aceite provisório dos arcos, usuário autoriza adicionar os equipamentos. Seis arcos de madeira com ATQ+10/15/22/31/44/58, chance da arma+12p.p. e multiplicador1,6×; seis trajes leves com DEF+5/8/12/17/24/33 e EVA+5 constante. Nomes adotados para teste em [ESCALA_ARCOS_E_TRAJES.md](ESCALA_ARCOS_E_TRAJES.md). Todos exclusivos do Aliado #2; #1 mantém espadas/metal. Arma e proteção obrigatórias. Primeiro arco/couro conservam IDs, bônus e defaults; nomes de exibição atualizados para Arco Composto de Madeira/Traje de Couro. Carga atualiza os nomes em cópia por ID, preservando atributos próprios, bônus editados, revisões e arquivo pessoal ao ler. Seletores, composição, histórico, presets e JSON aceitam todos os estágios. Sem novos slots, efeitos, inventário, níveis ou alteração do combate integrado. Números permanecem referência experimental.

**Pendente:** valores, progressão, limites efetivos, slots/troca de equipamento e efeitos adicionais por item. A sequência de espadas Madeira/Bronze/Ferro/Aço/Mithril/Adamantio/Rúnica e os números apresentados foram exemplos de discussão, sem aprovação de catálogo definitivo, chance/multiplicador crítico ou bônus mágicos. Registro de desenho; implementação experimental de seleção/composição no laboratório autorizada posteriormente em D66. Inventário e equipamentos da aventura permanecem pendentes.

**D65 — escopo de equipamentos confirmado:** armas/armaduras somente nos aliados neste recorte. Monstros comuns continuam com atributos diretos, sem slots ou equipamentos simulados. Equipamento em inimigos humanos/humanoides é uma possibilidade futura, explicitamente adiada para evitar complexidade. As progressões discutidas servem como ponto de partida experimental para testes no laboratório, sem fixar balanceamento definitivo. A interface e integração foram autorizadas e implementadas posteriormente em D66, somente no laboratório; ver `LABORATORIO_DANOS.md`.

**D66 — implementação autorizada e concluída no laboratório de danos:** seletores de arma/armadura só para o aliado, bônus editáveis, atributos próprios separados dos totais, equipamentos associados ao aliado mesmo quando ele vira alvo e condições completas no histórico/JSON. Monstros mantêm atributos diretos e nenhum equipamento. As progressões de exemplo são presets experimentais. O modo aliado sem arma dessa implementação foi retirado por D86; monstros mantêm multiplicador próprio provisório. A soma efetiva do aliado é limitada a 999 neste teste e a interface informa quando isso ocorre. Essa limitação não fixa o tratamento definitivo dos modificadores no jogo. Sem inventário, slots adicionais ou alteração da exploração; roteiro/dados em `LABORATORIO_DANOS.md`.

**D67 — catálogo experimental ajustado:** remover equipamentos de Madeira e deslocar os bônus dos demais uma posição para baixo. Armas e armaduras: Bronze +10, Ferro +16, Aço +24, Mithril +34, Adamantio +48 e Rúnica +65, nos respectivos ATQ F/DEF F. Padrão em Espada de Bronze; opções sem equipamento e controles de crítico permanecem. Valores continuam ponto de partida para testes, sem alterar atributos próprios, fórmulas ou a exploração.

**D68 — preferência para o cenário inicial de estudo (27/10/2026):** o usuário deseja manter o monstro com **30 HP**, preservando a referência de aproximadamente 3–4 ataques básicos normais para derrotá-lo. Não confirma a sugestão anterior de subir a vida para 50 nem fixa todos os inimigos em 30 HP. DEF F e demais números devem ser ajustados/testados junto do ataque esperado do aliado; exemplo recomendado, ainda sem aprovação de valor definitivo, em `LABORATORIO_DANOS.md`. D79 posteriormente substitui esta preferência por 35–45 HP para os monstros iniciais.

**D69 — escala dos monstros confirmada e implementada no laboratório (27/10/2026):** HP, MP, ATQ F, DEF F, MAG e DEF M de monstros vão de **1 a 9999**. A ampliação permite testar números de chefes, sem criar conteúdo ou perfil de chefe. Aliados mantêm 0..999 nesses atributos, INI/CRI permanecem 1..99 para ambos e equipamentos continuam somente nos aliados. Validação, edição, troca de lados e exportação respeitam a categoria do participante. O limite de atributos não limita o dano resultante; HP/MP após a ação podem chegar a zero normalmente. D76 posteriormente amplia somente HP dos monstros para 1..99999. Fichas e combate da exploração permanecem com o recorte anterior.

**D70 — resistência inicial do aliado:** com armadura de Bronze, o usuário deseja aproximadamente **4–5 golpes para o personagem cair**. A referência de estudo considera golpes físicos normais dos inimigos iniciais; críticos podem antecipar a derrota. D78 posteriormente altera a meta de resistência para 5–6 golpes no primeiro nível. O início é solo, portanto a queda do protagonista é Game Over. HP e atributos concretos do aliado/inimigo continuam para balanceamento; exemplo recomendado em `LABORATORIO_DANOS.md`, sem aprovação automática de números ou mudança de presets.

**D71 — necessidade de presets de teste (27/10/2026):** o usuário solicitou presets reutilizáveis de aliados e inimigos no laboratório de danos para evitar redigitação das fichas. Proposta autorizada e implementada posteriormente em D72; seleção/gravação e persistência descritas em `LABORATORIO_DANOS.md`. Esses presets pertencem ao teste e não definem atributos definitivos da aventura.

**D72 — presets de fichas autorizados e implementados (27/10/2026):** seletores independentes de aliado/monstro, dois presets iniciais de referência protegidos, Salvar como com nome e Atualizar para personalizados alterados. Presets guardam atributos próprios/diretos e equipamentos completos somente do aliado; totais são recalculados ao carregar. Personalizados persistem em arquivo local separado. Aplicar/gravar não avança RNG, não troca ação/parâmetros globais e não altera histórico. O JSON de amostras identifica preset, revisão e alterações daquela execução. São ferramentas de laboratório; não constituem save ou balanceamento definitivo da aventura. D77 posteriormente remove as referências fornecidas e revisa a interface/biblioteca, preservando a gravação dos novos presets.

**D77 — revisar presets do laboratório (27/10/2026):** excluir todos os presets anteriores de aliados/inimigos, incluindo referências fornecidas e os três personalizados locais existentes. Retirar o seletor antigo de oito exemplos, mantendo somente uma ficha manual de aliado e uma de monstro. Biblioteca começa vazia; futuros presets salvos pelo usuário persistem normalmente, sem limpeza automática ao iniciar. Em cada categoria, oferecer **Salvar**, **Carregar**, **Atualizar** e **Excluir**. Carregar restaura os nove atributos, multiplicador próprio e equipamentos completos do aliado, recalculando totais; permite recarregar o mesmo preset e descarta texto pendente anterior. Nome do preset identifica o participante salvo. Exclusão persiste em disco, mantém a ficha atual para edição e não altera histórico/RNG ou a outra categoria. Ação, semente e demais controles globais continuam separados das fichas. Esta decisão substitui as referências protegidas e o catálogo manual anterior de D72; detalhes em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

## 8. Tipos de alvo e área (direção funcional)

Habilidades podem afetar:
- **Um alvo** (aliado ou inimigo, conforme efeito);
- **Área localizada** (ex.: circular);
- **Linha/faixa**, se vier a ser adotada;
- **Todos** os alvos de um lado (ou outra regra de alvo de cada habilidade).

O posicionamento atual dos **inimigos móveis** importa na seleção das áreas de efeito. **D53 confirmado:** habilidade em área exige um alvo central válido; o círculo acompanha sua posição até o impacto, quando os demais atingidos são calculados pelo raio. **Não haverá fogo amigo:** ações ofensivas só afetam o lado adversário, tanto para aliados quanto para inimigos. Em Active, movimentos e prévia continuam durante seleção; Wait mantém sua pausa de seleção. Dimensões, demais geometrias e balanceamento continuam abertos. **Habilidades conjuntas/duplas/de grupo ficam para o futuro.**

### 8.1 Interface de comandos e alvos

**D52 confirmado em 26/10/2026:** combate navegável somente por teclado/controle, sem mouse para selecionar executor, ação ou alvo. A mão percorre os cards inferiores dos aliados prontos; confirmar transfere o foco para os comandos à direita. O card escolhido permanece destacado. Depois de escolher Ataque/Habilidade/Item, a mão aponta ao inimigo ou aliado válido em campo. Áreas mostram raio e demais atingidos. Cancelar retorna uma etapa por vez até os cards, sem custo antes da confirmação. Controles, escolhas técnicas e validação em [INTERFACE_BATALHA.md](INTERFACE_BATALHA.md).

## 9. IA programática — personalidade dos inimigos

### 9.1 Abordagem aprovada

- Implementar **sem LLM, sem agente de IA e sem ML**. Usar regras programáticas, estados simples e **seleção aleatória ponderada** (*weighted random selection*).
- Perfil do inimigo determina **preferências**, não escolhas absolutas. Inimigos podem escolher outros alvos válidos.
- IA de decisão (ações/alvos) é independente do sistema de movimento e do preset.
- Não é preciso decidir alvos a cada frame: a seleção pode ocorrer quando o inimigo está pronto para executar uma ação.
- Evitar mudanças de personalidade ou reações de fase durante a batalha na primeira versão. Mudanças reativas complexas foram consideradas interessantes para o futuro.
- Todos os alvos incapazes/inelegíveis devem ser excluídos do sorteio e o algoritmo precisa de fallback seguro.

### 9.2 Perfis propostos para uso inicial

Os nomes e comportamentos abaixo foram discutidos como **conjunto-base proposto**, com concordância explícita com a arquitetura probabilística, mas **sem pesos definitivos** ou decisão de quais tipos de inimigos os usarão:

| Perfil | Prioridade ponderada de alvo |
|---|---|
| **Instintivo** | Probabilidade uniforme entre alvos válidos. |
| **Predador** | Prefere alvos com menor porcentagem de HP. |
| **Implacável** | Favorece um alvo escolhido antes; pode trocar conforme probabilidade e validade. |
| **Retaliador** | Favorece quem lhe causou dano mais recentemente. |
| **Caçador de Magos** | Favorece alvos de maior MP máximo. |
| **Tático** | Pode ponderar alvos conforme habilidade/efeito escolhido; é mais complexo e pode ser adiado. |

Os exemplos (slime, lobo, soldado etc.) são **ilustrativos**, não bestiário ou classes definitivas.

### 9.3 Exemplo de seleção ponderada (pseudocódigo)

```text
quando_inimigo_esta_pronto:
    acao = escolher_acao_valida(inimigo, contexto_da_batalha)
    alvos = alvos_validos(acao, contexto_da_batalha)
    se alvos vazios: tratar_com_segurança_sem_travar
    para cada alvo:
        peso[alvo] = peso_base_positivo * modificador_de_perfil(inimigo, acao, alvo)
    alvo = sorteio_ponderado(alvos, peso, gerador_aleatorio_injetavel)
    executar_acao(inimigo, acao, alvo)
```

- Perfis não devem depender de LLM e não requerem custo de rede.
- A escolha do alvo e da ação são distintas. Para habilidades de área, a escolha pode ser de centro/ponto/região em vez de uma unidade, exigindo regra específica ainda a desenhar.
- Percentuais exatos, fórmulas, seleção de ações e tratamento de ameaças ainda estão pendentes.

## 10. Derrota e salvamento

- Game Over tradicional se **todos os integrantes ativos** ficarem com 0 HP; jogador carrega salvamento anterior.
- Não há retorno automático a pousada ou outro local após derrota.
- **Salvamento somente em locais específicos**: pousadas e pontos especiais em trechos relevantes da história, frequentemente perto de chefes, mas não necessariamente antes de cada um.
- Descanso em pousadas/pontos apropriados pode recuperar HP e MP; custos/regras precisas ainda não definidos.

## 11. Evoluções FUTURAS — não incluir no escopo inicial

- Em um momento avançado/final da história, protagonista poderá deixar de ser obrigatório no grupo ativo.
- Conteúdo de final de jogo com **missão pessoal opcional para cada companheiro**, ativada somente se o personagem estiver na equipe ativa; encerra seu arco e dá recompensa mecânica (poder, item) e/ou narrativa.
- Técnicas/magias de dupla e grupo, exigindo dois ou mais aliados prontos.
- Combate diretamente no cenário da dungeon em vez de tela separada.
- Possíveis reações avançadas de IA (medo, fuga, fúria, desespero etc.) conforme a batalha evolui.
- Possível revisão da movimentação inimiga para reduzir a sensação de percurso repetido e dispensar rotas fixas, somente após a pré-alfa. Sem solução escolhida ou compromisso de adoção; até esse marco permanece o modelo atual (D48).

## 12. Regras para especificar novos sistemas

Para cada funcionalidade nova, registrar:
- Objetivo na experiência do jogador;
- Regras confirmadas versus hipóteses;
- Dados necessários e interfaces entre sistemas;
- Casos de teste e situações de borda;
- Custo de implementação/risco de escopo.

**Não assumir como design definitivo:** fórmula de INI/ATB, tempo de barras, classes/raças definitivas, mapa, ordem de ações simultâneas, quantidade de inimigos por encontro, números de HP/MP, coeficientes de probabilidades, colisões de animação ou custo de qualquer habilidade. O motor escolhido é Godot, com GDScript. O usuário autorizou escolhas técnicas para preencher lacunas no laboratório, desde que documentadas em [DECISOES_TECNICAS.md](DECISOES_TECNICAS.md).
