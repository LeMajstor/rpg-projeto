# Paridade entre laboratório de danos e laboratório de combate

**D148 — autorizado e implementado em 15/11/2026.** O usuário solicitou levantar todas as alterações do laboratório de danos e aplicá-las ao laboratório de combate, para depois atualizar o combate da exploração com o mesmo conjunto de regras. As fontes atuais são compartilhadas; relatórios históricos continuam como evidência das etapas anteriores.

## Levantamento e resultado

O fluxo permanente para futuras alterações está na seção D150 ao final deste documento.

| Alteração aprovada | Fonte comum / resultado no combate |
| --- | --- |
| Treze atributos e faixas próprias de aliados/inimigos | `damage_calculator.gd`, `damage_equipment.gd`; cinco fichas aprovadas em `damage_reference_profiles.json`. |
| Três aliados: espada, arco e mago; dois monstros | Fonte única acessível nas duas ferramentas; referências pessoais existentes conferidas em leitura, sem alterar a biblioteca. Não inventa quarto aliado. |
| Seis estágios por família, dois slots e exclusividade | Catálogo de `damage_lab.json`, mesmo resolvedor e preparação de equipamentos no combate. Naturais e bônus permanecem separados. |
| ATQ F/DEF F e ATQ D/DEF D | Mesmo cálculo e modalidade da arma; arco e Monstro #2 não se aproximam para atacar. |
| Fórmula proporcional, variação ±10%, arredondamento e mínimo 1 | Impacto usa a mesma função `damage_calculator.sample`; não existe fórmula paralela no cenário atual. |
| Esquiva física, CRI própria + arma e multiplicadores | Mesmas fontes de EVA/CRI/equipamento; espada 2×, arco 1,6×, cajado 1,5×. |
| Magia ofensiva básica | Mesma ação de 1,5×/7 MP, MAG contra DEF M, sem esquiva ou crítico. |
| INT/VIG e aplicação das quatro aflições | Mesmas ações de 4 MP, EVA anterior e `100 × MAG / (MAG + DEF M + VIG/INT)`, sem piso/teto artificial. Esquivou/Resistiu/Aplicou separados. |
| Veneno temporal D127–D132 | 5% do HP máximo por tick, 5 s no Battle Speed 4, proporção por velocidade, mínimo 1, pausa em Wait/pausa manual/animações; pode incapacitar. |
| Lentidão D133–D135 | Metade da INI natural, inteiro com 0,5 para cima, depois modificadores; EVA natural zerada, bônus preservados inclusive quando a soma anterior estava saturada. Cura não altera carga parcial/pronta. |
| Confusão D137 | Ataque básico automático sem MP, alvo uniforme entre os demais vivos de ambos os lados, sem si próprio. Dano recebido não cura. |
| Medo D138–D146 | Comandos/ATB/rota bloqueados e retomados do estado exato; proteção de ao menos um aliado vivo, liberação por maior INT/ordem da equipe; recuperação por dano direto com fórmula aprovada; derrota da origem remove seus efeitos. |
| Uma aflição por alvo D144/D145 | Tentativa em alvo afetado gasta ação/MP sem substituir, renovar ou reiniciar estado/origem. |
| Cura, término de batalha e reviver | Remédio remove o estado e seus efeitos derivados no impacto; vitória, fuga e derrota limpam aflições sem curar HP/MP. O mecanismo de reviver limpa estado, mas nenhum recurso jogável de reviver foi inventado. |
| Remédio de teste D147 | Três por Novo teste, restante preservado na Próxima luta; cura garantida de aliado vivo, sem HP/MP. Agora testado contra aflições realmente aplicadas. |
| Sementes e interrupções | Quatro fluxos originais do cálculo preservados; recuperação de Medo e alvo de Confusão têm fluxos separados, também por semente. Rotas mantêm seus próprios RNGs. |

## Fontes que passam a ser únicas

- `data/damage_reference_profiles.json`: cinco fichas aprovadas com identidade, atributos naturais, equipamento inicial e proveniência dos presets. `combat_reference.gd` completa os campos legados pelo mesmo catálogo e resolve os equipamentos atuais.
- `data/damage_lab.json`: ações, custos, fórmulas/configuração, equipamentos e política ofensiva do Monstro #2. O laboratório de danos continua permitindo experiências locais; mudar um campo experimental ou salvar um preset pessoal não altera silenciosamente as referências aprovadas.
- `data/battle_damage_v1.json`: somente configuração de encontro, IDs das referências, repertórios, comportamento de teste e consumível. Não mantém cópias das cinco fichas.
- `damage_calculator.gd` / `damage_equipment.gd`: matemática comum; `affliction_rules.gd` e `BattleModel` acrescentam execução temporal, sem duplicar o teste de aplicação ou dano.

O laboratório de danos ganha seletores **Referência · Aliado / Monstro**, separados da biblioteca pessoal. Assim é possível carregar exatamente as fichas do combate sem perder experimentos, presets próprios ou relatórios antigos. As cinco referências coincidem com os treze atributos e críticos da biblioteca pessoal verificada nesta entrega.

## Repertórios e escopo

No laboratório atual, o mago possui magia ofensiva e as quatro aflições; os dois aliados físicos mantêm somente seus básicos. Para testar aplicação contra os aliados, o Monstro #1 também possui as quatro aflições, com seu MAG/MP originais. O Monstro #2 mantém somente básico físico à distância.

Os pesos iguais de ação do Monstro #1 em `enemy_actions` são uma **escolha técnica experimental do laboratório**, configurável em dados, sem definir personalidade, balanceamento ou repertório definitivo da aventura. Nenhum atributo ou equipamento das cinco fichas foi rebalanceado.

As quinze demonstrações anteriores ficam identificadas como **Legado** no laboratório independente. Servem para regressão e comparação histórica; não são alternativas atuais à referência compartilhada. Seus dados e acesso permanecem. O catálogo da exploração foi migrado posteriormente em D149, conforme `COMBATE_EXPLORACAO_COMPARTILHADO.md`.

O laboratório de danos continua sendo uma calculadora: lotes restauram recursos por amostra. O combate continua sendo temporal: HP/MP/estoque acumulam entre ações e lutas. A matemática e as referências são comuns, respeitando a função de cada ferramenta.

## Verificação

**69 suítes headless, 351.126 verificações, zero falhas.** Nova suíte de integração: **913 verificações**; interface compartilhada: **15**. Testes gráficos: **19 + 24 verificações**, zero falhas, com sete capturas.

Cobertura inclui comparação dos treze atributos, cinco fichas e seis armas/vestimentas por família; paridade exata de amostras de aflição com a calculadora em cinco sementes; todos os intervalos de Veneno; interrupção de 5 s; cura real, INI/EVA incluindo saturação; exclusividade e custo; Medo, desempate e único sobrevivente; origens diferentes; recuperação física/mágica, crítico, esquiva e KO; Confusão reproduzível com fogo amigo; vitória/fuga/derrota; interfaces e regressões da exploração.

```sh
godot --headless --path . --script res://tests/battle_affliction_tests.gd
godot --headless --path . --script res://tests/laboratory_parity_ui_smoke.gd
```

Evidências: `artifacts/laboratory-parity-2026-11-15/test-results.json`, `personal-reference-audit.json` e `visual/`. Não declara balanceamento coletivo definitivo nem avaliação humana de gameplay concluída.

## Exploração concluída — D149

Os seis encontros da exploração agora usam as mesmas referências e regras, com três aliados aprovados na fila e em combate. Formações/rotas/perfis de alvo e fuga preservados; ondas e técnicas antigas substituídas pelo repertório atual. Estoque de três Remédios no reinício explícito; restante e HP/MP preservados entre encontros/áreas. Sem monstros comuns no mapa-múndi. Associação de fichas aos movimentos é configurável, sem atributos novos.

Detalhes, escolhas técnicas e evidências em [COMBATE_EXPLORACAO_COMPARTILHADO.md](COMBATE_EXPLORACAO_COMPARTILHADO.md). D148 acima registra a primeira etapa histórica; D149 conclui a paridade solicitada dos três ambientes.

Buffs novos, recursos de reviver, magia de cura, progressão, economia, aflições de grupo e técnicas físicas experimentais sem usuário aprovado continuam fora deste recorte. A calculadora pode avaliá-los como experiências identificadas; isso não concede ações novas aos combatentes.

## Regra permanente de manutenção — D150

**Solicitada em 15/11/2026:** os três ambientes devem permanecer sincronizados. Uma alteração aprovada em dados/regras compartilhados só está concluída quando a fonte comum e todos os ambientes aplicáveis estiverem atualizados na mesma entrega. Não deixar uma nova migração para outra etapa sem decisão expressa do usuário registrada. Essa obrigação também consta em `AGENTS.md`.

1. **Identificar o alcance.** Fichas, atributos, equipamentos, repertórios, custos, fórmulas e aplicação de aflições pertencem às referências comuns. ATB, duração/ticks, pausas, cura e continuidade pertencem ao mesmo modelo temporal usado pelo laboratório de combate e exploração; a calculadora representa somente os aspectos que calcula. Interface, câmera, quantidade de inimigos, posições e rotas podem variar conforme a função do ambiente.
2. **Alterar a fonte única.** Usar os arquivos/componentes da tabela abaixo; consumidores devem ler essa fonte, sem cópias manuais ou ajustes compensatórios exclusivos de um ambiente. Novas mecânicas compartilhadas devem seguir o mesmo padrão.
3. **Atualizar todos os consumidores afetados.** Uma alteração pode começar pela análise em um laboratório, mas sua implementação aprovada deve chegar aos demais ambientes aplicáveis na mesma entrega. Incluir apresentação, descrições e seleção de ações quando afetadas.
4. **Verificar a paridade antes de concluir.** Executar as suítes pertinentes à mudança; para dados/cálculos compartilhados, conferir calculadora ↔ laboratório de combate e laboratório de combate ↔ seis encontros atuais da exploração, com mesmas entradas e sementes quando houver sorteio. Para efeitos temporais, exercitar o modelo compartilhado e sua integração na exploração. Testar interfaces quando houver impacto nelas; ampliar regressões conforme o alcance. Registrar resultados reais e limitações, sem declarar execução de testes não realizados.
5. **Atualizar os registros.** Documentar a decisão em `DECISOES.md`, comportamento em `GDD.md` e documentos específicos; revisar `PENDENCIAS.md`. Na entrega, informar o que mudou e quais ambientes foram afetados. Migração incompleta deve ser relatada como incompleta.

| Conteúdo | Fonte compartilhada atual |
| --- | --- |
| Cinco fichas aprovadas / equipamentos iniciais | `data/damage_reference_profiles.json`, carregado por `combat_reference.gd` |
| Ações, custos, catálogo de equipamentos e parâmetros do cálculo | `data/damage_lab.json` |
| Composição de atributos / cálculo de dano e aplicação | `damage_equipment.gd`, `damage_calculator.gd`, `damage_action_policy.gd` |
| Repertórios jogáveis, Remédio e parâmetros das aflições | `data/battle_damage_v1.json` |
| Execução temporal, recursos, cura e regras das aflições | `battle_model.gd`, `affliction_rules.gd` e configurações temporais comuns de `data/lab.json` |
| Associação dos encontros da exploração às referências | `data/exploration_combat.json`, montado pela mesma ponte `damage_v1_bridge.gd` |

**Experimentos locais:** alterar campos da calculadora, trocar equipamentos numa sessão ou salvar presets pessoais continua sendo um teste local. Somente a aprovação da mudança como referência do projeto autoriza promovê-la às fontes comuns. Isso preserva espaço para experimentar sem rebalancear os três ambientes a cada clique.

**Legado:** demonstrações e fixtures históricas conservam os dados necessários à comparação/regressão, sempre identificados. Não servem como fonte dos encontros atuais e não bloqueiam sua evolução.

**Exemplos de alcance:** mudar a DEF F aprovada de um aliado ou o custo de Veneno atualiza as três referências aplicáveis; mudar o intervalo de Veneno atualiza o modelo temporal comum e sua documentação, mantendo a aplicação calculada coerente; mover um botão da calculadora ou uma rota de encontro atualiza somente a interface ou configuração correspondente.

**Verificação disponível:** `battle_affliction_tests.gd` cobre paridade calculadora/combate e regras temporais; `exploration_combat_parity_tests.gd` cobre laboratório/combates da exploração; as suítes `laboratory_parity_ui_smoke.gd` e `exploration_combat_parity_ui_smoke.gd` verificam as respectivas interfaces. Acrescentar cobertura útil quando a nova regra não estiver representada nesses testes.
