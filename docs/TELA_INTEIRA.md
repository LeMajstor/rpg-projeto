# Apresentação configurável de habilidades de tela inteira

**Versão vigente:** teste este comportamento em **Atual · linha superior**. D e as opções anteriores são legadas; o mecanismo de centro/retorno permanece e está integrado ao comportamento por semente. Ver [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md).

## Regras confirmadas

O usuário autorizou deslocamento temporário ao centro visual do campo para técnicas de tela inteira, condicionado a uma propriedade individual do participante. Personagens e inimigos móveis normalmente vão ao centro; estáticos normalmente ficam no lugar, com exceções configuráveis. Uma condição futura poderá impedir esse deslocamento no protagonista, sem introduzir essa condição narrativa agora.

Posição de repouso e progresso da rota são preservados. Após a execução, o participante retorna exatamente à origem e retoma a rota. A área de efeito independe do deslocamento visual; melee continua separado. A representação é provisória.

## Testar no laboratório

1. Abra `Executar laboratorio.command`, selecione **D · técnica de tela inteira** e clique **Novo teste**.
2. Use **Habilidades → Onda → Confirmar** com um aliado pronto. Ele vai ao centro, aplica o efeito e retorna. F3 → Aliados prontos acelera a preparação do teste.
3. Observe os inimigos: E1 é móvel e vai ao centro; E2 é estático e executa no lugar; E3 também é estático, mas sua configuração individual o leva ao centro. A exceção usa apenas uma ficha provisória, sem criar um chefe definitivo.
4. Em **F3**, na linha **Centro**, selecione qualquer aliado ou inimigo e escolha **Usar padrão**, **Forçar: centro** ou **Forçar: imóvel**. O painel mostra configuração-base e resultado efetivo.
5. Experimente Onda com o mesmo aliado nas duas configurações. Os atingidos e o custo são os mesmos. Atacar e Varredura continuam melee.
6. Use 0,25×, Pausa e Passo para observar origem lógica, Δvisual e progresso da rota. A alteração de configuração vale na próxima ação, preservando a apresentação já iniciada.

Os inimigos de D tentam usar Onda enquanto têm MP; sem MP suficiente, usam o fallback de ataque já existente. Reiniciar o teste restaura MP e configurações. A/B/C permanecem disponíveis e seus dados de encontro não foram modificados.

```sh
godot --path . --scene res://scenes/combat_lab.tscn -- --preset=lab_fullscreen
```

## Configuração individual

`move_to_center_for_fullscreen_skill` é uma propriedade-base booleana do combatente. Pode aparecer na ficha aliada, no tipo inimigo ou na entrada individual do encontro.

Precedência na criação do inimigo: entrada individual do preset → definição do tipo → padrão derivado da rota. Sem configuração explícita, rota com velocidade/comprimento positivos habilita; estático desabilita. Para aliados, o padrão compatível é habilitado. As quatro fichas atuais explicitam `true`.

Exemplo de uma entrada estática com exceção, sem depender de ser classificada como chefe:

```json
{
  "id": "e3",
  "type": "static",
  "move_to_center_for_fullscreen_skill": true
}
```

O trecho ilustra apenas a propriedade; os demais campos de encontro continuam necessários.

## Alterações temporárias futuras

Cada instância de combatente também possui `fullscreen_center_override`, inicialmente `null`. O modelo oferece:

```gdscript
model.set_fullscreen_center_override("p1", false) # Impedir temporariamente.
model.set_fullscreen_center_override("e2", true) # Permitir excepcionalmente.
model.set_fullscreen_center_override("p1")       # Limpar; usar a base novamente.
```

O valor efetivo é consultado por `fullscreen_center_enabled(actor)`. O override não altera a ficha original e persiste ao continuar com o mesmo grupo entre encontros. Novo teste recria os padrões. Somente `bool` ou `null` são aceitos, e IDs inválidos são rejeitados.

Uma futura condição narrativa/estado pode usar essa API. Nenhum gatilho narrativo, chefe definitivo ou restrição especial do protagonista foi criado. O protagonista começa habilitado, como os outros aliados.

## Apresentação e efeito independentes

A habilidade recebe `presentation: "fullscreen"`. Esse campo seleciona a apresentação; `target`, raio e regras de elegibilidade continuam selecionando os atingidos. Onda foi explicitamente marcada. `target: "all"` sozinho **não** implica ir ao centro: Varredura, por exemplo, continua usando a aproximação melee existente.

Na confirmação, o modelo captura o valor efetivo para aquela ação. Trocar a propriedade durante a execução não teleporta o participante nem interrompe seu retorno. A próxima ação usa a nova configuração.

Centro visual = metade da área lógica de apresentação de 920×440. O tamanho é compartilhado pelo modelo e pelo campo, e a conversão de escala/letterbox mantém o centro na posição correta da tela. Isso não é centro de área de dano e não modifica coordenadas usadas pelas regras.

## Arquitetura e escolhas técnicas provisórias

- `fullscreen_motion.gd` calcula apenas aproximação ao centro, sustentação e retorno, ou deslocamento zero durante toda a técnica quando desabilitado. Não conhece rotas, recursos ou alvos.
- `battle_model.gd` escolhe esse componente somente quando a apresentação está marcada. Os caminhos de melee/gesto e a validação de efeitos permanecem separados.
- A duração e o instante do efeito foram preservados: 0,8 s e 50% da ação. A sustentação provisória usa 15% da ação, configurável pelo campo opcional `fullscreen_impact_hold` de settings. Esses valores não são balanceamento definitivo.
- A rota do participante fica congelada em todas as fases, inclusive ao executar sem deslocamento. Coordenada lógica e estado completo da rota são comparados ao snapshot antes de concluir; Δvisual termina exatamente em zero.
- `battlefield.gd` mostra um pulso/clareamento provisório no campo e os pontos realmente atingidos, sem participar da lógica do efeito. Não há animação artística definitiva.
- O preset D pode configurar `actions` por entrada inimiga para exercitar a mesma Onda sem mudar as listas dos tipos ou os presets anteriores. Não altera os perfis de alvo ou o algoritmo de seleção.
- Wait/Active, pausa manual, velocidade, ATB e retorno ao mapa mantêm as regras anteriores. Uma animação já iniciada ainda pode concluir ao mudar Active → Wait; pausa manual congela também a apresentação.

## Arquivos

| Arquivo | Alteração |
| --- | --- |
| `scripts/combat/fullscreen_motion.gd` | Novo componente de apresentação. |
| `scripts/combat/battle_model.gd` | Configuração individual, API temporária, centro compartilhado e seleção do componente. |
| `scripts/ui/combat_lab.gd` | Editor por participante em F3 e diagnóstico da decisão capturada. |
| `scripts/ui/battlefield.gd` | Referência ao centro comum e efeito provisório. |
| `data/lab.json` | Flags aliadas, marca de apresentação de Onda e preset D. |
| `tests/fullscreen_tests.gd` | Configurações, retorno, rotas, efeito e isolamento do melee. |
| `tests/fullscreen_ui_smoke.gd` | Menu, overrides individuais, pausa e execução real da habilidade. |

`attack_motion.gd`, `route_motion.gd` e `target_policy.gd` foram preservados integralmente. A/B/C, custos, potências, atributos, velocidades e regras anteriores foram comparados ao estado inicial desta alteração e preservados.

## Verificação

```sh
godot --headless --path . --script res://tests/fullscreen_tests.gd
godot --headless --path . --script res://tests/fullscreen_ui_smoke.gd
```

As seis suítes anteriores também foram executadas. Resultados em [VALIDACAO.md](VALIDACAO.md).
