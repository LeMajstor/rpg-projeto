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
	expect(screen.session.state == "transition", "E inicia viagem: " + id)
	screen._physics_process(screen.session.transition_duration)
	expect(screen.session.state == "exploration" and not screen.transition_overlay.visible, "Viagem conclui: " + id)

func close_dialogue() -> void:
	for step in range(12):
		if not screen.session.dialogue.opened:
			return
		screen.dialogue_next.pressed.emit()
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
	expect(screen.session.area_id == "lab_exterior" and screen.session.world.entities.size() == 6, "Vila possui três acessos, dois NPCs e pedra")
	for entity in screen.session.world.entities:
		expect(entity["kind"] in ["transition", "npc"] or entity.get("object_type", "") == "mysterious_stone", "Vila permite NPCs e pedra, sem monstros")
	await capture("interiors-exterior")
	# Percurso físico do início até a entrada da dungeon.
	key(KEY_D)
	screen._physics_process(1020.0 / 180.0)
	key(KEY_D, false)
	key(KEY_W)
	screen._physics_process(216.0 / 180.0)
	key(KEY_W, false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(1230, 284)), "Acesso à dungeon alcançável andando pelo exterior")
	expect("Sair da vila" in screen.interact_button.text, "Saída contextual da vila")
	tap(KEY_E)
	screen._physics_process(screen.session.transition_duration)
	expect(screen.session.area_id == "test_world", "Portão leva ao mundo aberto")
	travel("dungeon_entrance")
	expect(screen.session.area_id == "test_dungeon" and "dungeon" in screen.area_label.text, "Troca para mini dungeon")
	expect(screen.session.world.entities.size() == 10, "Seis monstros, três objetos e saída visíveis na dungeon")
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Quatro integrantes chegam em trecho livre")
	await capture("interiors-dungeon")
	# Percurso até a alavanca pela passagem estreita.
	for segment in [[KEY_D, 150.0], [KEY_W, 260.0], [KEY_D, 23.0]]:
		key(segment[0])
		screen._physics_process(segment[1] / 180.0)
		key(segment[0], false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(333, 340)), "Fila percorre corredores da dungeon")
	expect("Alavanca" in screen.interact_button.text, "Alavanca contextual no interior")
	tap(KEY_E)
	expect(screen.dialogue_overlay.visible and screen.session.world.entity_by_id("door_01")["open"], "Alavanca abre a passagem e apresenta fala")
	close_dialogue()
	key(KEY_D)
	screen._physics_process(147.0 / 180.0)
	key(KEY_D, false)
	expect(screen.session.world.leader_position.is_equal_approx(Vector2(480, 340)), "Porta aberta deixa atravessar")
	await capture("interiors-dungeon-open")
	# Batalha real no novo mapa, sem reimplementação.
	place(Vector2(930, 190))
	screen.session.battle.party[0]["hp"] = 97
	screen.session.battle.party[0]["mp"] = 30
	var shared = screen.session.battle
	tap(KEY_E)
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and lab.model == shared and lab.model.preset["id"] == "exploration_seeded_fullscreen", "M4 usa tela inteira com os ritmos atuais no combate existente")
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
	expect(screen.combat_ui == null and screen.map_ui.visible and screen.session.area_id == "test_dungeon", "Vitória retorna à dungeon")
	expect(not screen.session.world.entity_by_id("test_map_enemy_04")["present"] and screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Somente o monstro vencido desaparece")
	expect(screen.session.battle.party[0]["hp"] == 97 and screen.session.battle.party[0]["mp"] == 20, "HP/MP preservados após combate")
	travel("dungeon_exit")
	expect(screen.session.area_id == "test_world" and screen.session.world.entities.size() == 2, "Saída da dungeon retorna ao mundo sem monstros")
	travel("house_entrance")
	expect(screen.session.area_id == "test_house" and screen.session.world.entities.size() == 5, "Casa contém três NPCs, placa e saída")
	await capture("interiors-house-npcs")
	place(Vector2(380, 230))
	tap(KEY_E)
	expect(screen.dialogue_speaker.text == "NPC 2" and screen.dialogue_choice_buttons.size() == 2, "Respostas do NPC funcionam na casa")
	var before = screen.session.world.entity_by_id("npc_02")["route_state"].duplicate(true)
	key(KEY_D)
	screen._physics_process(1)
	key(KEY_D, false)
	expect(screen.session.world.leader_position == Vector2(380, 230) and screen.session.world.entity_by_id("npc_02")["route_state"] == before, "Diálogo pausa movimento e NPCs")
	await capture("interiors-house-dialogue")
	tap(KEY_2)
	expect(screen.session.dialogue.node_id == "formation", "Tecla seleciona resposta")
	close_dialogue()
	screen._physics_process(0.1)
	expect(screen.session.world.entity_by_id("npc_02")["route_state"] != before, "Patrulha da casa retoma após conversa")
	travel("house_exit")
	travel("dungeon_entrance")
	expect(not screen.session.world.entity_by_id("test_map_enemy_04")["present"] and screen.session.world.entity_by_id("door_01")["open"], "Revisita conserva vitória e porta")
	expect(screen.session.battle.party[0]["hp"] == 97 and screen.session.battle.party[0]["mp"] == 20, "Passar pela casa não recupera recursos")
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and screen.session.area_worlds.size() == 1, "Reinício começa no exterior")
	travel("dungeon_entrance")
	expect(screen.session.world.entity_by_id("test_map_enemy_04")["present"] and not screen.session.world.entity_by_id("door_01")["open"], "Reinício restaura dungeon")
	screen.queue_free()
	await process_frame
	print("INTERIORES/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
