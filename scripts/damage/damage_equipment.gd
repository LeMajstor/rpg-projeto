extends RefCounted
## Composição pura dos atributos do aliado; monstros mantêm fichas diretas.
static func resolve(actor: Dictionary, weapon: Dictionary, armor: Dictionary, limit: int) -> Dictionary:
	var effective = actor.duplicate(true)
	if actor["side"] != "ally":
		return {"actor": effective, "composition": {}}
	var attack_bonus = int(weapon.get("attack_bonus", 0)) if weapon.get("equipped", true) else 0
	var defense_bonus = int(armor.get("defense_bonus", 0)) if armor.get("equipped", false) else 0
	var base = {"physical_attack": actor["physical_attack"], "physical_defense": actor["physical_defense"]}
	var bonuses = {"physical_attack": attack_bonus, "physical_defense": defense_bonus}
	var raw: Dictionary = {}
	var totals: Dictionary = {}
	for stat in base:
		raw[stat] = base[stat] + bonuses[stat]
		totals[stat] = clampi(int(raw[stat]), 0, limit)
		effective[stat] = totals[stat]
	return {"actor": effective, "composition": {"base": base, "bonuses": bonuses, "raw_total": raw, "effective": totals, "limit": limit}}
