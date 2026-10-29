extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
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
	var raw: Dictionary = JSON.parse_string(original)
	var library = Library.new(data)
	check(library.load_error.is_empty(), "Reabre biblioteca pessoal")
	var model = Model.new(data)
	for entry in library.custom:
		check(model.apply_preset(entry).is_empty(), "Carrega preset pessoal")
		var actor: Dictionary = model.ally() if entry["side"] == "ally" else model.enemy()
		var expected = data["affliction_reference_stats"][actor.get("character_id", "enemy") if actor["side"] == "ally" else "enemy"]
		check(actor["intelligence"] == expected["intelligence"] and actor["vigor"] == expected["vigor"], "Novos valores de referência corretos")
		for old in raw["presets"]:
			if old["id"] != entry["id"]: continue
			for key in old["actor"]:
				check(entry["actor"][key] == old["actor"][key], "Preserva atributo anterior: " + key)
			check(entry["revision"] == old["revision"], "Preserva revisão ao ler")
		print(entry["name"], ": INT ", actor["intelligence"], "/VIG ", actor["vigor"], " · revisão ", entry["revision"])
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original, "Arquivo pessoal preservado integralmente")
	var samples = 0
	for name in DirAccess.get_files_at("res://exports/damage-lab"):
		if not name.ends_with(".json"): continue
		var path = "res://exports/damage-lab/" + name
		var text = FileAccess.get_file_as_string(path)
		var report: Dictionary = JSON.parse_string(text)
		var conditions: Dictionary = report["conditions"]
		model = Model.new(data)
		for role in ["attacker", "target"]:
			var actor: Dictionary = conditions["base_stats"][role]
			var preset = {"id":"report", "name":actor["name"], "side":actor["side"], "revision":1, "actor":actor}
			if actor["side"] == "ally": preset["equipment"] = conditions["equipment"][role]
			check(model.apply_preset(preset).is_empty(), "Carrega ficha da exportação anterior")
		if conditions["attacker"]["side"] == "enemy": model.swap_roles()
		model.action = conditions["action"].duplicate(true)
		model.settings = conditions["settings"].duplicate(true)
		var config = model.configuration()
		check(Calculator.validate(config).is_empty(), "Condições legadas válidas")
		for sample in report["samples"]:
			var calculated = Calculator.sample(config,sample["variation_roll"],sample["critical_roll"],sample["evasion_roll"])
			for key in ["damage","hp_removed","critical","evaded","hp_after","mp_after"]:
				check(calculated[key] == sample[key], "Reproduz dano anterior: " + name + "/" + key)
			samples += 1
		check(FileAccess.get_file_as_string(path) == text, "Arquivo anterior preservado")
	print("COMPATIBILIDADE/AFLIÇÕES: ", library.custom.size(), " presets e ", samples, " amostras; ", checks, " verificações, ", failures, " falhas")
	quit(0 if failures == 0 else 1)
