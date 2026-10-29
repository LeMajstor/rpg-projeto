extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var library = Library.new(data)
	if not library.load_error.is_empty():
		push_error(library.load_error)
		quit(1)
		return
	var inventory: Array = []
	for preset in library.custom:
		var model = Model.new(data)
		var error = model.apply_preset(preset)
		if not error.is_empty():
			push_error(error)
			quit(1)
			return
		var role = model.ally_role() if preset["side"] == "ally" else ("target" if model.ally_role() == "attacker" else "attacker")
		var entry = {"id":preset["id"],"name":preset["name"],"side":preset["side"],"revision":preset["revision"],"own":preset["actor"],"effective":model.configuration()[role]}
		inventory.append(entry)
		print(preset["name"], " · revisão ", preset["revision"], " · MAG ", entry["effective"]["magic_power"], " · DEF M ",entry["effective"]["magic_defense"], " · VIG ",entry["effective"]["vigor"], " · INT ",entry["effective"]["intelligence"], " · EVA ",entry["effective"]["evasion_base"], " · MP ",entry["effective"]["mp"])
	var file = FileAccess.open("res://artifacts/aflicoes-presets-defm-2026-10-29/inventario.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(inventory,"\t",false,true)+"\n")
	file.close()
	quit()
