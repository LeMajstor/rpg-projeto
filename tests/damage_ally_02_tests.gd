extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var source = payload.duplicate(true)
	var path = "/private/tmp/rpg-ally02-presets-%d.json" % OS.get_process_id()
	var library = Library.new(data, path)
	var model = Model.new(data)
	var saved = library.create(payload["name"], payload)
	expect(saved["error"].is_empty(), "Salva Aliado #2 com arco/couro reais do catálogo")
	var reopened = Library.new(data, path).get_entry(saved["preset"]["id"])
	expect(model.apply_preset(reopened).is_empty(), "Carrega o preset de disco")
	for stat in Calculator.STATS:
		expect(model.ally()[stat] == payload["actor"][stat], "Preserva atributo próprio " + stat)
	expect(model.weapon["id"] == "compound_bow" and model.armor["id"] == "leather_set", "Equipamentos corretos, sem renomear espada/armadura")
	var config = model.configuration()
	expect(config["attacker"]["ranged_attack"] == 30 and config["attacker"]["physical_defense"] == 35, "ATQ/DEF efetivos 30/35")
	expect(config["base_stats"]["attacker"]["evasion_base"] == 7 and config["attacker"]["evasion_base"] == 12, "EVA própria 7 e efetiva 12 separadas")
	expect(config["composition"]["attacker"]["bonuses"]["evasion_base"] == 5 and config["composition"]["attacker"]["effective"]["evasion_base"] == 12, "Composição registra bônus do couro")
	expect(Calculator.critical_chance(config) == 19 and Calculator.critical_source(config)["multiplier"] == 1.6, "CRI 7 + arco 12 = 19%, multiplicador 1,6×")
	model.enemy()["hp"] = 45
	model.enemy()["physical_attack"] = 24
	model.enemy()["physical_defense"] = 40
	model.enemy()["ranged_defense"] = 40
	model.enemy()["evasion_base"] = 3
	model.settings["critical_mode"] = "off"
	config = model.configuration()
	expect(Calculator.sample(config, 0, 0, 1)["damage"] == 12 and Calculator.sample(config, 1, 0, 1)["damage"] == 14, "Dano normal nos extremos é 12–14")
	model.settings["critical_mode"] = "forced"
	config = model.configuration()
	expect(Calculator.sample(config, 0, 0, 1)["damage"] == 19 and Calculator.sample(config, 1, 0, 1)["damage"] == 23, "Crítico 1,6× nos extremos é 19–23")
	model.settings["critical_mode"] = "rolled"
	var first = model.run(1000)
	model.restart_sequence()
	expect(model.run(1000)["samples"] == first["samples"], "Preset reproduz os mesmos resultados por semente")
	model.swap_roles()
	model.settings["critical_mode"] = "off"
	config = model.configuration()
	expect(config["target"]["evasion_base"] == 12 and config["target"]["physical_defense"] == 35 and not config.has("weapon"), "Inversão mantém couro e esquiva no aliado alvo")
	expect(Calculator.evasion_chance(config) == 12 and Calculator.sample(config, 0, 0, .119)["evaded"] and not Calculator.sample(config, 0, 0, .12)["evaded"], "Sorteio usa EVA efetiva e fronteira de 12%")
	expect(Calculator.sample(config, 0, 0, 1)["damage"] == 9 and Calculator.sample(config, 1, 0, 1)["damage"] == 11, "Recebe 9–11 normalmente")
	var historical = model.run(1000)
	var report = Export.document(historical)
	expect(report["conditions"]["base_stats"]["target"]["evasion_base"] == 7 and report["conditions"]["equipment"]["target"]["armor"]["evasion_bonus"] == 5 and report["conditions"]["target"]["evasion_base"] == 12, "JSON conserva próprio, bônus e total")
	expect(report["formula"].has("evasion_stats") and report["summary"]["evasion_chance"] == 12, "Exportação descreve composição de esquiva")
	var rng = model.rng_state.duplicate()
	model.armor = model.definition("armors", "armor_bronze")
	expect(model.armor["id"] == "leather_set" and model.configuration()["target"]["evasion_base"] == 12 and model.ally()["evasion_base"] == 7, "Armadura de metal é recusada pelo segundo aliado")
	model.armor = model.definition("armors", "none")
	expect(model.configuration()["target"]["evasion_base"] == 12 and model.configuration()["target"]["physical_defense"] == 35, "Remoção recusada mantém couro e bônus")
	expect(model.rng_state == rng and historical["snapshot"]["target"]["evasion_base"] == 12, "Equipar não avança RNG nem muda histórico")
	model.apply_preset(reopened)
	model.ally()["evasion_base"] = 99
	config = model.configuration()
	expect(config["target"]["evasion_base"] == 100 and config["composition"]["target"]["raw_total"]["evasion_base"] == 104, "EVA efetiva limitada a 100, com soma bruta preservada")
	model.apply_preset(reopened)
	model.armor["evasion_bonus"] = 8
	var updated = library.update(reopened["id"], model.preset_payload("ally"))
	var loaded = Library.new(data, path).get_entry(reopened["id"])
	expect(updated["error"].is_empty() and loaded["equipment"]["armor"]["evasion_bonus"] == 8 and loaded["actor"]["evasion_base"] == 7, "Atualizar persiste bônus separado da base")
	model.apply_preset(loaded)
	expect(model.configuration()["target"]["evasion_base"] == 15, "Recarregar não duplica bônus de EVA")
	for invalid in [-1, 101, .5, INF, NAN]:
		var bad = reopened.duplicate(true)
		bad["equipment"]["armor"]["evasion_bonus"] = invalid
		var before = model.ally().duplicate(true)
		expect(not model.apply_preset(bad).is_empty() and model.ally() == before, "Preset rejeita bônus inválido sem carga parcial")
		config = model.configuration()
		config["equipment"]["target"]["armor"]["evasion_bonus"] = invalid
		expect(not Calculator.validate(config).is_empty(), "Calculadora rejeita bônus inválido antes de sortear")
	config = model.configuration()
	config["equipment"]["target"]["armor"] = {"id": "none", "equipped": false, "evasion_bonus": 1}
	expect(not Calculator.validate(config).is_empty(), "Calculadora recusa armadura ausente e bônus fictício")
	# Preset anterior sem o novo campo continua válido e não é regravado na leitura.
	var legacy = reopened.duplicate(true)
	legacy["equipment"]["armor"] = model.definition("armors", "leather_set")
	legacy["equipment"]["armor"].erase("evasion_bonus")
	var file = FileAccess.open(path, FileAccess.WRITE)
	var content = JSON.stringify({"format": Library.FORMAT, "version": Library.VERSION, "presets": [legacy]})
	file.store_string(content)
	file.close()
	var old = Library.new(data, path)
	expect(old.load_error.is_empty() and old.custom[0]["equipment"]["armor"]["evasion_bonus"] == 0 and FileAccess.get_file_as_string(path) == content, "Preset antigo recebe bônus zero em memória sem regravar")
	expect(model.apply_preset(legacy).is_empty() and model.configuration()["target"]["evasion_base"] == 7, "Carga direta de preset antigo funciona")
	expect(payload == source, "Operações não alteram a definição de Aliado #2")
	DirAccess.remove_absolute(path)
	print("ALIADO #2: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
