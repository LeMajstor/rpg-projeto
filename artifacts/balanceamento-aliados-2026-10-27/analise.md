# Comparação ofensiva dos aliados — 27/10/2026

**Status atual:** proposta revisada D87 adotada e aplicada em D88. Aliado #1 atualizado para ATQ próprio23/total33; #2 e Monstro #1 preservados. Seções anteriores registram o histórico do estudo.

Dois relatórios mais recentes pelo campo `exported_at_utc`: execução 005/seed112 (Aliado #1, 20:33:16 UTC) e execução 004/seed111 (Aliado #2, 20:33:01 UTC), em `exports/damage-lab/`. Ambos têm 1000 ações contra o mesmo Monstro #1: HP45, DEF40, EVA3%, ataque básico 1×, variação ±10%, crítico sorteado e nenhum bônus de item/buff.

| Medida observada | Aliado #1 | Aliado #2 |
| --- | ---: | ---: |
| ATQ efetivo | 30 | 30 |
| Dano normal | 12–14 | 12–14 |
| Média normal | 12,903 | 12,915 |
| Dano crítico | 23–28 | 19–23 |
| Críticos | 98 | 170 |
| Críticos entre acertos | 10,10% | 17,58% |
| Chance configurada | 10% | 19% |
| Esquivas do alvo | 30 | 33 |
| Média por tentativa, incluindo crítico/esquiva | 13,785 | 13,794 |

Diferença observada de apenas 0,009 de dano (0,065%). A média normal é igual em teoria, porque ambos usam ATQ30. O aumento da frequência de crítico do arco é quase compensado pelo multiplicador 2× da espada contra 1,6× do arco. Antes do arredondamento/esquiva: fatores médios 1,10 e 1,114. Com arredondamento e EVA3%, médias teóricas 13,746 e 13,920: arco cerca de 1,27% acima por ação. Sementes diferentes e menos críticos observados no arco que sua chance configurada aproximaram ainda mais os lotes. INI11 contra9 não entra nos relatórios de dano por ação nem autoriza inferir DPS real sem resolução temporal/animações.

## Recomendação anterior — substituída por D87

**Histórico:** a proposta de reduzir o Aliado #1 abaixo foi substituída pelo esclarecimento posterior de que ele deve causar cerca de15% a mais. Não aplicar essa proposta anterior.

Reduzir **ATQ próprio do Aliado #1 de 20 para 19**, mantendo espada +10, ATQ efetivo **29**, CRI10% e crítico2×. Não alterar o arco, a fórmula ou a defesa para este primeiro experimento.

- Normal: **11–13**; crítico: **22–27**.
- Média teórica por tentativa: **12,975**, contra 13,746 do primeiro atual e 13,920 do segundo atual. Redução de 5,61% no primeiro; segundo fica 7,28% acima dele (ou primeiro 6,79% abaixo do segundo).
- Reaplicando os 1000 sorteios do próprio JSON do primeiro: média **12,997**, contra 13,785 atuais. Essa comparação pareada mantém críticos/esquivas idênticos.
- Monstro HP40 passa a exigir quatro acertos normais; HP35 exige três ou quatro. Em HP45, quatro acertos normais em **99,776%** dos casos e cinco em **0,224%** (quatro danos11 somam44). Portanto, não garante estritamente a meta de 3–4 em todos os monstros até45HP. Sem assumir flexibilização dessa meta.
- Com críticos/esquivas e dano acumulado sem ATB/cura, tentativas médias contra45HP mudam muito pouco: 3,834→3,837, por causa dos limiares de HP. Redução do dano médio não implica redução proporcional da velocidade de abate neste alvo.

**Alternativa para preservar estritamente os 3–4 acertos normais:** manter ATQ30 e reduzir o multiplicador da espada de2× para1,6×. Mantém normal12–14, crítico19–23 e média teórica13,249; arco fica5,07% acima por ação. Essa alternativa muda a diferença entre os picos críticos das armas e também está apenas proposta.

Não recomendo começar com ATQ próprio18: média12,309, normal10–13 e cinco acertos normais em12,00% dos casos contra45HP. É uma mudança maior que a direção de reduzir um pouco.

## Verificação e reprodução

`python3 artifacts/balanceamento-aliados-2026-10-27/analisar.py` recalcula e confere dano, crítico/esquiva, HP/MP e resumos das2000 amostras originais. Integra as probabilidades exatas dos intervalos de dano arredondado e calcula a distribuição de acertos/tentativas por programação dinâmica, com esquivas incluídas apenas nas tentativas. Execução concluída sem divergências. Resultados em `resultados.json`; não é simulação de luta com ATB. Presets pessoais preservados.

## Direção corrigida — D87/P07 revisada

Usuário esclareceu: **Aliado #1 com média cerca de15% maior que #2**, por ataque, usando o mesmo alvo e ação para comparar. O objetivo anterior de reduzir #1 foi substituído.

**Recomendação para teste:** ATQ próprio #1 **20→23**, mantendo espada+10, chance total10% e crítico2×; total33. Aliado #2 permanece total30, chance19% e crítico1,6×.

| Resultado teórico contra DEF40/EVA3% | #1 proposto | #2 atual |
| --- | ---: | ---: |
| Normal | 13–16 | 12–14 |
| Crítico | 27–33 | 19–23 |
| Média por tentativa | 15,919 | 13,920 |
| Acertos normais contra HP35–45 | 3–4 | 3–4 |

Vantagem média de **14,36%**, próxima da referência15%, usando apenas um ajuste inteiro de atributo e sem mexer na fórmula. Em comparação pareada com os sorteios do JSON original de #1, sua média passa de13,785 para15,968; a porcentagem comparável para balanceamento usa as médias teóricas de ambos, evitando a diferença de sementes. Contra HP45, três acertos normais em56,80% e quatro em43,20%; dois nunca bastam para HP35–45 e quatro sempre bastam. Média de tentativas com críticos/esquivas contra45HP:3,306 para #1 e3,690 para #2. Isso não mede DPS/ATB.

**Ressalva:** máximo normal16 supera em um ponto a faixa inicial aproximada9–15. A meta3–4 continua preservada; validar essa pequena ampliação junto aos números propostos antes de editar presets. Os presets permanecem inalterados. Script atualizado e executado, com as2000 amostras originais novamente conferidas sem divergências; resultados teóricos em `resultados.json`.

## Aplicação autorizada — D88

Usuário autorizou alterar os presets. Atualização pontual por `damage_presets.gd.update`, primeiro validada em cópia temporária e depois aplicada à biblioteca real. Aliado #1 passou a ATQ próprio23 e revisão2; os demais campos e os outros dois presets foram comparados integralmente e preservados. Biblioteca reaberta, totais33/30 e extremos13–16/27–33 para #1 e12–14/19–23 para #2 confirmados na calculadora Godot contra Monstro #1. Lotes de1000 com cada aliado concluídos sem erro. Cópia anterior em `/private/tmp/rpg-presets-before-attack23-54345.json`; logs nesta pasta. Recarregar o preset no laboratório para atualizar uma ficha já aberta.
