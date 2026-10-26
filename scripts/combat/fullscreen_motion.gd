extends RefCounted
## Apresentação de tela inteira. Não recebe alvos, rotas, HP/MP ou ATB.

static func create(origin: Vector2, center: Vector2, move_to_center: bool, settings: Dictionary) -> Dictionary:
	var impact = clampf(float(settings.get("impact_fraction", 0.5)), 0.05, 0.9)
	var hold = maxf(0.01, float(settings.get("fullscreen_impact_hold", 0.15)))
	return {"origin": origin, "contact": center if move_to_center else origin,
		"center": center, "move_to_center": move_to_center,
		"presentation": "fullscreen", "melee": false,
		"impact": impact, "return_start": minf(0.98, impact + hold),
		"phase": "approach" if move_to_center else "stationary", "effect_strength": 0.0}

static func sample(state: Dictionary, progress: float) -> Vector2:
	var t = clampf(progress, 0.0, 1.0)
	state["effect_strength"] = 0.0
	if t >= 1:
		state["phase"] = "complete"
		return Vector2.ZERO
	var offset: Vector2 = state["contact"] - state["origin"]
	if t < state["impact"]:
		state["phase"] = "approach" if state["move_to_center"] else "stationary"
		return offset * _ease(t / state["impact"])
	if t < state["return_start"]:
		state["phase"] = "impact"
		state["effect_strength"] = 1.0 - (t - state["impact"]) / (state["return_start"] - state["impact"])
		return offset
	state["phase"] = "return" if state["move_to_center"] else "stationary"
	return offset * (1.0 - _ease((t - state["return_start"]) / (1.0 - state["return_start"])))

static func _ease(value: float) -> float:
	var t = clampf(value, 0, 1)
	return t * t * (3 - 2 * t)
