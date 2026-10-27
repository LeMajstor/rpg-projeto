extends Control
## Mão vetorial provisória original, compartilhada pelos cards, menus e campo.
var active = false:
	set(value):
		if active != value:
			active = value
			queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(32, 28)

func _draw() -> void:
	if active:
		paint(self, Vector2(6, size.y * 0.5), 0.65)

static func paint(canvas: CanvasItem, origin: Vector2, scale: float = 1.0) -> void:
	var outline = PackedVector2Array([
		Vector2(0, -7), Vector2(5, -7), Vector2(7, -12), Vector2(12, -12),
		Vector2(17, -8), Vector2(32, -8), Vector2(36, -5), Vector2(35, -2),
		Vector2(18, -2), Vector2(21, 1), Vector2(20, 5), Vector2(18, 7),
		Vector2(17, 10), Vector2(12, 12), Vector2(7, 12), Vector2(1, 8), Vector2(0, 5)])
	for index in range(outline.size()):
		outline[index] = origin + outline[index] * scale
	canvas.draw_colored_polygon(outline, Color("fff0c5"))
	outline.append(outline[0])
	canvas.draw_polyline(outline, Color("4d3a2a"), maxf(1.0, 2.0 * scale), true)
	canvas.draw_rect(Rect2(origin + Vector2(-5, -7) * scale, Vector2(7, 15) * scale), Color("e8c36f"))
	canvas.draw_line(origin + Vector2(11, 3) * scale, origin + Vector2(18, 4) * scale, Color("a98c6c"), maxf(1.0, scale))
