extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var failures = 0
func check(ok: bool, message: String) -> bool:
	if not ok:
		failures += 1
		push_error(message)
	return ok
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var library = Library.new(data)
	if not check(library.load_error.is_empty(),library.load_error): quit(1); return
	var allies: Dictionary = {}
	var monster: Dictionary = {}
	for preset in library.custom:
		if preset["side"] == "ally":allies[preset["actor"]["character_id"]] = preset
		elif preset["name"] == "Monstro #1":monster = preset
	if not check(allies.has("ally_1") and allies.has("ally_2") and not monster.is_empty(),"Não foram encontrados os três presets pessoais."): quit(1); return
	var reference: Array = []
	var reference_rng: Dictionary = {}
	var cases: Array = []
	for mode in ["melee","ranged"]:
		for ally_id in ["ally_1","ally_2"]:
			var model = Model.new(data)
			check(model.apply_preset(allies[ally_id]).is_empty(),"Falha ao carregar aliado.")
			check(model.apply_preset(monster).is_empty(),"Falha ao carregar monstro.")
			model.swap_roles()
			model.action = model.definition("actions","basic")
			model.action["physical_mode"] = mode
			model.settings["variation_enabled"] = true
			model.settings["variation_percent"] = 10.0
			model.settings["critical_mode"] = "rolled"
			model.settings["item_bonus"] = 0.0
			model.settings["buff_bonus"] = 0.0
			model.set_seed(421)
			model.restart_sequence()
			var result = model.run(1000)
			if not check(result["error"].is_empty(),result["error"]): quit(1); return
			if reference.is_empty():
				reference = result["samples"].duplicate(true)
				reference_rng = result["rng_after"].duplicate()
			for index in range(1000):
				for roll in ["variation_roll","critical_roll","evasion_roll"]:
					check(result["samples"][index][roll] == reference[index][roll],"Sorteios não pareados.")
			check(result["rng_after"] == reference_rng and result["sequence_start"] == 0,"Sequência não reiniciada.")
			var name = "monstro-%s-aliado-%s-1000x.json" % ["contato" if mode == "melee" else "distancia",ally_id.trim_prefix("ally_")]
			var saved = Export.save("res://artifacts/monstro-quatro-cenarios-2026-10-28/" + name,result)
			check(saved["error"].is_empty(),"Falha ao salvar relatório.")
			cases.append({"file":name,"mode":mode,"ally":ally_id,"mean":result["mean"],"evasion_count":result["evasion_count"],"critical_count":result["critical_count"]})
			print(name,": média ",result["mean"],", esquivas ",result["evasion_count"],", críticos ",result["critical_count"])
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original,"Biblioteca pessoal foi alterada.")
	var manifest = FileAccess.open("res://artifacts/monstro-quatro-cenarios-2026-10-28/execucao.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"seed":421,"count_per_case":1000,"paired_rolls":true,"personal_presets_unchanged":true,"failures":failures,"cases":cases},"\t"))
	manifest.close()
	print("QUATRO LOTES: 4000 ataques reais na calculadora Godot, ",failures," falhas; sorteios pareados e presets preservados.")
	quit(0 if failures == 0 else 1)
