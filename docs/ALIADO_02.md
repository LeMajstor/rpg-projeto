# Segundo aliado — preset inicial do laboratório

**Data:** 27/10/2026. **Status:** autorizado e implementado no laboratório em D84, após adoção da proposta P06 pelo usuário para testes. Preset pessoal **Aliado #2** salvo na biblioteca local, com arco composto/couro reais do catálogo. Números são referência experimental de nível 1, sem fechar balanceamento ou progressão definitivos.

## Direção confirmada

Segundo aliado com arco composto e conjunto de couro. Priorizar críticos, maior INI e esquiva, com menor proteção física e resistência ao ser atingido em comparação com o Aliado #1. D82 refina a direção e D83 atualiza o multiplicador: CRI/EVA próprios levemente maiores, HP menor, MP levemente maior; arco com chance de crítico maior e multiplicador **1,6×**. Valores próprios e percentual da arma foram adotados para este preset de teste em D84. Nenhuma classe, raça, identidade, técnica, munição ou regra de alcance foi definida. INI não cresce naturalmente com nível; D95 permite crescimento muito lento da EVA e aumentos permanentes de+1 por itens raros. Intervalo e progressão dos demais atributos ainda serão desenhados.

## Atributos próprios do preset — nível 1

| Atributo | Aliado #1 salvo | Aliado #2 salvo |
| --- | ---: | ---: |
| HP | 40 | 36 |
| MP | 12 | 14 |
| INI | 9 | 11 |
| ATQ F próprio | 23 (D88) | 20 |
| DEF F própria | 45 | 30 |
| MAG | 20 | 20 |
| DEF M | 21 | 21 |
| CRI base | 5 | 7 |
| EVA base | 5 | 7 |

A proposta revisada diferencia também os atributos próprios: CRI/EVA em 7 contra 5 do primeiro aliado, HP 36 contra 40 e MP 14 contra 12. MAG/DEF M permanecem iguais por enquanto, sem inventar técnicas ou especialização mágica. A DEF F própria menor também compõe a identidade do personagem; não é uma penalidade automática de usar arco/couro em qualquer aliado.

## Equipamentos do preset

- **Arco Composto de Madeira** (ID original `compound_bow`): +10 ATQ F; +12 pontos percentuais de chance de crítico; multiplicador crítico **1,6×** (direção expressa do usuário).
- **Traje de Couro** (ID original `leather_set`): +5 DEF F e +5 pontos percentuais de esquiva, equivalentes a +5 EVA na conversão experimental atual.

Bônus e valores próprios adotados para teste em D84; multiplicador do arco em 1,6× definido em D83. Composição resultante: **ATQ F 30, DEF F 35, INI 11, crítico total 19% (7 + 12), EVA efetiva 12% (7 + 5)**. Comparação atual com Aliado #1 de Bronze após D88: ATQ F 33, DEF F 55, INI 9, crítico total 10%, EVA 5%.

**Implementação D84:** composição de EVA própria + `armor.evasion_bonus`, limitada experimentalmente a 100%, com soma bruta preservada. Editor mantém EVA própria 7 e mostra a composição 7 + 5 = 12%; o campo EVA + da armadura é editável para testes e permanece editável com o couro obrigatório (D86). Editar esse bônus não muda a base. Preset, histórico e JSON guardam próprios, bônus e totais separadamente; inversão de lados mantém o equipamento no aliado. Armas e armaduras antigas sem `evasion_bonus` continuam válidas com zero em memória.

Catálogo em `data/damage_lab.json`, definição de instalação em `data/damage_lab_ally_02.json`. A definição não é importada automaticamente ao iniciar: o preset foi adicionado uma vez à biblioteca pessoal, e pode ser atualizado/excluído normalmente. Aliado #1 e Monstro #1 foram preservados. Sem progressão de nível, alteração do combate integrado ou animação nova de arco; a ação física genérica do laboratório permanece.

## Exclusividade e equipamento obrigatório — D85/D86

Arco composto e conjunto de couro são **exclusivos do Aliado #2**, conforme decisão de 27/10/2026. Para o primeiro aliado, não aparecem nos seletores e são recusados pelo modelo, pela biblioteca de presets e pela calculadora. A restrição usa identidade estável de personagem (`character_id`), separada de `actor.id` (modelo da ficha), nome e ID de preset. Renomear uma ficha do primeiro aliado não concede acesso; salvar uma cópia do segundo mantém sua identidade e permissões. Atualizar um preset não pode trocar seu personagem de origem.

Os três presets locais foram migrados e reabertos, preservando atributos, bônus, IDs e revisões. D86 posteriormente confirma a restrição inversa: espadas e armaduras de metal são exclusivas do Aliado #1 e não aparecem para #2. Ao trocar os lados, os itens continuam associados ao personagem correto.

## Comparação calculada

Referência: Monstro #1 salvo, HP 45, ATQ F 24, DEF F 40, CRI 3%, EVA 3%; ataque básico 1×, variação ±10%, crítico do primeiro aliado/monstro 2× e do arco proposto 1,6×. Fórmula atual `potência × ATQ F² / (ATQ F + DEF F do alvo)`.

| Resultado | Aliado #1 | Aliado #2 salvo |
| --- | --- | --- |
| Dano normal causado | 13–16 (D88) | 12–14 |
| Dano crítico causado | 27–33 (D88) | 19–23 |
| Dano normal recebido | 7–8 | 9–11 |
| Acertos normais para derrotar monstro de 45 HP | 3–4 (D88) | 4 |
| Acertos normais para cair (HP 40 / HP 36) | 5–6 | 4 |
| Chance de crítico ao atacar | 10% | 19% |
| Chance de esquiva ao receber ação elegível | 5% | 12% |

Menor resistência é a contrapartida proposta à INI, esquiva e crítico maiores; não altera a meta de resistência do Aliado #1. Críticos mais frequentes com menor pico: 1,6× no arco contra 2× da espada de Bronze do estudo. Com 36 HP e 9–11 de dano normal recebido, três golpes não derrubam (máximo 33), mas quatro sempre derrubam (mínimo 36). Essa fragilidade precisa ser avaliada antes de fechar os números.

Estimativas teóricas, usando chances configuradas e distribuição uniforme com arredondamento, tentativas independentes e HP acumulado, sem cura/ATB: após D88, média de **3,31 tentativas** do Aliado #1 e **3,69 do Aliado #2** para derrotar o monstro de 45 HP; resistência média de **6,16 tentativas recebidas** no Aliado #1 e **4,45 no Aliado #2**. A INI não entra nessas estimativas. No modelo temporal provisório, 11/9 representa cerca de 22% a mais na taxa de carregamento da barra; não equivale automaticamente a 22% mais ações por causa de animações, esperas e resolução compartilhada.

Como comparação isolada antes do arredondamento e sem esquiva/INI: a proposta anterior de 15%/2× tinha fator médio 1,15, e a atual de 19%/1,6× tem 1,114. O multiplicador menor reduz a contribuição média dos críticos em relação à proposta anterior, mantendo sua maior frequência. D83 substitui o multiplicador 1,8× de D82 por 1,6×.

As estimativas de tentativas acima foram calculadas em Python, sem simular ATB. A ficha, os extremos de dano e o fluxo da interface foram testados em Godot em D84; validar sensações e ritmo temporal antes de considerar o balanceamento fechado. Técnicas específicas, MAG/DEF M diferenciadas, crescimento por nível e progressão de arco/couro continuam pendentes.

**D86 — obrigatório:** todo aliado mantém arma e armadura equipadas. Não há opções Sem arma/Sem armadura. Após D92, o Aliado #2 dispõe de seis arcos de madeira e seis trajes leves; o primeiro usa as seis espadas/armaduras de metal existentes. Modelo, presets e calculadora recusam slots ausentes, desligados ou incompatíveis. Presets legados com `id: none` recebem os padrões compatíveis do personagem em memória ao carregar, sem regravação automática. Caso manual/restauração inicia o primeiro aliado com espada e armadura de Bronze. Esta correção não muda números das três fichas salvas.

## Reavaliação da diferença ofensiva — D87/P07

Últimos relatórios (execuções005/seed112 e004/seed111): médias13,785 para #1 e13,794 para #2. Ambos usam ATQ30. **Direção esclarecida:** o primeiro deve causar aproximadamente15% mais dano médio por ataque que o segundo. Substitui a discussão anterior de diminuir o primeiro.

**D88 — autorizado e aplicado:** aumentar ATQ próprio #1 de20 para23, mantendo espada+10, total33; #2 continua total30. Média teórica por tentativa contra Monstro #1 (DEF40/EVA3%) é15,919 contra13,920, vantagem14,36%. Normal #1 de13–16 e crítico27–33; segundo continua12–14/19–23. Monstros HP35–45 continuam caindo em3–4 acertos normais. Máximo16 excede levemente a referência aproximada9–15 anterior, conforme a proposta adotada. INI e dano por tempo são uma avaliação separada. Detalhes em [análise dos lotes](../artifacts/balanceamento-aliados-2026-10-27/analise.md). Preset pessoal #1 atualizado para revisão2; #2 e Monstro #1 preservados.

**Verificação D88:** biblioteca pessoal reaberta após a atualização; comparação integral confirmou somente ATQ próprio20→23 e revisão1→2 no primeiro aliado. Extremos13–16/27–33 para #1 e12–14/19–23 para #2 confirmados pela calculadora Godot. Lotes de1000 ações com cada preset recarregado concluídos sem erro.

## Escalas disponíveis — D92, 28/10/2026

Implementadas as seis opções de arcos ATQ+10/15/22/31/44/58 e de trajes DEF+5/8/12/17/24/33. Todos os arcos mantêm CRI da arma+12p.p./1,6×; todos os trajes mantêm EVA+5, sem acúmulo dos anteriores. Exclusivos do segundo aliado, com dois slots obrigatórios. A ficha pessoal inicial conserva bônus e IDs; o primeiro arco/couro passa a ser exibido com os nomes atuais ao carregar. Nenhum preset foi trocado automaticamente para estágio superior. Tabela completa e instruções em [ESCALA_ARCOS_E_TRAJES.md](ESCALA_ARCOS_E_TRAJES.md).

## Separação de contato e distância — D94

No laboratório, a ficha do segundo mantém ATQ F próprio20 e recebe ATQ D próprio20; o arco soma seu bônus somente a ATQ D, mantendo30 efetivos inicialmente. DEF D própria30 escolhida pelo usuário; traje inicial soma10, totalizando40, enquanto DEF F permanece30+5=35. EVA continua7+5=12%. Primeiro aliado usa ATQ F23+10=33, ATQ D10, DEF F45+10=55 e DEF D45+5=50. A defesa de distância do Monstro #1 começa40 por compatibilidade, preservando o dano do arco. Leitura dos presets existentes acrescenta campos ausentes sem alterar arquivo ou revisão; Salvar/Atualizar passam a persistir todos os atributos. Tabela e política completas em [ATQ_DISTANCIA.md](ATQ_DISTANCIA.md).
