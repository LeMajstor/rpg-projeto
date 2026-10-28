extends "res://tests/damage_presets_ui_smoke.gd"

func has_equipment(picker: OptionButton, id: String) -> bool:
	for i in range(picker.item_count):
		if picker.get_item_metadata(i) == id:
			return true
	return false

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var path = "/private/tmp/rpg-exclusive-ui-%d.json" % OS.get_process_id()
	await new_screen(path)
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var first: Dictionary = screen.preset_library.create("Aliado #1", screen.model.preset_payload("ally"))["preset"]
	var second: Dictionary = screen.preset_library.create("Aliado #2", recipe)["preset"]
	screen._rebuild_preset_lists()
	screen._refresh_preset_controls()
	choose_preset("ally", first["id"])
	expect(not has_equipment(screen.weapon_picker, "compound_bow") and not has_equipment(screen.armor_picker, "leather_set"), "Arco/couro não aparecem para o primeiro aliado")
	expect(has_equipment(screen.weapon_picker, "sword_bronze") and has_equipment(screen.armor_picker, "armor_bronze"), "Primeiro aliado mantém equipamentos comuns")
	expect(not has_equipment(screen.weapon_picker, "none") and not has_equipment(screen.armor_picker, "none"), "Primeiro aliado não vê opções sem equipamento")
	await capture("ally1-restricted")
	var weapon_before: Dictionary = screen.model.weapon.duplicate(true)
	expect(not screen.model.choose_equipment("weapon", "compound_bow").is_empty() and screen.model.weapon == weapon_before, "Modelo também bloqueia escolha direta fora do menu")
	screen.model.ally()["name"] = "Aliado #2"
	screen._sync_controls()
	expect(not has_equipment(screen.weapon_picker, "compound_bow") and "Aliado #1" in screen.profile_labels["attacker"].tooltip_text, "Renomear ficha não altera identidade/permissões")
	choose_preset("ally", second["id"])
	expect(has_equipment(screen.weapon_picker, "compound_bow") and has_equipment(screen.armor_picker, "leather_set"), "Segundo aliado vê seus equipamentos exclusivos")
	expect(screen.weapon_picker.item_count == 6 and screen.armor_picker.item_count == 6, "Segundo aliado vê seis arcos/trajes, sem espadas, metal ou opção vazia")
	expect(screen.weapon_picker.get_item_metadata(screen.weapon_picker.selected) == "compound_bow" and screen.armor_picker.get_item_metadata(screen.armor_picker.selected) == "leather_set", "Carregamento seleciona equipamento por ID após filtrar lista")
	expect("Aliado #2" in screen.profile_labels["attacker"].tooltip_text and screen.model.configuration()["attacker"]["evasion_base"] == 12, "Identidade correta e totais mantidos")
	await capture("ally2-exclusive")
	screen._request_preset_save("ally")
	screen.preset_name_edit.text = "Cópia de teste"
	screen.preset_dialog.get_ok_button().pressed.emit()
	var copy_id: String = screen.model.selected_presets["ally"]["id"]
	expect(copy_id != second["id"] and screen.model.ally()["character_id"] == "ally_2" and has_equipment(screen.weapon_picker, "compound_bow"), "Salvar cópia com outro nome mantém exclusividade do personagem")
	await capture("ally2-copy")
	choose_preset("ally", first["id"])
	expect(screen.model.weapon["id"] == "sword_bronze" and not has_equipment(screen.armor_picker, "leather_set"), "Trocar para primeiro aliado restaura lista e equipamento compatíveis")
	choose_preset("ally", copy_id)
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.ally_role() == "target" and has_equipment(screen.weapon_picker, "compound_bow") and screen.model.configuration()["equipment"]["target"]["owner_id"] == "ally_2", "Inversão não perde permissão nem confunde dono")
	key(KEY_F7)
	expect(screen.last_result.get("error", "inválido").is_empty(), "Lote válido continua funcionando com segundo aliado alvo")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally", copy_id)
	expect(screen.model.ally()["character_id"] == "ally_2" and screen.model.weapon["id"] == "compound_bow", "Identidade e equipamentos exclusivos persistem ao reabrir")
	choose_preset("ally", first["id"])
	expect(not has_equipment(screen.weapon_picker, "compound_bow") and not has_equipment(screen.armor_picker, "leather_set"), "Bloqueio também persiste para primeiro aliado após reabrir")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("EXCLUSIVIDADE/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
