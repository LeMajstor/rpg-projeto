# Visão direcional — D159

Implementação e parâmetros de teste em [VISAO_DIRECIONAL.md](../../docs/VISAO_DIRECIONAL.md). Frontal180/90° e periférica60/180°; costas sem percepção, contato físico inicia a batalha. Parede/porta bloqueia ambos os campos. Móveis orientam pelo deslocamento real e conservam olhar nas pausas; estáticos mantêm direção configurada.

- `test-results.json`:76 suítes headless,353.355 verificações, zero falhas. Nova suíte direcional165; inimigos individuais289; UI29.
- `graphics.log` e `visual/`:39 verificações gráficas, zero falhas, dez capturas da cena real nos dois andares e aproximação pelas costas.
- `render-verification.log`:91 verificações gráficas, incluindo19 comparações completas de pixels com o desenho sem descarte. Conserva recorte de paredes fora da câmera e contornos de visão nas bordas.
- `render.json`: medições com monstros em movimento e F3 ligado/desligado. Piso2:0,784–0,834 ms de desenho sem F3;1,153–1,202 ms com F3, CPU local. Contornos de estáticos reaproveitados e móveis recalculados conforme orientação/posição, somente com F3.
- `summary.json`: configuração, contagens, métricas e hashes das fontes.

```sh
python3 artifacts/directional-vision-2026-11-15/run_regressions.py
godot --headless --path . --script res://tests/directional_vision_tests.gd
godot --path . --rendering-method gl_compatibility --script res://tests/exploration_pursuit_ui_smoke.gd -- --visual-captures=res://artifacts/directional-vision-2026-11-15/visual
godot --path . --rendering-method gl_compatibility --script res://tests/render_performance.gd
godot --path . --rendering-method gl_compatibility --script res://artifacts/directional-vision-2026-11-15/render_probe.gd -- --report=res://artifacts/directional-vision-2026-11-15/render.json
```

Tempos são medições locais do callback de desenho, não garantia universal de FPS. A sonda força quadros para continuar medindo em segundo plano; seus campos `frame_*` são diagnósticos e não representam tempo total normalizado de quadro. Relatórios anteriores permanecem históricos; o atual substitui a percepção circular D158 sem trocar os layouts, encontros ou regras do combate.
