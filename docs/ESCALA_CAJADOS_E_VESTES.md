# Escala de cajados e vestes — laboratório de danos

**Data:** 01/11/2026. **Status:** P13 adotada e implementada por D115, após autorização do usuário. Seis cajados e seis vestes exclusivos do mago, somente no laboratório de danos. Nomes e números experimentais para testes, sem balanceamento definitivo.

## Direção e composição

MAG30/DEF M30 são naturais (D112); equipamentos somam bônus separados. Seis estágios correspondem à quantidade das demais famílias; isso não garante equivalência de dano físico/mágico. Só o item equipado em cada slot contribui, sem acumular estágios anteriores. D114 mantém fragilidade física relativa e prioriza proteção mágica.

## Escala adotada — P13/D115

| Estágio | Cajado | MAG + | ATQ F + | Veste | DEF M + | DEF F + | DEF D + |
| --- | --- | ---: | ---: | --- | ---: | ---: | ---: |
| 1 | Cajado de Madeira | 10 | 2 | Veste Simples | 10 | 2 | 2 |
| 2 | Cajado de Carvalho | 16 | 3 | Veste Costurada | 16 | 3 | 3 |
| 3 | Cajado de Freixo | 24 | 5 | Veste Bordada | 24 | 5 | 5 |
| 4 | Cajado de Teixo | 34 | 7 | Veste Encantada | 34 | 7 | 7 |
| 5 | Cajado Ancestral | 48 | 10 | Veste Arcana | 48 | 10 | 10 |
| 6 | Cajado Rúnico | 65 | 13 | Veste Rúnica | 65 | 13 | 13 |

MAG/DEF M totais com próprios30: **40/46/54/64/78/95**. DEF F/DEF D totais com próprios16: **18/19/21/23/26/29** cada. ATQ F total com próprio12:14/15/17/19/22/25. EVA/VIG/INI/INT/HP/MP não recebem bônus dessas famílias. Nomes não concedem efeitos adicionais.

Todos os cajados têm chance crítica adicional0p.p. e multiplicador físico1,5× (D118). CRI própria3 dá3% nos golpes físicos. Cajado é arma de contato; não transforma ataque físico básico em magia gratuita. Magias e aflições não têm crítico e conservam custos da ação.

## Implementação e compatibilidade

Dados em `data/damage_lab.json`; identidade estável `ally_3`; receita inicial em `data/damage_lab_ally_03.json`. Famílias anteriores conservam dados e permissões. Catálogo tem18 armas/18 proteções no total, com seis opções por slot para cada aliado.

Composição usa `weapon.magic_attack_bonus` e `armor.magic_defense_bonus`; ausência significa zero nos equipamentos legados. Valores inteiros0..999, com limite efetivo999 e soma bruta preservada. Bônus mágicos não nulos só são aceitos em itens cujo catálogo oferece esse campo; não basta forjar metadados. Interface permite edição nas famílias compatíveis e mostra próprios/bônus/totais. Presets conservam formato v1; exportação JSONv5 recebe campos aditivos e descrição da composição mágica, mantendo fórmulas de dano/aflição e RNG anteriores.

Instalação explícita uma vez na biblioteca pessoal, sem importação automática ao iniciar, mudança dos outros presets, níveis, inventário ou migração ao combate da exploração. Apoio dos aliados e buffs/itens protetores de D114 permanecem direção futura, sem novos efeitos nesta entrega.

## Verificação

`tests/damage_mage_tests.gd` cobre36 combinações, seleção independente dos estágios, composição, limite, dados inválidos, exclusividade, recarga, inversão, cálculo de aflições e reprodução do estudo anterior. `tests/damage_mage_ui_smoke.gd` verifica seletores, edição por teclado, composição, histórico/JSON, persistência e famílias legadas.21 suítes headless aprovadas; teste gráfico com três capturas inspecionadas. Detalhes e comandos em [ALIADO_03.md](ALIADO_03.md) e [VALIDACAO.md](VALIDACAO.md).

Bateria de aflições usa o primeiro par. Estágios superiores foram verificados funcionalmente, mas seu balanceamento exige referências próprias de futuros atributos/inimigos.


## P15/D118 — revisão do crítico adotada

Em 01/11/2026, usuário autorizou a troca de **2× para 1,5× nos seis cajados**, mantendo bônus de chance 0 p.p. e CRI própria 3. Contra Monstro #1 (DEF F 40), ATQ F 14/potência 1/variação ±10%: normal 3–4 e crítico 5–6, verificados na calculadora Godot. Receita/catálogo e preset pessoal atualizados; mago revisão 2, com demais campos e presets preservados. Magias/aflições continuam sem crítico e reproduzem as mesmas amostras. Históricos anteriores conservam multiplicador e revisão originais.
