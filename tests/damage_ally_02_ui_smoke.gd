extends "res://tests/damage_presets_ui_smoke.gd"

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var path = "/private/tmp/rpg-ally02-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-ally02-ui-export-%d.json" % OS.get_process_id()
	await new_screen(path)
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var saved: Dictionary = screen.preset_library.create(payload["name"], payload)
	expect(saved["error"].is_empty(), "Cria preset temporário usando a mesma definição instalada")
	var id: String = saved["preset"]["id"]
	screen._rebuild_preset_lists()
	screen._refresh_preset_controls()
	screen.preset_pickers["ally"].grab_focus()
	key(KEY_RIGHT)
	for stat in screen.profile_edits["attacker"]:
		expect(screen.profile_edits["attacker"][stat].value == payload["actor"][stat], "Carrega atributo próprio no editor: " + stat)
	expect(screen.model.weapon["id"] == "compound_bow" and screen.model.armor["id"] == "leather_set", "Seletores carregam arco composto e couro")
	expect(screen.weapon_chance.value == 12 and is_equal_approx(screen.weapon_multiplier.value, 1.6) and screen.armor_evasion_bonus.value == 5, "Editores exibem crítico 12%/1,6× e bônus EVA 5")
	expect("EVA: 7 + 5 = 12%" in screen.composition_labels["attacker"].text and "chance" not in screen.profile_labels["attacker"].text, "Ficha mostra EVA própria e composição total")
	expect("19.00%" in screen.chance_label.text, "Prévia soma CRI próprio e arco")
	await capture("ally02-loaded")
	screen.armor_evasion_bonus.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	await capture("ally02-equipment")
	# Mesmo com ajuste de equipamento, base da ficha e preset salvo não mudam.
	key(KEY_RIGHT)
	expect(screen.model.armor["evasion_bonus"] == 6 and screen.model.ally()["evasion_base"] == 7 and screen.model.configuration()["attacker"]["evasion_base"] == 13, "Teclado ajusta bônus separado da EVA base")
	screen._reload_preset("ally")
	expect(screen.armor_evasion_bonus.value == 5 and screen.model.configuration()["attacker"]["evasion_base"] == 12, "Recarregar restaura bônus 5 sem duplicar")
	screen.profile_edits["target"]["physical_defense"].value = 40
	screen.profile_edits["target"]["ranged_defense"].value = 40
	screen.profile_edits["target"]["physical_attack"].value = 24
	screen.profile_edits["target"]["hp"].value = 45
	key(KEY_F9)
	expect(screen.last_result["chance"] == 19 and screen.last_result["maximum"] <= 23, "Lote usa crítico 19% e multiplicador 1,6×")
	var historical: Dictionary = screen.last_result.duplicate(true)
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect("EVA: 7 + 5 = 12%" in screen.composition_labels["target"].text and screen.profile_edits["target"]["evasion_base"].value == 7, "Inversão mantém EVA do aliado alvo separada do bônus")
	key(KEY_F9)
	expect(screen.last_result["evasion_chance"] == 12 and screen.last_result["snapshot"]["target"]["physical_defense"] == 35, "Ataques inimigos usam EVA 12 e DEF F 35 do aliado")
	screen._request_export()
	screen._save_export(export_path)
	var report = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["conditions"]["base_stats"]["target"]["evasion_base"] == 7 and report["conditions"]["target"]["evasion_base"] == 12 and report["conditions"]["equipment"]["target"]["armor"]["evasion_bonus"] == 5, "Interface exporta EVA própria, bônus e efetiva corretamente")
	screen.result_tabs.current_tab = 2
	screen.profile_edits["target"]["evasion_base"].grab_focus()
	await process_frame
	await capture("ally02-target-conditions")
	expect(not screen.model.choose_equipment("armor", "none").is_empty(), "Não permite remover armadura")
	expect(screen.armor_evasion_bonus.editable and screen.armor_evasion_bonus.value == 5 and screen.model.configuration()["target"]["evasion_base"] == 12, "Couro permanece equipado com bônus separado da base")
	choose_id(screen.armor_picker, screen.model.data["armors"], "leather_set")
	screen.armor_evasion_bonus.value = 8
	screen._update_preset("ally")
	var revision: int = screen.model.selected_presets["ally"]["revision"]
	expect(revision == 2 and historical["snapshot"]["attacker"]["evasion_base"] == 12, "Atualizar bônus mantém histórico anterior intacto")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally", id)
	expect(screen.armor_evasion_bonus.value == 8 and screen.profile_edits["attacker"]["evasion_base"].value == 7 and screen.model.configuration()["attacker"]["evasion_base"] == 15, "Reabertura restaura bônus editado e base independente")
	expect(is_equal_approx(screen.weapon_multiplier.value, 1.6) and screen.model.selected_presets["ally"]["revision"] == 2, "Reabertura preserva multiplicador e revisão")
	screen.profile_edits["attacker"]["evasion_base"].value = 99
	expect("107% → 100%" in screen.composition_labels["attacker"].text, "UI mostra soma bruta e limite de EVA")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("ALIADO #2/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
