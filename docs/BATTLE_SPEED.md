# Battle Speed — ritmo do ATB

**Confirmado em 26/10/2026 (D50, atualizado por D51):** configuração de 1 a 8, com **1 mais lento e 8 mais rápido**, conforme esclarecimento do usuário. **Padrão 4** (corrigido pelo usuário, mantendo a reescala). A escala anterior foi deslocada uma posição acima: antigo 3 → novo 4, antigo 4 → novo 5 etc. O nível **6 reproduz os tempos originais anteriores ao Battle Speed**. A escolha afeta aliados e inimigos igualmente, preservando diferenças de INI.

**D129 — direção confirmada em 10/11/2026, implementada no laboratório por D148:** ticks de Veneno acompanharão proporcionalmente o multiplicador de carga do ATB. Velocidades maiores aproximam os ticks em tempo real e menores os espaçam, mantendo 5% do HP máximo por tick. Isso amplia a regra anterior de afetar somente ATB para incluir Veneno; não amplia o efeito a rotas, animações, exploração ou dia/noite. Active mantém contagem/ticks no menu, Wait pausa e retoma o intervalo restante (D128). Não depende de INI individual ou de a vítima agir. **D130 confirma Battle Speed 4 como referência dos 5 segundos reais permitidos**, com o slider de simulação de teste em 1×. D148 integra o relógio de Veneno ao mesmo multiplicador no laboratório atual. D149 leva o mesmo relógio/regras aos encontros da exploração.

## Uso e comportamento

- Na exploração: abrir **Menu / equipe [Tab]** e escolher **Battle Speed**. O mapa permanece pausado no menu.
- No laboratório ou combate integrado: **Tab/Start** abre opções, cima/baixo escolhe Battle Speed e esquerda/direita ajusta. O seletor de teste continua disponível, separado do slider **Simulação (teste)**.
- Alteração vale para a carga seguinte, inclusive durante a batalha: não zera a barra parcial, não remove prontidão e não altera INI, HP/MP ou ações já iniciadas.
- A escolha acompanha a sessão entre áreas, entrada/retorno de combate e reencontros. Novo teste/Próxima luta no laboratório preservam o nível escolhido. **Reiniciar teste** da exploração cria uma sessão nova no padrão 4; reabrir o jogo também. Não há persistência em disco nesta entrega.
- **D148:** o incremento do ATB e o relógio de Veneno recebem o multiplicador, com normalização do Veneno no nível 4. Movimento, pausas/sorteios das rotas, animações, duração/impacto das ações, exploração e relógio de dia/noite não são acelerados ou desacelerados por Battle Speed.
- Wait, pausa manual, saturação em 100%, ausência de carga durante a própria ação e atendimento de múltiplos prontos mantêm as regras existentes. O slider de depuração continua escalando toda a simulação; manter em 1× para comparar níveis.

## Parâmetros experimentais em dados

O usuário confirmou intervalo, sentido, padrão e referência. Os multiplicadores intermediários abaixo são **escolhas técnicas experimentais**, ajustáveis em `battle_speed` de `data/lab.json`, sem balanceamento definitivo e sem alegação de reproduzir a fórmula de Chrono Trigger.

| Nível | Multiplicador de carga | Tempo relativo ao nível 6 |
| --- | --- | --- |
| 1 | 0,125× | 8× |
| 2 | 0,25× | 4× |
| 3 | 0,40× | 2,5× |
| **4 — padrão** | **0,60×** | **aproximadamente 1,67×** |
| 5 | 0,80× | 1,25× |
| **6 — referência original** | **1×** | **1×** |
| 7 | 1,25× | 0,8× |
| 8 | 1,50× | aproximadamente 0,67× |

**Limites da reescala:** os antigos níveis 1..7 passam integralmente aos novos 2..8; o antigo 8 deixa a faixa. Para completar o extremo lento, o novo 1 usa 0,125× (metade da carga do antigo 1), uma escolha técnica experimental ajustável. O padrão corrigido 4 equivale ao antigo nível 3. O antigo padrão 4 agora está no nível 5.

Fórmula experimental: incremento = `INI efetiva × 0,018 × multiplicador × segundos permitidos`. Tempo de zero até cheio = `1 / (INI efetiva × 0,018 × multiplicador)`, para INI positiva, sem interrupções e slider em 1×. INI efetiva zero não carrega.

| Participantes atuais | INI | Nível 6 | Padrão 4 |
| --- | --- | --- | --- |
| Aliado 2 / Ágil | 12 | 4,63 s | 7,72 s |
| Aliado 4 / Voador | 10 | 5,56 s | 9,26 s |
| Protagonista | 9 | 6,17 s | 10,29 s |
| Aliado 3 / Pesado | 7 | 7,94 s | 13,23 s |
| Estático | 5 | 11,11 s | 18,52 s |

Não existe sorteio do nível ou da INI. O modelo limita a escolha a 1..8; fixtures antigas sem a configuração mantêm multiplicador 1 para regressão histórica.

## Intervalo do Veneno — D129/D130, implementado em D148

O intervalo segue `5 × multiplicador_ATB(4) / multiplicador_ATB(nível)` segundos reais permitidos. Usar a razão entre multiplicadores preserva a referência no nível 4 mesmo se a escala experimental mudar. Pela configuração atual:

| Battle Speed | Intervalo entre ticks |
| --- | --- |
| 1 | 24 s |
| 2 | 12 s |
| 3 | 7,5 s |
| **4 — referência** | **5 s** |
| 5 | 3,75 s |
| 6 | 3 s |
| 7 | 2,4 s |
| 8 | 2 s |

Cada tick mantém 5% do HP máximo. Os tempos consideram simulação de teste em 1× e apenas o tempo permitido pelo modo: Active continua durante seleção no menu; Wait congela contagem e retoma o intervalo restante. D132 confirma congelamento do tempo de batalha durante toda execução de ação. D148 integra Veneno: ATB, rotas e seu relógio pausam juntos durante apresentação. Pausa manual congela a contagem. A proporção é relativa ao tempo permitido de carga de ATB, excluindo animações/pausas. Tick arredonda ao inteiro mais próximo, empate 0,5 para cima, mínimo 1 HP. Remédio D147 e integração temporal D148 estão funcionais no laboratório e, por D149, na exploração; magias de cura e recursos de reviver continuam futuros.

## Verificação

```sh
godot --headless --path . --script res://tests/battle_speed_tests.gd
godot --headless --path . --script res://tests/battle_speed_ui_smoke.gd
```

Cobertura: níveis monotônicos para os dois lados, deslocamento exato dos antigos níveis 1..7 para 2..8, nível 6 idêntico à carga original, padrão 4 mais lento, troca com carga parcial, limites, Wait e saturação, rotas/RNG idênticos sem ação, melee/tela inteira com duração/custo/dano/retorno iguais, menu e laboratório, escolha entre áreas, combate/retorno/reencontro, relógio independente e reinício global. Resultados executados em [VALIDACAO.md](VALIDACAO.md).
