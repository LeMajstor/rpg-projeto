extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var library = Library.new(data)
	if not library.load_error.is_empty():
		push_error(library.load_error)
		quit(1)
		return
	var inventory = []
	for entry in library.custom:
		var model = Model.new(data)
		var error = model.apply_preset(entry)
		if not error.is_empty():
			push_error(error)
			quit(1)
			return
		var role = model.ally_role() if entry["side"] == "ally" else ("target" if model.ally_role() == "attacker" else "attacker")
		inventory.append({"name":entry["name"],"id":entry["id"],"revision":entry["revision"],"own":entry["actor"],"effective":model.configuration()[role],"equipment":entry.get("equipment",{})})
	var file = FileAccess.open("res://artifacts/damage-lab-mage/installed-inventory.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(inventory,"\t",false,true)+"\n")
	print("BIBLIOTECA REABERTA: ",inventory.size()," presets válidos")
	quit()
