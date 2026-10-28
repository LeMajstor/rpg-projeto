# Análise dos quatro relatórios mais recentes — 28/10/2026

**Conclusão:** os dados são coerentes com as fichas e equipamentos iniciais atuais. #1 bate mais forte e suporta mais acertos; #2 critica e esquiva mais frequentemente, mas é mais frágil. As novas famílias carregam os nomes atuais, porém **os estágios superiores não foram usados nestes quatro JSONs**. Nenhum preset foi alterado nesta análise.

## Fontes e condições

Arquivos em `exports/damage-lab/`, escolhidos por `exported_at_utc`:

- `danos-execucao-019-seed-421-1000x.json`: #1 → Monstro #1, 20:13:52 UTC.
- `danos-execucao-020-seed-421-1000x.json`: #2 → Monstro #1, 20:14:05 UTC.
- `danos-execucao-021-seed-421-1000x.json`: Monstro #1 → #1, 20:14:17 UTC.
- `danos-execucao-022-seed-421-1000x.json`: Monstro #1 → #2, 20:14:26 UTC.

Todos com1000 tentativas, ataque básico físico1×, variação±10%, crítico sorteado, esquiva habilitada, nenhum bônus de item/buff. Monstro HP45/ATQ24/DEF40/CRI3/EVA3. #1 revisão2, ATQ próprio23 + Bronze10 =33, DEF45+10=55, HP40, CRI10%, EVA5%. #2 revisão1, ATQ20+arco10=30, DEF30+couro5=35, HP36, CRI19%/1,6×, EVA7+5=12%. Ambos com presets sem edições locais.

Mesma semente421, trechos diferentes e consecutivos da sequência: posições12001–13000,13001–14000,14001–15000 e15001–16000. Estados finais/iniciais dos três RNGs encadeiam exatamente. Ter a mesma semente não significa ter os mesmos sorteios quando a sequência não é reiniciada.

## Ofensiva — lotes19/20

| Resultado | #1 | #2 |
| --- | ---: | ---: |
| Dano normal | 13–16 | 12–14 |
| Média normal | 14,958 | 12,858 |
| Crítico | 27–33 | 19–23 |
| Críticos observados | 85 | 204 |
| Críticos entre acertos | 8,82% | 20,84% |
| Chance configurada | 10% | 19% |
| Ataques evitados pelo monstro | 36 (3,6%) | 21 (2,1%) |
| Média por tentativa | **15,700** | **14,143** |
| Média teórica por tentativa | 15,919 | 13,920 |

Vantagem observada11,01%, contra14,36% teóricos da configuração. Os sorteios aproximaram os dois: menos críticos que a chance configurada para #1, mais para #2, e mais esquivas do monstro contra #1. O dano normal médio de #1 ficou cerca de16,33% acima, mas o resumo geral inclui os críticos e zeros das esquivas. Não ajustar atributos para perseguir exatamente15% em um único lote. Para comparação pareada, reiniciar a sequência com a mesma semente antes de cada aliado.

Contra45HP, a distribuição teórica de **acertos normais** é3 em56,80% e4 em43,20% para #1;4 sempre para #2. Com críticos/esquivas, tentativas esperadas3,31 e3,69. As últimas são estimativas matemáticas de dano acumulado, não lutas executadas no laboratório com ATB.

## Defesa — lotes21/22

| Resultado | #1 | #2 |
| --- | ---: | ---: |
| HP | 40 | 36 |
| DEF efetiva | 55 | 35 |
| Normal recebido | 7–8 | 9–11 |
| Crítico recebido | 13–16 | 18–21 |
| Esquivas observadas | 45 (4,5%) | 119 (11,9%) |
| EVA configurada | 5% | 12% |
| Média recebida por tentativa | **7,260** | **8,914** |
| Média teórica recebida | 7,195 | 8,844 |
| Acertos normais para cair | 5–6 | 4 |

#2 recebeu22,78% mais dano médio por tentativa, apesar da esquiva maior. Essa esquiva reduz parte da diferença, sem compensar totalmente a DEF menor; HP menor também reduz a resistência total. Confirma a diferenciação já discutida, sem sugerir um novo ajuste.

**Detalhe da referência5–6:** para #1, cinco acertos só derrubam se todos causarem8, pois5×8=40. Com a distribuição uniforme/arredondamento atual, isso ocorre em0,578% das sequências normais; seis em99,422%. Portanto, o protagonista fica praticamente no extremo de seis acertos normais. #2 cai em quatro normais sempre: três máximos somam33<36 e quatro mínimos somam36. Com críticos/esquivas, tentativas esperadas até cair são6,16 e4,45, respectivamente. Esquivas podem alongar e críticos encurtar.

## Alcance e recomendação

Os dados usam Bronze/Bronze e Arco Composto de Madeira/Traje de Couro. Confirmam a manutenção da ficha inicial e a composição de EVA/nome dos itens; não validam o balanceamento dos novos arcos/trajes superiores. A INI maior do segundo não entra no dano médio por ataque. HP/MP são restaurados a cada amostra: somar dano e dividir HP pela média não produz a distribuição real de uma luta com ATB.

Recomendação: manter os valores iniciais e comparar depois pares de equipamentos do mesmo estágio, com a mesma semente reiniciada e o mesmo alvo para cada par. Não fixar novos HP/DEF de inimigos superiores sem desenho posterior.

## Conferência independente

Executado `python3 artifacts/analise-lotes-019-022-2026-10-28/analisar.py`: **4000 amostras conferidas, zero divergências**. Verificados fórmula/arredondamento, sorteios, crítico/esquiva, HP/MP restaurados, composição próprio+bônus, contagens, médias, totais, histogramas e continuidade dos RNGs. Integração das probabilidades de dano arredondado e programação dinâmica para acertos/tentativas reproduzem as estimativas acima. Resultados em `resultados.json`. Nenhuma nova exportação ou batalha Godot foi criada.
