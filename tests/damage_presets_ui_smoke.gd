extends "res://tests/damage_lab_ui_smoke.gd"

func choose_preset(side: String, id: String) -> void:
	var picker: OptionButton = screen.preset_pickers[side]
	for index in range(picker.item_count):
		if picker.get_item_metadata(index) == id:
			choose(picker, index)
			return

func new_screen(path: String) -> void:
	screen = load("res://scenes/damage_lab.tscn").instantiate()
	screen.preset_storage_path = path
	root.add_child(screen)
	await process_frame
	screen.set_process(false)

func save_preset(side: String, name: String) -> String:
	screen._request_preset_save(side)
	screen.preset_name_edit.text = name
	screen.preset_dialog.get_ok_button().pressed.emit()
	return screen.model.selected_presets.get(side, {}).get("id", "")

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var path = "/private/tmp/rpg-damage-presets-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-damage-presets-report-%d.json" % OS.get_process_id()
	await new_screen(path)
	expect(screen.preset_pickers["ally"].item_count == 1 and screen.preset_pickers["enemy"].item_count == 1 and not FileAccess.file_exists(path), "Listas começam vazias sem referências e sem criar arquivo pessoal")
	for side in ["ally", "enemy"]:
		expect(screen.preset_update_buttons[side].disabled and screen.preset_delete_buttons[side].disabled and screen.preset_load_buttons[side].disabled and not screen.preset_save_buttons[side].disabled, "Ficha manual permite salvar; carregar/atualizar/excluir indisponíveis")
	await capture("presets-empty")
	var own = {"hp": 47, "mp": 0, "ini": 17, "physical_attack": 23, "physical_defense": 28, "magic_power": 367, "magic_defense": 999, "critical_base": 8, "evasion_base": 19}
	var monster = {"hp": 99999, "mp": 1, "ini": 99, "physical_attack": 302, "physical_defense": 204, "magic_power": 9999, "magic_defense": 405, "critical_base": 16, "evasion_base": 7}
	for stat in own:
		screen.profile_edits["attacker"][stat].value = own[stat]
		screen.profile_edits["target"][stat].value = monster[stat]
	choose_id(screen.weapon_picker, screen.model.data["weapons"], "sword_steel")
	choose_id(screen.armor_picker, screen.model.data["armors"], "armor_mithril")
	screen.weapon_bonus.value = 17
	screen.armor_bonus.value = 12
	screen.weapon_chance.value = 7.5
	screen.weapon_multiplier.value = 3.1
	screen.enemy_multiplier.value = 2.5
	key(KEY_F7)
	var historical: Dictionary = screen.last_result.duplicate(true)
	var rng: Dictionary = screen.model.rng_state.duplicate()
	var settings: Dictionary = screen.model.settings.duplicate(true)
	var action: Dictionary = screen.model.action.duplicate(true)
	var number: int = screen.model.run_number
	# Salvar deve confirmar a digitação pendente, mesmo sem Enter.
	screen.profile_edits["attacker"]["hp"].grab_focus()
	type_text("47")
	screen._request_preset_save("ally")
	await process_frame
	expect(screen.preset_dialog.visible and screen.preset_name_edit.has_focus(), "Salvar abre diálogo de nome e captura ficha atual")
	key(KEY_F9)
	expect(screen.model.run_number == number, "Diálogo de nome bloqueia execução ao fundo")
	screen.preset_name_edit.text = ""
	screen.preset_dialog.get_ok_button().pressed.emit()
	expect(screen.preset_dialog.visible and not screen.preset_error.text.is_empty() and not FileAccess.file_exists(path), "Nome vazio não salva")
	await capture("presets-save-dialog", screen.preset_dialog)
	screen.preset_name_edit.text = "Aliado de estudo"
	screen.preset_name_edit.text_submitted.emit(screen.preset_name_edit.text)
	var ally_id: String = screen.model.selected_presets["ally"]["id"]
	expect(not ally_id.is_empty() and not screen.preset_dialog.visible and screen.model.ally()["hp"] == 47, "Confirmação salva ficha com digitação pendente")
	expect(screen.model.ally()["name"] == "Aliado de estudo" and screen.profile_labels["attacker"].text == "Aliado de estudo", "Nome salvo identifica ficha e duelo")
	expect(not screen.preset_load_buttons["ally"].disabled and not screen.preset_delete_buttons["ally"].disabled and screen.preset_update_buttons["ally"].disabled, "Preset salvo pode carregar/excluir; atualizar só após edição")
	var enemy_id = save_preset("enemy", "Monstro de estudo")
	expect(not enemy_id.is_empty() and screen.model.rng_state == rng and screen.model.run_number == number and screen.last_result == historical, "Salvar fichas mantém RNG e resultados anteriores")
	# Recarga explícita do mesmo preset; nenhum valor deve ficar preso ao texto anterior.
	for stat in own:
		screen.profile_edits["attacker"][stat].value = 1
	screen.weapon_bonus.value = 99
	screen.armor_bonus.value = 99
	screen.profile_edits["attacker"]["hp"].grab_focus()
	type_text("333")
	screen._reload_preset("ally")
	for stat in own:
		expect(screen.model.ally()[stat] == own[stat] and screen.profile_edits["attacker"][stat].value == own[stat], "Carregar restaura atributo e editor: " + stat)
	key(KEY_TAB)
	expect(screen.model.ally()["hp"] == 47 and screen.profile_edits["attacker"]["hp"].get_line_edit().text == "47", "Texto pendente não sobrescreve dados após carregar e perder foco")
	expect(screen.model.weapon["id"] == "sword_steel" and screen.model.armor["id"] == "armor_mithril" and screen.weapon_bonus.value == 17 and screen.armor_bonus.value == 12 and screen.weapon_chance.value == 7.5 and screen.weapon_multiplier.value == 3.1, "Carregar restaura seleções, bônus e crítico dos equipamentos")
	expect("23 + 17 = 40" in screen.composition_labels["attacker"].text and screen.model.settings == settings and screen.model.action == action and screen.model.rng_state == rng, "Carregar recalcula total sem duplicar bônus e preserva controles/RNG")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	screen.profile_edits["attacker"]["hp"].value = 2
	screen.enemy_multiplier.value = 9
	screen.preset_load_buttons["enemy"].grab_focus()
	pad(JOY_BUTTON_A)
	for stat in monster:
		expect(screen.model.enemy()[stat] == monster[stat] and screen.profile_edits["attacker"][stat].value == monster[stat], "Monstro carrega todos os valores após trocar lados: " + stat)
	expect(screen.enemy_multiplier.value == 2.5 and screen.model.ally()["mp"] == 0 and screen.model.weapon["attack_bonus"] == 17, "Crítico próprio do monstro e equipamento do aliado alvo são preservados")
	screen.profile_edits["target"]["hp"].value = 55
	screen.preset_update_buttons["ally"].grab_focus()
	key(KEY_ENTER)
	expect(screen.model.selected_presets["ally"]["revision"] == 2 and screen.preset_update_buttons["ally"].disabled, "Atualizar persiste revisão nova sem duplicação")
	key(KEY_F7)
	var result: Dictionary = screen.last_result.duplicate(true)
	screen._request_export()
	screen._save_export(export_path)
	var report = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["conditions"]["target"]["hp"] == 55 and report["conditions"]["attacker"]["hp"] == 99999 and report["conditions"]["presets"]["target"]["revision"] == 2, "Exportação conserva fichas e revisão carregadas")
	await capture("presets-saved")
	var unchanged = FileAccess.get_file_as_string(path)
	screen._request_preset_save("ally")
	screen.preset_name_edit.text = "Aliado de estudo"
	screen.preset_dialog.get_ok_button().pressed.emit()
	expect(screen.preset_dialog.visible and "Já existe" in screen.preset_error.text and FileAccess.get_file_as_string(path) == unchanged, "Nome duplicado não sobrescreve")
	screen.preset_dialog.get_cancel_button().pressed.emit()
	expect(FileAccess.get_file_as_string(path) == unchanged, "Cancelar preserva presets")
	# Exclusão é persistente, sem apagar a ficha em edição ou o histórico.
	var before: Dictionary = screen.model.ally().duplicate(true)
	var before_rng: Dictionary = screen.model.rng_state.duplicate()
	screen.preset_delete_buttons["ally"].grab_focus()
	pad(JOY_BUTTON_A)
	expect(screen.preset_pickers["ally"].item_count == 1 and not screen.model.selected_presets.has("ally") and screen.model.ally() == before, "Excluir remove preset do aliado e mantém ficha atual")
	expect(screen.preset_pickers["enemy"].item_count == 2 and screen.model.rng_state == before_rng and screen.last_result == result, "Excluir não modifica outra categoria, RNG ou histórico")
	expect(screen.preset_delete_buttons["ally"].disabled and screen.preset_load_buttons["ally"].disabled, "Exclusão volta ao estado manual")
	await capture("presets-deleted")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	expect(screen.preset_pickers["ally"].item_count == 1 and screen.preset_pickers["enemy"].item_count == 2, "Exclusão permanece ao reabrir")
	choose_preset("enemy", enemy_id)
	for stat in monster:
		expect(screen.model.enemy()[stat] == monster[stat], "Reabertura carrega campo do monstro: " + stat)
	key(KEY_F6)
	unchanged = FileAccess.get_file_as_string(path)
	screen._delete_preset("enemy")
	expect(screen.busy and FileAccess.get_file_as_string(path) == unchanged, "Exclusão bloqueada durante animação")
	finish()
	screen._delete_preset("enemy")
	expect(screen.preset_pickers["enemy"].item_count == 1 and screen.preset_library.custom.is_empty(), "Excluir último preset deixa biblioteca vazia")
	var new_id = save_preset("ally", "Novo aliado")
	expect(not new_id.is_empty() and screen.preset_library.entries("ally").size() == 1, "Salvar continua disponível após excluir todos")
	await capture("presets-restarted")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("PRESETS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
