# Desempenho da dungeon — correção técnica D158

Relato do usuário: queda de performance no segundo andar. O desenho reconstruía todos os polígonos de paredes, mesmo quando estavam completamente fora da câmera. Andar1 tem 4 paredes poligonais; andar2 tem 30. A correção rejeita essas paredes antes de converter vértices e enviar faces/topos ao renderizador. O teste visual considera chão, faces, topo elevado e margem da linha externa. Não muda colisões, visão, inimigos fora da câmera, rotas, semente ou combate.

Medição local, Godot 4.7.2, Compatibility / Apple M3 Pro, 80 amostras por cenário após 20 de aquecimento:

| Segundo andar, sem F3 | CPU desenho antes | CPU desenho depois | Redução | Chamadas antes → depois |
| --- | ---: | ---: | ---: | ---: |
| Escada /220,1350 |1,262 ms |0,906 ms |28,2% |317 → 145 |
| Galeria /1620,570 |1,590 ms |0,856 ms |46,2% |315 → 160 |

São custos locais do callback de desenho; não constituem garantia universal de FPS. `render_probe.gd` força o desenho após cada quadro para continuar medindo quando a janela fica em segundo plano; o campo `frame_median_usec` desses relatórios é diagnóstico e não deve ser convertido diretamente em FPS. Não houve diferença relevante no custo de simulação das duas áreas na sonda de 600 passos por ponto (~0,35 ms por passo de 1/120 s).

Validação: **12 suítes headless, 9.011 verificações, zero falhas**, incluindo inimigos individuais, escadas, câmera/profundidade, perseguição, relevo, tempo e paridade do combate. **`render_performance.gd`:91 verificações gráficas, zero falhas**, com 19 comparações de imagem completas e exatas contra uma vista que desenha tudo. Cobre os dois andares, 720×480 e 1392×594, F3 e uma parede cuja base está fora da câmera enquanto o topo alto ainda aparece. Estado dos monstros/rotas/fila permanece idêntico após os desenhos. A escada do piso2 também comprova redução de comandos com os mesmos pixels.

```sh
godot --path . --rendering-method gl_compatibility --script res://tests/render_performance.gd -- --report=res://artifacts/dungeon-performance-2026-11-15/world-render-after.json
godot --path . --rendering-method gl_compatibility --script res://artifacts/dungeon-performance-2026-11-15/render_probe.gd -- --report=res://artifacts/dungeon-performance-2026-11-15/render-after.json
godot --headless --path . --script res://artifacts/dungeon-performance-2026-11-15/model_probe.gd
```

`render-before.json` foi coletado antes da correção; `render-after.json` usa os mesmos pontos/parâmetros. `summary.json` agrega métricas e hashes das fontes. `regression.json` e logs registram cada suíte executada. Relatórios anteriores permanecem históricos. A avaliação de fluidez pelo usuário continua sendo o próximo retorno de gameplay.
