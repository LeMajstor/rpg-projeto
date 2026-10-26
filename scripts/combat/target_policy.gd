extends RefCounted
## Perfis independem de posição, movimento e apresentação.

static func weights(actor: Dictionary, candidates: Array, profile: Dictionary) -> Array[float]:
	var result: Array[float] = []
	for target in candidates:
		var weight = 1.0
		match profile.get("kind", "uniform"):
			"injured":
				weight += float(profile.get("strength", 0.0)) * (1.0 - float(target["hp"]) / target["max_hp"])
			"focus":
				if target["id"] == actor.get("last_target", ""):
					weight += float(profile.get("strength", 0.0))
			"retaliate":
				if target["id"] == actor.get("last_attacker", ""):
					weight += float(profile.get("strength", 0.0))
			"max_mp":
				weight += float(profile.get("strength", 0.0)) * float(target["max_mp"])
		if not is_finite(weight) or weight <= 0.0:
			weight = 1.0
		result.append(weight)
	return result

static func pick_index(values: Array, rng: RandomNumberGenerator) -> int:
	if values.is_empty():
		return -1
	var safe: Array[float] = []
	var total = 0.0
	for value in values:
		var weight = float(value)
		if not is_finite(weight) or weight <= 0.0:
			weight = 0.0
		safe.append(weight)
		total += weight
	if not is_finite(total) or total <= 0.0:
		return rng.randi_range(0, values.size() - 1)
	var draw = rng.randf() * total
	var accumulated = 0.0
	for index in range(safe.size()):
		accumulated += safe[index]
		if draw < accumulated:
			return index
	return safe.size() - 1
