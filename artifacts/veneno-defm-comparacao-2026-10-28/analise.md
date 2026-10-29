# Veneno: VIG versus DEF M + VIG — 28/10/2026

Experimento solicitado: duas rodadas de1.000 tentativas com Monstro #1 atacando Aliado #1 usando Veneno. Presets atuais da biblioteca pessoal carregados pelo modelo real. Semente421 reiniciada nas duas rodadas, preservando os mesmos quatro sorteios por tentativa.

Parâmetros: MAG do monstro **25**; VIG do aliado **25**; DEF M **21**; EVA efetiva **5%**. Veneno custa4MP; HP/MP restaurados em cada amostra. Revisões e fichas originais preservadas.

## Rodadas

| Medida | Atual: VIG | Proposta: DEF M + VIG |
| --- | ---: | ---: |
| Resistência usada | 25 | 46 |
| Chance de aplicação após passar por EVA | 50,00% | 35,21% |
| Chance calculada por tentativa, incluindo EVA | 47,50% | 33,45% |
| Aplicou | 444 | 309 |
| Resistiu | 512 | 647 |
| Esquivou | 44 | 44 |
| Aplicação observada por tentativa | 44,40% | 30,90% |

Fórmula atual: `25 / (25 + 25) = 50%` após EVA; por tentativa `0,95 × 50% = 47,50%`.

Fórmula proposta: `25 / (25 + 21 + 25) ≈ 35,21%` após EVA; por tentativa `0,95 × 35,21% ≈ 33,45%`.

## Comparação

- A soma de DEF M21 à VIG25 elevou a resistência total de25 para46.
- Nos mesmos sorteios, **135 tentativas passaram de Aplicou para Resistiu**. Nenhuma mudou de esquiva nem de resistência para aplicação.
- Redução observada: **13,50 pontos percentuais**, ou **30,41% menos aplicações** em relação à rodada atual.
- As44 esquivas ocorreram nas mesmas posições; a mudança veio exclusivamente do teste de resistência.
- Os percentuais observados não são a probabilidade exata da fórmula: cada rodada contém1.000 sorteios e pode ficar acima ou abaixo do esperado. Não foram adicionadas outras rodadas.

## Escopo e verificação

A proposta foi executada por uma cópia experimental isolada do calculador em `calculator_proposta.gd`, derivada do calculador vigente e alterando somente a soma de DEF M no cálculo da chance e no registro da resistência. O laboratório jogável e a biblioteca de presets não foram alterados. O segundo JSON identifica explicitamente a fórmula experimental e registra VIG, DEF M e resistência combinada; não confunde o experimento com a fórmula vigente.

Godot: **8147 verificações, zero falhas**. Auditoria independente em Python: **20145 verificações, zero divergências** sobre as2.000 amostras, fórmulas, sorteios, resultados e recursos. Nenhum dano, crítico ou efeito contínuo foi aplicado.

A adoção da nova fórmula permanece pendente de decisão do usuário. Este experimento não substitui a regra vigente D109/D110.

## Arquivos e reprodução

- `01-atual-vig-1000x.json`: rodada atual completa.
- `02-proposta-defm-vig-1000x.json`: rodada experimental completa.
- `execucao.json`: condições, resumo, hashes e verificações.
- `analise.json`: comparação, auditoria e índices das135 mudanças.

```sh
godot --headless --path . --script res://artifacts/veneno-defm-comparacao-2026-10-28/executar.gd
python3 artifacts/veneno-defm-comparacao-2026-10-28/analisar.py
```
