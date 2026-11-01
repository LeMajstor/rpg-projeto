extends RefCounted
## Adapta fichas do laboratório à simulação temporal. Não administra HP/MP ou ATB.
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Policy = preload("res://scripts/damage/damage_action_policy.gd")
const REFERENCE_PATH = "res://data/battle_damage_v1.json"
static var catalog: Dictionary = {}

static func damage_data() -> Dictionary:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	return catalog

static func extend_definitions(original: Dictionary) -> Dictionary:
	var data = original.duplicate(true)
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_PATH))
	var preset: Dictionary = reference["preset"].duplicate(true)
	preset["party"] = []
	for index in range(reference["party"].size()):
		preset["party"].append(actor_definition(reference["party"][index], "p%d" % (index + 1)))
	for index in range(reference["enemies"].size()):
		var definition = actor_definition(reference["enemies"][index], "")
		definition["movement_behavior"] = "heavy" if index == 0 else "agile"
		definition["facing_policy"] = "focus"
		definition["actions"] = [{"id": "attack", "weight": 1.0}]
		data["enemy_types"]["damage_monster_%d" % (index + 1)] = definition
	data["presets"].append(preset)
	data["default_preset_id"] = preset["id"]
	return data

static func actor_definition(entry: Dictionary, battle_id: String) -> Dictionary:
	var base = Equipment.upgraded_actor(entry["actor"])
	var loadout: Dictionary = {}
	if entry["side"] == "ally":
		for category in ["weapon", "armor"]:
			loadout[category] = Equipment.catalog_item(category, entry["equipment"][category]["id"])
	var stats: Dictionary = base if loadout.is_empty() else Equipment.resolve(base, loadout["weapon"], loadout["armor"], 999)["actor"]
	return {"id": battle_id, "name": entry["name"], "short_name": entry["name"],
		"max_hp": int(base["hp"]), "max_mp": int(base["mp"]), "ini": base["ini"],
		"attack": stats["physical_attack"], "color": base["color"],
		"skills": ["magic_skill"] if Equipment.character_id(base) == "ally_3" else [],
		"damage_base": base, "damage_stats": stats, "loadout": loadout,
		"source_preset_id": entry["id"], "source_revision": entry["revision"]}

static func equip_definition(definition: Dictionary, loadout: Dictionary) -> Dictionary:
	var result = definition.duplicate(true)
	result["loadout"] = loadout.duplicate(true)
	result["damage_stats"] = Equipment.resolve(result["damage_base"], loadout["weapon"], loadout["armor"], 999)["actor"]
	result["attack"] = result["damage_stats"]["physical_attack"]
	return result

static func skill(actor: Dictionary, id: String) -> Dictionary:
	if id != "attack" and not (id == "magic_skill" and actor.get("skills", []).has(id)):
		return {}
	var action: Dictionary = {}
	for entry in damage_data()["actions"]:
		if entry["id"] == ("basic" if id == "attack" else id):
			action = entry.duplicate(true)
	if action.is_empty() or not Policy.allows(actor["damage_stats"], action):
		return {}
	var mode = Equipment.attack_mode(actor["loadout"]["weapon"]) if actor["side"] == "ally" else Policy.default_physical_mode(actor["damage_stats"])
	action["physical_mode"] = mode
	return {"name": "Atacar" if id == "attack" else action["name"], "target": "single",
		"mp_cost": action["mp_cost"], "effect": "damage", "category": "basic" if id == "attack" else "magic",
		"delivery": "melee" if id == "attack" and mode == "melee" else "gesture", "damage_action": action}

static func configuration(attacker: Dictionary, target: Dictionary, battle_skill: Dictionary) -> Dictionary:
	var source: Dictionary = attacker["damage_stats"].duplicate(true)
	var destination: Dictionary = target["damage_stats"].duplicate(true)
	source["hp"] = attacker["hp"]
	source["mp"] = attacker["mp"]
	destination["hp"] = target["hp"]
	destination["mp"] = target["mp"]
	return {"attacker": source, "target": destination, "action": battle_skill["damage_action"],
		"settings": damage_data()["settings"], "weapon": attacker.get("loadout", {}).get("weapon", {})}
