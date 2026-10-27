# Pendências e limites de escopo

Esta lista impede que o Codex transforme lacunas em decisões arbitrárias.

## Situação após autorização do laboratório

- Engine e linguagem — **Godot + GDScript confirmados**.
- Plataforma comercial — **não escolhida**. O laboratório é executado localmente em desktop; validado em macOS.
- 2D/pixel art, resolução final, controles definitivos e direção de arte — **não fechados**, apesar das referências SNES. Para este protótipo, a câmera acompanha o líder na escala da casa; ajustes de apresentação definitiva continuam abertos.
- Escopo atual — **laboratório de combate e exploração integrada v0.2 autorizados**; ver `LABORATORIO.md` e `EXPLORACAO_V02.md`.
- Organização implementada do laboratório e parâmetros experimentais — ver `DECISOES_TECNICAS.md`. Saves da aventura e produção de assets seguem pendentes.
- Rotas suaves e melee provisório autorizados/implementados; ver `MOVIMENTO_E_MELEE.md`. Animações artísticas, trajetórias definitivas por inimigo e ajustes de ritmo continuam abertos.
- Apresentação configurável ao centro para tela inteira autorizada/implementada; ver `TELA_INTEIRA.md`. Chefes definitivos e uma eventual condição narrativa do protagonista continuam futuros, sem gatilho implementado.
- Ampliação do mesmo mapa de testes autorizada/implementada em 24/10/2026: seis encontros, cinco NPCs, diálogos/respostas, obstáculos e quatro objetos. Ver `EXPLORACAO_INTERACOES.md`. Falas, efeitos e estados são testes locais; conteúdo narrativo, recompensas definitivas, persistência em disco e mapas da aventura continuam pendentes.
- Transições casa↔laboratório autorizadas/implementadas em 24/10/2026; ver `TRANSICOES_AREAS.md`. Estado em memória, pausa de áreas inativas, fade e reconstrução segura da fila são escolhas provisórias deste teste. Mundo, mapas definitivos e salvamento em disco continuam pendentes.
- Distribuição anterior: NPCs somente na casa e exterior só com colisões foi substituída pela vila e mundo aberto descritos abaixo. O registro de interiores permanece em `INTERIORES_DUNGEON.md`.
- Câmera seguindo o líder e escala comum da casa autorizadas/implementadas; ver `CAMERA_EXPLORACAO.md`. Limites, seguimento imediato, referência visual e comportamento de redimensionamento são escolhas técnicas de teste; suavização/efeitos e direção artística definitiva continuam abertos, sem implementação adicional.
- Profundidade e oclusão do cenário autorizadas/implementadas; ver `PROFUNDIDADE_EXPLORACAO.md`. Atores e estruturas compartilham ordenação pela base, com colisão física separada da altura/copa. Dimensões, alturas, transparência futura e assets definitivos continuam sem especificação final; nenhuma transparência automática foi acrescentada.
- Distribuição vigente: **casa↔vila↔mundo aberto↔dungeon**, com NPCs dentro da casa e nas ruas. Mundo com paisagem provisória e sem monstros comuns. Ver `VILA_E_MUNDO.md`. Escala/mapas definitivos, quantidade final de habitantes, posição dos acessos e travessia de água continuam pendentes. A decisão posterior de relevo está abaixo; geometria e caminhos atuais são escolhas de teste.

- **Confirmado/implementado:** colinas bloqueiam passagem pelas bordas, rampas dão subida/descida gradual e florestas do mundo são massas inacessíveis. Ver `RELEVO_E_FLORESTAS.md`. Substitui as colinas caminháveis e os espaços livres entre árvores do mundo anterior. Alturas, dimensões, posições e mapas finais continuam provisórios. Não autoriza habilidades para atravessar florestas, saltos, quedas, pontes ou navegação marítima.

- **Confirmado/implementado:** relógio global, períodos, eventos mesmo pausado, iluminação e descanso sempre às 07:00. Agora `test_world` é o mapa-múndi do protótipo: avança automaticamente, com ciclo de **2 minutos reais**. Vila, casa e dungeon permanecem pausadas; prévia automática de F3 removida. Início 10:00, limites, paleta e luz interna fixa seguem provisórios. Ver `CICLO_DIA_NOITE.md`. Rotinas, calendário/clima, economia/recuperação de pousada e salvamento continuam futuros.

- **Confirmado/implementado:** experimento O Segredo da Casa, segunda casa, pedra com descoberta noturna única, NPCs 4/5 por horário e luzes geométricas. Ver `EVENTOS_DIA_NOITE.md`. A flag permanece na sessão entre áreas/horários; Reiniciar teste a limpa. Coordenadas, falas e halos são provisórios; save em disco, rotina entre mapas, animação de troca de posição e sistemas narrativos completos continuam futuros.

As lacunas abaixo continuam abertas para o jogo definitivo. As escolhas provisórias necessárias ao laboratório estão documentadas separadamente; não são balanceamento aprovado.

- **Integração do relógio realizada:** avanço automático sem F3 no mapa-múndi existente; pausa nas demais áreas, inclusive cidades externas. A aparência ao ar livre não substitui a classificação explícita. Eventos e descanso continuam podendo alterar o horário. Geografia definitiva do mapa-múndi permanece pendente.

**Confirmado/implementado em 25/10/2026:** ritmos programados dentro da batalha, aceleração/desaceleração, pausas, ida e volta e perfis de velocidade ajustáveis por encontro. Preset E e depuração; A–D e movimento no mapa preservados. Ver `RITMOS_BATALHA.md`. Velocidades, durações, trajetórias e tipos de teste continuam provisórios; reações a HP/dano e perseguição não foram incluídas.

**Refinamento confirmado/implementado:** E com velocidades menores e mais repouso; retornos parciais e diferenças entre ida/volta; F com aproximações programadas e voo amplo perto dos aliados. Isso permite sair da região inimiga em presets apropriados, sem perseguição ou mudança das posições aliadas. A decisão posterior abaixo aplica o modelo a toda a dungeon; valores definitivos de balanceamento continuam pendentes.

**Etapa anterior, substituída pela versão por semente:** todos os seis encontros de exploração usavam o modelo refinado, adaptado a suas formações e composição. Naquela etapa, A–E ficaram legados e o laboratório iniciava em F. A versão vigente descrita abaixo substitui essa seleção inicial. Perfis, trajetórias e números da aventura definitiva continuam abertos.

**Confirmado/implementado na versão por semente:** orientação para aliado com foco estável e alvo efetivo durante ação; terrestres sorteiam continuar/inverter; quantidade/duração de pausas variam pela semente, com pairar de voadores. RNG por participante separado de ações/alvos. Cinco novas formações; todos os presets anteriores são legados e os seis encontros usam a nova versão automaticamente. Ver `COMBATE_SEMENTE.md`. Faixas, probabilidades, durações, formações e política de retenção visual são escolhas técnicas de teste, não balanceamento definitivo. Não há implementação pendente de D44–D46; ajustes de sensação permanecem iterativos.

## Regras de combate ainda abertas

- **Futuro/fora do escopo até a pré-alfa, inclusive (D48, 26/10/2026):** possível movimentação inimiga mais orgânica sem rota fixa. Manter o modelo atual por semente nesse período. Caminhos conectados e escolha de destinos dentro de regiões foram alternativas discutidas, sem escolha, especificação ou autorização de implementação; reavaliar depois da pré-alfa não implica adoção obrigatória.
- Fórmula precisa de preenchimento da ATB em função da INI efetiva; caps e limites de buffs.
- **D50/D51 confirmado/implementado (26/10/2026):** Battle Speed 1..8 no menu; 1 mais lento, 8 mais rápido, padrão 4. Ritmos anteriores deslocados uma posição acima (antigo 3 → novo 4 etc.); nível 6 preserva a carga original anterior ao Battle Speed. Multiplicadores por nível são experimentais, somente para ATB, com escolha em memória durante a sessão. Ver `BATTLE_SPEED.md`. Balanceamento da escala e persistência em disco continuam pendentes; não altera Wait/Active nem resolve atendimento de vários prontos.
- **D49 confirmado/implementado (26/10/2026):** INI distinta entre os quatro tipos atuais, com valores experimentais Ágil 12, Voador 10, Pesado 7 e Estático 5. **Futuro:** definir valores por inimigo, independentemente do perfil de movimento. Balanceamento definitivo continua pendente; aliados e atendimento de múltiplos prontos não mudam.
- Quanto dura uma ação e em que instante a barra é zerada.
- Ordem de resolução de eventos simultâneos e de múltiplos inimigos prontos.
- **D52/D53 confirmado/implementado:** teclado/controle, mão nos cards/comandos/alvos, card escolhido destacado, cancelar por etapas e área centrada que acompanha o alvo até o impacto, sem fogo amigo. Ver `INTERFACE_BATALHA.md`. Teclas/botões, desenho e ritmos de repetição são experimentais; controle físico não foi validado. Detalhes restantes de simultaneidade/execução em Wait/Active continuam passíveis de refinamento, sem pendência da mira livre anterior.
- Como selecionar ações inimigas e suas respectivas probabilidades; pesos de perfis.
- Quem são alvos válidos com personagem incapacitado e habilidades de cura/ressurreição.
- Geometrias adicionais de área, raio definitivo, tamanho do campo, distâncias e balanceamento de efeitos. Mira circular centrada e indicação dos atingidos já foram definidas em D52/D53.
- **D54 confirmado no desenho (26/10/2026):** Ataque Físico, Defesa Física, Poder Mágico e Defesa Mágica separados para aliados/inimigos. Implementados no laboratório isolado D60 para experimentar a fórmula proporcional; valores, progressão e regras definitivos continuam pendentes. Combate integrado ainda usa a fórmula experimental anterior.
- **D55 confirmado (26/10/2026):** dano mínimo de 1 para ataques que atingem alvo válido. Valores, elegibilidade e ordem de cálculo dos críticos continuam pendentes.
- **D56 confirmado e esclarecido (26/10/2026):** armas definem chance e multiplicador de crítico; personagem tem chance-base, que afeta **somente a chance**. Itens e buffs de magia podem modificar essa chance; multiplicador permanece definido pela arma. Laboratório D60 permite testar composição aditiva, conversão de CRI, armas e modificadores numéricos. D63 confirma conversão 1 CRI = 1% e soma das contribuições. Valores por arma/modificador, limites finais, acúmulo/duração e casos sem arma continuam abertos; não há equipamento/buff real implementado nem multiplicador global 2×/3× aprovado.
- **D57 confirmado (26/10/2026):** rótulos HP, MP, INI, ATQ F, DEF F, MAG, DEF M e CRI usados na ficha do laboratório D60. Não há pendência de siglas; integração dos novos atributos ao combate permanece futura.
- **D58/D60 implementados (26/10/2026):** laboratório separado com lotes 10×/100×/1000×, ação única visual, resumo, distribuição e inspeção de amostras. HP/MP restaurados por amostra; sequência por semente e histórico. Próximo passo de design: avaliar resultados e ajustar números/fórmulas; integração ao jogo após validação. Ver [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).
- **D59/D69 confirmados:** HP, MP, ATQ F, DEF F, MAG e DEF M em **0..999 nos aliados** e **1..9999 nos monstros**; **INI e CRI em 1..99 para ambos**. Definir fórmulas de dano, conversão definitiva de INI para ATB, valores iniciais, progressão e limites com itens/buffs. Conversão de CRI para probabilidade aprovada em D63: 1 ponto = 1%. Não há solicitação de reescala do ATB atual; a faixa isolada não determinava a conversão percentual de CRI, agora aprovada em D63, nem altera automaticamente o combate.
- **D61 confirmado/implementado (26/10/2026):** exportação JSON da execução selecionada, com amostras completas e condições originais para estudo. Não há pendência da ferramenta solicitada; comparar e ajustar os resultados permanece atividade de balanceamento. Importação/save da aventura fora do recorte. Ver `LABORATORIO_DANOS.md`.
- **D62 — referência definida (26/10/2026):** inimigos iniciais levando cerca de 3–4 ataques básicos normais para serem derrotados; críticos podem reduzir a quantidade. Caso exportado documentado em `LABORATORIO_DANOS.md`. Valores concretos por inimigo, progressão e efeito do ritmo ATB/quantidade de participantes permanecem por validar; não alterar automaticamente o combate ou fixar todos nas fichas do exemplo.
- **D63 definido:** 1 ponto de CRI = 1% de chance-base, somado à chance da arma e aos bônus de itens/buffs. Não há pendência de conversão/composição; valores, limites finais e acúmulo/duração ainda a definir. Multiplicador permanece da arma.
- **D64 definido:** armas adicionam bônus ao ATQ F próprio; armaduras adicionam bônus à DEF F própria. Seleção de arma/armadura e composição implementadas apenas no laboratório (D66). Pendentes valores/progressão definitivos, limites efetivos do jogo, slots/troca e implementação na aventura. Exemplos de espadas e seus números não são catálogo/balanceamento aprovados; bônus mágicos adicionais ainda não definidos. Ver seção 7.5 do `GDD.md`.
- **D65 definido:** equipamentos somente nos aliados neste recorte; monstros mantêm atributos diretos, sem arma/armadura. Humanos/humanoides equipados ficam para o futuro. Seleção de equipamentos, composição próprio+bônus=efetivo e exportação implementadas no laboratório por D66; ver `LABORATORIO_DANOS.md`. Números das progressões são ponto de partida experimental.
- **D66 implementado:** equipamentos somente no aliado do laboratório, bônus/totais e JSON versão 2. Limite efetivo 999, multiplicadores próprios sem arma/monstro e valores por material são escolhas experimentais. O tratamento definitivo de personagens sem arma, limites e integração à aventura continuam pendentes.
- **D67 implementado:** Madeira removida das armas/armaduras do laboratório; demais materiais deslocados para bônus 10/16/24/34/48/65, começando em Bronze. Balanceamento definitivo continua pendente.
- **D68 — preferência definida (27/10/2026):** 30 HP para o monstro do cenário inicial de estudo, mantendo a meta de 3–4 golpes normais. Ajustar/testar DEF F e demais parâmetros; DEF F 60 com aliado ATQ F total 30 foi recomendação de teste, não valor definitivo aprovado. Não padronizar automaticamente todos os monstros.
- **D69 implementado no laboratório (27/10/2026):** seis atributos dos monstros em 1..9999; aliados e INI/CRI preservados. Amplitude aprovada, sem exigir que monstros comuns tenham números altos. Valores por inimigo/chefe e integração à aventura continuam pendentes.
- **D70 definido (27/10/2026):** protagonista começa sozinho na aventura; com armadura de Bronze, referência de resistência de 4–5 golpes físicos normais dos inimigos iniciais. Críticos podem reduzir essa quantidade. Queda do único ativo implica Game Over, conforme regra geral. HP/atributos iniciais, encontros e ritmo ATB continuam para balanceamento; exemplo HP 40/DEF F total 30 contra ATQ F 23 é sugestão, não valor aprovado. Protótipo de quatro personagens não foi alterado por esse registro.
- **D71 solicitado (27/10/2026):** presets reutilizáveis de aliado/monstro para o laboratório, evitando preencher fichas repetidamente. Proposta de seleção independente, salvar como/atualizar e persistência local autorizada e implementada em D72; ver `LABORATORIO_DANOS.md`. Fichas iniciais de estudo não são balanceamento definitivo.
- **D72 implementado:** presets reutilizáveis no laboratório, referências iniciais protegidas e personalizados persistentes com Salvar como/Atualizar. Controles globais e histórico independentes; nenhuma pendência da ferramenta solicitada. Importação de relatórios, salvar casos completos e salvamento da aventura não fazem parte desse recorte.
- Dano e valores dos atributos D54, fórmulas, efeitos de status, equipamentos, progressão e níveis.
- **Referência de estudo registrada em 26/10/2026:** guia de mecânicas de Chrono Trigger (SNES) no GameFAQs, indicado pelo usuário. Link e limites em [REFERENCIAS.md](REFERENCIAS.md). Somente guardar como referência por enquanto; nenhuma fórmula ou implementação nova foi aprovada por esse registro.
- Probabilidade de fuga, exceções de chefes, efeitos colaterais da fuga.
- Itens, custos de MP, economia, recuperação em pousadas e condições de salvamento.
- Política de encontro já derrotado ao retornar ao mapa (respawn/persistência); identidade de encontros fixa está definida, mas o respawn não.

## Exploração e narrativa ainda abertas

- História principal e evento que no futuro libera o protagonista da equipe.
- Número, nomes, classes e raças dos companheiros.
- Habilidades individuais no cenário e mapas necessários para utilizá-las.
- Identidade/nome/regras de acesso ao local especial de troca de membros.
- O seguimento reproduz o caminho do líder; transições locais entre casa e laboratório agora estão implementadas. Transições e escala dos mapas da aventura continuam pendentes. Movimento cardinal e ausência de colisão entre integrantes foram aprovados para este protótipo.
- Quais cenas exigem formação específica ou presença do protagonista.

## Sequência histórica sugerida (substituída para a primeira entrega)

O usuário priorizou explicitamente um laboratório de combate sem exploração. A lista original abaixo fica como contexto, não como ordem atual de execução.

1. Escolher engine/plataforma e aprovar um recorte minúsculo da primeira versão.
2. Montar cena de dungeon provisória, com quatro sprites em fila e troca de líder pelo menu.
3. Configurar um encontro visível que carrega tela separada com preset fixo.
4. Montar ATB e escolha entre personagens prontos, com INI fixa configurável.
5. Implementar um inimigo estático e um móvel com rota determinada; separar posição lógica e animação.
6. Adicionar uma habilidade de área e a seleção de alvos.
7. Adicionar comportamento programático ponderado a pelo menos dois perfis de teste.
8. Só então estender comandos, recursos, save, game over e múltiplos encontros conforme decisão do usuário.

Cada etapa depende de aprovação do plano; não significa que toda a lista caiba num único ciclo de desenvolvimento.
