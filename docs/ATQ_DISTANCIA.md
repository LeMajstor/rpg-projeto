# ATQ D e DEF D — laboratório de danos

**Data:**28/10/2026. **Status:** autorizado e implementado por **D94**, após discussão P09/D93. Somente no laboratório de danos; números são parâmetros experimentais, sem progressão por nível ou alteração do combate integrado.

## Atributos e modalidade

| Modalidade | Ofensiva | Defesa do alvo |
| --- | --- | --- |
| Contato | ATQ F (`physical_attack`) | DEF F (`physical_defense`) |
| Disparos físicos | ATQ D (`ranged_attack`) | DEF D (`ranged_defense`) |
| Magia | MAG | DEF M |

A estrutura proporcional experimental permanece `potência × ofensiva² / (ofensiva + defesa)`, com variação, crítico, arredondamento, mínimo1 e esquiva nas regras anteriores. DEF D é proteção quando o disparo acerta; EVA continua sendo chance de evitar a ação. Não somar DEF F e DEF D num mesmo golpe. Distância não é fator baseado nas coordenadas nem altera animação, posicionamento ou mira.

Armas têm `attack_mode: melee/ranged` no catálogo: espada soma seu bônus somente em ATQ F; arco somente em ATQ D. A modalidade canônica não é inferida pelo nome do personagem nem pode ser trocada por metadados de uma cópia de arma.

Ações físicas têm `physical_mode`: `weapon` (padrão, arma do aliado ou contato para monstro), `melee` ou `ranged` (override explícito). A UI permite comparar as modalidades sem trocar fichas; magia sempre usa MAG/DEF M e desabilita esse seletor. O monstro usa atributos diretos, sem equipamento. Não foram criadas habilidades ou inimigos novos.

## Fichas pessoais iniciais após compatibilidade

**DEF D própria escolhida explicitamente pelo usuário:**45 para #1 e30 para #2, iguais às respectivas DEF F. ATQ D adota a referência experimental10/20 discutida; campos antigos mantêm os valores, inclusive ATQ F próprio20 do segundo. Equipamento permanece exclusivo por personagem.

| Campo | Aliado #1 | Aliado #2 |
| --- | ---: | ---: |
| ATQ F próprio | 23 | 20 |
| ATQ D próprio | 10 | 20 |
| DEF F própria | 45 | 30 |
| DEF D própria | 45 | 30 |
| ATQ F efetivo inicial | 33 | 20 |
| ATQ D efetivo inicial | 10 | 30 |
| DEF F efetiva inicial | 55 | 35 |
| DEF D efetiva inicial | 50 | 40 |

O primeiro aliado continua com espada/Bronze, segundo com arco/traje inicial. Ter ATQ D não libera arco para #1. O Monstro #1 pessoal recebe ATQ D24/DEF D40 por compatibilidade com seus atributos físicos anteriores. Com o mesmo par ofensiva/defesa e sorteios, preservam-se os danos anteriores: #1 normal13–16/crítico27–33, #2 normal12–14/crítico19–23, contato inimigo normal7–8/9–11.

## Proteções — prioridades e tabela implementadas

| Estágio | Metal DEF F + | Metal DEF D + | Traje DEF F + | Traje DEF D + |
| --- | ---: | ---: | ---: | ---: |
| 1 | 10 | 5 | 5 | 10 |
| 2 | 16 | 8 | 8 | 16 |
| 3 | 24 | 12 | 12 | 24 |
| 4 | 34 | 17 | 17 | 34 |
| 5 | 48 | 24 | 24 | 48 |
| 6 | 65 | 33 | 33 | 65 |

Metal prioriza DEF F; couro DEF D. A proporção aproximada2:1 foi adotada para este teste. Cada proteção fornece os dois bônus no mesmo slot; trajes mantêm EVA+5. A prioridade do item não garante que #2 tenha DEF D total maior: com as bases escolhidas, o primeiro ainda tem50 contra40 inicialmente. Não define defesa mágica nem bônus de INI.

Os campos próprios de distância usam as faixas grandes já existentes: aliados0..999, monstros1..9999; HP inimigo continua1..99999, demais escalas preservadas. Bônus de DEF D da proteção0..999. Totais aliados limitados ao `effective_stat_limit` experimental999, mantendo soma bruta no histórico/JSON. Monstros não recebem limite de equipamento aliado.

## Presets e compatibilidade

A biblioteca continua no formato de presets versão1, com campos aditivos e atualização em cópia ao ler:

- ATQ D ausente: #1 recebe10 por configuração do personagem; #2 e monstro reaproveitam o próprio ATQ F antigo, preservando bônus separados.
- DEF D ausente: copiar DEF F própria, conforme escolha do usuário; não copiar o total equipado.
- Modalidade de arma ausente e bônus DEF D de proteção ausente: buscar no catálogo canônico pelo ID. Valores novos já presentes e editados não são sobrescritos.
- Valores antigos, bônus personalizados, IDs, revisões e arquivo original são preservados na leitura. Salvar/Atualizar gravam normalmente os campos novos. Não há reimportação automática ou troca de equipamento.

Os arquivos JSON antigos não são reescritos. Novas exportações são **versão4**: incluem os novos atributos, composição, modalidade escolhida e `damage_stats`; cada amostra informa `base.attack_stat/defense_stat`. Fórmula de disparo e seleção dos atributos documentadas no relatório. Não mudam os três fluxos RNG ou seu consumo por amostra.

## Verificação

Testes específicos `damage_distance_tests.gd` e `damage_distance_ui_smoke.gd`: isolamento dos três pares, modos automáticos/explícitos, bônus independentes, limites, zeros, valores inválidos, compatibilidade, persistência, histórico e JSON. Suítes anteriores também aprovadas; ver `VALIDACAO.md`.

`artifacts/damage-lab-distance/verify_existing.gd` reabriu os três presets pessoais sem gravar e reproduziu4000 amostras dos quatro relatórios anteriores com os mesmos sorteios, sem diferença em dano/crítico/esquiva/HP/MP. Níveis, novas ações de distância e balanceamento definitivo permanecem para outro passo.

## Conferência manual

Reabrir o laboratório e carregar cada preset. Os campos ATQ D/DEF D aparecem nas duas fichas e DEF D+ nas proteções. Com #2 carregado, a arma mostra ATQ D+; a prévia indica ATQ D/DEF D. Selecionar Corpo a corpo/Distância no painel da ação compara os pares; escolher magia volta a MAG/DEF M. Histórico e JSON mostram a fonte realmente usada, preservando as condições da execução.
