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

func travel(id: String) -> void:
	if id == "dungeon_entrance" and screen.session.area_id == "lab_exterior":
		travel("town_exit")
	if id == "house_entrance" and screen.session.area_id == "test_world":
		travel("enter_town")
	var portal: Dictionary = screen.session.world.entity_by_id(id)
	place(portal["position"] + Vector2(0, -40 if id.ends_with("exit") else 40))
	tap(KEY_E)
	expect(screen.session.state == "transition", "Viagem inicia com E")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.transition_overlay.visible and screen.transition_overlay.color.a == 1, "Câmera muda com destino coberto pelo fade")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.session.state == "exploration" and not screen.transition_overlay.visible, "Viagem revela área e câmera atuais")

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	expect(image.save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)
	# O ponto fica no espaço entre toolbar e mapa; cenário não pode desenhar ali.
	var point = screen.map_view.global_position + Vector2(screen.map_view.size.x * 0.5, -5)
	var color = image.get_pixel(int(point.x), int(point.y))
	expect(color.is_equal_approx(Color("0c181e")), "Recorte da câmera preserva área externa ao mapa")

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var board = screen.map_view
	var original_scale: float = board._scale_factor()
	expect(screen.map_frame.clip_contents and board.get_parent() == screen.map_frame, "Desenho do mundo é filho de uma área recortada")
	expect(is_equal_approx(original_scale, minf(board.size.x / 720.0, board.size.y / 480.0)), "Mesma distância anterior da casa")
	await capture("camera-exterior")
	travel("house_entrance")
	expect(is_equal_approx(board._scale_factor(), original_scale), "Casa usa mesma escala do exterior")
	expect(board.camera_center().is_equal_approx(Vector2(360, 240)), "Casa inteira cabe e fica centralizada")
	await capture("camera-house")
	travel("house_exit")
	travel("dungeon_entrance")
	expect(is_equal_approx(board._scale_factor(), original_scale), "Dungeon usa mesma escala da casa")
	expect(board.camera_center().y > 240, "Dungeon acompanha chegada na parte inferior")
	expect(not board.get_rect().has_point(board.screen_point(Vector2(560, 64))), "Dungeon deixou de ser encolhida para mostrar todas as salas")
	await capture("camera-dungeon-entry")
	place(Vector2(560, 400))
	expect(board.screen_point(screen.session.world.leader_position).is_equal_approx(board.size * 0.5), "Líder centralizado fora dos limites de borda")
	tap(KEY_TAB)
	screen.leader_buttons[3].pressed.emit()
	expect(screen.session.world.party_order[0] == "p4", "Líder muda pelo menu")
	var center: Vector2 = board.camera_center()
	key(KEY_S)
	screen._physics_process(0.1)
	key(KEY_S, false)
	expect(board.camera_center().is_equal_approx(center + Vector2(0, 18)), "Câmera acompanha deslocamento do novo líder")
	expect(board.screen_point(screen.session.world.formation_positions()[0]).is_equal_approx(board.size * 0.5), "Câmera segue slot da frente")
	expect(not board.screen_point(screen.session.world.formation_positions()[1]).is_equal_approx(board.size * 0.5), "Câmera não segue o antigo líder na fila")
	tap(KEY_F3)
	expect(board.show_path, "Depuração continua disponível")
	await capture("camera-dungeon-follow")
	# NPC e comando continuam usando coordenadas lógicas, apesar do novo enquadramento.
	travel("dungeon_exit")
	travel("house_entrance")
	place(Vector2(380, 230))
	var npc: Dictionary = screen.session.world.entity_by_id("npc_02")
	expect(board.get_rect().has_point(board.screen_point(npc["position"])), "NPC próximo continua visível")
	tap(KEY_E)
	expect(screen.dialogue_speaker.text == "NPC 2" and screen.dialogue_overlay.visible, "Interação funciona com a projeção da câmera")
	center = board.camera_center()
	key(KEY_D)
	screen._physics_process(0.5)
	key(KEY_D, false)
	expect(board.camera_center() == center, "Diálogo pausa movimento e câmera")
	tap(KEY_1)
	while screen.session.dialogue.opened:
		screen.dialogue_next.pressed.emit()
	travel("house_exit")
	travel("dungeon_entrance")
	place(Vector2(930, 190))
	center = board.camera_center()
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and not screen.map_ui.visible, "Combate continua em tela separada")
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
	expect(screen.map_ui.visible and screen.combat_ui == null and board.camera_center() == center, "Retorno do combate preserva enquadramento e área")
	expect(is_equal_approx(board._scale_factor(), original_scale), "Combate não altera escala da exploração")
	board.camera_reference_size = Vector2(360, 240)
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and is_equal_approx(board._scale_factor(), original_scale), "Reinício reposiciona câmera sem alterar zoom")
	screen.queue_free()
	await process_frame
	print("CÂMERA/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
