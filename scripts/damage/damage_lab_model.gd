extends RefCounted
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Presets = preload("res://scripts/damage/damage_presets.gd")
var data: Dictionary
var attacker: Dictionary
var target: Dictionary
var loadouts: Dictionary = {}
var weapon: Dictionary:
	get: return _loadout()["weapon"]
	set(value):
		if Equipment.can_equip(ally(), value, "weapon"):
			_loadout()["weapon"] = value.duplicate(true)
var armor: Dictionary:
	get: return _loadout()["armor"]
	set(value):
		if Equipment.can_equip(ally(), value, "armor"):
			_loadout()["armor"] = value.duplicate(true)
var action: Dictionary
var settings: Dictionary
var seed_value = 421
var sequence_position = 0
var rng_state: Dictionary = {}
var history: Array[Dictionary] = []
var run_number = 0
var selected_presets: Dictionary = {}
var preset_baselines: Dictionary = {}

func _init(definitions: Dictionary) -> void:
	data = definitions.duplicate(true)
	reset_case()

func definition(collection: String, id: String) -> Dictionary:
	for entry in data[collection]:
		if entry["id"] == id:
			return Equipment.upgraded_actor(entry) if collection == "profiles" else entry.duplicate(true)
	return {}

func reset_case() -> void:
	selected_presets.clear()
	preset_baselines.clear()
	loadouts.clear()
	attacker = definition("profiles", data["default_attacker"])
	target = definition("profiles", data["default_target"])
	weapon = definition("weapons", data["default_weapon"])
	armor = definition("armors", data["default_armor"])
	action = definition("actions", data["default_action"])
	settings = data["settings"].duplicate(true)
	set_seed(int(settings["seed"]))
	restart_sequence()

func choose_profile(role: String, id: String) -> void:
	var selected = definition("profiles", id)
	if selected.is_empty():
		return
	selected_presets.erase(selected["side"])
	preset_baselines.erase(selected["side"])
	if role == "attacker":
		attacker = selected
	else:
		target = selected
	if attacker["side"] == target["side"]:
		for profile in data["profiles"]:
			if profile["side"] != selected["side"]:
				selected_presets.erase(profile["side"])
				preset_baselines.erase(profile["side"])
				if role == "attacker":
					target = profile.duplicate(true)
				else:
					attacker = profile.duplicate(true)
				break

func swap_roles() -> void:
	var previous = attacker
	attacker = target
	target = previous

func ally_role() -> String:
	return "attacker" if attacker["side"] == "ally" else "target"

func ally() -> Dictionary:
	return attacker if attacker["side"] == "ally" else target

func enemy() -> Dictionary:
	return attacker if attacker["side"] == "enemy" else target

func _loadout() -> Dictionary:
	var id: String = Equipment.character_id(ally())
	if not loadouts.has(id):
		loadouts[id] = {"weapon": Equipment.default_item(ally(), "weapon"), "armor": Equipment.default_item(ally(), "armor")}
	return loadouts[id]

func choose_equipment(category: String, id: String) -> String:
	if category not in ["weapon", "armor"]:
		return "Categoria de equipamento inválida."
	var item = definition("weapons" if category == "weapon" else "armors", id)
	if not Equipment.can_equip(ally(), item, category):
		return "Equipamento indisponível para este personagem."
	_loadout()[category] = item
	return ""

func preset_payload(side: String) -> Dictionary:
	if side not in ["ally", "enemy"]:
		return {}
	var payload = {"side": side, "actor": (ally() if side == "ally" else enemy()).duplicate(true)}
	if side == "ally":
		payload["equipment"] = _loadout().duplicate(true)
	return payload

func apply_preset(preset: Dictionary) -> String:
	preset = Presets.upgraded_entry(preset)
	var error = Presets.validate_entry(preset, data)
	if not error.is_empty():
		return error
	var side: String = preset["side"]
	var role = ally_role() if side == "ally" else ("target" if ally_role() == "attacker" else "attacker")
	if role == "attacker":
		attacker = preset["actor"].duplicate(true)
	else:
		target = preset["actor"].duplicate(true)
	if side == "ally":
		loadouts[Equipment.character_id(ally())] = preset["equipment"].duplicate(true)
	selected_presets[side] = {"id": preset["id"], "name": preset["name"], "revision": int(preset.get("revision", 1)), "source": preset.get("source", "custom")}
	preset_baselines[side] = preset_payload(side)
	return ""

func preset_modified(side: String) -> bool:
	return preset_baselines.has(side) and preset_baselines[side] != preset_payload(side)

func set_seed(value: int) -> void:
	if seed_value != value:
		seed_value = value
		restart_sequence()

func restart_sequence() -> void:
	sequence_position = 0
	rng_state = {}

func configuration() -> Dictionary:
	var config = {"action": action.duplicate(true), "settings": settings.duplicate(true),
		"base_stats": {"attacker": attacker.duplicate(true), "target": target.duplicate(true)},
		"equipment": {}, "composition": {}}
	for role in ["attacker", "target"]:
		var actor: Dictionary = attacker if role == "attacker" else target
		var resolved = Equipment.resolve(actor, weapon, armor, int(settings["effective_stat_limit"]))
		config[role] = resolved["actor"]
		if actor["side"] == "ally":
			config["equipment"][role] = {"owner_id": Equipment.character_id(actor), "weapon": weapon.duplicate(true), "armor": armor.duplicate(true)}
			config["composition"][role] = resolved["composition"]
	if attacker["side"] == "ally":
		config["weapon"] = weapon.duplicate(true)
	if config["action"]["damage_type"] == "magical":
		config["action"]["critical_allowed"] = false
	config["critical_source"] = Calculator.critical_source(config)
	config["damage_stats"] = Calculator.damage_stats(config)
	config["presets"] = {}
	for side in selected_presets:
		var role = ally_role() if side == "ally" else ("target" if ally_role() == "attacker" else "attacker")
		config["presets"][role] = selected_presets[side].duplicate(true)
		config["presets"][role]["modified"] = preset_modified(side)
	return config

func run(count: int) -> Dictionary:
	var result = Calculator.run_batch(configuration(), count, seed_value, rng_state)
	if not result.get("error", "").is_empty():
		return result
	run_number += 1
	result["run_number"] = run_number
	result["sequence_start"] = sequence_position
	sequence_position += count
	rng_state = result["rng_after"].duplicate()
	history.append(result)
	while history.size() > int(settings["history_limit"]):
		history.pop_front()
	return result
