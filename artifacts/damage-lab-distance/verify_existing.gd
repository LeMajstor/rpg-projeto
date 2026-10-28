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
	var library = Library.new(data)
	check(library.load_error.is_empty(), library.load_error)
	var model = Model.new(data)
	for entry in library.custom:
		check(model.apply_preset(entry).is_empty(), "Falha ao reabrir preset pessoal.")
		if entry["side"] == "ally":
			var own = model.ally()
			var effective = model.configuration()[model.ally_role()]
			print(entry["name"], " revisão ",entry["revision"], ": próprios F/D ", own["physical_attack"], "/", own["ranged_attack"], "; defesas F/D ", own["physical_defense"], "/",own["ranged_defense"], "; efetivos F/D ",effective["physical_attack"],"/",effective["ranged_attack"]," e ",effective["physical_defense"],"/",effective["ranged_defense"])
		check(model.run(1)["error"].is_empty(), "Preset pessoal inválido após compatibilidade.")
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original, "Biblioteca pessoal alterada durante leitura.")
	var samples = 0
	for name in DirAccess.get_files_at("res://exports/damage-lab"):
		if not name.ends_with(".json"): continue
		var path = "res://exports/damage-lab/" + name
		var before = FileAccess.get_file_as_string(path)
		var report: Dictionary = JSON.parse_string(before)
		var conditions: Dictionary = report["conditions"]
		model = Model.new(data)
		for role in ["attacker", "target"]:
			var actor: Dictionary = conditions["base_stats"][role]
			var preset = {"id":"report", "name":actor["name"], "side":actor["side"], "revision":1, "actor":actor}
			if actor["side"] == "ally":preset["equipment"] = conditions["equipment"][role]
			check(model.apply_preset(preset).is_empty(), "Ficha do relatório não carregou.")
		if conditions["attacker"]["side"] == "enemy": model.swap_roles()
		model.action = conditions["action"].duplicate(true)
		model.settings = conditions["settings"].duplicate(true)
		var config = model.configuration()
		check(Calculator.validate(config).is_empty(), "Relatório convertido inválido.")
		for sample in report["samples"]:
			var calculated = Calculator.sample(config,sample["variation_roll"],sample["critical_roll"],sample["evasion_roll"])
			for key in ["damage","hp_removed","critical","evaded","hp_after","mp_after"]:
				check(calculated[key] == sample[key], "Resultado anterior mudou: " + name + " / " + key)
			samples += 1
		check(FileAccess.get_file_as_string(path) == before, "Exportação antiga foi modificada.")
	print("COMPATIBILIDADE REAL: ",library.custom.size()," presets e ",samples," amostras anteriores; ",checks," verificações, ",failures," falhas; arquivos preservados.")
	quit(0 if failures == 0 else 1)
