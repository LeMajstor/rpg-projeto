# Danos V1 no laboratório de batalha

**D126 — autorizado em 01/11/2026.** Primeira etapa da migração para experimentar gameplay. A referência numérica D124/D125 permanece fechada; aflições ficam expressamente para a segunda parte.

## Recorte implementado

O laboratório independente abre em **V1 · danos e equipamentos**: Aliados #1, #2 e #3 — Mago contra um Monstro #1 de contato e um Monstro #2 exclusivamente à distância. Não há quarto aliado inventado. As cinco fichas são cópias da referência finalizada, com os mesmos atributos naturais e equipamentos iniciais.

Cada aliado possui ataque físico básico: espada/cajado usam ATQ F contra DEF F e aproximação/impacto/retorno; arco usa ATQ D contra DEF D, sem aproximação. Monstros seguem os respectivos modos. Somente o mago possui **Magia ofensiva básica**, MAG contra DEF M, potência1,5 e custo7MP, sem esquiva ou crítico. Ataques físicos mantêm EVA e crítico da V1. A técnica física genérica e as antigas habilidades de círculo/tela inteira não são habilidades das novas fichas.

**Fórmula compartilhada:** `potência × ofensiva² / (ofensiva + defesa)`, variação±10%, crítico físico antes do arredondamento, inteiro mais próximo e mínimo1 em acerto. Esquiva física causa0. Não foi criado um segundo cálculo equivalente: o impacto chama `damage_calculator.gd.sample`, e a composição usa `damage_equipment.gd.resolve`.

O combate administra HP/MP acumulados, INI/ATB, incapacidade e vitória/derrota. O custo é debitado **uma vez, na confirmação**, e o dano somente no impacto. Cancelar ou recusar por MP insuficiente preserva ação/recursos/sorteios. O cálculo de lote, que reinicia as condições a cada amostra, não é usado na simulação temporal.

Wait/Active, Battle Speed, navegação por teclado/controle, depuração, atenção visual, sorteios de movimento e retorno exato continuam existentes. As duas rotas reutilizam os comportamentos pesado/ágil por semente. Geometria/posições e perfil uniforme de alvo são configurações técnicas provisórias deste encontro, sem definir uma IA ou formação definitiva.

## Como experimentar

1. Abra **Executar laboratorio.command**; o novo cenário já estará selecionado.
2. Use **Preparar equipamentos V1 [E]** para escolher arma e vestimenta de cada aliado. Seis estágios por família; exclusividade preservada. A janela mostra naturais→efetivos, EVA e crítico e pausa o combate. Tab/setas/Enter operam os controles da janela.
3. **Iniciar V1 com estes equipamentos** reinicia HP/MP e aplica as escolhas. Voltar fecha a preparação e retoma a luta sem alterar os equipamentos ativos. Escolhas pendentes permanecem apenas na sessão.
4. Espere ATB, escolha um dos três cards prontos e use Atacar. Para a magia: escolha o mago → Habilidades → Magia ofensiva básica → alvo → confirmar. Esc cancela por etapas; F3 permite deixar aliados prontos e inspecionar ATB/rotas.
5. F5/Novo teste aplica as escolhas pendentes e restaura os recursos. Após vitória/fuga, Próxima luta conserva HP/MP, incapacitação e os equipamentos ativos; não aplica uma troca pendente disfarçada de continuação. Trocar entre V1 e cenários anteriores exige Novo teste.

**Ainda fora deste recorte:** aflições/aplicação/efeitos/duração, buffs de proteção, progressão/níveis e migração para encontros da exploração. O comando Itens está indisponível na V1: os consumíveis antigos permanecem nas demonstrações anteriores, sem adotar silenciosamente suas quantidades/cura no novo balanceamento. A fuga conserva o comportamento experimental existente.

## Dados e compatibilidade

- `data/battle_damage_v1.json`: cópia versionada das cinco fichas de `artifacts/damage-v1-final/presets-v1.json`, incluindo origem/revisão, e geometria do novo encontro. Não lê nem regrava a biblioteca pessoal ao abrir a batalha.
- `scripts/combat/damage_v1_bridge.gd`: adapta fichas ao modelo temporal e lê ações, equipamentos e configurações numéricas do catálogo de danos. Upgrades de campos legados também são compartilhados.
- `battle_model.gd`: ativa esse cálculo somente em preset com `damage_ruleset: damage_lab_v1`. Quatro fluxos de sorteios seguem as sementes do laboratório de danos, separados de ações/alvos e dos fluxos individuais de movimento. Cada impacto consome um sorteio por canal, inclusive em esquiva; tentativas recusadas não consomem.
- `damage_results`: registro em memória dos últimos100 impactos com participantes, dano, rolagens, esquiva/crítico e HP/MP antes/depois; log da tela distingue esquiva e crítico.
- Os quinze cenários anteriores continuam no seletor com seus dados e habilidades antigos. `data/lab.json` não foi alterado: exploração continua com quatro aliados e seus encontros por semente. As novas definições só são acrescentadas pela UI do laboratório independente.
- O laboratório de danos, seus presets pessoais e relatórios históricos continuam independentes e preservados.

## Verificação

```sh
godot --headless --path . --script res://tests/battle_damage_v1_tests.gd
godot --headless --path . --script res://tests/battle_damage_v1_ui_smoke.gd
```

Cobertura: importação das cinco fichas; paridade de danos/rolagens nos cinco participantes e magia; custo/HP acumulados; magia contra EVA100/CRI100; esquiva física; repertórios e equipamento exclusivo; escolhas pendentes/reinício; ATB por INI; Wait; KO/seleção; vitória/derrota; recursos na próxima luta; retorno de posição/rota; partidas completas reproduzidas em Wait/Active. A interface testa comandos/mira/cancelamento, card ausente, preparação/seis estágios, aplicação e alternância para cenário antigo.

Resultados da entrega em `artifacts/battle-damage-v1/test-results.json`; capturas gráficas em `artifacts/battle-damage-v1/visual/`. Isso verifica a integração, sem declarar concluída uma avaliação humana do ritmo ou do balanceamento coletivo em gameplay.
