extends RefCounted
## Repertório ofensivo do tipo; alvo não herda restrições do atacante.
static var _profiles: Array = []

static func policy(actor: Dictionary) -> Dictionary:
	if actor.get("side") != "enemy": return {}
	if _profiles.is_empty():
		_profiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))["profiles"]
	for profile in _profiles:
		if profile["id"] == actor.get("id"):
			return profile.get("offensive_policy", {}).duplicate(true)
	return {}

static func allows(actor: Dictionary, action: Dictionary) -> bool:
	var rules = policy(actor)
	if rules.is_empty(): return true
	return action.get("id") in rules["action_ids"] and action.get("damage_type") == "physical" and action.get("effect_type", "damage") == "damage" and action.get("physical_mode", "weapon") in ["weapon", rules["physical_mode"]]

static func default_physical_mode(actor: Dictionary) -> String:
	return policy(actor).get("physical_mode", "melee")
