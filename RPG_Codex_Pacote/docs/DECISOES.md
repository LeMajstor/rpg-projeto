# Registro de decisões — RPG digital

**Atualizado em:** 23/10/2026. Use como índice rápido; detalhes completos em `GDD.md`.

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
