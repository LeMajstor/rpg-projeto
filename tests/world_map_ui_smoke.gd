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

func walk(code: Key, distance: float) -> void:
	key(code)
	screen._physics_process(distance / 180.0)
	key(code, false)

func place(point: Vector2) -> void:
	screen.session.world.leader_position = point
	screen.session.world.path.assign([point - Vector2(102, 0), point])
	screen.session.world.path_length = 102
	screen.session.world.moving = false
	screen._refresh_map()

func finish_transition() -> void:
	expect(screen.session.state == "transition", "Interação inicia fade")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.transition_overlay.visible and screen.transition_overlay.color.a == 1, "Troca de área sob preto total")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.session.state == "exploration" and not screen.transition_overlay.visible, "Chegada libera mapa e câmera")

func travel(id: String) -> void:
	var portal: Dictionary = screen.session.world.entity_by_id(id)
	place(portal["position"] + Vector2(0, 40))
	tap(KEY_E)
	finish_transition()

func close_dialogue() -> void:
	for step in range(12):
		if not screen.session.dialogue.opened:
			return
		if screen.session.dialogue.choices().is_empty():
			screen.dialogue_next.pressed.emit()
		else:
			screen.dialogue_choice_buttons[0].pressed.emit()
	expect(false, "Diálogo deve terminar")

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var scale: float = screen.map_view._scale_factor()
	expect(screen.session.area_id == "lab_exterior" and "Vila" in screen.area_label.text, "Projeto inicia na vila de testes")
	expect(screen.session.world.data["npcs"].size() == 2, "NPCs presentes nas ruas")
	place(Vector2(1100, 400))
	await capture("world-town-streets")
	place(screen.session.world.entity_by_id("npc_04")["position"])
	tap(KEY_E)
	expect(screen.dialogue_overlay.visible and screen.dialogue_speaker.text == "NPC 4", "NPC externo inicia conversa")
	var route = screen.session.world.entity_by_id("npc_04")["route_state"].duplicate(true)
	var position = screen.session.world.leader_position
	walk(KEY_D, 18)
	expect(screen.session.world.leader_position == position and screen.session.world.entity_by_id("npc_04")["route_state"] == route, "Conversa na rua pausa grupo e patrulha")
	close_dialogue()
	place(Vector2(900, 500))
	walk(KEY_D, 330)
	walk(KEY_W, 216)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(1230, 284)) and "Sair da vila" in screen.interact_button.text, "Portão é alcançável andando e tem ação contextual")
	tap(KEY_E)
	finish_transition()
	expect(screen.session.area_id == "test_world" and "Mundo aberto" in screen.area_label.text, "Portão leva ao mundo aberto")
	for entity in screen.session.world.entities:
		expect(entity["kind"] == "transition", "Mundo sem NPCs ou monstros comuns")
	expect(is_equal_approx(screen.map_view._scale_factor(), scale), "Mundo mantém escala e câmera do protótipo")
	await capture("world-town-access")
	# Percurso completo da entrada da vila até a dungeon por teclado.
	walk(KEY_D, 420)
	walk(KEY_W, 540)
	walk(KEY_D, 740)
	walk(KEY_W, 46)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(1540, 434)), "Caminho do mundo alcança dungeon sem atravessar sólidos")
	expect("Entrar na dungeon" in screen.interact_button.text, "Dungeon agora possui entrada no mundo")
	await capture("world-dungeon-access")
	tap(KEY_E)
	finish_transition()
	expect(screen.session.area_id == "test_dungeon" and screen.session.world.data["encounters"].size() == 6, "Mini dungeon conserva seis encontros")
	place(Vector2(930, 190))
	screen.session.battle.party[0]["hp"] = 89
	screen.session.battle.party[0]["mp"] = 30
	var shared = screen.session.battle
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and lab.model == shared and lab.model.preset["id"] == "exploration_seeded_fullscreen", "Batalha existente reutilizada com ritmos atuais e tela inteira")
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
	expect(screen.combat_ui == null and screen.session.area_id == "test_dungeon", "Vitória retorna ao interior da dungeon")
	expect(not screen.session.world.entity_by_id("test_map_enemy_04")["present"], "Encontro vencido fica removido")
	travel("dungeon_exit")
	expect(screen.session.area_id == "test_world" and screen.session.world.leader_position == Vector2(1540, 480), "Sair da dungeon retorna ao mundo, não à vila")
	# Vistas da paisagem preservam a mesma sessão e seus recursos.
	place(Vector2(620, 500))
	await capture("world-forest-hills")
	place(Vector2(1460, 200))
	await capture("world-mountains")
	place(Vector2(1620, 1020))
	await capture("world-coast")
	walk(KEY_D, 200)
	expect(screen.session.world.leader_position.x == 1668, "Mar bloqueia o líder")
	travel("enter_town")
	expect(screen.session.area_id == "lab_exterior" and "Vila" in screen.area_label.text, "Interação permite entrar na vila novamente")
	expect(screen.session.battle.party[0]["hp"] == 89 and screen.session.battle.party[0]["mp"] == 20, "Viagens não restauram HP/MP")
	travel("house_entrance")
	expect(screen.session.world.data["npcs"].size() == 3, "Casa continua com NPCs")
	await capture("world-house-npcs")
	place(Vector2(380, 230))
	tap(KEY_E)
	expect(screen.dialogue_speaker.text == "NPC 2" and screen.dialogue_choice_buttons.size() == 2, "Respostas permanecem disponíveis na casa")
	tap(KEY_2)
	close_dialogue()
	travel("house_exit")
	travel("town_exit")
	travel("dungeon_entrance")
	expect(not screen.session.world.entity_by_id("test_map_enemy_04")["present"], "Revisita por quatro áreas mantém encontro vencido")
	expect(is_equal_approx(screen.map_view._scale_factor(), scale), "Nenhuma viagem altera distância da câmera")
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and screen.session.area_worlds.size() == 1, "Reinício começa na vila")
	expect(screen.session.battle.party[0]["hp"] == screen.session.battle.party[0]["max_hp"], "Somente reinício restaura recursos")
	screen.queue_free()
	await process_frame
	print("MUNDO/VILA/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
