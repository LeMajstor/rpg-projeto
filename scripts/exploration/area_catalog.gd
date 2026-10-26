extends RefCounted
## Apenas carrega definições; estados de áreas pertencem à sessão.
const Terrain = preload("res://scripts/exploration/terrain_geometry.gd")
const Rules = preload("res://scripts/exploration/area_rules.gd")
static func load_definitions() -> Dictionary:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/areas.json"))
	var definitions: Dictionary = {}
	if not catalog is Dictionary:
		return definitions
	for id in catalog.get("areas", {}):
		var path: String = catalog["areas"][id]
		if not FileAccess.file_exists(path):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("id", "") == id and valid_map(data):
			definitions[id] = data
	return definitions

static func numbers(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count:
		return false
	for item in value:
		if not (item is float or item is int) or not is_finite(float(item)):
			return false
	return true

static func valid_map(data: Dictionary) -> bool:
	if not data.get("area_type", "exploration") is String or str(data.get("area_type", "exploration")).is_empty():
		return false
	if not data.get("time_advances", false) is bool:
		return false
	if data.get("time_advances", false) and data.get("area_type", "") != "overworld":
		return false
	if data.get("lighting_profile", "fixed") not in ["cycle", "fixed"]:
		return false
	for key in ["world_size", "spawn"]:
		if not numbers(data.get(key), 2):
			return false
	if not numbers(data.get("walkable_bounds"), 4):
		return false
	if data["world_size"][0] <= 0 or data["world_size"][1] <= 0 or data["walkable_bounds"][2] <= 0 or data["walkable_bounds"][3] <= 0:
		return false
	for key in ["move_speed", "leader_half_extent", "follower_gap"]:
		if not numbers([data.get(key)], 1) or float(data[key]) <= 0:
			return false
	if not data.get("obstacles") is Array:
		return false
	if not data.get("terrain", []) is Array:
		return false
	for feature in data.get("terrain", []):
		if not feature is Dictionary or not feature.get("kind") is String or not numbers(feature.get("rect"), 4):
			return false
		if feature["rect"][2] <= 0 or feature["rect"][3] <= 0:
			return false
		if not Terrain.valid_feature(feature, float(data["leader_half_extent"])):
			return false
	for obstacle in data["obstacles"]:
		if not obstacle is Dictionary or not numbers(obstacle.get("rect"), 4):
			return false
		if not valid_visual(obstacle):
			return false
	var ids = {}
	for group in ["encounters", "npcs", "objects", "transitions"]:
		if not data.get(group, []) is Array:
			return false
		for entity in data.get(group, []):
			if not entity is Dictionary or not entity.get("id") is String or not numbers(entity.get("position"), 2):
				return false
			if ids.has(entity["id"]) or entity["id"].is_empty():
				return false
			ids[entity["id"]] = true
			if not entity.get("route", []) is Array or not numbers([entity.get("speed", 0)], 1):
				return false
			for point in entity.get("route", []):
				if not numbers(point, 2):
					return false
			if entity.get("object_type", "") == "door" and not numbers(entity.get("rect"), 4):
				return false
			if not valid_visual(entity):
				return false
			var bindings = entity.get("dialogue_by_period", {})
			if not bindings is Dictionary or not data.get("dialogues", {}) is Dictionary:
				return false
			if not Rules.valid_entity(entity, data.get("dialogues", {})):
				return false
			for period in bindings:
				if not period is String or not bindings[period] is String or not data.get("dialogues", {}).has(bindings[period]):
					return false
	return data.get("entries", {}) is Dictionary and data.get("dialogues", {}) is Dictionary

static func valid_visual(definition: Dictionary) -> bool:
	for key in ["night_windows", "night_light"]:
		if definition.has(key) and not definition[key] is bool:
			return false
	if definition.has("ground_only") and not definition["ground_only"] is bool:
		return false
	for key in ["visual_height", "canopy_width", "sort_y"]:
		if definition.has(key) and not numbers([definition[key]], 1):
			return false
	return float(definition.get("visual_height", 28)) >= 0 and float(definition.get("canopy_width", 96)) > 0
