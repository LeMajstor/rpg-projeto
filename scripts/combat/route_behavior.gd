extends RefCounted
## Sorteios por participante, limitados à distância da rota. Estado só com valores copiáveis.
const Rhythm = preload("res://scripts/combat/route_rhythm.gd")
const EPS = 0.000001

static func create(length: float, closed: bool, speed: float, config: Dictionary, seed_value: int) -> Dictionary:
	var random = RandomNumberGenerator.new()
	random.seed = seed_value
	var state = {"config": config.duplicate(true), "length": length, "closed": closed,
		"speed": speed, "seed": seed_value, "rng_state": random.state,
		"phases": [], "phase_index": 0, "phase_elapsed": 0.0,
		"distance": 0.0, "direction": 1, "pending_direction": 1,
		"current_speed": 0.0, "movement_phase": "static", "pause_remaining": 0.0,
		"initial_pause_remaining": 0.0, "decision_count": 0, "pause_count": 0,
		"reversal_count": 0, "history": [], "elapsed": 0.0}
	if not valid_config(config) or not is_finite(length) or not is_finite(speed) or length <= EPS or speed <= EPS:
		return state
	_plan(state, true)
	_sample(state)
	return state

static func valid_config(config: Dictionary) -> bool:
	for key in ["speed_scale", "travel_seconds", "pause_seconds", "initial_pause"]:
		var bounds = config.get(key)
		if not bounds is Array or bounds.size() != 2:
			return false
		for value in bounds:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0:
				return false
		if float(bounds[1]) < float(bounds[0]):
			return false
		if key != "initial_pause" and float(bounds[0]) <= EPS:
			return false
	for key in ["acceleration", "deceleration"]:
		var value = config.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) <= EPS:
			return false
	for key in ["pause_chance", "reverse_chance"]:
		var value = config.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0 or float(value) > 1:
			return false
	return true

static func _range(random: RandomNumberGenerator, bounds: Array) -> float:
	return random.randf_range(float(bounds[0]), float(bounds[1]))

static func _plan(state: Dictionary, initial: bool = false) -> void:
	var config: Dictionary = state["config"]
	var random = RandomNumberGenerator.new()
	random.seed = state["seed"]
	random.state = state["rng_state"]
	var direction: int = state["direction"]
	# Consumir os mesmos sorteios em cada decisão, sem usar ID/configuração de preset.
	var reverse_draw = random.randf()
	var pause_draw = random.randf()
	var pause = _range(random, config["initial_pause"] if initial else config["pause_seconds"])
	var speed: float = state["speed"] * _range(random, config["speed_scale"])
	var distance = speed * _range(random, config["travel_seconds"])
	var origin: float = state["distance"]
	var reverse = not initial and not state["closed"] and reverse_draw < float(config["reverse_chance"])
	if not state["closed"]:
		if origin <= EPS:
			reverse = direction != 1
		elif origin >= float(state["length"]) - EPS:
			reverse = direction != -1
	if reverse:
		direction *= -1
		state["reversal_count"] += 1
	if not initial and not reverse and pause_draw >= float(config["pause_chance"]):
		pause = 0.0
	if not state["closed"]:
		distance = minf(distance, float(state["length"]) - origin if direction > 0 else origin)
	var phases: Array = []
	if pause > EPS:
		phases.append({"origin": origin, "direction": state["direction"], "duration": pause,
			"v0": 0.0, "v1": 0.0, "label": "initial_pause" if initial else "pause"})
		state["pause_count"] += 1
	var accelerating = float(config["acceleration"])
	var decelerating = float(config["deceleration"])
	var ramp_distance = speed * (accelerating + decelerating) * 0.5
	if ramp_distance > distance:
		var factor = distance / ramp_distance
		accelerating *= factor
		decelerating *= factor
		ramp_distance = distance
	var cruising = maxf(0.0, (distance - ramp_distance) / speed)
	origin = Rhythm._append_phase(phases, origin, direction, accelerating, 0.0, speed)
	origin = Rhythm._append_phase(phases, origin, direction, cruising, speed, speed)
	Rhythm._append_phase(phases, origin, direction, decelerating, speed, 0.0)
	state["phases"] = phases
	state["phase_index"] = 0
	state["phase_elapsed"] = 0.0
	state["pending_direction"] = direction
	state["rng_state"] = random.state
	state["decision_count"] += 1
	state["history"].append({"time": state["elapsed"], "direction": direction,
		"reverse": reverse, "pause": pause, "distance": distance, "speed": speed})
	if state["history"].size() > 32:
		state["history"].pop_front()

static func advance(state: Dictionary, delta: float) -> void:
	if not is_finite(delta) or delta <= 0 or state["phases"].is_empty():
		return
	while delta > 0.0:
		var phase: Dictionary = state["phases"][state["phase_index"]]
		var remaining: float = phase["duration"] - state["phase_elapsed"]
		var consumed = minf(delta, remaining)
		state["phase_elapsed"] += consumed
		state["elapsed"] += consumed
		delta -= consumed
		_sample(state)
		if consumed < remaining:
			break
		state["phase_elapsed"] = 0.0
		state["phase_index"] += 1
		if state["phase_index"] >= state["phases"].size():
			_plan(state)
		_sample(state)

static func _sample(state: Dictionary) -> void:
	# Reutiliza a mesma integral/cosseno das rotas anteriores, sem somar erro por frame.
	Rhythm._sample(state)
	if state["movement_phase"] == "initial_pause":
		state["pause_remaining"] = state["phases"][state["phase_index"]]["duration"] - state["phase_elapsed"]
	if state["closed"]:
		state["distance"] = fposmod(state["distance"], state["length"])
	else:
		state["distance"] = clampf(state["distance"], 0.0, state["length"])
