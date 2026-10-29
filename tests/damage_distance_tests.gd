extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	recipe.merge({"id": "user_2", "revision": 1})
	var model = Model.new(data)
	model.ally()["physical_attack"] = 23
	model.ally()["physical_defense"] = 45
	model.ally()["ranged_defense"] = 45
	model.ally()["hp"] = 40
	model.ally()["evasion_base"] = 5
	model.enemy()["physical_defense"] = 40
	model.enemy()["ranged_defense"] = 40
	model.enemy()["physical_attack"] = 24
	model.enemy()["ranged_attack"] = 24
	model.enemy()["hp"] = 45
	model.enemy()["evasion_base"] = 3
	var first = model.preset_payload("ally")
	first.merge({"id": "user_1", "name": "Aliado #1", "revision": 2})
	var config = model.configuration()
	expect(config["attacker"]["physical_attack"] == 33 and config["attacker"]["ranged_attack"] == 10, "Espada aumenta somente ATQ F; ATQ D próprio do primeiro é10")
	expect(config["attacker"]["physical_defense"] == 55 and config["attacker"]["ranged_defense"] == 50, "Metal inicial compõe55 DEF F/50 DEF D")
	expect(Calculator.damage_stats(config)["attack_stat"] == "physical_attack" and Calculator.damage_stats(config)["defense_stat"] == "physical_defense", "Espada usa contato automaticamente")
	config["settings"]["critical_mode"] = "off"
	expect(Calculator.sample(config,0,0,1)["damage"] == 13 and Calculator.sample(config,1,0,1)["damage"] == 16, "Primeiro preserva dano normal13–16")
	config["attacker"]["ranged_attack"] = 999
	config["target"]["ranged_defense"] = 9999
	expect(Calculator.sample(config,0,0,1)["damage"] == 13, "Contato ignora ATQ D/DEF D")
	expect(model.apply_preset(recipe).is_empty(), "Carrega segundo aliado com novos atributos")
	config = model.configuration()
	expect(config["attacker"]["physical_attack"] == 20 and config["attacker"]["ranged_attack"] == 30, "Arco aumenta somente ATQ D, preservando ATQ F próprio")
	expect(config["attacker"]["physical_defense"] == 35 and config["attacker"]["ranged_defense"] == 40 and config["attacker"]["evasion_base"] == 12, "Traje inicial compõe35/40/EVA12")
	expect(config["damage_stats"]["attack_stat"] == "ranged_attack" and config["damage_stats"]["defense_stat"] == "ranged_defense", "Arco usa ATQ D/DEF D automaticamente")
	config["settings"]["critical_mode"] = "off"
	expect(Calculator.sample(config,0,0,1)["damage"] == 12 and Calculator.sample(config,1,0,1)["damage"] == 14, "Arco preserva normal12–14")
	config["settings"]["critical_mode"] = "forced"
	expect(Calculator.sample(config,0,0,1)["damage"] == 19 and Calculator.sample(config,1,0,1)["damage"] == 23, "Arco preserva crítico19–23")
	config["attacker"]["physical_attack"] = 999
	config["target"]["physical_defense"] = 9999
	expect(Calculator.sample(config,0,0,1)["damage"] == 19, "Disparo ignora ATQ F/DEF F")
	config["target"]["ranged_defense"] = 0
	expect(Calculator.sample(config,0,0,1)["damage"] > 19, "Disparo responde à DEF D correta")
	config["action"]["damage_type"] = "magical"
	config["action"]["physical_mode"] = "ranged"
	expect(Calculator.damage_stats(config)["mode"] == "magical", "Magia permanece MAG/DEF M, mesmo com modo físico distância")
	var magic = Calculator.sample(config,.5,.5,1)["damage"]
	config["attacker"]["ranged_attack"] = 1
	config["target"]["ranged_defense"] = 9999
	expect(Calculator.sample(config,.5,.5,1)["damage"] == magic, "ATQ D/DEF D não alteram magia")
	model.swap_roles()
	config = model.configuration()
	expect(config["damage_stats"]["mode"] == "melee", "Monstro padrão continua em contato")
	config["settings"]["critical_mode"] = "off"
	expect(Calculator.sample(config,0,0,1)["damage"] == 9 and Calculator.sample(config,1,0,1)["damage"] == 11, "Dano de contato recebido pelo segundo preservado")
	model.action["physical_mode"] = "ranged"
	config = model.configuration()
	config["settings"]["critical_mode"] = "off"
	expect(config["damage_stats"]["attack_stat"] == "ranged_attack" and not config.has("weapon"), "Monstro pode testar disparos sem equipamentos")
	expect(Calculator.sample(config,0,0,1)["damage"] == 8 and Calculator.sample(config,1,0,1)["damage"] == 10, "Disparo inimigo usa DEF D40 do segundo")
	var rng = model.rng_state.duplicate()
	model.armor["ranged_defense_bonus"] = 17
	expect(model.configuration()["target"]["ranged_defense"] == 47 and model.configuration()["target"]["physical_defense"] == 35 and model.rng_state == rng, "Editor DEF D não altera DEF F nem sorteios")
	for side in ["ally", "enemy"]:
		for stat in ["ranged_attack", "ranged_defense"]:
			var role = model.ally_role() if side == "ally" else ("attacker" if model.ally_role() == "target" else "target")
			for invalid in [-1, 1000 if side == "ally" else 10000, .5, INF, NAN]:
				config = model.configuration()
				config[role][stat] = invalid
				expect(not Calculator.validate(config).is_empty(), "Novos atributos rejeitam valor fora da faixa")
	for invalid in [-1,1000,.5,INF,NAN]:
		config = model.configuration()
		config["equipment"]["target"]["armor"]["ranged_defense_bonus"] = invalid
		expect(not Calculator.validate(config).is_empty(), "Bônus DEF D inválido recusado")
	for index in range(6):
		var metal: Dictionary = data["armors"][index]
		var leather: Dictionary = data["armors"][index + 6]
		expect(metal["ranged_defense_bonus"] == [5,8,12,17,24,33][index] and metal["defense_bonus"] > metal["ranged_defense_bonus"], "Todo estágio de metal prioriza DEF F")
		expect(leather["ranged_defense_bonus"] == [10,16,24,34,48,65][index] and leather["ranged_defense_bonus"] > leather["defense_bonus"], "Todo estágio de traje prioriza DEF D")
	config = model.configuration()
	config["equipment"]["target"]["weapon"]["attack_mode"] = "melee"
	expect(not Calculator.validate(config).is_empty(), "Arma não pode falsificar sua modalidade canônica")
	for attack in [0,1,99,999]:
		config = model.configuration()
		config["attacker"]["ranged_attack"] = attack
		config["target"]["ranged_defense"] = 0
		var extreme = Calculator.sample(config,0,0,1)
		expect(is_finite(extreme["raw"]) and extreme["damage"] >= 1, "Disparos tratam0/0 e mínimos sem erro")
	var path = "/private/tmp/rpg-distance-%d.json" % OS.get_process_id()
	var library = Library.new(data,path)
	var saved = library.create("Distância personalizada",model.preset_payload("ally"))
	expect(saved["error"].is_empty(), "Salva novos atributos e bônus")
	var reopened = Library.new(data,path)
	expect(model.apply_preset(reopened.get_entry(saved["preset"]["id"])).is_empty() and model.armor["ranged_defense_bonus"] == 17, "Reabre preservando DEF D editada")
	var historical = model.run(1000)
	var document = Export.document(historical)
	expect(document["version"] == 5 and document["conditions"]["damage_stats"]["mode"] == "ranged" and document["formula"].has("ranged"), "JSON v5 explica a fonte selecionada e fórmula de disparo")
	expect(document["samples"][0]["base"]["defense_stat"] == "ranged_defense" and document["conditions"]["target"]["ranged_defense"] == 47, "Cada amostra identifica o par de atributos efetivo")
	model.armor["ranged_defense_bonus"] = 0
	expect(historical["snapshot"]["target"]["ranged_defense"] == 47, "Histórico não muda após editar defesa nova")
	# Leitura de biblioteca legada sem novos campos, sem regravar ou perder números antigos.
	var legacy = recipe.duplicate(true)
	legacy["actor"].erase("ranged_attack")
	legacy["actor"].erase("ranged_defense")
	legacy["equipment"]["weapon"].erase("attack_mode")
	legacy["equipment"]["armor"].erase("ranged_defense_bonus")
	legacy["actor"]["physical_attack"] = 21
	var before_legacy = legacy.duplicate(true)
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":Library.FORMAT,"version":Library.VERSION,"presets":[legacy]}))
	file.close()
	var original_file = FileAccess.get_file_as_string(path)
	reopened = Library.new(data,path)
	expect(reopened.load_error.is_empty() and model.apply_preset(reopened.custom[0]).is_empty(), "Lê preset antigo sem campos novos")
	expect(model.ally()["ranged_attack"] == 21 and model.ally()["ranged_defense"] == 30 and model.armor["ranged_defense_bonus"] == 10, "Compatibilidade usa antigo ataque do arqueiro e DEF própria existente")
	expect(legacy == before_legacy and FileAccess.get_file_as_string(path) == original_file, "Compatibilidade não modifica entrada ou arquivo")
	var old_first = first.duplicate(true)
	old_first["actor"].erase("ranged_attack")
	old_first["actor"].erase("ranged_defense")
	expect(model.apply_preset(old_first).is_empty() and model.ally()["ranged_attack"] == 10 and model.ally()["ranged_defense"] == 45, "Primeiro legado recebe ATQ D10 e DEF D45")
	model.ally()["ranged_defense"] = 999
	model.armor["ranged_defense_bonus"] = 33
	config = model.configuration()
	expect(config["target"]["ranged_defense"] == 999 and config["composition"]["target"]["raw_total"]["ranged_defense"] == 1032, "Limite preserva soma bruta de DEF D")
	model.action["physical_mode"] = "invalid"
	var before_rng = model.rng_state.duplicate()
	expect(not model.run(1)["error"].is_empty() and model.rng_state == before_rng, "Modalidade inválida falha antes dos sorteios")
	DirAccess.remove_absolute(path)
	print("DISTÂNCIA: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
