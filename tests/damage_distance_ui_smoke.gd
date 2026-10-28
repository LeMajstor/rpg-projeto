extends "res://tests/damage_presets_ui_smoke.gd"

func _run() -> void:
	root.size = Vector2i(1440,960)
	var path = "/private/tmp/rpg-distance-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-distance-export-%d.json" % OS.get_process_id()
	await new_screen(path)
	for stat in ["ranged_attack","ranged_defense"]:
		expect(screen.profile_edits["attacker"].has(stat) and screen.profile_edits["target"].has(stat), "Campos de distância presentes nas duas fichas")
	screen.profile_edits["attacker"]["physical_attack"].value = 23
	screen.profile_edits["attacker"]["physical_defense"].value = 45
	screen.profile_edits["attacker"]["ranged_defense"].value = 45
	screen.profile_edits["attacker"]["hp"].value = 40
	var first = save_preset("ally","Aliado #1")
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var second: Dictionary = screen.preset_library.create("Aliado #2",recipe)["preset"]
	screen._rebuild_preset_lists()
	screen._refresh_preset_controls()
	choose_preset("ally",first)
	expect(screen.model.configuration()["attacker"]["physical_defense"] == 55 and screen.model.configuration()["attacker"]["ranged_defense"] == 50 and screen.armor_ranged_bonus.value == 5, "Metal mostra as duas defesas e bônus DEF D")
	expect(screen.weapon_bonus.get_parent().get_child(0).text == "ATQ F +" and "ATQ F / DEF F" in screen.chance_label.text, "Espada mostra o atributo e a fonte de contato")
	screen.profile_edits["attacker"]["ranged_defense"].grab_focus()
	await process_frame
	await process_frame
	await process_frame
	await capture("first-defenses")
	choose_preset("ally",second["id"])
	for stat in ["physical_defense","ranged_defense"]:
		screen.profile_edits["target"][stat].value = 40
	screen.profile_edits["target"]["hp"].value = 45
	screen.profile_edits["target"]["physical_attack"].value = 24
	screen.profile_edits["target"]["ranged_attack"].value = 24
	expect(screen.model.configuration()["attacker"]["ranged_attack"] == 30 and screen.model.configuration()["attacker"]["physical_attack"] == 20, "Arco aumenta somente ATQ D na prévia")
	expect(screen.weapon_bonus.get_parent().get_child(0).text == "ATQ D +" and "ATQ D / DEF D" in screen.chance_label.text, "Arco mostra modalidade automática de disparo")
	expect("DEF D: 30 + 10 = 40" in screen.composition_labels["attacker"].text and screen.armor_bonus.value == 5 and screen.armor_ranged_bonus.value == 10, "Traje prioriza DEF D e composição informa40")
	screen.armor_ranged_bonus.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	await capture("bow-and-dual-armor")
	screen.profile_edits["attacker"]["ranged_attack"].grab_focus()
	type_text("24")
	key(KEY_ENTER)
	expect(screen.model.ally()["ranged_attack"] == 24 and screen.model.configuration()["attacker"]["ranged_attack"] == 34 and screen.model.ally()["physical_attack"] == 20, "Digitação edita ATQ D próprio sem alterar ATQ F")
	screen._reload_preset("ally")
	choose(screen.physical_mode_picker,1)
	expect(screen.model.configuration()["damage_stats"]["mode"] == "melee" and "ATQ F / DEF F" in screen.chance_label.text, "Override contato seleciona os atributos corretos")
	choose(screen.physical_mode_picker,2)
	expect(screen.model.configuration()["damage_stats"]["mode"] == "ranged", "Override distância seleciona disparo")
	choose(screen.action_picker,2)
	expect(screen.physical_mode_picker.disabled and "MAG / DEF M" in screen.chance_label.text, "Magia ignora modos físicos e desabilita seletor")
	key(KEY_F7)
	finish()
	expect(screen.physical_mode_picker.disabled, "Fim do lote mágico mantém seletor físico desabilitado")
	choose(screen.action_picker,0)
	expect(not screen.physical_mode_picker.disabled and screen.model.configuration()["damage_stats"]["mode"] == "ranged", "Volta ao ataque básico e modo automático do arco")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect("ATQ F / DEF F" in screen.chance_label.text, "Monstro padrão usa contato")
	choose(screen.physical_mode_picker,2)
	expect("ATQ D / DEF D" in screen.chance_label.text and screen.model.configuration()["target"]["ranged_defense"] == 40, "Pode testar disparos inimigos contra DEF D do aliado")
	screen.armor_ranged_bonus.value = 17
	expect(screen.model.configuration()["target"]["ranged_defense"] == 47 and screen.model.configuration()["target"]["physical_defense"] == 35, "Bônus DEF D editável independente do bônus DEF F")
	key(KEY_F7)
	finish()
	var historical = screen.last_result.duplicate(true)
	expect(historical["snapshot"]["damage_stats"]["mode"] == "ranged" and "Fonte de dano: ATQ D contra DEF D" in screen.conditions.text, "Histórico informa os atributos realmente usados")
	screen._request_export()
	screen._save_export(export_path)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["version"] == 4 and report["conditions"]["base_stats"]["target"]["ranged_defense"] == 30 and report["conditions"]["target"]["ranged_defense"] == 47 and report["samples"][0]["base"]["defense_stat"] == "ranged_defense", "UI exporta novos próprios, bônus, efetivos e par usado")
	var copy = save_preset("ally","Defesa à distância editada")
	screen.armor_ranged_bonus.value = 2
	expect(historical["snapshot"]["target"]["ranged_defense"] == 47, "Editar próxima defesa não muda resultado anterior")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally",copy)
	expect(screen.armor_ranged_bonus.value == 17 and screen.profile_edits["attacker"]["ranged_defense"].value == 30 and screen.model.configuration()["attacker"]["ranged_defense"] == 47, "Reabertura preserva base e bônus DEF D sem duplicação")
	screen.physical_mode_picker.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	await capture("ranged-source-picker")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("DISTÂNCIA/UI: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
