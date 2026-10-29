# Validação da entrega


## Matriz de aflições com DEF M — 29/10/2026

Versão vigente D111 executada entre todos os presets salvos de lados opostos: Aliado #1 e Aliado #2 contra Monstro #1, nos dois sentidos, usando Veneno/Lentidão/Confusão/Medo. **16 casos ×5 sementes ×1.000 tentativas =80.000 tentativas analisadas**. Sementes421/733/112/2026/31415, iguais às do estudo anterior. Dois sentidos aliado↔aliado bloqueados pela regra sem fogo amigo. Nenhum atributo, equipamento, preset ou cálculo do jogo foi alterado pelo estudo.

| Atacante → alvo | Veneno / Lentidão observados | Confusão / Medo observados |
| --- | ---: | ---: |
| Aliado #1 → Monstro #1 | 28,86% | 31,06% |
| Aliado #2 → Monstro #1 | 28,86% | 31,06% |
| Monstro #1 → Aliado #1 | 33,74% | 36,00% |
| Monstro #1 → Aliado #2 | 33,32% | 33,32% |

Valores incluem EVA e são baseados em5.000 tentativas por confronto/magia. Chances teóricas correspondentes:28,53%/30,79% contra o monstro;33,45%/35,98% contra #1;33,33% em todos contra #2. **Maior desvio observado/esperado:0,33 ponto percentual.** Primária:48.149 verificações, zero falhas; confirmação:128.128, zero falhas; auditoria independente Python de16.000 amostras primárias e comparação pareada:147.252 verificações, zero divergências.

Presets brutos e fichas efetivas coincidiram com o estudo anterior. Mesmos quatro fluxos RNG e mesmas esquivas por tentativa em todas as versões/sementes; apenas aplicações viraram resistência. Contra o monstro, aplicações dos aliados caíram de48,42% para28,86% nas aflições corporais e de55,14% para31,06% nas mentais. #1/#2 estão quase empatados contra Veneno/Lentidão; a maior EVA de #2 mantém vantagem contra Confusão/Medo. O efeito real em batalha/duração continua fora deste estudo.

[Análise completa, comparações com a versão anterior, amostras e scripts](../artifacts/aflicoes-presets-defm-2026-10-29/analise.md). Sorteios compartilhados permitem comparação direta, sem tratar as80.000 tentativas como um único conjunto de observações estatisticamente independentes. Aviso ambiental conhecido de certificados do macOS no headless, sem erro de script ou falha funcional.


## DEF M nas quatro magias de aflição — D111, 28/10/2026

Fórmula adotada pelo usuário e implementada: `100 × MAG / (MAG + DEF M + VIG ou INT)`. Veneno/Lentidão usam VIG; Confusão/Medo usam INT. Mesmos presets, atributos, custo4MP, EVA anterior e quatro fluxos RNG. Sem limites artificiais na chance ou na soma. Interface mostra a decomposição da resistência; JSONv5 usa `affliction_application_v2` e registra parcelas/total. Relatórios históricos preservados; seus scripts usam calculador/exportador v1 congelados para reprodução.

**19 suítes headless aprovadas**, 17289 verificações, zero falhas. `damage_defm_tests`:1.165; `damage_affliction_tests`:4.142; `damage_affliction_ui_smoke`:32. Conferência gráfica Compatibility:35 verificações, três capturas, zero falhas. Logs e resultados por suíte em `artifacts/damage-lab-defm/test-results.json`. Capturas inspecionadas para campos, composição DEF M+VIG/INT, chances, resultados e amostras.

A produção reproduziu a rodada experimental aceita: MAG25, DEF M21, VIG25, EVA5%, semente421,1.000 tentativas → **309 aplicações,647 resistências e44 esquivas**. Mesmos estados/sorteios que a versão anterior;135 aplicações converteram-se em resistência. Casos de soma10998 acima do limite dos atributos próprios e chances abaixo5%/acima95%, DEF M zero válida no aliado, influência isolada de DEF M, preservação de HP/custo/ausência de crítico e snapshots foram verificados.

A compatibilidade real reabriu os três presets pessoais e reproduziu4.000 amostras físicas anteriores:24.071 verificações, zero falhas; arquivos/revisões e atributos/equipamentos preservados. Sem mudança de progressão, ticks, duração, efeitos contínuos ou combate integrado. Aviso ambiental conhecido de certificados do macOS no headless, sem erro de script nas execuções finais.



## Veneno com VIG versus DEF M + VIG — experimento P12, 28/10/2026

Duas rodadas solicitadas de1.000 tentativas cada, Monstro #1 atacando Aliado #1 com Veneno. Presets pessoais atuais: MAG25 do atacante; VIG25/DEF M21/EVA5% do alvo. Mesma semente421 reiniciada em cada rodada; os quatro sorteios e seus estados iniciais/finais conferidos como idênticos. Sem mudança de presets, atributos ou calculador do laboratório: proposta executada em cópia experimental isolada, com fórmula identificada nos relatórios.

| Cálculo | Chance após passar por EVA | Chance por tentativa incluindo EVA | Aplicou | Resistiu | Esquivou |
| --- | ---: | ---: | ---: | ---: | ---: |
| Atual, VIG | 50,00% | 47,50% | 444 (44,40%) | 512 | 44 |
| Proposta, DEF M + VIG | 35,21% | 33,45% | 309 (30,90%) | 647 | 44 |

Nos mesmos sorteios,135 aplicações viraram resistência; redução observada de13,50 pontos percentuais (30,41% menos aplicações). Esquivas idênticas nas mesmas tentativas. Godot:8.147 verificações, zero falhas; auditoria Python das2.000 amostras:20.145 verificações, zero divergências. Todas as tentativas preservaram HP, gastaram4MP e não produziram dano/crítico. As diferenças entre observado e calculado refletem os1.000 sorteios de cada rodada; nenhuma rodada adicional foi incluída.

[Comparação completa, JSONs e scripts](../artifacts/veneno-defm-comparacao-2026-10-28/analise.md). Adoção de DEF M permanece pendente; fórmula vigente D109/D110 preservada. Aviso ambiental conhecido de certificados do macOS no headless, sem erro de script.


## Aflições entre todos os presets salvos — 28/10/2026

Executados pelo modelo real os quatro confrontos válidos dos três presets pessoais, nos dois sentidos, com Veneno/Lentidão/Confusão/Medo. **16 casos ×5 sementes ×1.000 tentativas =80.000 tentativas analisadas**, além da reprodução exata da semente primária. Aliado #1↔Aliado #2 recusado pela regra sem fogo amigo, sem alterar facção ou simular Confusão ativa. Nenhum parâmetro ou preset foi alterado.

Semente primária421:16 lotes com JSONv5 completo e32.149 verificações, zero falhas. Confirmação733/112/2026/31415:64 lotes e128.128 verificações, zero falhas. Auditoria independente em Python dos16.000 registros primários:128.162 verificações de fórmula, sorteios, recursos, índices e contagens, zero divergências. Maior desvio observado/esperado após5.000 tentativas por caso: **0,39 ponto percentual**. Presets/arquivo pessoal preservados integralmente.

Resultados combinados observados, já incluindo EVA: aliados→monstro **48,42%** para Veneno/Lentidão e **55,14%** para Confusão/Medo; monstro→#1 **47,40%/52,44%**; monstro→#2 **48,50%** nos quatro. Referências reais: MAG20/20/25, VIG25/20/20, INT20/20/15 e EVA efetiva5%/12%/3%. A EVA do #2 compensa quase toda a menor VIG nas aflições corporais e o protege mais nas mentais. Os aliados têm aplicação idêntica por compartilharem MAG20 e o mesmo alvo. Não há conclusão sobre duração/intensidade dos efeitos em batalha nem ajuste automático de balanceamento.

Método, resultados por semente, condições congeladas, amostras primárias, scripts reproduzíveis e análise em [aflicoes-presets-2026-10-28/analise.md](../artifacts/aflicoes-presets-2026-10-28/analise.md). As magias/confrontos compartilham sorteios para comparação; não foram tratados como80.000 observações estatísticas independentes nem usados para multiplicar artificialmente a confiança nos resultados. Aviso ambiental conhecido de certificados do macOS no headless, sem erro de script ou falha funcional.


## INT/VIG e magias puras de aflição — D110, 28/10/2026

Implementação autorizada após D99–D109. Executada com Godot4.7.2 Standard/macOS. **18 suítes headless aprovadas**, zero falhas nas execuções finais; resultados e logs em `artifacts/damage-lab-afflictions/`.

| Verificação | Resultado |
| --- | --- |
| `damage_affliction_tests.gd` | 4.138 verificações, zero falhas. |
| `damage_affliction_ui_smoke.gd` headless | 31 verificações, zero falhas. |
| Mesma suíte com renderização Compatibility | 34 verificações, três capturas, zero falhas. |
| Dezesseis suítes anteriores de danos/equipamentos/EVA/presets/UI/exportação | Todas aprovadas; contagens em `test-results.json`. |
| Compatibilidade de presets e relatórios pessoais | 3 presets e4.000 amostras;24.071 verificações, zero falhas. |

Cobertura: quatro magias, VIG/INT corretas, curva pura incluindo probabilidades abaixo5%/acima95%, fronteiras de sorteio, EVA anterior, permissão por ação, três resultados exclusivos, nenhum dano/mínimo1/crítico, gasto4MP em todos os resultados, recursos restaurados por amostra e bloqueio por MP insuficiente. Campos1..999 nos dois lados, validação de números inválidos, edição, inversão de lados, salvar/atualizar/reabrir e compatibilidade por leitura. RNG independente, mesma semente, continuidade entre lotes, mudança de semente, exportação/restauração dos quatro estados de64 bits, histórico imutável, chances condicionais/totais e lotes totalmente esquivados sem divisão por zero. JSONv5 identifica a fórmula de aplicação e sua ordem, preservando exportações de dano.

`verify_compatibility.gd` nesta pasta confirmou referências #1 INT20/VIG25, #2 INT20/VIG20 e Monstro #1 INT15/VIG20, preservando todos os atributos anteriores, revisões e conteúdo do arquivo pessoal. Reproduziu4.000 amostras físicas anteriores com os mesmos sorteios e os mesmos dano/HP removido/crítico/esquiva/HP/MP finais. Leitura não regravou presets nem relatórios. Combate integrado e seus dados não foram alterados.

Capturas `affliction-poison-summary.png`, `affliction-samples.png` e `affliction-evaded.png` inspecionadas: campos, resumo, probabilidades, tabela, gráfico e mensagem no duelo legíveis, com edição rolável e resultados dentro da janela1440×960. A suíte antiga de UI foi atualizada para a regra de crítico apenas físico; testes de exportação atualizados para versão5. A avaliação de balanceamento e a validação do usuário continuam posteriores; não há duração/ticks ou efeito de aflição ativo em batalha.

Avisos ambientais conhecidos no headless: consulta aos certificados do macOS e consulta a um arquivo temporário ainda inexistente durante o teste de diálogo de exportação. Sem erros de script nas execuções finais. Controle físico e outras plataformas não testados.


## Quatro lotes do Monstro #1 — contato/distância, 28/10/2026

Executados pelo modelo real do laboratório **4×1000 ataques**, usando os presets pessoais atuais, semente421 reiniciada em cada caso e mesmos sorteios verificados. Contato contra #1/#2 e distância contra #1/#2. Ataques24/24, potência1×, variação±10%, CRI3%/2×, EVA5%/12%. Arquivo pessoal preservado.

Médias recebidas: contato **7,197/8,783**; distância **7,560/8,094**. Normais7–8/9–11 e7–9/8–10. Defesas efetivas55/35 em contato e50/40 em distância; seleção e composição corretas. Conferência independente das **4000 amostras sem divergências**, incluindo sorteios, dano, crítico/esquiva e HP/MP. Acertos normais para cair5–6/4 em contato e5–6/4–5 em distância; estimativas de resistência acumulada calculadas separadamente, sem ATB.

Conclusão: especializações das proteções funcionam, com #1 ainda mais resistente nos dois modos pelas bases/HP; #2 melhora contra disparos em relação ao contato. Valores iniciais coerentes para manter, sem concluir justiça temporal de batalha a partir desses lotes. Nenhum ajuste de atributos. Quatro JSONsv4, scripts reproduzíveis, log e análise em `artifacts/monstro-quatro-cenarios-2026-10-28/`.

## ATQ D/DEF D e proteções com duas defesas — D94

Executada em **28/10/2026**, Godot4.7.2/macOS. **Dezesseis suítes headless aprovadas**, zero falhas nas execuções finais:

| Suíte | Verificações |
| --- | ---: |
| `damage_distance_tests` | 73 |
| `damage_distance_ui_smoke` | 22 |
| `damage_lab_tests` | 3.201 |
| `damage_equipment_scales_tests` | 512 |
| `damage_equipment_scales_ui_smoke` | 48 |
| `damage_equipment_exclusivity_tests` | 73 |
| `damage_equipment_exclusivity_ui_smoke` | 15 |
| `damage_equipment_tests` | 66 |
| `damage_export_tests` | 2.280 |
| `damage_evasion_tests` | 4.093 |
| `damage_presets_tests` | 88 |
| `damage_enemy_ranges_tests` | 1.208 |
| `damage_lab_ui_smoke` | 116 |
| `damage_presets_ui_smoke` | 53 |
| `damage_ally_02_tests` | 46 |
| `damage_ally_02_ui_smoke` | 28 |

Cobertura nova: pares independentes ATQ F/DEF F, ATQ D/DEF D e MAG/DEF M; arma determina modo automático do aliado, monstro contato por padrão, overrides físicos e magia independente. Arco não soma ATQ F; espada não soma ATQ D. Todos os estágios de metal/traje têm prioridades opostas;36 combinações verificam também DEF D. Bases45/30 e bônus iniciais5/10 compõem DEF D50/40. Valores inválidos, zero/zero, limites com soma bruta, modo canônico, compatibilidade legada, persistência de bônus editados, histórico imutável, campos/teclado, novo seletor e JSONv4 por amostra aprovados. O teste de clique da UI geral agora revela o campo antes de clicar, compatível com a ficha mais alta.

Execução gráfica específica: **25 verificações e três capturas**, zero falhas. `first-defenses.png`, `bow-and-dual-armor.png` e `ranged-source-picker.png` inspecionadas em `artifacts/damage-lab-distance/`: atributos, duas composições de defesa, bônus de arco e modo da ação legíveis. Nenhuma animação nova foi criada.

Compatibilidade real: `verify_existing.gd` na mesma pasta reabriu **os três presets pessoais** e reproduziu **4000 amostras dos relatórios19–22** com seus sorteios originais. **24.024 verificações, zero falhas**, comparando dano, HP removido, crítico, esquiva e HP/MP finais. Atributos antigos, bônus existentes, revisões e arquivos pessoais/relatórios foram preservados; campos ausentes foram completados somente em memória. #1 revisão2 agora mostra próprios ATQ F/D23/10 e DEF F/D45/45, efetivos33/10 e55/50; #2 revisão1 mostra20/20 e30/30, efetivos20/30 e35/40.

Logs finais na pasta das capturas. Avisos ambientais conhecidos de certificados/consulta ao destino temporário no headless, sem erros de script nas execuções finais. Controle físico e outras plataformas não testados.

Para repetir na raiz:

```sh
godot --headless --path . --script res://tests/damage_distance_tests.gd --log-file /private/tmp/rpg-distance-tests.log
godot --headless --path . --script res://tests/damage_distance_ui_smoke.gd --log-file /private/tmp/rpg-distance-ui.log
godot --path . --script res://tests/damage_distance_ui_smoke.gd --log-file /private/tmp/rpg-distance-graphics.log -- --visual-captures=res://artifacts/damage-lab-distance
godot --headless --path . --script res://artifacts/damage-lab-distance/verify_existing.gd --log-file /private/tmp/rpg-distance-existing.log
```

## Relatórios19–22 — ofensiva e defesa iniciais, 28/10/2026

Analisados os quatro JSONs mais recentes,1000 amostras cada, semente421 com trechos consecutivos dos três RNGs. #1 revisão2 com ATQ33/DEF55/HP40/EVA5; #2 revisão1 com ATQ30/DEF35/HP36/EVA12. Presets sem edição local, ambos no equipamento inicial.

Médias ofensivas15,700 e14,143: #1 **11,01% acima no lote**, contra14,36% esperados pela configuração. Mais críticos e menos esquivas do alvo favoreceram #2 nesse trecho. Médias recebidas7,260 e8,914, normais7–8 e9–11; esquivas4,5% e11,9%, coerentes com5% e12% configurados. Acertos normais para cair5–6 (quase sempre6) para #1 e4 para #2.

Cálculo independente conferiu **4000 amostras sem divergências**, incluindo dano, HP/MP, composição, contagens, resumos, histogramas e continuidade RNG. Estudo e script reproduzível em `artifacts/analise-lotes-019-022-2026-10-28/`. Não houve teste de equipamentos superiores nesses JSONs nem alteração de presets nesta análise. Recomendação de manter as fichas iniciais e comparar os demais estágios em teste posterior.

## Escalas de arcos e trajes leves — D92

Executada em **28/10/2026**, Godot 4.7.2/macOS. **Quatorze suítes headless aprovadas**, zero falhas nas execuções finais:

| Suíte | Verificações |
| --- | ---: |
| `damage_equipment_scales_tests` | 512 |
| `damage_equipment_scales_ui_smoke` | 48 |
| `damage_equipment_exclusivity_tests` | 73 |
| `damage_equipment_exclusivity_ui_smoke` | 15 |
| `damage_lab_tests` | 3.185 |
| `damage_equipment_tests` | 66 |
| `damage_export_tests` | 2.280 |
| `damage_evasion_tests` | 4.093 |
| `damage_presets_tests` | 82 |
| `damage_enemy_ranges_tests` | 1.162 |
| `damage_lab_ui_smoke` | 112 |
| `damage_presets_ui_smoke` | 53 |
| `damage_ally_02_tests` | 44 |
| `damage_ally_02_ui_smoke` | 26 |

Cobertura específica: seis arcos e seis trajes com as curvas aprovadas; crítico+12p.p./1,6× e EVA+5 constantes; todos os estágios recusados para primeiro aliado, mesmo ao remover metadados; **36 combinações** válidas com composição e atributos próprios separados, RNG sem avanço por troca, lote, JSON/dono, gravação e reabertura de cada par. Inversão mantém equipamento no aliado alvo e histórico anterior imutável. IDs originais continuam válidos; nomes antigos são atualizados em cópia sem perder bônus personalizados ou revisão. Arquivo e catálogo não são modificados pela leitura.

UI: seis opções em ordem por slot, índices filtrados por ID, seleção de cada estágio, teclado, próprios/totais, crítico/EVA, salvar/carga de equipamento superior, alternância para primeiro aliado sem expor itens do segundo, inversão, exportação e reabertura. Execução gráfica específica com **51 verificações e três capturas**, zero falhas. Capturas finais `stage-1-equipment.png`, `stage-6-equipment.png`, `stage-6-reopened.png` em `artifacts/damage-lab-equipment-scales/`, inspecionadas visualmente.

Biblioteca pessoal real reaberta: **três presets válidos**, primeiro com ATQ próprio23/revisão2 e segundo com20/revisão1, seus equipamentos iniciais e Monstro #1 preservados. Comparação integral confirmou que somente nomes de exibição são resolvidos em memória pelo catálogo; atributos, bônus, IDs e revisões preservados. Arquivo comparado antes/depois e mantido integralmente. Nenhuma migração com escrita no arquivo pessoal foi necessária.

Logs na pasta das capturas. Avisos ambientais conhecidos de certificados/consulta ao destino temporário no headless; nenhum erro de script nas execuções finais. Outras plataformas e controle físico não testados.

Para repetir, na raiz do projeto:

```sh
godot --headless --path . --script res://tests/damage_equipment_scales_tests.gd --log-file /private/tmp/rpg-scales-model.log
godot --headless --path . --script res://tests/damage_equipment_scales_ui_smoke.gd --log-file /private/tmp/rpg-scales-ui.log
godot --path . --script res://tests/damage_equipment_scales_ui_smoke.gd --log-file /private/tmp/rpg-scales-graphics.log -- --visual-captures=res://artifacts/damage-lab-equipment-scales
```

## Conferência dos relatórios após D88 — 27/10/2026

Analisados os dois JSONs mais recentes: execuções10 e11, semente421,1000 ações cada. Preset #1 revisão2 corretamente carregado com ATQ próprio23/total33; #2 revisão1 com20/30; ambos sem edição local. Mesmo alvo/ação/configuração, usando trechos consecutivos dos três RNGs.

Médias observadas **15,674 contra13,841**, vantagem de **13,24%** para #1; teóricas **15,919 contra13,920 (+14,36%)**. Normal13–16 contra12–14, crítico27–33 contra19–23. Comparação por cálculo independente das **2000 amostras** concluída sem divergências, inclusive HP/MP, resumos e estados RNG. Resultado consistente com a direção aproximada15%; recomendação de manter os valores, sem modificar presets nesta análise. Estudo e script reproduzível em `artifacts/balanceamento-aliados-pos-ajuste-2026-10-27/`.

## Atualização dos presets — D88

Executada em **27/10/2026**, Godot4.7.2/macOS. Primeiro ensaio em cópia temporária, depois atualização real por `damage_presets.gd.update`, ambos concluídos com **zero falhas** na execução final. Biblioteca reaberta e comparada integralmente com o estado anterior: somente ATQ próprio20→23 e revisão1→2 do Aliado #1; Aliado #2 e Monstro #1 e todos os demais campos preservados. Backup anterior em `/private/tmp/rpg-presets-before-attack23-54345.json`.

A calculadora validou os presets recarregados, ATQ efetivo33/30 e extremos normais13–16/12–14 e críticos27–33/19–23 contra Monstro #1 (DEF40). Executados **1000 ataques com cada aliado** após recarga, sem erro. Logs `preset-preview.log` e `preset-aplicado.log` em `artifacts/balanceamento-aliados-2026-10-27/`. Média esperada14,36% maior para #1 vem do cálculo teórico previamente conferido, e não da promessa de porcentagem exata em todo lote. Nenhum código de jogo ou fórmula foi alterado nesta atualização.

## Equipamentos obrigatórios e exclusividade nos dois sentidos — D86

Executada em **27/10/2026**, Godot 4.7.2/macOS. **Doze suítes headless aprovadas**, sem falhas: `damage_equipment_exclusivity_tests` (**73 verificações**), `damage_equipment_exclusivity_ui_smoke` (**15**), `damage_lab_tests` (3.185), `damage_equipment_tests` (66), `damage_export_tests` (2.280), `damage_evasion_tests` (4.093), `damage_presets_tests` (82), `damage_enemy_ranges_tests` (1.162), `damage_lab_ui_smoke` (112), `damage_presets_ui_smoke` (53), `damage_ally_02_tests` (44) e `damage_ally_02_ui_smoke` (26).

Cobertura: primeiro aliado somente espadas/metal; segundo somente arco/couro; nenhum seletor oferece `none`. Modelo recusa slots vazios, itens desligados e categorias trocadas, preservando o conjunto anterior. Salvamento/carga recusam equipamento ausente/desligado; calculadora exige os dois itens com aliado atacante ou alvo. Presets legados com `none` recebem defaults compatíveis para cada personagem em cópia, incluindo leitura da biblioteca sem regravar o arquivo original. Defaults por personagem e restauração mantêm os dois slots completos. Cobertura anterior de identidade, cópias, RNG, histórico, bônus, EVA e exportação permanece aprovada.

Execução gráfica específica com **18 verificações e três capturas**, zero falhas. Capturas inspecionadas em `artifacts/damage-lab-mandatory-equipment/`. Biblioteca pessoal real reaberta pelo modelo: **Aliado #1, Monstro #1 e Aliado #2** válidos; conferidos os seis pares de espadas/metal para #1 e somente arco/couro para #2. Arquivo original comparado antes/depois e preservado integralmente. Logs na mesma pasta. Avisos ambientais conhecidos de certificados/consulta ao destino temporário no headless; nenhum erro de script. Outras plataformas e controle físico não testados.

Para repetir:

```sh
godot --headless --path . --script res://tests/damage_equipment_exclusivity_tests.gd --log-file /private/tmp/rpg-mandatory-exclusivity.log
godot --headless --path . --script res://tests/damage_equipment_exclusivity_ui_smoke.gd --log-file /private/tmp/rpg-mandatory-ui.log
godot --path . --script res://tests/damage_equipment_exclusivity_ui_smoke.gd --log-file /private/tmp/rpg-mandatory-graphics.log -- --visual-captures=res://artifacts/damage-lab-mandatory-equipment
```

## Exclusividade do arco composto/couro — D85

Executada em **27/10/2026**, Godot 4.7.2/macOS. **Doze suítes headless aprovadas**, sem falhas: `damage_equipment_exclusivity_tests` (**30 verificações**), `damage_equipment_exclusivity_ui_smoke` (**13**), `damage_lab_tests` (3.185), `damage_equipment_tests` (66), `damage_export_tests` (2.280), `damage_evasion_tests` (4.093), `damage_presets_tests` (80), `damage_enemy_ranges_tests` (1.162), `damage_lab_ui_smoke` (111), `damage_presets_ui_smoke` (53), `damage_ally_02_tests` (44) e `damage_ally_02_ui_smoke` (25).

Cobertura nova: arco/couro recusados para primeiro aliado e permitidos para segundo; nome não concede acesso; remover restrição da cópia de item não contorna catálogo; bloqueio em seleção por ID, setter do modelo, salvamento/carga e calculadora, inclusive como alvo e arma ofensiva isolada. Falha não altera ficha, arquivo, histórico ou RNG. Identidade/dono corretos no JSON, equipamentos não vazam entre personagens, cópia com nome novo mantém personagem, Atualizar não troca identidade, identidade desconhecida é recusada, presets anteriores compatíveis e equipamentos comuns preservados.

UI específica: menus filtrados por identidade, restauração por ID depois de filtrar, alternância entre primeiro/segundo aliado, cópia e reabertura, inversão dos papéis e lote válido. Execução gráfica com **16 verificações e três capturas**, sem falhas ou erros de script na execução final. `ally1-restricted.png`, `ally2-exclusive.png` e `ally2-copy.png` inspecionadas em `artifacts/damage-lab-exclusivity/`. Logs guardados na mesma pasta. Avisos ambientais conhecidos de certificados/consulta ao destino inexistente no headless; controle físico e outras plataformas não testados.

Migração real executada e verificada: Aliado #1 identificado como `ally_1` com Bronze; Aliado #2 como `ally_2` com arco/couro; Monstro #1 preservado. Três presets mantidos sem alteração de atributos, bônus, IDs ou revisões. Somente metadados de identidade e restrição foram acrescentados; reabertura validou os itens de ambos. Registro em `migration.log`.

Para repetir:

```sh
godot --headless --path . --script res://tests/damage_equipment_exclusivity_tests.gd --log-file /private/tmp/rpg-exclusive-model.log
godot --headless --path . --script res://tests/damage_equipment_exclusivity_ui_smoke.gd --log-file /private/tmp/rpg-exclusive-ui.log
godot --path . --script res://tests/damage_equipment_exclusivity_ui_smoke.gd --log-file /private/tmp/rpg-exclusive-graphics.log -- --visual-captures=res://artifacts/damage-lab-exclusivity
```

## Aliado #2, arco composto e EVA do couro — D84

Executada em **27/10/2026**, Godot 4.7.2/macOS. **Dez suítes headless aprovadas**, sem falhas: `damage_ally_02_tests` (**44 verificações**), `damage_ally_02_ui_smoke` (**25**), `damage_lab_tests` (3.185), `damage_equipment_tests` (66), `damage_export_tests` (2.280), `damage_evasion_tests` (4.093), `damage_presets_tests` (80), `damage_enemy_ranges_tests` (1.162), `damage_lab_ui_smoke` (111) e `damage_presets_ui_smoke` (53).

Cobertura nova: salvar/reabrir todos os atributos e arco/couro do catálogo; ATQ30/DEF35, CRI7+12=19% e 1,6×, EVA própria7 + armadura5 = efetiva12; extremos de dano normal12–14/crítico19–23 e recebido9–11; RNG reproduzível; sorteio contra EVA total; troca/remoção de armadura e inversão sem alterar base; limite100 com soma bruta preservada; atualizar bônus e reabrir sem duplicação; histórico/JSON próprios/bônus/efetivos; rejeição de valores negativos/fracionários/não finitos/acima do limite ou bônus sem armadura; armaduras antigas sem o campo recebem zero em memória sem sobrescrita na leitura.

Interface: teclado edita bônus de EVA e Carregar recupera a ficha completa; seletores mostram arco/couro, chance/multiplicador e composição; inversão mantém couro no aliado alvo; Sem armadura bloqueia o bônus; atualização/reabertura preserva os campos; exportação descreve a EVA efetiva. Execução gráfica específica com **28 verificações e três capturas**, sem falhas. `ally02-loaded.png`, `ally02-equipment.png` e `ally02-target-conditions.png` inspecionadas em `artifacts/damage-lab-ally02/`, com campos e totais legíveis. Logs na mesma pasta. Avisos ambientais conhecidos de certificados macOS/consulta ao destino ainda inexistente no diálogo não impediram os testes; nenhum erro de script nas execuções finais. Controle físico e outras plataformas não validados.

Instalação real executada por `damage_presets.gd`: **Aliado #2** adicionado uma vez à biblioteca pessoal, depois reaberto e validado com os totais esperados. Os dois presets anteriores foram comparados após normalização e preservados, com nomes/IDs/revisões/valores mantidos; armaduras antigas recebem somente o novo bônus zero compatível. Biblioteca final contém **Aliado #1, Monstro #1 e Aliado #2**. Sem autoimportação da definição ao iniciar ou alteração de fichas da exploração. Instalação documentada em `install.log`; testes usam arquivos temporários exclusivos.

Para repetir os testes, na raiz do projeto:

```sh
godot --headless --path . --script res://tests/damage_ally_02_tests.gd --log-file /private/tmp/rpg-ally02-model.log
godot --headless --path . --script res://tests/damage_ally_02_ui_smoke.gd --log-file /private/tmp/rpg-ally02-ui.log
godot --path . --script res://tests/damage_ally_02_ui_smoke.gd --log-file /private/tmp/rpg-ally02-graphics.log -- --visual-captures=res://artifacts/damage-lab-ally02
```

## Biblioteca vazia e gerenciamento de presets — D77

Executada em **27/10/2026**, Godot 4.7.2/macOS. Oito suítes headless aprovadas: `damage_presets_tests` (**79 verificações**), `damage_presets_ui_smoke` (**53**), `damage_lab_ui_smoke` (**111**), `damage_lab_tests` (3.185), `damage_equipment_tests` (66), `damage_export_tests` (2.280), `damage_evasion_tests` (4.093) e `damage_enemy_ranges_tests` (1.162). Sem falhas nas execuções finais.

Cobertura nova: biblioteca inicialmente vazia sem referências; apenas duas fichas manuais; Salvar e Carregar/Atualizar/Excluir em categorias independentes; carga de todos os nove atributos com valores distintos, zeros e limites; HP 99999; restauração dos IDs, bônus e críticos dos equipamentos; multiplicador próprio do monstro; recarregar o mesmo preset após edição/digitação pendente e perda de foco; troca de lados sem truncamento ou duplicação de bônus; persistência e reabertura. Nome salvo identifica participante e preset. Exclusão relê disco, conserva registros novos de outra instância e a categoria oposta; é persistente, preserva ficha atual/histórico/RNG, permite excluir todos e depois salvar novamente. Arquivo inválido é preservado e bloqueia escrita/exclusão. Erros de nome, carga inválida e gravação não confirmam sucesso.

Execução gráfica específica de presets: **58 verificações**, incluindo **cinco capturas**, zero falhas. Capturas `presets-empty.png`, `presets-save-dialog.png`, `presets-saved.png`, `presets-deleted.png` e `presets-restarted.png` inspecionadas em `artifacts/damage-lab-presets-reset/`: controles legíveis, listas inicialmente vazias, dados/equipamentos completos após carregar e exclusão voltando à ficha manual. A suíte gráfica geral também passou com 125 verificações na reorganização do layout. Rolagem por foco é reaplicada após o layout estabilizar, validada na suíte headless geral. Logs na mesma pasta; avisos ambientais conhecidos de certificados/consulta ao destino inexistente no macOS, sem erros de script nas execuções finais. Controle físico e outras plataformas não validados.

Limpeza pontual autorizada: catálogo de referências removido do projeto e três presets do arquivo pessoal efetivamente excluídos. Novos presets não são apagados ao iniciar. Testes usam arquivos temporários próprios e não escrevem na biblioteca real.

Para repetir na raiz do projeto:

```sh
godot --headless --path . --script res://tests/damage_presets_tests.gd --log-file /private/tmp/rpg-presets-reset-model.log
godot --headless --path . --script res://tests/damage_presets_ui_smoke.gd --log-file /private/tmp/rpg-presets-reset-ui.log
godot --path . --script res://tests/damage_presets_ui_smoke.gd --log-file /private/tmp/rpg-presets-reset-graphics.log -- --visual-captures=res://artifacts/damage-lab-presets-reset
```

## HP dos inimigos até 99.999 — D76

Executada em **27/10/2026**, Godot 4.7.2/macOS. Seis suítes headless aprovadas: `damage_enemy_ranges_tests` (**1.162 verificações**), `damage_presets_tests` (**38**), `damage_lab_tests` (3.185), `damage_export_tests` (2.280), `damage_evasion_tests` (4.093) e `damage_lab_ui_smoke` (**111**). Execução gráfica com **125 verificações/14 capturas**, zero falhas nas execuções finais.

Cobertura: HP inicial de monstro em 1/9999/10000/99999, como atacante e alvo; recusa de zero, negativos, 100000, frações e NaN/INF sem consumir histórico/RNG; dano mínimo e HP restante 99998; edição com cinco dígitos e limite na digitação; inversão sem truncamento; salvar/reabrir preset com 99999; histórico/JSON e metadados da faixa íntegros. Demais atributos continuam nas faixas anteriores, inclusive HP do aliado até 999.

Captura `artifacts/damage-lab-hp99999/enemy-large-values.png` inspecionada: HP 99999 no editor, HUD e condições, sem corte do texto. Logs e capturas guardados nessa pasta. Avisos ambientais conhecidos de certificados e consulta ao destino inexistente no diálogo macOS; nenhum erro de script nas execuções finais. Para repetir: `godot --headless --path . --script res://tests/damage_enemy_ranges_tests.gd --log-file /private/tmp/rpg-hp99999.log`; trocar o arquivo para as demais suítes. Capturas: `godot --path . --script res://tests/damage_lab_ui_smoke.gd --log-file /private/tmp/rpg-hp99999-graphics.log -- --visual-captures=res://artifacts/damage-lab-hp99999`.

## EVA no laboratório de danos — D75

Executada em **27/10/2026**, Godot 4.7.2/macOS. Oito suítes headless passaram, sem falhas:

| Suíte | Verificações |
| --- | ---: |
| `damage_evasion_tests` | 4.093 |
| `damage_lab_tests` | 3.185 |
| `damage_export_tests` | 2.280 |
| `damage_equipment_tests` | 66 |
| `damage_enemy_ranges_tests` | 1.160 |
| `damage_presets_tests` | 37 |
| `damage_lab_ui_smoke` | 111 |
| `damage_presets_ui_smoke` | 28 |

Cobertura nova: EVA 0/100 e fronteira percentual; elegibilidade de física/magia; esquiva anterior ao crítico inclusive forçado; dano/HP removido zero com MP consumido; mínimo 1 nos acertos; alvo aliado/monstro e inversão; médias sem esquivas, lote sem acertos e histograma com três categorias; sorteios independentes reproduzíveis/contínuos, JSON v3 e estados RNG sem perda; recusa de valores inválidos sem alterar histórico/RNG; salvar/atualizar/reabrir EVA em presets e migração de presets antigos para zero sem sobrescrita na leitura. Os campos de item/buff de CRI não modificam EVA. Testes usam arquivos temporários exclusivos.

Execução gráfica com **125 verificações**, incluindo **14 capturas**, sem falhas. Capturas `evasion-all.png`, `evasion-single.png` e `evasion-mixed.png` inspecionadas em `artifacts/damage-lab-evasion/`: EVA nas duas fichas, aviso Esquivou!, HP preservado/MP consumido, resumo legível e cores distintas no histograma. Logs headless e gráfico guardados na mesma pasta. Avisos ambientais conhecidos de certificados do macOS e consulta a destino ainda inexistente no diálogo não impediram os testes; nenhum erro de script nas execuções finais. Controle físico e outras plataformas não validados.

Para repetir na raiz do projeto (use o caminho do executável se `godot` não estiver no PATH):

```sh
godot --headless --path . --script res://tests/damage_evasion_tests.gd --log-file /private/tmp/rpg-evasion-tests.log
godot --headless --path . --script res://tests/damage_lab_ui_smoke.gd --log-file /private/tmp/rpg-evasion-ui.log
godot --path . --script res://tests/damage_lab_ui_smoke.gd --log-file /private/tmp/rpg-evasion-graphics.log -- --visual-captures=res://artifacts/damage-lab-evasion
```

EVA permanece exclusiva do laboratório; dados e implementação do combate integrado não foram alterados. Conversão/limites, números das fichas e permissões são experimentais; equipamentos, itens e buffs de EVA continuam adiados.

## Presets persistentes de fichas — D72

Executada em **27/10/2026**, Godot 4.7.2/macOS. **44 suítes headless aprovadas**, incluindo combate, exploração e as sete suítes de danos. Testes novos: `damage_presets_tests` (**37 verificações**) e `damage_presets_ui_smoke` (**28 headless**, **32 gráficas** incluindo quatro capturas), zero falhas. A suíte anterior da interface de danos mantém suas 97 verificações headless aprovadas.

Cobertura: referências protegidas; carga independente por categoria; atributos próprios + equipamentos sem duplicar bônus; faixas do aliado/monstro; salvar cópia com nome, atualizar revisão e reler em outra instância; duplicação de nome, Unicode, cancelamento e erro de gravação. Arquivos pessoais inválidos são preservados, referências continuam disponíveis e novas gravações são bloqueadas. Releitura antes de escrever preserva alterações sequenciais de outra instância. Histórico/JSON preservam a revisão e os valores anteriores; aplicar presets não avança RNG nem altera ação/parâmetros globais. Inversão de papéis, restauração do caso e fechamento/reabertura mantêm a biblioteca pessoal.

Interface exercitada por teclado e controle simulado: seletores, diálogo modal, Enter para salvar, atualização de personalizado e marca de alteração. Atalhos de lote não atravessam o diálogo. Capturas `presets-reference.png`, `presets-save-dialog.png`, `presets-custom.png` e `presets-reopened.png` inspecionadas em `artifacts/damage-lab-presets/`; campos, nomes e botões legíveis. Testes usam arquivos temporários exclusivos, sem tocar os presets pessoais ou as exportações do usuário.

Logs `regression.log`, `presets.log`, `presets-ui.log` e `graphics.log` na mesma pasta. Execuções finais sem erros de script e com código 0; aviso ambiental conhecido de certificados do macOS no headless. Controle físico e outras plataformas não testados. Persistência é exclusiva dos presets do laboratório, não um salvamento da aventura. As fichas fornecidas continuam experimentais.

Para repetir, na raiz do projeto:

```sh
godot --headless --log-file /private/tmp/rpg-presets.log --path . --script res://tests/damage_presets_tests.gd
godot --headless --log-file /private/tmp/rpg-presets-ui.log --path . --script res://tests/damage_presets_ui_smoke.gd
godot --log-file /private/tmp/rpg-presets-graphics.log --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/damage_presets_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab-presets
```

## Escala 1..9999 dos monstros — D69

Executada em **27/10/2026**, Godot 4.7.2/macOS. Cinco suítes headless aprovadas: `damage_enemy_ranges_tests` (**1.160 verificações**), `damage_lab_tests` (3.177), `damage_equipment_tests` (66), `damage_export_tests` (2.280) e `damage_lab_ui_smoke` (**97**). UI gráfica: **108 verificações**, incluindo onze capturas, zero falhas nas execuções finais.

Cobertura nova: seis atributos do monstro em 1/1000/9999 como atacante e alvo; recusa de zero, negativos, 10000, frações, NaN/INF sem avançar RNG/histórico; INI/CRI mantidos em 1..99; aliado mantido em 0..999. Testes exercitam defesa 9999 com dano mínimo, ataque/magia 9999 com potência/variação/crítico extremos, dano acima do teto de atributos, HP/MP e restauração das condições em lote, JSON com valores íntegros e metadados de faixas por categoria.

Na interface: digitação de quatro dígitos, teto 9999, mudança das faixas ao inverter lados sem truncar o monstro ou contaminar atributos do aliado, preservação do limite 999 do aliado, execução e exportação com números grandes. Captura `enemy-large-values.png` inspecionada: fichas, recursos, dano e condições legíveis. Logs/capturas em `artifacts/damage-lab-enemy-ranges/`. Sem erros de script nas execuções finais; avisos ambientais já conhecidos do macOS. Controle físico e outras plataformas não testados. Nenhum perfil de chefe, ficha da exploração ou mudança da fórmula foi criado.

Para repetir: `godot --headless --log-file /private/tmp/rpg-enemy-ranges.log --path . --script res://tests/damage_enemy_ranges_tests.gd`; demais suítes com o mesmo comando e seu arquivo. Capturas: `godot --log-file /private/tmp/rpg-enemy-ranges-graphics.log --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/damage_lab_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab-enemy-ranges`.

## Remoção de Madeira e deslocamento dos bônus — D67

Armas/armaduras de Madeira removidas; seis materiais restantes recebem bônus 10/16/24/34/48/65, de Bronze a Rúnica. Padrão em Espada de Bronze (+10), sem alterar atributos próprios, chance/multiplicador crítico ou fórmulas. Fixtures de comparação usam agora Bronze (+10) e Ferro (+16); soma máxima do preset Rúnico é 999 + 65 = 1064, limitada a 999 como antes.

Quatro suítes headless executadas e aprovadas em Godot 4.7.2/macOS: `damage_lab_tests` (3.177 verificações), `damage_equipment_tests` (66), `damage_export_tests` (2.280) e `damage_lab_ui_smoke` (75), zero falhas. Os testes de equipamentos percorrem os seis materiais nos dois lados e validam histórico/JSON com os novos IDs e bônus. Logs em `artifacts/damage-lab-bronze/`. Sem nova alteração de layout ou teste gráfico nesta mudança de catálogo; aviso ambiental de certificados/consulta de novo arquivo no diálogo macOS permanece sem impedir os testes.

## Simplificação do seletor de armas e rótulos

Removidas do catálogo as duas armas de controle 2×/3× a pedido do usuário. O seletor agora tem Sem arma e as sete espadas; padrão em Madeira (+10 ATQ F), com atributos próprios preservados. Multiplicador permanece editável no controle existente. Rótulos ATQ F/DEF F sem sufixo pr.; composição próprio+bônus=total preservada.

Executadas e aprovadas as quatro suítes de danos: cálculo (3.177 verificações), equipamentos (74), exportação (2.280) e UI headless (75). UI gráfica: 85 verificações, zero falhas. As referências de teste passaram a considerar o bônus da Madeira no caso padrão; a referência de fórmula continua explicitamente em ofensiva efetiva 100. Conferência do catálogo: oito opções, sem IDs das duas armas removidas. Captura `equipment-totals.png` inspecionada, com rótulos e controle de multiplicador. Logs/capturas em `artifacts/damage-lab-equipment-cleanup/`. Sem alteração de fórmula ou da exploração.

## Equipamentos somente nos aliados do laboratório — D66

Godot 4.7.2 Standard/macOS, execução local. **41 suítes headless aprovadas**, mais UI com renderização real em Compatibility na janela 1440×960.

| Suíte | Resultado |
| --- | --- |
| `tests/damage_equipment_tests.gd` | 74 verificações, zero falhas. |
| `tests/damage_lab_tests.gd` | 3.177 verificações, zero falhas. |
| `tests/damage_export_tests.gd` | 2.280 verificações, zero falhas. |
| `tests/damage_lab_ui_smoke.gd` | 75 verificações headless, zero falhas. |
| Mesma suíte gráfica | 85 verificações, incluindo dez capturas, zero falhas. |
| Demais 37 suítes | Todas aprovadas, incluindo combate e exploração. |

Cobertura nova: sete materiais em ataque/defesa, próprio+bônus=efetivo, edição dos bônus e imutabilidade do catálogo, aumento de dano e redução de dano recebido conforme a fórmula, equipamento acompanhando o aliado ao inverter lados, equipamento local por aliado, opções sem item, ausência de bônus/arma no monstro, origem de chance/multiplicador crítico, parâmetros sem arma, independência de MAG/DEF M e potência, RNG sem avanço durante configuração, soma bruta/limite 999, validação de próprios/bônus inválidos e restauração. Histórico/JSON v2 preservam condições antigas, dono, itens, atributos próprios e totais, inclusive com o aliado como alvo. Testes anteriores do cálculo/exportação continuam aprovados.

A UI foi exercitada por eventos de teclado, clique e controle simulado: seletores, digitação de bônus, campos bloqueados sem equipamento, troca de lados por controle, prévia, lotes e exportação. Capturas `equipment-totals.png`, `equipment-selectors.png` e `equipment-monster-attack.png` inspecionadas em `artifacts/damage-lab-equipment/`, além das sete capturas anteriores atualizadas. Painel de edição rola por foco; condições mostram composição e origem real do crítico. Valores dos presets, limite efetivo e multiplicador próprio 2× são experimentais; nenhuma implementação de inventário ou mudança na exploração.

Logs na mesma pasta: `regression.log`, `equipment.log`, `core.log`, `export.log`, `ui.log` e `graphics.log`. As execuções finais terminaram com código 0, sem erros de script. Avisos ambientais de certificados no headless e consulta de arquivo novo do diálogo macOS não impediram gravação/leitura dos JSONs. Controle físico, exportação do executável e outras plataformas não foram testados.

Para repetir: `godot --headless --log-file /private/tmp/rpg-equipment.log --path . --script res://tests/damage_equipment_tests.gd`, com os mesmos argumentos para as outras suítes. Para as capturas: `godot --log-file /private/tmp/rpg-equipment-graphics.log --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/damage_lab_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab-equipment`. Dados, limites e roteiro em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

## Exportação JSON das amostras — D61

Executada em **26/10/2026**, Godot 4.7.2/macOS: **três suítes headless aprovadas**, mais renderização real da UI.

| Suíte | Resultado |
| --- | --- |
| `tests/damage_export_tests.gd` | 2.280 verificações, zero falhas. |
| `tests/damage_lab_tests.gd` | 3.177 verificações, zero falhas. |
| `tests/damage_lab_ui_smoke.gd` | 61 verificações headless, zero falhas. |
| Mesma suíte gráfica | 68 verificações, incluindo sete capturas, zero falhas. |

Testes gravam e leem JSON de lotes 1/10/100/1000, conferem esquema/fórmula, todas as linhas, totais, índices da sequência, Seed real, Unicode, precisão dos sorteios/dano bruto e estados de 64 bits em texto. Verificam cópias sem mutação do histórico/RNG, condições históricas após edição, resultado vazio, destino vazio e erro de abertura. Integração cobre botão indisponível antes de resultado/durante animação, F10 e controle, atalhos bloqueados ao fundo, cancelamento pelo botão, escolha de pasta/nome e gravação pelo próprio botão de salvar do diálogo, sucesso/caminho e erro de gravação.

Capturas inspecionadas em `artifacts/damage-lab-export/`, incluindo `damage-batch-1000.png` com o botão e `damage-export-dialog.png`. Logs `export.log`, `core.log`, `ui.log` e `graphics.log` na mesma pasta. Sem erros de script; aviso ambiental conhecido de certificados no headless. Controle físico/exportação do executável para outras plataformas não testados. Fórmulas, dados e combate da exploração preservados.

Para repetir: `godot --headless --log-file /private/tmp/rpg-export.log --path . --script res://tests/damage_export_tests.gd`, com os mesmos argumentos para as outras duas suítes. Capturas: `godot --log-file /private/tmp/rpg-export-graphics.log --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/damage_lab_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab-export`. Uso e esquema em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

## Digitação direta no laboratório de danos

Refinamento solicitado e validado em **26/10/2026**, Godot 4.7.2/macOS. `tests/damage_lab_ui_smoke.gd`: **50 verificações headless** e **56 com renderização real**, zero falhas. Testes novos enviam cliques e caracteres por eventos da engine: clicar no número e substituir o texto; começar a digitar com o SpinBox selecionado sem Enter prévio; confirmar por Enter/Tab ou clique em outro campo; decimal com vírgula; limitar 10000 digitado a 999; executar lote com edição aberta e conferir o valor usado. As verificações anteriores de teclado/controle, fichas, animação, histórico e lotes continuam aprovadas.

O LineEdit interno agora aceita foco por clique, com seleção do texto e confirmação ao perder foco; o SpinBox mantém a navegação por teclado/controle. Capturas em `artifacts/damage-lab-manual/`, logs `ui.log` e `graphics.log`. A simulação interativa de redução por defesa também recebeu entrada numérica manual para ATQ F, DEF F e potência; execução do JavaScript validou atualização do cálculo, valores vazios, limites e restauração do estado. Fórmulas e dados de combate preservados. Controle físico não foi testado.

## Laboratório isolado de danos — D60

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro. **39 suítes headless aprovadas**, incluindo as 37 regressões anteriores, mais verificação gráfica em Compatibility na janela 1440×960.

| Suíte / conjunto | Resultado |
| --- | --- |
| `tests/damage_lab_tests.gd` | 5 grupos, 3.177 verificações, zero falhas. |
| `tests/damage_lab_ui_smoke.gd` | 44 verificações headless, zero falhas. |
| Mesma suíte com renderização real | 50 verificações, incluindo seis capturas, zero falhas. |
| Demais 37 suítes headless | Todas aprovadas; contagens em `artifacts/damage-lab/regression.log`. |
| Lançador `Executar laboratorio de danos.command` | Sintaxe zsh e abertura headless da cena aprovadas, código 0. |

Cobertura do cálculo: proporcional física/mágica e independência entre seus atributos; defesa zero, ofensiva zero e 0/0; extremos, monotonicidade, arredondamento e mínimo 1; dano calculado versus HP removido; chance-base, arma, conversão e modificadores; fronteiras 0%/100%, multiplicador somente da arma, permissão da ação, modos de crítico e variação. Lotes 1/10/100/1000, médias/totais/histograma, recursos restaurados por amostra, reprodução pela semente, continuação exata e fluxos de RNG independentes. Validações de faixas/NaN/INF, MP insuficiente, alvo incapacitado, lados opostos, imutabilidade de entradas/histórico, retenção e isolamento da instância/dados do combate.

Cobertura da UI: teclado, eventos simulados de direcional/analógico/botões, edição exata, seleção de fichas/arma/ação, troca de lado válida, animação e bloqueio durante o golpe, lotes, tabela de 1000 amostras e navegação das linhas, reprodução, histórico com condições anteriores, erro sem consumo de RNG, restauração do caso e rolagem por foco até os parâmetros inferiores. O viewport do teste headless é explicitamente 1440×960 para conferir a mesma janela da execução gráfica; a primeira checagem de limites levou a ajustar a inicialização do teste. Não restaram erros de script.

Capturas em `artifacts/damage-lab/`: `damage-single-impact.png`, `damage-batch-1000.png`, `damage-samples.png`, `damage-conditions.png`, `damage-magic-critical.png` e `damage-editor-lower.png`. Inspeção confirmou leitura do impacto, barras, resumo, amostras/condições e campos inferiores; os rótulos de recursos ficam na origem durante a aproximação para evitar sobreposição. Logs finais `regression.log`, `ui-final.log`, `graphics.log` e `launcher.log`. Após o ajuste final da posição da chance de crítico e aviso de prévia, a suíte de UI foi repetida headless/gráfica e passou com as mesmas contagens.

Para repetir, na raiz do projeto (substitua `godot` pelo executável instalado se necessário):

```sh
godot --headless --log-file /private/tmp/rpg-damage-unit.log --path . --script res://tests/damage_lab_tests.gd
godot --headless --log-file /private/tmp/rpg-damage-ui.log --path . --script res://tests/damage_lab_ui_smoke.gd
godot --log-file /private/tmp/rpg-damage-graphics.log --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/damage_lab_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab
```

Os avisos headless de certificados do macOS são ambientais; execuções finais terminaram com código 0. Controle físico, exportação e outras plataformas não foram testados. Fórmula, valores e limites são experimentais; não houve migração do dano da exploração, sistema de equipamento/buff real ou save. Roteiro e escolhas em [LABORATORIO_DANOS.md](LABORATORIO_DANOS.md).

## Interface por teclado/controle e área centrada — D52/D53

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro. **37 suítes headless aprovadas**, mais inspeção gráfica em Compatibility.

| Suíte / conjunto | Resultado |
| --- | --- |
| `tests/centered_area_tests.gd` | 74 verificações, zero falhas. |
| `tests/battle_navigation_ui_smoke.gd` | 48 verificações, zero falhas. |
| Mesma suíte com renderização real | 53 verificações, incluindo cinco capturas, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 162.488 verificações, zero falhas. |
| `tests/fullscreen_tests.gd` | 10 grupos, 620 verificações, zero falhas. |
| `tests/ui_smoke.gd` | 32 verificações, zero falhas. |
| Demais 32 suítes headless | Todas aprovadas. |

Cobertura nova: eventos de teclado/joypad por `Input.parse_input_event`, mão em cards prontos e comandos, card escolhido persistente, mão no alvo em campo, confirmações/cancelamento por etapa, clique sem efeito, repetição de confirmação bloqueada, direcional/analógico com dead zone e repetição, opções de modo/Battle Speed sem mouse, cura e reanimação, falta de MP, alvo/executor invalidado, foco de campos de texto e Game Over integrado reiniciado por controle. Área exige centro válido, acompanha alvo móvel e avalia entrada/saída do raio no impacto; ausência de fogo amigo verificada dos dois lados, sem alterar âncoras aliadas, custos ou retorno.

Regressões cobrem ritmos/snapshots, melee/tela inteira, seis encontros, HP/MP, fuga, exploração, relógio e eventos. Uma expectativa histórica de tela inteira ainda passava coordenada livre a uma habilidade circular; foi atualizada para fornecer o ID central e conservar a verificação de independência entre apresentação e efeito. A primeira execução dessa suíte registrou a expectativa antiga como falha; a reexecução com o caso atualizado passou integralmente. Os demais testes geométricos agora usam consulta de raio explícita, sem reabrir mira livre como comando.

Logs em `artifacts/battle-navigation/regression.log`, com reexecuções anexadas, e `graphics.log`. Capturas inspecionadas: `navigation-cards.png`, `navigation-commands.png`, `navigation-area-target.png` e `navigation-item-target.png`; a captura de opções também foi gerada. O círculo foi recortado ao campo para não cobrir comandos. Mão vetorial original, sem assets de jogos de referência. Arquitetura e roteiro em [INTERFACE_BATALHA.md](INTERFACE_BATALHA.md).

Os avisos headless de certificados do macOS são ambientais; execuções finais terminaram com código 0. **Controle físico não foi testado:** a suíte de UI utiliza eventos simulados da engine. Não houve teste de exportação/outras plataformas nem mudança nos controles da exploração. Os registros anteriores abaixo são históricos, incluindo o fluxo antigo de clique/mira livre.

## Correção do padrão para 4, mantendo a reescala D51

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS, headless. `tests/battle_speed_tests.gd`: **111 verificações, zero falhas**. `tests/battle_speed_ui_smoke.gd`: **16 verificações, zero falhas**. Ambas terminaram com código 0 e apenas o aviso ambiental conhecido de certificados.

Verificados padrão 4 no modelo, menu/laboratório e reinício da exploração; escolha mantida entre batalhas, escala deslocada intacta e referência original ainda no nível 6. Os multiplicadores não mudaram: nível 4 usa 0,6× de carga. Tempos atualizados em [BATTLE_SPEED.md](BATTLE_SPEED.md). As escolhas iniciais de padrão 3 registradas abaixo são históricas e foram substituídas por esta correção.

## Reescala de Battle Speed e padrão 3 — D51

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS, modo headless. Cinco suítes aprovadas:

| Suíte | Resultado |
| --- | --- |
| `tests/battle_speed_tests.gd` | 111 verificações, zero falhas. |
| `tests/battle_speed_ui_smoke.gd` | 16 verificações, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 239.479 verificações, zero falhas. |
| `tests/seeded_behavior_tests.gd` | 14.860 verificações, zero falhas. |
| `tests/exploration_rhythm_tests.gd` | 2.124 verificações, zero falhas. |

Cobertura adicional explícita: cada antigo nível 1..7 conserva seu multiplicador no novo nível 2..8; padrão 3 no modelo, menu, laboratório e reinício da exploração; referência original no nível 6. Mantidas as verificações de ATB, Wait, carga parcial, rotas, ações e integração. O novo nível 1 usa 0,125× experimental, e o antigo 8 sai da faixa. Tempos atuais em [BATTLE_SPEED.md](BATTLE_SPEED.md).

Logs em `artifacts/battle-speed-rescale/`. As cinco execuções terminaram com código 0; aviso ambiental conhecido de certificados do macOS. Sem nova inspeção gráfica: a alteração é de dados/padrão e os controles existentes foram exercitados pela suíte de UI. A escala inicial D50 e os resultados abaixo são históricos; a referência original agora está em Battle Speed 6.

## Battle Speed 1..8 — D50

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro. **35 suítes headless aprovadas**, mais inspeção gráfica com Compatibility.

| Suíte / conjunto | Resultado |
| --- | --- |
| `tests/battle_speed_tests.gd` | 104 verificações, zero falhas. |
| `tests/battle_speed_ui_smoke.gd` | 16 verificações, zero falhas. |
| Mesma suíte com renderização real | 18 verificações, incluindo duas capturas, zero falhas. |
| `tests/seeded_behavior_tests.gd` | 14.860 verificações, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 126.039 verificações, zero falhas. |
| Demais 31 suítes headless | Todas aprovadas; contagens em `artifacts/battle-speed/regression.log`. |

Cobertura nova: 1 lento→8 rápido, padrão 4, nível 5 reproduzindo a fórmula anterior nos dois lados, carga parcial/prontidão preservadas ao mudar, Wait e limites, rotas/RNG independentes da escala, melee/tela inteira com duração/efeito/custo/retorno preservados, controles de menu/laboratório sincronizados com o modelo compartilhado, manutenção entre áreas/combates/retorno/reencontro, relógio do mundo independente e reinício global no padrão 4. Os multiplicadores intermediários são experimentais em dados; o padrão 4 usa carga 0,8×, portanto demora 25% mais que o nível 5. Não houve alteração da INI ou do atendimento de múltiplos prontos.

Capturas `battle-speed-lab.png` e `battle-speed-menu.png` inspecionadas: controles legíveis e menu dentro do mapa. A primeira tentativa gráfica no sandbox encerrou antes da inicialização; a execução com acesso à janela do macOS terminou com código 0. As execuções headless emitiram o aviso ambiental conhecido sobre consulta de certificados do macOS, sem falhas de testes. Sem testes de exportação ou persistência em disco.

Comandos e roteiro manual em [BATTLE_SPEED.md](BATTLE_SPEED.md). Os resultados D49 e anteriores abaixo permanecem históricos; seus tempos de referência correspondiam ao nível 5 na escala inicial e agora correspondem a Battle Speed 6 (D51).

## Variação de INI entre tipos atuais — D49

Executada em **26/10/2026**, Godot 4.7.2 Standard no macOS, modo headless.

| Suíte | Resultado |
| --- | --- |
| `tests/seeded_behavior_tests.gd` | 14.860 verificações, zero falhas. |
| `tests/exploration_rhythm_tests.gd` | 2.124 verificações, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.375 verificações, zero falhas. |
| `tests/seeded_behavior_ui_smoke.gd` | 34 verificações, zero falhas. |

Novos testes exercitam carga real e ordem da primeira ação de cada tipo no laboratório (Ágil, Voador, Pesado, Estático), carga igual quando INI efetiva é igual apesar de movimentos distintos e preservação integral das fichas legadas. Integração verifica que os seis encontros carregam a INI da ficha atual; comparações dos demais atributos e regras permanecem. INIs experimentais: 12/10/7/5 nessa ordem. Aliados mantêm 9/12/7/10; fórmula de ATB, atendimento de prontos, HP/MP, habilidades e movimentos não foram alterados.

Para repetir: `godot --headless --path . --script res://tests/seeded_behavior_tests.gd` e os mesmos argumentos para as outras três suítes. Roteiro manual em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md). Sem nova inspeção gráfica nesta alteração de dados. A engine emitiu aviso do ambiente na consulta de certificados do macOS; as quatro execuções terminaram com código 0. A primeira também avisou que não podia gravar o log padrão; as demais usaram logs em `/private/tmp`.

## Comportamento por semente, atenção visual e formações variadas

Executada em **25/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; Compatibility nas inspeções gráficas.

| Suíte | Resultado |
| --- | --- |
| `tests/seeded_behavior_tests.gd` | 9 grupos, 14.846 verificações, zero falhas. |
| `tests/seeded_behavior_ui_smoke.gd` | 34 verificações, zero falhas. |
| Mesma suíte com renderização real | 48 verificações, incluindo sete capturas do campo e sete da depuração, zero falhas. |
| `tests/exploration_rhythm_tests.gd` | 2.118 verificações, zero falhas. |
| Mesma suíte com renderização real | 2.122 verificações, incluindo quatro capturas, zero falhas. |
| `tests/internal_areas_ui_smoke.gd` com renderização real | 57 verificações, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.375 verificações, zero falhas. |
| Demais 29 suítes headless | Todas executadas e aprovadas. |

Total: **33 suítes headless aprovadas**, mais três execuções gráficas. Lista e saídas em `artifacts/seeded-behavior/regression.log` e `graphics.log`. Os resultados anteriores abaixo são históricos.

Cobertura nova: dez presets anteriores integralmente conservados e marcados como legados, cinco atuais distintos, início automático em `lab_seeded`, seis encontros usando a nova versão; mesma semente/entradas reproduzindo estados, mudança de semente variando decisões/quantidade/duração de pausas, RNG de movimento independente dos sorteios de ação/alvo e entre participantes, política sem override por preset, continuidade por divisão de tempo, geometria aberta/fechada, frenagem/pausa/aceleração na inversão, extremos, voador pairando com ATB ativo e flutuação separada, foco visual estável com substituição de incapacitado, recuo mantendo atenção no aliado, alvo efetivo durante ataque, exceção fixa, interrupção/retomada exatas em todas as fases para terrestre/voador e melee/tela inteira, centro visual exato, formações com margens e sem sobreposição de corpos e configurações inválidas imóveis sem travamento.

As suítes de integração atuais passaram a verificar os IDs novos, comportamento em todos os móveis e formações válidas, sem exigir igualdade das coordenadas aliadas antigas (variação agora autorizada). Continuam verificando composição, atributos, cenário, alvos, ações, fuga de M2, HP/MP e retorno. As suítes históricas usam os mesmos IDs antigos e conservaram suas fixtures; `pre_behavior_combat.json` registra todas as dez opções anteriores, sem escondê-las dos testes de preservação.

Capturas inspecionadas: `seeded-default.png`, `seeded-formation-12.png`, `seeded-formation-13.png`, `seeded-formation-14.png`, `seeded-hover-debug.png` e os combates integrados/percursos no mesmo diretório. Centrar rótulos melhora leitura com participantes nos dois lados; formas continuam provisórias. Nenhum sprite novo foi criado/importado.

Parâmetros de sorteio, velocidades, durações, cinco formações e retenção do foco são experimentais. Não foram alterados INI, custos, dano, perfis ponderados, permissões de fuga, patrulhas do mapa, relógio, câmera ou terrenos. O mundo permanece sem monstros comuns; os combates são acessados na dungeon. Não há novo save/replay persistente ou teste de exportação/outras plataformas. Arquitetura e controles em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md).

## Adoção do modelo atual em todos os encontros de exploração

Executada em **25/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; Compatibility nas execuções gráficas.

| Suíte | Resultado |
| --- | --- |
| `tests/exploration_rhythm_tests.gd` | 2.117 verificações, zero falhas. |
| Mesma suíte com renderização real | 2.121 verificações, incluindo quatro capturas, zero falhas. |
| `tests/internal_areas_ui_smoke.gd` com renderização real | 57 verificações, incluindo cinco capturas, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.338 verificações, zero falhas; valida as entradas dos quatro presets atuais. |
| Demais 29 suítes headless | Todas executadas e aprovadas. Contagens detalhadas no log. |

Total: **31 suítes headless aprovadas**, mais duas execuções gráficas. Logs em `artifacts/encounter-rhythms/regression.log` e `graphics.log`. Capturas novas de M1/M4 e do percurso real pela dungeon no mesmo diretório; M1/M4 inspecionados visualmente.

A nova suíte visita os seis encontros do catálogo real por transições, valida que nenhum referencia legado, compara formação/composição/atributos/cenário/alvos/ações/fuga com o registro anterior, verifica os perfis novos de todos os móveis, rotas dentro do campo e próximas do grupo sem sobreposição dos aliados, estáticos e exceções de centro. Exercita Wait/Active, agendamento pela IA existente/ATB, execução/retorno/retomada exatos, UI compartilhada, pausa das patrulhas do mapa, cinco fugas/reencontros determinísticos, bloqueio de fuga de M2 e seis vitórias com HP/MP persistentes. O laboratório independente inicia em F e identifica A–E como Legado.

As suítes que usam dados atuais foram ajustadas apenas nas expectativas de preset de M4, no conjunto de IDs atuais e no total de opções. O teste genérico de UI mira a posição lógica atual do inimigo ao confirmar a área, mantendo o mesmo fluxo de comando. Fixtures e testes dos modelos históricos foram preservados. Nenhuma regra de combate, perfil ponderado, INI, atributo, custo, permissão de fuga, posição inicial ou patrulha de exploração foi alterada; a mudança é de configuração de movimento e seleção inicial de preset. Parâmetros geométricos e velocidades seguem provisórios. Outras plataformas e exportação não foram verificadas. Ver [RITMOS_BATALHA.md](RITMOS_BATALHA.md).

## Ritmos mais lentos, retornos parciais e aproximações — E/F

Executada em **25/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro, Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/rhythm_tests.gd` | 11 grupos, 56.409 verificações, zero falhas. |
| `tests/rhythm_ui_smoke.gd` | 25 verificações, zero falhas. |
| Mesma suíte com renderização real | 35 verificações, incluindo cinco capturas do campo e cinco da janela F3, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.310 verificações, zero falhas; inclui validação das entradas do preset F. |
| Outras 27 suítes headless | Todas executadas e aprovadas, contagens preservadas. |

Total: **30 suítes headless aprovadas**, mais a execução gráfica. Lista/saídas em `artifacts/rhythm-refined/regression.log`; renderização em `graphics.log`. Os resultados das entregas anteriores abaixo permanecem históricos.

Cobertura adicional: velocidades dos três perfis menores que na demonstração anterior, retornos parciais na sequência aberta, visita a marcos em ordem não monotônica, repousos distintos, fechamento exato em zero, frenagem até zero em reversões mesmo sem pausa, velocidades/pausas diferentes na volta, rejeição segura de configurações inválidas e preservação dos padrões antigos. Preset F validado no modelo e na UI: voo dentro do campo, distância aos corpos aliados, aproximação real e afastamento amplo, aliados fixos durante a simulação e ataque próximo com origem/ritmo preservados. Continuam cobertos Wait/Active, ATB durante repouso, melee único/múltiplo, tela inteira e retomada exata de todas as etapas.

Capturas inspecionadas: `rhythm-start.png`, `rhythm-moving.png`, `rhythm-fullscreen.png`, `approach-near-party.png`, `approach-melee-impact.png` e correspondentes `-debug.png` em `artifacts/rhythm-refined/`. Os parâmetros permanecem experimentais. Nenhum script/dado de exploração, ficha de combate, INI, duração de ação, perfil de alvo ou preset A–D foi alterado. E recebeu os ajustes e F demonstra aproximações. Não há perseguição, navegação aleatória ou dano por contato. Outras plataformas e exportação não foram verificadas. Dados e roteiro em [RITMOS_BATALHA.md](RITMOS_BATALHA.md).

## Ritmos programados dentro da batalha — preset E

Executada em **25/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro, Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/rhythm_tests.gd` | 8 grupos, 16.295 verificações, zero falhas. |
| `tests/rhythm_ui_smoke.gd` | 21 verificações, zero falhas. |
| Mesma suíte com renderização real | 27 verificações, incluindo três capturas do campo e três da janela F3, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.301 verificações, zero falhas. Aumento pela validação automática das entradas do novo preset. |
| Regressões anteriores de curvas/melee e tela inteira | Quatro suítes executadas e aprovadas, contagens preservadas. |
| Demais regressões de UI, exploração, interações, áreas, câmera, profundidade, relevo, relógio e eventos | Todas executadas e aprovadas, contagens preservadas. |

Total: **30 suítes headless aprovadas**, incluindo as duas novas, mais uma execução gráfica. Lista completa e saídas em `artifacts/rhythm/regression.log`; execução gráfica em `artifacts/rhythm/graphics.log`. Nenhuma suíte anterior precisou ser alterada para esta entrega.

Cobertura nova: preservação integral de A–D/dados anteriores; herança perfil→tipo→encontro e cópia segura; aceleração/distância analíticas, desaceleração, pausas, retorno e inversão sem fechamento artificial; continuidade do voo e velocidades diferentes sem vínculo com INI; subdivisão de tempo e passos enormes; inválidos/degenerados sem travamento; ATB carregando durante parada; Wait/Active; interrupção em espera inicial, aceleração, percurso, desaceleração, pausa e retorno para melee único/múltiplo e tela inteira; retorno à origem e próximo tick exatamente igual ao avanço do snapshot; separação da mira lógica e flutuação visual; pausa manual, Passo e velocidade 2×; clique na apresentação visual; voador chegando ao centro exato e retornando à mesma fase visual.

Capturas inspecionadas em `artifacts/rhythm/`: `rhythm-start.png`, `rhythm-moving.png`, `rhythm-fullscreen.png` e correspondentes `-debug.png`. Formas provisórias, caminhos abertos desenhados sem fechamento, parâmetros visíveis em F3 e ausência de ATB inimigo no campo normal. Logs finais sem erros de script.

Os parâmetros de ritmo, posições e tipos são demonstrativos. A sequência continua repetível, sem navegação aleatória ou IA reativa. Encontros do mapa mantêm seus presets; a comparação nova é acessada no laboratório independente. Nenhum script/dado de exploração foi modificado. Outras plataformas/exportação não foram validadas nesta entrega. Configuração, arquivos e roteiro em [RITMOS_BATALHA.md](RITMOS_BATALHA.md).

## Eventos de dia/noite — segunda casa e descoberta persistente

Executada em **24/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/town_events_tests.gd` | 7 grupos, 214 verificações, zero falhas. |
| `tests/town_events_ui_smoke.gd` | 72 verificações, zero falhas. |
| Mesma suíte com renderização real | 83 verificações, incluindo seis capturas e cinco comparações de pixels, zero falhas. |
| Regressão `internal_areas_tests.gd` | 8 grupos, 6.370 verificações, zero falhas. |
| Regressão `internal_areas_ui_smoke.gd` | 52 verificações, zero falhas. |
| Regressão `camera_tests.gd` | 5 grupos, 110 verificações, zero falhas. |
| Regressão `depth_tests.gd` | 6 grupos, 264 verificações, zero falhas. |
| Regressão `world_map_tests.gd` | 8 grupos, 3.638 verificações, zero falhas. |
| Regressão `world_time_tests.gd` | 6 grupos, 70 verificações, zero falhas. |
| Demais vinte regressões headless | Todas executadas e aprovadas, contagens anteriores preservadas. |
| Profundidade com renderização real | 29 verificações, incluindo seis comparações de pixels, zero falhas. |
| Desempenho com renderização real | 13 verificações, zero falhas. |

Total: **28 suítes headless aprovadas**, além das três execuções gráficas. Lista e saídas finais em `artifacts/town-events/regression.log` e `graphics.log`.

Cobertura nova: catálogo de cinco áreas com a segunda casa, entradas/saídas/fila livres, caminho real por teclado, paredes do novo interior, mesma instância de relógio e pausa nas duas casas/cidade, ida ao mapa-múndi e retorno natural às 19:00/07:00, instruções diurnas preservadas com dica nova, NPC 4 em posições válidas e sem duplicação, NPC 5 com fala diurna/noturna, continuidade de rota no mesmo posicionamento, atualização adiada durante diálogo/cutscene ou destino ocupado pela fila, retomada após liberar destino, falha segura com posição inválida, disponibilidade independente do diálogo, inscrição indisponível de dia e descoberta única à noite, prioridade da flag registrada em qualquer horário, sinal emitido uma única vez, permanência entre horários/áreas/ambas as casas/revisitas, falha de diálogo sem marcar flag e reinício explícito.

As suítes anteriores que usam o catálogo real foram ajustadas somente onde o requisito mudou: quinta área, novo acesso, pedra sólida e conteúdos permitidos na vila. A suíte de rotas não trata o centro da pedra sólida como local caminhável, assim como já fazia com a porta sólida. Os casos de navegação, pausas, recursos, câmera, interações, transições e combate permanecem. Nenhuma fixture nova foi criada para ocultar a expansão; regressões históricas conservam suas fixtures anteriores.

Capturas inspecionadas: `town-second-house-interior.png`, `town-original-house-day.png`, `town-second-house-day.png`, `town-original-house-night.png`, `town-second-house-night.png` e `town-secret-discovered.png` em `artifacts/town-events/`. Comparações de pixels confirmam que ambas as janelas acendem, o poste acende, a pedra muda e o halo modifica o chão próximo com o mesmo horário noturno. Foram usadas somente formas/corpos já existentes, sem criar/importar sprites.

O teste gráfico de desempenho conserva uma consulta de origem da câmera por desenho e valida que o relógio real avança apenas no mapa-múndi. Medianas locais do callback: aproximadamente 0,496 ms na vila, 1,567 ms na entrada do mundo, 1,437 ms no mundo à noite, 1,340 ms na floresta, 1,985 ms na rampa e 1,879 ms no platô (`artifacts/town-events/render.json`). Não representam garantia universal de FPS.

Logs finais sem erros de script. Relógio de 120 segundos, mapa-múndi, controlador de entrada, modelo de diálogo, dados/scripts/cena do combate e câmera foram preservados. A flag é persistente **na sessão**; save em disco não foi implementado. Também não foram implementados pathfinding, rotina entre mapas, recompensa, missão completa, calendário/clima ou cutscene nova. Outras plataformas e exportação release não foram verificadas. Esquema de dados, API e limites em [EVENTOS_DIA_NOITE.md](EVENTOS_DIA_NOITE.md).

## Avanço automático somente no mapa-múndi — ciclo de 2 minutos

Atualização executada em **24/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro, Compatibility na execução gráfica. Substitui a configuração inicial de mapas todos pausados e ciclo de 24 minutos descrita na validação anterior.

`data/world.json` agora classifica `test_world` como `overworld`, com `time_advances: true`; vila/casa/dungeon continuam pausados. `data/world_clock.json` define **120 segundos reais permitidos para as 24 horas do jogo**. A prévia automática e seu multiplicador foram removidos de `clock_debug.gd`, eliminando a possibilidade de simular avanço natural em outras áreas pelo painel. Eventos manuais e descanso 07:00 permanecem.

| Suíte | Resultado |
| --- | --- |
| `world_clock_tests.gd` | 5 grupos, 1.478 verificações, zero falhas. |
| `world_time_tests.gd` | 6 grupos, 68 verificações, zero falhas. |
| `world_clock_ui_smoke.gd` | 52 verificações, zero falhas. |
| `day_lighting_tests.gd` | 2.894 verificações, zero falhas. |
| Outras 22 suítes headless | Todas executadas e aprovadas, contagens anteriores preservadas. |
| Relógio/UI com renderização real | 59 verificações, incluindo quatro capturas e três comparações de pixels, zero falhas. |
| `render_performance.gd` com renderização real | 13 verificações, zero falhas. |

**26 suítes headless aprovadas.** Logs em `artifacts/clock-120s/regression.log` e `graphics.log`; capturas no mesmo diretório. O teste do relógio confirma uma hora do jogo por 5 segundos reais, meio ciclo por 60 segundos e ciclo completo por 120 segundos, além de frações/meia-noite e duração configurável. O tempo foi simulado por deltas explícitos para verificar o ciclo completo; não foi necessário esperar dois minutos de parede.

A integração usa agora os metadados REAIS do mapa, sem fixture de reclassificação. Testa avanço somente em `test_world`, pausas de menu/diálogo/transição/batalha/derrota, retomada sem tempo acumulado, preservação entre áreas, alteração narrativa e descanso. A UI comprova avanço com F3 fechado, ciclo completo, retorno da dungeon retomando e entrada na vila pausando, além do combate real e dos controles anteriores.

O teste gráfico de desempenho roda também o loop normal da engine: o relógio permanece às 10:00 na vila e começa a avançar ao entrar no mapa-múndi, sem nenhuma ativação de F3. Mantém uma consulta de câmera por desenho; mediana local de aproximadamente 1,441 ms na entrada do mundo e 1,324 ms à noite (`artifacts/clock-120s/render.json`). São custos de desenho na CPU, não uma garantia universal de FPS.

A captura `clock-debug-dusk.png` foi inspecionada para confirmar a remoção da prévia e a permanência das consultas/eventos de teste. Nenhum erro de script nas execuções finais. Combate, movimento, colisões, câmera, topologia e regras de iluminação não foram alterados. Outras plataformas e exportação release não foram verificadas. Uso vigente em [CICLO_DIA_NOITE.md](CICLO_DIA_NOITE.md).

## Validação anterior — relógio com áreas pausadas e prévia de teste

Executada em **24/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro, Compatibility na inspeção gráfica.

| Suíte | Resultado final |
| --- | --- |
| `tests/world_clock_tests.gd` | 5 grupos, 1.477 verificações, zero falhas. |
| `tests/world_time_tests.gd` | 6 grupos, 68 verificações, zero falhas. |
| `tests/day_lighting_tests.gd` | 2.894 verificações, zero falhas. |
| `tests/world_clock_ui_smoke.gd` | 42 verificações, zero falhas. |
| Relógio/UI com renderização real | 49 verificações, incluindo quatro capturas e três comparações de pixels, zero falhas. |
| `tests/depth_ui_smoke.gd` com renderização real | 29 verificações, incluindo seis comparações de pixels, zero falhas. |
| `tests/render_performance.gd` com renderização real | 11 verificações, incluindo medição noturna e orçamento de câmera, zero falhas. |
| As 22 regressões headless anteriores | Todas executadas novamente e aprovadas, contagens preservadas. |

Total: **26 suítes headless aprovadas** (22 anteriores e quatro novas), além das três verificações gráficas acima. Lista e saídas finais em `artifacts/day-night/regression.log`. As anteriores foram `run_tests`, `ui_smoke`, `exploration_tests`, `exploration_ui_smoke`, `motion_tests`, `motion_ui_smoke`, `fullscreen_tests`, `fullscreen_ui_smoke`, `interaction_tests`, `interaction_ui_smoke`, `area_tests`, `area_ui_smoke`, `internal_areas_tests`, `internal_areas_ui_smoke`, `camera_tests`, `camera_ui_smoke`, `depth_tests`, `depth_ui_smoke`, `world_map_tests`, `world_map_ui_smoke`, `terrain_tests` e `terrain_ui_smoke`.

Cobertura: cada minuto do dia e limites configurados; duração/partição de deltas; fração de minuto; definição arbitrária e avanço pela meia-noite; sinais sem duplicação; configuração inválida; descanso 07:00 a partir de 10/18/23/03/07 horas; cidades e interiores pausados; quatro mapas reais explicitamente pausados; mapa-múndi em fixture isolada avançando sem modificar catálogo; guardas de menu/diálogo/batalha/derrota/transição; mesma instância nas viagens; alteração narrativa em interior e sob fade; ausência de tempo residual na chegada; descanso sem cura; iluminação contínua inclusive à meia-noite; noite legível e HUD preservado; campos/F3/Tab e liberação de foco; prévia sem reclassificação ou avanço oculto; variante noturna do NPC 5; fala aberta estável; vitória real preservando relógio; reinício e desconexão do sinal anterior.

A primeira regressão detectou foco de navegação dos SpinBox capturando Tab com F3 aberto. Foi corrigido com foco por clique e liberação ao confirmar/Enter/fechar o painel. As suítes de interações e rampa, além das demais, passaram após a correção. Não foi alterada a expectativa dos testes anteriores para esconder o problema.

Capturas inspecionadas em `artifacts/day-night/`: `clock-day-town.png`, `clock-night-town.png`, `clock-debug-dusk.png` e `clock-night-world.png`. Confirmam a apresentação simples, HUD preservado e painel de desenvolvimento. O teste gráfico verifica mudança real de pixels com hora noturna, visibilidade mínima do chão e ausência de escurecimento no HUD.

Em `artifacts/day-night/render-clock.json`, o callback de desenho mediano mediu aproximadamente 0,406 ms na vila, 1,575 ms na entrada do mundo, **1,426 ms na entrada à noite**, 1,292 ms na floresta, 2,092 ms na rampa e 1,901 ms no platô, sempre com uma consulta de origem da câmera por desenho. São medições locais de CPU, não garantia de FPS/plataformas. A otimização anterior foi preservada; não há cálculo de iluminação por vértice.

Logs finais não registraram erros de script. Não houve alteração nos scripts/dados/cena do combate, modelo de movimento/rota/câmera/diálogo ou topologia. Sem validação de exportação release, outras plataformas, salvamento em disco, calendário, agenda de NPCs ou pousada completa. Regras, decisões provisórias, APIs, arquivos e roteiro em [CICLO_DIA_NOITE.md](CICLO_DIA_NOITE.md).

## Correção de lentidão ao entrar no mundo aberto

Executada em **24/10/2026**, após relato de muita lentidão. A versão anterior recalculava origem/escala da câmera e consultava altura do líder para cada vértice das copas, além de redesenhar florestas fora da tela. As suítes funcionais anteriores não mediam esse custo por quadro.

Correção limitada a `scripts/exploration/exploration_view.gd`: transformação da câmera reutilizada durante um desenho, círculo unitário preparado uma vez, transformação por centro/raios e descarte conservador de terreno fora da câmera. Consultas públicas fora do desenho continuam calculando a projeção atual, inclusive após movimento, alteração de escala/tamanho e troca de área. Não houve mudança em colisões, relevo, dados, combate ou transições.

Medições do callback de desenho em Godot 4.7.2 Compatibility, janela 1440×960, macOS/Apple M3 Pro; mediana de 16 amostras por posição:

| Posição | Antes | Corrigido | Consultas de origem antes → depois |
| --- | --- | --- | --- |
| Vila | 1,756 ms | 0,405 ms | 608 → 1 |
| Entrada do mundo | 32,150 ms | 1,243 ms | 8.418 → 1 |
| Floresta | 32,191 ms | 1,256 ms | 8.418 → 1 |
| Rampa | 25,027 ms | 2,141 ms | 8.418 → 1 |
| Platô | Não medido antes | 2,031 ms | — → 1 |

Esses tempos medem o callback de desenho na CPU, não o tempo total de quadro/FPS nem todas as máquinas. Medições anteriores estão em `artifacts/render-before.log`; corrigidas em `artifacts/render-after.json`.

`tests/render_performance.gd` e a fixture `profile_exploration_view.gd` verificam o orçamento de uma consulta de origem por desenho sem um limite temporal dependente do computador. O teste falhou na versão anterior por repetição de consultas e passou na corrigida: **10 verificações, zero falhas**. Também percorre a transição com `_physics_process` normal habilitado, espera o fade concluir, confirma movimento/câmera e projeção após alterações.

As **22 suítes headless anteriores foram executadas novamente e passaram**, com as mesmas contagens da seção de relevo abaixo (`artifacts/render-regression.log`). Em renderização real: `depth_ui_smoke.gd` passou com 29 verificações, incluindo seis comparações de pixels; `terrain_ui_smoke.gd` passou com 90 e seis capturas; `world_map_ui_smoke.gd` passou com 56 e sete capturas. Capturas atualizadas em `artifacts/performance/`. Logs finais não registraram erros de script. O laboratório independente continua coberto por `run_tests` e `ui_smoke`.

## Colinas sólidas, rampas e florestas inacessíveis

Executada em **24/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; OpenGL Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/terrain_tests.gd` | 7 grupos, 2.814 verificações, zero falhas. |
| `tests/terrain_ui_smoke.gd` | 84 verificações, zero falhas. |
| Relevo/UI com renderização real | 90 verificações, incluindo seis capturas, zero falhas. |
| `tests/world_map_tests.gd` | 8 grupos, 3.624 verificações, zero falhas. |
| `tests/world_map_ui_smoke.gd` | 49 verificações, zero falhas. |
| Mundo/UI com renderização real | 56 verificações, incluindo sete capturas, zero falhas. |
| Laboratório independente com renderização real, `ui_smoke.gd` | 31 verificações, zero falhas. |
| Dezoito regressões restantes | Todas executadas novamente, zero falhas. |

As dezoito foram `run_tests` (104.292 verificações), `ui_smoke` (31), `exploration_tests` (3.338), `exploration_ui_smoke` (30), `motion_tests` (1.944), `motion_ui_smoke` (16), `fullscreen_tests` (620), `fullscreen_ui_smoke` (26), `interaction_tests` (3.597), `interaction_ui_smoke` (36), `area_tests` (146), `area_ui_smoke` (39), `internal_areas_tests` (5.954), `internal_areas_ui_smoke` (50), `camera_tests` (106), `camera_ui_smoke` (50), `depth_tests` (239) e `depth_ui_smoke` (23). Total: **22 suítes headless aprovadas**. Fixtures históricas continuam separadas dos mapas reais.

Cobertura nova: interior inteiro das massas florestais/colina fechada, bordas em quatro direções, colisão varrida com delta grande, bloqueio lateral da rampa e saída pelas bordas, chegada contínua ao platô, alturas individuais dos seguidores na curva de acesso, reversão/descida sem salto ou altura residual, preservação das coordenadas de chão, pausas/menu/liderança, rejeição de rampa malformada/desalinhada/estreita, chegada segura e bloqueio de interações através de paredão, ordenação atrás/sobre o platô e câmera acompanhando a altura com zoom preservado. Percurso real por teclado desde a vila comprova acesso à rampa sem teleporte. Regra antiga de colina livre foi atualizada na suíte do mundo; posições de captura foram movidas para trechos livres.

Capturas `artifacts/terrain-ramp-base.png`, `terrain-ramp-ascent.png`, `terrain-ramp-debug.png`, `terrain-plateau.png`, `terrain-ramp-descent.png` e `terrain-forest.png` permitem conferir o relevo provisório. As capturas do mundo também foram atualizadas. Scripts/dados/cenas do combate não foram alterados; transições e sessão continuam compartilhando o combate anterior. Não houve erro/aviso de script nas execuções finais. Documentação em [RELEVO_E_FLORESTAS.md](RELEVO_E_FLORESTAS.md). Alturas, dimensões e desenho permanecem experimentais; outras plataformas, camadas sobrepostas e arte definitiva não foram validadas.

## Validação anterior — vila e mundo aberto, antes do relevo sólido

Executada em **24/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/world_map_tests.gd` | 8 grupos, 3.624 verificações, zero falhas. |
| `tests/world_map_ui_smoke.gd` | 49 verificações, zero falhas. |
| Mesma suíte com renderização real | 56 verificações, incluindo sete capturas, zero falhas. |
| Regressão `tests/internal_areas_tests.gd` | 8 grupos, 5.954 verificações, zero falhas. |
| Regressão `tests/internal_areas_ui_smoke.gd` | 50 verificações, zero falhas. |
| Regressão `tests/camera_tests.gd` | 5 grupos, 106 verificações, zero falhas. |
| Regressão `tests/camera_ui_smoke.gd` | 50 verificações, zero falhas. |
| Regressão `tests/depth_tests.gd` | 6 grupos, 239 verificações, zero falhas. |
| Regressão `tests/depth_ui_smoke.gd` | 23 verificações, zero falhas. |
| Regressão de profundidade com renderização real, sem capturas | 29 verificações, incluindo seis comparações de pixels, zero falhas. |
| Doze regressões restantes | Todas executadas novamente, zero falhas; contagens anteriores preservadas. |

As doze restantes foram `run_tests`, `ui_smoke`, `exploration_tests`, `exploration_ui_smoke`, `motion_tests`, `motion_ui_smoke`, `fullscreen_tests`, `fullscreen_ui_smoke`, `interaction_tests`, `interaction_ui_smoke`, `area_tests` e `area_ui_smoke`. As suítes atuais de interiores/câmera/profundidade agora percorrem os acessos adicionais reais vila↔mundo e verificam os NPCs na casa e nas ruas. Não foram criadas novas fixtures para contornar a topologia atual; as fixtures históricas anteriores continuam separadas do catálogo jogável.

Cobertura nova: grafo casa↔vila↔mundo↔dungeon sem acesso direto vila↔dungeon; mesmos cinco NPCs distribuídos em dois locais; retorno explícito do mundo à vila; percurso físico inicial até o portão e do mundo até a dungeon, com quatro integrantes fora dos sólidos; ausência de encontros comuns por tempo/proximidade no mundo; terreno visual validado; mar e bases das montanhas sólidos; colinas caminháveis; água na camada de chão sem entrar na oclusão; conversa de NPC externo pausando grupo/patrulha; respostas mantidas na casa; combate compartilhado, retorno à dungeon, vitória persistente, HP/MP/incapacitação, liderança, objetos e patrulha preservados entre quatro áreas; reinício global.

Foram inspecionadas as capturas `artifacts/world-town-streets.png`, `world-town-access.png`, `world-dungeon-access.png`, `world-forest-hills.png`, `world-mountains.png`, `world-coast.png` e `world-house-npcs.png`. Rótulos da praça e a base do marcador da vila foram ajustados após inspeção para melhorar legibilidade; testes e capturas finais foram repetidos. Logs das vinte suítes, da renderização nova e da regressão gráfica de profundidade não registraram erros/avisos.

Comparação SHA-256 confirmou preservação dos scripts/dados de combate, modelos de movimento/câmera/diálogo, cenas e configuração do projeto. A sessão só recebeu nova mensagem inicial; algoritmos de transição e retorno de combate foram mantidos. Entre os arquivos anteriores monitorados, mudaram vista, validação do catálogo, camada de profundidade, legenda da UI e dados de áreas. O novo mundo está em JSON próprio. Paisagem, dimensões, distribuição dos NPCs e travessia são provisórias, sem validação de conteúdo definitivo, salvamento ou outras plataformas. Arquivos e roteiro em [VILA_E_MUNDO.md](VILA_E_MUNDO.md).

## Profundidade visual e bases de colisão

Executada em **24/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro; Compatibility na execução gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/depth_tests.gd` | 6 grupos, 199 verificações, zero falhas. |
| `tests/depth_ui_smoke.gd` | 21 verificações, zero falhas. |
| Mesma suíte com renderização real | 37 verificações, incluindo seis comparações de pixels e dez capturas, zero falhas. |
| Dezesseis regressões anteriores | Todas executadas novamente, zero falhas; contagens anteriores preservadas. |

Foram executadas novamente as suítes `run_tests`, `ui_smoke`, `exploration_tests`, `exploration_ui_smoke`, `motion_tests`, `motion_ui_smoke`, `fullscreen_tests`, `fullscreen_ui_smoke`, `interaction_tests`, `interaction_ui_smoke`, `area_tests`, `area_ui_smoke`, `internal_areas_tests`, `internal_areas_ui_smoke`, `camera_tests` e `camera_ui_smoke`. Fixtures históricas e mapas reais mantêm sua separação documentada nas seções anteriores.

Cobertura nova: metadados visuais válidos/inválidos; base inferior e configuração individual; estrutura antes/depois de ator conforme lado; empates estáveis; copa independente da colisão e tronco sólido; fundação da casa preservada; quatro integrantes contornando árvore com profundidades diferentes; NPCs, monstros e objetos na mesma ordenação; porta aberta no chão e fechada na fila de corpos; cálculo puro sem alterações de dados, coordenadas, fila ou rotas. A suíte gráfica altera temporariamente a cor do personagem e confirma que pixels encobertos permanecem iguais e pixels à frente mudam, para árvore, casa e parede.

Foram produzidas e inspecionadas capturas `artifacts/depth-tree-behind.png`, `depth-tree-front.png`, `depth-house-behind.png`, `depth-house-front.png`, `depth-wall-behind.png`, `depth-wall-front.png`, `depth-party-around-tree.png`, `depth-footprints-debug.png`, `depth-house-interior.png` e `depth-dungeon.png`. Mostram as estruturas encobrindo sprites atrás e a fila visível à frente, com sombras abaixo dos corpos. Logs finais das dezoito suítes e da renderização real não registraram erros/avisos.

Comparação SHA-256 confirmou preservação dos modelos de exploração/sessão/câmera/diálogo, rotas e combate, dados de combate, catálogo de áreas, cenas e configuração do projeto. Entre os arquivos anteriores monitorados, mudaram apenas a vista, a validação do catálogo e os três JSON de mapas. As bases físicas foram alteradas somente nas árvores atuais; os demais retângulos, posições e rotas foram preservados. O novo cálculo de profundidade é um módulo próprio. Alturas, proporções e formas continuam provisórias, sem validação de arte definitiva ou de outras plataformas. Configuração e roteiro em [PROFUNDIDADE_EXPLORACAO.md](PROFUNDIDADE_EXPLORACAO.md).

## Câmera da exploração — escala da casa e seguimento do líder

Executada em **24/10/2026**, Godot 4.7.2 Standard no macOS/Apple M3 Pro; Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/camera_tests.gd` | 5 grupos, 102 verificações, zero falhas. |
| `tests/camera_ui_smoke.gd` | 41 verificações, zero falhas. |
| Mesma suíte com renderização real | 49 verificações, incluindo quatro capturas e quatro verificações de pixels fora da janela do mapa, zero falhas. |
| Quatorze regressões anteriores | Todas executadas novamente, zero falhas; contagens preservadas conforme a seção de interiores abaixo. |

As regressões executadas foram `run_tests`, `ui_smoke`, `exploration_tests`, `exploration_ui_smoke`, `motion_tests`, `motion_ui_smoke`, `fullscreen_tests`, `fullscreen_ui_smoke`, `interaction_tests`, `interaction_ui_smoke`, `area_tests`, `area_ui_smoke`, `internal_areas_tests` e `internal_areas_ui_smoke`, todas em `tests/`. As fixtures dos layouts anteriores e os mapas reais mantêm a separação descrita na validação de interiores.

Cobertura nova: escala anterior da casa em diferentes tamanhos de vista; tamanho de sprite igual entre três áreas; limites e centralização de eixos curtos; seguimento do líder e da nova identidade após troca pelo menu; transformação reversível entre mundo/tela; ausência de mutações de coordenadas, fila, rotas, recursos e combate; transições com câmera do destino sob fade; interações na casa; pausa durante diálogo; retorno de vitória com enquadramento preservado; recarga da referência de escala ao reiniciar; cenário recortado sem invadir HUD.

Capturas `artifacts/camera-house.png`, `camera-dungeon-entry.png`, `camera-dungeon-follow.png` e `camera-exterior.png` foram inspecionadas. Confirmam o tamanho anterior da casa, dungeon ampliada com salas fora do enquadramento e acompanhamento do novo líder. A comparação de pixels no espaço acima da vista confirmou o recorte nas quatro cenas. Logs finais das dezesseis suítes e da renderização real não registraram erros/avisos.

Comparação SHA-256 com o estado anterior confirmou que, entre os arquivos de execução existentes monitorados, somente `exploration_test.gd`, `exploration_view.gd` e `data/areas.json` mudaram. O novo cálculo de câmera fica em módulo próprio. Modelos, mapas individuais, cenas, configuração e scripts/dados de combate foram preservados. A validação não cobre arte ou resolução definitiva nem outras plataformas. Configuração, limites provisórios e roteiro em [CAMERA_EXPLORACAO.md](CAMERA_EXPLORACAO.md).

## Distribuição em interiores — casa e mini dungeon

Executada em **24/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro; Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/internal_areas_tests.gd` — mapas reais | 8 grupos, 5.523 verificações, zero falhas. |
| `tests/internal_areas_ui_smoke.gd` — mapas reais | 39 verificações, zero falhas. |
| Mesma suíte com renderização real | 44 verificações, incluindo cinco capturas, zero falhas. |
| `tests/run_tests.gd` | 14 grupos, 104.292 verificações, zero falhas. |
| `tests/ui_smoke.gd` | 31 verificações, zero falhas. |
| `tests/motion_tests.gd` | 9 grupos, 1.944 verificações, zero falhas. |
| `tests/motion_ui_smoke.gd` | 16 verificações, zero falhas. |
| `tests/fullscreen_tests.gd` | 10 grupos, 620 verificações, zero falhas. |
| `tests/fullscreen_ui_smoke.gd` | 26 verificações, zero falhas. |
| Regressão `tests/exploration_tests.gd` — fixture anterior | 9 grupos, 3.338 verificações, zero falhas. |
| Regressão `tests/exploration_ui_smoke.gd` — fixture anterior | 30 verificações, zero falhas. |
| Regressão `tests/interaction_tests.gd` — fixture anterior | 9 grupos, 3.597 verificações, zero falhas. |
| Regressão `tests/interaction_ui_smoke.gd` — fixture anterior | 36 verificações, zero falhas. |
| Regressão `tests/area_tests.gd` — fixture anterior | 9 grupos, 146 verificações, zero falhas. |
| Regressão `tests/area_ui_smoke.gd` — fixture anterior | 39 verificações, zero falhas. |

Cobertura dos mapas reais: exterior sem NPCs, encontros ou objetos locais; dois acessos; cinco NPCs e placa somente na casa; seis encontros e três objetos somente na dungeon; mesmas referências A/B/C/D; dados, rotas e entradas livres; aproximação selecionável a todas as entidades; alavanca alcançável com a porta fechada e todas as salas alcançáveis após abri-la; caminho físico com quatro integrantes até a alavanca e passagem; diálogos/respostas/pausas na casa; baú sem recompensa nova; seis vitórias reais retornando à dungeon com HP/MP, fila e apenas o ID correto removido; fuga, revisita de três áreas, liderança, objetos, retomada exata de rotas e reinício global.

As seis suítes anteriores que dependiam de posições fixas passaram a usar o snapshot `tests/fixtures/areas_before_internal_split.json`, com uma subclasse de UI exclusiva de testes. Seus casos de colisão, diálogos, erros de destino, reentrada e resultados de combate foram mantidos. Essa fixture não pertence ao catálogo jogável. As duas novas suítes carregam os JSON reais do catálogo e verificam a distribuição atual.

Foram inspecionadas `artifacts/interiors-exterior.png`, `interiors-house-npcs.png`, `interiors-house-dialogue.png`, `interiors-dungeon.png` e `interiors-dungeon-open.png`. A acessibilidade detectou uma sala inicialmente sem passagem, corrigida antes da validação final; o rótulo de NPC sobreposto ao título também foi reposicionado. As execuções finais e capturas foram repetidas. Logs das quatorze suítes e da renderização real não registraram erros/avisos.

Comparação SHA-256 confirmou preservação de todos os scripts/dados de combate, modelos de exploração/diálogo/catálogo, cenas e configuração do projeto. Os únicos scripts de execução alterados foram a vista (cores/ícone), a legenda da UI e a mensagem inicial da sessão. Layouts, coordenadas e colocação dos objetos continuam provisórios. Não valida balanceamento, arte definitiva, saves ou outras plataformas. Roteiro e arquivos em [INTERIORES_DUNGEON.md](INTERIORES_DUNGEON.md).

## Transições casa ↔ laboratório

Executadas em **24/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro, Compatibility na inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/area_tests.gd` | 9 grupos, 146 verificações, zero falhas. |
| `tests/area_ui_smoke.gd` | 39 verificações, zero falhas. |
| Mesma suíte com renderização real | 43 verificações, incluindo quatro capturas, zero falhas. |
| Regressão `tests/run_tests.gd` | 14 grupos, 104.292 verificações, zero falhas. |
| Regressão `tests/ui_smoke.gd` | 31 verificações, zero falhas. |
| Regressão `tests/exploration_tests.gd` | 9 grupos, 3.338 verificações, zero falhas. |
| Regressão `tests/exploration_ui_smoke.gd` | 30 verificações, zero falhas. |
| Regressão `tests/motion_tests.gd` | 9 grupos, 1.944 verificações, zero falhas. |
| Regressão `tests/motion_ui_smoke.gd` | 16 verificações, zero falhas. |
| Regressão `tests/fullscreen_tests.gd` | 10 grupos, 620 verificações, zero falhas. |
| Regressão `tests/fullscreen_ui_smoke.gd` | 26 verificações, zero falhas. |
| Regressão `tests/interaction_tests.gd` | 9 grupos, 3.597 verificações, zero falhas. |
| Regressão `tests/interaction_ui_smoke.gd` | 36 verificações, zero falhas. |

Cobertura nova: catálogo e referências de entradas; percurso físico até a casa; ida/volta; preservação de equipe, recursos, líder escolhido no exterior e no interior; reconstrução da trilha local inteira; colisões internas; estado de baú/porta/alavanca e vitória real preservados ao revisitar; congelamento de área inativa e retomada exata da patrulha; fade, troca no escuro, bloqueio de movimento/menu/duplicação, passos grandes; guardas de diálogo/batalha/derrota; área inexistente/malformada, entrada inexistente, direção inválida, líder/cauda/trecho inicial bloqueados; falha sem cache parcial ou controles presos; revalidação de destino visitado; proteção de reentrada e reinício durante transição. Encontros adicionados somente nas fixtures confirmam fuga/vitória e retorno à segunda área, sem monstro no interior jogável.

Capturas `artifacts/areas-exterior-house.png`, `areas-transition-black.png`, `areas-house-interior.png` e `areas-return-exterior.png` foram inspecionadas. Mostram entrada contextual, quadro preto da troca, quatro integrantes no interior e retorno ao exterior. O rodapé foi reposicionado após inspeção, e a execução gráfica foi repetida. As suítes também verificaram a mensagem de destino inválido no HUD. Logs finais das doze suítes e da execução gráfica não registraram erros ou avisos.

Comparação SHA-256 confirmou preservação integral de `scripts/combat/`, `scripts/ui/`, `data/lab.json`, ambas as cenas, `project.godot` e lançadores. A única adaptação em teste antigo foi a contagem de entidades externas: 16 com o novo portal. A suíte de acessibilidade existente cobre esse ponto adicional. Sem validação de outras plataformas, balanceamento, arte definitiva ou saves. Dados, arquivos e roteiro manual em [TRANSICOES_AREAS.md](TRANSICOES_AREAS.md).

## Ampliação da exploração — encontros e interações

Executada em **24/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro. Inspeção gráfica com renderização Compatibility.

| Suíte | Resultado |
| --- | --- |
| `tests/interaction_tests.gd` | 9 grupos, 3.473 verificações, zero falhas. |
| `tests/interaction_ui_smoke.gd` | 36 verificações, zero falhas. |
| Mesma suíte com renderização real | 40 verificações, incluindo quatro capturas, zero falhas. |
| Regressão `tests/exploration_tests.gd` | 9 grupos, 3.338 verificações, zero falhas. |
| Regressão `tests/exploration_ui_smoke.gd` | 30 verificações, zero falhas. |
| Regressão `tests/run_tests.gd` | 14 grupos, 104.292 verificações, zero falhas. |
| Regressão `tests/ui_smoke.gd` | 31 verificações, zero falhas. |
| Regressão `tests/motion_tests.gd` | 9 grupos, 1.944 verificações, zero falhas. |
| Regressão `tests/motion_ui_smoke.gd` | 16 verificações, zero falhas. |
| Regressão `tests/fullscreen_tests.gd` | 10 grupos, 620 verificações, zero falhas. |
| Regressão `tests/fullscreen_ui_smoke.gd` | 26 verificações, zero falhas. |

Cobertura nova: quantidades/IDs/referências de dados; rotas fora de sólidos; acesso do spawn a um ponto de interação selecionável para todas as 15 entidades; quatro integrantes em dois corredores estreitos; colisão com árvore/pedra/porta; patrulhas determinísticas e pausa por menu/diálogo/batalha; falas de todos os NPCs; dois ramos de resposta; bloqueio de movimento e interações durante diálogo; baú repetido sem itens; placa; alavanca e porta sincronizadas; fechamento recusado sobre seguidor; interação bloqueada através de sólidos; seis vitórias reais em presets A/B/C/D, cada uma removendo só o ID correto e preservando HP/MP, fila, rotas e objetos. Regressões anteriores continuam cobrindo fuga falha/bem-sucedida, reencontro, derrota e reinício.

As capturas `artifacts/exploration-expanded-map.png`, `exploration-expanded-choices.png`, `exploration-expanded-objects.png` e `exploration-expanded-corridor.png` foram inspecionadas. Nome, falas, botões, opções e regiões cabem na interface de teste. As posições de rótulos foram ajustadas após a primeira inspeção, e as suítes da exploração e capturas foram repetidas no estado final. Logs finais das dez suítes e da execução gráfica não registraram erros/avisos.

Comparação SHA-256 com o estado anterior confirmou que todos os arquivos de `scripts/combat/`, `scripts/ui/`, `data/lab.json` e `scenes/combat_lab.tscn` foram preservados integralmente. As alterações dos testes antigos apenas migram a consulta do encontro único para a coleção por ID. A busca de acesso é uma ferramenta do teste; não há navegação adicionada ao jogo. Não valida balanceamento, arte definitiva, salvamento ou outras plataformas. Arquitetura e roteiro manual em [EXPLORACAO_INTERACOES.md](EXPLORACAO_INTERACOES.md).

## Aprimoramento posterior — apresentação de tela inteira

Executado em **23/10/2026**, Godot 4.7.2 Standard no macOS. Inspeção gráfica com renderização Compatibility.

| Suíte | Resultado |
| --- | --- |
| `tests/fullscreen_tests.gd` | 10 grupos, 620 verificações, zero falhas. |
| `tests/fullscreen_ui_smoke.gd` | 26 verificações, zero falhas. |
| Mesma suíte com renderização real | 29 verificações, incluindo três capturas, zero falhas. |
| Regressão `tests/run_tests.gd` | 14 grupos, 104.292 verificações, zero falhas. |
| Regressão `tests/ui_smoke.gd` | 31 verificações, zero falhas. |
| Regressão `tests/exploration_tests.gd` | 9 grupos, 3.338 verificações, zero falhas. |
| Regressão `tests/exploration_ui_smoke.gd` | 30 verificações, zero falhas. |
| Regressão `tests/motion_tests.gd` | 9 grupos, 1.944 verificações, zero falhas. |
| Regressão `tests/motion_ui_smoke.gd` | 16 verificações, zero falhas. |

Cobertura nova: padrões de aliados/móveis/estáticos; exceção individual estática; uso pelo agendador normal dos inimigos; deslocamento ao centro e execução imóvel; efeito único, custos e ATB; preservação de posições/rotas terrestres e voadoras; retorno e retomada exatos; substituição temporária e remoção da condição; mudanças durante a ação valendo na próxima execução; persistência entre encontros; geometria de alvos independente da apresentação; regressão melee; pausas, reinício, resultados e passos grandes.

As capturas `artifacts/fullscreen-stationary-ally.png`, `fullscreen-center-ally.png` e `fullscreen-static-exception.png`, com suas variantes `-debug.png`, foram inspecionadas. A interface mostra a origem lógica, o centro e a configuração efetiva. Logs das suítes não registraram erros ou avisos de script.

Comparação com o estado anterior confirmou a preservação integral dos presets A/B/C, parâmetros anteriores, perfis e tipos de inimigo. `route_motion.gd`, `attack_motion.gd` e `target_policy.gd` não foram alterados. O preset D e os tempos/efeitos visuais continuam experimentais. Nenhuma condição narrativa, chefe definitivo ou animação artística foi criada. Configuração e roteiro manual em [TELA_INTEIRA.md](TELA_INTEIRA.md).

## Aprimoramento posterior — rotas suaves e melee

Executado em **23/10/2026**, Godot 4.7.2 Standard no macOS, com renderização Compatibility para inspeção gráfica.

| Suíte | Resultado |
| --- | --- |
| `tests/motion_tests.gd` | 9 grupos, 1.944 verificações, zero falhas. |
| `tests/motion_ui_smoke.gd` | 16 verificações, zero falhas. |
| Mesma suíte com renderização real | 18 verificações, incluindo duas capturas, zero falhas. |
| Regressão `tests/run_tests.gd` | 14 grupos, 104.285 verificações, zero falhas. |
| Regressão `tests/ui_smoke.gd` | 31 verificações, zero falhas. |
| Regressão `tests/exploration_tests.gd` | 9 grupos, 3.338 verificações, zero falhas. |
| Regressão `tests/exploration_ui_smoke.gd` | 30 verificações, zero falhas. |

Cobertura nova: preservação integral dos presets A/B por fixture; geração determinística; continuidade de tangentes/fechamento; voo circular; velocidade por distância; curvas degeneradas; aproximação, chegada, efeito único e retorno; alvo móvel; pausa Wait/Active/manual; velocidade e passo; interrupção exata de terrestre/voador/estático em ataques únicos/múltiplos; retomada a partir do snapshot; reinício durante aproximação; alvo incapacitado e passos grandes.

`artifacts/motion-routes.png` e `artifacts/motion-melee-impact.png` foram inspecionadas: mostram curvas na região inimiga e o aliado junto ao alvo voador no impacto, com sua âncora lógica original preservada. Logs das seis suítes e da execução gráfica não registraram erros/avisos. A política de alvos, fichas, perfis, presets A/B e parâmetros anteriores de combate foram comparados com o estado anterior e preservados. O novo C e os parâmetros visuais são experimentais, sem aprovação de balanceamento ou arte definitiva.

## Validação anterior — versão jogável 0.2, exploração integrada

Executada em **23/10/2026**, Godot 4.7.2 Standard, macOS/Apple M3 Pro.

| Suíte | Resultado final |
| --- | --- |
| `tests/run_tests.gd` | 14 grupos do combate, 104.278 verificações, zero falhas. |
| `tests/ui_smoke.gd` | 31 verificações da UI independente do laboratório, zero falhas. |
| `tests/exploration_tests.gd` | 9 grupos novos, 3.338 verificações, zero falhas. |
| `tests/exploration_ui_smoke.gd` | 30 verificações de entrada/menu/transição/recursos, zero falhas. |
| Integração com renderização real | 33 verificações, incluindo três capturas gráficas, zero falhas. |

As regressões do laboratório foram executadas antes e depois das alterações. O núcleo `scripts/combat/battle_model.gd`, `data/lab.json` e `scenes/combat_lab.tscn` conservam os mesmos hashes SHA-256 da análise inicial.

Os testes novos cobrem: ausência de diagonais; movimento contínuo; colisão varrida e limites; três seguidores nas curvas e reversões sem colisão entre integrantes; compressão/descarte de histórico; menu pausando movimento; mudança de líder sem mudar slots/caminho; guardas de interação e preset; compartilhamento da instância de combate; ausência de recuperação automática; vitória/fuga com retorno ao mesmo mapa; inventário/incapacitação/liderança preservados; fuga falha; reencontro explícito e determinístico; Game Over e reinício explícito. Teclas foram injetadas no sistema de entrada da engine com processamento dos eventos acumulados.

Capturas `artifacts/exploration-v02.png`, `exploration-menu.png`, `exploration-combat.png` e `exploration-victory-return.png` foram inspecionadas. A execução gráfica confirmou menu, quatro sprites, tela de combate reutilizada e retorno com HP/MP gastos. Logs finais dessas execuções não registraram erros ou avisos de script. Os testes não validam balanceamento, plataformas diferentes, salvamento da aventura ou direção artística.

## Validação anterior — laboratório isolado

Executada em **23/10/2026**, macOS/Apple M3 Pro, **Godot 4.7.2 Standard** oficial. Não representa validação de outras plataformas ou balanceamento.

## Simulação

`godot --headless --path . --script res://tests/run_tests.gd`

Resultado: **14 grupos aprovados, zero falhas**. Cobertura: formação determinística, INI/ATB/saturação, escolha manual, Wait/Active, loops e segmentos nulos, retorno exato de animações únicas e múltiplas, custos e validação de habilidades, área avaliada no impacto, itens/recuperação/ressurreição, fuga bem-sucedida/falha/bloqueada, incapacitação, vitória/derrota, persistência, perfis/pesos/fallback, exclusão de mortos, RNG reproduzível e batalhas completas nos dois presets e modos.

## Interface

`godot --headless --path . --script res://tests/ui_smoke.gd`

Resultado: **31 verificações aprovadas, zero falhas**. A cena foi instanciada e os sinais usados pelos botões foram acionados, além de clique no campo e atalhos. Foram verificados seleção entre aliados, comandos, habilidades, item em cartão aliado, modo, velocidade, depuração, troca de preset, bloqueio de fuga, cancelamento e passo.

## Execução gráfica

O lançador macOS foi executado com renderização OpenGL Compatibility. A cena abriu, capturas da interface e da depuração foram inspecionadas. Não houve erros de script nos logs destas execuções. Arquivos de inspeção em `artifacts/`; nenhum é necessário para executar o jogo.

## Limites

Os testes de UI são automatizados; o roteiro manual para experimentar ritmo e legibilidade está em `LABORATORIO.md`. Fórmulas, custos, fichas, pesos e timings são experimentais. Saves da aventura e exportação comercial não fazem parte da entrega.
