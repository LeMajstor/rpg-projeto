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

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var path = "/private/tmp/rpg-damage-presets-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-damage-presets-report-%d.json" % OS.get_process_id()
	await new_screen(path)
	expect(screen.preset_pickers["ally"].item_count == 2 and screen.preset_pickers["enemy"].item_count == 2, "Cada categoria tem ficha manual e referência inicial")
	expect(screen.preset_update_buttons["ally"].disabled and screen.preset_update_buttons["enemy"].disabled and not FileAccess.file_exists(path), "Estado manual não atualiza referência nem cria arquivo")
	var enemy_before: Dictionary = screen.model.enemy().duplicate(true)
	var settings: Dictionary = screen.model.settings.duplicate(true)
	var action: Dictionary = screen.model.action.duplicate(true)
	screen.preset_pickers["ally"].grab_focus()
	pad(JOY_BUTTON_DPAD_RIGHT)
	expect(screen.model.ally()["hp"] == 40 and screen.model.ally()["physical_attack"] == 20 and screen.model.enemy() == enemy_before, "Controle carrega somente a ficha aliada")
	expect(screen.model.weapon["id"] == "sword_bronze" and screen.model.armor["id"] == "armor_bronze" and "20 + 10 = 30" in screen.composition_labels["attacker"].text, "Referência recompõe totais e equipamentos")
	screen.preset_pickers["enemy"].grab_focus()
	key(KEY_RIGHT)
	expect(screen.model.enemy()["hp"] == 30 and screen.model.enemy()["physical_attack"] == 23 and screen.model.enemy()["physical_defense"] == 60, "Teclado carrega referência inicial completa do monstro")
	expect(screen.model.settings == settings and screen.model.action == action and screen.model.sequence_position == 0, "Seleção de presets mantém controles globais e sequência")
	expect(screen.preset_update_buttons["ally"].disabled and "protegida" in screen.preset_status["ally"].text, "Referências fornecidas ficam protegidas")
	key(KEY_F9)
	expect(screen.last_result["snapshot"]["presets"]["attacker"]["name"] == "Aliado inicial · Bronze" and screen.last_result["snapshot"]["presets"]["target"]["name"] == "Monstro inicial · 30 HP", "Histórico identifica os dois presets usados")
	await capture("presets-reference")
	var historical: Dictionary = screen.last_result.duplicate(true)
	var rng: Dictionary = screen.model.rng_state.duplicate()
	var number: int = screen.model.run_number
	screen.profile_edits["attacker"]["hp"].value = 45
	expect("alterado" in screen.preset_status["ally"].text and screen.preset_update_buttons["ally"].disabled, "Edição marca referência alterada e exige salvar cópia")
	screen.preset_save_buttons["ally"].grab_focus()
	key(KEY_ENTER)
	await process_frame
	await process_frame
	expect(screen.preset_dialog.visible and screen.preset_name_edit.has_focus(), "Salvar como abre nome por teclado")
	key(KEY_F9)
	expect(screen.model.run_number == number, "Diálogo de nome bloqueia execução ao fundo")
	screen.preset_name_edit.text = ""
	screen.preset_dialog.get_ok_button().pressed.emit()
	expect(screen.preset_dialog.visible and not screen.preset_error.text.is_empty() and not FileAccess.file_exists(path), "Nome vazio mantém diálogo aberto sem criar preset")
	await capture("presets-save-dialog", screen.preset_dialog)
	screen.preset_name_edit.text = "Meu aliado · defesa"
	screen.preset_name_edit.text_submitted.emit(screen.preset_name_edit.text)
	expect(not screen.preset_dialog.visible and FileAccess.file_exists(path), "Confirmar nome grava arquivo pessoal")
	var ally_id: String = screen.model.selected_presets["ally"]["id"]
	expect(screen.model.selected_presets["ally"]["source"] == "custom" and not screen.model.preset_modified("ally") and screen.preset_update_buttons["ally"].disabled, "Novo personalizado fica selecionado e sincronizado")
	expect(screen.model.rng_state == rng and screen.last_result == historical, "Salvar não muda sorteios ou execução anterior")
	screen.profile_edits["attacker"]["hp"].value = 55
	expect(not screen.preset_update_buttons["ally"].disabled and "alterado" in screen.preset_status["ally"].text, "Atualizar só é habilitado após editar personalizado")
	screen.preset_update_buttons["ally"].grab_focus()
	pad(JOY_BUTTON_A)
	expect(screen.model.selected_presets["ally"]["revision"] == 2 and screen.preset_update_buttons["ally"].disabled, "Controle atualiza personalizado com revisão nova")
	var disk = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(disk["presets"].size() == 1 and disk["presets"][0]["actor"]["hp"] == 55, "Atualização persiste sem duplicar entrada")
	var unchanged = FileAccess.get_file_as_string(path)
	screen._request_preset_save("enemy")
	screen.preset_dialog.get_cancel_button().pressed.emit()
	expect(FileAccess.get_file_as_string(path) == unchanged and screen.pending_preset.is_empty(), "Cancelar preserva biblioteca e limpa captura")
	screen._request_preset_save("enemy")
	screen.preset_name_edit.text = "Meu monstro · inicial"
	screen.preset_dialog.get_ok_button().pressed.emit()
	var enemy_id: String = screen.model.selected_presets["enemy"]["id"]
	expect(screen.model.selected_presets["enemy"]["source"] == "custom" and screen.model.rng_state == rng, "Monstro personalizado é salvo independente do aliado e sem sorteios")
	unchanged = FileAccess.get_file_as_string(path)
	screen._request_preset_save("ally")
	screen.preset_name_edit.text = "Meu aliado · defesa"
	screen.preset_dialog.get_ok_button().pressed.emit()
	expect(screen.preset_dialog.visible and "Já existe" in screen.preset_error.text and FileAccess.get_file_as_string(path) == unchanged, "Nome duplicado não sobrescreve preset")
	screen.preset_dialog.get_cancel_button().pressed.emit()
	for control in screen.focus_controls:
		if control is Button and control.text == "Trocar lados":
			control.grab_focus()
			pad(JOY_BUTTON_A)
			break
	expect(screen.model.ally_role() == "target" and screen.preset_pickers["ally"].get_item_metadata(screen.preset_pickers["ally"].selected) == ally_id, "Presets permanecem nas categorias após inverter lados")
	screen.profile_edits["attacker"]["hp"].value = 9000
	choose_preset("enemy", enemy_id)
	expect(screen.model.attacker["hp"] == 30 and screen.model.target["hp"] == 55 and screen.model.armor["id"] == "armor_bronze", "Carregar monstro restaura só seu lado e preserva equipamento do aliado alvo")
	key(KEY_F7)
	expect("Meu aliado · defesa" in screen.conditions.text and "revisão 2" in screen.conditions.text, "Condições exibem preset/revisão de cada participante")
	await capture("presets-custom")
	screen.profile_edits["target"]["hp"].value = 65
	screen._request_export()
	screen._save_export(export_path)
	var report = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["conditions"]["presets"]["target"]["id"] == ally_id and report["conditions"]["presets"]["target"]["revision"] == 2 and report["conditions"]["target"]["hp"] == 55, "JSON mantém valores e revisão da execução, não da edição posterior")
	key(KEY_F5)
	expect(screen.model.selected_presets.is_empty() and FileAccess.get_file_as_string(path) == unchanged, "Restaurar caso não apaga os dois presets pessoais")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	expect(screen.preset_pickers["ally"].item_count == 3 and screen.preset_pickers["enemy"].item_count == 3, "Reabrir mostra referências e personalizados de ambas as categorias")
	choose_preset("ally", ally_id)
	choose_preset("enemy", enemy_id)
	expect(screen.model.ally()["hp"] == 55 and screen.model.enemy()["hp"] == 30 and screen.model.configuration()["attacker"]["physical_attack"] == 30, "Reabertura carrega próprios e recalcula total sem duplicação")
	await capture("presets-reopened")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("PRESETS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
