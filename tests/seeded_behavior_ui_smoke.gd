extends SceneTree
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var lab
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-captures="):
			capture_directory = arg.trim_prefix("--visual-captures=")
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
	lab._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)
	if lab.debug_window.visible:
		expect(lab.debug_window.get_texture().get_image().save_png(capture_directory.path_join(name + "-debug.png")) == OK, "Captura F3 " + name)

func start(index: int = 10, seed_value: int = 421) -> void:
	lab.preset_picker.select(index)
	lab.seed_input.value = seed_value
	lab.mode_picker.select(1)
	lab._start(false)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	lab.pause_button.button_pressed = false
	lab.speed_slider.value = 1.0

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	expect(lab.model.preset["id"] == "lab_seeded" and lab.preset_picker.selected == 10, "Laboratório inicia na nova versão")
	expect(lab.preset_picker.item_count == 15, "Cinco opções atuais e dez anteriores")
	for index in range(15):
		expect(lab.preset_picker.get_item_text(index).begins_with("Legado · ") == (index < 10), "Todas as opções anteriores marcadas como legadas")
	start()
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect("Semente da batalha: 421" in lab.debug_text.text and "último sorteio" in lab.debug_text.text and "foco" in lab.debug_text.text, "F3 exibe semente, decisões, pausas e atenção visual")
	for index in range(25):
		lab._process(0.1)
	await capture("seeded-default")
	var actor = lab.model.enemies[0]
	lab.pause_button.button_pressed = true
	var saved: Dictionary = actor["route_state"].duplicate(true)
	lab._process(0.2)
	expect(actor["route_state"] == saved, "Pausa manual congela também o RNG de movimento")
	var expected = saved.duplicate(true)
	var ui_step: float = lab.definitions["settings"]["fixed_step"]
	Route.advance(expected, ui_step)
	Route.advance(expected, ui_step)
	lab._step()
	expect(actor["route_state"] == expected, "Passo usa o mesmo estado e sorteios da simulação")
	var elapsed: float = actor["route_state"]["behavior"]["elapsed"]
	lab.speed_slider.value = 2.0
	lab.pause_button.button_pressed = false
	lab._process(0.1)
	expect(absf(actor["route_state"]["behavior"]["elapsed"] - elapsed - 0.2) < STEP * 1.1, "Velocidade 2x escala movimento e pausas")
	lab.speed_slider.value = 1.0
	lab.model.debug_ready_allies()
	lab.model.select_actor("p1")
	lab.mode_picker.select(0)
	lab.mode_picker.item_selected.emit(0)
	saved = actor["route_state"].duplicate(true)
	lab._process(0.2)
	expect(actor["route_state"] == saved, "Wait congela decisões durante seleção")
	lab.mode_picker.select(1)
	lab.mode_picker.item_selected.emit(1)
	lab._process(0.1)
	expect(actor["route_state"] != saved, "Active retoma durante seleção")
	lab.model.cancel_selection()
	var flyer = lab.model.enemies[2]
	var guard = 0
	while flyer["route_state"]["behavior"]["movement_phase"] != "pause" and guard < 1200:
		lab._process(STEP)
		guard += 1
	if guard >= 1200:
		# Amostra até um minuto sem acelerar a política em função dos frames.
		while flyer["route_state"]["behavior"]["movement_phase"] != "pause" and guard < 7200:
			lab._process(STEP)
			guard += 1
	expect(guard < 7200, "Interface alcança pausa real do voador")
	var position: Vector2 = flyer["logical_position"]
	var before: Vector2 = lab.board.actor_visual_position(flyer)
	flyer["ini_modifier"] = 0.0
	var atb: float = flyer["atb"]
	lab._process(0.1)
	expect(flyer["logical_position"] == position and lab.board.actor_visual_position(flyer) != before, "Voador paira visualmente sem avançar no caminho")
	expect(flyer["atb"] > atb, "ATB carrega ao pairar")
	flyer["ini_modifier"] = -float(flyer["ini"])
	lab.pause_button.button_pressed = true
	await capture("seeded-hover")
	saved = flyer["route_state"].duplicate(true)
	var visual_origin: Vector2 = lab.board.actor_visual_position(flyer)
	lab.model._begin_action(flyer, lab.definitions["skills"]["all"], "", Vector2.ZERO, "")
	guard = 0
	while not lab.model.action["applied"] and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 120 and lab.board.actor_visual_position(flyer).is_equal_approx(lab.model.visual_center()), "Tela inteira chega ao centro exato durante pausa de voo")
	expect(flyer["route_state"] == saved, "Ação preserva pausa e RNG já sorteados")
	await capture("seeded-fullscreen")
	guard = 0
	while not lab.model.action.is_empty() and guard < 120:
		lab.model.tick(STEP)
		guard += 1
	expect(guard < 120 and flyer["route_state"] == saved and lab.board.actor_visual_position(flyer) == visual_origin, "Retorno recupera fase visual e estado exatos")
	var first_pause: float = lab.model.enemies[0]["route_state"]["behavior"]["history"][0]["pause"]
	start(10, 733)
	expect(lab.model.simulation_seed == 733 and lab.model.enemies[0]["route_state"]["behavior"]["history"][0]["pause"] != first_pause, "Campo de semente altera a amostra de movimento")
	for index in range(11, 15):
		start(index)
		lab.pause_button.button_pressed = true
		expect(lab.model.preset["id"] not in lab.definitions["legacy_preset_ids"], "Seletor abre formação atual")
		await capture("seeded-formation-%d" % index)
	lab.debug_window.hide()
	lab.queue_free()
	await process_frame
	print("COMPORTAMENTO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
