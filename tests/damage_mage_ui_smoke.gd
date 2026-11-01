extends "res://tests/damage_affliction_ui_smoke.gd"

func _run() -> void:
	root.size = Vector2i(1440,960)
	var path = "/private/tmp/rpg-mage-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-mage-ui-export-%d.json" % OS.get_process_id()
	var source = FileAccess.get_file_as_string("res://artifacts/damage-lab-staff-critical/presets-staged.json")
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(source)
	file.close()
	await new_screen(path)
	var mage_id = ""
	var enemy_id = ""
	var first_id = ""
	for entry in screen.preset_library.custom:
		if entry["actor"].get("character_id") == "ally_3": mage_id = entry["id"]
		elif entry["actor"].get("character_id") == "ally_1": first_id = entry["id"]
		if entry["side"] == "enemy": enemy_id = entry["id"]
	expect(not mage_id.is_empty(), "Mago aparece na biblioteca")
	choose_preset("ally",mage_id)
	choose_preset("enemy",enemy_id)
	var initial_revision = screen.model.selected_presets["ally"]["revision"]
	expect(screen.weapon_multiplier.value == 1.5 and screen.model.weapon["critical_chance"] == 0, "Preset carrega cajado1,5× sem bônus de chance")
	expect(screen.profile_edits["attacker"]["magic_power"].value == 30 and screen.profile_edits["attacker"]["magic_defense"].value == 30 and screen.profile_edits["attacker"]["physical_defense"].value == 16, "Editor mostra atributos naturais")
	expect(screen.weapon_magic_bonus.value == 10 and screen.armor_magic_bonus.value == 10 and screen.weapon_magic_bonus.editable and screen.armor_magic_bonus.editable, "Bônus mágicos editáveis e separados")
	expect("MAG: 30 + 10 = 40" in screen.composition_labels["attacker"].text and "DEF M: 30 + 10 = 40" in screen.composition_labels["attacker"].text, "Composição mágica visível")
	expect(screen.weapon_picker.item_count == 6 and screen.armor_picker.item_count == 6, "Seletores contêm seis cajados/seis vestes")
	screen.profile_edits["attacker"]["magic_power"].grab_focus()
	await capture("mage-own-stats")
	choose_id(screen.weapon_picker,screen.model.data["weapons"],"staff_runic")
	choose_id(screen.armor_picker,screen.model.data["armors"],"robe_runic")
	expect(screen.weapon_multiplier.value == 1.5 and screen.model.configuration()["attacker"]["magic_power"] == 95 and screen.model.configuration()["attacker"]["magic_defense"] == 95 and screen.model.configuration()["attacker"]["physical_defense"] == 29, "Seleção do último estágio recalcula totais")
	choose_id(screen.weapon_picker,screen.model.data["weapons"],"staff_wood")
	choose_id(screen.armor_picker,screen.model.data["armors"],"robe_simple")
	screen.weapon_magic_bonus.grab_focus()
	type_text("12")
	key(KEY_ENTER)
	screen.armor_magic_bonus.value = 14
	expect(screen.model.configuration()["attacker"]["magic_power"] == 42 and screen.model.configuration()["attacker"]["magic_defense"] == 44, "Digitação e edição recalculam bônus sem alterar próprios")
	screen._update_preset("ally")
	expect(screen.model.selected_presets["ally"]["revision"] == initial_revision+1, "Atualizar persiste bônus editados")
	screen.armor_magic_bonus.grab_focus()
	await process_frame
	await capture("mage-equipment")
	action_id("poison")
	key(KEY_F9)
	var historical: Dictionary = screen.last_result.duplicate(true)
	expect(historical["count"] == 1000 and historical["snapshot"]["attacker"]["magic_power"] == 42 and historical["critical_count"] == 0, "F9 usa MAG equipada e aflição sem crítico")
	expect("MAG 30 + 12 → 42" in screen.conditions.text and "DEF M 30 + 14 → 44" in screen.conditions.text, "Condições registram base/bônus/total")
	var rng: Dictionary = screen.model.rng_state.duplicate()
	screen._request_export()
	screen._save_export(export_path)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["conditions"]["equipment"]["attacker"]["weapon"]["magic_attack_bonus"] == 12 and report["conditions"]["base_stats"]["attacker"]["magic_power"] == 30 and report["conditions"]["attacker"]["magic_power"] == 42 and report["formula"].has("magical_stats"), "JSON contém bônus novos e fórmula de composição")
	expect(screen.last_result == historical and screen.model.rng_state == rng, "Exportar preserva resultado/RNG")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.configuration()["target"]["magic_defense"] == 44 and "DEF M 44 + VIG 15 = 59" in screen.chance_label.text, "Inversão usa DEF M equipada na resistência")
	action_id("magic_skill")
	key(KEY_F7)
	expect(screen.last_result["snapshot"]["target"]["magic_defense"] == 44 and screen.last_result["critical_count"] == 0, "Dano mágico recebido usa veste")
	screen.result_tabs.current_tab = 0
	screen.action_picker.grab_focus()
	await capture("mage-magic-summary")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally",mage_id)
	expect(screen.weapon_multiplier.value == 1.5 and screen.weapon_magic_bonus.value == 12 and screen.armor_magic_bonus.value == 14 and screen.profile_edits["attacker"]["magic_power"].value == 30, "Reabrir preserva bônus e base sem duplicação")
	choose_preset("ally",first_id)
	expect(not screen.weapon_magic_bonus.editable and not screen.armor_magic_bonus.editable and screen.weapon_magic_bonus.value == 0 and screen.armor_magic_bonus.value == 0, "Famílias legadas mantêm bônus mágicos zero e controles indisponíveis")
	expect(screen.model.configuration()["attacker"]["magic_power"] == 20 and screen.weapon_picker.item_count == 6, "Primeiro aliado preservado")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("MAGO/UI: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
