# Aflições com o mago — 01/11/2026

**Resultado:** 120.000 tentativas da versão D111 com três aliados e um monstro, quatro magias, dois sentidos e cinco sementes. Zero falhas nas execuções e na auditoria.

## Condições

MAG/DEF M naturais do mago30/30; Cajado de Madeira/Veste Simples somam10 cada, resultando40/40. HP30, MP24, INI7, VIG15, INT25, EVA3%; defesas físicas16+2=18. Aliados #1/#2 e Monstro #1 preservados.

Cada caso recebeu5.000 tentativas: sementes421/733/112/2026/31415 e mil amostras por semente. Mesmo fluxo RNG entre magias/confrontos para comparação; o conjunto não representa120 mil observações estatisticamente independentes. Recursos restaurados por amostra: o estudo não mede autonomia de MP, ATB ou duração/efeitos das aflições.

## Aplicações por tentativa, incluindo EVA

| Atacante → alvo | Veneno/Lentidão observado (teórico) | Confusão/Medo observado (teórico) |
| --- | ---: | ---: |
| Aliado #1 → Monstro #1 | 28,86% (28,53%) | 31,06% (30,79%) |
| Monstro #1 → Aliado #1 | 33,74% (33,45%) | 36,00% (35,98%) |
| Monstro #1 → Aliado #2 | 33,32% (33,33%) | 33,32% (33,33%) |
| Monstro #1 → Aliado #3 — Mago | 30,56% (30,31%) | 26,94% (26,94%) |
| Aliado #2 → Monstro #1 | 28,86% (28,53%) | 31,06% (30,79%) |
| Aliado #3 — Mago → Monstro #1 | 43,78% (44,09%) | 46,78% (46,75%) |

## Leitura dos resultados

O mago aplica aflições com mais frequência graças à MAG equipada40, contra20 dos demais aliados. A DEF M equipada40 reduz a aplicação inimiga; INT25 protege mais contra Confusão/Medo do que VIG15 contra Veneno/Lentidão. EVA3% mantém menor esquiva. Isso não substitui o teste futuro de fragilidade física e ritmo em batalha.

As16.000 amostras primárias anteriores mantiveram resultados e sorteios na precisão decimal dos JSONs (tolerância relativa1e-12); estados RNG textuais idênticos. Contagens das outras sementes anteriores também preservadas. Auditoria Python: 120492 verificações, zero divergências. Maior desvio observado/teórico: 0.33 ponto percentual.

## Reprodução

Na raiz do projeto, com a biblioteca pessoal contendo os quatro presets:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-study.log --path . --script res://artifacts/aflicoes-mago-2026-11-01/executar.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-confirm.log --path . --script res://artifacts/aflicoes-mago-2026-11-01/confirmar_sementes.gd
python3 artifacts/aflicoes-mago-2026-11-01/analisar.py
```

As condições congeladas estão nos24 JSONs primários; a confirmação usa essas condições, sem precisar da biblioteca pessoal. Relatórios anteriores permanecem intactos.
