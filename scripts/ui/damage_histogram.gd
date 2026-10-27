extends Control
var result: Dictionary = {}
var font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(300, 125)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if result.is_empty():
		return
	var bins: Array = result["histogram"]
	var peak = 1
	for bin in bins:
		peak = maxi(peak, bin["count"])
	var origin = Vector2(36, 12)
	var width = maxf(1, size.x - 50)
	var height = maxf(1, size.y - 43)
	draw_line(origin + Vector2(0, height), origin + Vector2(width, height), Color("7d94aa"), 1)
	var step = width / bins.size()
	for index in range(bins.size()):
		var bin: Dictionary = bins[index]
		var normal_height: float = float(bin["normal"]) / peak * height
		var critical_height: float = float(bin["critical"]) / peak * height
		var x = origin.x + index * step + 2
		draw_rect(Rect2(Vector2(x, origin.y + height - normal_height), Vector2(maxf(1, step - 4), normal_height)), Color("65cbb0"))
		draw_rect(Rect2(Vector2(x, origin.y + height - normal_height - critical_height), Vector2(maxf(1, step - 4), critical_height)), Color("edc776"))
	var minimum = str(result["minimum"])
	var maximum = str(result["maximum"])
	draw_string(font, Vector2(origin.x, size.y - 8), minimum, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("bdcee0"))
	if minimum != maximum:
		var label_width = font.get_string_size(maximum, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(origin.x + width - label_width, size.y - 8), maximum, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("bdcee0"))
	draw_string(font, Vector2(1, 16), str(peak), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("bdcee0"))
	var label = "Dano calculado · verde: normal · amarelo: crítico"
	var label_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(maxf(origin.x + 25, (size.x - label_width) * 0.5), size.y - 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("bdcee0"))
