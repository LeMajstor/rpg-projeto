# Relógio global e ciclo de dia/noite — 24/10/2026

## Requisitos confirmados

- Um horário compartilhado entre todas as áreas, preservado nas viagens e no combate integrado.
- Avanço natural exclusivamente em áreas explicitamente classificadas/habilitadas como mapa-múndi. Aparência externa, nome do mapa e `is_outdoor` não autorizam avanço.
- **Configuração aprovada agora:** ciclo completo de 24 horas em **2 minutos reais permitidos (120 segundos)**.
- Amanhecer, dia, entardecer e noite derivados do horário, com limites configuráveis.
- Eventos podem definir qualquer horário ou avançar minutos mesmo quando o avanço natural está pausado. Mudanças notificam interessados.
- Descansar em pousada **define 07:00**, inclusive se antes eram 10:00, 18:00, 23:00 ou 03:00.
- Iluminação gradual na apresentação, com personagens e interface legíveis.
- Ferramentas de depuração e testes isolados; sem nova vila, mapa-múndi completo, castelo, chefe, clima, calendário, rotina complexa ou pousada completa.

O cenário de castelo às 22:00 seguido de evento às 08:00 é um caso de teste, não conteúdo da aventura.

**Atualização autorizada:** o mundo aberto existente (`test_world`) agora é o mapa-múndi de testes e avança automaticamente, sem depender de F3. Entrar em cidade, interior ou dungeon pausa o relógio. A antiga prévia automática de depuração foi removida para não simular passagem natural em outras áreas. Ser um ambiente externo não basta: uma cidade externa continua pausada. Alterações explícitas por eventos e descanso permanecem válidas nas áreas pausadas.

## Arquitetura

`ExplorationSession` é a autoridade existente da partida e agora possui **uma instância de `WorldClock`**, exposta por `session.clock`. Modelos de área e o laboratório integrado não criam relógios próprios. Isso mantém os testes isolados e evita acrescentar Autoload ou um segundo gerenciador de estado. O laboratório de combate independente permanece um laboratório separado, sem passagem de tempo de aventura.

`world_clock.gd` é RefCounted: recebe configuração e deltas explícitos, guarda minutos fracionários desde meia-noite e calcula consultas/períodos. Não conhece cores, cenas, áreas ou ATB. Não usa o relógio do computador. Ao atravessar meia-noite, normaliza para `[0, 1440)`. Não há contador de dias nem calendário.

`ExplorationSession.tick` decide se o contexto permite `advance_natural(delta)`. Trocar de área não copia/recria o relógio. Durante transição, o mesmo objeto continua disponível; mudanças narrativas podem ocorrer sob o fade e o destino consulta o horário atualizado antes de ser revelado. Não se transfere tempo residual do fade para a área de chegada.

Escolha técnica provisória: menu, diálogo, batalha, derrota e transição pausam o avanço natural; ao fechar, retoma sem recuperar tempo pausado. Ficar parado em um mapa-múndi habilitado não pausa o relógio. ATB e velocidade do laboratório continuam independentes.

`day_lighting.gd` interpola uma paleta visual independente, carregada uma vez pela vista. `exploration_view.gd` aplica um único retângulo de cor depois do cenário/atores e antes do debug/rodapé. HUD, menus e diálogos estão fora desse passe. A vista escuta `time_changed` para redesenhar imediatamente e desconecta o relógio anterior ao reiniciar. A otimização da câmera/copa permanece; não há consulta de horário ou iluminação por vértice.

## Configuração atual e parâmetros provisórios

Em `data/world_clock.json`:

| Parâmetro | Valor atual |
| --- | --- |
| `initial_time` | `[10, 0]` |
| `day_duration_seconds` | **`120`: ciclo completo em 2 minutos reais permitidos**, aprovado pelo usuário |
| `periods[].start_minute` | Amanhecer 300, dia 420, entardecer 1020, noite 1140 |
| Períodos resultantes | Amanhecer 05–07; dia 07–17; entardecer 17–19; noite 19–05 |

Cada período contém `id`, `label` e `start_minute`, ordenados pelo início. Os IDs `dawn`, `day`, `dusk` e `night` são estáveis para consultas. Configuração inválida é detectada por `WorldClock.valid_settings`; o construtor exige configuração válida. Frações de minuto são preservadas para progressão visual contínua. Os limites não estão espalhados pela lógica.

**07:00 no descanso é regra confirmada**, independente do limite configurável do período diurno. A operação define esse horário, sem calcular a próxima manhã nem inventar dias de calendário.

Em `data/day_lighting.json`, `keyframes` contém horário em minutos e `rgba`. A interpolação é contínua, inclusive à meia-noite; a noite atual usa opacidade máxima de 0,38 para preservar legibilidade. A paleta é uma escolha artística provisória. Ao mudar os limites temporais, ajuste os keyframes visuais se quiser manter a mesma correspondência entre cores e períodos; eles são configuráveis separadamente.

## Configuração de áreas

O mapa-múndi atual e futuras áreas equivalentes usam **ambos**:

```json
{
  "area_type": "overworld",
  "time_advances": true,
  "lighting_profile": "cycle"
}
```

Uma área sem metadados é pausada por padrão. `overworld` com `time_advances: false` também pausa. O catálogo rejeita avanço habilitado em um tipo diferente de `overworld`, campos com tipos incorretos e perfil de iluminação desconhecido.

| Área atual | Tipo | Avanço natural | Iluminação |
| --- | --- | --- | --- |
| Vila / `lab_exterior` | `town` | Pausado | `cycle`, consulta horário global |
| Casa original / `test_house` | `interior` | Pausado | `fixed` |
| Segunda casa / `secret_house` | `interior` | Pausado | `fixed` |
| Dungeon / `test_dungeon` | `dungeon` | Pausado | `fixed` |
| Mapa-múndi de testes / `test_world` | `overworld` | **Automático** | `cycle` |

O mundo aberto existente foi explicitamente habilitado como mapa-múndi pelo pedido mais recente, sem criar outra área. O relógio avança inclusive parado, desde que fora das pausas. A iluminação fixa dos interiores é uma decisão técnica de apresentação: eles preservam e podem consultar o horário, sem escurecer com o céu.

## Consultas, eventos e descanso

```gdscript
var clock = session.clock
print(clock.time_text())          # "10:00"
print(clock.hour(), clock.minute())
print(clock.minutes_of_day())     # Inclui a fração do minuto.
print(clock.period())             # ID estável, por exemplo "night".
print(clock.period_label())       # Rótulo configurado.
if clock.is_night():
    pass                         # Consulta disponível para futuros sistemas.

clock.set_time(22, 0)             # Define horário; permite voltar para uma hora anterior.
clock.advance_time(180)           # Agora 01:00, mesmo em cidade/interior pausado.
clock.set_time(8, 0)              # Evento/cutscene pode fazer isso durante o fade.
session.rest_at_inn()             # Sempre define 07:00 no MESMO relógio.

clock.time_changed.connect(func(minutes): print(minutes))
clock.period_changed.connect(func(period_id): print(period_id))
```

Operações retornam `bool`. Horas fora de 0–23, minutos fora de 0–59, avanços negativos ou não finitos são recusados sem alterar estado. Não há notificação quando o valor final não muda. Os sinais descrevem o estado final; não são um agendador que dispara eventos para cada período saltado por um avanço grande. `advance_natural(seconds)` é a conversão de segundos permitidos em minutos; quem autoriza seu uso no jogo é a sessão.

A API de descanso é somente temporal: não cura, revive, consome dinheiro, cria pousada ou toca fade. Um futuro fluxo autorizado pode coordenar essas operações e então chamar a mesma API. A operação de descanso não cria cutscenes. O experimento narrativo local posterior está em [EVENTOS_DIA_NOITE.md](EVENTOS_DIA_NOITE.md).

## Exemplo mínimo de interação

O NPC 5 da vila mantém seu diálogo diurno anterior e acrescenta uma fala noturna de teste por `dialogue_by_period: {"night": "clock_night"}`. A sessão escolhe a variante ao iniciar a interação. E, botão contextual, proximidade, nome, avanço e pausa permanecem os mesmos. Uma fala já aberta não troca no meio se um evento mudar a hora. `dialogue_model.gd` não precisou ser modificado; não há linguagem de condições ou rotina de NPC.

## Testar pelo protótipo

Abra **Executar exploracao.command** ou F5 no projeto. **Não é preciso ativar nenhuma opção para o tempo correr.**

1. Na vila, o relógio inicia às 10:00 e permanece pausado. A casa e a dungeon também pausam o avanço natural.
2. Saia pelo portão para o mapa-múndi. O horário avança automaticamente e a luz acompanha o ciclo, mesmo parado. Cada 5 segundos reais permitidos equivalem a uma hora do jogo; 120 segundos completam as 24 horas.
3. F3 consulta horário, período, classificação e estado do avanço. Abrir/fechar esse painel não habilita nem desabilita o relógio. A prévia antiga e seu multiplicador foram removidos.
4. Entre na dungeon: o horário de chegada permanece. Saia: o tempo retoma. Volte à vila: pausa novamente. Transições preservam a hora e não transferem tempo residual do fade.
5. Menu de equipe, diálogo e batalha mantêm suas pausas. Voltar à exploração do mapa-múndi retoma sem acumular o tempo pausado.
6. Os botões de F3 continuam testando operações **explícitas**: definir hora/minuto, evento +180 minutos, evento 08:00 e descanso 07:00. Funcionam mesmo em área pausada; não são avanço natural nem pousada completa. Clique nos campos para editar; confirmar/Enter ou fechar F3 libera o foco. Tab fora da edição mantém o menu da equipe.
7. Teste o NPC 5 de dia/noite. Reiniciar teste cria uma sessão/relógio novos às 10:00 na vila.

O painel só é criado em builds de desenvolvimento (`OS.is_debug_build()`); não é uma funcionalidade definitiva de jogabilidade. Acesso independente ao combate, comandos e regras existentes permanecem iguais.

## Arquivos e validação

| Arquivos | Responsabilidade |
| --- | --- |
| `data/world_clock.json`, `scripts/exploration/world_clock.gd` — novos | Configuração e modelo temporal com sinais/APIs. |
| `data/day_lighting.json`, `scripts/exploration/day_lighting.gd` — novos | Paleta e interpolação visual. |
| `scripts/exploration/clock_debug.gd` | Painel de consultas/eventos manuais, sem avanço automático próprio. |
| `scripts/exploration/exploration_session.gd` | Instância única, política de avanço, descanso e variante de diálogo. |
| `scripts/exploration/area_catalog.gd` | Validação dos metadados e das referências de diálogos. |
| `scripts/exploration/exploration_view.gd` | Passe de iluminação e assinatura/desconexão do sinal do relógio. |
| `scripts/exploration/exploration_test.gd` | F3, vínculo do painel com a sessão e proteção do foco/controles. |
| `data/exploration.json`, `house.json`, `dungeon.json`, `world.json` | Classificação, pausa e perfil visual explícitos; apenas NPC 5 ganha variante. |
| `tests/world_clock_tests.gd`, `world_time_tests.gd`, `day_lighting_tests.gd`, `world_clock_ui_smoke.gd` — novos | Modelo, áreas/eventos, iluminação e UI/combate/viagens. |
| `tests/render_performance.gd` | Inclui medição noturna e mantém orçamento de câmera. |
| GDD, decisões, pendências, instruções, README e validação | Regras, limites, configuração e resultados. |

Movimento/colisão/fila, módulo de câmera, rotas, `dialogue_model.gd`, scripts/dados/cena do combate, catálogo topológico e lançadores não foram reimplementados. A mudança é compatível com as fixtures históricas sem metadados temporais.

```sh
godot --headless --path . --script res://tests/world_clock_tests.gd
godot --headless --path . --script res://tests/world_time_tests.gd
godot --headless --path . --script res://tests/day_lighting_tests.gd
godot --headless --path . --script res://tests/world_clock_ui_smoke.gd
```

Para capturas, execute a última suíte com janela e `-- --visual-captures=/caminho/absoluto/existente`. As regressões anteriores e a medição gráfica de desempenho continuam no README. Resultados efetivamente executados em [VALIDACAO.md](VALIDACAO.md).

Ficam para o futuro: mapa-múndi definitivo, agenda/eventos narrativos, rotina de habitantes, economia/recuperação/visual de pousada, calendário, clima, salvamento do horário em disco e iluminação artística. Exportação de release e outras plataformas não foram verificadas.

A vila agora inclui a segunda casa e o experimento O Segredo da Casa. Posições/diálogos/flags e luzes locais estão em `EVENTOS_DIA_NOITE.md`; não alteram este relógio nem as regras de avanço.
