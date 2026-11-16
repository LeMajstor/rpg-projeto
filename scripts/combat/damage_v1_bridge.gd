extends RefCounted
## Adapta fichas do laboratório à simulação temporal. Não administra HP/MP ou ATB.
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Policy = preload("res://scripts/damage/damage_action_policy.gd")
const Reference = preload("res://scripts/damage/combat_reference.gd")
const REFERENCE_PATH = "res://data/battle_damage_v1.json"
static var catalog: Dictionary = {}

static func damage_data() -> Dictionary:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	return catalog

static func extend_definitions(original: Dictionary) -> Dictionary:
	var data = original.duplicate(true)
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_PATH))
	# As quinze demonstrações anteriores são históricas no laboratório independente.
	# A exploração usa exploration_definitions para conservar suas formações atuais.
	data["legacy_preset_ids"] = data["presets"].map(func(entry): return entry["id"])
	data["items"].merge(reference.get("items", {}).duplicate(true))
	data["affliction_rules"] = reference["affliction_rules"].duplicate(true)
	var preset: Dictionary = reference["preset"].duplicate(true)
	preset["party"] = []
	for index in range(reference["party_profile_ids"].size()):
		var definition = actor_definition(Reference.entry(reference["party_profile_ids"][index]), "p%d" % (index + 1))
		definition["skills"] = reference["skills_by_character"].get(Equipment.character_id(definition["damage_base"]), [])
		preset["party"].append(definition)
	for index in range(reference["enemies_profile_ids"].size()):
		var profile_id: String = reference["enemies_profile_ids"][index]
		var definition = actor_definition(Reference.entry(profile_id), "")
		definition["movement_behavior"] = "heavy" if index == 0 else "agile"
		definition["facing_policy"] = "focus"
		definition["actions"] = reference["enemy_actions"][profile_id].duplicate(true)
		definition["skills"] = definition["actions"].map(func(option): return option["id"])
		data["enemy_types"]["damage_monster_%d" % (index + 1)] = definition
	data["presets"].append(preset)
	data["default_preset_id"] = preset["id"]
	return data

static func exploration_definitions(original: Dictionary) -> Dictionary:
	var data = extend_definitions(original)
	var configuration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/exploration_combat.json"))
	var shared: Dictionary = data["presets"].back()
	var shared_enemies: Dictionary = {}
	for entry in shared["enemies"]:
		var definition: Dictionary = data["enemy_types"][entry["type"]]
		shared_enemies[definition["reference_profile_id"]] = definition
	# Variantes espaciais reutilizam fichas/repertórios; não criam monstros novos.
	for type_id in configuration["enemy_profiles_by_type"]:
		var profile_id: String = configuration["enemy_profiles_by_type"][type_id]
		var definition: Dictionary = shared_enemies[profile_id].duplicate(true)
		definition["movement_behavior"] = original["enemy_types"][type_id]["movement_behavior"]
		definition["facing_policy"] = original["enemy_types"][type_id]["facing_policy"]
		data["enemy_types"]["shared_" + type_id] = definition
	for preset in data["presets"]:
		if preset["id"] not in configuration["preset_ids"]:
			continue
		preset["party"] = shared["party"].duplicate(true)
		preset["damage_ruleset"] = shared["damage_ruleset"]
		preset["item_ids"] = shared["item_ids"].duplicate()
		preset["allied_slots"] = preset["allied_slots"].slice(0, shared["party"].size())
		for enemy in preset["enemies"]:
			enemy["type"] = "shared_" + enemy["type"]
			# As antigas ondas de área não pertencem ao repertório aprovado da V1.
			enemy.erase("actions")
		data["legacy_preset_ids"].erase(preset["id"])
	data["default_preset_id"] = configuration["preset_ids"][0]
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
		"skills": [], # Repertório configurado em dados na montagem do encontro.
		"damage_base": base, "damage_stats": stats, "loadout": loadout,
		"reference_profile_id": entry["id"], "source_preset_id": entry.get("source_preset_id", entry["id"]), "source_revision": entry["revision"]}

static func equip_definition(definition: Dictionary, loadout: Dictionary) -> Dictionary:
	var result = definition.duplicate(true)
	result["loadout"] = loadout.duplicate(true)
	result["damage_stats"] = Equipment.resolve(result["damage_base"], loadout["weapon"], loadout["armor"], 999)["actor"]
	result["attack"] = result["damage_stats"]["physical_attack"]
	return result

static func skill(actor: Dictionary, id: String) -> Dictionary:
	if id != "attack" and not actor.get("skills", []).has(id):
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
		"mp_cost": action["mp_cost"], "effect": "affliction" if action.get("effect_type") == "affliction" else "damage", "category": "basic" if id == "attack" else "magic",
		"delivery": "melee" if id == "attack" and mode == "melee" else "gesture", "damage_action": action}

static func configuration(attacker: Dictionary, target: Dictionary, battle_skill: Dictionary) -> Dictionary:
	var source: Dictionary = attacker["damage_stats"].duplicate(true)
	var destination: Dictionary = target["damage_stats"].duplicate(true)
	# Lentidão suprime somente a parcela natural de EVA; o bônus permanece.
	if target.get("affliction", {}).get("id", "") == "slow":
		var loadout: Dictionary = target.get("loadout", {})
		var composed = Equipment.resolve(target["damage_base"], loadout.get("weapon", {}), loadout.get("armor", {}), 999)
		var equipped_bonus = int(loadout.get("armor", {}).get("evasion_bonus", 0))
		var temporary_bonus = int(destination["evasion_base"]) - int(composed["actor"]["evasion_base"])
		destination["evasion_base"] = clampi(equipped_bonus + temporary_bonus, 0, 100)
	source["hp"] = attacker["hp"]
	source["mp"] = attacker["mp"]
	destination["hp"] = target["hp"]
	destination["mp"] = target["mp"]
	return {"attacker": source, "target": destination, "action": battle_skill["damage_action"],
		"settings": damage_data()["settings"], "weapon": attacker.get("loadout", {}).get("weapon", {})}
