extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var library = Library.new(data,"res://artifacts/damage-lab-enemy02/presets-staged.json")
	var model = Model.new(data)
	for entry in library.custom:
		if entry["actor"].get("character_id") == "ally_3" or entry["name"] == "Monstro #1":
			expect(model.apply_preset(entry).is_empty(),"Reabre referências sem alterar presets")
	expect(model.choose_action("magic_skill").is_empty(),"Seleciona magia ofensiva básica")
	var config = model.configuration()
	expect(config["action"]["name"] == "Magia ofensiva básica" and config["action"]["power"] == 1.5 and config["action"]["mp_cost"] == 7,"Referência numérica escolhida")
	expect(config["ruleset"]["id"] == "damage_lab_v1" and config["action"]["reference_status"] == "v1_reference","Snapshot identifica V1 e ação de referência")
	expect(config["attacker"]["magic_power"] == 40 and config["target"]["magic_defense"] == 28,"Atributos efetivos de referência preservados")
	expect(Calculator.sample(config,0,0,0)["damage"] == 32 and Calculator.sample(config,1,0,0)["damage"] == 39,"Extremos aprovados32–39")
	model.enemy()["evasion_base"] = 100
	model.action["evasion_allowed"] = true
	model.action["critical_allowed"] = true
	model.settings["critical_mode"] = "forced"
	config = model.configuration()
	expect(not config["action"]["evasion_allowed"] and not config["action"]["critical_allowed"],"Configuração normaliza sinais antigos")
	config["action"]["evasion_allowed"] = true
	config["action"]["critical_allowed"] = true
	var sample = Calculator.sample(config,0,0,0)
	expect(not sample["evaded"] and not sample["critical"] and sample["damage"] == 32 and sample["mp_after"] == 17,"Calculadora também impede EVA/crítico forjados")
	model.restart_sequence()
	var result = model.run(1000)
	expect(result["error"].is_empty() and result["evasion_count"] == 0 and result["critical_count"] == 0,"Lote mantém regra mesmo contra EVA100")
	for s in result["samples"]:
		expect(s["mp_before"]-s["mp_after"] == 7 and s["damage"] >= 32 and s["damage"] <= 39,"Custo/faixa por amostra")
	var report = Export.document(result)
	expect(report["conditions"]["ruleset"]["decision"] == "D124" and report["formula"]["status"] == "approved_initial" and report["formula"]["action_reference_status"] == "v1_reference","JSON distingue referência aprovada e parâmetros efetivos")
	var historical = result.duplicate(true)
	var rng = model.rng_state.duplicate()
	model.ally()["mp"] = 6
	expect(not model.run(1)["error"].is_empty() and model.rng_state == rng and model.history.back() == historical,"MP insuficiente bloqueia sem consumir RNG/histórico")
	model.ally()["mp"] = 24
	model.ally()["magic_power"] = 0
	model.weapon["magic_attack_bonus"] = 0
	config = model.configuration()
	expect(Calculator.sample(config,0,0,0)["damage"] == 1,"Mínimo1 num acerto mágico com ofensiva0")
	for id in ["poison","slow","confusion","fear"]:
		model.choose_action(id)
		config = model.configuration()
		var evade = Calculator.sample(config,0,0,0,0)
		expect(evade["evaded"] and not evade["affliction"]["tested"] and evade["damage"] == 0 and evade["mp_before"]-evade["mp_after"] == 4,"Aflição conserva EVA anterior e custo4MP: "+id)
	model.choose_action("basic")
	config = model.configuration()
	config["target"]["evasion_base"] = 0
	config["attacker"]["physical_attack"] = 5
	config["target"]["physical_defense"] = 5
	config["settings"]["critical_mode"] = "off"
	config["settings"]["variation_enabled"] = false
	expect(Calculator.sample(config,0,0,1)["damage"] == 3,"Arredondamento2,5→3 após multiplicadores")
	config["target"]["evasion_base"] = 100
	expect(Calculator.sample(config,0,0,0)["damage"] == 0,"Esquiva física preserva zero, sem mínimo1")
	expect(model.definition("actions","physical_skill")["reference_status"] == "experimental","Técnica genérica permanece experimento explícito")
	print("REFERÊNCIA V1: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
