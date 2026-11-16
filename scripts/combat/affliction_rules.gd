extends RefCounted
## Regras puras aprovadas; clocks, alvo/origem e RNG pertencem ao BattleModel.
static func id(actor: Dictionary) -> String:
	return actor.get("affliction", {}).get("id", "")

static func ini(actor: Dictionary) -> float:
	var natural = float(actor["ini"])
	if id(actor) == "slow":
		natural = ceilf(natural / 2.0)
	return maxf(0.0, natural + float(actor["ini_modifier"]))

static func intelligence(actor: Dictionary) -> float:
	return float(actor.get("damage_stats", {}).get("intelligence", 1))

static func recovery_chance(actor: Dictionary) -> float:
	var intelligence_value = intelligence(actor)
	var source_magic = float(actor.get("affliction", {}).get("source_magic", 0))
	return intelligence_value / (intelligence_value + source_magic) if intelligence_value + source_magic > 0 else 0.0

static func poison_damage(actor: Dictionary, rule: Dictionary) -> int:
	return maxi(1, roundi(float(actor["max_hp"]) * float(rule["hp_fraction"])))
