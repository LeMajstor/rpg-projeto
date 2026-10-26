extends SceneTree
var checks = 0
var failures = 0
var screen
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

func close_dialogue() -> void:
	for step in range(12):
		if not screen.session.dialogue.opened:
			return
		if screen.session.dialogue.choices().is_empty():
			screen.dialogue_next.pressed.emit()
		else:
			screen.dialogue_choice_buttons[0].pressed.emit()
	expect(false, "A conversa deve terminar")

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
	expect(not screen.dialogue_overlay.visible, "Diálogo começa oculto")
	expect(screen.session.world.entities.size() == 16, "Cena possui seis encontros, cinco NPCs, quatro objetos e entrada da casa")
	expect(screen.map_view.get_global_rect().size.y >= 420, "Mapa cabe na interface")
	tap(KEY_F3)
	expect(screen.map_view.show_path, "F3 habilita rotas e colisões")
	await capture("exploration-expanded-map")
	place(Vector2(115, 185))
	expect(not screen.interact_button.disabled and "NPC 1" in screen.interact_button.text, "Botão contextual indica NPC próximo")
	tap(KEY_E)
	expect(screen.dialogue_overlay.visible and screen.dialogue_speaker.text == "NPC 1", "E abre diálogo com nome")
	expect(screen.dialogue_text.text == screen.session.dialogue.current()["text"], "UI apresenta fala atual")
	var first = screen.dialogue_text.text
	var position = screen.session.world.leader_position
	var route = screen.session.world.entity_by_id("npc_04")["route_state"].duplicate(true)
	key(KEY_D)
	screen._physics_process(1)
	key(KEY_D, false)
	expect(screen.session.world.leader_position == position, "Teclado não move durante fala")
	expect(screen.session.world.entity_by_id("npc_04")["route_state"] == route, "Conversa pausa patrulha")
	tap(KEY_TAB)
	tap(KEY_ESCAPE)
	expect(not screen.menu_panel.visible and screen.dialogue_overlay.visible, "Diálogo bloqueia menu e não desaparece com Esc")
	await process_frame
	expect(root.get_visible_rect().encloses(screen.dialogue_panel.get_global_rect()), "Janela de diálogo cabe na tela")
	expect(screen.dialogue_text.get_line_count() >= 1 and screen.dialogue_text.size.y >= screen.dialogue_text.get_line_height(), "Fala dispõe de espaço visível")
	tap(KEY_ENTER)
	expect(screen.dialogue_text.text != first and screen.dialogue_overlay.visible, "Enter avança sem encerrar todas as falas")
	screen.dialogue_next.pressed.emit()
	expect(not screen.dialogue_overlay.visible, "Botão encerra e libera mapa")
	key(KEY_D)
	screen._physics_process(0.1)
	key(KEY_D, false)
	expect(screen.session.world.leader_position.x > position.x, "Movimento retoma após fala")
	place(Vector2(245, 190))
	screen.interact_button.pressed.emit()
	expect(screen.dialogue_choice_buttons.size() == 2 and not screen.dialogue_next.visible, "Botão abre opções de resposta")
	tap(KEY_E)
	expect(screen.session.dialogue.node_id == "question", "E não responde pela pessoa")
	await capture("exploration-expanded-choices")
	screen.dialogue_choice_buttons[1].pressed.emit()
	expect(screen.session.dialogue.node_id == "formation" and screen.dialogue_next.visible, "Clique seleciona segundo ramo")
	close_dialogue()
	screen.interact_button.pressed.emit()
	tap(KEY_1)
	expect(screen.session.dialogue.node_id == "encounters", "Tecla numérica escolhe primeiro ramo")
	close_dialogue()
	place(Vector2(900, 660))
	tap(KEY_E)
	expect(screen.dialogue_speaker.text == "Baú" and screen.session.world.entity_by_id("chest_01")["open"], "Baú apresenta diálogo e estado visual aberto")
	close_dialogue()
	place(Vector2(1040, 660))
	tap(KEY_E)
	expect(screen.dialogue_speaker.text == "Placa", "Placa usa a mesma interface")
	close_dialogue()
	place(Vector2(920, 795))
	tap(KEY_E)
	expect(screen.session.world.entity_by_id("door_01")["open"], "Alavanca abre porta na cena real")
	close_dialogue()
	await capture("exploration-expanded-objects")
	place(Vector2(970, 751))
	tap(KEY_E)
	expect(not screen.session.world.entity_by_id("door_01")["open"], "Porta interage diretamente")
	close_dialogue()
	# Percorre corredores reais por teclado, observando a fila.
	screen._restart()
	key(KEY_S)
	screen._physics_process(200.0 / 180.0)
	key(KEY_S, false)
	key(KEY_D)
	screen._physics_process(448.0 / 180.0)
	key(KEY_D, false)
	key(KEY_S)
	screen._physics_process(100.0 / 180.0)
	key(KEY_S, false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(658, 800)), "Teclado percorre os dois corredores estreitos")
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Fila permanece fora das paredes")
	await capture("exploration-expanded-corridor")
	# Um preset diferente do original também passa pela cena compartilhada.
	place(Vector2(1320, 495))
	var shared = screen.session.battle
	var patrol = screen.session.world.entity_by_id("test_map_enemy_03")["route_state"].duplicate(true)
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and lab.model == shared and lab.model.preset["id"] == "lab_fullscreen", "M4 abre D no combate compartilhado")
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
	expect(screen.combat_ui == null and screen.map_ui.visible, "Vitória em D retorna ao mesmo mapa")
	expect(not screen.session.world.entity_by_id("test_map_enemy_04")["present"] and screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Somente M4 desapareceu")
	expect(screen.session.world.entity_by_id("test_map_enemy_03")["route_state"] == patrol, "Rotas do mapa congelaram durante luta")
	place(Vector2(900, 660))
	tap(KEY_E)
	expect(screen.dialogue_overlay.visible, "É possível interagir após combate")
	screen._restart()
	expect(not screen.dialogue_overlay.visible and not screen.session.world.dialogue_open, "Reinício limpa diálogo")
	expect(not screen.session.world.entity_by_id("chest_01")["open"] and not screen.session.world.entity_by_id("door_01")["open"], "Reinício restaura objetos")
	expect(screen.session.world.entity_by_id("test_map_enemy_04")["present"], "Reinício restaura encontro vencido")
	screen.queue_free()
	await process_frame
	print("INTERAÇÕES/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
