# Monstro #1 contra os dois aliados — quatro lotes de1000

**Executado:**28/10/2026, Godot4.7.2/macOS. **Escopo:** contato e distância contra cada aliado, usando os presets pessoais atuais, sem alterar seus valores ou arquivos. Não houve simulação temporal com ATB.

## Método

O script `executar.gd` usa a biblioteca/modelo/calculadora/exportador reais do laboratório. Carrega os três presets pessoais, coloca o Monstro #1 como atacante e executa1000 ações em cada combinação. Ataque básico físico1×, MP0, variação±10%, CRI3%, crítico2× e esquiva habilitada. ATQ F e ATQ D do monstro são ambos24. Semente421 reiniciada antes de cada lote; conferidos os mesmos3000 sorteios e o mesmo estado RNG final nos quatro casos.

Os quatro JSONs nesta pasta foram exportados pelo Godot em versão4. Os presets pessoais foram comparados antes/depois e preservados integralmente. `analisar.py` recalcula as4000 amostras por fórmula independente, confere modo, ataque/defesa, dano, crítico/esquiva, HP/MP e resumos, e integra as probabilidades para estimar resistência com dano acumulado.

## Resultado observado

Médias por tentativa incluem zeros de esquivas e dano crítico.

| Ataque | Alvo | HP | Defesa usada | Base antes dos sorteios | Normal | Média recebida | Esquivas | Críticos |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| Contato | #1 | 40 | DEF F55 | 7,291 | 7–8 | **7,197** | 44/1000 | 21/1000 |
| Contato | #2 | 36 | DEF F35 | 9,763 | 9–11 | **8,783** | 123/1000 | 21/1000 |
| Distância | #1 | 40 | DEF D50 | 7,784 | 7–9 | **7,560** | 44/1000 | 21/1000 |
| Distância | #2 | 36 | DEF D40 | 9,000 | 8–10 | **8,094** | 123/1000 | 21/1000 |

Equipes e bônus:

- #1: bases DEF F45/DEF D45; metal inicial+10/+5, totais55/50; EVA5%.
- #2: bases DEF F30/DEF D30; traje inicial+5/+10, totais35/40; EVA7+5=12%.

Críticos possíveis pela fórmula: contato #1 de13–16, contato #2 de18–21, distância #1 de14–17 e distância #2 de16–20. Nestes1000 ataques, com apenas21 críticos por cenário, apareceram13–15,18–21,14–17 e16–19, respectivamente. Não observar o extremo máximo em um lote não altera o intervalo possível.

## Resistência

Os lotes restauram HP/MP por amostra. A tabela seguinte é **estimativa matemática**, usando probabilidades exatas da variação arredondada e programação dinâmica, com dano acumulado, sem cura ou ATB. Não dividir simplesmente HP pela média do lote para estimar a quantidade de tentativas.

| Ataque/alvo | Acertos normais para cair | Distribuição dos normais | Tentativas esperadas com críticos/esquivas |
| --- | --- | --- | ---: |
| Contato #1 | 5–6 | 5:0,58%;6:99,42% | 6,16 |
| Contato #2 | 4 | 4:100% | 4,45 |
| Distância #1 | 5–6 | 5:22,48%;6:77,52% | 5,92 |
| Distância #2 | 4–5 | 4:64,64%;5:35,36% | 4,84 |

O traje favorece o segundo contra disparos: média observada8,094 contra8,783 em contato, queda de7,84%. A armadura favorece o primeiro em contato:7,197 contra7,560 em distância, diferença de5,04% a mais recebido à distância. Ambos são efeitos relativos ao próprio personagem. O primeiro ainda recebe menos dano e tem maisHP nos dois tipos.

## Respostas e julgamento

**Está balanceado?** Como ponto inicial do laboratório, está coerente com o desenho aceito. #1 mantém a meta5–6 acertos normais para cair nas duas modalidades e é o integrante mais resistente. #2 é mais frágil em contato e melhora contra disparos. O benefício do couro está funcionando, sem transformá-lo automaticamente em maior defesa total que o metal.

**Está justo?** É uma distribuição defensiva plausível para os papéis definidos, com ressalva: #1 permanece mais resistente aos dois ataques; #2 não se torna o melhor resistente a distância, porque a base escolhida é menor. Seu conjunto também inclui maior INI e frequência de críticos, além da EVA maior, mas o efeito temporal dessas vantagens não foi medido nestes lotes. Portanto, não declarar justiça definitiva de batalhas/ATB a partir apenas das médias recebidas. Se o objetivo fosse #2 superar #1 especificamente na resistência a disparos, os valores atuais não atingiriam esse objetivo — ele não foi fixado como requisito.

**Os atributos correspondem ao dano?** Sim, numericamente. A seleção usa a defesa correta e a fórmula é `24²/(24+defesa)`:7,291/9,763 em contato e7,784/9,000 em distância. Variação±10%, arredondamento, crítico2× e zeros das esquivas reproduzem todos os resultados. Nenhuma divergência nas4000 amostras. Médias teóricas incluindo crítico/EVA são7,195;8,844;7,560;8,158, consistentes com os lotes.

**Recomendação:** manter os valores para a próxima etapa de testes. Não ajustar fichas para igualar resistências ou compensar a semente. Ainda validar ritmo ATB e, depois, estágios superiores/níveis. Nenhuma mudança de balanceamento foi feita nesta tarefa.

## Reprodução

```sh
godot --headless --path . --script res://artifacts/monstro-quatro-cenarios-2026-10-28/executar.gd --log-file /private/tmp/rpg-monstro-quatro-cenarios.log
python3 artifacts/monstro-quatro-cenarios-2026-10-28/analisar.py
```

JSONs completos, manifesto e análise numérica estão nesta pasta. Reexecutar usa os presets pessoais que estiverem salvos naquele momento; as condições exatas da execução aqui analisada permanecem nos quatro relatórios exportados.
