extends SceneTree
const Route = preload("res://scripts/combat/route_motion.gd")
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura do campo " + name)
	if lab.debug_window.visible:
		expect(lab.debug_window.get_texture().get_image().save_png(capture_directory.path_join(name + "-debug.png")) == OK, "Captura da depuração " + name)

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	lab.preset_picker.select(4)
	lab._start(false)
	lab.mode_picker.select(1)
	lab.mode_picker.item_selected.emit(1)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	expect(lab.model.preset["id"] == "lab_rhythm" and lab.preset_picker.item_count == 15, "Presets atuais acessíveis junto das referências legadas")
	lab.pause_button.button_pressed = true
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect("ritmo heavy_test" in lab.debug_text.text and "pausa inicial" in lab.debug_text.text, "F3 identifica perfil e pausa inicial")
	await capture("rhythm-start")
	var heavy = lab.model.enemies[0]
	var saved: Dictionary = heavy["route_state"].duplicate(true)
	lab._process(0.25)
	expect(saved == heavy["route_state"], "Pausa manual congela cronograma")
	lab._step()
	expect(saved != heavy["route_state"] and heavy["logical_position"] == Vector2(510, 125), "Passo desconta pausa sem mover posição")
	lab.pause_button.button_pressed = false
	lab.speed_slider.value = 2.0
	var before: float = heavy["route_state"]["rhythm"]["initial_pause_remaining"]
	lab._process(0.1)
	expect(absf(before - heavy["route_state"]["rhythm"]["initial_pause_remaining"] - 0.2) < STEP * 1.1, "Velocidade 2x também escala pausas programadas")
	lab.speed_slider.value = 1.0
	for index in range(12):
		lab._process(0.1)
	lab.pause_button.button_pressed = true
	lab._refresh()
	expect("u/s" in lab.debug_text.text and "etapa" in lab.debug_text.text and "sentido" in lab.debug_text.text, "Depuração mostra velocidade, etapa e sentido")
	var flyer = lab.model.enemies[2]
	var bob = Route.presentation_offset(flyer["route_state"])
	expect(lab.board.actor_visual_position(flyer) == flyer["logical_position"] + bob, "Renderização aplica flutuação separada")
	await capture("rhythm-moving")
	# Clique na figura provisória flutuante, sem mudar a posição lógica usada pela área.
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[0].pressed.emit()
	var clicked = []
	lab.board.target_clicked.connect(func(id, _point): clicked.append(id))
	var input = InputEventMouseButton.new()
	input.button_index = MOUSE_BUTTON_LEFT
	input.pressed = true
	input.position = lab.board.screen_point(lab.board.actor_visual_position(flyer))
	lab.board._gui_input(input)
	expect(clicked.size() == 1 and clicked[0] == flyer["id"], "Seleção por clique acompanha apresentação visual")
	expect(not lab.model.action.is_empty() and lab.model.action["target_id"] == flyer["id"], "Fluxo normal inicia melee contra voador novo")
	var guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		lab._step()
		guard += 1
	expect(guard < 120 and lab.model.party[0]["visual_offset"] == Vector2.ZERO, "Ataque aliado retorna ao repouso")
	# Suspensão no meio de uma desaceleração, agora com tela inteira.
	guard = 0
	while heavy["route_state"]["rhythm"]["movement_phase"] != "decelerate" and guard < 2000:
		lab._step()
		guard += 1
	expect(guard < 2000, "Alcança desaceleração pela mesma simulação da UI")
	saved = heavy["route_state"].duplicate(true)
	var origin: Vector2 = heavy["logical_position"]
	lab.model._begin_action(heavy, lab.definitions["skills"]["all"], "", Vector2.ZERO, "")
	lab._refresh()
	expect("rota suspensa" in lab.debug_text.text, "Depuração distingue velocidade preservada e rota suspensa")
	for index in range(24):
		lab._step()
	expect(heavy["route_state"] == saved and heavy["logical_position"] == origin, "Técnica ao centro preserva ritmo completo")
	await capture("rhythm-fullscreen")
	guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		# Passo +1 contém dois ticks; observar o tick exato de conclusão.
		lab.model.tick(STEP)
		guard += 1
	lab._refresh()
	expect(guard < 120 and heavy["visual_offset"] == Vector2.ZERO and heavy["route_state"] == saved, "Técnica retorna sem perder desaceleração")
	var expected = saved.duplicate(true)
	var ui_step: float = lab.definitions["settings"]["fixed_step"]
	Route.advance(expected, ui_step)
	Route.advance(expected, ui_step)
	lab._step()
	expect(heavy["route_state"] == expected, "Passo seguinte retoma exatamente o estado salvo")
	# A flutuação não desloca o centro de tela inteira, nem salta ao iniciar/terminar.
	var flyer_saved: Dictionary = flyer["route_state"].duplicate(true)
	var flyer_visual: Vector2 = lab.board.actor_visual_position(flyer)
	lab.model._begin_action(flyer, lab.definitions["skills"]["all"], "", Vector2.ZERO, "")
	expect(lab.board.actor_visual_position(flyer) == flyer_visual, "Início da ação não salta a flutuação visual")
	guard = 0
	while not lab.model.action["applied"] and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 120 and lab.board.actor_visual_position(flyer).is_equal_approx(lab.model.visual_center()), "Voador chega ao centro exato sem offset de flutuação")
	guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 120 and lab.board.actor_visual_position(flyer) == flyer_visual and flyer["route_state"] == flyer_saved, "Retorno recupera exatamente origem visual e fase da flutuação")
	# Wait congela todas as novas etapas; Active as retoma durante seleção.
	lab.model.debug_ready_allies()
	lab.model.mode = "Wait"
	lab.model.select_actor("p1")
	saved = heavy["route_state"].duplicate(true)
	lab.pause_button.button_pressed = false
	lab._process(0.1)
	expect(heavy["route_state"] == saved, "Wait da UI congela velocidade e etapa")
	lab.mode_picker.select(1)
	lab.mode_picker.item_selected.emit(1)
	lab._process(0.1)
	expect(heavy["route_state"] != saved, "Active retoma cronograma durante seleção")
	lab.model.cancel_selection()
	lab._start(false)
	expect(heavy != lab.model.enemies[0] and lab.model.enemies[0]["logical_position"] == Vector2(510, 125), "Novo teste reinicia formação e ritmo")
	# F pode atravessar a parte central do campo e se aproximar do grupo.
	lab.preset_picker.select(5)
	lab._start(false)
	lab.model.mode = "Active"
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	expect(lab.model.preset["id"] == "lab_approach", "Seletor força o novo preset F")
	lab.pause_button.button_pressed = false
	var near_flyer = lab.model.enemies[2]
	guard = 0
	while near_flyer["logical_position"].distance_to(lab.model.party[1]["logical_position"]) > 120 and guard < 900:
		lab._process(0.1)
		guard += 1
	lab.pause_button.button_pressed = true
	expect(guard < 900 and near_flyer["logical_position"].x < 330, "Simulação da UI alcança aproximação ampla programada")
	lab._refresh()
	await capture("approach-near-party")
	var close_saved: Dictionary = near_flyer["route_state"].duplicate(true)
	var close_origin: Vector2 = near_flyer["logical_position"]
	lab.model._begin_action(near_flyer, lab.definitions["skills"]["attack"], "p2", Vector2.ZERO, "")
	guard = 0
	while not lab.model.action["applied"] and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	lab._refresh()
	expect(guard < 120 and near_flyer["route_state"] == close_saved, "Ataque próximo preserva progresso e ritmo do voo amplo")
	await capture("approach-melee-impact")
	guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 120 and near_flyer["logical_position"] == close_origin and near_flyer["visual_offset"] == Vector2.ZERO and near_flyer["route_state"] == close_saved, "Voador próximo retorna sem deslocar a origem")
	lab.debug_window.hide()
	lab.queue_free()
	await process_frame
	print("RITMOS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
