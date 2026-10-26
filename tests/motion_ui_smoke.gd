extends SceneTree
const STEP = 1.0 / 120.0
var lab
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-captures="):
			capture_directory = argument.trim_prefix("--visual-captures=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura gráfica " + name)

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	lab.preset_picker.select(2)
	lab._start(false)
	expect(lab.model.preset["id"] == "lab_motion", "Demonstração C acessível no seletor existente")
	expect(lab.preset_picker.item_count >= 3, "Presets antigos continuam disponíveis")
	lab.mode_picker.select(1)
	lab.mode_picker.item_selected.emit(1)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	var route = lab.model.enemies[1]["route_state"].duplicate(true)
	lab._process(0.1)
	expect(route != lab.model.enemies[1]["route_state"], "Voo avança pelo relógio da interface")
	lab.pause_button.button_pressed = true
	route = lab.model.enemies[1]["route_state"].duplicate(true)
	lab._process(0.3)
	expect(route == lab.model.enemies[1]["route_state"], "Pausa manual congela voo")
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect("air/ellipse" in lab.debug_text.text and "ground/smooth" in lab.debug_text.text, "Depuração distingue curva, voo e percurso terrestre")
	await capture("motion-routes")
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[0].pressed.emit()
	lab.board.target_clicked.emit("e2", lab.model.enemies[1]["logical_position"])
	expect(not lab.model.action.is_empty(), "Comando normal inicia ataque melee")
	lab.pause_button.button_pressed = false
	var guard = 0
	while not lab.model.action["applied"] and guard < 120:
		lab._process(STEP)
		guard += 1
	expect(guard < 120 and lab.model.action["motion"]["phase"] == "impact", "Interface alcança fase de contato")
	lab.pause_button.button_pressed = true
	lab._refresh()
	var offset = lab.model.party[0]["visual_offset"]
	var elapsed = lab.model.action["elapsed"]
	lab._process(0.2)
	expect(lab.model.party[0]["visual_offset"] == offset and lab.model.action["elapsed"] == elapsed, "Pausa manual também congela aproximação/impacto/retorno")
	expect("impact" in lab.debug_text.text and "contato" in lab.debug_text.text, "Depuração mostra fase e posição de contato")
	expect(lab.model.action["motion"]["effect_strength"] > 0 and lab.model.action["impact_points"].size() == 1, "Representação provisória acompanha o efeito real")
	await capture("motion-melee-impact")
	guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		lab._step()
		guard += 1
	expect(guard < 120 and lab.model.party[0]["visual_offset"] == Vector2.ZERO, "Avanço manual conclui retorno sem deslocamento residual")
	# Pausa/velocidade também respeitam a rota de um atacante inimigo.
	var enemy = lab.model.enemies[0]
	route = enemy["route_state"].duplicate(true)
	lab.model._begin_action(enemy, lab.definitions["skills"]["attack"], "p1", Vector2.ZERO, "")
	lab.pause_button.button_pressed = true
	lab._process(0.2)
	expect(lab.model.action["elapsed"] == 0 and enemy["route_state"] == route, "Pausa congela ataque inimigo e seu progresso de rota")
	lab._step()
	expect(lab.model.action["elapsed"] > 0 and enemy["route_state"] == route, "Passo movimenta sprite, preservando a rota")
	elapsed = lab.model.action["elapsed"]
	lab.speed_slider.value = 2.0
	lab.pause_button.button_pressed = false
	lab._process(0.1)
	expect(absf(lab.model.action["elapsed"] - elapsed - 0.2) < STEP * 1.1, "Velocidade 2x escala a mesma simulação de ataque")
	expect(enemy["route_state"] == route, "Velocidade não faz rota avançar durante ação")
	guard = 0
	while not lab.model.action.is_empty() and guard < 240:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 240 and enemy["visual_offset"] == Vector2.ZERO and enemy["route_state"] == route, "Inimigo retorna ao snapshot original também via interface")
	lab.debug_window.hide()
	lab.queue_free()
	await process_frame
	print("MOVIMENTO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
