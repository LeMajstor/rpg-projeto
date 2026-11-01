extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
func _initialize() -> void:
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var library = Library.new(data)
	if not library.load_error.is_empty():
		push_error(library.load_error)
		quit(1)
		return
	var model = Model.new(data)
	var loaded = 0
	for p in library.custom:
		if p["actor"].get("character_id") == "ally_3" or p["name"] == "Monstro #1":
			if not model.apply_preset(p).is_empty():
				quit(1)
				return
			loaded += 1
	if loaded != 2 or not model.choose_action("magic_skill").is_empty():
		quit(1)
		return
	model.set_seed(421)
	model.restart_sequence()
	var result = model.run(1000)
	if not result.get("error","").is_empty() or not Export.save("res://artifacts/damage-v1-final/magia-ofensiva-v1-1000.json",result)["error"].is_empty():
		quit(1)
		return
	if FileAccess.get_file_as_string(Library.DEFAULT_PATH) != original:
		push_error("Biblioteca alterada durante exportação de referência")
		quit(1)
		return
	print("REFERÊNCIA V1 EXPORTADA:1000 amostras;presets preservados")
	quit()
