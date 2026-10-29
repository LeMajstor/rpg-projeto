extends "res://tests/damage_presets_ui_smoke.gd"

func action_id(id: String) -> void:
	for index in range(screen.model.data["actions"].size()):
		if screen.model.data["actions"][index]["id"] == id:
			choose(screen.action_picker,index)
			return
	expect(false,"Ação ausente: " + id)

func _run() -> void:
	root.size = Vector2i(1440,960)
	var path = "/private/tmp/rpg-affliction-ui-%d.json" % OS.get_process_id()
	var export_path = "/private/tmp/rpg-affliction-export-%d.json" % OS.get_process_id()
	await new_screen(path)
	for role in ["attacker","target"]:
		for stat in ["intelligence","vigor"]:
			expect(screen.profile_edits[role][stat].min_value == 1 and screen.profile_edits[role][stat].max_value == 999, "Campos INT/VIG em1..999 nos dois lados")
	screen.profile_edits["attacker"]["intelligence"].value = 20
	screen.profile_edits["attacker"]["vigor"].value = 25
	var first = save_preset("ally","Aliado #1")
	screen.profile_edits["attacker"]["magic_power"].value = 20
	screen.profile_edits["target"]["vigor"].value = 20
	screen.profile_edits["target"]["magic_defense"].value = 20
	screen.profile_edits["target"]["intelligence"].value = 15
	screen.profile_edits["target"]["evasion_base"].value = 25
	for id in ["poison","slow","confusion","fear"]:
		action_id(id)
		var stat = "vigor" if id in ["poison","slow"] else "intelligence"
		expect(screen.model.configuration()["damage_stats"]["defense_stat"] == stat and screen.evasion_allowed.button_pressed and screen.mp_cost_edit.value == 4, "Quatro magias escolhem resistência/EVA/custo corretos")
		expect(not screen.power_edit.editable and screen.critical_allowed.disabled and not screen.critical_allowed.button_pressed and screen.critical_mode.disabled and screen.variation_toggle.disabled, "Controles de dano/crítico/variação indisponíveis em aflições")
	action_id("poison")
	expect("33.33%" in screen.chance_label.text and "25.00%" in screen.chance_label.text and "DEF M 20 + VIG 20 = 40" in screen.chance_label.text and "Sem dano direto" in screen.chance_label.text, "Prévia distingue probabilidade condicional e total")
	key(KEY_F9)
	var historical: Dictionary = screen.last_result.duplicate(true)
	expect(historical["count"] == 1000 and historical["applied_count"] + historical["resisted_count"] + historical["evasion_count"] == 1000, "F9 calcula lote completo com três resultados")
	expect("Aplicou:" in screen.summary.text and "Resistiu:" in screen.summary.text and "Esquivou:" in screen.summary.text, "Resumo separa os três resultados")
	expect(screen.samples_tree.get_column_title(1) == "Resultado" and screen.samples_tree.get_root().get_child_count() == 1000, "Tabela específica mostra todas as tentativas")
	expect(screen.field.result.has("affliction") and screen.histogram.result["histogram"].size() == 3, "Duelo e gráfico recebem resultados de aplicação")
	expect("Teste: MAG 20 contra DEF M + VIG 40" in screen.conditions.text and "sem limites adicionais" in screen.conditions.text and "Dano 0" in screen.calculation.text, "Condições e cálculo explicam o teste real, sem dano")
	screen.result_tabs.current_tab = 0
	screen.action_picker.grab_focus()
	await process_frame
	await process_frame
	await capture("affliction-poison-summary")
	screen.result_tabs.current_tab = 1
	var first_row = screen.samples_tree.get_root().get_first_child()
	first_row.select(0)
	screen._select_sample()
	expect("Amostra #1" in screen.sample_detail.text, "Selecionar uma tentativa detalha o resultado correto")
	await capture("affliction-samples")
	var rng: Dictionary = screen.model.rng_state.duplicate()
	screen._request_export()
	screen._save_export(export_path)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(report["version"] == 5 and report["summary"]["applied_count"] == historical["applied_count"] and report["conditions"]["target"]["intelligence"] == 15 and report["run"]["rng_after"].has("affliction"), "UI exporta JSONv5 com INT/VIG, resultado e novo RNG")
	expect(screen.model.rng_state == rng and screen.last_result == historical, "Exportação não recalcula nem avança sorteios")
	screen.profile_edits["target"]["magic_defense"].value = 40
	expect("DEF M 40 + VIG 20 = 60" in screen.chance_label.text and screen.last_result == historical and screen.model.rng_state == rng, "Editar DEF M recalcula a prévia e preserva histórico/RNG")
	screen.profile_edits["target"]["vigor"].value = 999
	expect(historical["snapshot"]["target"]["vigor"] == 20 and screen.last_result == historical, "Editar resistência não modifica resultado antigo")
	action_id("basic")
	expect(screen.power_edit.editable and not screen.critical_allowed.disabled and not screen.critical_mode.disabled and not screen.variation_toggle.disabled, "Voltar ao físico restaura controles relevantes")
	key(KEY_F7)
	expect(screen.samples_tree.get_column_title(1) == "Dano" and screen.last_result["result_type"] == "damage" and not screen.last_result["samples"][0].has("affliction"), "Fluxo de dano anterior continua independente")
	choose(screen.history_picker,0)
	expect(screen.last_result == historical and screen.samples_tree.get_column_title(1) == "Resultado", "Histórico restaura apresentação e condições da aflição")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	action_id("fear")
	expect("INT" in screen.chance_label.text and screen.profile_edits["target"]["vigor"].value == 25, "Inversão mantém referências e escolhe INT do alvo correto")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	screen.profile_edits["target"]["evasion_base"].value = 100
	key(KEY_F6)
	expect(screen.busy and screen.last_result["evasion_count"] == 1, "Amostra única anima a esquiva")
	finish()
	expect(screen.last_result["samples"][0]["mp_before"] - screen.last_result["samples"][0]["mp_after"] == 4 and "Teste de resistência não realizado" in screen.calculation.text, "Esquiva consome4MP e encerra a tentativa")
	screen.result_tabs.current_tab = 0
	await capture("affliction-evaded")
	choose_preset("ally",first)
	expect(screen.model.ally()["intelligence"] == 20 and screen.model.ally()["vigor"] == 25, "Carregar preset mantém as resistências salvas")
	screen.profile_edits["attacker"]["intelligence"].grab_focus()
	type_text("37")
	key(KEY_ENTER)
	screen._update_preset("ally")
	screen.queue_free()
	await process_frame
	await new_screen(path)
	choose_preset("ally",first)
	expect(screen.profile_edits["attacker"]["intelligence"].value == 37 and screen.profile_edits["attacker"]["vigor"].value == 25, "Digitação/atualização/reabertura preservam INT/VIG")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(export_path)
	print("AFLIÇÕES/UI: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
