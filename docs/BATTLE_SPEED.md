# Battle Speed — ritmo do ATB

**Confirmado em 26/10/2026 (D50, atualizado por D51):** configuração de 1 a 8, com **1 mais lento e 8 mais rápido**, conforme esclarecimento do usuário. **Padrão 4** (corrigido pelo usuário, mantendo a reescala). A escala anterior foi deslocada uma posição acima: antigo 3 → novo 4, antigo 4 → novo 5 etc. O nível **6 reproduz os tempos originais anteriores ao Battle Speed**. A escolha afeta aliados e inimigos igualmente, preservando diferenças de INI.

## Uso e comportamento

- Na exploração: abrir **Menu / equipe [Tab]** e escolher **Battle Speed**. O mapa permanece pausado no menu.
- No laboratório ou combate integrado: **Tab/Start** abre opções, cima/baixo escolhe Battle Speed e esquerda/direita ajusta. O seletor de teste continua disponível, separado do slider **Simulação (teste)**.
- Alteração vale para a carga seguinte, inclusive durante a batalha: não zera a barra parcial, não remove prontidão e não altera INI, HP/MP ou ações já iniciadas.
- A escolha acompanha a sessão entre áreas, entrada/retorno de combate e reencontros. Novo teste/Próxima luta no laboratório preservam o nível escolhido. **Reiniciar teste** da exploração cria uma sessão nova no padrão 4; reabrir o jogo também. Não há persistência em disco nesta entrega.
- Somente o incremento do ATB recebe o multiplicador. Movimento, pausas/sorteios das rotas, animações, duração/impacto das ações, exploração e relógio de dia/noite não são acelerados ou desacelerados por Battle Speed.
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

## Verificação

```sh
godot --headless --path . --script res://tests/battle_speed_tests.gd
godot --headless --path . --script res://tests/battle_speed_ui_smoke.gd
```

Cobertura: níveis monotônicos para os dois lados, deslocamento exato dos antigos níveis 1..7 para 2..8, nível 6 idêntico à carga original, padrão 4 mais lento, troca com carga parcial, limites, Wait e saturação, rotas/RNG idênticos sem ação, melee/tela inteira com duração/custo/dano/retorno iguais, menu e laboratório, escolha entre áreas, combate/retorno/reencontro, relógio independente e reinício global. Resultados executados em [VALIDACAO.md](VALIDACAO.md).
