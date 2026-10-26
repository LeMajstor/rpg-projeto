extends SceneTree
var screen
var checks = 0
var failures = 0
var captures = ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-captures="):
			captures = arg.trim_prefix("--visual-captures=")
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

func place(point: Vector2, direction: Vector2 = Vector2.RIGHT) -> void:
	screen.session.world.leader_position = point
	screen.session.world.path.assign([point - direction * 102, point])
	screen.session.world.path_length = 102
	screen.session.world.moving = false
	screen._refresh_map()

func walk(code: Key, distance: float) -> void:
	key(code, true)
	screen._physics_process(distance / 180.0)
	key(code, false)
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Fila fora de sólidos no percurso real")

func finish_transition() -> void:
	expect(screen.session.state == "transition", "E/botão inicia transição")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.transition_overlay.color.a == 1, "Destino atualizado sob preto total")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.session.state == "exploration", "Fade libera controles")

func travel(id: String) -> void:
	place(screen.session.world.entity_by_id(id)["position"] + Vector2(0, 40))
	tap(KEY_E)
	finish_transition()

func close_dialogue() -> void:
	for index in range(12):
		if not screen.session.dialogue.opened:
			return
		tap(KEY_E)
	expect(false, "Diálogo fecha usando E")

func frame_image():
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func pixel(image, point: Vector2) -> Color:
	return image.get_pixelv(Vector2i(screen.map_view.global_position + screen.map_view.screen_point(point)))

func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		return
	var image = await frame_image()
	expect(image.save_png(captures.path_join(name + ".png")) == OK, "Captura: " + name)

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var session = screen.session
	var shared_clock = session.clock
	var scale: float = screen.map_view._scale_factor()
	# Caminho real da posição inicial até a nova casa.
	walk(KEY_D, 1020)
	walk(KEY_S, 280)
	walk(KEY_A, 160)
	expect("segunda casa" in screen.interact_button.text, "Entrada identificada no botão contextual")
	screen.interact_button.pressed.emit()
	finish_transition()
	expect(session.area_id == "secret_house" and session.clock == shared_clock, "Segunda casa reutiliza sessão/transição")
	screen._physics_process(120)
	expect(shared_clock.time_text() == "10:00", "Tempo não passa no novo interior")
	walk(KEY_A, 400)
	expect(session.world.leader_position.x == 130, "Paredes do novo interior são sólidas")
	walk(KEY_D, 230)
	walk(KEY_S, 90)
	await capture("town-second-house-interior")
	tap(KEY_E)
	finish_transition()
	walk(KEY_D, 107)
	walk(KEY_W, 80)
	expect("Pedra" in screen.interact_button.text, "Pedra alcançável andando sem atravessar a casa")
	tap(KEY_E)
	expect(session.dialogue.dialogue_id == "stone_day" and session.story_flags.is_empty(), "Pedra diurna comum, sem descoberta")
	close_dialogue()
	var day_old: Color
	var day_new: Color
	var day_lamp: Color
	var day_stone: Color
	place(Vector2(840, 310))
	if DisplayServer.get_name() != "headless":
		day_old = pixel(await frame_image(), Vector2(802, 200))
	await capture("town-original-house-day")
	place(Vector2(1230, 780))
	if DisplayServer.get_name() != "headless":
		var image = await frame_image()
		day_new = pixel(image, Vector2(1022, 700))
		day_lamp = pixel(image, Vector2(877, 510))
		day_stone = pixel(image, Vector2(1176, 650))
	await capture("town-second-house-day")
	travel("town_exit")
	screen._physics_process(45)
	expect(shared_clock.time_text() == "19:00", "Noite chega pelo ciclo natural do mapa-múndi")
	travel("enter_town")
	expect(session.world.entity_by_id("npc_04")["position"] == Vector2(970, 780), "Morador ocupa posição noturna na chegada")
	screen._physics_process(10)
	expect(shared_clock.time_text() == "19:00", "Cidade preserva hora recebida")
	place(Vector2(840, 310))
	if DisplayServer.get_name() != "headless":
		var night_old = pixel(await frame_image(), Vector2(802, 200))
		expect(night_old.r > day_old.r + 0.2, "Janela original acende: pixel real")
	await capture("town-original-house-night")
	place(Vector2(1230, 780))
	if DisplayServer.get_name() != "headless":
		var image = await frame_image()
		expect(pixel(image, Vector2(1022, 700)).r > day_new.r + 0.2, "Janela nova acende: pixel real")
		expect(pixel(image, Vector2(877, 510)).r > day_lamp.r + 0.2, "Poste acende: pixel real")
		expect(not pixel(image, Vector2(1176, 650)).is_equal_approx(day_stone), "Pedra muda visualmente à noite")
		var lamp = session.world.data["obstacles"].filter(func(item): return item.get("kind", "") == "lamp")[0]
		var on = pixel(image, Vector2(930, 574))
		lamp["night_light"] = false
		screen.map_view.queue_redraw()
		var off = pixel(await frame_image(), Vector2(930, 574))
		expect(not on.is_equal_approx(off), "Halo ilumina discretamente chão próximo ao poste")
		lamp["night_light"] = true
		screen.map_view.queue_redraw()
	await capture("town-second-house-night")
	place(Vector2(1177, 720), Vector2.UP)
	tap(KEY_E)
	expect(session.dialogue.dialogue_id == "stone_discover" and session.story_flags.get("house_secret_discovered", false), "E registra inscrição noturna")
	await capture("town-secret-discovered")
	close_dialogue()
	screen.interact_button.pressed.emit()
	expect(session.dialogue.dialogue_id == "stone_known", "Botão não repete descoberta")
	close_dialogue()
	travel("town_exit")
	screen._physics_process(60)
	travel("enter_town")
	expect(shared_clock.time_text() == "07:00" and session.story_flags.get("house_secret_discovered", false), "Dia natural retorna sem apagar descoberta")
	var resident = session.world.entity_by_id("npc_04")
	place(resident["position"])
	tap(KEY_E)
	expect(session.dialogue.dialogue_id == "resident_knows", "Morador reconhece o segredo durante o dia")
	var before: Vector2 = resident["position"]
	shared_clock.set_time(22, 0)
	expect(resident["position"] == before and session.dialogue.dialogue_id == "resident_knows", "Evento durante diálogo preserva interlocutor/fala")
	close_dialogue()
	expect(resident["position"] == Vector2(970, 780), "Morador atualiza após diálogo")
	place(Vector2(1177, 720), Vector2.UP)
	tap(KEY_E)
	expect(session.dialogue.dialogue_id == "stone_known", "Nova noite mantém descoberta única")
	close_dialogue()
	travel("house_entrance")
	expect(session.world.data["npcs"].size() == 3, "Casa original mantém NPCs e funções")
	expect(is_equal_approx(screen.map_view._scale_factor(), scale), "Câmera mantém distância comum e seguimento")
	screen._restart()
	expect(screen.session.story_flags.is_empty(), "Reinício explícito limpa estado do experimento")
	screen.queue_free()
	await process_frame
	print("EVENTOS/CIDADE/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
