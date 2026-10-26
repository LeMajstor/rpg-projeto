extends RefCounted
## Condições declarativas limitadas: sem scripts, missões, avaliador de expressões ou relógio próprio.
static func matches(condition: Dictionary, period: String, flags: Dictionary) -> bool:
	if not condition.get("periods", []).is_empty() and not condition["periods"].has(period):
		return false
	for flag in condition.get("flags_set", []):
		if not flags.get(flag, false):
			return false
	for flag in condition.get("flags_unset", []):
		if flags.get(flag, false):
			return false
	return true

static func interaction(entity: Dictionary, period: String, flags: Dictionary) -> Dictionary:
	for rule in entity.get("interaction_rules", []):
		if matches(rule.get("when", {}), period, flags):
			return rule
	return {}

static func valid_condition(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if key not in ["periods", "flags_set", "flags_unset"] or not value[key] is Array:
			return false
		for item in value[key]:
			if not item is String or item.is_empty():
				return false
	return true

static func valid_placement(value: Variant) -> bool:
	if not value is Dictionary or not _point(value.get("position")):
		return false
	if not value.get("route", []) is Array:
		return false
	for point in value.get("route", []):
		if not _point(point):
			return false
	if not value.get("route", []).is_empty():
		var first: Array = value["route"][0]
		var position: Array = value["position"]
		if not Vector2(first[0], first[1]).is_equal_approx(Vector2(position[0], position[1])):
			return false
	var speed = value.get("speed", 0)
	return (speed is int or speed is float) and is_finite(float(speed)) and speed >= 0

static func _point(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for item in value:
		if not (item is float or item is int) or not is_finite(float(item)):
			return false
	return true

static func valid_entity(entity: Dictionary, dialogues: Dictionary) -> bool:
	if not valid_condition(entity.get("available_when", {})):
		return false
	var placements = entity.get("placement_by_period", {})
	if not placements is Dictionary:
		return false
	for period in placements:
		if not period is String or not valid_placement(placements[period]):
			return false
	var rules = entity.get("interaction_rules", [])
	if not rules is Array:
		return false
	for rule in rules:
		if not rule is Dictionary or not valid_condition(rule.get("when", {})):
			return false
		if not rule.get("dialogue_id") is String or not dialogues.has(rule["dialogue_id"]):
			return false
		if rule.has("set_flag") and (not rule["set_flag"] is String or rule["set_flag"].is_empty()):
			return false
	if entity.has("solid") and not entity["solid"] is bool:
		return false
	if entity.get("solid", false):
		var rect = entity.get("rect")
		if not rect is Array or rect.size() != 4 or not _point([rect[0], rect[1]]) or not _point([rect[2], rect[3]]) or rect[2] <= 0 or rect[3] <= 0:
			return false
	return true
