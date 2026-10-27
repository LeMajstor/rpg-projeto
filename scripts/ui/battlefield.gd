extends Control
## Desenho provisório original. A UI nunca escreve nas posições da simulação.

const Hand = preload("res://scripts/ui/battle_hand.gd")
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const WORLD = Battle.BATTLEFIELD_SIZE
var model
var debug_visible = false
var aiming_skill: Dictionary = {}
var aiming_target_id = ""
var font: Font = ThemeDB.fallback_font
var result_hint = "Use os controles do laboratório para continuar."

func _ready() -> void:
	custom_minimum_size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _scale_factor() -> float:
	return minf(size.x / WORLD.x, size.y / WORLD.y)

func _origin() -> Vector2:
	return (size - WORLD * _scale_factor()) * 0.5

func screen_point(world: Vector2) -> Vector2:
	return _origin() + world * _scale_factor()

func world_point(local: Vector2) -> Vector2:
	return (local - _origin()) / _scale_factor()

func preview() -> Dictionary:
	var source = model.actor_by_id(model.selected_id)
	var skill = aiming_skill
	var target_id = aiming_target_id
	if not model.action.is_empty() and model.action["skill"].get("target", "") == "circle" and not model.action["applied"]:
		source = model.actor_by_id(model.action["actor_id"])
		skill = model.action["skill"]
		target_id = model.action["target_id"]
	if source.is_empty() or skill.is_empty():
		return {}
	var target = model.actor_by_id(target_id)
	return {"skill": skill, "target": target,
		"targets": model.targets_for(source, skill, target_id)}

func _draw() -> void:
	if model == null or model.preset.is_empty():
		return
	var scale = _scale_factor()
	var rect = Rect2(_origin(), WORLD * scale)
	draw_style_box(_panel(Color(model.preset["background"])), rect)
	for x in range(40, 920, 55):
		draw_line(screen_point(Vector2(x, 35)), screen_point(Vector2(x, 410)), Color(0.7, 0.8, 1, 0.045))
	for y in range(45, 430, 55):
		draw_line(screen_point(Vector2(30, y)), screen_point(Vector2(890, y)), Color(0.7, 0.8, 1, 0.045))
	_label(Vector2(28, 28), "ALIADOS  /  posições lógicas fixas", Color("94b6d3"), 15)
	_label(Vector2(565, 28), "INIMIGOS  /  trajetórias do preset", Color("c0a9b5"), 15)
	if debug_visible:
		var center = screen_point(model.visual_center())
		draw_line(center - Vector2(9, 0), center + Vector2(9, 0), Color("a4d5e8"), 1.5)
		draw_line(center - Vector2(0, 9), center + Vector2(0, 9), Color("a4d5e8"), 1.5)
		for enemy in model.enemies:
			var points = enemy["route_state"]["points"]
			var color = Color(0.5, 0.85, 1, 0.4) if enemy["route_state"]["kind"] == "air" else Color(1, 0.65, 0.5, 0.35)
			for index in range(points.size() if enemy["route_state"].get("closed", true) else maxi(0, points.size() - 1)):
				var a = screen_point(points[index])
				var b = screen_point(points[(index + 1) % points.size()])
				draw_line(a, b, color, 1.5)
			for point in enemy["route_state"]["control_points"]:
				draw_circle(screen_point(point), 3, color.lightened(0.2))
	var aim = preview()
	if not aim.is_empty() and aim["skill"].get("target", "") == "circle" and not aim["target"].is_empty() and not aim["targets"].is_empty():
		var center: Vector2 = aim["target"]["logical_position"]
		var radius: float = aim["skill"]["radius"] * scale
		draw_circle(screen_point(center), radius, Color(0.5, 0.8, 1, 0.12))
		draw_arc(screen_point(center), radius, 0, TAU, 80, Color("8bd2ff"), 2.0)
		_label(center + Vector2(-55, -aim["skill"]["radius"] - 12), "%d alvo(s) agora" % aim["targets"].size(), Color("c6eaff"), 15)
	for actor in model.actors():
		_draw_actor(actor, scale)
		if not aim.is_empty() and aim["targets"].has(actor):
			draw_arc(screen_point(actor_visual_position(actor)), 30 * scale, 0, TAU, 48, Color("9de9ff"), 2.0)
	if not aim.is_empty() and not aim["target"].is_empty() and not aim["targets"].is_empty():
		Hand.paint(self, screen_point(actor_visual_position(aim["target"]) + Vector2(-65, 0)), scale)
	if not model.action.is_empty():
		_draw_impact(scale)
		var actor = model.actor_by_id(model.action["actor_id"])
		var phase_labels = {"approach":"aproximação", "impact":"impacto", "return":"retorno", "gesture":"ação", "stationary":"no lugar"}
		var phase = model.action["motion"]["phase"]
		_label(Vector2(250, 430), "%s → %s · %s" % [actor["short_name"], model.action["skill"]["name"], phase_labels.get(phase, phase)], Color("ffe3a8"), 16)
	if model.outcome != "running":
		var titles = {"victory": "VITÓRIA", "defeat": "GAME OVER", "escaped": "GRUPO ESCAPOU"}
		draw_rect(Rect2(screen_point(Vector2(270, 165)), Vector2(380, 95) * scale), Color(0.02, 0.04, 0.07, 0.93))
		_label(Vector2(325, 210), titles.get(model.outcome, model.outcome), Color("f2deb5"), 30)
		_label(Vector2(285, 241), result_hint, Color("b9c9da"), 14)

func actor_visual_position(actor: Dictionary) -> Vector2:
	var offset = Vector2.ZERO
	if actor["hp"] > 0:
		offset = Route.presentation_offset(actor["route_state"]) * _idle_presentation_weight(actor)
	return actor["logical_position"] + actor["visual_offset"] + offset

func _idle_presentation_weight(actor: Dictionary) -> float:
	if model.action.get("actor_id", "") != actor["id"]:
		return 1.0
	var motion: Dictionary = model.action["motion"]
	var progress: float = model.action["elapsed"] / maxf(0.05, float(model.data["settings"]["action_duration"]))
	if progress < motion["impact"]:
		return 1.0 - smoothstep(0.0, motion["impact"], progress)
	return smoothstep(motion["return_start"], 1.0, progress)

func _draw_actor(actor: Dictionary, scale: float) -> void:
	var logical: Vector2 = actor["logical_position"]
	var visual = actor_visual_position(actor)
	var point = screen_point(visual)
	var tint = Color(actor["color"])
	if actor["hp"] <= 0:
		tint = Color("626978")
	var highlighted = actor["id"] == model.selected_id
	if highlighted:
		draw_arc(point, 27 * scale, 0, TAU, 48, Color("ffdf8f"), 3.0)
	elif actor["side"] == "ally" and model.is_ready(actor):
		draw_arc(point, 26 * scale, 0, TAU, 48, Color(0.4, 1, 0.8, 0.65), 2.0)
	draw_ellipse_shadow(screen_point(logical + actor["visual_offset"]) + Vector2(0, 20 * scale), scale)
	if actor["side"] == "ally":
		draw_circle(point, 18 * scale, tint)
		draw_circle(point + Vector2(0, -4 * scale), 7 * scale, tint.lightened(0.25))
	else:
		var route: Dictionary = actor["route_state"]
		var lean = 0.0
		if actor["hp"] > 0 and (route.has("rhythm") or route.has("behavior")):
			var movement: Dictionary = route.get("behavior", route.get("rhythm", {}))
			lean = Route.travel_direction(route).x * minf(1.0, movement["current_speed"] / maxf(1.0, route["speed"])) * float(route["presentation"].get("lean", 0.0)) * _idle_presentation_weight(actor)
		var vertices = PackedVector2Array([point + Vector2(0, -22) * scale, point + Vector2(23, 0) * scale,
			point + Vector2(0, 22) * scale, point + Vector2(-23, 0) * scale])
		for index in range(vertices.size()):
			vertices[index] = point + (vertices[index] - point).rotated(lean)
		draw_colored_polygon(vertices, tint)
	if actor["hp"] > 0:
		draw_line(point, point + actor["facing"] * 28 * scale, tint.lightened(0.5), 3)
	else:
		draw_line(point - Vector2(10, 10) * scale, point + Vector2(10, 10) * scale, Color("d4d9e0"), 2)
	var label = actor.get("short_name", actor["name"])
	if actor["side"] == "enemy" and actor["route_state"]["kind"] == "air":
		label += " / VOO"
	var label_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(15 * scale))).x / scale
	_label(visual + Vector2(-label_width * 0.5, -34), label, Color("e2eaf2"), 15)
	var bar_pos = screen_point(visual + Vector2(-37, 30))
	draw_rect(Rect2(bar_pos, Vector2(74, 5) * scale), Color("283649"))
	draw_rect(Rect2(bar_pos, Vector2(74 * float(actor["hp"]) / actor["max_hp"], 5) * scale), tint)
	# Nenhum ATB inimigo é desenhado no campo, nem em modo de depuração.
	if debug_visible:
		var anchor = screen_point(logical)
		draw_line(anchor - Vector2(6, 0), anchor + Vector2(6, 0), Color("ffffff"))
		draw_line(anchor - Vector2(0, 6), anchor + Vector2(0, 6), Color("ffffff"))
		draw_dashed_line(anchor, point, Color("ffffff"), 1, 3)
		_label(logical + Vector2(-32, 46), "(%.1f, %.1f)" % [logical.x, logical.y], Color("9fb4c9"), 12)

func _draw_impact(scale: float) -> void:
	var strength: float = model.action["motion"]["effect_strength"]
	if strength <= 0 or not model.action["applied"]:
		return
	var color = Color(1, 0.88, 0.48, strength) if model.action["motion"]["melee"] else Color(0.55, 0.85, 1, strength)
	if model.action["motion"].get("presentation", "") == "fullscreen":
		# Efeito provisório cobre o campo; não participa do cálculo de alvos.
		draw_rect(Rect2(_origin(), WORLD * scale), Color(0.3, 0.65, 0.9, strength * 0.12))
		var source = model.actor_by_id(model.action["actor_id"])
		var origin = screen_point(source["logical_position"] + source["visual_offset"])
		draw_arc(origin, (34 + (1 - strength) * 100) * scale, 0, TAU, 64, color, 3)
	for position in model.action["impact_points"]:
		var point = screen_point(position)
		draw_arc(point, (27 + (1 - strength) * 15) * scale, 0, TAU, 40, color, 2.0)
		draw_line(point + Vector2(-17, 13) * scale, point + Vector2(17, -13) * scale, color, 4 * scale)
		draw_line(point + Vector2(-7, -18) * scale, point + Vector2(7, 18) * scale, color, 2 * scale)

func draw_ellipse_shadow(point: Vector2, scale: float) -> void:
	draw_set_transform(point, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 25 * scale, Color(0, 0, 0, 0.27))
	draw_set_transform(Vector2.ZERO)

func _label(point: Vector2, text: String, color: Color, font_size: int) -> void:
	draw_string(font, screen_point(point), text, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(font_size * _scale_factor())), color)

func _panel(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color("33475e")
	return style
