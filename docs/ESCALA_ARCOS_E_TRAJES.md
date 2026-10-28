# Escala de arcos e trajes leves — laboratório de danos

**Data:** 27/10/2026. **Revisão:** 28/10/2026 (D90, arcos de madeira; P08B, curva própria calculada). **Status:** autorizado e implementado por **D92, 28/10/2026**, somente no laboratório de danos. Nomes e números adotados para teste, sem fixar balanceamento definitivo.

## Confirmado

- Manter o balanceamento inicial atual: Aliado #1 com ATQ próprio23 + espada10 =33; Aliado #2 com ATQ próprio20 + arco10 =30. Diferença média teórica14,36% contra o Monstro #1, aceita após o estudo dos últimos JSONs.
- O usuário quer uma escala de equipamentos de arcos paralela às espadas e uma escala do equipamento leve paralela às armaduras de metal.
- **D90, 28/10/2026:** os arcos devem ser de madeira. Os nomes da progressão não devem tratar Mithril/Adamantio como materiais dos arcos. Espadas e armaduras de metal não mudam.
- **D91, 28/10/2026:** curva dos arcos+10/15/22/31/44/58 aceita provisoriamente, com crítico+12p.p./1,6× e nomes de madeira da proposta. Não é implementação nem balanceamento definitivo.
- O desenho foi feito antes da implementação (D89); D92 posteriormente autorizou adicionar as escalas ao laboratório.
- O nome da família leve pode mudar; não é obrigatório usar “armadura de couro”.
- Permanecem as exclusividades e a obrigação de arma + proteção equipadas. O catálogo atual contém seis espadas, seis armaduras de metal, seis arcos de madeira e seis trajes leves.

## Organização adotada para o laboratório

**Arcos** e **Trajes leves** têm seis estágios, correspondentes aos seis estágios de espadas/armaduras atuais. Correspondência significa posição na escala de teste; a correspondência não obriga os arcos a usar os materiais das espadas nem define classe, raça ou progressão narrativa. Arcos de madeira seguem D90.

O primeiro estágio preserva os bônus do Arco composto (+10) e Conjunto de couro (+5 DEF F/+5 EVA), agora exibidos como **Arco Composto de Madeira** e **Traje de Couro**. IDs `compound_bow` e `leather_set` e defaults permanecem. Nomes são atualizados em memória ao carregar por ID do catálogo; bônus editados, atributos, revisões e biblioteca pessoal não são regravados na leitura.

## P08B/D92 — escala adotada

Todos os valores abaixo são **bônus de equipamento**, separados dos atributos próprios. Esta escala busca manter o primeiro aliado aproximadamente15% acima também nos pares de estágios, usando as fichas e o alvo atuais. D91 adotou essa curva como referência provisória e D92 a implementou para testes. Não é garantia universal da porcentagem nem regra definitiva da progressão por nível.

| Estágio | Referência espada/metal | Bônus espada/metal em ATQ/DEF | Arco | ATQ F + | Traje leve | DEF F + |
| --- | --- | ---: | --- | ---: | --- | ---: |
| 1 | Bronze | 10 | Arco Composto de Madeira | 10 | Traje de Couro | 5 |
| 2 | Ferro | 16 | Arco de Carvalho | 15 | Traje Reforçado | 8 |
| 3 | Aço | 24 | Arco de Freixo | 22 | Traje de Caça | 12 |
| 4 | Mithril | 34 | Arco de Teixo | 31 | Traje do Batedor | 17 |
| 5 | Adamantio | 48 | Arco de Madeira Ancestral | 44 | Traje do Patrulheiro | 24 |
| 6 | Rúnica | 65 | Arco de Madeira Rúnica | 58 | Traje Rúnico | 33 |

Os nomes dos seis arcos são propostas revisadas em28/10/2026. Madeira Ancestral/Rúnica são nomes de equipamento sugeridos; não criam efeitos especiais. A preferência por madeira está confirmada, a sequência foi aceita provisoriamente em D91 e implementada em D92.

**Por que essa curva:** os arcos mantêm os mesmos seis estágios, com bônus próprios para aproximar a diferença de dano pretendida; os trajes usam aproximadamente metade do bônus de proteção do metal, arredondado, preservando o ponto inicial +5. Isso cria seis opções comparáveis sem igualar a proteção das famílias. A relação pela metade é uma recomendação para teste, não uma regra definitiva nem redução pela metade do dano recebido.

**Atributos secundários adotados para teste (D92):** todos os arcos começam com **+12 pontos percentuais de CRI e multiplicador1,6×**, preservando o arco atual; todos os trajes começam com **+5 EVA**, preservando o couro atual. Assim, primeiro estudamos a curva de ataque/defesa. Aumentar CRI, multiplicador, EVA ou acrescentar INI em cada estágio não está aprovado. A EVA total do segundo continuaria12% com sua base7, enquanto a proteção física aumentaria. As espadas/armaduras atuais permanecem como estão.

## Resultado calculado da P08B

Curva de ATQ do arco proposta: **+10 → +15 → +22 → +31 → +44 → +58**. O bônus cresce sem alterar o atributo próprio do personagem. Com próprio20, os totais seriam30/35/42/51/64/78. Trocar equipamento não significa subir de nível.

| Estágio | Bônus espada | Bônus arco proposto | Vantagem média #1 contra DEF40/EVA3% |
| --- | ---: | ---: | ---: |
| 1 | 10 | 10 | 14,36% |
| 2 | 16 | 15 | 16,35% |
| 3 | 24 | 22 | 16,55% |
| 4 | 34 | 31 | 15,75% |
| 5 | 48 | 44 | 13,85% |
| 6 | 65 | 58 | 15,86% |

**Método:** para cada espada, calcular a média por tentativa e dividir por1,15; escolher o bônus inteiro do arco cuja média fica mais próxima desse alvo, considerando a fórmula atual, arredondamento, variação, chances e multiplicadores. Isso mantém aproximadamente15%, sem impor porcentagem de dano diretamente nem mudar a fórmula. A tabela anterior com bônus idênticos continua abaixo como alternativa P08A.

**Limites:** fichas próprias mantidas em23/20, DEF do alvo40, EVA3%, variação±10%, crítico10%/19% e multiplicadores2×/1,6×. Mudar defesa do alvo ou futuramente aumentar atributos por nível altera a diferença; esta curva não garante15% em toda situação. O primeiro estágio preserva o preset atual e a referência3–4 contra monstros iniciais. Os estágios superiores precisam de futuros alvos/HP de referência; não devem continuar presos ao dano inicial9–15.

Cálculo reproduzível em `artifacts/escala-arcos-2026-10-28/calcular.py`, executado sem falhas nas verificações de distribuição e pontos iniciais. Resultado em `resultados.json`. É cálculo de médias, sem execução de batalhas com ATB. O catálogo foi implementado posteriormente por D92 e validado na calculadora e UI Godot.

## Histórico — alternativa P08A e vantagem de aproximadamente15%

A vantagem de D87/D88 foi calibrada para as fichas/equipamentos iniciais contra o Monstro #1. Somar o mesmo bônus de ataque aos dois personagens **não preserva a diferença percentual** em todos os estágios: a distância de três pontos dos atributos próprios fica proporcionalmente menor.

Cálculo isolado, mantendo próprios23/20, chances10%/19%, multiplicadores2×/1,6×, alvo DEF40/EVA3%, variação±10% e arredondamento atual:

| Bônus da arma de ambos | Média #1 | Média #2 | Vantagem média #1 |
| ---: | ---: | ---: | ---: |
| 10 | 15,919 | 13,920 | 14,36% |
| 16 | 20,552 | 18,437 | 11,47% |
| 24 | 27,094 | 24,898 | 8,82% |
| 34 | 35,739 | 33,520 | 6,62% |
| 48 | 48,458 | 46,274 | 4,72% |
| 65 | 64,554 | 62,451 | 3,37% |

Essas médias são por tentativa com crítico/esquiva e não medem ATB. Não representam o dano contra futuros inimigos, cujas defesas e HP não foram definidos. Testar equipamento superior contra o mesmo monstro inicial naturalmente reduz a quantidade de acertos; a meta3–4 pertence ao cenário inicial, sem congelar todos os equipamentos nesse dano.

**Alternativas comparadas — D91 adotou provisoriamente P08B:**

1. **P08A — bônus iguais aos das espadas:** manter a proposta anterior +10/16/24/34/48/65; manter aproximadamente15% apenas como referência inicial. Reavaliar a diferença junto da futura progressão dos atributos e inimigos.
2. **P08B — curva própria, recomendação atual:** usar como primeiro teste +10/15/22/31/44/58 para os arcos, preservando os seis estágios e aproximando a vantagem de15% nos pares contra o alvo atual. Validar junto dos futuros atributos/inimigos; uma porcentagem exata contra toda defesa não é garantida pela fórmula atual.

D92 adotou os nomes e bônus de ambas as famílias para testes. Inventário, obtenção, preço, níveis exigidos, novas habilidades, munição, slots extras e progressão por nível ficam fora deste desenho.

## Proteção leve — adotada por D92, 28/10/2026

**Curva implementada:** bônus de DEF F **+5 → +8 → +12 → +17 → +24 → +33**. É aproximadamente metade dos bônus10/16/24/34/48/65 das armaduras de metal, com arredondamento. Assim, todos os estágios melhoram a proteção sem igualar o bônus do metal.

Todos os seis trajes têm **+5 EVA** neste primeiro teste. Com EVA própria7, o segundo aliado continuaria com12% efetivos; somente a proteção física cresce ao trocar o traje. Não somar a EVA dos itens anteriores: apenas o traje equipado contribui. Nenhum bônus de INI, HP ou defesa mágica novo está proposto.

| Traje | DEF F + | EVA + | DEF total com própria30 |
| --- | ---: | ---: | ---: |
| Traje de Couro | 5 | 5 | 35 |
| Traje Reforçado | 8 | 5 | 38 |
| Traje de Caça | 12 | 5 | 42 |
| Traje do Batedor | 17 | 5 | 47 |
| Traje do Patrulheiro | 24 | 5 | 54 |
| Traje Rúnico | 33 | 5 | 63 |

Metade do bônus de DEF não significa metade da defesa total, o dobro do dano recebido nem15% de diferença defensiva. A proteção efetiva também depende da DEF própria e da fórmula. A referência15% de D87 diz respeito ao dano causado, não à defesa.

Cálculo isolado contra ATQ24/potência1/variação±10% do Monstro #1: normal recebido9–11/8–10/8–10/7–9/7–8/6–7, conforme os seis trajes. Esses valores só ilustram o efeito mantendo o mesmo inimigo e DEF própria30; não definem inimigos futuros ou resistência definitiva em todos os estágios. Dados conferidos em `artifacts/escala-arcos-2026-10-28/trajes-propostos.json`; nenhuma batalha temporal executada nesta etapa.

A recomendação é primeiro crescer DEF mantendo EVA estável, para estudar uma curva por vez e preservar os12% de esquiva já testados. Nomes, curva e EVA dos trajes foram adotados para teste e implementados em D92.

## Implementação e compatibilidade — D92

Dados em `data/damage_lab.json`; a receita inicial `data/damage_lab_ally_02.json` mantém os mesmos números/IDs e nomes atualizados. Novos IDs: `bow_oak`, `bow_ash`, `bow_yew`, `bow_ancient`, `bow_runic`; `leather_reinforced`, `leather_hunting`, `leather_scout`, `leather_ranger`, `leather_runic`. Todos têm permissão somente para `ally_2`, validada pelo catálogo canônico, modelo, presets e calculadora. Os seletores apresentam seis opções por slot em ordem de estágio, selecionadas por ID. Não há opção sem equipamento.

`damage_equipment.gd` fornece o nome atual do catálogo por categoria/ID; `damage_presets.gd` usa esse nome em cópia durante a carga. Isso permite que as fichas antigas exibam os nomes atuais e preservem quaisquer bônus personalizados. Nenhuma leitura regrava o arquivo; históricos e exportações anteriores permanecem imutáveis. Não há autoimportação de presets novos ou alteração da ficha pessoal inicial para equipamento superior.

Testes específicos: `tests/damage_equipment_scales_tests.gd` e `tests/damage_equipment_scales_ui_smoke.gd`. Cobrem os seis estágios,36 combinações, exclusividade, composição, crítico/EVA constantes, salvar/reabrir, nomes anteriores, bônus editados, teclado, inversão de lados e JSON. Suítes e resultado gráfico em `VALIDACAO.md`.

Para conferir manualmente: reabrir o laboratório, carregar **Aliado #2** e selecionar os seis arcos/trajes. Primeiro par mantém ATQ30/DEF35/EVA12; último par mostra ATQ78/DEF63/EVA12, com próprios20/30/7. Salvar uma cópia permite comparar sem substituir a ficha inicial. O primeiro aliado continua vendo apenas seis espadas/seis armaduras de metal.

## Extensão de DEF D — D93/D94 implementada

O usuário definiu que ambas as famílias de proteção devem contribuir para DEF F e DEF D, com metal priorizando DEF F e couro priorizando DEF D. D94 implementa a extensão numérica descrita em [ATQ_DISTANCIA.md](ATQ_DISTANCIA.md) mantém as DEF F existentes e acrescenta DEF D+5/8/12/17/24/33 ao metal e+10/16/24/34/48/65 aos trajes. Bônus espelhados adotados para teste, com DEF D própria45/30 escolhida pelo usuário e compatibilidade de presets por leitura. Arcos agora somam ATQ D; as curvas de ataque permanecem iguais. Novas exportações JSONv4 identificam os atributos utilizados.
