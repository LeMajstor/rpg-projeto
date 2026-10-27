extends RefCounted
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
var data: Dictionary
var attacker: Dictionary
var target: Dictionary
var loadouts: Dictionary = {}
var weapon: Dictionary:
	get: return _loadout()["weapon"]
	set(value): _loadout()["weapon"] = value.duplicate(true)
var armor: Dictionary:
	get: return _loadout()["armor"]
	set(value): _loadout()["armor"] = value.duplicate(true)
var action: Dictionary
var settings: Dictionary
var seed_value = 421
var sequence_position = 0
var rng_state: Dictionary = {}
var history: Array[Dictionary] = []
var run_number = 0

func _init(definitions: Dictionary) -> void:
	data = definitions.duplicate(true)
	reset_case()

func definition(collection: String, id: String) -> Dictionary:
	for entry in data[collection]:
		if entry["id"] == id:
			return entry.duplicate(true)
	return {}

func reset_case() -> void:
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
	if role == "attacker":
		attacker = selected
	else:
		target = selected
	if attacker["side"] == target["side"]:
		for profile in data["profiles"]:
			if profile["side"] != selected["side"]:
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
	var id: String = ally()["id"]
	if not loadouts.has(id):
		loadouts[id] = {"weapon": definition("weapons", data["default_weapon"]), "armor": definition("armors", data["default_armor"])}
	return loadouts[id]

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
			config["equipment"][role] = {"owner_id": actor["id"], "weapon": weapon.duplicate(true), "armor": armor.duplicate(true)}
			config["composition"][role] = resolved["composition"]
	if attacker["side"] == "ally":
		config["weapon"] = weapon.duplicate(true)
	config["critical_source"] = Calculator.critical_source(config)
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
