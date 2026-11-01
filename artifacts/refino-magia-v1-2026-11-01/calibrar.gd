extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const DIR = "res://artifacts/refino-magia-v1-2026-11-01"
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var library = Library.new(data)
	check(library.load_error.is_empty(),"Biblioteca válida")
	var mages = library.custom.filter(func(p): return p["side"] == "ally" and p["actor"].get("character_id") == "ally_3")
	var monsters = library.custom.filter(func(p): return p["side"] == "enemy" and p["name"] in ["Monstro #1","Monstro #2 — Distância"])
	check(mages.size() == 1 and monsters.size() == 2,"Um mago e dois inimigos")
	if failures:
		quit(1)
		return
	var rows: Array = []
	for variant in [{"id":"A","power":1.5,"mp":7},{"id":"B","power":1.2,"mp":6}]:
		for monster in monsters:
			for seed_value in [421,733,112,2026,31415]:
				var model = Model.new(data)
				check(model.apply_preset(mages[0]).is_empty() and model.apply_preset(monster).is_empty(),"Carrega sem alterar presets")
				check(model.choose_action("magic_skill").is_empty(),"Mago atacante com magia")
				model.action["power"] = variant["power"]
				model.action["mp_cost"] = variant["mp"]
				model.action["evasion_allowed"] = false
				model.set_seed(seed_value)
				model.restart_sequence()
				var result = model.run(1000)
				check(result.get("error","").is_empty(),"Lote válido")
				if not result.get("error","").is_empty(): continue
				for sample in result["samples"]:
					check(not sample["critical"] and not sample["evaded"] and sample["mp_before"]-sample["mp_after"] == variant["mp"],"Sem crítico/EVA e custo correto")
					check(sample["damage"] < model.enemy()["hp"] and sample["damage"]*2 >= model.enemy()["hp"],"Um uso não vence; dois usos garantem vitória nesta referência")
				model.restart_sequence()
				check(model.run(1000)["samples"] == result["samples"],"Reprodução da semente")
				var name: String = "%s-%s-seed-%d.json" % [variant["id"],monster["actor"]["id"],seed_value]
				if seed_value == 421:
					check(Export.save(DIR.path_join(name),result)["error"].is_empty(),"Amostras primárias completas")
				rows.append({"variant":variant,"enemy":monster["name"],"seed":seed_value,"count":1000,"minimum":result["minimum"],"maximum":result["maximum"],"mean":result["mean"],"total":result["total"],"conditions":result["snapshot"],"report":name if seed_value==421 else "","samples_sha256":JSON.stringify(result["samples"]).sha256_text(),"rng_before":Export._rng_text(result["rng_before"]),"rng_after":Export._rng_text(result["rng_after"])})
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original,"Presets preservados integralmente")
	var file = FileAccess.open(DIR.path_join("calibracao.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"checks":checks,"failures":failures,"presets_sha256":original.sha256_text(),"presets_unchanged":FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original},"\t",false,true)+"\n")
	print("CALIBRAÇÃO MAGIA: ",rows.size()*1000," tentativas; ",checks," verificações, ",failures," falhas")
	quit(0 if failures==0 else 1)
