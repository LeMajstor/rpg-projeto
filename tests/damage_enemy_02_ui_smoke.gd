extends "res://tests/damage_affliction_ui_smoke.gd"
func _run() -> void:
	root.size = Vector2i(1440,960)
	var path = "/private/tmp/rpg-enemy02-ui-%d.json" % OS.get_process_id()
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string("res://artifacts/damage-lab-enemy02/presets-staged.json"))
	file.close()
	await new_screen(path)
	var new_id = ""
	var old_id = ""
	var ally_id = ""
	for entry in screen.preset_library.custom:
		if entry["actor"]["id"] == "enemy_ranged": new_id = entry["id"]
		if entry["name"] == "Monstro #1": old_id = entry["id"]
		if entry["name"] == "Aliado #1": ally_id = entry["id"]
	choose_preset("ally",ally_id)
	choose_preset("enemy",new_id)
	expect(screen.profile_edits["target"]["hp"].value == 40 and screen.profile_edits["target"]["ranged_defense"].value == 50 and screen.profile_edits["target"]["physical_defense"].value == 32,"Editor mostra atributos novos")
	action_id("magic_skill")
	expect(screen.model.action["id"] == "magic_skill","Pode testar magia recebida pelo novo monstro")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.action["id"] == "basic" and screen.physical_mode_picker.selected == 2 and screen.physical_mode_picker.disabled,"Novo atacante usa distância fixa")
	for index in range(screen.model.data["actions"].size()):
		expect(screen.action_picker.is_item_disabled(index) == (screen.model.data["actions"][index]["id"] != "basic"),"Repertório da UI contém somente básico físico")
	var rng = screen.model.rng_state.duplicate()
	action_id("poison")
	expect(screen.model.action["id"] == "basic" and screen.model.data["actions"][screen.action_picker.selected]["id"] == "basic" and screen.model.rng_state == rng,"Sinal direto de ação desabilitada também é recusado")
	screen.action_picker.grab_focus()
	var editor_scroll = screen.action_picker.get_parent()
	while not editor_scroll is ScrollContainer: editor_scroll = editor_scroll.get_parent()
	editor_scroll.ensure_control_visible(screen.physical_mode_picker)
	await process_frame
	await capture("enemy02-ranged-only")
	key(KEY_F9)
	expect(screen.last_result["snapshot"]["damage_stats"]["mode"] == "ranged" and screen.last_result["snapshot"]["target"]["physical_defense"] == 55 and screen.last_result["snapshot"]["target"]["ranged_defense"] == 50,"F9 usa DEF D distinta da DEF F")
	expect(screen.last_result["mean"] > 7.3 and screen.last_result["mean"] < 7.8,"Dano médio de distância esperado")
	await capture("enemy02-summary")
	var history: Dictionary = screen.last_result.duplicate(true)
	screen.profile_edits["attacker"]["hp"].value = 41
	screen._update_preset("enemy")
	expect(screen.model.selected_presets["enemy"]["revision"] == 2 and screen.last_result == history,"Atualizar preserva histórico")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("enemy",new_id)
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.enemy()["hp"] == 41 and screen.model.action["physical_mode"] == "ranged" and screen.physical_mode_picker.disabled,"Reabrir mantém dados e restrição")
	choose_preset("enemy",old_id)
	expect(not screen.physical_mode_picker.disabled,"Monstro #1 mantém override livre do laboratório")
	action_id("poison")
	expect(screen.model.action["id"] == "poison","Ferramenta legada de aflições preservada")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("MONSTRO #2/UI: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
