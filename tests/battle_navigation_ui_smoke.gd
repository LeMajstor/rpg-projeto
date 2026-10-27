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

func key(code: Key, echo: bool = false) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func pad(button: JoyButton) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func axis(value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func click(point: Vector2) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func finish() -> void:
	var guard = 0
	while not lab.model.action.is_empty() and guard < 240:
		lab.model.tick(STEP)
		guard += 1
	lab._refresh()
	expect(guard < 240, "Ação termina sem travar o fluxo")

func reset() -> void:
	lab._start(false)
	lab.model.mode = "Wait"
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	lab.model.debug_ready_allies()
	lab._refresh()

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	key(KEY_ENTER)
	expect(lab.model.selected_id.is_empty(), "Confirmar não seleciona card sem ATB pronto")
	reset()
	lab.model.party[0]["atb"] = 0.5
	lab.model.party[2]["hp"] = 0
	lab.model.party[2]["atb"] = 0.0
	lab._refresh()
	expect(lab.party_focus_id == "p2" and lab.cards[1]["button"].get_meta("battle_hand").active, "Mão aparece no primeiro card pronto, pulando indisponíveis")
	key(KEY_RIGHT)
	expect(lab.party_focus_id == "p4", "Seta percorre apenas os cards prontos")
	await capture("navigation-cards")
	click(lab.cards[3]["button"].get_global_rect().get_center())
	expect(lab.model.selected_id.is_empty(), "Mouse não seleciona card")
	key(KEY_ENTER)
	expect(lab.model.selected_id == "p4" and lab.command_buttons[0].get_meta("battle_hand").active, "Confirmar transfere foco do card aos comandos")
	expect(lab.cards[3]["style"].border_width_left == 2, "Card escolhido permanece destacado")
	var time: float = lab.model.simulation_time
	lab.model.tick(0.2)
	expect(lab.model.simulation_time == time, "Wait continua pausando durante seleção")
	await capture("navigation-commands")
	key(KEY_RIGHT)
	key(KEY_ENTER)
	expect(lab.menu_kind == "skills", "Teclado abre habilidades")
	key(KEY_DOWN)
	key(KEY_ENTER)
	expect(lab.menu_kind == "target" and lab.board.aiming_skill.get("target") == "circle", "Teclado escolhe habilidade em área")
	key(KEY_RIGHT)
	expect(lab.target_focus_id == "e2" and lab.board.preview()["target"]["id"] == "e2", "Mão aponta ao alvo no campo")
	key(KEY_ESCAPE)
	expect(lab.menu_kind == "skills" and lab.model.selected_id == "p4", "Cancelar alvo volta à lista sem perder executor")
	key(KEY_ESCAPE)
	expect(lab.menu_kind.is_empty() and lab.model.selected_id == "p4", "Cancelar lista volta aos comandos")
	key(KEY_ESCAPE)
	expect(lab.model.selected_id.is_empty() and lab.model.party[3]["atb"] == 1.0, "Cancelar comandos volta aos cards sem custo")
	key(KEY_Z)
	key(KEY_Z)
	key(KEY_RIGHT)
	var target: String = lab.target_focus_id
	click(lab.board.global_position + lab.board.screen_point(lab.model.enemies[1]["logical_position"]))
	expect(lab.model.action.is_empty(), "Mouse no campo não confirma ataque")
	key(KEY_Z, true)
	expect(lab.model.action.is_empty(), "Repetição de tecla não confirma ação")
	key(KEY_Z)
	expect(lab.model.action.get("target_id") == target and lab.model.action.get("actor_id") == "p4", "Fluxo completo confirma ataque do aliado escolhido")
	key(KEY_Z)
	expect(lab.model.completed_actions == 0, "Confirmações extras durante animação não enfileiram ações")
	finish()
	await _test_items()
	await _test_controller()
	_test_invalidation()
	lab.queue_free()
	await process_frame
	await _test_integrated_restart()
	print("NAVEGAÇÃO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_items() -> void:
	reset()
	lab.model.party[0]["hp"] = 0
	lab.model.party[0]["atb"] = 0.0
	lab.model.party[2]["hp"] = 10
	lab._refresh()
	key(KEY_ENTER)
	key(KEY_DOWN)
	key(KEY_ENTER)
	expect(lab.menu_kind == "items", "Teclado abre itens")
	key(KEY_ENTER)
	expect(lab.target_focus_id == "p2", "Item de cura pula aliado incapacitado")
	key(KEY_RIGHT)
	expect(lab.target_focus_id == "p3" and lab.board.preview()["target"]["side"] == "ally", "Mão de item aponta ao aliado em campo")
	await capture("navigation-item-target")
	key(KEY_ENTER)
	finish()
	expect(lab.model.party[2]["hp"] == 75 and lab.model.inventory["hp"] == 5, "Item cura somente o alvo e consome estoque")
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_ENTER)
	key(KEY_DOWN)
	key(KEY_ENTER)
	key(KEY_DOWN)
	key(KEY_DOWN)
	key(KEY_ENTER)
	expect(lab.target_focus_id == "p1", "Reanimação oferece somente incapacitados")
	key(KEY_ENTER)
	finish()
	expect(lab.model.party[0]["hp"] == 45, "Reanimação concluída sem mouse")

func _test_controller() -> void:
	reset()
	pad(JOY_BUTTON_DPAD_RIGHT)
	expect(lab.party_focus_id == "p2", "Direcional do controle muda card")
	pad(JOY_BUTTON_A)
	pad(JOY_BUTTON_DPAD_RIGHT)
	pad(JOY_BUTTON_A)
	pad(JOY_BUTTON_DPAD_DOWN)
	pad(JOY_BUTTON_A)
	expect(lab.menu_kind == "target" and lab.aim_id == "circle", "Controle chega à mira de área sem teclado")
	var first = lab.target_focus_id
	axis(0.8)
	expect(lab.target_focus_id != first, "Analógico esquerdo muda alvo")
	var second = lab.target_focus_id
	axis(0.9)
	expect(lab.target_focus_id == second, "Eventos repetidos no mesmo sentido não causam corrida de seleção")
	lab.pause_button.button_pressed = true
	lab._process(0.36)
	expect(lab.target_focus_id != second, "Analógico segurado repete navegação com intervalo controlado")
	axis(0.0)
	var neutral = lab.target_focus_id
	axis(0.1)
	lab._process(0.4)
	expect(lab.target_focus_id == neutral, "Zona morta não navega")
	lab.model.mode = "Active"
	var center = lab.model.actor_by_id(lab.target_focus_id)
	var position: Vector2 = center["logical_position"]
	lab.model.tick(1.0)
	lab._refresh()
	expect(lab.board.preview()["target"]["id"] == center["id"] and center["logical_position"] != position, "Prévia acompanha alvo móvel em Active")
	await capture("navigation-area-target")
	pad(JOY_BUTTON_B)
	expect(lab.menu_kind == "skills", "Botão leste retorna uma etapa")
	pad(JOY_BUTTON_START)
	expect(lab.settings_open, "Start abre opções de combate")
	pad(JOY_BUTTON_DPAD_DOWN)
	var speed: int = lab.model.battle_speed
	pad(JOY_BUTTON_DPAD_RIGHT)
	expect(lab.model.battle_speed == speed + 1, "Controle ajusta Battle Speed")
	await capture("navigation-settings")
	pad(JOY_BUTTON_START)
	expect(not lab.settings_open and lab.menu_kind == "skills", "Fechar opções devolve o foco anterior")
	lab.pause_button.button_pressed = false
	pad(JOY_BUTTON_A)
	pad(JOY_BUTTON_A)
	expect(lab.model.action.get("skill", {}).get("target") == "circle" and lab.model.action.get("actor_id") == "p2", "Controle confirma habilidade em área")
	finish()

func _test_invalidation() -> void:
	reset()
	lab.model.mode = "Active"
	key(KEY_ENTER)
	key(KEY_RIGHT)
	key(KEY_ENTER)
	key(KEY_DOWN)
	key(KEY_ENTER)
	var old_target = lab.target_focus_id
	lab.model.actor_by_id(old_target)["hp"] = 0
	lab._refresh()
	expect(lab.target_focus_id != old_target and not lab.target_focus_id.is_empty(), "Alvo invalidado na seleção é substituído por outro válido")
	lab.model.party[0]["hp"] = 0
	lab._refresh()
	expect(lab.model.selected_id.is_empty() and lab.menu_kind.is_empty(), "Executor incapacitado devolve foco aos cards")
	reset()
	lab.model.party[0]["mp"] = 0
	key(KEY_ENTER)
	key(KEY_RIGHT)
	key(KEY_ENTER)
	key(KEY_ENTER)
	expect(lab.menu_kind == "skills" and lab.model.action.is_empty(), "Habilidades sem MP não são confirmadas")
	key(KEY_ESCAPE)
	key(KEY_ESCAPE)
	lab.seed_input.get_line_edit().grab_focus()
	key(KEY_ENTER)
	expect(lab.model.selected_id.is_empty(), "Digitar em campo da depuração não confirma comando")
	lab.seed_input.get_line_edit().release_focus()
	reset()
	lab.model.outcome = "defeat"
	lab._refresh()
	pad(JOY_BUTTON_A)
	expect(lab.model.outcome == "running", "Controle reinicia laboratório após derrota")

func _test_integrated_restart() -> void:
	var screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	for portal_id in ["town_exit", "dungeon_entrance"]:
		var portal: Dictionary = screen.session.world.entity_by_id(portal_id)
		var arrival: Vector2 = portal["position"] + Vector2(0, 40)
		screen.session.world.leader_position = arrival
		screen.session.world.path.assign([arrival - Vector2(102, 0), arrival])
		screen.session.world.path_length = 102
		expect(screen.session.begin_transition(portal_id), "Percurso integrado até batalha")
		screen.session.tick(screen.session.transition_duration)
	var enemy: Dictionary = screen.session.world.entity_by_id("test_map_enemy_01")
	screen.session.world.leader_position = enemy["position"]
	screen._try_encounter()
	var combat = screen.combat_ui
	expect(is_instance_valid(combat) and combat.encounter_mode, "Mesmo fluxo de navegação disponível no encontro integrado")
	if is_instance_valid(combat):
		combat.set_process(false)
		for member in combat.model.party:
			member["hp"] = 0
		combat.model._check_end()
		combat._refresh()
		await process_frame
		pad(JOY_BUTTON_A)
		await process_frame
		expect(screen.session.state == "exploration" and screen.combat_ui == null, "Confirmar no controle reinicia percurso após Game Over integrado")
	screen.queue_free()
	await process_frame
