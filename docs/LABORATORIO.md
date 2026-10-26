# Laboratório de combate — escopo e teste manual

**Modelo vigente:** o laboratório abre em **Atual · comportamento por semente** e todos os seis encontros de exploração usam a nova versão, com formações variadas. Todos os dez presets anteriores são legados. Controles, configuração e testes em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md). As demonstrações anteriores abaixo são registros históricos.

**Autorizado pelo usuário em 23/10/2026.** Prioridade: funcionamento das mecânicas, com gráficos provisórios. Sem exploração, missões, níveis ou técnicas conjuntas. Godot + GDScript confirmados; fichas/números experimentais.

Atualização autorizada: curvas suaves/voo no preset C e aproximação melee com impacto/retorno, mantendo A/B e regras existentes. Consulte [MOVIMENTO_E_MELEE.md](MOVIMENTO_E_MELEE.md) para dados, fases e testes.

O preset D demonstra habilidades de tela inteira com deslocamento configurável por participante. Use **Habilidades → Onda**; em **F3 → Centro**, escolha um participante e use o padrão ou force centro/imobilidade. Consulte [TELA_INTEIRA.md](TELA_INTEIRA.md) para regras, configuração e roteiro de teste.

## Executar e controles

Consulte o [README](../README.md) para abrir `Executar laboratorio.command` ou executar `scenes/combat_lab.tscn` com F6 no editor. Desde a v0.2, F5 no editor inicia a exploração; F5 dentro da janela do laboratório reinicia o teste. O laboratório continua independente. A integração está em [EXPLORACAO_V02.md](EXPLORACAO_V02.md).

- Clique ou 1–4: selecionar aliado pronto. Cartões mostram HP/MP/INI/ATB.
- A/H/I/F: Atacar/Habilidades/Itens/Fugir. Sem Defender.
- Alvo único: clique no inimigo/botão. Item: clique no aliado/cartão/botão. Área: clique no campo para fixar centro. Todos: confirme o botão.
- Esc cancela sem custo e permite retomar Wait. Só estar pronto não pausa Wait: selecionar um aliado pronto pausa.
- Wait/Active podem ser alterados no menu superior.
- Trocar o menu de preset só tem efeito ao iniciar luta. Novo teste restaura dados iniciais; Próxima luta mantém recursos após vitória/fuga.

## Roteiro de aceite

| Teste | Procedimento | Resultado esperado |
| --- | --- | --- |
| Seleção | Aguarde vários prontos ou use F3 → Aliados prontos; escolha quarto e depois segundo. | Qualquer pronto selecionável; nenhum aliado age automaticamente. |
| Saturação | Deixe um pronto aguardando enquanto outro age. | ATB para em 100%, sem segunda carga. |
| Wait | Selecione pronto, abra Habilidades/mira e observe F3. | ATB/rotas param; Esc retoma. |
| Active | Repita em Active. | ATB/rotas continuam; inimigos podem agir durante escolha. |
| Posição lógica | Ataque e compare lógica/Δvisual no F3. | Só Δvisual muda; âncora aliada fixa, deslocamento volta a zero. |
| Rota | Observe inimigo antes/durante/depois de ação; use 0,25×/pausa/passo. | Segmento/progresso preservados e retomados exatamente; inclusive na Varredura. |
| Alvo único | Use Impacto em E1. | Só E1 recebe dano; técnica física também gasta MP. |
| Área | Use Pulso perto de uma rota em Active. | Prévia espacial; atingidos avaliados no impacto. Quem saiu pode não ser atingido. |
| Todos | Use Onda e confirme. | Todos os inimigos vivos recebem dano, independentemente da distância. |
| Itens | Reduza HP no F3; teste HP, MP e reanimação. | Estoque reduz sem gastar MP; cura comum não revive; reanimação não concede ação pronta. |
| IA | Observe decisões/pesos no F3 e reduza HP de um aliado. | Predador aumenta preferência, preservando outros vivos; incapacitados nunca entram. Outros perfis aparecem nos dois presets. |
| Fuga | Tente no A; repita para sucesso/falha. Inicie B. | Sucesso retira grupo; falha consome ação; B bloqueia sem consumir. |
| Presets | Inicie A, B e A novamente. | Formações diferentes entre A/B; A repete posições/rotas iniciais. |
| Recursos | Vença com HP/MP gastos/incapacitado; Próxima luta. | Recursos, estoque e incapacitação persistem; vitória não cura. |
| Derrota | Coloque todos em HP zero na depuração. | Game Over, sem continuação automática; Novo teste reinicia explicitamente. |

## Depuração

F3 abre janela móvel, fechável/reposicionável, com ATB de ambos os lados, coordenadas, Δvisual, segmento/progresso/direção e decisões com probabilidades. ATB inimigo nunca aparece normalmente. As rotas e coordenadas também são sobrepostas ao campo com F3.

Ferramentas: aliados prontos, restaurar HP/MP, ajustar HP e modificador de INI de um aliado. O modificador não altera a base. Enquanto se digita nos campos, atalhos do jogo não são acionados.

Pausa/velocidade ficam na barra superior. Passo avança 1/60 s, respeitando Wait: para avançar rotas, cancele a seleção ou use Active. Velocidade modifica toda a simulação, inclusive animações. Semente é aplicada ao iniciar luta; repetição exige os mesmos comandos/estado/timing.

## Limites

Sem save da aventura, equipamentos, buffs, narrativa ou criação de personagem. Salvamento restrito e carregar save após derrota continuam requisitos do jogo; este laboratório tem Game Over e reinício manual. Perfis/habilidades/itens não são conteúdo definitivo. Consulte [DECISOES_TECNICAS.md](DECISOES_TECNICAS.md).
