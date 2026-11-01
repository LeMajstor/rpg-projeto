extends SceneTree
const STEP = 1.0 / 120.0
var lab
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-captures="):
			capture_directory = arg.trim_prefix("--visual-captures=")
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	lab._handle_battle_input(event)

func finish() -> void:
	for index in range(120):
		if lab.model.action.is_empty():
			break
		lab.model.tick(STEP)
	lab._refresh()
	expect(lab.model.action.is_empty(), "Ação termina pela simulação")

func capture(name: String, window = null) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	lab._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var viewport = root if window == null else window
	expect(viewport.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	expect(lab.model.preset["id"] == "lab_damage_v1" and lab.model.party.size() == 3, "Abre diretamente na V1")
	expect(not lab.cards[3]["panel"].visible and lab.cards[2]["panel"].visible, "Somente três cards visíveis")
	key(KEY_4)
	expect(lab.model.selected_id.is_empty(), "Atalho4 seguro sem quarto aliado")
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -enemy["ini"]
	lab.model.debug_ready_allies()
	lab._refresh()
	await capture("v1-ready")
	key(KEY_1)
	expect(lab.model.selected_id == "p1" and lab.command_buttons[1].disabled and lab.command_buttons[2].disabled, "Sem magia/itens antigos no Aliado1")
	key(KEY_A)
	key(KEY_ESCAPE)
	expect(lab.model.action.is_empty() and lab.model.party[0]["atb"] == 1.0, "Cancelar mira não gasta ação")
	key(KEY_ESCAPE)
	key(KEY_3)
	key(KEY_H)
	expect(lab.list_buttons.size() == 1 and "7 MP" in lab.list_buttons[0].text, "Só magia básica7MP na lista do mago")
	key(KEY_ENTER)
	expect(lab.menu_kind == "target", "Magia abre mira com teclado")
	key(KEY_RIGHT)
	var target = lab.target_focus_id
	key(KEY_ENTER)
	expect(lab.model.action.get("target_id") == target and lab.model.party[2]["mp"] == 17, "Confirmação gasta7MP")
	while not lab.model.action.is_empty() and not lab.model.action["applied"]:
		lab.model.tick(STEP)
	await capture("v1-magic-impact")
	finish()
	expect(lab.model.damage_results.size() == 1 and not lab.model.damage_results[0]["evaded"], "Impacto mágico registrado")
	var damage: int = lab.model.damage_results[0]["damage"]
	expect(lab.model.actor_by_id(target)["hp"] == lab.model.actor_by_id(target)["max_hp"] - damage, "Interface mostra HP cumulativo")
	# Preparar pausa o tempo e mantém os equipamentos ativos até iniciar.
	lab.held_direction = Vector2.RIGHT
	lab.preparation_button.pressed.emit()
	await process_frame
	var preparation = lab.preparation_window
	expect(preparation.visible and preparation.summaries.size() == 3, "Preparação dos três aliados")
	var time_before: float = lab.model.simulation_time
	lab._process(0.2)
	expect(lab.model.simulation_time == time_before and lab.held_direction == Vector2.ZERO, "Preparação pausa ATB/movimento e limpa repetição do controle")
	var row = preparation.summaries[2]["row"]
	var weapon: OptionButton = row.get_child(0)
	var armor: OptionButton = row.get_child(1)
	expect(weapon.item_count == 6 and armor.item_count == 6, "Seis estágios exclusivos de cajados/vestes")
	for i in range(6):
		weapon.select(i)
		weapon.item_selected.emit(i)
		armor.select(i)
		armor.item_selected.emit(i)
	expect(lab.model.pending_loadouts["p3"]["weapon"]["id"] == "staff_runic" and lab.model.pending_loadouts["p3"]["armor"]["id"] == "robe_runic", "Seletores atualizam o aliado correto")
	expect(lab.model.party[2]["damage_stats"]["magic_power"] == 40 and lab.model.party[2]["mp"] == 17, "Seleções pendentes não alteram luta atual")
	expect("30 → 95" in preparation.summaries[2]["label"].text, "Resumo mostra naturais e efetivos")
	await capture("v1-equipment", preparation)
	preparation.hide()
	preparation.start_requested.emit()
	expect(lab.model.party[2]["damage_stats"]["magic_power"] == 95 and lab.model.party[2]["damage_stats"]["magic_defense"] == 95 and lab.model.party[2]["mp"] == 24, "Reinício aplica equipamento e restaura recursos")
	# F3 acompanha o número de aliados, inclusive ao alternar para cenário anterior.
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect(lab.debug_actor.item_count == 3 and "Aliado #3" in lab.debug_actor.get_item_text(2), "F3 mostra as três fichas atuais")
	lab.preset_picker.select(0)
	lab._start(false)
	lab._refresh()
	expect(lab.model.party.size() == 4 and lab.cards[3]["panel"].visible and lab.debug_actor.item_count == 4, "Referência anterior conserva equipe/depuração")
	lab.preset_picker.select(lab.model.default_preset_index())
	lab._start(false)
	lab.debug_actor.select(2)
	lab.hp_edit.value = 0
	lab._apply_debug_edits()
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_3)
	expect(lab.model.selected_id.is_empty(), "Incapacitado não pode ser escolhido")
	lab.debug_window.hide()
	lab.queue_free()
	await process_frame
	print("BATALHA DANOS V1 UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
