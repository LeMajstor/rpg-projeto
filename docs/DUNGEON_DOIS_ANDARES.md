# Dungeon ampliada e patrulhas territoriais

**Atualização vigente — D158:** cada participante da batalha aparece no mapa: 18 monstros nos mesmos seis encontros, nove por andar, com detecção individual. Movimento reutiliza o perfil comum pesado/ágil/voador/estático; estáticos ficam imóveis e ativam a batalha por círculo 60 ou cone 180/90° simultâneos, ambos bloqueados por paredes e somente pelo líder. Móveis detectam a 180, com perseguição/território por perfil e retomada da rota fixa sem deslocar sua área. Vitória/fuga bem-sucedida remove os três representantes do grupo. Dois pisos refeitos: galerias em L/T e cavernas irregulares, com caminhos para romper visão. Escadas, recursos, câmera e regras de batalha preservados. Substitui representação única, patrulha obrigatória de todos e valores uniformes de D157. Ver [INIMIGOS_INDIVIDUAIS.md](INIMIGOS_INDIVIDUAIS.md).

O restante deste documento preserva o registro histórico anterior; representação e parâmetros uniformes foram substituídos por D158.

**D157 — autorizado e implementado em 15/11/2026.** O usuário solicitou refazer a dungeon, ampliar o espaço, acrescentar andares e permitir paredes irregulares para apreciar perseguição e retomada natural da patrulha. Escolheu expressamente **dois andares em áreas separadas, com escadas por E e fade**. Mantém rotas de patrulha definidas e território fixo em torno delas, sem ampliar a área a cada nova percepção.

## Espaço de teste

Cada piso tem **2400 × 1600 unidades**, contra1120 ×760 do mapa anterior. Dimensões, coordenadas, velocidades das patrulhas e apresentação continuam escolhas técnicas provisórias. A câmera mantém a escala comum anterior e acompanha o líder; não encolhe a dungeon para caber na tela.

| Piso | Organização |
| --- | --- |
| Andar1 · galerias e quinas | Saguão sul com saída ao mundo; salão aberto de M1; passagem entre paredes inclinadas e circuito de M2; portão/alavanca na galeria central; circuito leste de M3, baú e escada a nordeste. |
| Andar2 · circuito de rochas | Escada de chegada a sudoeste; circuito oeste de M4; galeria de ligação; circuito irregular entre rochas de M5 e patrulha longa de M6 na parte sudeste. |

Os **mesmos seis encontros**, IDs e presets de batalha permanecem, agora três por piso. Todos possuem rotas de patrulha no mapa, em vez de quatro deles ficarem parados. M2 continua bloqueando fuga **na batalha**; seu contato na exploração pode ser evitado. Baú/porta/alavanca continuam objetos de teste, sem recompensa ou inventário novo. O mapa-múndi permanece sem monstros comuns.

Paredes e rochas usam polígonos convexos combinados, com lados inclinados, quinas e ilhas centrais que quebram a visão. Piso, sombreamento, escadas, cores e marcas de orientação são geometria provisória original, sem assets de terceiros ou conteúdo narrativo novo.

Mapa de orientação externo ao jogo: [mapa-dungeon.svg](../artifacts/dungeon-expansion-2026-11-15/mapa-dungeon.svg).

## Perseguição e retomada

- Detecção inicial continua em **180 unidades**, com paredes/portas fechadas bloqueando visão.
- O território passa a ser uma **faixa fixa de240 unidades ao redor de toda a rota original**. Esse valor amplia o teste anterior, conforme a proposta discutida com o usuário. Substitui o círculo de120 em torno do ponto onde começava cada perseguição.
- Para perseguir, o líder também deve estar dentro desse território. Enxergá-lo fora da faixa não inicia nem mantém a perseguição. Novas detecções, inclusive durante retorno, **não deslocam a rota nem seu território**.
- Perder visão interrompe a perseguição na atualização seguinte; o inimigo deixa de seguir a posição do líder e procura retomar sua patrulha. Não busca o jogador atrás da parede.
- O inimigo caminha até a projeção acessível mais próxima ou um vértice acessível da sua rota e continua no sentido definido, atualizando segmento/progresso para esse trecho. **Não precisa retornar ao ponto onde saiu ou ao spawn.**
- A ligação direta com a rota deve caber no chão e não atravessar sólidos. Quando não existe ligação direta entre os candidatos avaliados, utiliza a trilha segura da perseguição somente até encontrar uma ligação. Não há busca geral de caminhos. Porta fechada pode fazê-lo esperar; não atravessa a porta nem teleporta.
- Velocidade máxima de perseguição permanece144 unidades/s, abaixo das180 do líder. Retorno e patrulha usam a velocidade de patrulha de cada encontro, com transição suave configurada em0,3 s como parâmetro técnico experimental. A retomada não muda INI nem velocidades dentro das batalhas.
- Contato só com líder inicia batalha automática; seguidores não disparam encontros. Menu/diálogo/transição/batalha pausam o mapa. Fuga bem-sucedida remove o encontro da sessão; vitória também. Recursos e remoção de aflições seguem as mesmas regras compartilhadas de combate.

Esta mudança supera D155/D156 somente no comportamento de patrulha/território/retorno do mapa. Fórmulas, fichas, equipamentos, repertórios, custos, aflições e rotas dentro da batalha continuam comuns aos três ambientes por D150. Não foi implementada fuga inimiga por nível, progressão/XP, recompensa de fuga, respawn definitivo ou encontros roteirizados novos.

## Andares e estado

O catálogo passa de cinco para **seis áreas**: duas casas, vila, mapa-múndi e dois pisos da dungeon. `test_dungeon` continua ligado ao mundo; `test_dungeon_upper` só é acessado pela escada do primeiro piso. O segundo piso retorna ao primeiro. Escadas usam o mesmo sistema de E, fade, validação de entrada e cache de áreas.

Os quatro lugares da fila são validados nas entradas, embora a equipe atual tenha três fichas aprovadas. Liderança, HP/MP, incapacitação, estoque, relógio/flags e estados dos objetos/encontros são preservados. Andar inativo mantém patrulhas e perseguições pausadas. Combate retorna ao andar onde começou. Reiniciar teste recria todos os estados; não há save em disco.

## Fontes e geometria

- `data/dungeon.json` e `data/dungeon_upper.json`: layouts, regiões, polígonos, rotas, objetos e acessos explícitos. Sem geração procedural em runtime.
- `data/areas.json.encounter_rules`: detecção180, faixa territorial240, perseguição144 e transição de velocidade0,3; uma configuração comum aos pisos e futuras áreas com encontros.
- `patrol_territory.gd`: projeções e distância à geometria imutável da rota. `encounter_motion.gd`: estados e retomada, preservando uma ligação segura com a rota ao perceber novamente durante o retorno.
- `wall_geometry.gd`: paredes convexas no chão, expansão pelo volume quadrado do líder, colisão varrida e oclusão de visão. `ExplorationModel` aplica a mesma geometria ao líder/inimigos, contatos, interações e validação de entradas. Margem técnica de0,05 unidade evita que arredondamento deixe o ator dentro da borda.
- `ExplorationView` e `ExplorationDepth`: desenham polígonos com altura provisória e ordenação pela base, separando posição lógica/visual. F3 mostra rotas, visão e faixas territoriais; não altera colisões.

Snapshots de áreas anteriores vivem exclusivamente em `tests/fixtures/areas_before_dungeon_expansion.json`. Regressões antigas que dependem dessas coordenadas usam `pre_expansion_catalog.gd` / `pre_expansion_screen.gd`, com o código atual. As novas suítes verificam os mapas atuais dos dois pisos, além das regressões existentes de tempo, relevo, eventos e profundidade. A cena jogável nunca carrega essas fixtures.

## Como experimentar

1. Abra `Executar exploracao.command`, saia da vila e entre na dungeon pelo mundo.
2. Explore o salão de M1 e tente atrair o inimigo por trajetos diferentes. Perceba que ele acelera, mas o líder ganha distância em caminho aberto.
3. Use quinas e paredes para quebrar visão. Observe a retomada de um trecho próximo da patrulha; tente aparecer novamente durante o retorno e confirme que ele continua limitado à região original.
4. Siga para a galeria central e acione a alavanca. Atravesse o portão e siga ao norte pela galeria leste até **Subir · andar2 [E]**.
5. No andar2, contorne as rochas entre patrulhas e observe os corredores inclinados. Contato só com o líder abre o combate existente; fuga bem-sucedida remove apenas o encontro daquele piso.
6. Desça e suba novamente: porta/baú e encontros removidos permanecem; HP/MP/estoque não são restaurados.

## Verificação

**74 suítes headless, 352.829 verificações, zero falhas.** Nova suíte `dungeon_expansion_tests.gd`:752 verificações, incluindo acesso geométrico aos dois pisos, todos os segmentos de patrulha, quatro lugares nas entradas, paredes inclinadas, território fixo após detecções repetidas, retomada próxima em vez da origem, quebra de visão, escadas/estado/KO/estoque/relógio e paridade dos seis encontros com o laboratório. A busca em malha é somente uma auditoria de acesso nos testes; o jogo não usa grade para navegar.

`exploration_pursuit_tests.gd`:77 verificações atualizadas às regras atuais. Interface da cena principal:26 verificações headless / **35 gráficas Compatibility**, nove capturas finais. Exercita os dois pisos, perseguição/pausa/retomada, escadas, retorno de combate ao piso2, fuga e persistência/reinício. Avaliação humana de naturalidade e layout continua aberta; testes verificam comportamento e não substituem essa avaliação.

```sh
godot --headless --path . --script res://tests/dungeon_expansion_tests.gd
godot --headless --path . --script res://tests/exploration_pursuit_tests.gd
godot --headless --path . --script res://tests/exploration_pursuit_ui_smoke.gd
```

Executor, logs, resultados, manifesto de fontes e imagens em `artifacts/dungeon-expansion-2026-11-15/`.
