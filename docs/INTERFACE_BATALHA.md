# Interface de batalha — teclado, controle e mira por alvo

**Confirmado e autorizado em 26/10/2026 (D52/D53).** Fluxo de combate por teclado/controle, sem seleção por mouse. Mão provisória original nos cards, comandos e alvo em campo. Área exige um alvo central, acompanha sua posição até o impacto e não causa fogo amigo. Laboratório independente e encontros da exploração compartilham a implementação.

## Fluxo confirmado

1. Aguardar ATB e navegar pelos **cards inferiores dos aliados prontos**. A mão indica quem receberá o comando; só navegar não pausa Wait nem escolhe automaticamente um ator.
2. Confirmar o aliado transfere o foco para **Atacar / Habilidades / Itens / Fugir à direita**. Seu card fica destacado durante seleção e execução.
3. Habilidades/itens abrem suas listas. Confirmar uma ação abre a **mira em campo**, com a mão apontando para o inimigo ou aliado válido. Cura comum ignora incapacitados; reanimação só oferece incapacitados, conforme regras anteriores.
4. Confirmar o alvo inicia a ação. Os demais atingidos aparecem destacados na prévia. Ações em todos destacam o lado válido inteiro, sem restringir o efeito ao alvo de referência visual.
5. Cancelar volta **mira → lista de origem (quando houver) → comandos → cards**. Até voltar aos cards, o executor continua selecionado e Wait continua pausado. Cancelar antes de confirmar não gasta recursos. Uma ação já confirmada não é cancelada.

Não há comando Defender. Comando, alvo e custos continuam validados pelo modelo; indicação visual não altera posições, INI, perfis ou sorteios de movimento.

## Controles experimentais adotados

| Operação | Teclado | Controle |
| --- | --- | --- |
| Navegar | Setas | Direcional / analógico esquerdo |
| Confirmar | Enter ou Z | Botão sul (A no padrão Xbox) |
| Voltar uma etapa | Esc ou X | Botão leste (B no padrão Xbox) |
| Opções de combate | Tab | Start / Menu |

Opções permitem ajustar **Wait/Active e Battle Speed** sem mouse: cima/baixo escolhe a linha, esquerda/direita altera o valor e cancelar/Tab/Start volta ao foco anterior. Battle Speed permanece padrão **4**, com a escala D51 existente. No laboratório, confirmar após vitória/fuga inicia a próxima luta mantendo recursos; após derrota reinicia o teste. No encontro integrado, confirmar após Game Over reinicia o percurso explicitamente.

Os atalhos 1–4 e A/H/I/F permanecem como atalhos de teclado. F3, Espaço e F5 continuam ferramentas do laboratório. Seletores de preset, semente e depuração conservam sua interface de teste; o fluxo do jogador não depende deles nem aceita cliques em cards, comandos ou campo. A navegação por controle nesta entrega é da batalha; controles da exploração não foram ampliados.

**Escolhas técnicas experimentais:** cards seguem ordem da equipe; comandos usam a grade 2×2 à direita; listas percorrem opções disponíveis; alvos percorrem a ordem estável do encontro, não uma busca espacial recalculada a cada movimento. O analógico tem ativação em 0,55, liberação em 0,30 e repetição após 0,35 s a intervalos de 0,12 s. Valores, mapeamento de botões e aparência da mão não são interface/arte definitivas. Perda de foco/desconexão limpa repetição; campos de texto das ferramentas não acionam comandos.

## Área centrada e ausência de fogo amigo

- Área ofensiva precisa selecionar um adversário vivo como centro; ponto livre, aliado e ID inválido são rejeitados sem custo antes de confirmar.
- Círculo usa a **posição lógica atual** do alvo central. A mão acompanha sua posição visual, inclusive flutuação, sem mudar a geometria de efeito.
- Em Active, a prévia se atualiza enquanto os inimigos se movem. Durante a ação, o centro acompanha o alvo até o impacto. Os participantes dentro do raio são avaliados **nesse instante**, com a mesma regra usada pela prévia.
- Ações ofensivas afetam somente o lado adversário. Isso vale para aliados e inimigos: nenhum causa fogo amigo. Efeitos de recuperação usam o próprio lado e mantêm sua elegibilidade anterior.
- Antes de confirmar, alvo invalidado é substituído por outro válido; sem candidatos, retorna à lista/comandos. Executor incapacitado devolve foco aos cards.
- Se o centro for invalidado **depois** da confirmação, o efeito não troca automaticamente de alvo nem reembolsa o custo, preservando a política técnica T07. Não há ações simultâneas novas ou fila de comandos do jogador.

Tamanho do raio, custos, dano, tempo e geometria permanecem experimentais. Não foram criadas habilidades, inimigos ou arte definitivos. Melee, tela inteira, snapshots de rota, HP/MP e modos temporais permanecem.

## Arquivos e verificação

`combat_lab.gd` mantém somente o foco da interface e traduz eventos de teclado/controle para comandos do modelo. `battle_hand.gd` desenha a mão vetorial original. `battlefield.gd` desenha mão, raio e atingidos, com recorte no campo. `battle_model.gd` centraliza elegibilidade, consulta geométrica e efeito centrado no impacto; não depende de input ou desenho.

```sh
godot --headless --path . --script res://tests/centered_area_tests.gd
godot --headless --path . --script res://tests/battle_navigation_ui_smoke.gd
```

Teste manual: abrir o laboratório, aguardar prontos, usar setas/Enter ou controle para escolher card → Habilidades → Pulso → alvo. Em Active, observar a mão/círculo acompanhando o inimigo; cancelar uma etapa por vez. Testar Atacar, Onda, itens de HP/MP e reanimação, opções por Tab/Start e o mesmo fluxo em um encontro da dungeon. Os atalhos de depuração podem preparar condições de teste.

Cobertura automática: eventos reais de teclado/joypad na cena, seleção e custo, bloqueio de mouse, repetição/dead zone, retorno, incapacitação, cura/reanimação, opções, Game Over integrado e área com participantes entrando/saindo do raio. Resultados e capturas em [VALIDACAO.md](VALIDACAO.md). Controle físico ainda não foi inspecionado; a validação de joypad usa eventos simulados da engine.
