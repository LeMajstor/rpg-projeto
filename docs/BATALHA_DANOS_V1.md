# Danos V1 no laboratório de batalha

**D149 — 15/11/2026:** a mesma referência agora atende também os seis encontros da exploração, com os três aliados na fila e em batalha, aflições e Remédio funcionais. Formações/rotas/perfis e recursos/estados das áreas preservados; repertórios antigos substituídos pelas ações atuais. Ver [COMBATE_EXPLORACAO_COMPARTILHADO.md](COMBATE_EXPLORACAO_COMPARTILHADO.md).

**Estado atual — D148 (15/11/2026):** integração das quatro aflições concluída, com mesmas fórmulas, fichas e equipamentos do laboratório de danos. As cinco fichas vêm de `damage_reference_profiles.json`, e o Mago possui magia ofensiva e Veneno/Lentidão/Confusão/Medo. Remédio cura efeitos realmente ativos. As notas D126–D147 abaixo são histórico da aprovação; suas antigas ressalvas de integração pendente foram superadas por D148 para o laboratório independente. [Levantamento completo](PARIDADE_LABORATORIOS.md).

**D126 — autorizado em 01/11/2026.** Primeira etapa da migração para experimentar gameplay. A referência numérica D124/D125 permanece fechada; aflições ficam expressamente para a segunda parte.

**D127 — desenho de Veneno definido parcialmente em 10/11/2026, ainda sem implementação:** 5% do HP máximo a cada 5 segundos, sem expiração por duração, até cura por magia/item ou encerramento da batalha. Pode incapacitar ao chegar a 0 HP e não persiste na próxima luta; remoção não recupera HP/revive. **D128/D131:** não há reaplicação do efeito, acúmulo ou reinício; tentar lançar em alvo já envenenado é permitido e gasta MP/ação normalmente, sem efeito adicional; Active mantém contagem/ticks no menu e Wait pausa, retomando o intervalo restante ao sair, sem acumular ticks. **D129:** intervalo dos ticks acompanha proporcionalmente a escala Battle Speed do ATB, mantendo 5% por tick e D128. **D130:** referência de 5 segundos reais permitidos no Battle Speed 4; intervalo nos demais níveis = `5 × multiplicador_ATB(4) / multiplicador_ATB(nível)`. **D131:** ao ser revivido, retorna sem Veneno, sem retomar a contagem anterior. **D132 (15/11/2026):** tick arredondado ao inteiro mais próximo, empate 0,5 para cima, mínimo 1 HP. Contagem de Veneno congela na pausa manual e durante toda a ação. Recursos de cura/reviver continuam pendentes em `PENDENCIAS.md`; demais aflições ainda em definição. O recorte de ações disponíveis abaixo permanece o de D126; D132 já atualiza o tempo do combate compartilhado, sem integrar Veneno.

**D133 — Lentidão, desenho parcial de 15/11/2026:** divide somente a INI natural por 2 e zera somente a EVA natural; bônus de outras fontes permanecem separados. D134/D135 confirmam resultado inteiro com 0,5 para cima antes de somar bônus e duração até cura por item/magia ou fim da batalha. D136 resolve reaplicação e reviver para todas as aflições. Recursos de cura e demais detalhes pendentes em `PENDENCIAS.md`; ainda sem integração ao combate.

**D136 — regra comum de 15/11/2026, ainda sem integração:** tentar aplicar a mesma aflição já ativa consome ação/MP sem efeito adicional, acúmulo ou reinício de contagens; reviver remove todas as aflições. Vale para Veneno, Lentidão, Confusão e Medo. D137 define Confusão e D138 define duração/remoção de Medo; D144/D145 resolvem exclusividade e preservação da aflição atual; D146 fecha execução de Medo; integração ainda pendente.

**D137 — Confusão definida em 15/11/2026, ainda sem integração:** ataque básico automático quando ATB está completo e a execução está disponível, sem MP ou escolha manual de comando. Sorteio uniforme entre os demais combatentes vivos de ambos os lados, sem si próprio; regras normais de contato/distância, dano/esquiva/crítico, ação e pausa global. Até cura por item/magia ou fim da batalha; dano recebido não remove. D136 vale; habilidades/itens/buffs fora do funcionamento inicial.

**D138 — duração de Medo definida em 15/11/2026, ainda sem integração:** até fim da batalha, cura ou reviver, sem recuperação automática por tempo. Proposta de 10 segundos não adotada. D139 acrescenta trava nos aliados e chance de recuperação por dano; D146 fecha execução/retomada de ATB/rotas e gatilhos de recuperação; integração e recursos de cura continuam pendentes em `PENDENCIAS.md`.

**D139 — Medo, trava e recuperação por dano (15/11/2026), ainda sem integração:** impedir todos os aliados com Medo; em quatro integrantes, três afetados tornam o último imune a esse efeito. Aliado/inimigo com Medo que recebe dano físico/mágico tem chance de se recuperar. Sem prazo automático ou derrota por Medo; D140 confirma proteção dinâmica nos vivos; D141 define maior INT efetiva/desempate pela ordem da equipe e recuperação por teste de INT; D142 aprova a fórmula; D146 fecha execução/gatilhos; magias de grupo continuam futuras.

**D140 — proteção dinâmica de 15/11/2026, ainda sem integração:** manter ao menos um aliado vivo sem Medo, inclusive quando o último livre cai; se necessário, remover Medo de um sobrevivente. D141 define maior INT efetiva, com desempate pela ordem da equipe. Único sobrevivente fica protegido do efeito; não cura HP nem impede dano, e não se aplica aos inimigos.

**D141 — critérios de Medo definidos em 15/11/2026, ainda sem integração:** proteção dinâmica libera o sobrevivente de maior INT efetiva, com desempate pela ordem da equipe. Recuperação por dano físico/mágico usa teste de INT do afetado; D142 aprova a fórmula; D146 confirma INT efetiva atual e gatilhos por dano. Proposta de chance fixa de 25% não adotada.

**D142 — fórmula de recuperação de Medo aprovada em 15/11/2026, ainda sem integração:** `100 × INT do afetado / (INT do afetado + MAG de quem aplicou Medo)` em %, com MAG da origem registrada na aplicação. D146 confirma INT efetiva atual e gatilhos por dano. **P18/D143:** derrota da origem remove automaticamente seu Medo, conforme registro abaixo.

**D143 — derrota do aplicador remove Medo, aprovado em 15/11/2026, ainda sem integração:** ao chegar a 0 HP, remover sem teste todos os efeitos de Medo originados naquele participante, mantendo os de outras origens. Vale para aplicadores aliados/inimigos; reviver o aplicador não restaura os efeitos removidos. Específico de Medo, sem cura de HP ou remoção de outras aflições.

**D144 — uma aflição por alvo, aprovado em 15/11/2026, ainda sem integração:** Veneno, Lentidão, Confusão e Medo não coexistem. D145 define que tentativa da mesma ou de outra aflição contra alvo afetado consome ação/MP e não tem efeito adicional: mantém a atual sem substituir, renovar, reiniciar contagens ou trocar origem.

**D145 — preservação da aflição atual aprovada em 15/11/2026, ainda sem integração:** tentar aplicar qualquer aflição em alvo já afetado gasta ação/MP normalmente, sem efeito adicional. Mantém a atual e suas contagens/origem. Vale para aliados e inimigos.

**D146 — regras individuais de Medo fechadas em 15/11/2026, ainda sem integração:** todos os comandos bloqueados; ATB/rota preservados e congelados até remoção, com retomada exata. Fórmula D142 usa INT efetiva atual; uma tentativa por ação/afetado após dano físico/mágico direto que retire HP e o deixe vivo, sem teste por esquiva/dano zero/Veneno ou aumento da chance por crítico. Tentativa contra aliado protegido consome ação/MP sem aplicar Medo. Integração, recursos de cura e futura aplicação coletiva continuam separados.

**D147 — Remédio de teste aprovado e integrado em 15/11/2026:** único item disponível na V1, com 3 unidades por Novo teste/F5. Consome unidade/ação, 0 MP; remove aflição no impacto de um aliado vivo, inclusive usuário. Sem HP/MP/reviver, teste de resistência ou esquiva; alvo limpo consome sem efeito. Próxima luta conserva estoque. Aflições continuam sem aplicação/efeitos temporais integrados: testes exercitam remoção de estados controlados. O item pode ser usado em alvo limpo para verificar lista, mira, animação e consumo. Não adota consumíveis antigos ou magias/itens de reviver.

## Recorte implementado

O laboratório independente abre em **V1 · danos e equipamentos**: Aliados #1, #2 e #3 — Mago contra um Monstro #1 de contato e um Monstro #2 exclusivamente à distância. Não há quarto aliado inventado. As cinco fichas são cópias da referência finalizada, com os mesmos atributos naturais e equipamentos iniciais.

Cada aliado possui ataque físico básico: espada/cajado usam ATQ F contra DEF F e aproximação/impacto/retorno; arco usa ATQ D contra DEF D, sem aproximação. Monstros seguem os respectivos modos. O mago possui **Magia ofensiva básica**, MAG contra DEF M, potência1,5 e custo7MP, sem esquiva ou crítico, e agora as quatro magias de aflição de4MP. Monstro #1 usa essas aflições no cenário de teste; Monstro #2 permanece exclusivamente físico à distância. Ataques físicos mantêm EVA e crítico da V1. A técnica física genérica e as antigas habilidades de círculo/tela inteira não são habilidades das novas fichas.

**Fórmula compartilhada:** `potência × ofensiva² / (ofensiva + defesa)`, variação±10%, crítico físico antes do arredondamento, inteiro mais próximo e mínimo1 em acerto. Esquiva física causa0. Não foi criado um segundo cálculo equivalente: o impacto chama `damage_calculator.gd.sample`, e a composição usa `damage_equipment.gd.resolve`.

O combate administra HP/MP acumulados, INI/ATB, incapacidade e vitória/derrota. O custo é debitado **uma vez, na confirmação**, e o dano somente no impacto. Cancelar ou recusar por MP insuficiente preserva ação/recursos/sorteios. O cálculo de lote, que reinicia as condições a cada amostra, não é usado na simulação temporal.

Wait/Active, Battle Speed, navegação por teclado/controle, depuração, atenção visual, sorteios de movimento e retorno exato continuam existentes. **D132:** toda execução de ação congela ATB e rotas de todos os participantes, com progresso de apresentação próprio e efeito no impacto; seleção em Active/Wait mantém suas regras. As duas rotas reutilizam os comportamentos pesado/ágil por semente. Geometria/posições e perfil uniforme de alvo são configurações técnicas provisórias deste encontro, sem definir uma IA ou formação definitiva.

## Como experimentar

1. Abra **Executar laboratorio.command**; o novo cenário já estará selecionado.
2. Use **Preparar equipamentos V1 [E]** para escolher arma e vestimenta de cada aliado. Seis estágios por família; exclusividade preservada. A janela mostra naturais→efetivos, EVA e crítico e pausa o combate. Tab/setas/Enter operam os controles da janela.
3. **Iniciar V1 com estes equipamentos** reinicia HP/MP e aplica as escolhas. Voltar fecha a preparação e retoma a luta sem alterar os equipamentos ativos. Escolhas pendentes permanecem apenas na sessão.
4. Espere ATB, escolha um dos três cards prontos e use Atacar. Para a magia: escolha o mago → Habilidades → Magia ofensiva básica → alvo → confirmar. Esc cancela por etapas; F3 permite deixar aliados prontos e inspecionar ATB/rotas.
5. F5/Novo teste aplica as escolhas pendentes e restaura os recursos. Após vitória/fuga, Próxima luta conserva HP/MP, incapacitação e os equipamentos ativos; não aplica uma troca pendente disfarçada de continuação. Trocar entre V1 e cenários anteriores exige Novo teste.

**Fora do recorte atual:** buffs de proteção, magia de cura, recurso jogável de reviver, progressão/níveis e migração para encontros da exploração. As quatro aflições têm aplicação/efeitos temporais implementados por D148. D147 habilita Itens na V1 somente com Remédio de teste; os consumíveis anteriores permanecem nas respectivas demonstrações, com repertório/estoque separados por preset. A fuga conserva o comportamento experimental existente.

## Usar o Remédio de teste

1. Em V1, aguarde um aliado pronto, confirme seu card e escolha **Itens** (atalho **I**).
2. Selecione **Remédio de teste ×3** e um dos aliados vivos, incluindo o usuário. Esc volta por etapas, sem custo antes da confirmação.
3. Confirmar gasta uma unidade; o efeito ocorre no impacto e a barra zera após a apresentação. Em alvo sem aflição, há consumo sem cura de HP/MP.
4. Próxima luta conserva o estoque; Novo teste/F5 restaura as 3 unidades.

D148 acrescenta aplicação real, ticks e ações automáticas: use o Mago → Habilidades para aplicar as aflições; Monstro #1 também pode aplicá-las ao grupo. Os testes antigos de D147 mantêm suas fixtures de estado, complementados agora por integração real em `battle_affliction_tests.gd` e `laboratory_parity_ui_smoke.gd`.

## Dados e compatibilidade

- `data/battle_damage_v1.json`: geometria, repertórios/pesos de teste, regras temporais e itens do encontro; referencia as cinco fichas centralizadas em `data/damage_reference_profiles.json`, com origem/revisão preservadas. Não lê nem regrava a biblioteca pessoal ao abrir a batalha.
- `scripts/combat/damage_v1_bridge.gd`: adapta fichas ao modelo temporal e lê ações, equipamentos e configurações numéricas do catálogo de danos. Upgrades de campos legados também são compartilhados.
- `battle_model.gd`: ativa esse cálculo somente em preset com `damage_ruleset: damage_lab_v1`. Quatro fluxos de sorteios seguem as sementes do laboratório de danos, separados de ações/alvos e dos fluxos individuais de movimento. Cada impacto consome um sorteio por canal, inclusive em esquiva; tentativas recusadas não consomem.
- `damage_results`: registro em memória dos últimos100 impactos com participantes, dano, rolagens, esquiva/crítico e HP/MP antes/depois; log da tela distingue esquiva e crítico.
- Os quinze cenários anteriores continuam no seletor, todos identificados como **Legado**, com seus dados e habilidades históricos. `data/lab.json` não foi alterado: exploração continua com quatro aliados e seus encontros por semente. As novas definições só são acrescentadas pela UI do laboratório independente.
- Biblioteca pessoal e relatórios históricos do laboratório de danos permanecem preservados; os novos seletores de referência compartilham as mesmas cinco fichas aprovadas com o combate.

## Verificação

D148: **69 suítes, 351.126 verificações, zero falhas**, mais testes gráficos e conferência das cinco referências pessoais. Roteiro e evidências em `PARIDADE_LABORATORIOS.md` e `VALIDACAO.md`.

```sh
godot --headless --path . --script res://tests/battle_affliction_tests.gd
godot --headless --path . --script res://tests/laboratory_parity_ui_smoke.gd
```

D147:

```sh
godot --headless --path . --script res://tests/remedy_v1_tests.gd
godot --headless --path . --script res://tests/remedy_v1_ui_smoke.gd
```

Modelo: quatro estados de aflição em fixtures, cura no impacto, consumo único, MP/HP/atributos/RNG preservados, autocura, bloqueio de Medo/Confusão, alvos inválidos, estoque esgotado, alvo limpo, cancelamento, continuação/reinício e catálogo legado. UI: teclado, lista/mira/cancelamento, nome/estoque, consumo, Novo teste e bloqueios. Não verifica efeitos temporais ainda não implementados.

D126:

```sh
godot --headless --path . --script res://tests/battle_damage_v1_tests.gd
godot --headless --path . --script res://tests/battle_damage_v1_ui_smoke.gd
```

Cobertura: importação das cinco fichas; paridade de danos/rolagens nos cinco participantes e magia; custo/HP acumulados; magia contra EVA100/CRI100; esquiva física; repertórios e equipamento exclusivo; escolhas pendentes/reinício; ATB por INI; Wait; KO/seleção; vitória/derrota; recursos na próxima luta; retorno de posição/rota; partidas completas reproduzidas em Wait/Active. A interface testa comandos/mira/cancelamento, card ausente, preparação/seis estágios, aplicação e alternância para cenário antigo.

Resultados da entrega em `artifacts/battle-damage-v1/test-results.json`; capturas gráficas em `artifacts/battle-damage-v1/visual/`. Isso verifica a integração, sem declarar concluída uma avaliação humana do ritmo ou do balanceamento coletivo em gameplay.
