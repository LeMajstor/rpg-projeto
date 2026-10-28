extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const LARGE_STATS = ["hp", "mp", "physical_attack", "physical_defense", "ranged_attack", "ranged_defense", "magic_power", "magic_defense"]
var checks = 0
var failures = 0
var definitions: Dictionary

func _initialize() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	for attacking in [false, true]:
		var model = Model.new(definitions)
		if attacking:
			model.swap_roles()
		var role = "attacker" if attacking else "target"
		for stat in LARGE_STATS:
			var original = model.enemy()[stat]
			var cap = 99999 if stat == "hp" else 9999
			var endpoints = [1, 9999, 10000, 99999] if stat == "hp" else [1, 1000, 9999]
			for endpoint in endpoints:
				model.enemy()[stat] = endpoint
				var result = model.run(1)
				expect(result["error"].is_empty() and result["snapshot"][role][stat] == endpoint, "Monstro aceita faixa ampliada nos dois papéis: " + stat)
			for invalid in [0, -1, cap + 1, 1.5, INF, NAN]:
				model.enemy()[stat] = invalid
				var rng = model.rng_state.duplicate()
				var number = model.run_number
				expect(not model.run(1)["error"].is_empty() and model.rng_state == rng and model.run_number == number, "Fora da faixa é recusado sem sorteios/histórico: " + stat)
			model.enemy()[stat] = original
		for stat in ["ini", "critical_base"]:
			var original = model.enemy()[stat]
			model.enemy()[stat] = 99
			expect(model.run(1)["error"].is_empty(), "INI/CRI mantêm máximo 99")
			for invalid in [0, 100, 9999]:
				model.enemy()[stat] = invalid
				expect(not model.run(1)["error"].is_empty(), "INI/CRI não recebem a escala de chefes")
			model.enemy()[stat] = original
		var own_role = model.ally_role()
		for stat in LARGE_STATS:
			var config = model.configuration()
			config[own_role][stat] = 1000
			expect(not Calculator.validate(config).is_empty(), "Aliado continua limitado a 999: " + stat)
			config = model.configuration()
			config[own_role][stat] = 0
			expect(Calculator.validate(config).is_empty() if stat != "hp" else not Calculator.validate(config).is_empty(), "Zero continua permitido na ficha aliada; HP zero impede agir")
	var model = Model.new(definitions)
	model.attacker["physical_attack"] = 20
	for stat in LARGE_STATS:
		model.enemy()[stat] = 9999
	model.enemy()["hp"] = 99999
	var defender = model.run(1000)
	expect(defender["snapshot"]["target"]["physical_defense"] == 9999 and defender["snapshot"]["target"]["hp"] == 99999, "Monstro alvo não sofre limite de equipamento 999")
	expect(defender["minimum"] == 1 and defender["maximum"] == 1 and defender["samples"][0]["hp_after"] == 99998, "Defesa 9999 respeita dano mínimo e HP de cinco dígitos")
	model.swap_roles()
	model.action["damage_type"] = "magical"
	model.action["mp_cost"] = 999
	model.action["power"] = 10.0
	model.settings["variation_percent"] = 100.0
	model.settings["critical_mode"] = "forced"
	model.enemy()["unarmed_critical_multiplier"] = 10.0
	var attacker = model.run(1000)
	expect(attacker["error"].is_empty() and attacker["maximum"] > 9999 and is_finite(attacker["mean"]), "MAG 9999 com potência/variação/crítico extremos não limita dano a atributos")
	expect(attacker["snapshot"]["attacker"]["physical_attack"] == 9999 and not attacker["snapshot"].has("weapon"), "ATQ F 9999 é direto, sem arma ou cap de aliado")
	for sample in attacker["samples"]:
		expect(sample["mp_before"] == 9999 and sample["mp_after"] == 9000 and sample["hp_before"] == 999, "Recursos grandes são restaurados corretamente em cada amostra")
	var path = "/private/tmp/rpg-enemy-9999-%d.json" % OS.get_process_id()
	expect(Export.save(path, attacker)["error"].is_empty(), "Exporta lote com atributos grandes")
	var exported = JSON.parse_string(FileAccess.get_file_as_string(path))
	for stat in LARGE_STATS:
		expect(exported["conditions"]["attacker"][stat] == (99999 if stat == "hp" else 9999) and exported["formula"]["attribute_ranges"]["enemy"][stat] == [1.0, 99999.0 if stat == "hp" else 9999.0], "JSON preserva valores e documenta faixas por lado: " + stat)
	expect(exported["formula"]["attribute_ranges"]["ally"]["hp"] == [0.0, 999.0] and exported["formula"]["attribute_ranges"]["enemy"]["ini"] == [1.0, 99.0], "JSON distingue aliados de monstros e INI/CRI")
	DirAccess.remove_absolute(path)
	print("FAIXAS/MONSTROS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
