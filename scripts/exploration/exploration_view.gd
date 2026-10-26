extends Control
## Sprites provisórios originais, gerados em memória sem arquivos/importações.
const Camera = preload("res://scripts/exploration/exploration_camera.gd")
const Depth = preload("res://scripts/exploration/exploration_depth.gd")
const DayLighting = preload("res://scripts/exploration/day_lighting.gd")
var session:
	set(value):
		if session != null and session.clock.time_changed.is_connected(_on_time_changed):
			session.clock.time_changed.disconnect(_on_time_changed)
		session = value
		if session != null:
			session.clock.time_changed.connect(_on_time_changed)
		queue_redraw()
var lighting
var camera_reference_size = Vector2(720, 480) # Mesmo enquadramento/escala da casa anterior.
var show_path = false
var actor_texture: ImageTexture
var font: Font = ThemeDB.fallback_font
var _drawing = false
var _frame_origin = Vector2.ZERO
var _frame_scale = 1.0
var _frame_is_night = false
var _ellipse_points = PackedVector2Array()

func _ready() -> void:
	custom_minimum_size = Vector2(760, 420)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_texture = _make_sprite()
	lighting = DayLighting.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/day_lighting.json")))
	for index in range(32):
		var angle = TAU * index / 32.0
		_ellipse_points.append(Vector2(cos(angle), sin(angle)))

func _on_time_changed(_minutes: float) -> void:
	queue_redraw()

func lighting_overlay() -> Color:
	if session == null or lighting == null or session.world.data.get("lighting_profile", "fixed") != "cycle":
		return Color.TRANSPARENT
	return lighting.overlay_at(session.clock.minutes_of_day())

func _scale_factor() -> float:
	if _drawing:
		return _frame_scale
	return Camera.scale_for(size, camera_reference_size)

func camera_center() -> Vector2:
	var world_size = Vector2(session.world.data["world_size"][0], session.world.data["world_size"][1])
	return Camera.center_for(session.world.visual_position(session.world.leader_position), size, world_size, _scale_factor())

func _origin() -> Vector2:
	var world_size = Vector2(session.world.data["world_size"][0], session.world.data["world_size"][1])
	return Camera.origin_for(session.world.visual_position(session.world.leader_position), size, world_size, _scale_factor())

func screen_point(world: Vector2) -> Vector2:
	if _drawing:
		return _frame_origin + world * _frame_scale
	return _origin() + world * _scale_factor()

func world_point(screen: Vector2) -> Vector2:
	return (screen - _origin()) / _scale_factor()

func _draw() -> void:
	if session == null or actor_texture == null:
		return
	# A câmera depende do líder, não de cada vértice de cada copa.
	# Cache restrito ao callback: consultas externas refletem movimento/resize/transição imediatamente.
	_frame_scale = _scale_factor()
	_frame_origin = _origin()
	_frame_is_night = session.clock.is_night()
	_drawing = true
	var world = session.world
	var scale = _scale_factor()
	var world_size = Vector2(world.data["world_size"][0], world.data["world_size"][1])
	draw_rect(Rect2(_frame_origin, world_size * scale), Color(world.data.get("background_color", "142b30")))
	draw_rect(Rect2(screen_point(world.bounds.position), world.bounds.size * scale), Color(world.data.get("floor_color", "203c3c")))
	for feature in world.data.get("terrain", []):
		if feature["kind"] not in ["hill", "forest"]:
			_draw_terrain(feature, scale)
	for region in world.data.get("regions", []):
		var rect: Rect2 = world._rect(region["rect"])
		draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color(region["color"]))
		draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color(0.8, 0.9, 0.85, 0.13), false)
		_label(rect.position + Vector2(10, 23), region["label"], Color("c2d4cb"), 16)
	var candidate: Dictionary = world.interaction_candidate()
	var positions = world.formation_positions()
	# Camada de chão: sombras, marcadores e portas abertas ficam sob os corpos.
	for obstacle in world.data["obstacles"]:
		if obstacle.get("ground_only", false):
			_draw_obstacle(obstacle, scale)
			continue
		var rect = Depth.footprint(obstacle)
		if obstacle.get("night_light", false) and _frame_is_night:
			_ellipse(Vector2(rect.get_center().x, rect.end.y), Vector2(68, 30), Color(1, 0.82, 0.4, 0.16))
			_ellipse(Vector2(rect.get_center().x, rect.end.y), Vector2(42, 18), Color(1, 0.86, 0.55, 0.12))
		if obstacle.get("kind", "wall") == "tree":
			_ellipse(Vector2(rect.get_center().x, rect.end.y - 3), Vector2(30, 9), Color(0, 0, 0, 0.22))
		else:
			draw_rect(Rect2(screen_point(rect.position + Vector2(5, 7)), rect.size * scale), Color(0, 0, 0, 0.22))
	for entity in world.entities:
		if not entity["present"]:
			continue
		var near: bool = candidate.get("id", "") == entity["id"]
		if entity["kind"] == "transition":
			_draw_entity(entity, scale, near)
		elif entity.get("object_type", "") == "door" and entity["open"]:
			var rect = Depth.footprint(entity)
			draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color("86c99e"), false, 2)
		if near and (entity["kind"] == "transition" or (entity.get("object_type", "") == "door" and entity["open"])):
			draw_arc(screen_point(world.visual_position(entity["position"])), 32 * scale, 0, TAU, 48, Color("ffdf9b"), 2)
	# Corpos do cenário e dos atores compartilham a mesma ordem de profundidade.
	for entry in Depth.draw_order(world):
		match entry["kind"]:
			"terrain": _draw_terrain(entry["definition"], scale)
			"obstacle": _draw_obstacle(entry["definition"], scale)
			"entity":
				var entity: Dictionary = entry["entity"]
				var visual: Vector2 = world.visual_position(entity["position"])
				var near: bool = candidate.get("id", "") == entity["id"]
				_ellipse(visual, Vector2(13, 6), Color(0, 0, 0, 0.25))
				if near:
					draw_arc(screen_point(visual), 32 * scale, 0, TAU, 48, Color("ffdf9b"), 2)
				_draw_entity(entity, scale, near)
			"member":
				# Sombras no próprio plano elevado; a trilha de colisão permanece no chão.
				var visual: Vector2 = world.visual_position(entry["position"])
				_ellipse(visual, Vector2(13, 6), Color(0, 0, 0, 0.3))
				if entry["slot"] == 0:
					var point = screen_point(visual)
					draw_arc(point, 18 * scale, 0, TAU, 40, Color("ffda87"), 2)
					draw_line(point, point + world.facing * 23 * scale, Color("ffda87"), 2)
				_draw_member(entry["slot"], visual, scale)
	for entity in world.entities:
		if entity["present"] and (entity["kind"] == "transition" or (entity.get("object_type", "") == "door" and entity["open"])):
			_draw_entity_label(entity, candidate.get("id", "") == entity["id"])
	# Um único passe de iluminação; debug, rodapé, HUD e diálogos permanecem legíveis.
	var shade = lighting_overlay()
	if shade.a > 0:
		draw_rect(Rect2(Vector2.ZERO, size), shade)
	if show_path:
		# Debug explícito sobre o desenho: vermelho = sólido; azul = base de profundidade.
		for rect in world.obstacles:
			draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color("f0a38c"), false, 1.5)
		for obstacle in world.data["obstacles"]:
			if obstacle.get("ground_only", false):
				continue
			var rect = Depth.footprint(obstacle)
			var base = Depth.base_y(obstacle)
			draw_line(screen_point(Vector2(rect.position.x, base)), screen_point(Vector2(rect.end.x, base)), Color("86d8e2"), 2)
		for index in range(1, world.path.size()):
			draw_line(screen_point(world.path[index - 1]), screen_point(world.path[index]), Color("e4c776"), 2)
		for point in positions:
			draw_line(screen_point(point), screen_point(world.visual_position(point)), Color("a7e4ff"), 2)
			_label(world.visual_position(point) + Vector2(20, -12), "h %.1f" % world.elevation_at(point), Color("a7e4ff"), 10)
		var extent = float(world.data["leader_half_extent"])
		draw_rect(Rect2(screen_point(world.leader_position - Vector2.ONE * extent), Vector2.ONE * extent * 2 * scale), Color("ffd984"), false, 1.5)
		for entity in world.entities:
			var points: Array = entity["route_state"]["points"]
			if entity["present"] and points.size() > 1:
				for index in range(points.size()):
					draw_line(screen_point(points[index]), screen_point(points[(index + 1) % points.size()]), Color("8fc8d2"), 1.5)
	# Instruções ficam na tela; não viajam com as coordenadas do mapa.
	var hud_height = 44.0 if show_path else 25.0
	draw_rect(Rect2(0, size.y - hud_height, size.x, hud_height), Color(0.04, 0.08, 0.1, 0.85))
	draw_string(font, Vector2(12, size.y - hud_height + 17), world.data.get("footer", "E: interagir"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 13, Color("b2c8c1"))
	if show_path:
		var center = camera_center()
		draw_string(font, Vector2(12, size.y - 7), "Líder (%.1f, %.1f) · altura %.1f · câmera (%.1f, %.1f) · escala %.3f" % [world.leader_position.x, world.leader_position.y, world.elevation_at(world.leader_position), center.x, center.y, scale], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 13, Color("e4c776"))
	_drawing = false

func _visible_rect(rect: Rect2) -> bool:
	return Rect2(screen_point(rect.position), rect.size * _scale_factor()).intersects(Rect2(Vector2.ZERO, size), true)

func _ellipse(position: Vector2, radii: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	var center = screen_point(position)
	var extent = radii * _scale_factor()
	for unit in _ellipse_points:
		points.append(center + unit * extent)
	draw_colored_polygon(points, color)

func _draw_box(rect: Rect2, height: float, top: Color, front: Color) -> void:
	var scale = _scale_factor()
	var upper = rect.position - Vector2(0, height)
	draw_rect(Rect2(screen_point(upper), rect.size * scale), top)
	draw_rect(Rect2(screen_point(Vector2(rect.position.x, rect.end.y - height)), Vector2(rect.size.x, height) * scale), front)
	draw_line(screen_point(upper), screen_point(upper + Vector2(rect.size.x, 0)), top.lightened(0.18), 2)
	draw_line(screen_point(Vector2(rect.position.x, rect.end.y - height)), screen_point(Vector2(rect.end.x, rect.end.y - height)), front.lightened(0.18), 1)

func _draw_terrain(feature: Dictionary, scale: float) -> void:
	var rect = Depth.footprint(feature)
	var kind: String = feature["kind"]
	var painted = rect
	if kind == "hill" and feature.has("ramp"):
		painted = painted.merge(Depth.footprint(feature["ramp"]))
	# Inclui altura/copa e margem para rótulos; não desenha massas fora da câmera.
	if not _visible_rect(painted.grow(maxf(64, float(feature.get("elevation", 0)) + 32))):
		return
	if kind == "hill":
		var height = float(feature.get("elevation", 48))
		_draw_box(rect, height, Color("648159"), Color("75664b"))
		if feature.has("ramp"):
			var ramp = Depth.footprint(feature["ramp"])
			var top = ramp.position - Vector2(0, height)
			# Uma faixa contínua liga o pé ao topo, cobrindo a abertura do paredão.
			draw_colored_polygon(PackedVector2Array([screen_point(top), screen_point(top + Vector2(ramp.size.x, 0)), screen_point(ramp.end), screen_point(Vector2(ramp.position.x, ramp.end.y))]), Color("9a8962"))
			for step in range(1, 7):
				var y = lerpf(top.y, ramp.end.y, step / 7.0)
				draw_line(screen_point(Vector2(ramp.position.x + 8, y)), screen_point(Vector2(ramp.end.x - 8, y)), Color("bdab7a"), 2)
			draw_line(screen_point(top), screen_point(Vector2(ramp.position.x, ramp.end.y)), Color("5d553e"), 3)
			draw_line(screen_point(top + Vector2(ramp.size.x, 0)), screen_point(ramp.end), Color("5d553e"), 3)
			_label(ramp.end + Vector2(12, -12), "RAMPA · subir ↑", Color("f1d99c"), 12)
		if not feature.get("label", "").is_empty():
			_label(rect.position + Vector2(16, 26 - height), feature["label"], Color("d0dfc2"), 14)
		return
	elif kind == "forest":
		_draw_box(rect, 24, Color("294c35"), Color("253f2e"))
		# Formas repetidas apenas para desenhar a massa fechada; o mapa é autorado em dados.
		for y in range(int(rect.position.y) + 22, int(rect.end.y), 50):
			for x in range(int(rect.position.x) + 24, int(rect.end.x), 50):
				_ellipse(Vector2(x, y - 24), Vector2(28, 26), Color("3d6846"))
				_ellipse(Vector2(x - 5, y - 33), Vector2(18, 16), Color("4d7752"))
	else:
		var colors = {"path": "8d805e", "sand": "b8a473", "forest": "2f4a36"}
		draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color(colors.get(kind, "405b42")))
	if not feature.get("label", "").is_empty():
		_label(rect.position + Vector2(16, 26), feature["label"], Color("d0dfc2"), 14)

func _draw_obstacle(obstacle: Dictionary, scale: float) -> void:
	var rect = Depth.footprint(obstacle)
	var kind: String = obstacle.get("kind", "wall")
	var height = Depth.height(obstacle)
	var base = Vector2(rect.get_center().x, rect.end.y)
	if kind == "water":
		draw_rect(Rect2(screen_point(rect.position), rect.size * scale), Color("285c77"))
		for y in range(int(rect.position.y) + 18, int(rect.end.y) - 8, 36):
			draw_line(screen_point(Vector2(rect.position.x + 12, y)), screen_point(Vector2(rect.end.x - 12, y)), Color("39738e"), 2)
	elif kind == "mountain":
		var peak = Vector2(rect.get_center().x, rect.position.y - height)
		var left = Vector2(rect.position.x, rect.end.y)
		var right = rect.end
		draw_colored_polygon(PackedVector2Array([screen_point(left), screen_point(peak), screen_point(right)]), Color("84918d"))
		draw_colored_polygon(PackedVector2Array([screen_point(peak), screen_point(base), screen_point(right)]), Color("647777"))
		draw_colored_polygon(PackedVector2Array([screen_point(peak), screen_point(peak.lerp(left, 0.26)), screen_point(peak.lerp(right, 0.26))]), Color("d5dfd6"))
	elif kind == "town_marker":
		_draw_box(rect, height, Color("776b5c"), Color("a9987b"))
		for offset in [30.0, 110.0, 180.0]:
			var origin = rect.position + Vector2(offset, 25 - height)
			draw_rect(Rect2(screen_point(origin), Vector2(40, 44) * scale), Color("b19a7b"))
			draw_colored_polygon(PackedVector2Array([screen_point(origin - Vector2(5, 0)), screen_point(origin + Vector2(20, -20)), screen_point(origin + Vector2(45, 0))]), Color("986359"))
	elif kind == "tree":
		var tree_height = float(obstacle.get("visual_height", 96))
		var width = float(obstacle.get("canopy_width", 96))
		var trunk_width = rect.size.x * 0.7
		draw_rect(Rect2(screen_point(base - Vector2(trunk_width * 0.5, tree_height * 0.6)), Vector2(trunk_width, tree_height * 0.6) * scale), Color("69523f"))
		_ellipse(base - Vector2(0, tree_height * 0.75), Vector2(width * 0.5, tree_height * 0.44), Color("3e7356"))
		_ellipse(base + Vector2(-width * 0.15, -tree_height * 0.86), Vector2(width * 0.29, tree_height * 0.27), Color("578764"))
	elif kind == "house":
		_draw_box(rect, height, Color("986359"), Color("aa9375"))
		var upper = rect.position - Vector2(0, height)
		var roof = PackedVector2Array([screen_point(upper + Vector2(-10, 12)), screen_point(upper + Vector2(rect.size.x * 0.5, -28)), screen_point(upper + Vector2(rect.size.x + 10, 12))])
		draw_colored_polygon(roof, Color("ad7567"))
		draw_rect(Rect2(screen_point(base - Vector2(14, minf(35, height))), Vector2(28, minf(35, height)) * scale), Color("29353a"))
		if obstacle.get("night_windows", false):
			for x in [rect.position.x + 18, rect.end.x - 38]:
				var window = Vector2(x, rect.end.y - height + 9)
				draw_rect(Rect2(screen_point(window), Vector2(20, 18) * scale), Color("ffdc8e") if _frame_is_night else Color("283c49"))
				draw_line(screen_point(window + Vector2(10, 0)), screen_point(window + Vector2(10, 18)), Color("795b40"), 2)
	elif kind == "lamp":
		draw_line(screen_point(base), screen_point(base - Vector2(0, height)), Color("6a7375"), 5 * scale)
		var head = base - Vector2(9, height)
		draw_rect(Rect2(screen_point(head), Vector2(18, 18) * scale), Color("ffe2a0") if _frame_is_night and obstacle.get("night_light", false) else Color("39464b"))
		draw_line(screen_point(head - Vector2(3, 2)), screen_point(head + Vector2(21, -2)), Color("7b8580"), 3)
	elif kind == "dungeon_entrance":
		_draw_box(rect, height, Color("5b626a"), Color("3b454f"))
		draw_rect(Rect2(screen_point(base - Vector2(22, height * 0.85)), Vector2(44, height * 0.85) * scale), Color("111c26"))
	elif kind == "rock":
		_draw_box(rect, height, Color("899593"), Color("63726f"))
	else:
		_draw_box(rect, height, Color("73858b"), Color("52646a"))
	if not obstacle.get("label", "").is_empty() and rect.size.x > 80:
		_label(rect.position + Vector2(8, minf(28, rect.size.y - 5) - height), obstacle["label"], Color("d6e0dc"), 12)

func _draw_entity(entity: Dictionary, scale: float, near: bool) -> void:
	var position: Vector2 = session.world.visual_position(entity["position"])
	var center = screen_point(position)
	if entity["kind"] == "encounter":
		center -= Vector2(0, 19) * scale
		var vertices = PackedVector2Array([center + Vector2(0, -25) * scale, center + Vector2(23, 0) * scale,
			center + Vector2(0, 19) * scale, center + Vector2(-23, 0) * scale])
		draw_colored_polygon(vertices, Color("ef937f"))
		draw_circle(center + Vector2(-7, -5) * scale, 3 * scale, Color("25323d"))
		draw_circle(center + Vector2(7, -5) * scale, 3 * scale, Color("25323d"))
	elif entity["kind"] == "transition":
		draw_rect(Rect2(center + Vector2(-23, -8) * scale, Vector2(46, 16) * scale), Color("426b72"))
		draw_line(center + Vector2(0, 6) * scale, center + Vector2(0, -6) * scale, Color("d1f0e8"), 2)
		draw_line(center + Vector2(0, -6) * scale, center + Vector2(-6, 0) * scale, Color("d1f0e8"), 2)
		draw_line(center + Vector2(0, -6) * scale, center + Vector2(6, 0) * scale, Color("d1f0e8"), 2)
		return # Marcador plano; seu rótulo é desenhado após os corpos.
	elif entity["kind"] == "npc":
		draw_texture_rect(actor_texture, Rect2(center + Vector2(-12, -36) * scale, Vector2(24, 36) * scale), false, Color(entity["color"]))
	else:
		match entity["object_type"]:
			"mysterious_stone":
				var rect = Depth.footprint(entity)
				var height = Depth.height(entity)
				if _frame_is_night:
					_ellipse(rect.get_center() - Vector2(0, height), Vector2(30, 22), Color(0.55, 0.85, 1, 0.22))
				_draw_box(rect, height, Color("8d999a"), Color("657574"))
				if _frame_is_night:
					var point = rect.position - Vector2(0, height) + Vector2(10, 8)
					draw_line(screen_point(point), screen_point(point + Vector2(13, 8)), Color("b4eafa"), 2 * scale)
					draw_line(screen_point(point + Vector2(13, 0)), screen_point(point + Vector2(3, 12)), Color("b4eafa"), 2 * scale)
			"chest":
				draw_rect(Rect2(center + Vector2(-18, -18) * scale, Vector2(36, 18) * scale), Color("b28b57"))
				draw_rect(Rect2(center + Vector2(-18, -28) * scale, Vector2(36, 10) * scale), Color("302c30") if entity["open"] else Color("e3bd78"))
			"sign":
				draw_line(center, center + Vector2(0, -24) * scale, Color("ad8e64"), 5 * scale)
				draw_rect(Rect2(center + Vector2(-21, -46) * scale, Vector2(42, 28) * scale), Color("c4af7e"))
				draw_line(center + Vector2(-14, -34) * scale, center + Vector2(14, -34) * scale, Color("5a554b"), 2)
			"door":
				_draw_box(Depth.footprint(entity), Depth.height(entity), Color("bb996c"), Color("a87d54"))
			"lever":
				draw_rect(Rect2(center + Vector2(-13, -8) * scale, Vector2(26, 8) * scale), Color("7e8c8d"))
				draw_line(center, center + Vector2(12 if entity["active"] else -12, -23) * scale, Color("efce82"), 5 * scale)
	_draw_entity_label(entity, near)

func _draw_entity_label(entity: Dictionary, near: bool) -> void:
	var position: Vector2 = session.world.visual_position(entity["position"])
	var label_height = 57 if entity.get("object_type", "") == "sign" else 47
	_label(position + Vector2(-28, -label_height), entity["label"], Color("f4dbb5"), 14)
	if near:
		_label(position + Vector2(-22, 24), "E · interagir", Color("ffdf9b"), 13)

func _draw_member(index: int, position: Vector2, scale: float) -> void:
	var id: String = session.world.party_order[index]
	var actor = session.battle.actor_by_id(id)
	var tint = Color(actor["color"])
	if actor["hp"] == 0:
		tint = tint.darkened(0.55)
	var point = screen_point(position)
	var bob = sin(session.world.distance_walked * 0.24 - index) * 2.0 if session.world.moving else 0.0
	draw_texture_rect(actor_texture, Rect2(point + Vector2(-16, -48 + bob) * scale, Vector2(32, 48) * scale), false, tint)
	_label(position + Vector2(-18, -52), "%d%s" % [index + 1, " · LÍDER" if index == 0 else ""], Color("edf3ee"), 12)

func _make_sprite() -> ImageTexture:
	var image = Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(4, 1, 8, 8), Color("e7ecf0"))
	image.fill_rect(Rect2i(3, 0, 10, 3), Color("6d7a91"))
	image.fill_rect(Rect2i(3, 10, 10, 8), Color.WHITE)
	image.fill_rect(Rect2i(1, 11, 2, 7), Color("b6c1ce"))
	image.fill_rect(Rect2i(13, 11, 2, 7), Color("b6c1ce"))
	image.fill_rect(Rect2i(4, 18, 3, 6), Color("91a0b4"))
	image.fill_rect(Rect2i(9, 18, 3, 6), Color("91a0b4"))
	image.fill_rect(Rect2i(5, 5, 2, 2), Color("283440"))
	image.fill_rect(Rect2i(10, 5, 2, 2), Color("283440"))
	return ImageTexture.create_from_image(image)

func _label(position: Vector2, text: String, color: Color, font_size: int) -> void:
	draw_string(font, screen_point(position), text, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(font_size * _scale_factor())), color)
