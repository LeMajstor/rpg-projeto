# Monstro #1 — dano físico nos três aliados — 01/11/2026

**Executado:** 30.000 ataques individuais e 60.000 sequências de dano acumulado, com zero falhas/divergências. Nenhum atributo, equipamento, preset ou fórmula foi alterado. Monstro #2 permanece apenas proposta.

## Condições e método

- Monstro #1: ATQ F 24, ATQ D 24, CRI 3%, multiplicador físico 2×. Ataque básico de potência 1, custo 0 MP, variação uniforme ±10%, esquiva habilitada.
- Três aliados com equipamentos iniciais: #1 HP 40/DEF F 55/DEF D 50/EVA 5%; #2 HP 36/DEF F 35/DEF D 40/EVA 12%; mago HP 30/DEF F 18/DEF D 18/EVA 3%.
- Contato usa ATQ F/DEF F; distância usa ATQ D/DEF D pelo override já existente no laboratório, sem criar ação inimiga nova.
- Cinco sementes iguais entre casos: 421, 733, 112, 2026, 31415. Cada um dos seis casos recebeu 5.000 golpes e duas condições de 5.000 sequências até 0 HP.
- Nos golpes individuais, o laboratório restaura HP/MP por amostra. Para sobrevivência, um observador separado acumula `damage` em HP local e encerra a sequência no primeiro 0 HP. A próxima começa com HP cheio. Sem cura, buffs, ações dos aliados, ATB, seleção de alvos ou efeitos contínuos.
- Diagnóstico normal: crítico desligado/esquiva desabilitada para contar acertos normais necessários. Condição mista: críticos 3% e EVA real habilitados, contando todas as tentativas, inclusive esquivas.
- Fluxos RNG continuam entre buffers de mil amostras. Amostras não usadas no último buffer são explicitamente contabilizadas; hashes e estado final referem-se ao buffer completo. Cada sequência guarda passos (variação, sorteio crítico, sorteio EVA, dano, crítico, esquiva), auditados independentemente em Python.
- Sorteios compartilhados permitem comparação pareada; não tratar repetições entre casos como observações estatisticamente independentes.

## Dano por tentativa

As faixas abaixo são limites da fórmula com variação; a média observada inclui dano normal, crítico e zeros de esquiva. Cada linha corresponde a 5.000 tentativas.

| Ataque | Alvo | Normal | Crítico | Média recebida | Esquivas | Críticos |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Contato | Aliado #1 | 7–8 | 13–16 | 7,20 | 247 | 141 |
| Contato | Aliado #2 | 9–11 | 18–21 | 8,84 | 597 | 132 |
| Contato | Aliado #3 — Mago | 12–15 | 25–30 | 13,74 | 140 | 144 |
| Distância | Aliado #1 | 7–9 | 14–17 | 7,56 | 247 | 141 |
| Distância | Aliado #2 | 8–10 | 16–20 | 8,16 | 597 | 132 |
| Distância | Aliado #3 — Mago | 12–15 | 25–30 | 13,74 | 140 | 144 |

## Até a incapacitação

Resultados de 5.000 sequências por linha/condição. Acertos normais excluem crítico/esquiva; tentativas mistas incluem ambos. Médias não foram estimadas dividindo HP pelo dano médio: houve acumulação e encerramento no primeiro 0 HP. A teoria usa distribuição exata da variação arredondada e programação dinâmica.

| Ataque | Alvo | Acertos normais para cair | Distribuição normal observada | Tentativas mistas médias (teoria) |
| --- | --- | ---: | --- | ---: |
| Contato | Aliado #1 | 5–6 | 5: 0,62%; 6: 99,38% | 6,16 (6,16) |
| Contato | Aliado #2 | 4 | 4: 100,00% | 4,44 (4,45) |
| Contato | Aliado #3 — Mago | 2–3 | 2: 4,64%; 3: 95,36% | 2,98 (2,98) |
| Distância | Aliado #1 | 5–6 | 5: 23,16%; 6: 76,84% | 5,92 (5,92) |
| Distância | Aliado #2 | 4–5 | 4: 64,24%; 5: 35,76% | 4,83 (4,84) |
| Distância | Aliado #3 — Mago | 2–3 | 2: 4,64%; 3: 95,36% | 2,98 (2,98) |

## Leitura dos resultados

O mago é o mais frágil fisicamente nas duas modalidades. DEF F/DEF D e HP baixos pesam mais que a proteção mágica, que não participa desses golpes. Contato e distância produzem os mesmos resultados no mago porque o inimigo tem ATQ F/ATQ D iguais e a veste dá defesas físicas iguais. Essas duas linhas não são evidências estatísticas independentes.

Com HP 30, o mago caiu em três acertos normais em 95,36% das sequências e em dois em 4,64%. Com críticos/esquivas, média 2,98 tentativas. Um crítico pode causar 30 e derrubá-lo com HP cheio: 21 de 5.000 sequências terminaram já na primeira tentativa (0,42%); probabilidade teórica 0,36%. Foram 21 sequências encerradas no primeiro acerto, incluindo casos com esquivas antes dele.

O primeiro aliado segue como o mais resistente. O traje do segundo favorece disparos: recebe menos dano de distância que de contato. Isso não o torna mais resistente que o primeiro, cujos HP e defesas totais continuam maiores.

**Recomendação:** usar esta bateria como referência antes de adotar P16. A ficha atual do mago já permite uma queda rara por crítico do Monstro #1; a proposta de ATQ F 27 tornaria o risco maior. Definir a tolerância desejada antes de cadastrar Monstro #2. Nenhum ajuste automático foi realizado.

## Evidência e reprodução

Godot: 327205 verificações, zero falhas. Auditoria Python: 768516, zero divergências; cada passo das sequências acumuladas recalculado. A distribuição teórica foi calculada separadamente, sem substituir a simulação executada.

Na raiz do projeto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/rpg-physical-three.log --path . --script res://artifacts/monstro-fisico-tres-aliados-2026-11-01/executar.gd
python3 artifacts/monstro-fisico-tres-aliados-2026-11-01/analisar.py
```

A execução usa os presets pessoais vigentes e verifica preservação integral do arquivo; a auditoria usa relatórios congelados. `execucao.json` registra presets, sementes, relatórios e hash. Arquivos `*-survival-normal.json`/`*-survival-mixed.json` guardam a observação acumulada, não batalhas com ATB.
