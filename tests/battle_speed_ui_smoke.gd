extends SceneTree
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

func choose(picker: OptionButton, level: int) -> void:
	picker.select(level - 1)
	picker.item_selected.emit(level - 1)

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func travel(screen, id: String) -> void:
	var portal: Dictionary = screen.session.world.entity_by_id(id)
	var position: Vector2 = portal["position"] + Vector2(0, 40)
	screen.session.world.leader_position = position
	screen.session.world.path.assign([position - Vector2(102, 0), position])
	screen.session.world.path_length = 102
	expect(screen.session.begin_transition(id), "Transição disponível: " + id)
	screen.session.tick(screen.session.transition_duration)

func _run() -> void:
	var lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	expect(lab.battle_speed_picker.item_count == 8 and lab.battle_speed_picker.selected == 3, "Laboratório oferece 1..8 e inicia em 4")
	choose(lab.battle_speed_picker, 6)
	expect(lab.model.battle_speed == 6 and lab.model.atb_rate_multiplier() == 1.0, "Controle do laboratório seleciona referência 6")
	choose(lab.battle_speed_picker, 2)
	lab._start(false)
	expect(lab.model.battle_speed == 2 and lab.battle_speed_picker.selected == 1, "Novo teste preserva seleção e controle sincronizado")
	expect(lab.speed_slider.value == 1.0, "Battle Speed não muda velocidade de depuração")
	choose(lab.battle_speed_picker, 4)
	lab._refresh()
	await capture("battle-speed-lab")
	lab.queue_free()
	await process_frame
	var screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	screen._toggle_menu()
	expect(screen.menu_panel.visible and screen.session.world.menu_open, "Menu do mapa aberto e pausado")
	expect(screen.battle_speed_picker.item_count == 8 and screen.battle_speed_picker.selected == 3, "Menu do jogo oferece 1..8 com padrão 4")
	expect(screen.map_view.get_global_rect().encloses(screen.menu_panel.get_global_rect()), "Menu ampliado cabe no mapa")
	choose(screen.battle_speed_picker, 7)
	expect(screen.session.battle.battle_speed == 7, "Menu altera configuração da sessão")
	await capture("battle-speed-menu")
	screen._toggle_menu()
	travel(screen, "town_exit")
	var clock_before: float = screen.session.clock.minutes_of_day()
	screen.session.tick(1.0)
	var clock_delta: float = screen.session.clock.minutes_of_day() - clock_before
	screen.session.battle.battle_speed = 1
	clock_before = screen.session.clock.minutes_of_day()
	screen.session.tick(1.0)
	expect(is_equal_approx(screen.session.clock.minutes_of_day() - clock_before, clock_delta), "Battle Speed não altera relógio do mapa-múndi")
	screen.session.battle.battle_speed = 7
	travel(screen, "dungeon_entrance")
	var entity: Dictionary = screen.session.world.entity_by_id("test_map_enemy_01")
	var position: Vector2 = entity["position"]
	screen.session.world.leader_position = position
	screen.session.world.path.assign([position - Vector2(102, 0), position])
	screen.session.world.path_length = 102
	screen._try_encounter()
	var combat = screen.combat_ui
	expect(is_instance_valid(combat), "Encontro abre combate integrado")
	if is_instance_valid(combat):
		combat.set_process(false)
		expect(combat.model == screen.session.battle and combat.battle_speed_picker.selected == 6, "Combate integrado recebe velocidade escolhida no menu")
		choose(combat.battle_speed_picker, 3)
		combat.model.outcome = "escaped"
		screen._on_battle_finished("escaped")
		expect(screen.session.state == "exploration" and screen.battle_speed_picker.selected == 2, "Retorno sincroniza menu com escolha feita no combate")
		expect(screen.session.begin_encounter("test_map_enemy_01") and screen.session.battle.battle_speed == 3, "Reencontro preserva velocidade escolhida")
	screen._restart()
	expect(screen.session.battle.battle_speed == 4 and screen.battle_speed_picker.selected == 3, "Reinício global cria sessão no padrão 4")
	screen.queue_free()
	await process_frame
	print("BATTLE SPEED/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
