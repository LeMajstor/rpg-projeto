extends SceneTree
var screen
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

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(code: Key) -> void:
	key(code)
	key(code, false)

func place(position: Vector2) -> void:
	screen.session.world.leader_position = position
	screen.session.world.path.assign([position - Vector2(102, 0), position])
	screen.session.world.path_length = 102
	screen._refresh_map()

func finish_transition() -> void:
	for step in range(60):
		if screen.session.state != "transition":
			break
		screen._physics_process(1.0 / 120.0)
	expect(screen.session.state == "exploration" and not screen.transition_overlay.visible, "Transição termina e overlay sai")

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	screen.set_script(load("res://tests/fixtures/legacy_exploration_screen.gd"))
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	expect(screen.session.area_id == "lab_exterior" and "externo" in screen.area_label.text, "Projeto inicia no laboratório atual")
	expect(not screen.transition_overlay.visible, "Fade inicia oculto")
	tap(KEY_TAB)
	screen.leader_buttons[3].pressed.emit()
	var order = screen.session.world.party_order.duplicate()
	screen.session.battle.party[0]["hp"] = 94
	screen.session.battle.party[0]["mp"] = 21
	screen.session.world.entity_by_id("chest_01")["open"] = true
	screen.session.world.toggle_door("door_01")
	# Caminho físico desde o spawn até a entrada, sem teletransporte.
	key(KEY_D)
	screen._physics_process(630.0 / 180.0)
	key(KEY_D, false)
	key(KEY_W)
	screen._physics_process(210.0 / 180.0)
	key(KEY_W, false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(840, 290)), "Entrada acessível pelo mapa existente")
	expect("Entrar na casa" in screen.interact_button.text and not screen.interact_button.disabled, "Botão contextual mostra entrada")
	await capture("areas-exterior-house")
	var source = screen.session.world
	var source_route = source.entity_by_id("npc_04")["route_state"].duplicate(true)
	tap(KEY_E)
	expect(screen.session.state == "transition" and screen.transition_overlay.visible, "E inicia fade e bloqueia interface")
	tap(KEY_TAB)
	tap(KEY_E)
	expect(not screen.menu_panel.visible and screen.session.area_id == "lab_exterior", "Menu e nova interação não interrompem fade")
	key(KEY_D)
	screen._physics_process(0.09)
	key(KEY_D, false)
	expect(source.leader_position.is_equal_approx(Vector2(840, 290)), "Teclado não move durante transição")
	expect(is_equal_approx(screen.transition_overlay.color.a, 0.5), "Fade aparece parcialmente escuro")
	screen._physics_process(0.10)
	expect(screen.session.area_id == "test_house" and screen.transition_overlay.color.a == 1, "Troca fica coberta mesmo ao cruzar a metade")
	await capture("areas-transition-black")
	finish_transition()
	expect("Casa de teste" in screen.area_label.text and screen.map_view.session == screen.session, "Vista e HUD usam área de destino")
	expect(screen.session.world.party_order == order, "Líder e ordem preservados na interface")
	expect(screen.session.world.formation_positions().size() == 4, "Quatro slots no interior")
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Slot de chegada livre")
	expect(screen.session.battle.party[0]["hp"] == 94 and screen.session.battle.party[0]["mp"] == 21, "Transição preserva HP/MP")
	expect(source.entity_by_id("npc_04")["route_state"] == source_route, "Patrulha externa não avança durante fade")
	await capture("areas-house-interior")
	# Movimento e colisão reais no interior.
	key(KEY_A)
	screen._physics_process(1)
	key(KEY_A, false)
	key(KEY_W)
	screen._physics_process(1)
	key(KEY_W, false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(180, 232)), "Mesa do interior tem colisão")
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Fila acompanha curva no interior")
	expect(source.entity_by_id("npc_04")["route_state"] == source_route, "Área inativa não simula enquanto se anda na casa")
	place(Vector2(360, 385))
	expect("Sair da casa" in screen.interact_button.text, "Saída contextual identificada")
	screen.interact_button.pressed.emit()
	finish_transition()
	expect(screen.session.world == source and screen.session.area_id == "lab_exterior", "Botão volta à mesma instância do exterior")
	expect(source.entity_by_id("chest_01")["open"] and source.entity_by_id("door_01")["open"], "Revisita preserva objetos")
	expect(source.party_order == order and source.leader_position == Vector2(840, 310), "Fila retorna na entrada externa")
	tap(KEY_E)
	expect(screen.session.state == "exploration", "Não retorna imediatamente por interação fora do alcance")
	await capture("areas-return-exterior")
	# Falha de destino nunca cobre a tela nem prende controles.
	place(Vector2(840, 290))
	source.entity_by_id("house_entrance")["target_entry_id"] = "missing"
	tap(KEY_E)
	expect(screen.session.state == "exploration" and not screen.transition_overlay.visible and "inválida" in screen.message_label.text, "Destino inválido aparece no HUD sem bloquear")
	key(KEY_D)
	screen._physics_process(0.01)
	key(KEY_D, false)
	expect(source.leader_position.x > 840, "Controles continuam utilizáveis após falha")
	screen._restart()
	# Reinício explícito durante fade cancela o estado sem callbacks tardios.
	place(Vector2(840, 290))
	tap(KEY_E)
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and screen.session.area_worlds.size() == 1 and not screen.transition_overlay.visible, "Reinício elimina todas as áreas anteriores e o fade")
	expect(not screen.session.world.entity_by_id("chest_01")["open"] and screen.session.battle.party[0]["hp"] == screen.session.battle.party[0]["max_hp"], "Reinício restaura objetos e recursos")
	# Encontro interior existe apenas nesta fixture automatizada.
	screen.session.area_definitions["test_house"]["encounters"] = [{"id": "inside_enemy", "label": "Teste", "position": [470, 290], "battle_preset_id": "lab_a", "interaction_distance": 72}]
	place(Vector2(840, 290))
	tap(KEY_E)
	finish_transition()
	place(Vector2(435, 290))
	var shared = screen.session.battle
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and lab.model == shared and screen.session.area_id == "test_house", "Combate compartilhado abre em outra área")
	lab.set_process(false)
	for enemy in lab.model.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	lab.model.debug_ready_allies()
	lab.model.select_actor("p1")
	lab.model.submit("all")
	for step in range(100):
		lab.model.tick(1.0 / 120.0)
	lab._refresh()
	await process_frame
	expect(screen.combat_ui == null and screen.map_ui.visible and screen.session.area_id == "test_house", "Vitória mostra novamente o interior correto")
	expect(not screen.session.world.entity_by_id("inside_enemy")["present"] and screen.session.world.leader_position == Vector2(435, 290), "Resultado e posição aplicados à área correta")
	screen.queue_free()
	await process_frame
	print("ÁREAS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
