# Relevo e florestas do mundo — 24/10/2026

## Confirmado pelo usuário

- Colinas funcionam como obstáculos para guiar/bloquear acesso a regiões. Não se atravessa o paredão.
- Quando houver rampa, subir deve produzir sensação gradual de elevação; descer faz o inverso.
- Florestas do mundo são áreas inacessíveis inteiras, inclusive entre suas árvores.
- Manter gráficos provisórios e os sistemas de exploração/combate existentes.

Isso substitui as colinas caminháveis e florestas permeáveis da primeira versão do mundo. Árvores isoladas na vila continuam usando a base do tronco; não se transformam em massas florestais.

## Escolhas técnicas experimentais

O mesmo `test_world` contém um platô com rampa na borda sul e outra colina sem acesso. A segunda foi deslocada para o leste do caminho principal, preservando o percurso vila→dungeon. São formas geométricas com topo, face frontal e faixa inclinada de teste; não há sprites novos elaborados.

`terrain_geometry.gd` transforma definições em retângulos sólidos e fornece a altura de cada ponto. Floresta e colina sem rampa são sólidas inteiras. O platô acessível tem bordas sólidas e abertura alinhada à rampa; as laterais da rampa também bloqueiam. A colisão varrida existente, o raio do líder, `is_walkable`, a visibilidade das interações e a validação de chegada usam esses sólidos. Deltas grandes não atravessam barreiras. Não se cai ou salta das bordas.

Altura não muda coordenadas de chão nem velocidade. Na rampa ela varia linearmente de zero ao valor do platô; no topo é constante. Cada seguidor consulta a altura na **própria posição no histórico do líder**, inclusive nas curvas e reversões. Não copia a altura instantânea do líder. Não há estado vertical acumulado para restaurar ao abrir menu, trocar líder ou mudar de área.

`visual_position(p) = p - Vector2(0, elevation_at(p))`. Sprite, sombra e indicação do líder usam essa projeção; a câmera acompanha os pés elevados, mantendo zoom e limites anteriores. A ordem de desenho usa a borda norte da colina para ocultar quem passa atrás e permitir que quem subiu apareça sobre o topo. Florestas usam sua borda sul; árvores/estruturas e atores mantêm a ordenação anterior. F3 mostra sólidos em coordenadas lógicas, ligação até os pés projetados e alturas individuais.

É relevo 2.5D simples, sem física vertical, sobreposição de andares, pontes/passagens sob o platô, habilidades de travessia, saltos ou quedas. O formato inicial suporta rampa **ao sul, subindo para o norte**. Isso não define todos os tipos de acesso do jogo futuro.

## Dados

Em `data/world.json`, `terrain` aceita, por exemplo:

```json
{
  "kind": "hill",
  "rect": [100, 500, 360, 140],
  "label": "PLATÔ DE TESTE",
  "elevation": 48,
  "cliff_thickness": 8,
  "ramp": {"rect": [340, 640, 96, 120]}
}
```

`rect` descreve o plano lógico, antes da elevação visual. Remover `ramp` torna a colina inteiramente inacessível. `forest` com `rect` gera uma região sólida. `path` e `sand` continuam só visuais. O catálogo rejeita alturas/bordas inválidas, rampa fora da borda sul, largura insuficiente para o líder ou dimensões inválidas. Alturas 48/56, borda 8, dimensões, posições e inclinação são parâmetros técnicos provisórios, não geografia ou balanceamento definitivos.

## Arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/exploration/terrain_geometry.gd` — novo | Geometria pura de colisão, altura e validação. |
| `scripts/exploration/exploration_model.gd` | Integra os sólidos e expõe altura/projeção sem mudar o seguimento. |
| `scripts/exploration/area_catalog.gd` | Valida definições de relevo antes de carregar mapas. |
| `scripts/exploration/exploration_depth.gd` | Inclui colinas/florestas na oclusão. |
| `scripts/exploration/exploration_view.gd` | Relevo simples, projeção de atores/sombras, câmera e debug de altura. |
| `data/world.json` | Barreiras, platô, rampa e desvio visual até o acesso. |
| `tests/terrain_tests.gd` — novo | Barreiras, rampas, continuidade, fila, pausas, validação, visibilidade e oclusão. |
| `tests/terrain_ui_smoke.gd` — novo | Percurso por teclado, alturas, liderança, câmera e capturas. |
| `tests/world_map_tests.gd`, `tests/world_map_ui_smoke.gd` | Substituem a expectativa antiga de colina livre e evitam posições de captura dentro dos novos sólidos. |

Sessão, catálogo de áreas, transições, dados/código/cenas de combate, rotas dos inimigos, diálogos e laboratório independente não foram reimplementados.

## Executar e testar

Abra **Executar exploracao.command** ou execute F5 no projeto. Saia da vila pelo portão a nordeste usando E.

1. No mundo, contorne o marcador da vila pelo **leste** e siga ao norte. O desvio à esquerda conduz à faixa marcada **RAMPA · subir ↑**, ao norte do marcador.
2. Entre pela base da rampa e segure **W/↑**. Observe cada integrante subir quando chega à inclinação; no topo todos repousam na mesma altura.
3. Inverta com **S/↓** no meio da subida e no topo. A fila deve reproduzir a ida/volta sem teleporte ou altura residual.
4. Tente entrar pela lateral, sair da rampa de lado e ultrapassar as bordas do platô. Deve bloquear.
5. Tente atravessar a outra colina e os espaços entre árvores das florestas. Tudo deve bloquear. Árvores isoladas da vila continuam permitindo passar em volta do tronco.
6. Abra Tab/Esc na rampa, troque o líder e continue. A altura e o caminho permanecem nos mesmos slots. F3 exibe os sólidos e `h` de cada integrante.
7. Siga o caminho principal à dungeon, combata e retorne. Vila/casa/dungeon, recursos e laboratório separado continuam disponíveis.

```sh
godot --headless --path . --script res://tests/terrain_tests.gd
godot --headless --path . --script res://tests/terrain_ui_smoke.gd
```

Para capturas reais, execute `terrain_ui_smoke.gd` sem `--headless` e acrescente `-- --visual-captures=/caminho/absoluto/existente`. As vinte regressões anteriores estão no README. Resultados executados em [VALIDACAO.md](VALIDACAO.md).

## Correção de desempenho

Após o relato de lentidão no mundo, o desenho passou a calcular a transformação da câmera uma vez por callback, reutilizar os pontos do círculo unitário das copas e ignorar terreno fora do enquadramento. A otimização é visual; dados, colisões, altura, fila e combate permanecem iguais. A projeção pública continua atual fora do desenho, sem cache obsoleto após viagens ou redimensionamento.

Teste adicional com renderização real e transição pelo relógio normal do jogo:

```sh
godot --path . --audio-driver Dummy --script res://tests/render_performance.gd
```

Opcionalmente, acrescente `-- --report=/caminho/absoluto/relatorio.json`. O teste limita deterministicamente consultas de câmera por desenho e reporta tempos sem impor um FPS universal. Resultados antes/depois em `VALIDACAO.md`.
