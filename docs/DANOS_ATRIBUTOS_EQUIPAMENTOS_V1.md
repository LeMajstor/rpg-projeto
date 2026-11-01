# Danos, atributos e equipamentos — referência V1

**Data:** 01/11/2026. **Status:** **laboratório de danos V1 finalizado e aceito pelo usuário (D125)**, após as escolhas D123/D124, a verificação final e a discussão do balanceamento. Identificador `damage_lab_v1`, versão 1, decisão D124. As regras de cálculo e a referência inicial abaixo estão adotadas para esta versão; o balanceamento da aventura poderá ser revisado com novos inimigos, progressão e testes temporais.

Não há pendência que impeça o fechamento desta primeira versão. Avaliações adicionais pertencem a etapas futuras.

A exploração e o combate integrado conservam seus cálculos anteriores. Este fechamento não migra automaticamente fichas, equipamentos ou fórmulas para eles.

**Etapa posterior autorizada — D126:** a primeira integração ao laboratório de batalha independente foi implementada com três aliados, dois monstros, básicos físicos, magia ofensiva do mago e preparação de equipamentos. Compartilha este cálculo sem alterar a referência. Aflições ficam para a segunda parte; exploração permanece fora da migração. Roteiro em [BATALHA_DANOS_V1.md](BATALHA_DANOS_V1.md).

## Magia ofensiva básica — D123/D124

| Propriedade | Referência adotada |
| --- | --- |
| Nome técnico | Magia ofensiva básica |
| ID preservado | `magic_skill` |
| Referência de usuário normal | Aliado #3 — Mago |
| Alvo no laboratório | Um inimigo |
| Ofensiva/defesa | MAG contra DEF M |
| Potência | **1,5 ×** |
| Custo | **7 MP por uso** |
| Crítico | **Não permite**, inclusive no modo forçado |
| Esquiva por EVA | **Não permite**, inclusive se uma configuração antiga ligar a permissão |
| Variação | ±10% |
| Efeito | Dano direto, sem aflição/efeito secundário |

Com MAG efetiva 40 contra DEF M 28 dos dois inimigos atuais: **32–39 de dano**, dois usos para derrotar HP 40/45, gastando 14 MP. MP 24 permite três usos, sobrando 3 MP. O gasto é relevante e o dano supera os básicos físicos das referências atuais. Esses resultados não definem nome temático, elemento, animação artística ou outras magias da aventura.

A antiga `Magia · teste` existia como parâmetro experimental desde D 60 (documentado em 26/10 e registrado no Git em 27/10). **D124 é a adoção explícita** de 1,5 ×/7 MP nesta V1. A alternativa 1,2 ×/6 MP foi estudada, mas não adotada. Os estudos históricos conservam suas condições originais.

## Fórmula e ordem do dano — D124

```text
base = potência × ofensiva² / (ofensiva + defesa)
resultado = base × variação × multiplicador crítico quando permitido
dano = máximo(1, arredondar resultado ao inteiro mais próximo)
```

- Contato físico: ATQ F contra DEF F. Distância física: ATQ D contra DEF D. Magia direta: MAG contra DEF M.
- Variação uniforme de 0,9 a 1,1. Crítico apenas físico; aplicar multiplicador antes de arredondar. No domínio não negativo de dano, empate em 0,5 arredonda para cima.
- Ofensiva zero produz base zero; um acerto ainda causa o mínimo 1. Defesas físicas não se somam, e INT/VIG não entram no dano mágico direto.
- Esquiva de ação elegível gera dano zero, sem crítico ou mínimo 1. Ataques básicos custam 0 MP; habilidades consomem o custo da ação mesmo quando evitadas ou resistidas.
- Dano bruto e HP efetivamente removido ficam separados: remoção limitada ao HP restante. HP 0 é incapacitação; MP insuficiente impede execução sem consumir sorteios.

## Aflições — aplicação/resistência

| Magias | Resistência específica | Custo por tentativa |
| --- | --- | ---: |
| Veneno/Lentidão | VIG | 4 MP |
| Confusão/Medo | INT | 4 MP |

```text
chance após superar EVA (%) = 100 × MAG / (MAG + DEF M + resistência específica)
chance total por tentativa (%) = (1 − EVA/100) × chance após superar EVA
```

As quatro referências atuais permitem EVA antes da resistência. Se houver esquiva, o teste de resistência não é realizado. Caso contrário, aplicar a fórmula sem piso/teto adicionais; a soma DEF M+INT/VIG não recebe teto próprio. Esquivou, Resistiu e Aplicou são resultados distintos. Sem dano direto, crítico ou dano mínimo nessas ações. Duração, cura, acúmulo, ticks e execução dos efeitos ainda são futuros.

## Atributos e composição

13 atributos: **HP, MP, INI, ATQ F, DEF F, ATQ D, DEF D, MAG, DEF M, INT, VIG, CRI e EVA**. Próprios, bônus, soma bruta e efetivo separados; totais equipados não viram base.

| Grupo | Aliados | Inimigos |
| --- | --- | --- |
| HP | 0..999 | 1..99999 |
| MP, ATQ F/D, DEF F/D, MAG, DEF M próprios/diretos | 0..999 | 1..9999 |
| INI e CRI próprios | 1..99 | 1..99 |
| INT e VIG próprios/diretos | 1..999 | 1..999 |
| EVA própria | 0..100 | 0..100 |

São as faixas operacionais existentes nesta referência. Configuração de lote requer participantes com HP maior que zero. Totais aliados usam o limite operacional 999, preservando a soma bruta; EVA efetiva usa 0..100. Inimigos têm atributos diretos, sem equipamento. Limites futuros de buffs, progressão e balanceamento de níveis não são definidos por essas faixas.

INI base não cresce naturalmente por nível; EVA admite a direção de crescimento lento D 95, sem curva implementada. INT/VIG têm crescimento por nível definido no desenho, sem ganhos/curvas implementados. O laboratório não mede o ATB temporal.

## Equipamentos e crítico

Três aliados e dois inimigos de teste. Catálogo com seis espadas/seis armaduras de metal, seis arcos/seis trajes leves, seis cajados/seis vestes. Dois slots obrigatórios por aliado, famílias exclusivas por identidade. Só os itens equipados contribuem, sem acumular estágios anteriores.

- Espada contribui em ATQ F; arco em ATQ D; cajado em ATQ F e MAG. Proteções contribuem somente nos campos que o item oferece: DEF F, DEF D, DEF M e/ou EVA.
- Chance crítica física:1 CRI=1%, somada aos bônus configurados, limitada a 0..100%. Bônus de chance não alteram o multiplicador. Campos numéricos de item/buff do laboratório não implementam itens ou magias na aventura.
- Multiplicadores de referência atuais: **espada 2 ×, arco 1,6 ×, cajado 1,5 ×**. Arma define multiplicador do aliado; monstro usa o direto próprio. Magia/aflição nunca têm crítico.
- MAG 30/DEF M 30 do mago são naturais; o primeiro cajado/veste somam 10 cada, dando 40/40. DEF F/DEF D naturais 16 chegam a 18/18.

Fichas e tabelas: [Aliado #2](ALIADO_02.md), [Mago](ALIADO_03.md), [Monstro #2](MONSTRO_02.md), [Arcos/trajes](ESCALA_ARCOS_E_TRAJES.md), [Cajados/vestes](ESCALA_CAJADOS_E_VESTES.md), [Contato/distância](ATQ_DISTANCIA.md). Estágios superiores têm verificação funcional; seu balanceamento exige referências futuras de inimigos/progressão.

## Repertórios e ferramenta

#1/#2 normalmente não usam magia; exceções são futuras. Mago é a referência mágica. Monstro #2 tem apenas básico físico à distância, com política canônica no tipo. A ferramenta genérica preserva comparações hipotéticas dos tipos legados; isso não concede habilidades da aventura.

`Técnica física · experimento` (1,8 ×/4 MP) continua explicitamente experimental: não define uma técnica individual aprovada. Preservam-se IDs para compatibilidade. A interface distingue referência V1 e experiências por rótulos/tooltips; condições/JSON registram regras de origem e valores efetivamente usados. Editar parâmetros na ferramenta não altera automaticamente os padrões aprovados. Relatórios anteriores permanecem intactos.

Lotes restauram HP/MP por amostra. Observadores acumulados começam com HP/MP cheios e param na primeira incapacitação, sem cura/buffs/respostas dos aliados; não representam combate completo. Na aventura, HP/MP persistem entre batalhas conforme as regras já aprovadas.

## Validação do fechamento

- **25 suítes headless,35.706 verificações, zero falhas.** Incluem 1020 novas verificações da referência e 11 da interface.
- **Teste gráfico Compatibility:12 verificações, uma captura inspecionada, zero falhas.** Confirma nome/potência/custo e ausência de crítico/EVA na magia direta; aflições conservam EVA.
- Calibração das alternativas:20 mil tentativas,40.087 verificações Godot e 8.020 na conferência independente, zero falhas/divergências. A escolhida é A:1,5 ×/7 MP.
- Regressões preservam equipamentos, atributos, tipos de ataque, aflições, cinco presets, histórico, limites e RNG. Há cobertura de EVA 100, flags antigas, crítico forçado, MP insuficiente e arredondamento final.

Evidências em `artifacts/damage-v1-final/` e `artifacts/refino-magia-v1-2026-11-01/`. Snapshot da referência e hashes em `artifacts/damage-v1-final/reference-manifest.json`.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-v1-reference.log --path . --script res://tests/damage_v1_reference_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-v1-reference-ui.log --path . --script res://tests/damage_v1_reference_ui_smoke.gd
```

## Futuro/fora deste fechamento

Integração ao combate da exploração; ATB/INI temporal e avaliação de lutas completas; duração/efeitos de aflições; buffs/itens protetores do mago; inventário/obtenção/economia; níveis/XP/curvas; novas técnicas físicas, elementos e catálogo de magias; arte e animação definitivas. Não são pendências do fechamento laboratorial desta V1.
