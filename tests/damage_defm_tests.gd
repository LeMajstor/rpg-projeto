extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const Legacy = preload("res://artifacts/damage-lab-defm/calculator_v1.gd")
const LegacyExport = preload("res://artifacts/damage-lab-defm/export_v1.gd")
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var model = Model.new(data)
	for action_id in ["poison","slow","confusion","fear"]:
		model.action = model.definition("actions",action_id)
		var config = model.configuration()
		var specific: String = config["action"]["resistance_stat"]
		config["attacker"]["magic_power"] = 100
		config["target"]["magic_defense"] = 40
		config["target"][specific] = 60
		check(Calculator.application_chance(config) == 50,"Soma DEF M40+resistência60 contra MAG100 dá50%")
		var sample = Calculator.sample(config,0,0,1,.49)
		check(sample["affliction"]["specific_resistance"] == 60 and sample["affliction"]["magic_defense"] == 40 and sample["affliction"]["combined_resistance"] == 100 and sample["affliction"]["resistance"] == 100,"Amostra decompõe a resistência sem confundir valores próprios")
		check(sample["base"]["defense"] == 100 and is_equal_approx(sample["base"]["ratio"],.5),"Base e chance usam o mesmo total")
		config["target"]["magic_defense"] = 80
		check(is_equal_approx(Calculator.application_chance(config),10000.0/240),"DEF M maior reduz chance, preservando resistência específica")
		config["target"]["magic_defense"] = 9999
		config["target"][specific] = 999
		config["attacker"]["magic_power"] = 1
		check(Calculator.validate(config).is_empty() and Calculator.application_resistance(config)["total"] == 10998 and Calculator.application_chance(config) < .01,"Soma não é limitada a999 e chance não recebe piso5%")
	# DEF M zero é um valor próprio válido no aliado; não há divisão por zero, pois VIG/INT>=1.
	model.swap_roles()
	model.action = model.definition("actions","poison")
	model.attacker["magic_power"] = 999
	model.target["magic_defense"] = 0
	model.target["vigor"] = 1
	var zero = model.configuration()
	check(Calculator.validate(zero).is_empty() and is_equal_approx(Calculator.application_chance(zero),99.9),"DEF M zero válida no aliado mantém curva pura acima95%")
	model.attacker["magic_power"] = 25
	model.attacker["mp"] = 8
	model.target["magic_defense"] = 21
	model.target["vigor"] = 25
	model.target["evasion_base"] = 5
	model.target["hp"] = 40
	model.set_seed(421)
	model.restart_sequence()
	var before = model.configuration()
	var result = model.run(1000)
	var old = Legacy.run_batch(before,1000,421)
	old["run_number"] = 1
	old["sequence_start"] = 0
	check(result["applied_count"] == 309 and result["resisted_count"] == 647 and result["evasion_count"] == 44,"Produção reproduz exatamente a rodada experimental aceita309/647/44")
	check(is_equal_approx(result["application_chance"],2500.0/71) and is_equal_approx(result["total_application_chance"],2375.0/71),"Chances aprovadas35,21% e33,45%")
	check(old["applied_count"] == 444 and old["resisted_count"] == 512 and old["evasion_count"] == 44,"Calculador histórico mantém o resultado anterior444/512/44")
	check(result["rng_before"] == old["rng_before"] and result["rng_after"] == old["rng_after"],"Mudança de fórmula não altera os quatro fluxos RNG")
	var changed = 0
	for i in range(1000):
		var a: Dictionary = old["samples"][i]
		var b: Dictionary = result["samples"][i]
		check(a["evasion_roll"] == b["evasion_roll"] and a["variation_roll"] == b["variation_roll"] and a["critical_roll"] == b["critical_roll"] and a["affliction"]["roll"] == b["affliction"]["roll"],"Sorteios exatos preservados por tentativa")
		if a["outcome"] != b["outcome"]:
			changed += 1
			check(a["outcome"] == "applied" and b["outcome"] == "resisted","Adicionar DEF M só converte aplicação em resistência")
	check(changed == 135,"135 aplicações convertidas em resistência")
	var report = Export.document(result)
	check(report["version"] == 5 and report["formula"]["id"] == "affliction_application_v2" and "magic_defense" in report["formula"]["affliction"],"JSONv5 identifica fórmula nova como aplicação_v2")
	check(report["samples"][0]["affliction"]["magic_defense"] == 21 and report["samples"][0]["affliction"]["specific_resistance"] == 25 and report["samples"][0]["affliction"]["combined_resistance"] == 46,"JSON preserva parcelas21+25=46")
	check(LegacyExport.document(old)["formula"]["id"] == "affliction_application_v1","Exportação histórica continua identificando fórmula anterior")
	model.target["magic_defense"] = 100
	check(result["snapshot"]["target"]["magic_defense"] == 21 and result["samples"][0]["affliction"]["combined_resistance"] == 46,"Editar DEF M não altera snapshot ou amostras anteriores")
	print("DEF M/AFLIÇÕES: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
