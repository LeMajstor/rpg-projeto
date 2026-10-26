extends RefCounted
## A rota altera somente a posição lógica. A animação não toca neste estado.
const Rhythm = preload("res://scripts/combat/route_rhythm.gd")
const Behavior = preload("res://scripts/combat/route_behavior.gd")

static func create(points_data: Array, speed: float, options: Dictionary = {}) -> Dictionary:
	var points: Array[Vector2] = []
	for point in points_data:
		points.append(Vector2(float(point[0]), float(point[1])))
	var controls = points.duplicate()
	var curve: String = options.get("curve", "linear")
	var closed: bool = options.get("rhythm", {}).get("pattern", "loop") not in ["ping_pong", "sequence"]
	if options.has("behavior"):
		closed = options.get("kind", "ground") == "air"
	if curve == "smooth" and points.size() >= 3:
		points = _smooth_points(points, clampi(int(options.get("samples_per_segment", 24)), 8, 128), closed)
	elif curve == "ellipse":
		points = _ellipse_points(options)
		if not closed and not points.is_empty():
			points.append(points[0])
	var length = 0.0
	for index in range(points.size() if closed else maxi(0, points.size() - 1)):
		length += points[index].distance_to(points[(index + 1) % points.size()])
	var state = {"points": points, "control_points": controls, "segment": 0, "progress": 0.0,
		"direction": int(options.get("direction", 1)), "speed": maxf(0.0, speed),
		"length": length, "curve": curve,
		"kind": options.get("kind", "static" if speed <= 0 else "ground")}
	if options.has("behavior"):
		state["closed"] = closed
		state["behavior"] = Behavior.create(length, closed, state["speed"], options["behavior"], int(options.get("seed", 0)))
		state["presentation"] = options.get("presentation", {}).duplicate(true)
		state["presentation_time"] = 0.0
	elif options.has("rhythm"):
		state["closed"] = closed
		state["rhythm"] = Rhythm.create(length, state["speed"], options["rhythm"])
		state["presentation"] = options.get("presentation", {}).duplicate(true)
		state["presentation_time"] = 0.0
	return state

static func _smooth_points(controls: Array[Vector2], samples: int, closed: bool = true) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var count = controls.size()
	for index in range(count if closed else count - 1):
		var a = controls[(index - 1 + count) % count] if closed else controls[maxi(0, index - 1)]
		var b = controls[index]
		var c = controls[(index + 1) % count]
		var d = controls[(index + 2) % count] if closed else controls[mini(count - 1, index + 2)]
		for sample in range(samples):
			var t = float(sample) / samples
			result.append(0.5 * (2 * b + (-a + c) * t
				+ (2 * a - 5 * b + 4 * c - d) * t * t
				+ (-a + 3 * b - 3 * c + d) * t * t * t))
	if not closed:
		result.append(controls.back())
	return result

static func _ellipse_points(options: Dictionary) -> Array[Vector2]:
	var center_data = options.get("center", [0, 0])
	var radii_data = options.get("radii", [0, 0])
	var center = Vector2(float(center_data[0]), float(center_data[1]))
	var radii = Vector2(absf(float(radii_data[0])), absf(float(radii_data[1])))
	var count = clampi(int(options.get("samples", 128)), 32, 512)
	var direction = -1.0 if int(options.get("direction", 1)) < 0 else 1.0
	var result: Array[Vector2] = []
	for index in range(count):
		var angle = float(options.get("start_angle", 0.0)) + TAU * float(index) / count * direction
		result.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return result

static func position_at(state: Dictionary, fallback: Vector2) -> Vector2:
	var points = state["points"]
	if points.is_empty():
		return fallback
	if points.size() == 1:
		return points[0]
	var index: int = state["segment"]
	var next = (index + 1) % points.size() if state.get("closed", true) else mini(index + 1, points.size() - 1)
	return points[index].lerp(points[next], state["progress"])

static func advance(state: Dictionary, delta: float) -> void:
	if state.has("behavior"):
		if is_finite(delta) and delta > 0.0 and state["speed"] > 0.0:
			Behavior.advance(state["behavior"], delta)
			state["presentation_time"] += delta
			_seek_distance(state, state["behavior"]["distance"])
		return
	if state.has("rhythm"):
		if is_finite(delta) and delta > 0.0 and state["speed"] > 0.0:
			Rhythm.advance(state["rhythm"], delta)
			state["presentation_time"] += delta
			_seek_distance(state, state["rhythm"]["distance"])
		return
	var points = state["points"]
	if points.size() < 2 or state["speed"] <= 0.0 or delta <= 0.0:
		return
	var distance: float = state["speed"] * delta
	# Voltas completas não mudam segmento/progresso; evita iteração excessiva.
	var total_length: float = state.get("length", 0.0)
	if total_length <= 0.00001:
		return
	if distance >= total_length:
		distance = fmod(distance, total_length)
	var zero_segments = 0
	while distance > 0.0:
		var index: int = state["segment"]
		var length: float = points[index].distance_to(points[(index + 1) % points.size()])
		if length < 0.00001:
			state["segment"] = (index + 1) % points.size()
			state["progress"] = 0.0
			zero_segments += 1
			if zero_segments >= points.size():
				return
			continue
		zero_segments = 0
		var remaining: float = length * (1.0 - state["progress"])
		if distance < remaining:
			state["progress"] += distance / length
			return
		distance -= remaining
		state["segment"] = (index + 1) % points.size()
		state["progress"] = 0.0

static func _seek_distance(state: Dictionary, distance: float) -> void:
	var points: Array = state["points"]
	var count = points.size() if state["closed"] else maxi(0, points.size() - 1)
	distance = clampf(distance, 0.0, state["length"])
	if count > 0 and distance >= state["length"]:
		state["segment"] = count - 1
		state["progress"] = 1.0
		return
	for index in range(count):
		var length: float = points[index].distance_to(points[(index + 1) % points.size()])
		if distance <= length and length > 0.000001:
			state["segment"] = index
			state["progress"] = distance / length
			return
		distance -= length

static func presentation_offset(state: Dictionary) -> Vector2:
	var options: Dictionary = state.get("presentation", {})
	var amplitude = float(options.get("bob_amplitude", 0.0))
	var period = maxf(0.1, float(options.get("bob_period", 2.0)))
	return Vector2(0, sin(float(state.get("presentation_time", 0.0)) * TAU / period) * amplitude)

static func travel_direction(state: Dictionary) -> Vector2:
	var points: Array = state["points"]
	if points.size() < 2:
		return Vector2.ZERO
	var index: int = state["segment"]
	var next = (index + 1) % points.size() if state.get("closed", true) else mini(index + 1, points.size() - 1)
	return points[index].direction_to(points[next]) * float(state.get("behavior", state.get("rhythm", {})).get("direction", 1))
