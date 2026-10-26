extends RefCounted
## Apenas apresentação temporária: não recebe nem modifica rota, HP ou ATB.

static func create(origin: Vector2, aim: Vector2, melee: bool, settings: Dictionary) -> Dictionary:
	var impact = clampf(float(settings.get("impact_fraction", 0.5)), 0.05, 0.9)
	var hold = maxf(0.01, float(settings.get("melee_impact_hold", 0.15)))
	return {"origin": origin, "contact": origin, "contact_locked": false,
		"melee": melee, "impact": impact, "return_start": minf(0.98, impact + hold),
		"stop_distance": maxf(0, float(settings.get("melee_stop_distance", 44))),
		"gesture_offset": origin.direction_to(aim) * minf(100, origin.distance_to(aim) * 0.4),
		"phase": "approach" if melee else "gesture", "effect_strength": 0.0}

static func sample(state: Dictionary, progress: float, target_position: Vector2) -> Vector2:
	var t = clampf(progress, 0.0, 1.0)
	state["effect_strength"] = 0.0
	if t >= 1.0:
		state["phase"] = "complete"
		return Vector2.ZERO
	if not state["melee"]:
		state["phase"] = "gesture"
		if t >= state["impact"]:
			state["effect_strength"] = clampf(1.0 - (t - state["impact"]) / 0.2, 0.0, 1.0)
		return state["gesture_offset"] * sin(t * PI)
	var origin: Vector2 = state["origin"]
	if not state["contact_locked"]:
		var distance = origin.distance_to(target_position)
		state["contact"] = origin + origin.direction_to(target_position) * maxf(0.0, distance - state["stop_distance"])
	if t < state["impact"]:
		state["phase"] = "approach"
		return (state["contact"] - origin) * _ease(t / state["impact"])
	state["contact_locked"] = true
	if t < state["return_start"]:
		state["phase"] = "impact"
		state["effect_strength"] = 1.0 - (t - state["impact"]) / (state["return_start"] - state["impact"])
		return state["contact"] - origin
	state["phase"] = "return"
	var return_progress: float = (t - state["return_start"]) / (1.0 - state["return_start"])
	return (state["contact"] - origin) * (1.0 - _ease(return_progress))

static func _ease(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
