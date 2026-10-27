# Laboratório de danos

**Status em 26/10/2026 (D60): implementado para experimentar e ajustar durante os testes**, conforme autorização do usuário. Cena independente `scenes/damage_lab.tscn`, aberta por `Executar laboratorio de danos.command`. O combate da exploração e o laboratório de combate continuam com seus cálculos anteriores. Fórmula, fichas e números abaixo são **experimentais**, sem confirmação de balanceamento definitivo.

## Confirmado

- Atributos D54 e siglas D57: HP, MP, INI, ATQ F, DEF F, MAG, DEF M e CRI.
- Escalas vigentes (D59/D69): **HP, MP, ATQ F, DEF F, MAG e DEF M: aliados 0..999, monstros 1..9999**. **INI e CRI: 1..99 para ambos**. Ampliação dos monstros confirmada em 27/10/2026 para permitir grandezas maiores, inclusive chefes; não define valores por inimigo.
- Dano mínimo de 1 para um ataque que atinge alvo válido (D55).
- **D64:** armas somam bônus ao ATQ F próprio, armaduras à DEF F própria. D66 implementa campos próprios do aliado, bônus de arma/armadura e totais efetivos separados; monstros mantêm atributos diretos. Potência pertence à ação. Valores de itens e limites efetivos ainda a definir; ver seção 7.5 do `GDD.md`.
- Arma define chance e multiplicador de crítico; CRI do personagem influencia somente a chance, modificável por itens ou buffs mágicos (D56). **D63 confirmado:** 1 ponto de CRI = 1% de chance-base, somado à chance da arma e aos bônus de itens/buffs em pontos percentuais. Valores por arma/modificador e limites finais continuam pendentes.
- **D58, 26/10/2026:** oferecer ações em lotes de **10×, 100× e 1000×**, exibindo os resultados para comparação.
- Guia de Chrono Trigger guardado somente como referência, em [REFERENCIAS.md](REFERENCIAS.md).

## Equipamentos dos aliados — D64/D65/D66

**Autorizado e implementado:** arma/armadura somente no aliado. Monstros continuam com atributos diretos, sem slots. Inimigos humanos/humanoides equipados permanecem fora do recorte. As progressões são presets experimentais para comparação. **D67:** Madeira removida de armas e armaduras; bônus restantes deslocados uma posição para baixo, mantendo Bronze como primeiro material, com +10. As chances/multiplicadores críticos permanecem configuráveis como antes.

Na ficha do aliado, **ATQ F** e **DEF F** são os atributos próprios editáveis. Abaixo deles, a composição mostra `próprio + bônus = total`. O total entra na fórmula; a potência continua da ação. No monstro, ATQ F/DEF F são valores diretos. MAG, DEF M, HP/MP, INI e CRI não recebem bônus desses equipamentos.

A seção **Arma do aliado** identifica seu dono e se ele é atacante ou alvo. Permite escolher arma e editar bônus de ATQ F, chance e multiplicador de crítico. **Armadura do aliado** permite escolher armadura e editar bônus de DEF F. Sem arma/armadura, os bônus correspondentes são zero e ficam bloqueados para edição. Digitação, setas e controle continuam disponíveis nos campos editáveis; o painel rola por foco.

| Material de teste | Bônus da espada em ATQ F | Bônus da armadura em DEF F |
| --- | ---: | ---: |
| Bronze | 10 | 10 |
| Ferro | 16 | 16 |
| Aço | 24 | 24 |
| Mithril | 34 | 34 |
| Adamantio | 48 | 48 |
| Rúnica | 65 | 65 |

Os seis presets de espada começam com chance **5%** e multiplicador **2×**, editáveis. Esses valores mantêm a referência de crítico existente e **não aprovam uma progressão de crítico por material nem um multiplicador global**. Por solicitação do usuário, as opções antigas Arma de teste · 2× e Arma de teste · 3× foram removidas: o multiplicador já é editável no campo próprio. O caso padrão agora seleciona Espada de Bronze (+10 ATQ F) e começa sem armadura; atributos próprios permanecem iguais. Há também as opções Sem arma e Sem armadura. Catálogo independente em `data/damage_lab.json`.

Cada aliado guarda seu equipamento local na sessão. Ao trocar lados, arma e armadura acompanham o aliado: arma contribui ao atacar, armadura ao receber dano. Selecionar outra ficha recarrega seus atributos originais, como antes, mas permite retornar ao equipamento editado daquele aliado. **Restaurar caso** limpa os equipamentos locais e volta aos padrões; histórico anterior permanece imutável.

### Limites e críticos sem equipamento — parâmetros experimentais

Atributos próprios do aliado e bônus editáveis permanecem inteiros 0..999. Monstros usam os seis atributos grandes diretamente em **1..9999**, sem limite de equipamento do aliado. INI/CRI permanecem 1..99 em ambos. A soma efetiva do aliado neste laboratório é limitada a **999**, configurada em `effective_stat_limit`. Se a soma exceder, a prévia informa, por exemplo, `999 + 65 = 1064 → 999 (limite de teste)`. JSON mantém o total bruto, o efetivo e o limite aplicado. O limite definitivo dos modificadores do jogo continua pendente.

Monstros não recebem a arma do aliado: usam CRI próprio, sem bônus de chance de arma, e um **multiplicador próprio de teste**, inicialmente 2× e editável em Crítico próprio do monstro. O aliado Sem arma usa seu CRI próprio e multiplicador de teste do perfil, também inicialmente 2×, editável no campo de multiplicador. Itens/buffs numéricos da simulação continuam modificadores de chance do atacante. Esse tratamento permite testar sem inventar equipamentos para monstros; a regra final de crítico sem arma ainda não foi escolhida.

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

## Duelo e edição

- Um atacante e um alvo, sem ATB ou IA. Quatro fichas aliadas e quatro inimigas de teste: Pesado, Ágil, Voador e Estático. Qualquer lado pode atacar o outro; escolher duas fichas do mesmo lado ajusta a outra seleção para um perfil do lado oposto. Sem fogo amigo.
- Todos os atributos das duas fichas são editáveis nas faixas D59/D69, atualizadas ao selecionar ou inverter o participante: seis atributos 0..999 no aliado e 1..9999 no monstro, INI/CRI 1..99 em ambos. HP e MP representam os recursos iniciais/máximos da amostra. HP zero pode ser editado no aliado, mas impede executar; no monstro, mínimo inicial 1. HP/MP após a ação podem chegar a zero. MP insuficiente impede executar, sem consumir sorteios ou gerar resultado parcial. INI é informativa.
- **Refinamento solicitado em 26/10/2026:** digitação direta em todos os campos numéricos. Clicar no número seleciona o texto; selecionar o campo pelo teclado e começar a digitar também substitui o valor. Enter, Tab, clique em outro campo ou execução confirmam a edição, respeitando os limites existentes. Decimais aceitam ponto ou vírgula; setas/controle continuam disponíveis.
- Seletores de arma e ação; chance/multiplicador da arma, potência/custo de MP, permissão de crítico, variação e modificadores ajustáveis. Trocar lados mantém a ação e move o equipamento junto do aliado; o monstro usa seu próprio crítico de teste.
- **1×** mostra aproximação/impacto/retorno físico ou projétil mágico provisório; rótulos de recursos ficam na posição de origem. Lotes **10×, 100× e 1000×** calculam imediatamente e mostram o estado da última amostra, sem enfileirar animações.
- Toda edição é local à sessão. Arma/armadura são seleções do simulador; não há inventário da aventura, sistema de buffs real, persistência da sessão ou sincronização de fichas com a exploração.

## Fórmula proporcional v1 — experimento

```text
base física = potência × ATQ F² / (ATQ F + DEF F do alvo)
base mágica = potência × MAG² / (MAG + DEF M do alvo)
```

Potência é um **coeficiente**: 1,0× é a referência, 1,8× multiplica a base por 1,8. Ofensiva zero resulta em base zero, incluindo ofensiva/defesa ambas zero, evitando divisão por zero. Defesa zero preserva ofensiva × potência. Os outros atributos não interferem na família de dano escolhida.

Ordem experimental implementada:

1. Calcular base proporcional com os atributos correspondentes.
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

As ações iniciais são ataque físico **1× / 0 MP**, técnica física **1,8× / 4 MP** e magia **1,5× / 7 MP**. Potência pode variar 0..10×, custo 0..999 MP. Físicas permitem crítico inicialmente; magia não, mas a opção pode ser ligada para comparação. Fichas e valores em `data/damage_lab.json` são exemplos originais, sem classes, bestiário ou progressão aprovados. Nenhuma fórmula foi copiada automaticamente da referência de Chrono Trigger.

## Lotes, sequência e comparação

Cada amostra começa com **os mesmos HP/MP e condições**. Isso permite coletar 1000 ataques mesmo que um só golpe derrote o alvo ou gaste todo o MP. Não é uma simulação de 1000 turnos consecutivos de batalha.

Resumo com mínimo, máximo, média, médias normal/crítica, totais de dano/HP removido, quantidade e frequência observada de críticos e chance configurada. Histograma com até 12 intervalos, distinguindo danos normais e críticos. Aba **Amostras** exibe todas as ações e permite selecionar cada uma para decompor o cálculo. Aba **Condições** registra as fichas, arma, ação, modificadores, semente e início da sequência daquele resultado.

Há dois RNGs independentes, derivados da semente: variação e crítico. Cada ação avança ambos uma vez, inclusive nos modos fixos. Alterar a permissão de crítico não muda a sequência da variação. Ações e lotes sucessivos continuam a sequência; 10× + 10× equivalem às primeiras 20 amostras de uma execução maior iniciada na mesma semente. **Reiniciar sequência** volta ao primeiro sorteio sem mudar as fichas; alterar a semente também reinicia. A mesma configuração, semente e posição na sequência reproduzem o resultado na engine validada.

Histórico guarda até **12 execuções** com cópias das condições e estados de RNG. Editar o próximo caso não reescreve resultados anteriores. Consultar o histórico não aplica suas fichas ao próximo teste nem altera a sequência atual. **Restaurar caso** volta aos presets e semente iniciais, mantendo o histórico. Fechar o laboratório descarta a sessão.

## Exportar amostras em JSON — D61

**Confirmado e implementado em 26/10/2026.** Execute uma ação/lote, ou selecione um resultado no histórico, e use **Exportar JSON [F10]**, ao lado do seletor **Resultado**. Escolha pasta/nome e confirme **Salvar JSON**. O botão só fica disponível quando há resultado e a animação terminou. Cancelar não grava arquivo nem altera a sequência.

A pasta inicial é `exports/damage-lab/`, na raiz do projeto, criada ao abrir a exportação. Depois de salvar, o diálogo reutiliza a última pasta da sessão. O nome sugerido identifica execução, Seed e quantidade, por exemplo `danos-execucao-006-seed-421-1000x.json`. É possível escolher outro destino/nome; extensão `.json` é adicionada quando ausente. Se já existir, o diálogo pede confirmação de substituição. O caminho salvo aparece no rodapé. A pasta de saídas está ignorada pelo Git; não se confunde com dados de configuração.

O arquivo contém **todas as linhas daquela execução**, mesmo que só parte esteja visível na tabela. Exportar um resultado antigo usa sua cópia de condições e sorteios, mesmo depois de editar o próximo caso. Não executa novas ações, não muda o histórico nem avança o RNG. Exporta uma execução por arquivo; para comparar casos, selecione e exporte cada resultado desejado. Anexe o `.json` na conversa para análise.

Formato legível, UTF-8, com números sem arredondamento de apresentação e booleanos de crítico. Versão 2 acrescenta composição/equipamentos, preservando arquivos v1 anteriores:

| Campo | Conteúdo |
| --- | --- |
| `format` / `version` | Identificador `rpg.damage_lab.samples`, versão 2. |
| `exported_at_utc` / `engine_version` | Data UTC da exportação e versão da engine. |
| `formula` | Identificador `proportional_v1`, status experimental, fórmulas, ordem de cálculo, composição da chance, política de recursos por amostra e `attribute_ranges` com faixas por categoria/atributo. |
| `run` | Número da execução, Seed, primeiro/último índice global e estados dos dois RNGs antes/depois. Estados inteiros de 64 bits são **strings** para preservar os bits em leitores JSON/JavaScript. |
| `conditions` | Atacante/alvo efetivos, fichas próprias, equipamentos somente do aliado, composição de atributos, origem de crítico, ação e parâmetros originais. A Seed registrada é a usada na execução. |
| `summary` | Quantidade, mínimo/máximo/média, totais de dano e HP removido, frequência/contagem de críticos, médias por tipo, chance configurada e histograma. |
| `samples` | Todas as amostras, com índice local e global (`sequence_index`), atributos usados na base, sorteios/fatores, crítico/multiplicador, dano bruto/final, HP removido e HP/MP antes/depois. |

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
- Progressão, equipamentos, itens reais, buffs/duração, resistências, elementos, acerto/esquiva, cura e demais variáveis futuras não fazem parte deste recorte.
- Definir limites efetivos definitivos, crítico sem arma e valores por equipamento; escolhas atuais da composição são provisórias.
- Integrar o modelo aprovado ao combate da exploração em etapa posterior; INI/ATB e Battle Speed permanecem com as regras atuais.

Arquitetura: calculadora pura em `scripts/damage/damage_calculator.gd`; estado/histórico em `damage_lab_model.gd`; interface e visual separados em `scripts/ui/damage_*`. Testes `tests/damage_lab_tests.gd` e `tests/damage_lab_ui_smoke.gd`; comandos/resultados em [VALIDACAO.md](VALIDACAO.md).
