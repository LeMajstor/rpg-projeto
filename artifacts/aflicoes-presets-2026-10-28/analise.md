# Aflições entre todos os presets salvos — 28/10/2026

**Resultado:** 80 lotes de1.000 tentativas,80.000 tentativas analisadas. As16 combinações válidas de confronto/magia foram testadas com5.000 tentativas cada. Zero falhas de execução ou divergências na conferência dos sorteios. Presets e parâmetros do jogo não foram alterados.

## Configuração e cobertura

Presets reais da biblioteca pessoal, carregados pelo mesmo modelo do laboratório. Dois aliados e um monstro; confronto nos dois sentidos. Os dois sentidos Aliado #1↔Aliado #2 foram recusados pela regra vigente sem fogo amigo. Não houve mudança de facção, nem simulação de Confusão ativa para contornar essa regra.

| Preset | MAG | VIG | INT | EVA própria | EVA efetiva | MP | Revisão |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Aliado #1 | 20 | 25 | 20 | 5 | 5% | 12 | 2 |
| Aliado #2 | 20 | 20 | 20 | 7 | 12% | 14 | 1 |
| Monstro #1 | 25 | 20 | 15 | 3 | 3% | 8 | 1 |

Semente primária421:16 lotes/16.000 tentativas, exportados integralmente em JSONv5. Confirmação com sementes733,112,2026 e31415:64 lotes/64.000 tentativas. Mesma semente reiniciada em cada caso para comparar as mesmas posições dos sorteios. A repetição exata da semente primária também foi conferida, sem somá-la como nova observação estatística.

Fórmula pura: `P(aplicar | sem esquiva) = MAG / (MAG + VIG ou INT)`. Chance por tentativa: `(1 − EVA efetiva / 100) × P(aplicar | sem esquiva)`. Veneno/Lentidão usam VIG; Confusão/Medo usam INT. Custo4MP, HP/MP restaurados por tentativa; sem dano direto ou crítico.

## Resultados combinados

Cada célula mostra **observado / esperado**, já incluindo EVA. Veneno/Lentidão compartilham as mesmas chances e sorteios; o mesmo vale para Confusão/Medo. As duas magias de cada grupo foram efetivamente executadas.

| Atacante → alvo | Veneno / Lentidão | Confusão / Medo |
| --- | ---: | ---: |
| Aliado #1 → Monstro #1 | 48,42% / 48,50% | 55,14% / 55,43% |
| Aliado #2 → Monstro #1 | 48,42% / 48,50% | 55,14% / 55,43% |
| Monstro #1 → Aliado #1 | 47,40% / 47,50% | 52,44% / 52,78% |
| Monstro #1 → Aliado #2 | 48,50% / 48,89% | 48,50% / 48,89% |

O maior desvio absoluto entre observado e esperado foi **0,39 ponto percentual** após5.000 tentativas por caso. Na semente421 isolada houve desvios negativos de2,43 a3,69 pontos; a confirmação nas outras sementes aproxima os resultados da fórmula, sem alterar atributos ou filtrar resultados.

## Análise

1. **A fórmula e a ordem EVA→resistência estão coerentes.** A conferência independente dos16.000 registros primários recalculou resultado, chance, custo e estado de HP/MP. As64.000 amostras de confirmação também tiveram os sorteios e recursos conferidos.
2. **Os aliados têm o mesmo desempenho ofensivo de aflição.** Ambos usam MAG20 contra o mesmo monstro. Arco/espada, ATQ F/ATQ D e crítico não entram nesse teste; os resultados idênticos com sorteios compartilhados são esperados.
3. **O monstro é mais vulnerável a Confusão/Medo:** INT15 contra VIG20. A probabilidade por tentativa sobe de48,50% para55,43%, diferença teórica de6,93 pontos. Isso é uma consequência dos valores provisórios, sem concluir que os efeitos mentais são mais fortes no jogo.
4. **EVA compensa parte da VIG menor do Aliado #2.** Contra MAG25 do monstro, #1 tem VIG25/EVA5% e chance corporal47,50%; #2 tem VIG20/EVA12% e48,89%. A diferença teórica fica em1,39 ponto. Em aflições mentais os dois têm INT20, então EVA12% torna #2 mais resistente:48,89% de aplicação contra52,78% de #1.
5. **MAG25 do monstro não garante vantagem em qualquer confronto.** MAG maior melhora chance contra o mesmo alvo; entre alvos diferentes, VIG/INT e EVA também mudam. Os resultados próximos de50% são coerentes com atributos iniciais da mesma ordem de grandeza.
6. **4MP é relevante para as reservas atuais.** Sem recuperar MP, #1 com12MP e #2 com14MP comportam3 tentativas cada; Monstro #1 com8MP comporta2. Isso é uma leitura das fichas, não uma simulação de batalha: no laboratório, os recursos são restaurados por amostra.

**Recomendação:** manter estes valores como referência inicial para a avaliação do usuário. Os testes não apontam necessidade de corrigir a fórmula ou alterar atributos automaticamente. A eficácia de cada efeito em combate, duração e ticks continuam fora deste estudo.

## Evidência e reprodução

- Auditoria independente em Python: 128.162 verificações sobre relatórios/contagens e16.000 amostras primárias. sem divergências.
- Modelo Godot:32.149 verificações na execução primária,128.128 na confirmação, zero falhas.
- `execucao.json`: inventário, hash do arquivo de presets, resultados primários e pares bloqueados.
- `01-poison.json` a `16-fear.json`: todas as amostras primárias, condições e estados de RNG.
- `confirmacao.json`: contagens por semente/caso, estados e hashes das amostras de confirmação; os scripts permitem regenerá-las.
- `analise.json`: resultados combinados, desvios e intervalos de Wilson95% por caso.
- Intervalos por caso não representam intervalos independentes entre magias/confrontos: estes compartilham sorteios. Não foi feito agrupamento estatístico das80.000 tentativas como se fossem um único teste independente.

Na raiz do projeto, execute nesta ordem:

```sh
godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/inventario.gd
godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/executar.gd
godot --headless --path . --script res://artifacts/aflicoes-presets-2026-10-28/confirmar_sementes.gd
python3 artifacts/aflicoes-presets-2026-10-28/analisar.py
```

A execução utiliza a biblioteca pessoal disponível no momento. Para reproduzir somente a confirmação histórica, mantenha os JSONs primários e rode `confirmar_sementes.gd`, que lê as condições congeladas desses relatórios.
