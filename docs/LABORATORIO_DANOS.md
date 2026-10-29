# Laboratório de danos

**Status em 26/10/2026 (D60): implementado para experimentar e ajustar durante os testes**, conforme autorização do usuário. Cena independente `scenes/damage_lab.tscn`, aberta por `Executar laboratorio de danos.command`. O combate da exploração e o laboratório de combate continuam com seus cálculos anteriores. Fórmula, fichas e números abaixo são **experimentais**, sem confirmação de balanceamento definitivo.

## Confirmado

- Atributos D54 e siglas D57: HP, MP, INI, ATQ F, DEF F, MAG, DEF M e CRI; EVA D74/D75 com direção de crescimento revisada em D95. ATQ D/DEF D implementados por D94; INT/VIG por D100/D110, em1..999 para ambos os lados. Crescimento por nível de INT/VIG é desenho futuro, sem progressão automática no laboratório.
- Escalas vigentes (D59/D69/D76): **HP, MP, ATQ F, DEF F, MAG e DEF M: aliados 0..999**; **HP dos monstros 1..99999**; **MP, ATQ F, DEF F, MAG e DEF M dos monstros 1..9999**. **INI e CRI: 1..99 para ambos**. Ampliação dos monstros confirmada em 27/10/2026 para permitir grandezas maiores, inclusive chefes; não define valores por inimigo.
- Dano mínimo de 1 para um ataque que atinge alvo válido (D55).
- **D64:** armas somam bônus ao ATQ F próprio, armaduras à DEF F própria. D66 implementa campos próprios do aliado, bônus de arma/armadura e totais efetivos separados; monstros mantêm atributos diretos. Potência pertence à ação. Valores de itens e limites efetivos ainda a definir; ver seção 7.5 do `GDD.md`.
- Arma define chance e multiplicador de crítico; CRI do personagem influencia somente a chance, modificável por itens ou buffs mágicos (D56). **D63 confirmado:** 1 ponto de CRI = 1% de chance-base, somado à chance da arma e aos bônus de itens/buffs em pontos percentuais. Valores por arma/modificador e limites finais continuam pendentes.
- **D58, 26/10/2026:** oferecer ações em lotes de **10×, 100× e 1000×**, exibindo os resultados para comparação.
- Guia de Chrono Trigger guardado somente como referência, em [REFERENCIAS.md](REFERENCIAS.md).

**D76 — HP dos inimigos (27/10/2026):** ampliado para **1..99999**. O campo aceita cinco dígitos como atacante e alvo, preservados em presets, histórico e JSON. O limite inicial mínimo continua 1; HP após dano pode chegar a zero. Permite estudar chefes acima de 10 mil HP, sem criar um chefe nem alterar fichas/presets iniciais. Demais faixas permanecem iguais.

## Esquiva — D74/D75

**Autorizada e implementada em 27/10/2026 somente neste laboratório.** As fichas de aliado e monstro têm **EVA**, a chance-base própria de esquiva. Nenhum crescimento por nível é aplicado. D84 posteriormente acrescenta o bônus de EVA de armadura para o couro; itens/buffs de EVA continuam **para depois**; os campos Item CRI/Buff CRI anteriores modificam somente o crítico.

**Escolhas experimentais para testar, sem fixar o jogo definitivo:** EVA inteira de **0 a 100**, com **1 EVA = 1%**; fichas e referências começam em zero para preservar as comparações anteriores. A opção **Esta ação permite esquiva** controla a elegibilidade: inicialmente ligada no ataque básico/técnica física e desligada na magia, podendo ser alterada para comparação.

Quando a ação permite, sortear a EVA **do alvo** antes de aplicar crítico e dano. Se esquivar, o dano e HP removido são **zero**, não ocorre crítico (inclusive no modo forçado) e o mínimo 1 não se aplica. A ação e seu custo de MP são consumidos normalmente. Se acertar, a fórmula anterior permanece com mínimo 1. O duelo mostra **Esquivou!**, sem alterar a posição lógica ou criar uma nova animação de deslocamento.

Resumo e Amostras distinguem **Esquiva / Normal / Crítico**. A média por ação inclui as esquivas com zero; médias normal/crítica incluem somente golpes que acertaram. O resumo mostra frequência de críticos entre os acertos, permitindo comparar com a chance configurada; o JSON também conserva a frequência por tentativa. Sem acertos, essas médias/frequências são zero, sem divisão por zero. O histograma representa esquivas em azul, normais em verde e críticos em amarelo.

EVA é salva/carregada/atualizada nos presets e acompanha o participante ao inverter os lados. Presets pessoais antigos sem `evasion_base` recebem zero em memória; a leitura não regrava o arquivo. Histórico e **JSON v3** guardam EVA, permissão da ação, chance, sorteio, resultado, contagens e estado exato do novo RNG independente. Exportações v1/v2 já existentes não são modificadas.

Para verificar: EVA do alvo em **0** → nenhum golpe evitado; **100** → todos evitados em ação elegível; **25** e lote 1000× → mistura reproduzível de esquivas/acertos. Troque para magia para conferir que ignora a EVA até ligar sua permissão. Inverta os lados para testar a EVA do aliado; técnica física esquivada preserva HP mas ainda gasta MP. Esses números são casos de teste, não fichas definitivas.

## Equipamentos dos aliados — D64/D65/D66

**Autorizado e implementado:** arma/armadura somente no aliado. Monstros continuam com atributos diretos, sem slots. Inimigos humanos/humanoides equipados permanecem fora do recorte. As progressões são presets experimentais para comparação. **D67:** Madeira removida de armas e armaduras; bônus restantes deslocados uma posição para baixo, mantendo Bronze como primeiro material, com +10. As chances/multiplicadores críticos permanecem configuráveis como antes.

Na ficha do aliado, **ATQ F** e **DEF F** são os atributos próprios editáveis. Abaixo deles, a composição mostra `próprio + bônus = total`. O total entra na fórmula; a potência continua da ação. No monstro, ATQ F/DEF F são valores diretos. MAG, DEF M, HP/MP, INI e CRI não recebem bônus desses equipamentos.

A seção **Arma do aliado** identifica seu dono e se ele é atacante ou alvo. Permite escolher arma e editar bônus de ATQ F, chance e multiplicador de crítico. **Armadura do aliado** permite escolher armadura e editar bônus de DEF F e, após D84, de EVA. D86 exige arma e armadura equipadas; não há opções Sem arma/Sem armadura. Digitação, setas e controle continuam disponíveis nos campos editáveis; o painel rola por foco.

| Material de teste | Bônus da espada em ATQ F | Bônus da armadura em DEF F |
| --- | ---: | ---: |
| Bronze | 10 | 10 |
| Ferro | 16 | 16 |
| Aço | 24 | 24 |
| Mithril | 34 | 34 |
| Adamantio | 48 | 48 |
| Rúnica | 65 | 65 |

Os seis presets de espada começam com chance **5%** e multiplicador **2×**, editáveis. Esses valores mantêm a referência de crítico existente e **não aprovam uma progressão de crítico por material nem um multiplicador global**. Por solicitação do usuário, as opções antigas Arma de teste · 2× e Arma de teste · 3× foram removidas: o multiplicador já é editável no campo próprio. Após D86, o caso padrão seleciona Espada de Bronze (+10 ATQ F) e Armadura de Bronze (+10 DEF F); atributos próprios permanecem iguais. Catálogo independente em `data/damage_lab.json`.

Cada aliado guarda seu equipamento local na sessão. Ao trocar lados, arma e armadura acompanham o aliado: arma contribui ao atacar, armadura ao receber dano. Selecionar outra ficha recarrega seus atributos originais, como antes, mas permite retornar ao equipamento editado daquele aliado. **Restaurar caso** limpa os equipamentos locais e volta aos padrões; histórico anterior permanece imutável.

### Limites e crítico dos monstros — parâmetros experimentais

Atributos próprios do aliado e bônus editáveis permanecem inteiros 0..999. Monstros usam **HP em 1..99999 (D76)** e os demais cinco atributos grandes diretamente em **1..9999**, sem limite de equipamento do aliado. INI/CRI permanecem 1..99 em ambos. A soma efetiva do aliado neste laboratório é limitada a **999**, configurada em `effective_stat_limit`. Se a soma exceder, a prévia informa, por exemplo, `999 + 65 = 1064 → 999 (limite de teste)`. JSON mantém o total bruto, o efetivo e o limite aplicado. O limite definitivo dos modificadores do jogo continua pendente.

Monstros não recebem a arma do aliado: usam CRI próprio, sem bônus de chance de arma, e um **multiplicador próprio de teste**, inicialmente 2× e editável em Crítico próprio do monstro. O aliado sempre usa o crítico da arma equipada (D86). Itens/buffs numéricos da simulação continuam modificadores de chance do atacante. Esse tratamento permite testar sem inventar equipamentos para monstros.

### Comparação e exportação

Lotes, custo de MP, mínimo 1, variação e sementes continuam iguais. Equipar, editar bônus ou inverter lados não consome sorteios. Para comparar com os mesmos sorteios, use Reiniciar sequência antes de cada caso.

Histórico/Condições e JSON versão **2** registram fichas próprias (`base_stats`), itens e dono (`equipment`, só no papel ocupado pelo aliado), composição (`composition`: próprios, bônus, soma bruta, total efetivo e limite) e origem do crítico do atacante (`critical_source`). `attacker` e `target` continuam sendo as fichas efetivas usadas no cálculo. Quando o monstro ataca, não há arma do atacante no snapshot. Resultados antigos não mudam ao editar a próxima configuração; arquivos versão 1 já exportados ficam preservados.

Exemplo de verificação: aliado com ATQ F próprio 20 e DEF F própria 20, espada de Bronze e armadura de Ferro → ATQ F total 30 e DEF F total 36. Contra DEF F direta 35, potência 1×, variação/crítico desligados, ataque causa 14. Ao inverter, um monstro com ATQ F direta 30 causa 14 no aliado com DEF F 36. Reative variação/crítico para estudar os lotes.

Não há inventário, slots extras, bônus mágicos, equipamento em monstros ou integração à exploração. Composição pura em `scripts/damage/damage_equipment.gd`, estado por aliado em `damage_lab_model.gd`; testes em `tests/damage_equipment_tests.gd` e `tests/damage_lab_ui_smoke.gd`.

## Referência de resistência dos inimigos iniciais — D62

Em 26/10/2026, após analisar o JSON exportado, o usuário indicou esse cenário como referência para os inimigos iniciais: aproximadamente **3 a 4 ataques básicos normais por inimigo**. Críticos podem encurtar a sequência; golpes são ações individuais, não rodadas completas da equipe.

O primeiro exemplo usa ATQ F 30, DEF F do alvo 35, HP do alvo 40 e potência 1×, com variação ±10%. Nas 1000 amostras analisadas, danos normais ficaram em 12–15 e críticos 2× em 25–30; chance configurada 10%, frequência observada 9,9%. Isso coloca o alvo na faixa pretendida de 3–4 golpes normais, podendo cair em 2 com crítico e dano suficiente. Arquivo de referência da sessão: `exports/damage-lab/danos-execucao-006-seed-421-1000x.json` (saída local, ignorada pelo Git).

**Confirmado:** direção de resistência para inimigos iniciais. **Experimental:** números desse caso e fórmula atual. **Pendente:** diversidade entre inimigos, relação com equipamentos/progressão e validação do encontro com ATB, vários aliados/inimigos e dano recebido. Não foram alteradas fichas do jogo ou parâmetros do laboratório por este registro.

**Atualização D68 (27/10/2026):** o usuário prefere o monstro com **30 HP** no cenário de estudo, mantendo a meta de 3–4 golpes normais. O teste sugerido com 50 HP não foi adotado. **Recomendação para experimentar, sem valor de DEF F confirmado:** aliado com ATQ F próprio 20 + Bronze 10 = total 30, ataque básico 1×, variação ±10%, monstro HP 30 e DEF F 60. Base `900 / (30 + 60) = 10`; dano normal 9–11, dois golpes 18–22, três 27–33 e quatro 36–44. Assim, são necessários 3 ou 4 golpes normais. Críticos podem reduzir a contagem. Nenhum preset/código foi alterado por essa recomendação.

## Resistência do aliado no início — D70

**Confirmado em 27/10/2026:** o personagem começa sozinho na aventura. O usuário deseja que, usando armadura de Bronze, sejam necessários aproximadamente **4–5 golpes para cair**. Referência para golpes físicos normais, com críticos podendo encurtar a contagem. Como único integrante ativo, 0 HP causa Game Over pela regra de derrota do grupo.

Para testar a defesa, usar **Trocar lados**: o monstro passa a atacante e a armadura acompanha o aliado alvo. **Exemplo recomendado, sem números iniciais definitivos aprovados:** aliado com HP 40, DEF F própria 20 + Bronze 10 = total 30; monstro com ATQ F direta 23, ataque básico 1×, variação ±10%. Base `23² / (23 + 30) ≈ 9,98`; dano normal 9–11. Três golpes somam 27–33, quatro 36–44 e cinco 45–55: derrota em 4 ou 5 golpes normais.

Esse cenário pode manter o monstro com HP 30 e DEF F 60 da comparação ofensiva: aliado com ATQ F próprio 20 + espada Bronze 10 causa 9–11 nele, exigindo 3–4 golpes normais. São referências de dano por ação; frequência ATB, chance de crítico e vários inimigos ainda precisam ser avaliados em batalha. Os lotes restauram HP/MP por amostra e não simulam automaticamente a sequência completa de morte/Game Over. Não foram alterados presets, composição da equipe de teste ou combate da exploração por este registro.

## Estudo dos dois JSONs e nova referência — D78, 27/10/2026

**Meta solicitada:** no primeiro nível, monstros iniciais caem em 3–4 golpes e protagonista em 5–6. Atualiza a referência anterior de 4–5 recebidos de D70. Comparar inicialmente acertos normais; críticos podem encurtar e esquivas podem acrescentar tentativas. Os lotes restauram HP por amostra e não medem uma luta com ATB.

Fontes, escolhidas pelo horário interno de exportação: `exports/damage-lab/danos-execucao-003-seed-232-1000x.json` (aliado → monstro) e `danos-execucao-014-seed-214-1000x.json` (monstro → aliado). O primeiro nome está desatualizado: o conteúdo registra execução **12, semente 214**, não execução 3/semente 232. O segundo registra execução 14/semente 214. Conferência independente das 2000 amostras: dano, esquiva/crítico, HP/MP e resumos coerentes com as condições.

| Direção | ATQ efetivo / DEF alvo | HP do alvo | Dano normal | Crítico | Esquivas observadas |
| --- | --- | ---: | --- | --- | --- |
| Aliado → monstro | 52 / 40 | 40 | 26–32 (894 acertos) | 53–65 (88) | 18/1000 |
| Monstro → aliado | 35 / 55 | 50 | 12–15 (917 acertos) | 25–30 (36) | 47/1000 |

Aliado: ATQ próprio 42 + Bronze 10 = 52; DEF própria 45 + Bronze 10 = 55; HP 50, CRI 5 + arma 5% = 10%, EVA 5. Monstro: ATQ 35, DEF 40, HP 40, CRI 3%, EVA 3. Críticos 2× e variação ±10%. Atualmente o monstro cai em dois acertos normais ou um crítico; o aliado cai quase sempre em quatro acertos normais (cinco são possíveis com danos baixos).

**Recomendações para teste, sem aprovação de valores nem alteração de código/dados:**

| Campo | Experimento A: ajustar HP | Experimento B: preservar HP e reduzir ATQ |
| --- | ---: | ---: |
| HP do aliado | 70 | 50 |
| ATQ próprio do aliado | 42 (+10 = 52) | 20 (+10 = 30) |
| DEF própria do aliado | 45 (+10 = 55) | 45 (+10 = 55) |
| HP do monstro | 90 | 40 |
| ATQ do monstro | 35 | 29 |
| DEF do monstro | 40 | 40 |
| Dano normal aliado → monstro | 26–32: 3–4 acertos | 12–14: 3–4 acertos |
| Dano normal monstro → aliado | 12–15: 5–6 acertos | 9–11: 5–6 acertos |

Ambos mantêm armas, fórmula, variação, crítico e EVA do caso atual. A altera apenas dois HP; B mantém HP do caso atual e altera apenas os dois ataques. Esses exemplos usam 40 HP do monstro do JSON atual; não tornam esse valor definitivo nem substituem automaticamente a preferência histórica de 30 HP registrada em D68.

Cálculo de referência: `base = ATQ efetivo² / (ATQ efetivo + DEF efetiva do alvo)`, potência 1×. Considerar o arredondamento: para o monstro cair em 3–4 acertos normais, dois danos máximos precisam ficar abaixo do HP e quatro mínimos precisam alcançá-lo; conferir ainda se três golpes conseguem alcançar o HP para haver variação. Para o aliado cair em 5–6, quatro máximos devem ficar abaixo do HP e seis mínimos devem alcançá-lo; conferir a possibilidade de morte no quinto. Crítico/esquiva não podem garantir essas mesmas contagens em toda tentativa.

Distribuições teóricas adicionais, calculadas pela variação uniforme e chances configuradas, acumulando dano e sem cura/ATB: A exige em média **3,51 tentativas** contra o monstro e **5,91** contra o aliado; B, **3,57** e **5,51**. São estimativas matemáticas, não novas execuções do laboratório nem validação de uma batalha real. Estudo detalhado em `artifacts/balanceamento-inicial-2026-10-27/analise.md`.

## Ajuste de direção após o estudo — D79

**Confirmado em 27/10/2026:** aliado inicial com **40 HP**, monstros iniciais com **35–45 HP**, dano normal causado pelo aliado aproximadamente em **9–15**. Após esclarecer o conflito numérico, o usuário confirmou que essa faixa vale para o aliado atacar; os inimigos causam menos para manter **5–6 acertos normais até a queda do aliado**. A meta ofensiva continua **3–4 acertos**. A faixa 35–45 substitui a preferência de 30 HP de D68 para este estudo. Propostas anteriores de aumentar HP do aliado para 70/monstro para 90 não seguem esta direção.

**Exemplo recomendado para experimentar, sem aprovação dos ATQ/DEF:** manter potência básica 1×, variação ±10% e bônus Bronze +10:

| Campo | Aliado | Monstro inicial |
| --- | ---: | ---: |
| HP | 40 (confirmado) | 35–45 (confirmado); 40 como exemplo central |
| ATQ F próprio/direto | 20 + arma 10 = total 30 | 24 |
| DEF F própria/direta | 45 + armadura 10 = total 55 | 40 |

Cálculo: aliado `30²/(30+40) ≈ 12,86`, arredondando com variação para **12–14** de dano normal, dentro da referência 9–15. Monstro de 35 HP cai em três acertos; de 40 HP, em três ou quatro; de 45 HP, em quatro. Todos os HP inteiros da faixa 35–45 respeitam três a quatro acertos normais neste exemplo.

Monstro `24²/(24+55) ≈ 7,29`, arredondando para **7–8** de dano normal recebido. Quatro golpes somam no máximo 32; cinco somam 35–40; seis somam no mínimo 42. Portanto, aliado de 40 HP cai em **cinco ou seis acertos normais**. Se o dano recebido fosse pelo menos 9 por acerto, cinco já somariam pelo menos 45; não seria possível manter a possibilidade de seis com 40 HP.

Verificação por cálculo independente em Python, incluindo extremos/arredondamento e todos os HP inteiros 35–45. Não é nova execução da calculadora Godot ou validação de luta com ATB. Se usado crítico 2× do exemplo anterior, as faixas seriam 23–28 causados e 13–16 recebidos, podendo encurtar a sequência; esquivas podem alongar o número de tentativas. Valores de ATQ/DEF, chance/multiplicador, demais atributos e ritmo ainda precisam de teste. Nenhuma ficha, preset ou fórmula foi alterada por este registro.

**D80 — referência para progressão (27/10/2026):** o preset pessoal **Aliado #1** está sendo montado como ficha inicial do personagem no nível 1. O estudo atual de dano/resistência calibra esse ponto de partida, mantendo próprios e bônus de Bronze separados. Os valores continuam em teste. Decidir futuramente ganhos/curvas por nível, XP, nível máximo e CRI; INI/EVA permanecem sem crescimento natural por nível. O laboratório continua manual, sem sistema de níveis/progressão implementado.

## Aliado #2 e EVA do couro — D84

**Autorizado e implementado em 27/10/2026:** preset **Aliado #2** gravado na biblioteca pessoal preservando Aliado #1 e Monstro #1. Ficha própria HP36/MP14/INI11/ATQ20/DEF30/MAG20/DEF M21/CRI7/EVA7; **Arco composto** (+10 ATQ F, +12 p.p. CRI, crítico 1,6×) e **Conjunto de couro** (+5 DEF F, +5 EVA). Totais **ATQ30/DEF35, CRI19%, EVA12%**. Referência experimental de nível 1; detalhes em [ALIADO_02.md](ALIADO_02.md).

Catálogo inclui arco/couro como itens próprios. A definição em `data/damage_lab_ally_02.json` foi usada para instalação pontual e testes; não recria o preset automaticamente ao iniciar. Continua possível salvar, carregar, atualizar e excluir normalmente. Reabrir o laboratório para carregar o catálogo e selecionar **Aliado #2**.

EVA na ficha do aliado representa o atributo próprio. A armadura tem campo **EVA +** (inteiro 0..100, experimental). A armadura é obrigatória após D86. A composição mostra `EVA: 7 + 5 = 12%`. Os sorteios usam o total do alvo; a base não muda ao editar o bônus do couro ou trocar os lados. EVA efetiva limitada a 100%, com soma bruta preservada. Exemplo de teste: 99 + 5 = 104 → 100%. Monstros continuam sem equipamento e com EVA direta.

Presets v1 anteriores sem `armor.evasion_bonus` recebem zero em memória, sem regravar ao ler. JSON v3 ganha dados aditivos de composição de EVA (`base_stats`, `equipment`, `composition`) e `formula.evasion_stats`; `attacker`/`target` registram os valores efetivos usados na ação. Histórico e exportação mantêm as condições originais após trocar equipamento. Esta etapa implementa o bônus de armadura solicitado; itens/buffs reais de EVA continuam fora do recorte.

Testes específicos: `damage_ally_02_tests.gd` e `damage_ally_02_ui_smoke.gd`; cobertura de composição, limites, recusa de troca/remoção incompatível, recarga/persistência, JSON, condições, semente, arco 1,6× e presets anteriores. Sem novas animações, regras de alcance/munição, progressão por nível ou integração ao combate da exploração.

## Equipamentos exclusivos e obrigatórios — D85/D86

**Confirmado e implementado em 27/10/2026:** arco composto e conjunto de couro são exclusivos do **Aliado #2**. Os seletores apresentam somente equipamentos compatíveis com o personagem carregado. Carregar preset recompõe os menus e seleciona itens por ID, preservando nomes, números e bônus. O nome da ficha tem tooltip indicando seu personagem de origem.

Identidade de personagem (`character_id`) é separada do modelo reutilizável `actor.id` e do ID/nome do preset. Primeiro aliado usa `ally_1`; segundo, `ally_2`. Salvar cópia mantém a identidade, mesmo com nome novo; renomear não concede itens e Atualizar não troca o personagem de origem. A restrição canônica vem de `allowed_character_ids` no catálogo, não de metadados removíveis da cópia do item. Modelo, salvamento/carga e calculadora rejeitam equipamentos incompatíveis antes de consumir RNG ou registrar execução.

A biblioteca local foi migrada uma vez para registrar as identidades explícitas dos dois aliados, mantendo os três presets, atributos, equipamentos e revisões. Presets antigos sem identidade explícita usam o ID do modelo como compatibilidade; a migração do segundo aliado instalado é explícita, sem inferir permissão por nome ou arma. JSON passa a incluir a identidade nos atores e `equipment.owner_id` identifica o personagem, distinguindo o segundo aliado do modelo compartilhado. Histórico anterior não é reescrito.

**D86:** espadas e armaduras de metal são exclusivas do Aliado #1. O Aliado #2 vê somente arco composto e couro. Ambos os slots são obrigatórios: não há Sem arma/Sem armadura. O modelo preserva o item anterior ao recusar remoção ou troca incompatível, e salvamento/carga/execução validam o conjunto. Os padrões por personagem ficam em `characters` no catálogo: espada/armadura de Bronze para #1 e arco/couro para #2. Presets legados com `id: none` recebem esses padrões em memória ao carregar, sem regravar a biblioteca; equipamento ausente/desligado/incompatível é recusado. Loadouts são separados por personagem, evitando vazamento ao alternar presets. Sem mudança de números, ações, níveis ou combate integrado. Reabrir o laboratório para carregar a regra atualizada.

## Presets de fichas — D71/D72, revisão D77

**Revisado em 27/10/2026 a pedido do usuário:** todos os presets anteriores foram excluídos, incluindo as duas referências fornecidas e os três personalizados locais existentes. O catálogo `data/damage_lab_presets.json` foi removido. O seletor antigo com oito fichas de exemplo foi retirado; `data/damage_lab.json` mantém somente uma ficha manual de aliado e uma de monstro para iniciar a edição. Os números dessas fichas continuam provisórios, sem novo balanceamento.

A biblioteca começa **vazia**. Isso é uma limpeza pontual: novos presets criados pelo usuário permanecem entre sessões e não são apagados ao abrir o laboratório. No topo existem seletores separados **Preset do aliado** e **Preset do monstro**, inicialmente em **Ficha atual / manual**.

- **Salvar…:** confirma o número que estiver sendo digitado, captura a ficha daquela categoria e solicita um nome de até 80 caracteres. Cria um novo preset e o seleciona. Nome vazio ou repetido na mesma categoria é recusado; aliado e monstro podem ter nomes iguais. O nome identifica também o participante salvo no editor/duelo.
- **Carregar:** restaura o preset selecionado, inclusive se ele já estiver selecionado e tiver sido editado. Selecionar outro preset também o carrega. O carregamento relê o arquivo local e preenche todos os valores antes de atualizar a apresentação; texto pendente anterior não sobrescreve os dados carregados.
- **Atualizar:** grava alterações no preset selecionado, mantendo ID/nome e aumentando a revisão. Só fica habilitado após editar uma ficha salva.
- **Excluir:** remove definitivamente o preset selecionado do arquivo e da lista daquela categoria. A ficha atual permanece disponível para edição ou novo salvamento; histórico e execuções anteriores são preservados. A outra categoria permanece intacta. Excluir o último preset deixa a lista vazia e Salvar continua disponível.

São salvos os **nove atributos próprios/diretos**, incluindo **EVA**, **HP de monstro até 99999** e **multiplicador crítico próprio**. Para o aliado, guardar também arma/armadura, IDs, bônus editados de ATQ F/DEF F/EVA, chance e multiplicador da arma. Não salvar atributos efetivos como se fossem próprios: ao carregar, recalcular os totais sem somar bônus duas vezes. O monstro continua sem equipamentos. Presets acompanham o participante ao inverter os lados; carregar aliado/inimigo altera somente aquela categoria, independentemente de estar como atacante ou alvo.

Ação, potência/custo, permissões de crítico/esquiva, modo de crítico, variação, modificadores globais e semente continuam **fora** do preset de ficha. Salvar/carregar/atualizar/excluir não consomem sorteios nem modificam resultados anteriores. Durante a animação ou diálogo de salvar/exportar, essas operações ficam bloqueadas. **Restaurar caso** volta às duas fichas manuais/equipamentos iniciais e reinicia a sequência, preservando os presets pessoais e o histórico.

Persistência em **`user://damage_lab_presets.json`**, formato `rpg.damage_lab.presets`, versão 1, separado das exportações de amostras. Gravação por arquivo temporário e substituição; releitura antes de criar/atualizar/excluir preserva alterações sequenciais feitas por outra instância. JSON inválido é preservado e operações de escrita/exclusão ficam bloqueadas, com erro exibido. Presets antigos sem EVA continuam recebendo zero em memória se carregados, sem regravar na leitura. Não há autosave de edições nem carregamento automático do último preset.

Histórico/Condições e `conditions.presets` no JSON v3 guardam ID, nome, revisão, origem personalizada e marca de alteração por participante. Atualizar ou excluir um preset posteriormente não altera os dados de uma execução anterior. Não há importação de relatórios ou salvamento da aventura.

Implementação em `scripts/damage/damage_presets.gd`, `damage_lab_model.gd` e `scripts/ui/damage_lab.gd`. Testes em `tests/damage_presets_tests.gd` e `tests/damage_presets_ui_smoke.gd`, com arquivos temporários exclusivos. Cobrem todos os campos, zeros, limites, digitação pendente, recarregamento do mesmo preset, equipamentos, troca de lados, persistência/reabertura, exclusão e erros de leitura/gravação.

## Duelo e edição

- Um atacante e um alvo, sem ATB ou IA. Após D77, uma ficha manual de aliado e uma de monstro, com presets criados pelo usuário; Trocar lados inverte os papéis. Sem fogo amigo.
- Todos os atributos das duas fichas são editáveis nas faixas D59/D69/D76, atualizadas ao selecionar ou inverter o participante: seis atributos 0..999 no aliado; HP 1..99999 e os outros cinco 1..9999 no monstro; INI/CRI 1..99 e EVA experimental 0..100 em ambos. HP e MP representam os recursos iniciais/máximos da amostra. HP zero pode ser editado no aliado, mas impede executar; no monstro, mínimo inicial 1. HP/MP após a ação podem chegar a zero. MP insuficiente impede executar, sem consumir sorteios ou gerar resultado parcial. INI é informativa.
- **Refinamento solicitado em 26/10/2026:** digitação direta em todos os campos numéricos. Clicar no número seleciona o texto; selecionar o campo pelo teclado e começar a digitar também substitui o valor. Enter, Tab, clique em outro campo ou execução confirmam a edição, respeitando os limites existentes. Decimais aceitam ponto ou vírgula; setas/controle continuam disponíveis.
- Seletores de arma e ação; chance/multiplicador da arma, potência/custo de MP, permissão de crítico, variação e modificadores ajustáveis. Trocar lados mantém a ação e move o equipamento junto do aliado; o monstro usa seu próprio crítico de teste.
- **1×** mostra aproximação/impacto/retorno físico ou projétil mágico provisório; rótulos de recursos ficam na posição de origem. Lotes **10×, 100× e 1000×** calculam imediatamente e mostram o estado da última amostra, sem enfileirar animações.
- Edições são locais à sessão até Salvar como/Atualizar um preset pessoal. Arma/armadura são seleções do simulador; não há inventário da aventura, sistema de buffs real, salvamento completo da sessão ou sincronização de fichas com a exploração.

## Fórmula proporcional v1 — experimento

```text
base física = potência × ATQ F² / (ATQ F + DEF F do alvo)
base mágica = potência × MAG² / (MAG + DEF M do alvo)
```

Potência é um **coeficiente**: 1,0× é a referência, 1,8× multiplica a base por 1,8. Ofensiva zero resulta em base zero, incluindo ofensiva/defesa ambas zero, evitando divisão por zero. Defesa zero preserva ofensiva × potência. Os outros atributos não interferem na família de dano escolhida.

Ordem experimental implementada:

0. Se a ação permitir, verificar esquiva com EVA do alvo: se esquivar, dano zero, sem crítico, consumindo ação/MP; encerrar a resolução do golpe.
1. Nos acertos, calcular base proporcional com os atributos correspondentes.
2. Se ligada, sortear variação uniforme entre `1 − faixa/100` e `1 + faixa/100`; padrão **±10%**, editável de 0 a 100%.
3. Determinar crítico pela permissão da ação e pelo modo **sorteado / desligado / forçado**. O modo forçado ainda respeita a permissão da ação.
4. Multiplicar o dano variado pelo multiplicador da arma em caso de crítico; caso contrário, por 1.
5. Arredondar ao inteiro mais próximo e aplicar **mínimo 1**. Não limitar o dano à faixa dos atributos: 999 nos aliados e 9999 nos monstros não são tetos do dano resultante.
6. Remover no máximo o HP inicial do alvo e descontar o MP da ação. Exibir separadamente **dano calculado** e **HP removido**, inclusive nos totais dos lotes.

Composição aprovada da chance (D63):

```text
chance (%) = CRI + chance da arma + bônus de item + bônus de buff
```

No laboratório, o ajuste de conversão permanece disponível para comparar alternativas e o limite experimental continua 0..100%:

```text
chance (%) = limitar(CRI × conversão + chance da arma + item + buff, 0, 100)
```

A conversão **1% por ponto de CRI foi confirmada pelo usuário em D63**. Exemplo: CRI 5 + arma com 5% = chance total 10%, antes de outros bônus. O campo de conversão 0..10% é uma ferramenta de experimentação do laboratório, sem criar uma configuração do jogo ou mudar a regra aprovada. Item/buff são campos numéricos em pontos percentuais, de −100 a +100 cada; não implementam itens ou magias reais. Somente a arma fornece multiplicador. Os seis presets de espada usam **5% / 2×**, com chance editável 0..100% e multiplicador 1..10×; as antigas armas de controle 2×/3× foram removidas a pedido do usuário. Valores das armas e limites dos campos continuam parâmetros de teste, sem constituir regra definitiva.

As ações iniciais são ataque físico **1× / 0 MP**, técnica física **1,8× / 4 MP** e magia **1,5× / 7 MP**. Nas ações de dano, potência pode variar0..10× e custo0..999MP; nas magias puras de aflição, potência não se aplica e o custo inicial é4MP. Físicas permitem crítico; D103/D110 restringem crítico ao dano físico. Magia não permite crítico, inclusive no modo forçado. Fichas e valores em `data/damage_lab.json` são exemplos originais, sem classes, bestiário ou progressão aprovados. Nenhuma fórmula foi copiada automaticamente da referência de Chrono Trigger.

## Lotes, sequência e comparação

Cada amostra começa com **os mesmos HP/MP e condições**. Isso permite coletar 1000 ataques mesmo que um só golpe derrote o alvo ou gaste todo o MP. Não é uma simulação de 1000 turnos consecutivos de batalha.

Resumo com mínimo, máximo, média, médias normal/crítica, totais de dano/HP removido, quantidade e frequência observada de críticos e chance configurada. Histograma com até 12 intervalos, distinguindo esquivas, danos normais e críticos. Aba **Amostras** exibe todas as ações e permite selecionar cada uma para decompor o cálculo. Aba **Condições** registra as fichas, arma, ação, modificadores, semente e início da sequência daquele resultado.

Há quatro RNGs independentes, derivados da semente: variação, crítico, esquiva e aflição (D110). Cada ação avança cada fluxo uma vez, inclusive nos modos fixos, em esquivas e em ações sem permissão de esquiva. Alterar a permissão de crítico não muda a sequência da variação. Ações e lotes sucessivos continuam a sequência; 10× + 10× equivalem às primeiras 20 amostras de uma execução maior iniciada na mesma semente. **Reiniciar sequência** volta ao primeiro sorteio sem mudar as fichas; alterar a semente também reinicia. A mesma configuração, semente e posição na sequência reproduzem o resultado na engine validada.

Histórico guarda até **12 execuções** com cópias das condições e estados de RNG. Editar o próximo caso não reescreve resultados anteriores. Consultar o histórico não aplica suas fichas ao próximo teste nem altera a sequência atual. **Restaurar caso** volta aos presets e semente iniciais, mantendo o histórico. Fechar o laboratório descarta a sessão; presets pessoais explicitamente salvos continuam em disco.

## Exportar amostras em JSON — D61

**Confirmado e implementado em 26/10/2026.** Execute uma ação/lote, ou selecione um resultado no histórico, e use **Exportar JSON [F10]**, ao lado do seletor **Resultado**. Escolha pasta/nome e confirme **Salvar JSON**. O botão só fica disponível quando há resultado e a animação terminou. Cancelar não grava arquivo nem altera a sequência.

A pasta inicial é `exports/damage-lab/`, na raiz do projeto, criada ao abrir a exportação. Depois de salvar, o diálogo reutiliza a última pasta da sessão. O nome sugerido identifica execução, Seed e quantidade, por exemplo `danos-execucao-006-seed-421-1000x.json`. É possível escolher outro destino/nome; extensão `.json` é adicionada quando ausente. Se já existir, o diálogo pede confirmação de substituição. O caminho salvo aparece no rodapé. A pasta de saídas está ignorada pelo Git; não se confunde com dados de configuração.

O arquivo contém **todas as linhas daquela execução**, mesmo que só parte esteja visível na tabela. Exportar um resultado antigo usa sua cópia de condições e sorteios, mesmo depois de editar o próximo caso. Não executa novas ações, não muda o histórico nem avança o RNG. Exporta uma execução por arquivo; para comparar casos, selecione e exporte cada resultado desejado. Anexe o `.json` na conversa para análise.

Formato legível, UTF-8, com números sem arredondamento de apresentação e booleanos de crítico/esquiva. A versão atual é **5**, com INT/VIG, testes de aflição e quarto RNG; versão4 acrescentou distância, versão3 EVA e versão2 composição/equipamentos. Arquivos anteriores são preservados:

| Campo | Conteúdo |
| --- | --- |
| `format` / `version` | Identificador `rpg.damage_lab.samples`, versão 3. |
| `exported_at_utc` / `engine_version` | Data UTC da exportação e versão da engine. |
| `formula` | Identificador `proportional_v1`, status experimental, fórmulas, ordem de cálculo, composição da chance, política de recursos por amostra e `attribute_ranges` com faixas por categoria/atributo. |
| `run` | Número da execução, Seed, primeiro/último índice global e estados dos três RNGs antes/depois. Estados inteiros de 64 bits são **strings** para preservar os bits em leitores JSON/JavaScript. |
| `conditions` | Atacante/alvo efetivos, fichas próprias, equipamentos somente do aliado, composição de atributos, origem de crítico, presets selecionados com revisão/marca de edição, ação e parâmetros originais. A Seed registrada é a usada na execução. |
| `summary` | Quantidade, mínimo/máximo/média, totais de dano e HP removido, frequência/contagem de críticos e esquivas, acertos, médias por tipo, chances configuradas e histograma. |
| `samples` | Todas as amostras, com índice local e global (`sequence_index`), atributos usados na base, sorteios/fatores, esquiva/chance, crítico/multiplicador, dano bruto/final, HP removido e HP/MP antes/depois. |

Falhas ao abrir/gravar o destino são mostradas no rodapé, sem informar sucesso nem alterar o resultado. Esta ferramenta exporta relatórios; não implementa importação, salvamento da aventura ou garantia de replay entre versões diferentes da engine.

Módulo separado `scripts/damage/damage_export.gd`, sem dependência da interface ou da simulação de combate. Testes de exportação em `tests/damage_export_tests.gd` e integração com o diálogo em `tests/damage_lab_ui_smoke.gd`.

## Controles e roteiro

| Controle | Ação |
| --- | --- |
| Tab / Shift+Tab / ↑↓ | Percorrer campos e botões. Nas amostras, ↑↓ percorre linhas; Tab sai da tabela. |
| ←→ | Ajustar número, opção, marcação ou aba focada. |
| Clique no número / digitar com o campo selecionado | Informar o valor diretamente, substituindo o texto selecionado. |
| Enter / Tab / mudar o foco | Confirmar valor digitado. Enter também inicia edição ou aciona botão/opção. Aceita vírgula ou ponto decimal. |
| F6 / F7 / F8 / F9 | Executar 1× / 10× / 100× / 1000×. |
| F10 / Exportar JSON | Salvar todas as amostras do resultado selecionado com as condições originais. |
| R / Reiniciar sequência | Voltar ao início dos sorteios. |
| F5 / Restaurar caso | Restaurar fichas, arma, ação e semente iniciais. |
| Controle: direcional / analógico esquerdo | Percorrer campos; esquerda/direita ajusta. |
| Controle: botão sul / Start | Acionar opção focada / executar 1×. |
| Controle: ombros | Campo anterior/próximo, inclusive para sair da tabela. |

O painel de edição rola automaticamente ao receber foco abaixo da parte visível; o resultado fica à direita. Durante a animação individual, a edição e novas execuções ficam bloqueadas até o retorno.

Para comparar: desative variação e crítico, coloque ofensiva e defesa em 100 e potência 1×: dano 50. Zere a defesa: dano 100. Ative variação e execute 1000×; depois reinicie a sequência e repita para conferir reprodução. Teste armas 2×/3×, magia e outros tipos de alvo, consultando Amostras/Condições. Alterar DEF M deve afetar apenas a magia, e DEF F apenas o físico.

## Pendente para o jogo

- Validar sensações e balancear curvas, números, distribuição de variação, arredondamento e ordem das operações após experimentar.
- Definir valores/limites dos modificadores e armas, acúmulo/duração dos bônus, elegibilidade por ação e casos sem arma. Conversão de CRI e soma das contribuições confirmadas em D63.
- Progressão, equipamentos, itens reais, buffs/duração, resistências, elementos, precisão adicional, itens/buffs de EVA, cura e demais variáveis futuras não fazem parte deste recorte.
- Definir limites efetivos definitivos, crítico sem arma e valores por equipamento; escolhas atuais da composição são provisórias.
- Integrar o modelo aprovado ao combate da exploração em etapa posterior; INI/ATB e Battle Speed permanecem com as regras atuais.

Arquitetura: calculadora pura em `scripts/damage/damage_calculator.gd`; estado/histórico em `damage_lab_model.gd`; interface e visual separados em `scripts/ui/damage_*`. Testes `tests/damage_lab_tests.gd` e `tests/damage_lab_ui_smoke.gd`; comandos/resultados em [VALIDACAO.md](VALIDACAO.md).

## Ajuste ofensivo aplicado — D87/D88, 27/10/2026

O usuário definiu #1 cerca de15% acima de #2 em dano médio por ataque e autorizou aplicar a proposta: **ATQ próprio do Aliado #1 de20→23**, espada+10 e total33; preset pessoal atualizado para revisão2. Aliado #2 e Monstro #1 preservados. Contra Monstro #1 (DEF40/EVA3%), média teórica por tentativa15,919 contra13,920 (+14,36%); normal13–16/crítico27–33 para #1, mantendo3–4 acertos normais contra monstros35–45HP. Máximo16 faz parte da proposta adotada, ampliando levemente a referência inicial aproximada9–15. INI/ATB são comparação separada. Somente o preset pessoal foi alterado; catálogo manual e combate integrado permanecem como estavam.

Gravação feita pela biblioteca existente, depois reaberta e comparada com a anterior; somente o ATQ próprio e a revisão do primeiro mudaram. Ambos os aliados passaram por1000 ações após recarga, com extremos de dano confirmados na calculadora. Reabrir o laboratório, selecionar **Aliado #1** e usar **Carregar** para atualizar uma ficha já aberta.

## Escalas do Aliado #2 — D92, 28/10/2026

Adicionados seis arcos de madeira com ATQ+10/15/22/31/44/58 e seis trajes leves com DEF+5/8/12/17/24/33, somente para Aliado #2. Cada arco mantém CRI+12p.p./1,6× e cada traje EVA+5. Primeiro arco/couro conservam IDs e valores, com nomes Arco Composto de Madeira/Traje de Couro; a carga resolve nomes atuais em memória por ID sem sobrescrever bônus editados, revisões ou arquivo pessoal. Os seletores mostram seis estágios, sem opção vazia. Primeiro e último pares dão ATQ30/DEF35 e ATQ78/DEF63 com a ficha atual do segundo, sempre EVA12. Salvar/Carregar/Atualizar/Excluir, troca de lados e exportação continuam funcionando. Espadas/metal e presets iniciais permanecem com os mesmos números. Sem progressão por nível, obtenção, inventário ou alteração do combate integrado. Tabela e testes em `ESCALA_ARCOS_E_TRAJES.md`; reabrir o laboratório para carregar o catálogo atualizado.

## ATQ D e DEF D — D94, 28/10/2026

Implementados no laboratório os pares de contato ATQ F/DEF F, disparo físico ATQ D/DEF D e magia MAG/DEF M. Espada soma ATQ F; arco soma ATQ D. Proteções mantêm bônus DEF F e ganham DEF D espelhado: metal+5/8/12/17/24/33; trajes+10/16/24/34/48/65. DEF D+ é editável separadamente e EVA continua independente. DEF D própria45/30 para os aliados, conforme escolha do usuário; ATQ D10/20 adotado para o teste. Com os equipamentos iniciais, primeiro tem33/10 ATQ F/D e55/50 DEF F/D; segundo20/30 e35/40. O arco usa DEF D40 do Monstro #1 para preservar o dano inicial.

Seletor físico: da arma (contato para monstro), corpo a corpo ou distância. Magia ignora o seletor e usa MAG/DEF M. Prévia e histórico indicam o par efetivamente usado. Valores de distância usam0..999 nos aliados e1..9999 nos monstros; limites, soma bruta, bônus, composição e atributos próprios continuam separados. Presets antigos recebem campos ausentes e modo da arma por ID em cópia; não são regravados automaticamente. Novos relatórios são JSONv4 e incluem fonte do dano por amostra. Três RNGs, custos, EVA, crítico, movimento visual provisório e combate integrado permanecem com o comportamento anterior. Especificação e testes em `ATQ_DISTANCIA.md` e `VALIDACAO.md`. Reabrir o laboratório e carregar os presets para usar a versão atual.

## Direção futura da EVA — D95, 28/10/2026

Usuário revisa a regra de ausência de crescimento natural: EVA poderá receber+1 a cada10 ou15 níveis (intervalo ainda por escolher), além de modificadores de equipamentos/magias e aumentos permanentes de+1 por itens especiais raros encontrados na campanha. Não há progressão por nível nem esses itens/efeitos implementados no laboratório. Presets e valores atuais permanecem; o campo EVA própria continua editável para testes. A composição atual própria+equipamento não perde ou ganha valores automaticamente por este registro. INI não foi alterada.


## Testes de aplicação de aflições — D110/D111 implementados

**D98–D111, 28/10/2026:** o recorte estudado é somente magias cujo objetivo é aplicar uma aflição, sem dano direto. Não incluir ataques físicos com aflição nem ações que combinam dano e aflição nesta etapa. Campos e testes implementados após autorização do usuário em D110; avaliação de balanceamento posterior.

- MAG do atacante enfrenta **DEF M + VIG** para Veneno/Lentidão e **DEF M + INT** para Confusão/Medo (D111).
- Fórmula comum vigente D111: `chance (%) = 100 × MAG / (MAG + DEF M + resistência específica)`. Soma sem teto adicional, mantendo os limites dos atributos próprios. Prévia e amostras mostram DEF M, VIG/INT e total.
- **D109 — regra vigente:** usar diretamente a fórmula pura, sem saturação, mínimo de5% ou máximo de95%. Substitui os limites anteriores D102/D107. EVA permanece anterior e pode impedir a aplicação; chance total por tentativa = `(1 − EVA/100) × chance da fórmula`. Com MAG e resistência positivas, a chance da fórmula fica estritamente entre0% e100%.
- INT/VIG próprios em **1..999**, com crescimento por nível definido para o desenho futuro. Referências iniciais escolhidas em D106; ganhos por nível pendentes, sem implementar progressão.
- **D105:** Veneno, Lentidão, Confusão e Medo iniciais permitem esquiva por EVA. Primeiro verificar esquiva; se ocorrer, encerrar sem aflição. Sem esquiva, testar MAG contra DEF M + VIG/INT. Permissão configurável por magia: outras futuras poderão ignorar EVA, mantendo o teste de resistência. Resistir e esquivar são resultados distintos; não criar essas magias futuras agora.
- Crítico se refere somente ao dano físico; aflições não têm crítico. A opção experimental atual que permite ligar crítico em magia descreve a implementação anterior, não essa nova regra aprovada. D110 implementa a restrição: interface desabilita crítico para magia, modelo e calculadora impedem crítico mágico inclusive no modo forçado.
- Preservar referências e demais atributos/equipamentos. **D106:** Aliado #1 INT20/VIG25; Aliado #2 INT20/VIG20; Monstro #1 INT15/VIG20. Valores experimentais: campos ausentes são preenchidos em memória ao ler os presets; valores novos personalizados são preservados. Arquivos e revisões não são alterados na leitura. Salvar/Atualizar passam a persistir INT/VIG normalmente.
- **D108:** custo inicial de **4 MP** para cada uma das quatro magias, para fins de teste.

**Disponível:** escolha Veneno, Lentidão, Confusão ou Medo em Ação. INT/VIG aparecem nas duas fichas; próprios/diretos1..999. Prévia mostra a composição da resistência (DEF M + VIG/INT), a chance após a etapa EVA e a chance total por tentativa. F6/F7/F8/F9 executam1×/10×/100×/1000×, com4MP por tentativa e recursos restaurados por amostra. Resumo/gráfico/tabela separam Esquivou/Resistiu/Aplicou; escolher uma amostra mostra resistência, chances e sorteios. A etapa DEF M + VIG/INT é marcada como não realizada se houve esquiva. Histórico preserva condições anteriores; exportação F10 gera JSONv5 com a fórmula `affliction_application_v2`, DEF M/INT/VIG e resistência combinada, estatísticas, índices e quarto RNG em texto. Para aflições, não há dano direto nem aplicação do mínimo1. Potência/variação/crítico ficam indisponíveis nessa ação; demais testes de dano continuam disponíveis. Eventos de duração/ticks não são executados.


### Compatibilidade, sorteios e verificação de D110

A biblioteca continua no formato de presets versão1, com campos aditivos. `intelligence`/`vigor` ausentes recebem referências por identidade estável do personagem ou categoria de monstro, configuradas em `data/damage_lab.json`. A leitura preserva atributos existentes, bônus, IDs, revisões e arquivo pessoal. Definição de instalação do Aliado #2 também atualizada. Novas exportações usam versão5; arquivos de relatórios anteriores não são regravados.

O quarto RNG (`affliction`) usa uma semente derivada independente e estado copiável. Cada amostra avança os quatro fluxos uma vez, inclusive ações sem aflição ou esquivadas. O teste de resistência não é realizado quando há esquiva, embora o sorteio independente seja consumido para manter a sequência reproduzível. Alternar ações ou editar fichas não modifica os sorteios de dano/variação/esquiva anteriores. JSON inclui chances condicionais e totais, classificação da tentativa e estado dos quatro fluxos; exportar não recalcula.

Verificações específicas e regressões aprovadas em `VALIDACAO.md`. Para executar as suítes novas, na pasta do projeto:

```sh
godot --headless --path . --script res://tests/damage_affliction_tests.gd
godot --headless --path . --script res://tests/damage_defm_tests.gd
godot --headless --path . --script res://tests/damage_affliction_ui_smoke.gd
```

Para conferir com renderização real e salvar capturas:

```sh
godot --path . --audio-driver Dummy --script res://tests/damage_affliction_ui_smoke.gd -- --visual-captures=res://artifacts/damage-lab-afflictions
```


### Estudo histórico dos três presets — versão anterior sem DEF M, 28/10/2026

A matriz de quatro confrontos válidos e quatro magias foi executada com cinco sementes,5.000 tentativas por caso (80.000 no total). Sem mudanças de atributos/equipamentos/presets. Resultados próximos à fórmula, com maior desvio0,39 ponto percentual; mesma MAG dá mesmo desempenho ofensivo e EVA compensa parte da menor VIG do segundo aliado. [Análise completa e scripts](../artifacts/aflicoes-presets-2026-10-28/analise.md). Avaliação dos efeitos em batalha e aprovação de balanceamento continuam para outra etapa.


### Adoção de DEF M — D111

Depois da comparação de duas rodadas1.000×, o usuário adotou a soma de DEF M à resistência específica para as quatro magias. O custo4MP, EVA anterior, ausência de dano direto/crítico e fórmula sem limites adicionais foram preservados. Editar DEF M atualiza as chances da próxima execução; histórico e resultados anteriores não mudam. Amostras/JSON incluem `specific_resistance`, `magic_defense`, `combined_resistance` e `resistance_formula`. JSON continua na versão5, identificando a fórmula nova como `affliction_application_v2`; relatórios anteriores permanecem intactos com sua identificação original.

A suíte `damage_defm_tests.gd` reproduz exatamente o caso aceito: MAG25 contra DEF M21 + VIG25, EVA5%, semente421,1.000 tentativas →309 aplicações/647 resistências/44 esquivas. Também verifica as quatro magias, soma acima999 sem limitação, contribuição de cada parcela, mesmas sequências RNG, preservação de histórico e curva sem piso/teto.

Scripts dos estudos anteriores usam as referências congeladas `artifacts/damage-lab-defm/calculator_v1.gd` e `export_v1.gd` para manter a reprodução dos resultados históricos sem DEF M. Esses arquivos não são usados pelo laboratório jogável. Resultados atuais de regressão e capturas em `artifacts/damage-lab-defm/`; resumo em VALIDACAO.md.


### Estudo atual dos três presets com DEF M — 29/10/2026

Matriz D111 de quatro confrontos válidos/quatro magias, com cinco sementes e5.000 tentativas por confronto/magia, total80.000. Aplicações observadas incluindo EVA: aliados→monstro28,86% em Veneno/Lentidão e31,06% em Confusão/Medo; monstro→#1 33,74%/36,00%; monstro→#2 33,32% nos quatro. Maior desvio teórico0,33 ponto percentual, zero divergências na auditoria. Comparação com a versão anterior utilizou os mesmos presets/sorteios; nenhuma mudança de atributos ou custo. [Resultados completos e reprodução](../artifacts/aflicoes-presets-defm-2026-10-29/analise.md).
