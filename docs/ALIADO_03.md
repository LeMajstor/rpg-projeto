# Terceiro aliado — preset de mago do laboratório

**Data:** 01/11/2026. **Status:** criado e cadastrado por D115, após autorização do usuário para implementar a ficha e os equipamentos discutidos em P13/P14. Números adotados para teste, sem fechar balanceamento ou progressão definitivos. Preset pessoal **Aliado #3 — Mago**; definição reproduzível em `data/damage_lab_ally_03.json`.

## Direção confirmada — D112/D114

MAG 30 e DEF M 30 são naturais, antes de equipamentos. O mago é fisicamente frágil, depende do apoio dos aliados e pode recorrer a buffs de magia e itens para proteção física. HP, EVA, VIG, INI e defesas físicas menores que os dos dois aliados atuais. INI7 e DEF F/DEF D16 adotadas para o teste dentro das referências indicadas pelo usuário. As vestes priorizam proteção mágica e preservam vulnerabilidade física relativa.

Quais proteções existirão, seus efeitos, custos, duração e acúmulo ainda serão definidos; nenhum buff, item de proteção ou ação de apoio foi criado nesta entrega. Nome e geometria são provisórios, sem definir classe/raça ou identidade narrativa definitivas.

## Atributos naturais adotados — P14/D115

| Atributo natural | Aliado #1 | Aliado #2 | Mago |
| --- | ---: | ---: | ---: |
| HP | 40 | 36 | 30 |
| MP | 12 | 14 | 24 |
| INI | 9 | 11 | 7 |
| ATQ F | 23 | 20 | 12 |
| ATQ D | 10 | 20 | 8 |
| DEF F | 45 | 30 | 16 |
| DEF D | 45 | 30 | 16 |
| MAG | 20 | 20 | 30 |
| DEF M | 21 | 21 | 30 |
| INT | 20 | 20 | 25 |
| VIG | 25 | 20 | 15 |
| CRI | 5 | 7 | 3 |
| EVA | 5 | 7 | 3 |

MP24 permite seis tentativas de aflição de4MP numa sequência com consumo normal, mas o laboratório restaura recursos por amostra e não mede autonomia. INT25 diferencia a resistência mental da corporal VIG15; DEF M efetiva compõe ambas.

## Equipamento inicial

- **Cajado de Madeira:** MAG+10, ATQ F+2, chance crítica adicional0p.p., multiplicador físico1,5× (D118).
- **Veste Simples:** DEF M+10, DEF F+2, DEF D+2, sem bônus de EVA.
- Totais iniciais: **MAG40, DEF M40, ATQ F14, ATQ D8, DEF F18, DEF D18, EVA3%**.
- Chance crítica física total3%, da CRI própria; magias/aflições não têm crítico. Ataque básico é físico de contato e não consome MP.

Seis cajados e seis vestes exclusivos de `ally_3`; escala em [ESCALA_CAJADOS_E_VESTES.md](ESCALA_CAJADOS_E_VESTES.md). Os dois slots são obrigatórios. Troca de equipamento, inversão dos lados, salvar/reabrir e JSON mantêm atributos naturais, bônus e totais separados.

## Uso e persistência

Abra `Executar laboratorio de danos.command`, escolha **Aliado #3 — Mago** no seletor de presets do aliado e clique em Carregar. Carregue Monstro #1 no outro seletor. MAG/DEF M naturais aparecem na ficha; composição mostra30+10=40. Role o editor para selecionar equipamentos ou editar MAG+/DEF M+.

O cadastro foi realizado uma vez na biblioteca pessoal, com backup e preservação integral dos três registros anteriores, inclusive IDs/revisões. Reabrir o laboratório não reinstala o preset nem desfaz alterações/exclusões feitas pelo usuário. Receita disponível no repositório; instalador explícito `scripts/tools/install_mage_preset.py` recebe `--library` e `--backup-dir`, não sobrescreve preset existente e verifica mudanças concorrentes antes de gravar.

## Verificação

21 suítes headless: **34.597 verificações, zero falhas**. Nova suíte verifica36 pares de equipamentos, composição mágica/física, limites, exclusividade, entradas inválidas, persistência, inversão, histórico e reprodução das16.000 amostras anteriores na precisão dos relatórios. Teste gráfico Compatibility:20 verificações, três capturas inspecionadas, zero falhas.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-test.log --path . --script res://tests/damage_mage_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-mage-ui-test.log --path . --script res://tests/damage_mage_ui_smoke.gd
```

Bateria de aflições:120 mil tentativas,24 casos×5 sementes×1.000 amostras. [Análise e reprodução](../artifacts/aflicoes-mago-2026-11-01/analise.md); demais evidências em [VALIDACAO.md](VALIDACAO.md). ATB, efeitos/duração das aflições, progressão, inventário e combate integrado permanecem fora desta implementação.


## Comparação defensiva de aflições — D116

Os dois primeiros aliados normalmente não usam magias; exceções por condições/itens especiais são futuras. A bateria focada usa apenas Monstro #1 como conjurador e os três aliados como alvos, preservando fichas e equipamentos iniciais. Foram executadas 60 mil tentativas, com aplicação observada no mago de 30,56% para Veneno/Lentidão e 26,94% para Confusão/Medo. Sua DEF M efetiva 40 compensa VIG 15/EVA 3% menores; INT 25 amplia a resistência mental. [Comparação completa e reprodução](../artifacts/monstro-aflicoes-tres-aliados-2026-11-01/analise.md). Nenhum efeito contínuo foi executado.


## Revisão do crítico — D118, 01/11/2026

Os seis cajados usam multiplicador físico **1,5×**. Chance adicional 0 p.p., CRI própria 3 e todos os demais atributos/bônus preservados. Cajado inicial contra Monstro #1: normal **3–4**, crítico **5–6**. Receita e catálogo atualizados; preset pessoal do mago passou da revisão 1 para 2, com alteração exclusiva do multiplicador e revisão. IDs, demais campos e três presets anteriores preservados, com backup e reabertura validados. Magias/aflições produzem as mesmas amostras; resultados históricos anteriores permanecem com suas condições originais.

Duas suítes executadas: `damage_mage_tests.gd` (17.300 verificações) e `damage_mage_ui_smoke.gd` (18), zero falhas. Evidências em `artifacts/damage-lab-staff-critical/`.


## Fragilidade física medida — D119, 01/11/2026

Monstro #1 (ATQ F/ATQ D 24, CRI 3%, multiplicador físico 2×) contra equipamentos iniciais do mago: HP 30, DEF F/DEF D 18, EVA 3%. Cinco sementes, 5.000 golpes por modalidade e 5.000 sequências acumuladas em cada condição (somente normais; críticos/esquivas reais). Contato e distância são iguais neste caso e compartilham sorteios, sem serem evidência estatística independente.

- Dano normal **12–15**, crítico **25–30**, média por tentativa **13,736**, incluindo esquivas e críticos.
- Sem crítico/esquiva, **três acertos normais em 95,36%** das sequências, **dois em 4,64%**.
- Com críticos/esquivas, **2,9768 tentativas médias** até 0 HP. Em **21/5.000 sequências (0,42%)**, o primeiro ataque foi crítico letal; probabilidade teórica aproximada 0,36%.
- Observador acumula dano até a incapacitação, sem cura/buffs/ATB ou ações dos aliados; o lote de golpes isolados restaura recursos por amostra.

Nenhuma ficha/fórmula alterada. [Comparação com os outros aliados, dados e reprodução](../artifacts/monstro-fisico-tres-aliados-2026-11-01/analise.md). Essa é a referência para avaliar o próximo inimigo; fragilidade não fixa automaticamente quantos golpes ou críticos futuros o mago deve suportar.


## Magia ofensiva básica adotada — D124

Referência V1 explícita: potência1,5×, custo7MP, MAG contra DEF M, sem crítico/EVA. Com MAG40 contra DEF M28 dos inimigos atuais, dano32–39 e dois usos/14MP para vencer; MP24 permite três usos. O antigo rótulo `Magia · teste` passa para **Magia ofensiva básica**, preservando ID. Esses números foram escolhidos pelo usuário em01/11/2026; antes eram um exemplo genérico. [Regras fechadas da V1](DANOS_ATRIBUTOS_EQUIPAMENTOS_V1.md).
