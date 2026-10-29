extends RefCounted
## Fórmula experimental pura, independente do BattleModel e da renderização.
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const ALLOWED_COUNTS = [1, 10, 100, 1000]
const STATS = ["hp", "mp", "ini", "physical_attack", "physical_defense", "ranged_attack", "ranged_defense", "magic_power", "magic_defense", "intelligence", "vigor", "critical_base", "evasion_base"]

static func stat_bounds(side: String, stat: String) -> Vector2i:
	if stat in ["intelligence", "vigor"]:
		return Vector2i(1, 999)
	if stat == "evasion_base":
		return Vector2i(0, 100) # Faixa percentual experimental do laboratório.
	if stat in ["ini", "critical_base"]:
		return Vector2i(1, 99)
	if side == "enemy" and stat == "hp":
		return Vector2i(1, 99999)
	return Vector2i(1, 9999) if side == "enemy" else Vector2i(0, 999)

static func attribute_ranges() -> Dictionary:
	var ranges: Dictionary = {}
	for side in ["ally", "enemy"]:
		ranges[side] = {}
		for stat in STATS:
			var bounds = stat_bounds(side, stat)
			ranges[side][stat] = [bounds.x, bounds.y]
	return ranges

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum

static func validate(config: Dictionary) -> String:
	for role in ["attacker", "target"]:
		if not config.get(role) is Dictionary:
			return "Ficha ausente: " + role
		if config[role].get("side", "") not in ["ally", "enemy"]:
			return "Lado inválido."
		for stat in STATS:
			var bounds = stat_bounds(config[role]["side"], stat)
			var value = config[role].get(stat)
			if not _number(value, bounds.x, bounds.y) or float(value) != floorf(float(value)):
				return "Atributo fora da faixa: %s / %s" % [role, stat]
		if config[role]["hp"] == 0:
			return "Atacante e alvo precisam de HP maior que zero para executar ações."
	if config["attacker"]["side"] == config["target"]["side"]:
		return "Escolha lados opostos: sem fogo amigo."
	for role in config.get("base_stats", {}):
		for stat in STATS:
			var bounds = stat_bounds(config["base_stats"][role]["side"], stat)
			var value = config["base_stats"][role].get(stat)
			if not _number(value, bounds.x, bounds.y) or float(value) != floorf(float(value)):
				return "Atributo próprio fora da faixa: " + stat
	for role in ["attacker", "target"]:
		if config[role]["side"] == "ally" and not config.get("equipment", {}).get(role) is Dictionary:
			return "Aliados precisam de arma e armadura equipadas."
	for role in config.get("equipment", {}):
		if config[role]["side"] != "ally":
			return "Monstros não usam equipamentos."
		var equipment: Dictionary = config["equipment"][role]
		for category in ["weapon", "armor"]:
			if not equipment.get(category) is Dictionary or not Equipment.can_equip(config[role], equipment[category], category):
				return "Equipamento exclusivo ou inválido para este personagem."
		if equipment["weapon"].get("attack_mode") != Equipment.attack_mode(equipment["weapon"]):
			return "Modalidade da arma inválida."
		var eva_bonus = equipment["armor"].get("evasion_bonus", 0)
		if not _number(eva_bonus, 0, 100) or float(eva_bonus) != floorf(float(eva_bonus)) or (not equipment["armor"].get("equipped", false) and eva_bonus != 0):
			return "Bônus de EVA da armadura inválido."
		for bonus in [equipment["weapon"].get("attack_bonus"), equipment["armor"].get("defense_bonus"), equipment["armor"].get("ranged_defense_bonus")]:
			if not _number(bonus, 0, 999) or float(bonus) != floorf(float(bonus)):
				return "Bônus de equipamento fora da faixa."
	if not config.get("action") is Dictionary or not config.get("settings") is Dictionary:
		return "Ação ou configuração ausente."
	var action = config.get("action", {})
	if not action.get("evasion_allowed") is bool:
		return "Permissão de esquiva inválida."
	if action.get("damage_type", "") not in ["physical", "magical"] or not _number(action.get("power"), 0, 10) or not _number(action.get("mp_cost"), 0, 999):
		return "Ação inválida."
	if action.get("effect_type", "damage") not in ["damage", "affliction"]:
		return "Tipo de efeito inválido."
	if is_affliction(config):
		if action["damage_type"] != "magical" or action["power"] != 0 or action.get("affliction_id", "") not in ["poison", "slow", "confusion", "fear"] or action.get("resistance_stat", "") not in ["vigor", "intelligence"]:
			return "Magia de aflição inválida: somente aplicação, sem dano direto."
	if action.get("physical_mode", "weapon") not in ["weapon", "melee", "ranged"]:
		return "Modalidade física inválida."
	if config["attacker"]["mp"] < action["mp_cost"]:
		return "MP insuficiente para esta ação."
	if config["attacker"]["side"] == "ally":
		var weapon = config.get("weapon", {})
		if not Equipment.can_equip(config["attacker"], weapon, "weapon"):
			return "Arma exclusiva ou inválida para este personagem."
		if not _number(weapon.get("critical_chance"), 0, 100) or not _number(weapon.get("critical_multiplier"), 1, 10):
			return "Arma de teste inválida."
	if not _number(config["attacker"].get("unarmed_critical_multiplier", 2.0), 1, 10):
		return "Crítico próprio inválido."
	var settings = config.get("settings", {})
	for field in ["item_bonus", "buff_bonus"]:
		if not _number(settings.get(field), -100, 100):
			return "Modificador de chance inválido."
	if not _number(settings.get("crit_per_point"), 0, 10) or not _number(settings.get("variation_percent"), 0, 100):
		return "Parâmetro experimental inválido."
	if settings.get("critical_mode", "") not in ["rolled", "off", "forced"]:
		return "Modo de crítico inválido."
	return ""

static func is_affliction(config: Dictionary) -> bool:
	return config["action"].get("effect_type", "damage") == "affliction"

static func application_resistance(config: Dictionary) -> Dictionary:
	var stat: String = config["action"]["resistance_stat"]
	var specific = float(config["target"][stat])
	var magic_defense = float(config["target"]["magic_defense"])
	return {"stat": stat, "specific": specific, "magic_defense": magic_defense, "total": magic_defense + specific}

static func application_chance(config: Dictionary) -> float:
	if not is_affliction(config):
		return 0.0
	var magic = float(config["attacker"]["magic_power"])
	var resistance: float = application_resistance(config)["total"]
	return 100.0 * magic / (magic + resistance)

static func damage_stats(config: Dictionary) -> Dictionary:
	if is_affliction(config):
		var stat: String = config["action"]["resistance_stat"]
		return {"mode": "affliction", "attack_stat": "magic_power", "defense_stat": stat, "additional_defense_stat": "magic_defense", "attack_label": "MAG", "defense_label": "DEF M + VIG" if stat == "vigor" else "DEF M + INT"}
	if config["action"]["damage_type"] == "magical":
		return {"mode": "magical", "attack_stat": "magic_power", "defense_stat": "magic_defense", "attack_label": "MAG", "defense_label": "DEF M"}
	var mode: String = config["action"].get("physical_mode", "weapon")
	if mode == "weapon":
		mode = Equipment.attack_mode(config.get("weapon", {})) if config["attacker"]["side"] == "ally" else "melee"
	return {"mode": mode, "attack_stat": "ranged_attack" if mode == "ranged" else "physical_attack", "defense_stat": "ranged_defense" if mode == "ranged" else "physical_defense", "attack_label": "ATQ D" if mode == "ranged" else "ATQ F", "defense_label": "DEF D" if mode == "ranged" else "DEF F"}

static func base_damage(config: Dictionary) -> Dictionary:
	var source = damage_stats(config)
	var attack: float = config["attacker"][source["attack_stat"]]
	var defense: float = config["target"][source["defense_stat"]]
	if is_affliction(config):
		defense = application_resistance(config)["total"]
	var power: float = config["action"]["power"]
	var ratio = attack / (attack + defense) if attack > 0 else 0.0
	return {"mode": source["mode"], "attack_stat": source["attack_stat"], "defense_stat": source["defense_stat"], "attack": attack, "defense": defense, "power": power,
		"ratio": ratio, "unprotected": 0.0 if is_affliction(config) else attack * power, "base": 0.0 if is_affliction(config) else attack * power * ratio}

static func critical_source(config: Dictionary) -> Dictionary:
	var attacker: Dictionary = config["attacker"]
	if attacker["side"] == "ally" and config.get("weapon", {}).get("equipped", true):
		var weapon: Dictionary = config.get("weapon", {})
		return {"kind": "weapon", "name": weapon.get("name", "Arma de teste"), "chance_bonus": weapon.get("critical_chance", 0.0), "multiplier": weapon.get("critical_multiplier", 2.0)}
	return {"kind": "innate" if attacker["side"] == "enemy" else "unarmed", "name": "Crítico próprio de teste", "chance_bonus": 0.0, "multiplier": attacker.get("unarmed_critical_multiplier", 2.0)}

static func critical_chance(config: Dictionary) -> float:
	if config["action"]["damage_type"] != "physical":
		return 0.0
	var settings: Dictionary = config["settings"]
	return clampf(float(config["attacker"]["critical_base"]) * settings["crit_per_point"] + critical_source(config)["chance_bonus"] + settings["item_bonus"] + settings["buff_bonus"], 0.0, 100.0)

static func evasion_chance(config: Dictionary) -> float:
	return float(config["target"]["evasion_base"]) if config["action"].get("evasion_allowed", false) else 0.0

static func sample(config: Dictionary, variation_roll: float, critical_roll: float, evasion_roll: float = 1.0, affliction_roll: float = 1.0) -> Dictionary:
	var base = base_damage(config)
	var evade_chance = evasion_chance(config)
	var evaded = evade_chance >= 100.0 or (evade_chance > 0.0 and evasion_roll * 100.0 < evade_chance)
	if is_affliction(config):
		var chance = application_chance(config)
		var resistance = application_resistance(config)
		var applied = not evaded and affliction_roll * 100.0 < chance
		return {"base": base, "variation_roll": variation_roll, "variation_factor": 1.0,
			"evasion_roll": evasion_roll, "evasion_chance": evade_chance, "evaded": evaded,
			"critical_roll": critical_roll, "chance": 0.0, "critical": false,
			"critical_multiplier": 1.0, "varied": 0.0, "raw": 0.0, "damage": 0, "hp_removed": 0,
			"hp_before": int(config["target"]["hp"]), "hp_after": int(config["target"]["hp"]),
			"mp_before": int(config["attacker"]["mp"]), "mp_after": int(config["attacker"]["mp"] - config["action"]["mp_cost"]),
			"outcome": "evaded" if evaded else "applied" if applied else "resisted",
			"affliction": {"id": config["action"]["affliction_id"], "resistance_stat": base["defense_stat"],
				"magic_power": base["attack"], "resistance": base["defense"], "chance": chance,
				"specific_resistance": resistance["specific"], "magic_defense": resistance["magic_defense"],
				"combined_resistance": resistance["total"], "resistance_formula": "magic_defense + " + resistance["stat"],
				"total_chance": (1.0 - evade_chance / 100.0) * chance,
				"roll": affliction_roll, "tested": not evaded, "applied": applied, "resisted": not evaded and not applied}}
	var settings: Dictionary = config["settings"]
	var span = float(settings["variation_percent"]) / 100.0 if settings.get("variation_enabled", false) else 0.0
	var factor = lerpf(1.0 - span, 1.0 + span, clampf(variation_roll, 0.0, 1.0))
	var chance = critical_chance(config)
	var critical = false
	if not evaded and config["action"]["damage_type"] == "physical" and config["action"].get("critical_allowed", false):
		match settings["critical_mode"]:
			"forced": critical = true
			"rolled": critical = chance >= 100.0 or (chance > 0.0 and critical_roll * 100.0 < chance)
	var multiplier = float(critical_source(config)["multiplier"]) if critical else 1.0
	var varied: float = 0.0 if evaded else base["base"] * factor
	var raw: float = varied * multiplier
	var damage = 0 if evaded else maxi(1, roundi(raw))
	var removed = mini(damage, int(config["target"]["hp"]))
	return {"base": base, "variation_roll": variation_roll, "variation_factor": factor,
		"evasion_roll": evasion_roll, "evasion_chance": evade_chance, "evaded": evaded,
		"critical_roll": critical_roll, "chance": chance, "critical": critical,
		"critical_multiplier": multiplier, "varied": varied, "raw": raw,
		"damage": damage, "hp_removed": removed,
		"hp_before": int(config["target"]["hp"]), "hp_after": int(config["target"]["hp"]) - removed,
		"mp_before": int(config["attacker"]["mp"]), "mp_after": int(config["attacker"]["mp"] - config["action"]["mp_cost"])}

static func run_batch(config: Dictionary, count: int, random_seed: int, rng_state: Dictionary = {}) -> Dictionary:
	var error = validate(config)
	if not error.is_empty():
		return {"error": error}
	if count not in ALLOWED_COUNTS:
		return {"error": "Quantidade permitida: 1, 10, 100 ou 1000."}
	var variance_rng = RandomNumberGenerator.new()
	var critical_rng = RandomNumberGenerator.new()
	var evasion_rng = RandomNumberGenerator.new()
	var affliction_rng = RandomNumberGenerator.new()
	variance_rng.seed = random_seed ^ 0x5a4f3d2c
	critical_rng.seed = random_seed ^ 0x27d4eb2d
	evasion_rng.seed = random_seed ^ 0x6c8e9cf5
	affliction_rng.seed = random_seed ^ 0x3b9d72a1
	if not rng_state.is_empty():
		variance_rng.state = rng_state["variance"]
		critical_rng.state = rng_state["critical"]
		evasion_rng.state = rng_state["evasion"]
		if rng_state.has("affliction"):
			affliction_rng.state = rng_state["affliction"]
	var before = {"variance": variance_rng.state, "critical": critical_rng.state, "evasion": evasion_rng.state, "affliction": affliction_rng.state}
	var samples: Array[Dictionary] = []
	var total = 0
	var removed_total = 0
	var critical_total = 0
	var critical_count = 0
	var evasion_count = 0
	var applied_count = 0
	var resisted_count = 0
	var minimum = 2147483647
	var maximum = 0
	for index in range(count):
		# Um sorteio por fluxo/amostra, inclusive em esquiva e ações sem aflição.
		var result = sample(config, variance_rng.randf(), critical_rng.randf(), evasion_rng.randf(), affliction_rng.randf())
		if result.has("affliction"):
			applied_count += int(result["affliction"]["applied"])
			resisted_count += int(result["affliction"]["resisted"])
		result["index"] = index + 1
		samples.append(result)
		total += result["damage"]
		removed_total += result["hp_removed"]
		minimum = mini(minimum, result["damage"])
		maximum = maxi(maximum, result["damage"])
		if result["evaded"]:
			evasion_count += 1
		if result["critical"]:
			critical_count += 1
			critical_total += result["damage"]
	var hit_count = count - evasion_count
	var normal_count = 0 if is_affliction(config) else hit_count - critical_count
	var buckets: Array[Dictionary] = []
	var width = maxi(1, ceili(float(maximum - minimum + 1) / 12.0))
	for low in range(minimum, maximum + 1, width):
		buckets.append({"from": low, "to": mini(maximum, low + width - 1), "normal": 0, "critical": 0, "evaded": 0, "count": 0})
	for result in samples:
		var bucket: Dictionary = buckets[int((result["damage"] - minimum) / width)]
		bucket["count"] += 1
		bucket["evaded" if result["evaded"] else "critical" if result["critical"] else "normal"] += 1
	if is_affliction(config):
		buckets = [{"label": "Esquivou", "count": evasion_count}, {"label": "Resistiu", "count": resisted_count}, {"label": "Aplicou", "count": applied_count}]
	return {"error": "", "snapshot": config.duplicate(true), "count": count, "seed": random_seed,
		"rng_before": before, "rng_after": {"variance": variance_rng.state, "critical": critical_rng.state, "evasion": evasion_rng.state, "affliction": affliction_rng.state},
		"result_type": "affliction" if is_affliction(config) else "damage",
		"applied_count": applied_count, "resisted_count": resisted_count,
		"application_frequency": float(applied_count) * 100.0 / count, "resistance_frequency": float(resisted_count) * 100.0 / count,
		"application_hit_frequency": float(applied_count) * 100.0 / hit_count if hit_count else 0.0,
		"application_chance": application_chance(config), "total_application_chance": (1.0 - evasion_chance(config) / 100.0) * application_chance(config),
		"samples": samples, "minimum": minimum, "maximum": maximum, "mean": float(total) / count,
		"total": total, "hp_removed_total": removed_total, "critical_count": critical_count,
		"critical_frequency": float(critical_count) * 100.0 / count,
		"evasion_count": evasion_count, "evasion_frequency": float(evasion_count) * 100.0 / count,
		"evasion_chance": evasion_chance(config), "hit_count": hit_count, "normal_count": normal_count,
		"critical_hit_frequency": float(critical_count) * 100.0 / hit_count if hit_count else 0.0,
		"normal_mean": float(total - critical_total) / normal_count if normal_count else 0.0,
		"critical_mean": float(critical_total) / critical_count if critical_count else 0.0,
		"chance": critical_chance(config), "histogram": buckets}
