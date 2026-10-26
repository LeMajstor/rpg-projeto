extends RefCounted
## Apresentação pura: interpola uma paleta, sem controlar o relógio ou regras de área.
var _keyframes: Array[Dictionary] = []

func _init(definition: Dictionary) -> void:
	assert(valid_definition(definition), "Paleta temporal inválida")
	for frame in definition["keyframes"]:
		var rgba: Array = frame["rgba"]
		_keyframes.append({"minute": float(frame["minute"]), "color": Color(rgba[0], rgba[1], rgba[2], rgba[3])})

static func valid_definition(definition: Dictionary) -> bool:
	var frames = definition.get("keyframes")
	if not frames is Array or frames.size() < 2:
		return false
	var previous = -1.0
	for frame in frames:
		if not frame is Dictionary or not _number(frame.get("minute")):
			return false
		if frame["minute"] <= previous or frame["minute"] < 0 or frame["minute"] >= 24 * 60:
			return false
		var rgba = frame.get("rgba")
		if not rgba is Array or rgba.size() != 4:
			return false
		for component in rgba:
			if not _number(component) or component < 0 or component > 1:
				return false
		previous = float(frame["minute"])
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func overlay_at(minutes: float) -> Color:
	if not is_finite(minutes):
		return Color.TRANSPARENT
	var time = fposmod(minutes, 24 * 60)
	for index in range(_keyframes.size()):
		var first = _keyframes[index]
		var second = _keyframes[(index + 1) % _keyframes.size()]
		var finish: float = second["minute"] + (24 * 60 if index == _keyframes.size() - 1 else 0)
		var local_time = time + (24 * 60 if time < first["minute"] else 0)
		if local_time >= first["minute"] and local_time <= finish:
			return first["color"].lerp(second["color"], (local_time - first["minute"]) / (finish - first["minute"]))
	return Color.TRANSPARENT
