extends SceneTree
const STEP = 1.0 / 120.0
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

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	lab._handle_battle_input(event)

func successful_rolls() -> void:
	for key_name in ["affliction", "evasion"]:
		var stream = lab.model.damage_rngs[key_name]
		for seed_value in range(1, 20000):
			stream.seed = seed_value
			var before: int = stream.state
			var roll: float = stream.randf()
			if roll < 0.01 if key_name == "affliction" else roll >= 0.99:
				stream.state = before
				break

func finish() -> void:
	for index in range(120):
		if lab.model.action.is_empty():
			break
		lab.model.tick(STEP)
	lab._refresh()
	expect(lab.model.action.is_empty(), "Apresentação conclui sem travar")

func run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_3)
	key(KEY_H)
	expect(lab.list_buttons.size() == 5, "Mago tem magia ofensiva e quatro aflições")
	key(KEY_DOWN)
	key(KEY_ENTER)
	expect(lab.menu_kind == "target" and lab.aim_id == "poison", "Navegação normal seleciona Veneno")
	successful_rolls()
	key(KEY_ENTER)
	expect(lab.model.party[2]["mp"] == 20, "Confirmação gasta 4MP uma única vez")
	finish()
	expect(lab.model.enemies[0]["affliction"].get("id") == "poison", "Comando jogável aplica Veneno real")
	# Um inimigo de teste usa as mesmas ações/cálculos contra o grupo.
	successful_rolls()
	lab.model._begin_action(lab.model.enemies[0], lab.model.skill_for(lab.model.enemies[0], "poison"), "p1", Vector2.ZERO, "")
	finish()
	expect("Veneno" in lab.cards[0]["button"].text, "Card identifica aflição recebida")
	var before: Dictionary = lab.model.party[0]["affliction"].duplicate(true)
	lab.pause_button.button_pressed = true
	lab._process(10.0)
	expect(lab.model.party[0]["affliction"] == before, "Pausa manual não avança contagem de aflição")
	await capture("combat-afflictions")
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_I)
	key(KEY_ENTER)
	await capture("remedy-target")
	key(KEY_ENTER)
	finish()
	expect(lab.model.party[0]["affliction"].is_empty() and lab.model.inventory["remedy_test"] == 2, "Remédio cura aplicação real e consome estoque")
	expect(lab.model.enemies[0]["affliction"].get("id") == "poison", "Cura não afeta outro participante")
	await capture("combat-after-cure")
	lab.queue_free()
	await process_frame
	var damage = load("res://scenes/damage_lab.tscn").instantiate()
	damage.preset_storage_path = "/private/tmp/rpg-shared-references-%d.json" % OS.get_process_id()
	root.add_child(damage)
	await process_frame
	expect(damage.reference_pickers["ally"].item_count == 4 and damage.reference_pickers["enemy"].item_count == 3, "Cinco referências compartilhadas acessíveis na calculadora")
	damage._choose_reference(3, "ally")
	damage._choose_reference(2, "enemy")
	var config: Dictionary = damage.model.configuration()
	expect(config[damage.model.ally_role()]["magic_power"] == 40 and damage.model.enemy()["ranged_defense"] == 50, "Calculadora carrega Mago e Monstro2 aprovados")
	expect(damage.preset_library.custom.is_empty(), "Carregar referência não grava biblioteca pessoal")
	expect(damage.preset_update_buttons["ally"].disabled, "Referência não permite sobrescrita pessoal")
	await capture("shared-damage-references")
	damage.queue_free()
	await process_frame
	print("PARIDADE LABORATÓRIOS UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
