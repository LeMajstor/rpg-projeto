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

func key(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(code: Key) -> void:
	key(code, true)
	key(code, false)

func walk(code: Key, distance: float) -> void:
	key(code, true)
	screen._physics_process(distance / 180.0)
	key(code, false)
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Fila real permanece fora dos sólidos")

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
	var board = screen.map_view
	var scale: float = board._scale_factor()
	walk(KEY_D, 1020)
	walk(KEY_W, 216)
	tap(KEY_E)
	screen._physics_process(screen.session.transition_duration)
	expect(screen.session.area_id == "test_world", "Mundo acessível normalmente")
	var map = screen.session.world
	var resources = screen.session.battle.party.duplicate(true)
	# Percurso real desde a vila, sem teleportar através das barreiras.
	walk(KEY_D, 150)
	walk(KEY_W, 230)
	walk(KEY_A, 142)
	expect(map.leader_position.is_equal_approx(Vector2(388, 790)), "Desvio do caminho chega ao pé da rampa")
	await capture("terrain-ramp-base")
	walk(KEY_W, 90)
	expect(map.leader_position == Vector2(388, 700) and is_equal_approx(map.elevation_at(map.leader_position), 24), "Meio da rampa eleva gradualmente")
	expect(is_equal_approx(board.screen_point(map.visual_position(map.leader_position)).y, board.size.y * 0.5) and is_equal_approx(board.camera_center().y, map.visual_position(map.leader_position).y), "Câmera segue pés elevados do líder")
	var positions = map.formation_positions()
	expect(map.elevation_at(positions[0]) > map.elevation_at(positions[1]) and map.elevation_at(positions[1]) > map.elevation_at(positions[2]), "Seguidores sobem em instantes distintos")
	await capture("terrain-ramp-ascent")
	tap(KEY_F3)
	expect(board.show_path, "F3 permite verificar colisões e alturas individuais")
	await capture("terrain-ramp-debug")
	tap(KEY_TAB)
	walk(KEY_W, 18)
	expect(map.formation_positions() == positions, "Menu bloqueia subida")
	screen.leader_buttons[3].pressed.emit()
	expect(map.party_order[0] == "p4" and map.formation_positions() == positions, "Novo líder ocupa mesma altura e trilha")
	walk(KEY_A, 100)
	expect(map.leader_position.x == 360, "Lateral da rampa impede saída no ar")
	walk(KEY_D, 28)
	walk(KEY_W, 180)
	expect(map.leader_position == Vector2(388, 520), "Platô acessível somente pela rampa")
	for point in map.formation_positions():
		expect(is_equal_approx(map.elevation_at(point), 48), "Quatro integrantes alcançam topo")
	tap(KEY_F3)
	await capture("terrain-plateau")
	walk(KEY_D, 100)
	expect(map.leader_position.x == 440, "Borda do platô impede queda lateral")
	walk(KEY_A, 52)
	walk(KEY_S, 270)
	expect(map.leader_position == Vector2(388, 790) and map.elevation_at(map.leader_position) == 0, "Descida devolve altura zero")
	await capture("terrain-ramp-descent")
	walk(KEY_D, 232)
	walk(KEY_W, 460)
	walk(KEY_A, 200)
	expect(map.leader_position == Vector2(562, 330), "Massa florestal bloqueia passagem entre árvores")
	await capture("terrain-forest")
	expect(is_equal_approx(board._scale_factor(), scale), "Subida não muda escala da câmera")
	expect(screen.session.battle.party == resources, "Teste de relevo não altera combate/HP/MP")
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and screen.session.world.elevation_at(screen.session.world.leader_position) == 0, "Reinício retorna à vila sem altura residual")
	screen.queue_free()
	await process_frame
	print("RELEVO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
