# Aflições com DEF M entre todos os presets — 29/10/2026

**Resultado:** 80.000 tentativas da versão D111, em80 lotes de1.000. As16 combinações de confronto/magia tiveram5.000 tentativas cada. Zero falhas funcionais ou divergências na conferência dos cálculos/sorteios. Nenhum atributo, preset ou código do jogo foi alterado por este estudo.

## Método e referências

Três presets atuais da biblioteca pessoal; dois aliados e um monstro. Quatro confrontos válidos, nos dois sentidos, com Veneno/Lentidão/Confusão/Medo. Aliado #1↔Aliado #2 permanece bloqueado pela regra sem fogo amigo. Sementes421,733,112,2026 e31415, reiniciadas a cada caso, iguais às do estudo anterior. Os16 lotes primários foram exportados completos em JSONv5 com fórmula `affliction_application_v2`; as outras sementes possuem resumos, estados e hashes reproduzíveis.

| Preset | MAG | DEF M | VIG | INT | EVA efetiva | MP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Aliado #1 | 20 | 21 | 25 | 20 | 5% | 12 |
| Aliado #2 | 20 | 21 | 20 | 20 | 12% | 14 |
| Monstro #1 | 25 | 28 | 20 | 15 | 3% | 8 |

Fórmula: `P(aplicar | sem esquiva) = MAG / (MAG + DEF M + VIG ou INT)`. Chance por tentativa = `(1 − EVA/100) × chance após EVA`. Mesmos4MP, HP/MP restaurados por amostra, sem dano direto/crítico e sem limites artificiais.

## Resultados atuais

Cada célula mostra **observado / esperado**, incluindo EVA. Ambas as magias de cada grupo foram executadas e obtiveram resultados idênticos com a mesma fórmula, resistência e sorteios.

| Atacante → alvo | Veneno / Lentidão | Confusão / Medo |
| --- | ---: | ---: |
| Aliado #1 → Monstro #1 | 28,86% / 28,53% | 31,06% / 30,79% |
| Aliado #2 → Monstro #1 | 28,86% / 28,53% | 31,06% / 30,79% |
| Monstro #1 → Aliado #1 | 33,74% / 33,45% | 36,00% / 35,98% |
| Monstro #1 → Aliado #2 | 33,32% / 33,33% | 33,32% / 33,33% |

Maior desvio absoluto observado/esperado: **0,33 ponto percentual** após5.000 tentativas por caso.

## Antes e depois de incluir DEF M

Valores observados, já com EVA, usando os mesmos presets e sorteios nas duas versões.

| Atacante → alvo | Veneno / Lentidão: antes → agora | Confusão / Medo: antes → agora |
| --- | ---: | ---: |
| Aliado #1 → Monstro #1 | 48,42% → 28,86% | 55,14% → 31,06% |
| Aliado #2 → Monstro #1 | 48,42% → 28,86% | 55,14% → 31,06% |
| Monstro #1 → Aliado #1 | 47,40% → 33,74% | 52,44% → 36,00% |
| Monstro #1 → Aliado #2 | 48,50% → 33,32% | 48,50% → 33,32% |

As esquivas foram idênticas nas mesmas posições dos sorteios. A única mudança de resultado foi Aplicou→Resistiu. O hash do arquivo de presets coincide com o estudo anterior.

## Análise

1. **DEF M reduziu a frequência de todas as aflições conforme esperado.** Contra o monstro, aplicações dos aliados passaram de48,42% para28,86% em Veneno/Lentidão e de55,14% para31,06% em Confusão/Medo. A DEF M28 do monstro passou a contribuir junto de VIG20/INT15.
2. **Os aliados continuam iguais ao lançar as magias.** Ambos têm MAG20 e enfrentam o mesmo alvo. Armas e crítico não influenciam o teste; mesma semente produz resultados idênticos.
3. **O monstro agora aplica com mais facilidade nesses confrontos.** Sua MAG25 enfrenta DEF M21 dos aliados, enquanto MAG20 dos aliados enfrenta DEF M28 do monstro. A maior MAG e as resistências dos alvos explicam os resultados; não se trata de bônus oculto.
4. **Aliado #1 e #2 estão quase empatados contra Veneno/Lentidão.** Chances teóricas33,45% e33,33%: EVA12% de #2 compensa VIG20 contra VIG25/EVA5% de #1. As taxas observadas33,74% e33,32% variam pelos sorteios. Em Confusão/Medo, #2 segue mais protegido pela EVA maior, com a mesma INT20 dos dois.
5. **A diferença entre aflições corporais e mentais ficou menor no monstro.** A vantagem teórica de aplicar Confusão/Medo em relação a Veneno/Lentidão passou de6,93 para2,26 pontos, pois DEF M28 agora compõe as duas resistências.
6. **Falhas têm mais peso mantendo4MP por tentativa.** A taxa por tentativa ficou próxima de30% a36% nesses presets. Isso não determina sozinho se o custo está equilibrado: duração e impacto das aflições em batalha continuam fora deste laboratório.

**Recomendação:** usar estes resultados como referência da versão aceita D111, sem alterar automaticamente atributos ou custo. O cálculo está coerente e reproduzível; a avaliação dos efeitos em batalha permanece posterior.

## Evidência e reprodução

- Execução primária: 48149 verificações, zero falhas;16.000 tentativas e reprodução exata da semente.
- Confirmação nas outras sementes: 128128 verificações, zero falhas;64.000 tentativas.
- Auditoria independente em Python: 147252 verificações, zero divergências sobre as16.000 amostras primárias, seus sorteios, recursos, resistência combinada e comparação com os registros antigos.
- `execucao.json`, `confirmacao.json` e `analise.json`: condições, resumos por caso/semente, comparações e auditoria.
- `01-poison.json` a `16-fear.json`: amostras primárias completas, chances e parcelas DEF M+VIG/INT.
- Sorteios são compartilhados entre magias, confrontos e versões para comparação. As80.000 tentativas não foram tratadas como um único conjunto de observações estatisticamente independentes.

Na raiz do projeto:

```sh
godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/inventario.gd
godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/executar.gd
godot --headless --path . --script res://artifacts/aflicoes-presets-defm-2026-10-29/confirmar_sementes.gd
python3 artifacts/aflicoes-presets-defm-2026-10-29/analisar.py
```

Os scripts de execução usam a biblioteca pessoal e a implementação vigentes. A confirmação pode ser reproduzida a partir das condições congeladas nos JSONs primários. A análise pareada usa os arquivos preservados da versão anterior em `artifacts/aflicoes-presets-2026-10-28/`.
