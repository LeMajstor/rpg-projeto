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

- Fórmula precisa de preenchimento da ATB em função da INI efetiva; caps e limites de buffs.
- Quanto dura uma ação e em que instante a barra é zerada.
- Ordem de resolução de eventos simultâneos e de múltiplos inimigos prontos.
- Detalhes de modo Wait/Active para mira de área, seleção de alvo e animações.
- Como selecionar ações inimigas e suas respectivas probabilidades; pesos de perfis.
- Quem são alvos válidos com personagem incapacitado e habilidades de cura/ressurreição.
- Geometria das áreas, visualização de mira, tamanho do campo, distâncias e efeitos de alvo.
- Dano, atributos além de INI, fórmulas, efeitos de status, equipamentos, progressão e níveis.
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
