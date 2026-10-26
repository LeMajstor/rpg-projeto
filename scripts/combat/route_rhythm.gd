extends RefCounted
## Cronograma determinístico por distância. Não conhece atores, ATB ou animações.
const EPS = 0.000001

static func create(length: float, speed: float, config: Dictionary) -> Dictionary:
	var state = {"phases": [], "cycle_duration": 0.0, "phase_index": 0,
		"phase_elapsed": 0.0, "distance": 0.0, "current_speed": 0.0,
		"movement_phase": "static", "pause_remaining": 0.0, "direction": 1,
		"initial_pause_remaining": 0.0}
	if not is_finite(length) or not is_finite(speed) or length <= EPS or speed <= EPS:
		return state
	var pattern = config.get("pattern", "loop")
	if pattern not in ["loop", "ping_pong", "sequence"]:
		return state
	for key in ["acceleration", "deceleration", "turn_pause", "initial_pause"]:
		if not _nonnegative(config.get(key, 0.0)):
			return state
	var steps = config.get("steps", [{"to": 1.0}])
	if not steps is Array or steps.is_empty():
		return state
	var previous = 0.0
	var legs: Array = []
	for step in steps:
		if not step is Dictionary:
			return state
		for key in ["to", "speed_scale", "end_speed_scale", "pause", "return_speed_scale", "return_pause"]:
			if key.begins_with("return_") and not step.has(key):
				continue
			if not _nonnegative(step.get(key, 1.0 if key == "speed_scale" else 0.0)):
				return state
		var target = float(step.get("to", 0.0))
		if target < 0.0 or target > 1.0 or is_equal_approx(target, previous) or (pattern != "sequence" and target < previous):
			return state
		if float(step.get("speed_scale", 1.0)) <= EPS or float(step.get("return_speed_scale", 1.0)) <= EPS:
			return state
		legs.append({"from": previous, "to": target, "speed_scale": step.get("speed_scale", 1.0),
			"end_speed_scale": step.get("end_speed_scale", 0.0), "pause": step.get("pause", 0.0),
			"return_speed_scale": step.get("return_speed_scale", step.get("speed_scale", 1.0)),
			"return_pause": step.get("return_pause", step.get("pause", 0.0))})
		previous = target
	if previous != (0.0 if pattern == "sequence" else 1.0):
		return state
	if pattern == "ping_pong":
		# Mesmos marcos geométricos; ritmo de retorno pode ser diferente.
		for index in range(legs.size() - 1, -1, -1):
			var leg: Dictionary = legs[index]
			legs.append({"from": leg["to"], "to": leg["from"], "speed_scale": leg["return_speed_scale"],
				"end_speed_scale": 0.0, "pause": legs[index - 1]["return_pause"] if index > 0 else config.get("turn_pause", 0.0)})
	if pattern == "sequence":
		# Reversões, inclusive na emenda, sempre freiam até zero.
		for index in range(legs.size()):
			var leg: Dictionary = legs[index]
			var next: Dictionary = legs[(index + 1) % legs.size()]
			if signf(leg["to"] - leg["from"]) != signf(next["to"] - next["from"]):
				leg["end_speed_scale"] = 0.0
	var last: Dictionary = legs.back()
	var start_speed = 0.0 if pattern == "ping_pong" or float(last["pause"]) > 0 else speed * float(last["end_speed_scale"])
	var phases: Array = []
	for leg in legs:
		var distance = absf(float(leg["to"]) - float(leg["from"])) * length
		var cruise = speed * float(leg["speed_scale"])
		var finish_speed = 0.0 if pattern == "ping_pong" or float(leg["pause"]) > 0 else speed * float(leg["end_speed_scale"])
		var accelerating = float(config.get("acceleration", 0.4))
		var decelerating = float(config.get("deceleration", 0.4))
		# Zero só é permitido se a mudança de velocidade também for zero.
		if not is_equal_approx(start_speed, cruise):
			accelerating = maxf(accelerating, EPS)
		if not is_equal_approx(cruise, finish_speed):
			decelerating = maxf(decelerating, EPS)
		var ramp_distance = (start_speed + cruise) * accelerating * 0.5 + (cruise + finish_speed) * decelerating * 0.5
		if ramp_distance > distance:
			var factor = distance / ramp_distance
			accelerating *= factor
			decelerating *= factor
			ramp_distance = distance
		var cruising = maxf(0.0, (distance - ramp_distance) / cruise)
		var origin = float(leg["from"]) * length
		var direction = 1 if float(leg["to"]) > float(leg["from"]) else -1
		origin = _append_phase(phases, origin, direction, accelerating, start_speed, cruise)
		origin = _append_phase(phases, origin, direction, cruising, cruise, cruise)
		_append_phase(phases, origin, direction, decelerating, cruise, finish_speed)
		if float(leg["pause"]) > EPS:
			phases.append({"origin": float(leg["to"]) * length, "direction": direction,
				"duration": float(leg["pause"]), "v0": 0.0, "v1": 0.0, "label": "pause"})
		start_speed = finish_speed
	state["phases"] = phases
	for phase in phases:
		state["cycle_duration"] += phase["duration"]
	state["initial_pause_remaining"] = float(config.get("initial_pause", 0.0))
	_sample(state)
	return state

static func _nonnegative(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0

static func _append_phase(phases: Array, origin: float, direction: int, duration: float, v0: float, v1: float) -> float:
	if duration > 0.0:
		var label = "cruise" if is_equal_approx(v0, v1) else ("accelerate" if v1 > v0 else "decelerate")
		phases.append({"origin": origin, "direction": direction, "duration": duration,
			"v0": v0, "v1": v1, "label": label})
	return origin + direction * (v0 + v1) * duration * 0.5

static func advance(state: Dictionary, delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or state["phases"].is_empty():
		return
	var delay: float = minf(delta, state["initial_pause_remaining"])
	state["initial_pause_remaining"] -= delay
	delta -= delay
	# Um passo enorme não precisa visitar repetidamente o mesmo cronograma.
	delta = fmod(delta, state["cycle_duration"])
	while delta > 0.0:
		var phase: Dictionary = state["phases"][state["phase_index"]]
		var remaining: float = phase["duration"] - state["phase_elapsed"]
		if delta < remaining:
			state["phase_elapsed"] += delta
			break
		delta -= remaining
		state["phase_elapsed"] = 0.0
		state["phase_index"] = (state["phase_index"] + 1) % state["phases"].size()
	_sample(state)

static func _sample(state: Dictionary) -> void:
	if state["phases"].is_empty():
		return
	if state["initial_pause_remaining"] > 0.0:
		state["movement_phase"] = "initial_pause"
		state["pause_remaining"] = state["initial_pause_remaining"]
		state["current_speed"] = 0.0
		return
	var phase: Dictionary = state["phases"][state["phase_index"]]
	var elapsed: float = state["phase_elapsed"]
	var duration: float = phase["duration"]
	var blend = 0.5 * (1.0 - cos(PI * elapsed / duration))
	state["current_speed"] = lerpf(phase["v0"], phase["v1"], blend)
	# Integral da velocidade: resultado independe da divisão de tempo em frames.
	var distance: float = phase["v0"] * elapsed + (phase["v1"] - phase["v0"]) * 0.5 * (elapsed - duration / PI * sin(PI * elapsed / duration))
	state["distance"] = phase["origin"] + phase["direction"] * distance
	state["direction"] = phase["direction"]
	state["movement_phase"] = phase["label"]
	state["pause_remaining"] = duration - elapsed if phase["label"] == "pause" else 0.0
