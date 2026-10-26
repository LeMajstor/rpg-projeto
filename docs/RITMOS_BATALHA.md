# Ritmos programados dos inimigos na batalha

**Versão vigente:** a evolução por semente foi implementada no laboratório e nos seis encontros da exploração. Todos os modelos descritos abaixo são agora legados; documentação e controles atuais em [COMBATE_SEMENTE.md](COMBATE_SEMENTE.md). Orientação, inversões, pausas e novas formações não estão mais pendentes.

## Registro histórico — ritmos programados

## Adoção anterior nos encontros de exploração

**Decisão posterior confirmada:** o modelo refinado de F passa a ser o padrão para **todos os seis encontros** do laboratório de exploração. Os modelos anteriores ficam legados. A adoção preserva formações iniciais, quantidade/atributos dos participantes, perfis de alvo, habilidades, cenário, exceções de tela inteira e permissões de fuga; muda somente a configuração de movimento e sua apresentação provisória. Os estáticos continuam estáticos.

| Encontros | Preset atual | Movimento dentro da batalha |
| --- | --- | --- |
| M1 e M5 | `exploration_open` / Dungeon · formação aberta | Pesado com retornos parciais; voador com arcos amplos próximos ao grupo; estático. |
| M2 | `exploration_clustered` / Dungeon · sem fuga | Ágil com ida/volta assimétricas; pesado com retornos parciais; estático. Fuga continua bloqueada. |
| M3 e M6 | `exploration_motion` / Dungeon · voo amplo | Ágil com pausas; voador com aproximações amplas; estático. |
| M4 | `exploration_fullscreen` / Dungeon · tela inteira | Pesado com ritmo atual; dois estáticos. Ações de tela inteira e exceção de centro preservadas. |

As rotas começam nos mesmos spawns anteriores, e os aliados conservam seus slots. As aproximações são adaptadas a cada formação, em dados; não há sorteio ou reimplementação do combate. Patrulhas e posições dos monstros **antes da batalha**, no mapa, permanecem iguais.

O laboratório independente abre automaticamente em **F · aproximações e voo amplo**. O campo `default_preset_id` define essa entrada para a UI/sessão; na ausência de um ID válido, mantém compatibilidade com o primeiro preset. `legacy_preset_ids` identifica A–E: o seletor mostra **Legado · …**, disponíveis somente para consulta/regressão manual. Nenhum encontro do catálogo jogável referencia esses IDs; as fixtures históricas continuam exclusivas dos testes. A preservação anterior de A–D como modelos usados pela dungeon foi substituída por esta decisão.

Para testar no fluxo normal, reabra `Executar exploracao.command`, entre na dungeon e interaja com qualquer M1–M6 usando **E**. Não é necessário forçar preset. Use **Active** com **Pausa desligada** e F3 dentro da batalha para observar o ritmo; em Wait, a seleção de um aliado pronto pausa as rotas. M1/M3/M5/M6 incluem voo amplo. Vitória/fuga retornam à dungeon com HP/MP preservados; M2 não permite fuga.

Arquivos desta migração: `data/lab.json` (quatro presets atuais, IDs legados e padrão), `data/dungeon.json` (seis referências e rótulos), `data/house.json` (instrução do NPC), `battle_model.gd` (resolução do padrão), `combat_lab.gd` (início atual e identificação dos legados), `exploration_session.gd` (inicialização compartilhada atual), testes e documentos. As regras de ATB/ações/rota e o movimento de exploração não foram reescritos.

## Confirmado e implementado — 25/10/2026

Melhorar o movimento **dentro da tela de batalha**: aceleração/desaceleração suaves, pausas programadas, ida e volta, sequências com ritmos diferentes e velocidades por tipo, ajustáveis pelo encontro. Preservar rotas determinísticas, ATB, perfis de alvo, melee, técnicas de tela inteira e retorno/retomada exatos. Os monstros no mapa de exploração permanecem com o movimento anterior.

**Origem da demonstração:** E (`lab_rhythm`, agora legado) e F (`lab_approach`, modelo atual) introduziram os três perfis de teste e um estático. Esses perfis agora também alimentam os quatro presets atuais da dungeon:

| Participante | Demonstração |
| --- | --- |
| E1 · Pesado | Curva aberta lenta, paradas longas e sequência com retornos parciais antes de avançar novamente. |
| E2 · Ágil | Outra curva aberta, velocidade habitual menor e arrancadas curtas; pausas e velocidades diferentes na volta. |
| E3 · Voador | Curva fechada assimétrica, diferentes velocidades ao longo do percurso, sem parar no fechamento; leve flutuação e inclinação visuais. |
| E4 · Estático | Mantém posição; serve como referência de comparação. |

**Refinamento autorizado nesta etapa:** reduzir as velocidades por tipo e aumentar repousos, tornando a repetição menos evidente. O pesado usa uma sequência como avançar um pouco → avançar mais → recuar parcialmente → avançar até o fim → voltar em trechos. O ágil usa ritmo diferente na ida e na volta. O voador percorre curvas maiores com vários arcos e mudanças suaves de velocidade.

**F** reutiliza os mesmos tipos e posições iniciais de E, com outra geometria: terrestres chegam mais à região central e o voador aproxima-se do grupo, afasta-se e cruza outros arcos antes de repetir. As aproximações são autoradas pelo preset, sem perseguição nem sorteio; não alteram a posição dos aliados. Na geometria de teste, o voo conserva distância dos corpos aliados. Proximidade não cria contato/dano automático nem regra nova de combate. O posicionamento lógico do inimigo continua contando para habilidades de área.

As velocidades de referência **experimentais** passaram de 52→32 (pesado), 120→72 (ágil) e 150→90 (voador), em unidades/s. Multiplicadores dos trechos e pausas também foram ajustados; não são valores definitivos de balanceamento. A velocidade global de simulação permanece independente desses ajustes.

A/B/C/D foram conservados apenas como referências legadas. Fichas, custos, duração de ação, INI e pesos de alvo foram preservados integralmente na migração. Os três móveis novos usam os mesmos atributos/ações do antigo tipo móvel, diferenciando somente nome provisório, cor e movimento. Velocidade de rota não altera INI nem ATB. Pausas de deslocamento não impedem carregamento ou execução de ações.

## Como executar e observar

1. Abra `Executar laboratorio.command`, ou `scenes/combat_lab.tscn` com F6 no editor.
2. O laboratório abre em **F · aproximações e voo amplo**. Para experimentar outra formação atual, escolha uma opção **Dungeon · …** e **Novo teste**. Selecione **Active**, deixando **Pausa** desligada: o tempo avança automaticamente.
3. Observe os dois terrestres reduzindo velocidade antes de parar e invertendo o sentido. O voador varia o ritmo sem parar. Compare depois com **F · aproximações e voo amplo → Novo teste**: espere o voador chegar perto do grupo; use F3 para enxergar a amplitude total.
4. Abra **F3**: além das coordenadas e segmentos, cada móvel mostra perfil de movimento, velocidade em unidades/s, etapa, sentido e pausa restante. Durante a ação, a janela indica que a velocidade exibida está preservada para retomada.
5. Use a velocidade de simulação de **0,25×** para observar transições; **Espaço** pausa tudo. **Passo +1/60 s** executa dois ticks existentes de 1/120 s e continua respeitando Wait.
6. Em F3, deixe aliados prontos, ataque o voador e use **Onda**. Observe aproximação/impacto/retorno. Os inimigos também usam seu fluxo normal de escolha de ações/alvos.
7. Em **Wait**, selecionar um aliado pronto congela ATB e todos os relógios de movimento. Cancelar a seleção retoma. Em **Active**, eles continuam durante seleção. Uma ação já iniciada ainda pode concluir ao mudar para Wait, conforme a política anterior.
8. **Novo teste/F5** reproduz formação, pausas iniciais e sequências. Na exploração, todos os encontros usam os novos presets automaticamente.

Também é possível iniciar diretamente:

```sh
godot --path . --scene res://scenes/combat_lab.tscn -- --preset=lab_rhythm
godot --path . --scene res://scenes/combat_lab.tscn -- --preset=lab_approach
```

## Configuração reutilizável em dados

`data/lab.json` contém `movement_profiles`. O tipo pode indicar `movement_profile`; a entrada do encontro pode substituí-lo. A resolução usa:

1. Perfil de movimento escolhido pelo encontro ou pelo tipo.
2. Campos `speed`/`motion` do tipo, se presentes.
3. Campos `speed`/`motion` individuais do encontro.

Os subdicionários `rhythm` e `presentation` são mesclados, permitindo alterar só uma pausa sem apagar os demais campos. Arrays, como `steps`, são substituídos integralmente. A rota geométrica e o spawn continuam pertencendo ao preset. Nenhum dado fonte é alterado durante a simulação.

Exemplo **experimental**, baseado no perfil pesado atual:

```json
{
  "speed": 32,
  "motion": {
    "kind": "ground",
    "curve": "smooth",
    "rhythm": {
      "pattern": "sequence",
      "acceleration": 1.2,
      "deceleration": 1.0,
      "initial_pause": 0.8,
      "steps": [
        {
          "to": 0.28,
          "speed_scale": 0.65,
          "pause": 2.0
        },
        {
          "to": 0.64,
          "speed_scale": 0.85,
          "pause": 1.2
        },
        {
          "to": 0.43,
          "speed_scale": 0.55,
          "pause": 2.8
        },
        {
          "to": 1.0,
          "speed_scale": 1.0,
          "pause": 3.6
        },
        {
          "to": 0.72,
          "speed_scale": 0.7,
          "pause": 0.7
        },
        {
          "to": 0.0,
          "speed_scale": 0.8,
          "pause": 3.0
        }
      ]
    },
    "presentation": {
      "lean": 0.06
    }
  }
}
```

| Campo | Significado técnico |
| --- | --- |
| `speed` | Velocidade de referência em unidades do campo por segundo de simulação. |
| `rhythm.pattern` | `loop`: caminho fechado; `ping_pong`: caminho aberto com ida e volta; `sequence`: caminho aberto com marcos visitados em ordem explícita, incluindo retornos parciais. |
| `acceleration`, `deceleration` | Durações das transições de velocidade em segundos de simulação. |
| `initial_pause` | Espera apenas no início do encontro, útil para não sincronizar participantes. |
| `turn_pause` | Espera no ponto inicial após cada retorno em `ping_pong`. |
| `steps[].to` | Fração da distância total da rota (0 a 1). Em `loop`/`ping_pong`, deve crescer e terminar exatamente em 1. Em `sequence`, pode crescer ou diminuir, sem marcos consecutivos iguais, e deve terminar exatamente em 0 para fechar sem salto. |
| `steps[].speed_scale` | Multiplicador da velocidade de referência no trecho. |
| `steps[].pause` | Espera após chegar ao marco; ATB continua. No `ping_pong`, é também o padrão de pausa desse marco no retorno. |
| `steps[].return_speed_scale` | Velocidade do mesmo trecho na volta de `ping_pong`; padrão igual à ida. |
| `steps[].return_pause` | Pausa no mesmo marco durante a volta de `ping_pong`; padrão igual à ida. A pausa ao voltar ao início usa `turn_pause`. |
| `steps[].end_speed_scale` | Velocidade ao terminar o trecho, para conectar etapas contínuas de um `loop`. Padrão zero; pausas e `ping_pong` exigem parada. O último valor também define a velocidade inicial do loop, evitando salto na emenda. Em `sequence`, toda reversão de sentido freia até zero, inclusive na emenda, mesmo com velocidade final não nula configurada. |
| `presentation.lean` | Inclinação visual máxima aproximada, em radianos. |
| `presentation.bob_amplitude`, `bob_period` | Amplitude e período da flutuação visual. Não alteram posição lógica, alvos ou ATB. |

Configuração inválida de ritmo resulta em rota imóvel, sem cronograma infinito. Geometria vazia/degenerada e velocidade zero também ficam imóveis. Perfis são compilados ao iniciar a luta; editar JSON requer reiniciar o laboratório. A velocidade global da UI escala a mesma simulação, incluindo pausas e ações.

## Arquitetura e escolhas técnicas provisórias

- `route_rhythm.gd`: módulo puro que compila as etapas em aceleração, percurso, desaceleração e pausa. A velocidade transita com uma curva de cosseno; a distância é calculada pela sua integral, evitando dependência da quantidade de frames. Trechos curtos comprimem as durações de transição para caberem na distância. Passos grandes descartam ciclos completos por módulo.
- `route_motion.gd`: mantém a assinatura antiga; só ativa o novo cronograma quando existe `motion.rhythm`. Curvas abertas usam extremos fixos e não recebem fechamento artificial. A distância do cronograma determina segmento/progresso na polilinha. A exploração continua chamando a API antiga sem ritmo.
- `battle_model.gd`: resolve perfil/tipo/encontro, atualiza orientação dos novos móveis pelo deslocamento e reutiliza o congelamento de rota existente. ATB, escolhas ponderadas e RNG não recebem vínculo com o ritmo.
- `battlefield.gd`: desenha curvas abertas corretamente, aplica inclinação/flutuação e usa a posição visual para clique. A flutuação fica congelada na rota durante a ação e cede suavemente à apresentação, chegando a zero no impacto para manter centro/contato; retorna à mesma fase visual. Sombra e posição lógica permanecem separadas. Efeitos de área usam somente posições lógicas.
- `combat_lab.gd`: acrescenta os dados de ritmo à janela F3. O seletor existente recebe E/F automaticamente pelos dados.

O snapshot de ação já preserva a rota inteira. Agora inclui etapa e tempo decorrido, velocidade atual, sentido, pausa restante, espera inicial e relógio de apresentação. Nenhum desses campos avança durante a ação do participante. Após o retorno, o próximo tick permitido retoma o estado salvo. Isso vale para melee único/múltiplo e tela inteira, com centro habilitado ou não; as apresentações existentes continuam em seus módulos próprios.

Velocidades, durações, curvas, coordenadas, inclinações e amplitudes da demonstração são **parâmetros de teste**, sem balanceamento ou bestiário definitivo. O movimento ainda repete uma sequência autorada; não há perseguição, reação a HP/dano, navegação aleatória, pathfinding ou animação artística. Esses comportamentos reativos continuam fora deste recorte.

## Testes

```sh
godot --headless --path . --script res://tests/rhythm_tests.gd
godot --headless --path . --script res://tests/rhythm_ui_smoke.gd
godot --headless --path . --script res://tests/exploration_rhythm_tests.gd
```

Para capturas com renderização real:

```sh
godot --path . --audio-driver Dummy --resolution 1440x960 --script res://tests/rhythm_ui_smoke.gd -- --visual-captures=res://artifacts/rhythm-refined
```

Cobertura: preservação dos dados anteriores em fixture, herança/ajuste sem mutação, distâncias/velocidades calculadas, pausas, inversão, fechamento do voo, limites, determinismo e subdivisão de tempo, passos enormes, geometria degenerada, ATB independente, Wait/Active, clique visual, efeitos de área e interrupção/retomada em cada fase. Novos casos cobrem retornos parciais, fechamento exato, frenagem nas reversões, ritmos diferentes na ida/volta e aproximação/afastamento no preset F. UI também cobre pausa manual, passo, velocidade 2×, seleção/comando, centro visual exato do voador, acesso a F e ataque no trecho próximo aos aliados. Resultados efetivamente executados em [VALIDACAO.md](VALIDACAO.md).

A suíte `exploration_rhythm_tests.gd` percorre todos os encontros do catálogo real: ausência de referências legadas, preservação de formações/atributos/alvos/ações/fuga, ritmos em todos os móveis, estáticos e exceções de centro, geometria/aproximações, Wait/Active, agendamento inimigo por ATB, retorno/retomada, UI compartilhada, patrulhas do mapa pausadas, fuga/reencontro determinístico e vitória com HP/MP persistentes. Também valida o padrão F e os rótulos Legado.
