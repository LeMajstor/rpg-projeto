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

func place(point: Vector2) -> void:
	screen.session.world.leader_position = point
	screen.session.world.path.assign([point - Vector2(102, 0), point])
	screen.session.world.path_length = 102
	screen._refresh_map()

func travel(id: String) -> void:
	place(screen.session.world.entity_by_id(id)["position"] + Vector2(0, 40))
	tap(KEY_E)
	expect(screen.session.state == "transition", "Tecla E ainda inicia " + id)
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.transition_overlay.color.a == 1, "Troca de área ocorre sob preto total")
	screen._physics_process(screen.session.transition_duration * 0.5)
	expect(screen.session.state == "exploration", "Fade termina normalmente")

func frame_image():
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func capture(name: String) -> void:
	if capture_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	var image = await frame_image()
	expect(image.save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var clock = screen.session.clock
	var board = screen.map_view
	var panel = screen.clock_panel
	expect(not panel.visible and clock.time_text() == "10:00", "Depuração inicialmente oculta; horário provisório")
	expect(panel.hours.value == 10 and panel.minutes.value == 0, "Campos começam com horário da sessão")
	var scale: float = board._scale_factor()
	var day_image
	if DisplayServer.get_name() != "headless":
		day_image = await frame_image()
	await capture("clock-day-town")
	clock.set_time(22, 0) # Sem refresh manual: sinal invalida o desenho.
	expect(board.lighting_overlay().a > 0, "Alteração narrativa ilumina imediatamente")
	if DisplayServer.get_name() != "headless":
		var night_image = await frame_image()
		var point: Vector2 = board.global_position + Vector2(40, 60)
		var day_pixel: Color = day_image.get_pixelv(Vector2i(point))
		var night_pixel: Color = night_image.get_pixelv(Vector2i(point))
		expect(not day_pixel.is_equal_approx(night_pixel) and night_pixel.get_luminance() < day_pixel.get_luminance(), "Iluminação realmente altera pixels do cenário")
		expect(night_pixel.get_luminance() > 0.03, "Noite preserva visibilidade do cenário")
		expect(day_image.get_pixel(28, 36).is_equal_approx(night_image.get_pixel(28, 36)), "HUD não recebe escurecimento")
	await capture("clock-night-town")
	screen._physics_process(120)
	expect(clock.time_text() == "22:00" and not screen.session.can_advance_world_time(), "Cidade externa permanece pausada")
	tap(KEY_F3)
	expect(panel.visible and board.show_path and "Noite" in panel.status.text and "pausado" in panel.status.text, "F3 consulta hora, período e política")
	panel.hours.value = 23
	panel.minutes.value = 30
	panel.set_button.pressed.emit()
	expect(clock.time_text() == "23:30", "Definição manual funciona pausado")
	panel.advance_button.pressed.emit()
	expect(clock.time_text() == "02:30", "Evento em botão atravessa meia-noite")
	panel.morning_button.pressed.emit()
	expect(clock.time_text() == "08:00" and board.lighting_overlay().a == 0, "Evento 08:00 reflete na iluminação")
	var resources = screen.session.battle.party.duplicate(true)
	panel.rest_button.pressed.emit()
	expect(clock.time_text() == "07:00" and screen.session.battle.party == resources, "Descanso temporal não recupera recursos")
	tap(KEY_TAB)
	expect(screen.session.world.menu_open, "Tab mantém menu da equipe com F3 aberto")
	tap(KEY_TAB)
	expect(not screen.session.world.menu_open, "Tab fecha menu sem focar campos do relógio")
	panel.hours.get_line_edit().grab_focus()
	var position: Vector2 = screen.session.world.leader_position
	key(KEY_W, true)
	screen._physics_process(0.1)
	key(KEY_W, false)
	expect(screen.session.world.leader_position == position, "Editar hora não movimenta personagem")
	panel.hours.value = 7
	panel.minutes.value = 0
	panel.set_button.pressed.emit()
	expect(not screen._clock_field_focused(), "Confirmar horário devolve controle ao mapa")
	screen._physics_process(60)
	expect(clock.time_text() == "07:00" and not screen.session.can_advance_world_time(), "Abrir F3 não faz o tempo correr na cidade")
	screen.session.world.menu_open = true
	screen._physics_process(60)
	expect(clock.time_text() == "07:00", "Cidade permanece pausada com menu aberto")
	screen.session.world.menu_open = false
	clock.set_time(18, 0)
	screen._refresh_map()
	await capture("clock-debug-dusk")
	tap(KEY_F3)
	expect(not panel.visible, "F3 fecha somente a depuração")
	screen._physics_process(60)
	expect(clock.time_text() == "18:00", "Cidade permanece pausada com F3 fechado")
	clock.set_time(22, 0)
	place(screen.session.world.entity_by_id("npc_05")["position"])
	tap(KEY_E)
	expect(screen.dialogue_overlay.visible and "noite" in screen.dialogue_text.text, "NPC 5 demonstra consulta noturna via E existente")
	var dialogue_text: String = screen.dialogue_text.text
	clock.set_time(8, 0)
	expect(screen.dialogue_text.text == dialogue_text, "Fala aberta não muda durante evento")
	tap(KEY_E)
	expect(not screen.dialogue_overlay.visible, "E ainda encerra a conversa")
	clock.set_time(22, 0)
	travel("house_entrance")
	expect(screen.session.clock == clock and clock.time_text() == "22:00" and board.lighting_overlay().a == 0, "Interior preserva relógio com iluminação fixa")
	clock.set_time(8, 0)
	travel("house_exit")
	expect(board.lighting_overlay().a == 0 and clock.time_text() == "08:00", "Retorno revela manhã narrativa")
	clock.set_time(22, 0)
	travel("town_exit")
	expect(board.lighting_overlay().a > 0 and screen.session.can_advance_world_time(), "Mapa-múndi real recebe noite e habilita avanço automático")
	screen._physics_process(5)
	expect(clock.time_text() == "23:00" and not panel.visible, "Tempo avança no mapa-múndi sem ativar F3")
	screen._physics_process(120)
	expect(clock.time_text() == "23:00", "Ciclo completo tem dois minutos reais")
	await capture("clock-night-world")
	clock.set_time(22, 0)
	travel("dungeon_entrance")
	expect(board.lighting_overlay().a == 0 and clock.time_text() == "22:00", "Dungeon não muda horário e usa luz fixa")
	place(screen.session.world.entity_by_id("test_map_enemy_01")["position"])
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and not screen.map_ui.visible, "Combate existente acessível")
	lab.set_process(false)
	for enemy in lab.model.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	lab.model.debug_ready_allies()
	lab.model.select_actor("p1")
	lab.model.submit("all")
	for index in range(120):
		lab.model.tick(1.0 / 120)
	lab._refresh()
	await process_frame
	expect(screen.combat_ui == null and screen.session.clock == clock and clock.time_text() == "22:00", "Vitória real retorna mantendo relógio")
	travel("dungeon_exit")
	screen._physics_process(5)
	expect(clock.time_text() == "23:00", "Sair da dungeon retoma avanço no mapa-múndi")
	travel("enter_town")
	screen._physics_process(60)
	expect(clock.time_text() == "23:00", "Entrar na vila pausa automaticamente sem alterar hora da chegada")
	expect(is_equal_approx(board._scale_factor(), scale), "Iluminação e painel não alteram câmera/zoom")
	screen._restart()
	expect(screen.session.clock != clock and screen.session.clock.time_text() == "10:00", "Somente reinício explícito cria relógio novo")
	expect(not panel.visible and board.lighting_overlay().a == 0, "Reinício limpa depuração e iluminação")
	clock.set_time(2, 0)
	expect(screen.session.clock.time_text() == "10:00" and not clock.time_changed.is_connected(board._on_time_changed), "Relógio anterior desconectado após reinício")
	screen.queue_free()
	await process_frame
	print("RELÓGIO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
