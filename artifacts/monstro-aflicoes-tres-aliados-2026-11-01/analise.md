# Monstro #1 aplicando aflições nos três aliados — 01/11/2026

**Resultado:** 60.000 tentativas executadas agora, com zero falhas e zero divergências na auditoria. Somente Monstro #1 como atacante; Aliados #1, #2 e #3 — Mago como alvos. Nenhum atributo, equipamento ou preset alterado.

## Método

Quatro magias de 4 MP: Veneno/Lentidão contra DEF M + VIG; Confusão/Medo contra DEF M + INT. EVA anterior ao teste de resistência. Monstro #1 usa MAG 25, MP 8. Cada um dos 12 casos recebeu 5.000 tentativas: cinco sementes (421, 733, 112, 2026 e 31415), mil amostras por semente. Recursos restaurados por amostra; sem duração, ticks, efeitos contínuos, ATB ou autonomia de MP.

Mesmos sorteios entre alvos e magias, para isolar os atributos. Cada par de magias tem a mesma fórmula e obteve resultados idênticos; não tratar as cópias como observações estatisticamente independentes.

## Resistências com equipamentos iniciais

| Alvo | DEF M efetiva | VIG | INT | EVA efetiva | DEF M + VIG | DEF M + INT |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Aliado #1 | 21 | 25 | 20 | 5% | 46 | 41 |
| Aliado #2 | 21 | 20 | 20 | 12% | 41 | 41 |
| Aliado #3 — Mago | 40 | 15 | 25 | 3% | 55 | 65 |

## Aplicações por tentativa, incluindo EVA

| Alvo | Veneno/Lentidão observados (teóricos) | Confusão/Medo observados (teóricos) |
| --- | ---: | ---: |
| Aliado #1 | 33,74% (33,45%) | 36,00% (35,98%) |
| Aliado #2 | 33,32% (33,33%) | 33,32% (33,33%) |
| Aliado #3 — Mago | 30,56% (30,31%) | 26,94% (26,94%) |

## Resultados completos por magia

| Alvo | Magia | Aplicou | Resistiu | Esquivou |
| --- | --- | ---: | ---: | ---: |
| Aliado #1 | Veneno | 1687 | 3066 | 247 |
| Aliado #1 | Lentidão | 1687 | 3066 | 247 |
| Aliado #1 | Confusão | 1800 | 2953 | 247 |
| Aliado #1 | Medo | 1800 | 2953 | 247 |
| Aliado #2 | Veneno | 1666 | 2737 | 597 |
| Aliado #2 | Lentidão | 1666 | 2737 | 597 |
| Aliado #2 | Confusão | 1666 | 2737 | 597 |
| Aliado #2 | Medo | 1666 | 2737 | 597 |
| Aliado #3 — Mago | Veneno | 1528 | 3332 | 140 |
| Aliado #3 — Mago | Lentidão | 1528 | 3332 | 140 |
| Aliado #3 — Mago | Confusão | 1347 | 3513 | 140 |
| Aliado #3 — Mago | Medo | 1347 | 3513 | 140 |

## Interpretação

- O mago é o mais protegido contra as quatro aflições com o equipamento inicial. Sua DEF M 40 compensa VIG 15 e EVA 3% menores; contra Confusão/Medo, soma também INT 25. Isso preserva a distinção entre fragilidade física e resistência a aflições mágicas.
- #1 e #2 quase empatam contra Veneno/Lentidão: VIG 25/EVA 5% do primeiro contra VIG 20/EVA 12% do segundo. A EVA maior compensa a resistência específica menor.
- #2 evita melhor Confusão/Medo que #1 pela EVA maior, com a mesma DEF M 21 e INT 20.
- No mago, Confusão/Medo aplicam menos que Veneno/Lentidão porque INT 25 supera VIG 15. A diferença observada é de 3,62 pontos percentuais.

Maior desvio entre observado e teórico: 0,29 ponto percentual. Auditoria Python: 60148 verificações, zero divergências. Todos os resultados agregados reproduzem o estudo anterior quando condições e sementes são as mesmas.

## Acesso a magia — D116

Os dois primeiros aliados normalmente não usam magias no desenho do jogo. Condições/itens especiais que poderiam permitir isso pertencem a uma versão futura e ainda serão definidos. Seus atributos MAG/MP permanecem nas fichas; MP também serve a técnicas físicas especiais. Estudos anteriores com esses aliados lançando magias são comparações hipotéticas da ferramenta e não concessão dessa capacidade. Este estudo contém apenas o monstro lançando aflições nos três.

## Evidência e reprodução

- `execucao.json`: condições dos quatro presets, resumo dos 12 casos e hash da biblioteca preservada.
- `01-poison.json` a `12-fear.json`: 12.000 amostras primárias completas.
- `confirmacao.json`: 48.000 tentativas nas outras quatro sementes, resumos e estados RNG textuais.
- `analise.json`: auditoria independente e totais dos 60 lotes.

Na raiz do projeto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-monster-afflictions.log --path . --script res://artifacts/monstro-aflicoes-tres-aliados-2026-11-01/executar.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-monster-afflictions-confirm.log --path . --script res://artifacts/monstro-aflicoes-tres-aliados-2026-11-01/confirmar_sementes.gd
python3 artifacts/monstro-aflicoes-tres-aliados-2026-11-01/analisar.py
```

A execução primária usa a biblioteca pessoal vigente; a confirmação e auditoria usam as condições congeladas nos relatórios.
