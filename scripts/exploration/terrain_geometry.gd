extends RefCounted
## Relevo determinístico 2.5D, sem física/gravity nem camadas sobrepostas.
## A rampa fica na borda sul do platô; sobe caminhando para o norte.

static func rect(value: Array) -> Rect2:
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

static func collision_rects(feature: Dictionary) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var area = rect(feature["rect"])
	if feature["kind"] == "forest" or (feature["kind"] == "hill" and not feature.has("ramp")):
		result.append(area)
	elif feature["kind"] == "hill":
		var ramp = rect(feature["ramp"]["rect"])
		var edge = float(feature.get("cliff_thickness", 8))
		# Bordas fechadas: não é possível subir de lado ou saltar do platô.
		result.append(Rect2(area.position, Vector2(area.size.x, edge)))
		result.append(Rect2(area.position, Vector2(edge, area.size.y)))
		result.append(Rect2(area.end.x - edge, area.position.y, edge, area.size.y))
		if ramp.position.x > area.position.x:
			result.append(Rect2(area.position.x, area.end.y - edge, ramp.position.x - area.position.x, edge))
		if ramp.end.x < area.end.x:
			result.append(Rect2(ramp.end.x, area.end.y - edge, area.end.x - ramp.end.x, edge))
		result.append(Rect2(ramp.position, Vector2(edge, ramp.size.y)))
		result.append(Rect2(ramp.end.x - edge, ramp.position.y, edge, ramp.size.y))
	return result

static func elevation_at(features: Array, position: Vector2) -> float:
	for feature in features:
		if feature["kind"] != "hill":
			continue
		var height = float(feature.get("elevation", 48))
		if rect(feature["rect"]).has_point(position):
			return height
		if feature.has("ramp"):
			var ramp = rect(feature["ramp"]["rect"])
			if ramp.has_point(position):
				return height * clampf((ramp.end.y - position.y) / ramp.size.y, 0, 1)
	return 0.0

static func valid_feature(feature: Dictionary, radius: float) -> bool:
	if feature["kind"] != "hill":
		return not feature.has("ramp") and not feature.has("elevation")
	for value in [feature.get("elevation", 48), feature.get("cliff_thickness", 8)]:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) <= 0:
			return false
	var area = rect(feature["rect"])
	var edge = float(feature.get("cliff_thickness", 8))
	if minf(area.size.x, area.size.y) <= edge * 2 + radius * 2:
		return false
	if not feature.has("ramp"):
		return true
	var definition = feature["ramp"]
	if not definition is Dictionary or not definition.get("rect") is Array or definition["rect"].size() != 4:
		return false
	for value in definition["rect"]:
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	var ramp = rect(definition["rect"])
	return is_equal_approx(ramp.position.y, area.end.y) and ramp.size.y > 0 \
		and ramp.size.x > 2 * (edge + radius) \
		and ramp.position.x >= area.position.x + edge and ramp.end.x <= area.end.x - edge
