extends RefCounted
## Composição dos atributos e política canônica de equipamento por personagem.
static var _allowed_by_item: Dictionary = {}
static var _catalog: Dictionary = {}
static var _category_by_item: Dictionary = {}

static func character_id(actor: Dictionary) -> String:
	return str(actor.get("character_id", actor.get("id", "")))

static func _ensure_catalog() -> void:
	if not _catalog.is_empty():
		return
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	for collection in ["weapons", "armors"]:
		for entry in _catalog[collection]:
			_allowed_by_item[entry["id"]] = entry.get("allowed_character_ids", []).duplicate()
			_category_by_item[entry["id"]] = "weapon" if collection == "weapons" else "armor"

static func can_equip(actor: Dictionary, item: Dictionary, category: String = "") -> bool:
	# Política do catálogo, independente do nome do preset ou metadados da cópia.
	_ensure_catalog()
	if actor.get("side") != "ally" or item.get("equipped") != true or not _allowed_by_item.has(item.get("id")):
		return false
	if not category.is_empty() and _category_by_item[item["id"]] != category:
		return false
	var allowed: Array = _allowed_by_item[item["id"]]
	return allowed.is_empty() or character_id(actor) in allowed

static func catalog_item(category: String, id: String) -> Dictionary:
	_ensure_catalog()
	if category not in ["weapon", "armor"]:
		return {}
	for item in _catalog["weapons" if category == "weapon" else "armors"]:
		if item["id"] == id:
			return item.duplicate(true)
	return {}

static func attack_mode(weapon: Dictionary) -> String:
	return catalog_item("weapon", str(weapon.get("id", ""))).get("attack_mode", "melee")

static func upgraded_actor(actor: Dictionary) -> Dictionary:
	_ensure_catalog()
	var result = actor.duplicate(true)
	if not result.has("ranged_attack"):
		result["ranged_attack"] = result.get("physical_attack", 0)
		if result.get("side") == "ally":
			for character in _catalog["characters"]:
				if character["id"] == character_id(result):
					result["ranged_attack"] = character.get("legacy_ranged_attack", result["ranged_attack"])
	if not result.has("ranged_defense"):
		result["ranged_defense"] = result.get("physical_defense", 0)
	return result

static func catalog_name(category: String, id: String) -> String:
	_ensure_catalog()
	if category not in ["weapon", "armor"]:
		return ""
	for item in _catalog["weapons" if category == "weapon" else "armors"]:
		if item["id"] == id:
			return item["name"]
	return ""

static func default_item(actor: Dictionary, category: String) -> Dictionary:
	_ensure_catalog()
	if category not in ["weapon", "armor"]:
		return {}
	for character in _catalog["characters"]:
		if character["id"] == character_id(actor):
			for item in _catalog["weapons" if category == "weapon" else "armors"]:
				if item["id"] == character["default_" + category]:
					return item.duplicate(true)
	return {}

static func resolve(actor: Dictionary, weapon: Dictionary, armor: Dictionary, limit: int) -> Dictionary:
	var effective = actor.duplicate(true)
	if actor["side"] != "ally":
		return {"actor": effective, "composition": {}}
	var attack_bonus = int(weapon.get("attack_bonus", 0))
	var defense_bonus = int(armor.get("defense_bonus", 0))
	var ranged_defense_bonus = int(armor.get("ranged_defense_bonus", 0))
	var evasion_bonus = int(armor.get("evasion_bonus", 0))
	var base = {"physical_attack": actor["physical_attack"], "ranged_attack": actor["ranged_attack"], "physical_defense": actor["physical_defense"], "ranged_defense": actor["ranged_defense"], "evasion_base": actor["evasion_base"]}
	var bonuses = {"physical_attack": 0, "ranged_attack": 0, "physical_defense": defense_bonus, "ranged_defense": ranged_defense_bonus, "evasion_base": evasion_bonus}
	bonuses["ranged_attack" if attack_mode(weapon) == "ranged" else "physical_attack"] = attack_bonus
	var raw: Dictionary = {}
	var totals: Dictionary = {}
	for stat in base:
		raw[stat] = base[stat] + bonuses[stat]
		totals[stat] = clampi(int(raw[stat]), 0, 100 if stat == "evasion_base" else limit)
		effective[stat] = totals[stat]
	return {"actor": effective, "composition": {"base": base, "bonuses": bonuses, "raw_total": raw, "effective": totals, "limit": limit, "evasion_limit": 100}}
