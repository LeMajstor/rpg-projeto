# Inimigos individuais e visão dos estáticos

**D158 — autorizado e implementado em 15/11/2026.** O mapa representa cada participante do encontro existente. Detecção individual, movimento conforme o tipo compartilhado da batalha e novos layouts com obstáculos para quebrar visão. Esta é a regra vigente da exploração; os registros D155–D157 descrevem suas etapas anteriores.

## Confirmado e implementado

Cada um dos seis encontros tem três participantes: **18 monstros visíveis, nove por andar**. Cada representante conserva o ID do encontro e o ID do participante do preset. Rótulos como `M1/E2 · Voador` permitem reconhecer o grupo e o tipo. Não há alerta compartilhado: um monstro pode perseguir enquanto outro do mesmo encontro continua patrulhando ou permanece estático.

Contato de qualquer representante móvel com o **líder atual** inicia a mesma batalha completa do encontro, com os três participantes e a formação existente. Os outros monstros não precisam se aproximar. Seguidores não detectam nem disparam encontros. M2 conserva a restrição de fuga na batalha.

Vitória ou fuga bem-sucedida remove todos os representantes daquele encontro do andar. Fuga falha continua a batalha. Remover o grupo não concede vitória ao resultado de fuga. HP/MP, incapacitação, Remédio e estados continuam preservados; fim de batalha limpa aflições pelas regras comuns. Reiniciar teste restaura os seis grupos.

## Movimento e parâmetros do teste

Patrulhas continuam em **rotas definidas em dados**. O perfil real do participante da batalha fornece velocidade de patrulha, aceleração, pausas e sorteio de sentido, com a mesma implementação de ritmos por semente. A geometria da rota no mapa é própria da exploração; não copia posições do campo de batalha. RNG de movimento do mapa é individual e separado dos RNGs do combate.

| Perfil | Patrulha/base (unidades/s) | Perseguição máxima (unidades/s) | Faixa territorial fixa da rota |
| --- | ---: | ---: | ---: |
| Pesado | 32 | 108 | 180 |
| Ágil | 72 | 144 | 240 |
| Voador | 90 | 162 | 320 |
| Estático | 0 | 0 | Sem perseguição |

**Parâmetros técnicos configuráveis para avaliar jogando**, sem balanceamento definitivo: detecção dos móveis em 180 unidades, líder 180 unidades/s e transição de velocidade em 0,3 s. Todos os perseguidores comuns são mais lentos que o líder. Velocidade não deriva da INI nem do Battle Speed. Voadores têm apresentação elevada/pairar, mas respeitam paredes, portas e limites físicos do mapa.

Território é medido a partir da **rota original fixa**, com largura por perfil. Novas percepções durante o retorno não deslocam nem ampliam esse território. Rotas terrestres abertas não recebem uma ligação fictícia entre último e primeiro ponto; voos fechados mantêm seu circuito. Perder visão por parede/porta encerra a perseguição na atualização seguinte. Sair da detecção ou do território também a encerra.

Ao desistir, o monstro procura a projeção ou vértice acessível próximo da rota. Quando necessário, usa sua trilha segura para recuperar uma ligação com a patrulha. Retoma segmento, progresso e ritmo na posição alcançada, sem teleportar nem voltar obrigatoriamente à posição inicial. Não há busca geral de caminhos, navegação livre ou geração procedural. Menu, diálogo, transição e batalha pausam o mapa, inclusive pausas/RNG dos monstros; andares inativos preservam seus estados.

## Estáticos: duas áreas simultâneas

O estático não patrulha nem persegue. Sua posição e orientação são fixas. Possui simultaneamente:

- **Círculo de proximidade:** raio60 unidades, em todas as direções.
- **Cone frontal:** alcance180 unidades e abertura total90°, centrado em `vision_direction`.

Entrar em **qualquer uma** das áreas com o líder inicia imediatamente o encontro completo, sem exigir contato físico ou E. **Paredes/portas bloqueiam ambas**; a presença geométrica na área atrás de uma parede não ativa a batalha. A verificação acompanha o segmento percorrido pelo líder para não ignorar uma entrada rápida nem a saída de uma sombra de parede. Seguidores e controles bloqueados não ativam os sensores.

F3 desenha círculo e cone, além das rotas, percepção e territórios dos móveis. As formas mostram a geometria nominal; os sólidos continuam bloqueando a ativação. Rotação futura do cone como movimento de cabeça foi mencionada pelo usuário e **permanece futura**, sem varredura automática nesta versão. Confrontos obrigatórios futuros podem reutilizar sensores; os layouts atuais possuem caminhos para evitá-los.

## Dois layouts distintos

Os pisos mantêm 2400×1600, câmera na escala comum e escadas com E/fade. São mapas autorados, provisórios e originais.

| Piso | Organização atual |
| --- | --- |
| Andar1 · galerias e passagens | Paredes construídas em L/T, quinas retas, passagens alternativas e ilhas de pedra. M1 a sudoeste, M2 a noroeste e M3 a leste. Alavanca/porta central, baú a leste e escada a nordeste. |
| Andar2 · cavernas e curvas | Paredes oblíquas, rochas irregulares e circuitos amplos com desvios. M4 a oeste, M5 a nordeste e M6 a sudeste. Escada de retorno a sudoeste. |

Cada piso contém três grupos e nove representantes. Existem corredores para romper visão e rotas acessíveis para escadas/saída sem tornar os estáticos confrontos obrigatórios. Objetos, entradas para até quatro integrantes, estado por andar e retorno ao piso da batalha permanecem. O mapa-múndi continua sem monstros comuns.

Mapa de orientação: [mapa-dungeon.svg](../artifacts/individual-enemies-2026-11-15/mapa-dungeon.svg). As linhas tracejadas representam as rotas originais; paredes continuam bloqueando os sensores.

## Fontes compartilhadas e implementação

- `data/lab.json`: participantes dos presets, tipos e perfis de movimento comuns.
- `data/exploration_combat.json` e `damage_v1_bridge.gd`: associação às fichas/regras atuais do combate, sem duplicar atributos.
- `data/dungeon.json` / `dungeon_upper.json`: grupos, `members` por ID do participante, posições, rotas e orientação estática, além dos layouts.
- `data/exploration_enemy_behaviors.json`: apenas extensões próprias da exploração, como perseguição, faixa territorial e sensores.
- `encounter_roster.gd`: expande os grupos usando o elenco real do preset; rejeita quantidade/ID de membros incompatível. Não inventa participantes nem posicionamento automático.
- `encounter_perception.gd`: sensores e interseção do caminho; `exploration_model.gd` aplica visão/colisão no chão.
- `encounter_motion.gd` / `patrol_territory.gd`: detecção individual, território fixo, perseguição e retomada.
- `route_behavior.gd`: implementação comum do ritmo; operação aditiva `relocate` reancora o ritmo somente na retomada da patrulha do mapa.
- `exploration_session.gd`: registra representante e grupo ativos; remove o grupo ao receber vitória/fuga bem-sucedida.

Não há cópia de fórmulas, fichas, custos, aflições ou regras de dano nesta entrega. Dados comuns continuam seguindo D150; laboratórios e batalha da exploração permanecem consumidores das mesmas referências.

## Desempenho do segundo andar

Correção técnica após relato do usuário em 15/11/2026: paredes poligonais inteiramente fora da câmera são descartadas antes da reconstrução do desenho, incluindo corretamente altura/topo no limite visual. O segundo piso tem 30 paredes poligonais e era mais afetado por esse trabalho desnecessário. Monstros fora da câmera continuam ativos, e colisões, visão e rotas não mudam. Custo de desenho na CPU caiu 28–46% nos dois pontos locais medidos; 19 comparações de pixels com a referência sem descarte foram idênticas. [Métricas, testes e limites](../artifacts/dungeon-performance-2026-11-15/README.md).

## Verificação executada

**75 suítes headless, 353.185 verificações, zero falhas.** A nova suíte `individual_enemies_tests.gd` possui 285 verificações: elenco/perfis comuns, rotas e acesso geométrico, territórios por tipo, detecção individual, reprodução por semente, retomada sem salto, sensores estáticos, paredes, seguidores e remoção conjunta dos representantes com estados preservados.

A cena principal foi exercitada por `exploration_pursuit_ui_smoke.gd`: 28 verificações headless e 37 gráficas Compatibility, com nove capturas. Testa os dois andares, grupo completo por sensor estático ou contato de voador, fuga falha/sucesso, vitória, preservação de recursos e reinício. Resultados e capturas em `artifacts/individual-enemies-2026-11-15/`.

```sh
godot --headless --path . --script res://tests/individual_enemies_tests.gd
godot --headless --path . --script res://tests/exploration_pursuit_ui_smoke.gd
python3 artifacts/individual-enemies-2026-11-15/run_regressions.py
```

**Pendente de avaliação do usuário:** naturalidade e distâncias jogando. **Futuro/fora de escopo:** cone giratório, fuga por diferença de nível, progressão/XP, recompensas/respawn definitivo, novos confrontos roteirizados e navegação geral.
