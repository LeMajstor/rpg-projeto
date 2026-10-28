extends "res://tests/damage_equipment_exclusivity_ui_smoke.gd"
const ScaleTests = preload("res://tests/damage_equipment_scales_tests.gd")

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var path = "/private/tmp/rpg-scales-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-scales-export-%d.json" % OS.get_process_id()
	await new_screen(path)
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var first: Dictionary = screen.preset_library.create("Aliado #1", screen.model.preset_payload("ally"))["preset"]
	var second: Dictionary = screen.preset_library.create("Aliado #2", recipe)["preset"]
	screen._rebuild_preset_lists()
	screen._refresh_preset_controls()
	choose_preset("ally", second["id"])
	expect(screen.weapon_picker.item_count == 6 and screen.armor_picker.item_count == 6, "Seis opções em cada seletor do segundo aliado")
	for i in range(6):
		expect(screen.weapon_picker.get_item_metadata(i) == ScaleTests.BOW_IDS[i] and screen.armor_picker.get_item_metadata(i) == ScaleTests.TRAJE_IDS[i], "Menus mantêm ordem dos estágios")
		choose_id(screen.weapon_picker, screen.model.data["weapons"], ScaleTests.BOW_IDS[i])
		choose_id(screen.armor_picker, screen.model.data["armors"], ScaleTests.TRAJE_IDS[i])
		expect(screen.weapon_bonus.value == ScaleTests.ATTACK[i] and screen.armor_bonus.value == ScaleTests.DEFENSE[i] and screen.armor_evasion_bonus.value == 5, "Seleção atualiza os três bônus exibidos")
		expect(screen.weapon_chance.value == 12 and is_equal_approx(screen.weapon_multiplier.value, 1.6) and "19.00%" in screen.chance_label.text, "Crítico permanece12%/1,6×, total19%")
		expect(screen.profile_edits["attacker"]["physical_attack"].value == 20 and screen.profile_edits["attacker"]["physical_defense"].value == 30 and "EVA: 7 + 5 = 12%" in screen.composition_labels["attacker"].text, "Próprios intactos e EVA não acumula ao trocar traje")
		if i == 0 or i == 5:
			screen.armor_evasion_bonus.grab_focus()
			await process_frame
			await process_frame
			await process_frame
			await capture("stage-%d-equipment" % (i + 1))
	# Teclado usa os mesmos índices filtrados; não confunde catálogo global com menu.
	screen.weapon_picker.grab_focus()
	key(KEY_LEFT)
	expect(screen.model.weapon["id"] == "bow_ancient" and screen.weapon_bonus.value == 44, "Teclado percorre estágios do arco")
	key(KEY_RIGHT)
	expect(screen.model.weapon["id"] == "bow_runic" and screen.weapon_bonus.value == 58, "Teclado retorna ao último estágio")
	var saved = save_preset("ally", "Equipamento superior")
	expect(not saved.is_empty(), "Salva preset com arco e traje superiores")
	choose_preset("ally", first["id"])
	for id in ScaleTests.BOW_IDS:
		expect(not has_equipment(screen.weapon_picker, id), "Primeiro aliado não vê nenhum arco novo")
	for id in ScaleTests.TRAJE_IDS:
		expect(not has_equipment(screen.armor_picker, id), "Primeiro aliado não vê nenhum traje novo")
	expect(screen.weapon_picker.item_count == 6 and screen.armor_picker.item_count == 6, "Primeiro mantém seis espadas e seis armaduras")
	choose_preset("ally", saved)
	expect(screen.model.weapon["id"] == "bow_runic" and screen.model.armor["id"] == "leather_runic" and screen.weapon_bonus.value == 58 and screen.armor_bonus.value == 33, "Carga recupera os últimos estágios sem confundir índices")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.configuration()["target"]["physical_defense"] == 63 and screen.model.configuration()["target"]["evasion_base"] == 12, "Troca de lados mantém traje e total correto no alvo")
	key(KEY_F7)
	expect(screen.last_result.get("error", "inválido").is_empty(), "Lote executa com equipamento superior")
	screen._request_export()
	screen._save_export(export_path)
	var report = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["conditions"]["equipment"]["target"]["weapon"]["id"] == "bow_runic" and report["conditions"]["equipment"]["target"]["armor"]["id"] == "leather_runic" and report["conditions"]["target"]["physical_defense"] == 63, "JSON contém equipamento superior e total do aliado alvo")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally", saved)
	expect(screen.weapon_picker.get_item_metadata(screen.weapon_picker.selected) == "bow_runic" and screen.armor_picker.get_item_metadata(screen.armor_picker.selected) == "leather_runic", "Reabertura preserva seleção por IDs")
	expect(screen.model.configuration()["attacker"]["ranged_attack"] == 78 and screen.model.configuration()["attacker"]["physical_defense"] == 63 and screen.model.configuration()["attacker"]["evasion_base"] == 12, "Reabertura recalcula78/63/EVA12 sem duplicar bônus")
	screen.armor_evasion_bonus.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	await capture("stage-6-reopened")
	choose_preset("ally", second["id"])
	expect(screen.model.weapon["id"] == "compound_bow" and screen.model.armor["id"] == "leather_set" and screen.model.configuration()["attacker"]["ranged_attack"] == 30 and screen.model.configuration()["attacker"]["physical_defense"] == 35, "Preset inicial não é substituído pelo superior")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("ESCALAS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
