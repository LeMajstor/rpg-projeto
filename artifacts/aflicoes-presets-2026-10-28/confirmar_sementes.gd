extends SceneTree
const Calculator = preload("res://artifacts/damage-lab-defm/calculator_v1.gd")
const DIRECTORY = "res://artifacts/aflicoes-presets-2026-10-28"
const SEEDS = [733,112,2026,31415]
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var execution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY.path_join("execucao.json")))
	var rows: Array = []
	for base in execution["rows"]:
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY.path_join(base["report"])))
		var config: Dictionary = report["conditions"]
		for seed_value in SEEDS:
			var result = Calculator.run_batch(config,1000,seed_value)
			check(result.get("error","").is_empty(),"Executa confirmação independente")
			if not result.get("error","").is_empty(): continue
			check(result["applied_count"]+result["resisted_count"]+result["evasion_count"] == 1000,"Contagens completas")
			for sample in result["samples"]:
				check(sample["damage"] == 0 and sample["hp_removed"] == 0 and sample["hp_before"] == sample["hp_after"] and sample["mp_before"]-sample["mp_after"] == 4 and not sample["critical"],"Recorte e recursos corretos")
				var magic = float(config["attacker"]["magic_power"])
				var resistance = float(config["target"][config["action"]["resistance_stat"]])
				var chance = magic/(magic+resistance)
				var evaded = sample["evasion_roll"] < config["target"]["evasion_base"]/100.0
				var applied = not evaded and sample["affliction"]["roll"] < chance
				check(sample["evaded"] == evaded and sample["affliction"]["applied"] == applied and sample["affliction"]["resisted"] == (not evaded and not applied),"Conferência independente de cada sorteio e fórmula")
			rows.append({"case_index":base["index"],"attacker":base["attacker"],"target":base["target"],"action_id":base["action_id"],"seed":seed_value,"count":1000,"applied_count":result["applied_count"],"resisted_count":result["resisted_count"],"evasion_count":result["evasion_count"],"application_chance":result["application_chance"],"total_application_chance":result["total_application_chance"],"samples_sha256":JSON.stringify(result["samples"]).sha256_text(),"rng_before":result["rng_before"],"rng_after":result["rng_after"]})
	var file = FileAccess.open(DIRECTORY.path_join("confirmacao.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"seeds":SEEDS,"rows":rows,"checks":checks,"failures":failures},"\t",false,true)+"\n")
	file.close()
	print("CONFIRMAÇÃO: ",rows.size()," lotes e ",rows.size()*1000," tentativas; ",checks," verificações, ",failures," falhas")
	quit(0 if failures == 0 else 1)
