extends RefCounted
## Referências aprovadas comuns à calculadora e à batalha; não grava presets pessoais.
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const PATH = "res://data/damage_reference_profiles.json"

static func entries(side: String = "") -> Array:
	var profiles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))["profiles"]
	var result = []
	for id in profiles:
		var entry: Dictionary = profiles[id].duplicate(true)
		if not side.is_empty() and entry["side"] != side:
			continue
		entry["actor"] = Equipment.upgraded_actor(entry["actor"])
		if entry["side"] == "ally":
			for category in ["weapon", "armor"]:
				entry["equipment"][category] = Equipment.catalog_item(category, entry["equipment"][category]["id"])
		result.append(entry)
	return result

static func entry(id: String) -> Dictionary:
	for value in entries():
		if value["id"] == id:
			return value
	return {}
