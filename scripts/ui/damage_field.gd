extends Control
## Duelo visual manual. Não altera os valores do modelo nem possui ATB/IA.
signal strike_finished
const Motion = preload("res://scripts/combat/attack_motion.gd")
var source: Dictionary = {}
var destination: Dictionary = {}
var result: Dictionary = {}
var action_type = "physical"
var active = false
var elapsed = 0.0
var duration = 0.8
var motion: Dictionary = {}
var settings: Dictionary = {}
var font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(480, 220)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func preview(config: Dictionary) -> void:
	source = config["attacker"].duplicate(true)
	destination = config["target"].duplicate(true)
	action_type = config["action"]["damage_type"]
	settings = config["settings"].duplicate(true)
	result = {}
	active = false
	queue_redraw()

func start(config: Dictionary, sample_result: Dictionary, animate: bool) -> void:
	preview(config)
	result = sample_result
	duration = float(settings["animation_seconds"])
	var options = {"melee_stop_distance": settings["melee_stop_distance"], "melee_impact_hold": settings["melee_impact_hold"], "impact_fraction": settings["impact_fraction"]}
	motion = Motion.create(Vector2(100, 120), Vector2(430, 120), action_type == "physical", options)
	elapsed = 0.0 if animate else duration
	active = animate
	queue_redraw()

func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(duration, elapsed + delta)
	queue_redraw()
	if elapsed >= duration:
		active = false
		strike_finished.emit()

func _point(world: Vector2) -> Vector2:
	return Vector2(world.x / 530.0 * size.x, world.y / 220.0 * size.y)

func _text(point: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if source.is_empty():
		return
	draw_style_box(_style(), Rect2(Vector2.ZERO, size))
	var ground = size.y * 0.7
	draw_line(Vector2(20, ground), Vector2(size.x - 20, ground), Color("40546b"), 1)
	var origin = _point(Vector2(100, 120))
	var target_point = _point(Vector2(430, 120))
	var progress = elapsed / maxf(0.05, duration)
	var offset = Vector2.ZERO
	if not result.is_empty():
		offset = Motion.sample(motion, progress, Vector2(430, 120))
	var impact = not result.is_empty() and progress >= motion["impact"]
	_draw_actor(source, origin + Vector2(offset.x / 530.0 * size.x, offset.y / 220.0 * size.y), origin, int(source["hp"]), int(result["mp_after"]) if impact else int(source["mp"]))
	_draw_actor(destination, target_point, target_point, int(result["hp_after"]) if impact else int(destination["hp"]), int(destination["mp"]))
	if not result.is_empty() and action_type == "magical" and progress < motion["impact"]:
		var t = clampf(progress / motion["impact"], 0, 1)
		draw_circle(origin.lerp(target_point, t) + Vector2(0, -20 * sin(PI * t)), 8, Color("9bd8ff"))
	if impact:
		var text = "Esquivou!" if result["evaded"] else "%d%s" % [result["damage"], "  CRÍTICO" if result["critical"] else ""]
		var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		_text(Vector2(clampf(target_point.x - text_width * 0.5, 10, size.x - text_width - 10), target_point.y - 50), text, Color("91c8ff") if result["evaded"] else Color("ffe29b") if result["critical"] else Color("ffa6a0"), 22)
		if active and not result["evaded"]:
			draw_arc(target_point, 31 + 9 * sin(progress * PI), 0, TAU, 40, Color("ffe29b"), 2)
	_text(Vector2(18, 24), "GOLPE MANUAL" if active else "DUELO DE TESTE · CADA AMOSTRA RESTAURA HP/MP", Color("b4ccdf"), 12)

func _draw_actor(actor: Dictionary, point: Vector2, hud_origin: Vector2, hp: int, mp: int) -> void:
	var color = Color(actor["color"])
	draw_ellipse_shadow(point + Vector2(0, 28))
	if actor["side"] == "ally":
		draw_circle(point, 21, color)
		draw_circle(point + Vector2(0, -6), 8, color.lightened(0.25))
	else:
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -25), point + Vector2(25, 0), point + Vector2(0, 25), point + Vector2(-25, 0)]), color)
	var name: String = actor["name"]
	var width = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	# Rótulos e recursos ficam no lugar lógico durante a aproximação visual.
	_text(Vector2(clampf(hud_origin.x - width * 0.5, 10, size.x - width - 10), hud_origin.y - 68), name, Color("e4edf7"))
	var hp_label = "HP %d / %d" % [hp, actor["hp"]]
	_text(hud_origin + Vector2(-49, 48), hp_label, Color("d4e8ef"), 13)
	draw_rect(Rect2(hud_origin + Vector2(-55, 55), Vector2(110, 7)), Color("273d51"))
	draw_rect(Rect2(hud_origin + Vector2(-55, 55), Vector2(110 * float(hp) / maxf(1, actor["hp"]), 7)), color)
	_text(hud_origin + Vector2(-40, 80), "MP %d / %d" % [mp, actor["mp"]], Color("afc1e2"), 12)

func draw_ellipse_shadow(point: Vector2) -> void:
	draw_set_transform(point, 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 29, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

func _style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("17283b")
	style.set_corner_radius_all(8)
	return style
