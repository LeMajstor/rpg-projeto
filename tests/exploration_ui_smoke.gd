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

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura gráfica de " + name)

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

func approach() -> void:
	screen.session.move(Vector2.RIGHT, 4.0)
	screen.session.move(Vector2.UP, 1.75)
	screen._refresh_map()

func finish(lab) -> void:
	for step in range(100):
		lab.model.tick(1.0 / 120.0)
	lab._refresh()

func quiet_enemies(lab) -> void:
	lab.set_process(false)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	screen.set_script(load("res://tests/fixtures/legacy_exploration_screen.gd"))
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	expect(screen.map_ui.visible and screen.combat_ui == null, "Inicializa no mapa sem cena de combate")
	expect(screen.session.world.formation_positions().size() == 4, "Quatro personagens visíveis")
	expect(screen.map_view.actor_texture != null, "Sprite provisório foi criado sem importações externas")
	key(KEY_W)
	key(KEY_D)
	var position = screen.session.world.leader_position
	screen._physics_process(0.1)
	key(KEY_W, false)
	key(KEY_D, false)
	expect(screen.session.world.leader_position - position == Vector2(18, 0), "Teclas simultâneas produzem apenas eixo mais recente")
	key(KEY_TAB)
	key(KEY_TAB, false)
	expect(screen.menu_panel.visible and screen.session.world.menu_open, "Tab abre menu real da interface")
	await capture("exploration-menu")
	position = screen.session.world.leader_position
	key(KEY_D)
	screen._physics_process(0.1)
	key(KEY_D, false)
	expect(screen.session.world.leader_position == position, "Menu interrompe movimento por teclado")
	screen.leader_buttons[2].pressed.emit()
	expect(screen.session.world.party_order[0] == "p3" and not screen.menu_panel.visible, "Botão troca líder e fecha menu")
	expect("Aliado 3" in screen.leader_label.text, "HUD reflete identidade do novo líder")
	expect(screen.map_view.get_global_rect().encloses(screen.menu_panel.get_global_rect()), "Menu de liderança fica dentro da área visível do mapa")
	screen._restart()
	approach()
	screen.session.world.menu_open = true
	screen._choose_leader("p4")
	screen.session.battle.party[0]["hp"] = 143
	screen.session.battle.party[0]["mp"] = 28
	var slots = screen.session.world.formation_positions()
	var shared = screen.session.battle
	key(KEY_E)
	key(KEY_E, false)
	expect(screen.session.state == "battle" and not screen.map_ui.visible, "E inicia encontro e oculta mapa")
	var lab = screen.combat_ui
	expect(is_instance_valid(lab) and lab.encounter_mode, "Usa a cena de combate existente no modo integrado")
	expect(lab.model == shared, "Modelo é compartilhado, não copiado ou reimplementado")
	expect(lab.model.party[0]["hp"] == 143 and lab.model.party[0]["mp"] == 28, "Adicionar UI não reinicia recursos")
	expect(not lab.preset_picker.visible and not lab.continue_button.visible, "Controles isolados do laboratório ficam ocultos no encontro")
	lab._start(false)
	expect(lab.model.party[0]["hp"] == 143, "Reinício do laboratório não pode restaurar encontro integrado")
	quiet_enemies(lab)
	await capture("exploration-combat")
	position = screen.session.world.leader_position
	screen.session.move(Vector2.LEFT, 1)
	expect(screen.session.world.leader_position == position, "Mapa congelado durante combate")
	for enemy in lab.model.enemies:
		enemy["hp"] = 1
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[1].pressed.emit()
	lab.action_menu.get_child(2).pressed.emit()
	lab.action_menu.get_child(0).pressed.emit()
	finish(lab)
	await process_frame
	expect(screen.combat_ui == null and screen.map_ui.visible, "Sinal de vitória retorna automaticamente ao mapa")
	expect(screen.session.world.formation_positions() == slots, "Posição da fila preservada ao retornar")
	expect(screen.session.world.party_order[0] == "p4", "Líder escolhido preservado")
	expect(screen.session.battle.party[0]["hp"] == 143 and screen.session.battle.party[0]["mp"] == 18, "HP e custo real de MP refletem no mapa")
	expect(not screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Inimigo vencido desaparece da sessão")
	await capture("exploration-victory-return")
	# Fuga falha, fuga bem-sucedida e reencontro explícito.
	screen._restart()
	approach()
	screen._try_encounter()
	lab = screen.combat_ui
	quiet_enemies(lab)
	lab.model.data["settings"]["escape_chance"] = 0.0
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[3].pressed.emit()
	finish(lab)
	await process_frame
	expect(screen.combat_ui == lab and screen.session.state == "battle", "Fuga falha não retorna ao mapa")
	lab.model.data["settings"]["escape_chance"] = 1.0
	lab.model.mode = "Active"
	lab.model.party[0]["hp"] = 86
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[3].pressed.emit()
	finish(lab)
	await process_frame
	expect(screen.session.state == "exploration" and screen.combat_ui == null, "Fuga bem-sucedida retorna automaticamente")
	expect(screen.session.battle.party[0]["hp"] == 86 and screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Fuga mantém inimigo e HP gasto")
	await process_frame
	expect(screen.session.state == "exploration", "Proximidade não reinicia luta automaticamente")
	screen._try_encounter()
	lab = screen.combat_ui
	quiet_enemies(lab)
	expect(lab.model.party[0]["hp"] == 86 and lab.mode_picker.selected == 1, "Reencontro preserva HP e modo Active")
	for member in lab.model.party:
		member["hp"] = 0
	lab.model._check_end()
	lab._refresh()
	await process_frame
	expect(screen.session.state == "defeat" and not screen.map_ui.visible and is_instance_valid(screen.combat_ui), "Game Over permanece no combate")
	expect(lab.encounter_restart.visible, "Derrota oferece reinício explícito do teste")
	lab.encounter_restart.pressed.emit()
	await process_frame
	expect(screen.session.state == "exploration" and screen.session.world.entity_by_id("test_map_enemy_01")["present"], "Reinício reconstrói o teste sem callbacks antigos")
	expect(screen.session.battle.party[0]["hp"] == screen.session.battle.party[0]["max_hp"], "Somente reinício explícito restaura condições iniciais")
	screen.queue_free()
	await process_frame
	print("INTEGRAÇÃO/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
