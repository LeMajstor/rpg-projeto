extends SceneTree
var screen
var lab
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-captures="):
			capture_directory = argument.trim_prefix("--visual-captures=")
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func place(position: Vector2) -> void:
	screen.session.world.leader_position = position
	screen.session.world.path.assign([position - Vector2(102, 0), position])
	screen.session.world.path_length = 102
	screen._refresh_map()

func travel(id: String) -> void:
	place(screen.session.world.entity_by_id(id)["position"] + Vector2(0, 40))
	expect(screen.session.begin_transition(id), "Transição por acesso real: " + id)
	screen.session.tick(screen.session.transition_duration)
	screen._refresh_map()

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	lab._handle_battle_input(event)

func finish() -> void:
	for step in range(240):
		if lab.model.action.is_empty():
			break
		lab.model.tick(1.0 / 120.0)
	lab._refresh()
	expect(lab.model.action.is_empty(), "Apresentação conclui no encontro integrado")

func successful_rolls() -> void:
	for key_name in ["affliction", "evasion"]:
		var stream = lab.model.damage_rngs[key_name]
		for seed_value in range(20000):
			stream.seed = seed_value
			var saved: int = stream.state
			var roll: float = stream.randf()
			if (key_name == "affliction" and roll < 0.01) or (key_name == "evasion" and roll > 0.99):
				stream.state = saved
				break

func run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	screen.set_script(load("res://tests/fixtures/pre_expansion_screen.gd"))
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	expect(screen.session.battle.uses_damage_v1() and screen.party_labels.size() == 3 and screen.leader_buttons.size() == 3, "Cena principal usa a equipe compartilhada")
	screen._toggle_menu()
	expect(screen.menu_panel.visible and "40/40" in screen.party_labels[0].text and "24/24" in screen.party_labels[2].text, "Menu/HUD mostram HP/MP aprovados")
	await capture("exploration-shared-party")
	screen.leader_buttons[2].pressed.emit()
	expect(screen.session.world.party_order[0] == "p3" and not screen.menu_panel.visible, "Mago lidera pelo menu")
	travel("town_exit")
	travel("dungeon_entrance")
	screen.session.world.toggle_door("door_01")
	var encounter = screen.session.world.entity_by_id("test_map_enemy_01")
	place(encounter["position"])
	var positions = screen.session.world.formation_positions()
	var shared = screen.session.battle
	screen._try_encounter()
	lab = screen.combat_ui
	lab.set_process(false)
	expect(lab.encounter_mode and lab.model == shared and lab.model.uses_damage_v1(), "UI recebe a mesma instância sem restaurar recursos")
	expect(not lab.cards[3]["panel"].visible and not lab.preset_picker.visible and lab.preparation_button == null, "Três cards e controles próprios do encontro")
	for actor in lab.model.enemies:
		actor["ini_modifier"] = -actor["ini"]
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_3)
	key(KEY_H)
	expect(lab.list_buttons.size() == 5, "Mago possui exatamente o repertório comum")
	key(KEY_DOWN)
	key(KEY_ENTER)
	successful_rolls()
	key(KEY_ENTER)
	finish()
	expect(lab.model.enemies[0]["affliction"].get("id") == "poison" and lab.model.party[2]["mp"] == 20, "Comando real aplica Veneno e debita 4 MP")
	successful_rolls()
	lab.model._begin_action(lab.model.enemies[0], lab.model.skill_for(lab.model.enemies[0], "poison"), "p1", Vector2.ZERO, "")
	finish()
	expect("Veneno" in lab.cards[0]["button"].text, "Aflição inimiga aparece no card")
	var before = lab.model.party[0]["affliction"].duplicate(true)
	lab.pause_button.button_pressed = true
	lab._process(10.0)
	expect(lab.model.party[0]["affliction"] == before, "Pausa manual congela Veneno integrado")
	await capture("exploration-poison")
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_I)
	expect(lab.list_buttons.size() == 1 and "3" in lab.list_buttons[0].text, "Só Remédio de teste com estoque correto")
	key(KEY_ENTER)
	await capture("exploration-remedy-target")
	key(KEY_ENTER)
	finish()
	expect(lab.model.inventory["remedy_test"] == 2 and lab.model.party[0]["affliction"].is_empty(), "Remédio cura no impacto e consome uma unidade")
	lab.model.data["settings"]["escape_chance"] = 1.0
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_F)
	finish()
	await process_frame
	expect(screen.combat_ui == null and screen.map_ui.visible and screen.session.area_id == "test_dungeon", "Sinal de fuga retorna à dungeon")
	expect(screen.session.world.formation_positions() == positions and screen.session.world.party_order[0] == "p3", "Retorno conserva fila e liderança")
	expect(shared.inventory["remedy_test"] == 2 and shared.party[2]["mp"] == 20 and shared.actors().all(func(actor): return actor["affliction"].is_empty()), "Retorno mantém gasto de MP/estoque e limpa efeitos")
	await capture("exploration-return")
	expect(not screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Fuga remove encontro atual")
	place(screen.session.world.entity_by_id("test_map_enemy_03")["position"])
	screen._physics_process(1.0 / 120.0)
	lab = screen.combat_ui
	lab.set_process(false)
	expect(lab.model == shared and shared.inventory["remedy_test"] == 2 and shared.party[2]["mp"] == 20, "Outro encontro não repõe recursos")
	screen._restart()
	await process_frame
	expect(screen.combat_ui == null and screen.session.battle.inventory["remedy_test"] == 3 and screen.session.battle.party[2]["mp"] == 24, "Reinício explícito restaura a sessão")
	screen.queue_free()
	await process_frame
	print("PARIDADE EXPLORAÇÃO UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
