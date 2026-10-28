# Verificação dos JSONs após o ajuste — 27/10/2026

**Resultado:** o ajuste está carregado corretamente. Nos lotes atuais, Aliado #1 causou **13,24% mais dano médio por ataque** que Aliado #2, perto da direção de aproximadamente15%. A diferença teórica da configuração é14,36%; não há indicação de erro nem necessidade de novo ajuste com base nesses dois lotes.

## Fontes e condições

Dois JSONs mais recentes pelo horário interno de exportação, em `exports/damage-lab/`:

- `danos-execucao-010-seed-421-1000x.json`: 20:44:36 UTC, Aliado #1, preset revisão2, sem edição local, ATQ próprio23 + espada10 =33.
- `danos-execucao-011-seed-421-1000x.json`: 20:44:44 UTC, Aliado #2, preset revisão1, sem edição local, ATQ próprio20 + arco10 =30.

Mesmo Monstro #1 (HP45/DEF40/EVA3%), ação básica física1×, variação±10%, crítico sorteado e nenhum bônus de item/buff. Cada lote contém1000 tentativas. Mesma semente421, mas trechos consecutivos diferentes: posições9001–10000 e10001–11000. Os três estados RNG finais do primeiro coincidem com os iniciais do segundo.

| Resultado observado | Aliado #1 | Aliado #2 |
| --- | ---: | ---: |
| Normal | 13–16 | 12–14 |
| Média normal | 14,914 | 12,916 |
| Crítico | 27–33 | 19–23 |
| Média crítica | 29,989 | 20,417 |
| Críticos observados | 89 | 175 |
| Chance configurada | 10% | 19% |
| Críticos entre acertos | 9,26% | 18,04% |
| Esquivas do monstro | 39 (3,9%) | 30 (3,0%) |
| Média por tentativa | **15,674** | **13,841** |
| Média teórica por tentativa | 15,919 | 13,920 |

Diferença observada `(15,674/13,841 -1)×100 =13,243%`. Médias incluem críticos e esquivas com dano zero. Aliado #1 sofreu mais esquivas do alvo que os3% configurados e os críticos de ambos ficaram abaixo da chance configurada; oscilações compatíveis com lotes de1000. Não confundir esquivas do monstro nesses relatórios com EVA própria dos aliados.

## Leitura de balanceamento

A separação ofensiva pretendida aparece: primeiro com golpes mais fortes e picos críticos maiores, segundo com críticos mais frequentes. Contra45HP, os intervalos atuais preservam a referência de3–4 acertos normais para #1 e quatro para #2. Os dois ainda ficam em3–4 contra monstros de35–45HP. Críticos podem encurtar e esquivas acrescentar tentativas.

O laboratório restaura HP/MP por amostra: as2000 ações não são batalhas acumuladas. INI11 contra9 pode favorecer a frequência de ações do segundo no combate temporal, mas não entra no dano médio por ataque nem foi medida aqui. A direção de15% não é garantia de dano por segundo15% maior.

**Recomendação:** manter os valores atuais para o próximo teste. Não corrigir atributos para perseguir exatamente15% em um lote específico. Para comparar com os mesmos sorteios, usar Reiniciar sequência com a mesma semente antes de cada aliado.

## Verificação independente

Executado `python3 artifacts/balanceamento-aliados-pos-ajuste-2026-10-27/analisar.py`. Recalculadas e conferidas **2000 amostras**, incluindo dano, crítico/esquiva, HP/MP, contagens, resumos, extremos, condições, revisão do preset e continuidade dos três RNGs. Zero divergências. Integração exata da variação/arredondamento confirmou médias teóricas15,919 e13,920 (+14,36%).

Comparação adicional reaplicando as duas configurações aos mesmos sorteios exportados: vantagem de13,45% no trecho do lote10 e14,89% no trecho do lote11. São recálculos sobre as amostras, sem gerar novas exportações Godot e sem medir ATB. Resultados em `resultados.json`. Nenhum preset ou código de jogo alterado.
