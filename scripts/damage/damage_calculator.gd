extends RefCounted
## Fórmula experimental pura, independente do BattleModel e da renderização.
const ALLOWED_COUNTS = [1, 10, 100, 1000]
const STATS = ["hp", "mp", "ini", "physical_attack", "physical_defense", "magic_power", "magic_defense", "critical_base"]

static func stat_bounds(side: String, stat: String) -> Vector2i:
	if stat in ["ini", "critical_base"]:
		return Vector2i(1, 99)
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
	for role in config.get("equipment", {}):
		if config[role]["side"] != "ally":
			return "Monstros não usam equipamentos."
		var equipment: Dictionary = config["equipment"][role]
		for bonus in [equipment["weapon"].get("attack_bonus"), equipment["armor"].get("defense_bonus")]:
			if not _number(bonus, 0, 999) or float(bonus) != floorf(float(bonus)):
				return "Bônus de equipamento fora da faixa."
	if not config.get("action") is Dictionary or not config.get("settings") is Dictionary:
		return "Ação ou configuração ausente."
	var action = config.get("action", {})
	if action.get("damage_type", "") not in ["physical", "magical"] or not _number(action.get("power"), 0, 10) or not _number(action.get("mp_cost"), 0, 999):
		return "Ação inválida."
	if config["attacker"]["mp"] < action["mp_cost"]:
		return "MP insuficiente para esta ação."
	if config["attacker"]["side"] == "ally":
		var weapon = config.get("weapon", {})
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

static func base_damage(config: Dictionary) -> Dictionary:
	var physical: bool = config["action"]["damage_type"] == "physical"
	var attack: float = config["attacker"]["physical_attack" if physical else "magic_power"]
	var defense: float = config["target"]["physical_defense" if physical else "magic_defense"]
	var power: float = config["action"]["power"]
	var ratio = attack / (attack + defense) if attack > 0 else 0.0
	return {"attack": attack, "defense": defense, "power": power,
		"ratio": ratio, "unprotected": attack * power, "base": attack * power * ratio}

static func critical_source(config: Dictionary) -> Dictionary:
	var attacker: Dictionary = config["attacker"]
	if attacker["side"] == "ally" and config.get("weapon", {}).get("equipped", true):
		var weapon: Dictionary = config.get("weapon", {})
		return {"kind": "weapon", "name": weapon.get("name", "Arma de teste"), "chance_bonus": weapon.get("critical_chance", 0.0), "multiplier": weapon.get("critical_multiplier", 2.0)}
	return {"kind": "innate" if attacker["side"] == "enemy" else "unarmed", "name": "Crítico próprio de teste", "chance_bonus": 0.0, "multiplier": attacker.get("unarmed_critical_multiplier", 2.0)}

static func critical_chance(config: Dictionary) -> float:
	var settings: Dictionary = config["settings"]
	return clampf(float(config["attacker"]["critical_base"]) * settings["crit_per_point"] + critical_source(config)["chance_bonus"] + settings["item_bonus"] + settings["buff_bonus"], 0.0, 100.0)

static func sample(config: Dictionary, variation_roll: float, critical_roll: float) -> Dictionary:
	var base = base_damage(config)
	var settings: Dictionary = config["settings"]
	var span = float(settings["variation_percent"]) / 100.0 if settings.get("variation_enabled", false) else 0.0
	var factor = lerpf(1.0 - span, 1.0 + span, clampf(variation_roll, 0.0, 1.0))
	var chance = critical_chance(config)
	var critical = false
	if config["action"].get("critical_allowed", false):
		match settings["critical_mode"]:
			"forced": critical = true
			"rolled": critical = chance >= 100.0 or (chance > 0.0 and critical_roll * 100.0 < chance)
	var multiplier = float(critical_source(config)["multiplier"]) if critical else 1.0
	var varied: float = base["base"] * factor
	var raw: float = varied * multiplier
	var damage = maxi(1, roundi(raw))
	var removed = mini(damage, int(config["target"]["hp"]))
	return {"base": base, "variation_roll": variation_roll, "variation_factor": factor,
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
	variance_rng.seed = random_seed ^ 0x5a4f3d2c
	critical_rng.seed = random_seed ^ 0x27d4eb2d
	if not rng_state.is_empty():
		variance_rng.state = rng_state["variance"]
		critical_rng.state = rng_state["critical"]
	var before = {"variance": variance_rng.state, "critical": critical_rng.state}
	var samples: Array[Dictionary] = []
	var total = 0
	var removed_total = 0
	var critical_total = 0
	var critical_count = 0
	var minimum = 2147483647
	var maximum = 0
	for index in range(count):
		# Fluxos independentes e um sorteio de cada por amostra, inclusive nos modos fixos.
		var result = sample(config, variance_rng.randf(), critical_rng.randf())
		result["index"] = index + 1
		samples.append(result)
		total += result["damage"]
		removed_total += result["hp_removed"]
		minimum = mini(minimum, result["damage"])
		maximum = maxi(maximum, result["damage"])
		if result["critical"]:
			critical_count += 1
			critical_total += result["damage"]
	var normal_count = count - critical_count
	var buckets: Array[Dictionary] = []
	var width = maxi(1, ceili(float(maximum - minimum + 1) / 12.0))
	for low in range(minimum, maximum + 1, width):
		buckets.append({"from": low, "to": mini(maximum, low + width - 1), "normal": 0, "critical": 0, "count": 0})
	for result in samples:
		var bucket: Dictionary = buckets[int((result["damage"] - minimum) / width)]
		bucket["count"] += 1
		bucket["critical" if result["critical"] else "normal"] += 1
	return {"error": "", "snapshot": config.duplicate(true), "count": count, "seed": random_seed,
		"rng_before": before, "rng_after": {"variance": variance_rng.state, "critical": critical_rng.state},
		"samples": samples, "minimum": minimum, "maximum": maximum, "mean": float(total) / count,
		"total": total, "hp_removed_total": removed_total, "critical_count": critical_count,
		"critical_frequency": float(critical_count) * 100.0 / count,
		"normal_mean": float(total - critical_total) / normal_count if normal_count else 0.0,
		"critical_mean": float(critical_total) / critical_count if critical_count else 0.0,
		"chance": critical_chance(config), "histogram": buckets}
