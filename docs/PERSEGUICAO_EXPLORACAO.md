# Perseguição e contato com inimigos na exploração

**D159 — visão direcional autorizada e implementada em 15/11/2026:** móveis e estáticos usam visão frontal longa e periférica curta, orientadas pelo olhar e bloqueadas por paredes/portas. Substitui detecção circular dos móveis e círculo próximo dos estáticos. Parâmetros experimentais: frontal 180 unidades/90°, periférica 60/180°, costas sem percepção; contato físico com o líder continua iniciando a batalha completa de qualquer representante. Móveis olham no sentido do deslocamento e conservam orientação nas pausas; estáticos mantêm direção configurada. F3 mostra contornos recortados pelos sólidos. Mantém detecção individual, territórios fixos, perseguição/retomada, grupos e regras compartilhadas de combate. Varredura de cabeça permanece futura. Ver [VISAO_DIRECIONAL.md](VISAO_DIRECIONAL.md).

Descrições de círculos de percepção abaixo preservam a etapa D158 anterior; o catálogo jogável usa D159.

**Atualização vigente — D158:** cada participante da batalha aparece no mapa: 18 monstros nos mesmos seis encontros, nove por andar, com detecção individual. Movimento reutiliza o perfil comum pesado/ágil/voador/estático; estáticos ficam imóveis e ativam a batalha por círculo 60 ou cone 180/90° simultâneos, ambos bloqueados por paredes e somente pelo líder. Móveis detectam a 180, com perseguição/território por perfil e retomada da rota fixa sem deslocar sua área. Vitória/fuga bem-sucedida remove os três representantes do grupo. Dois pisos refeitos: galerias em L/T e cavernas irregulares, com caminhos para romper visão. Escadas, recursos, câmera e regras de batalha preservados. Substitui representação única, patrulha obrigatória de todos e valores uniformes de D157. Ver [INIMIGOS_INDIVIDUAIS.md](INIMIGOS_INDIVIDUAIS.md).

O restante deste documento preserva o registro histórico anterior; representação e parâmetros uniformes foram substituídos por D158.

**Atualização vigente — D157:** dois andares ampliados, todos os encontros em rotas definidas, território fixo em faixa de240 unidades ao redor da rota e retomada por trecho acessível próximo. Perda de visão cancela perseguição; novas detecções não ampliam o território. Detecção180 e velocidades144/180 preservadas. O limite120 e retorno obrigatório à origem descritos abaixo são históricos, substituídos por D157. Funcionamento, mapas e testes atuais em [DUNGEON_DOIS_ANDARES.md](DUNGEON_DOIS_ANDARES.md).

**D155 — autorizado e implementado em 15/11/2026.** Implementa D152–D154 com a recomendação P20 aceita pelo usuário: raio de detecção de **180 unidades lógicas**, perseguição de **144 unidades/s**, líder com **180 unidades/s**. O usuário também confirmou desistir ao sair dos 180 ou perder visão e retornar à patrulha.

**D156 — refinamento aprovado e implementado em 15/11/2026:** perseguição limitada a **120 unidades de afastamento da origem fixa**, onde o inimigo deixou a patrulha. Atingir esse limite provoca retorno mesmo com o líder ainda visível. A detecção permanece em 180 unidades entre inimigo e líder.

## Regras atuais

- Somente dungeons e demais áreas com encontros visíveis recebem esse comportamento. O mapa-múndi permanece sem monstros comuns.
- O inimigo detecta o **líder atual**, escolhido no menu, dentro de um círculo de 180 unidades. Paredes, portas fechadas e sólidos existentes bloqueiam a percepção.
- Ao detectar, abandona temporariamente sua patrulha e segue diretamente o líder a 144 unidades/s. INI e Battle Speed não controlam essa velocidade. Em caminho livre, continuar andando permite ao líder ganhar distância e escapar.
- Ao atingir120 unidades de afastamento do ponto de início da perseguição, superar180 unidades entre inimigo e líder ou perder a visão, desiste e retorna ao ponto exato em que deixou a patrulha, sem teleporte ou reinício do segmento/progresso. Completa o retorno antes de voltar a detectar; esta ordem de estados é uma escolha técnica do protótipo.
- **Contato somente com o líder** inicia automaticamente a batalha existente. Seguidores não disparam encontros; E permanece para NPCs, objetos e acessos. O contato vale também se o inimigo atingir o líder parado, durante patrulha, perseguição ou retorno.
- Menu, diálogo, transição e batalha pausam o movimento/percepção/contato. Áreas inativas conservam o estado, seguindo a sessão existente.
- **Fuga bem-sucedida em batalha remove o encontro visível**, como a vitória, e não reaparece ao sair e voltar à área. Fuga falha mantém a luta; M2 continua impedindo fuga na batalha. Resultado permanece `escaped`, sem conversão em vitória ou novas recompensas. HP/MP, incapacitação e estoque persistem; aflições terminam com a batalha.
- Reiniciar teste reconstrói os encontros e recursos da sessão. Novas regras de respawn da aventura continuam futuras.

Os seis encontros mantêm IDs, presets, posições/rotas originais de patrulha e combate, perfis de alvo, fichas e ações compartilhadas com os laboratórios. A remoção por fuga substitui a disponibilidade para reencontro que era usada na entrega D149.

## Escolhas técnicas e limites

`data/areas.json.encounter_rules` (`detection_radius:180`, `chase_limit:120`, `chase_speed:144`) é a configuração única para as áreas jogáveis com encontros; `AreaCatalog` a injeta no carregamento. Área sem encontros não recebe o comportamento, e mapa classificado como `overworld` é excluído. Validação recusa valores não positivos/não finitos e perseguição igual ou superior à velocidade do líder. Os números atuais são parâmetros aprovados para testar, não balanceamento definitivo de toda a aventura.

`encounter_motion.gd` mantém estados `patrol`, `chase` e `return`. A perseguição usa direção direta, com verificação do volume e do segmento contra obstáculos, sem busca de caminhos, navegação livre ou sorteios. Pode ficar bloqueada numa quina em vez de contorná-la automaticamente; perder a visão provoca retorno. O limite de120 é um círculo de centro fixo na posição onde a perseguição começou, não o comprimento acumulado do trajeto. Cada deslocamento é limitado à borda para não ultrapassá-la em passos fracionários/diagonais. O retorno refaz a trilha já percorrida, comprimindo trechos colineares. Porta fechada no retorno faz o inimigo esperar até o caminho ficar livre; a porta não fecha sobre seu corpo. O ritmo da rota de batalha permanece separado dessa trilha do mapa.

Contato usa centros no chão e distância de **24 unidades** na dungeon atual: duas vezes a meia extensão lógica existente de 12 do líder. É um volume técnico provisório, independente da altura visual dos sprites. `encounter_contact.gd` calcula o primeiro contato ao longo do deslocamento, evitando atravessar o inimigo em frames longos. Contatos simultâneos usam a ordem estável das entidades. A cena principal intercala movimento e avanço em passos de no máximo 1/120 s nas áreas com encontros; transições usam tolerância numérica para concluir o fade sem quadro residual.

`ExplorationSession` inicia o mesmo `BattleModel`; a UI abre a cena automaticamente, uma vez, via `_show_combat`. Apenas os catálogos históricos injetados por fixtures sem `encounter_rules` mantêm E/reencontro após fuga para regressão. Não são o comportamento da cena principal.

**D150:** esta mudança pertence ao mapa da exploração. Calculadora e laboratório independente continuam usando os mesmos dados e regras de combate, sem acrescentar perseguição a uma batalha em tela separada. A paridade dos cálculos/aflições e dos seis presets é verificada pela bateria completa.

**Pendentes/futuros:** fuga do inimigo por diferença de nível, referência e limiar de nível, XP/progressão, recompensas por fuga, respawn definitivo, exceções de encontros roteirizados e navegação mais elaborada. Nenhum desses sistemas foi incluído nesta implementação.

## Testar manualmente

1. Execute `Executar exploracao.command`, saia da vila para o mundo e entre na dungeon. O mundo permanece sem monstros.
2. Na sala de M1, aproxime o líder em caminho aberto. O inimigo avança; andar para longe aumenta a distância. Uma parede ou porta fechada impede a detecção.
3. Afaste o inimigo120 unidades do ponto onde começou a perseguir, saia do raio de visão ou esconda-se atrás de parede: o inimigo volta ao ponto de saída da patrulha. M3/M5 retomam seu percurso, preservando o progresso.
4. Abra o menu durante a perseguição; tudo pausa. Troque o líder pelo menu e feche: a posição da frente continua sendo a referência da perseguição.
5. Deixe o inimigo alcançar o líder ou encoste nele: a batalha abre sem E. Passar um seguidor pelo inimigo não basta.
6. Fuja com sucesso: o encontro desaparece. Voltar à área não o restaura; Reiniciar teste o restaura. M2 continua sem fuga em combate, mas é possível evitar seu contato na exploração.

F3 mostra raios de detecção/contato, o limite fixo120 em verde durante perseguição/retorno, e estados `patrulha`, `persegue`, `retorna`, além da trilha e sólidos. São marcas de depuração, ocultas no uso normal.

## Verificação automatizada

**D156 — validação atual:** 73 suítes headless, 352.388 verificações, zero falhas. Suíte de perseguição:385 verificações; interface:24 headless/29 gráficas, cinco capturas finais inspecionadas. Cobertura adicional de limite120 mesmo com líder ainda visível, borda exata, diagonal/passos fracionários, pausa/retorno e origem em patrulha móvel. Evidências em `artifacts/exploration-chase-limit-2026-11-15/`. Os números D155 abaixo são históricos.

**Bateria completa: 73 suítes headless, 352.113 verificações, zero falhas.** Teste gráfico Compatibility com 26 verificações e quatro capturas finais inspecionadas, sem falhas.

Suítes novas: `exploration_pursuit_tests.gd` (**112 verificações**) e `exploration_pursuit_ui_smoke.gd` (**22 headless / 26 gráficas**). Cobrem limites 180/181, paredes/portas, perda de visão, retorno exato e retomada de rota, porta fechada durante retorno, pausa, troca de líder, escape por movimento, contato só com líder, deslocamento longo, contato inimigo→líder parado, empate entre encontros, batalha única/modelo compartilhado, fuga falha/sucesso, recursos e persistência de área/reinício. As regressões de paridade foram atualizadas para remoção pós-fuga e novo início por contato.

```sh
godot --headless --path . --script res://tests/exploration_pursuit_tests.gd
godot --headless --path . --script res://tests/exploration_pursuit_ui_smoke.gd
```

Executor, resultados e capturas: `artifacts/exploration-pursuit-2026-11-15/`. Testes não substituem avaliação de gameplay pelo diretor criativo.
