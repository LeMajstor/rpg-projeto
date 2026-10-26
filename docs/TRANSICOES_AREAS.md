# Casa e laboratório: transições entre áreas

O sistema agora conecta cinco áreas: duas casas↔vila↔mundo aberto↔dungeon. A segunda casa e seu evento são descritos em [EVENTOS_DIA_NOITE.md](EVENTOS_DIA_NOITE.md). A dungeon não é mais acessada diretamente pelo antigo exterior. O mapa externo representa a vila, com NPCs nas ruas; veja [VILA_E_MUNDO.md](VILA_E_MUNDO.md) para o roteiro vigente. A mecânica de transições abaixo permanece reutilizada.

Distribuição atual: o catálogo agora também contém a mini dungeon. NPCs ficam na casa e monstros na dungeon; o exterior passou a ter somente colisões e acessos. A distribuição e o roteiro atuais estão em [INTERIORES_DUNGEON.md](INTERIORES_DUNGEON.md). O funcionamento das transições descrito abaixo permanece; referências à ocupação antiga do exterior são históricas.

## Recorte confirmado

Autorizado em **24/10/2026**: pequena casa de teste com interior separado, conectada ao mapa externo existente. Entrada/saída por E ou botão contextual, fade simples, estado por área preservado, fila segura no destino e testes. Manter combate, NPCs, objetos, liderança e fila existentes. A porta/alavanca do sudeste continuam locais e não transportam.

Não há mapa-múndi, vila, história, missões, descanso, inventário definitivo, progressão ou salvamento em disco. Os móveis e a casa são representações provisórias originais. Patrulhas inativas pausadas e memória até reinício são escolhas técnicas deste protótipo; não definem persistência ou passagem de tempo da aventura final.

## Executar e experimentar

Abra `Executar exploracao.command` no macOS ou execute `project.godot` no Godot (F5). O projeto ainda começa no laboratório externo.

```sh
godot --path .
```

A casa fica ao nordeste, à direita do Bloco C e acima do Bloco B. Partindo do início, ande à direita pela faixa livre e suba pelo lado direito do Bloco B. A entrada indica **Entrar na casa [E]**. No interior, a saída fica ao sul, entre os dois trechos da parede inferior; aproxime-se e use **Sair da casa [E]**.

| Controle/contexto | Resultado |
| --- | --- |
| WASD / setas | Movimento cardinal e fila existentes em ambas as áreas. |
| E / botão contextual perto da entrada ou saída | Inicia transição explícita; não há troca por contato de líder ou seguidores. |
| Tab / Esc | Menu de liderança em qualquer área, fora de diálogo/combate/transição. |
| F3 | Colisões, trilha e rotas da área exibida. |
| Durante o fade | Movimento, menus e novas interações ficam bloqueados. |
| Reiniciar teste | Descarta estados de todas as áreas e restaura recursos; começa no exterior. |

Ao chegar, o grupo mantém líder/ordem, mas ocupa a fila definida pela entrada de destino. O histórico de coordenadas anterior é descartado. A direção da chegada é configurada por entrada. Não há cura. Aproximar-se novamente de uma saída e pressionar E é necessário para outra viagem. Se uma entrada futura deixar o líder no alcance do portal de retorno, esse portal só rearma depois de sair do alcance e se aproximar novamente.

Roteiro manual:

1. Troque o líder pelo menu, entre na casa e confira sprite da frente, ordem e HP/MP.
2. Contorne a mesa e os móveis. Confira colisões e seguimento sem cortar quinas.
3. Saia pela abertura ao sul. Confira o exterior e a nova fila em trecho livre.
4. Abra o baú/porta locais, vença um encontro, visite a casa e retorne. Objetos conservam os estados e só o encontro vencido continua ausente.
5. Observe uma patrulha externa antes/depois da visita: a área inativa pausa e retoma o mesmo progresso.
6. Depois da viagem, inicie uma batalha externa, gaste MP e vença/fuja. O retorno continua no exterior, com os mesmos recursos.
7. Reinicie o teste: objetos, encontros, recursos e áreas visitadas voltam às condições iniciais.

O laboratório de combate independente mantém `Executar laboratorio.command` ou `godot --path . --scene res://scenes/combat_lab.tscn`.

## Dados e reutilização

`data/areas.json` é o catálogo: define `initial_area_id`, caminhos das áreas e `transition_duration`. O carregador lê definições; a sessão cria modelos de estado conforme as áreas são visitadas.

Cada mapa mantém o formato existente e acrescenta:

- `id` e `label`: identidade e nome da área exibida.
- `entries`: dicionário de entradas, com `position`, `facing` cardinal unitário e `arrival_transition_id` opcional para proteger o retorno.
- `transitions`: pontos com ID único no mapa, `label`, `position`, `interaction_distance`, `target_area_id` e `target_entry_id`.
- `footer`: instrução provisória de apresentação.

Exemplo real da conexão de saída, em `data/house.json`:

```json
{
  "id": "house_exit",
  "label": "Sair da casa",
  "position": [360, 430],
  "interaction_distance": 64,
  "target_area_id": "lab_exterior",
  "target_entry_id": "from_house"
}
```

A entrada `from_house` do exterior define posição `[840, 310]`, direção `[1, 0]` e portal de retorno `house_entrance`. A entrada da casa aponta para `[360, 300]`, direção `[0, -1]`. Coordenadas, escala do interior, espaçamento e tempos são provisórios.

Para outra porta, escada ou saída, cadastre uma área no catálogo, uma entrada livre no destino e um ponto de transição na origem. Para uma conexão de ida e volta, configure também o ponto inverso. Os dados identificam destinos, sem executar código ou conter scripts narrativos. Uma entrada deve comportar o trecho inteiro da fila, não só o líder.

## Arquitetura e escolhas técnicas

| Componente | Responsabilidade |
| --- | --- |
| `area_catalog.gd` | Ler catálogo/JSON e validar estrutura básica antes de construir um destino. Sem estado de partida. |
| `exploration_model.gd` | Entidades de transição, proximidade/visibilidade existentes, plano de chegada, validação de limites/sólidos do trecho inteiro e proteção de reentrada. Movimento normal e colisão continuam no mesmo modelo. |
| `exploration_session.gd` | Definições e cache `area_worlds` por ID, área ativa, transição, efeitos de diálogo/objetos e modelo único de combate. |
| `exploration_test.gd` | Carregar catálogo, exibir área ativa e fade, encaminhar entrada e reutilizar a mesma UI/cena. |
| `exploration_view.gd` | Desenhar o modelo ativo, casa, interior e marcadores de transição provisórios. |

A sessão continua expondo `world` como área ativa, preservando seus consumidores. Cada área visitada conserva sua instância com entidades, baús, portas, alavancas, encontros e rotas. Ao viajar, só a formação é reconstruída; o restante do destino não é reiniciado. A ordem atual é copiada para o destino, inclusive quando o líder foi alterado no interior. HP/MP, estoque, incapacitação e modo ATB continuam na mesma instância de BattleModel, compartilhada com a cena de combate.

O destino e a entrada são validados **antes do fade**. O sistema verifica estrutura, IDs, direção, limites, sólidos e todo o segmento inicial da fila com seu volume. Uma área ainda não visitada é preparada temporariamente e só entra no cache ao confirmar a troca. Na metade do fade, o espaço é revalidado e a área é trocada com a tela coberta. Se a validação falhar, a origem continua utilizável, sem cache parcial, perda de estado ou bloqueio permanente. O HUD mostra o erro até novo movimento/interação.

Fade experimental: **0,36 s**, metade para escurecer e metade para revelar, avançado pelo mesmo tick da exploração. O quadro da troca fica preto mesmo quando um passo cruza a metade do tempo. Passos grandes concluem uma única transição. Durante esse tick não se avança patrulha nem se aplica movimento acumulado à área recém-chegada. Não há coroutine/tween antigo que possa concluir depois de Reiniciar teste.

Somente a área ativa recebe simulação; menu/diálogo/batalha/transição também pausam seu movimento. Não há tempo simulado ao retornar a áreas inativas. Rotas mantêm posição, segmento e progresso. O combate guarda também a área de origem do encontro, e as guardas impedem viagens durante a luta ou Game Over. Vitória/fuga mostram novamente o mesmo mapa e fila, sem usar entradas de viagem.

## Arquivos criados e alterados

| Arquivo | Mudança |
| --- | --- |
| `data/areas.json` | Novo catálogo e duração provisória da transição. |
| `data/house.json` | Novo interior pequeno com paredes, móveis, entrada e saída. Sem monstros ou NPCs adicionais. |
| `scripts/exploration/area_catalog.gd` | Novo carregador de definições e validação básica. |
| `data/exploration.json` | Identidade da área externa, casa sólida provisória, entrada e portal; elementos anteriores preservados. |
| `scripts/exploration/exploration_model.gd` | Plano seguro de chegada, bloqueios e entidade de transição. |
| `scripts/exploration/exploration_session.gd` | Estado por área, fade determinístico, validação, erros e identificação da origem de batalha. |
| `scripts/exploration/exploration_test.gd` | Catálogo, nome da área e overlay de fade. |
| `scripts/exploration/exploration_view.gd` | Casa, portal e rodapé adequado a mapas de dimensões diferentes. |
| `tests/area_tests.gd` | Novos testes de modelo e integração. |
| `tests/area_ui_smoke.gd` | Novos testes de controles, fade, apresentação e retorno do combate. |
| `tests/interaction_ui_smoke.gd` | Contagem atualizada de 15 para 16 entidades externas, incluindo o portal. |
| Documentação e `AGENTS.md` | Autorização, limites, arquitetura, uso e validação. |

A cena principal, configuração do projeto, lançadores, todos os scripts/dados de combate e a cena independente do laboratório permanecem preservados.

## Testes

```sh
godot --headless --path . --script res://tests/area_tests.gd
godot --headless --path . --script res://tests/area_ui_smoke.gd
```

As dez suítes anteriores continuam no README. Para capturas opcionais, execute a suíte de UI com renderização gráfica e acrescente `-- --visual-captures=/caminho/absoluto/existente`.

Cobertura: catálogo/entradas, ida/volta, líder escolhido em ambas as áreas, ordem, recursos, trilha segura, pausas, objetos, vitória externa real, progressão exata de patrulha, fases do fade, passos grandes, guardas de menu/diálogo/batalha/derrota, destino inexistente/malformado, entrada inválida, direção inválida, líder/cauda/trecho bloqueados, revalidação, reentrada e reinício. Uma configuração exclusiva dos testes adiciona encontro no interior para verificar fuga/vitória/retorno à segunda área; esse monstro não existe na casa jogável. Resultados executados em [VALIDACAO.md](VALIDACAO.md).
