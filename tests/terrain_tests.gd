extends SceneTree
const World = preload("res://scripts/exploration/exploration_model.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Terrain = preload("res://scripts/exploration/terrain_geometry.gd")
const Depth = preload("res://scripts/exploration/exploration_depth.gd")
var checks = 0
var failures = 0
var definitions: Dictionary

func _initialize() -> void:
	definitions = Catalog.load_definitions()
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	return World.new(definitions["test_world"].duplicate(true), ["p1", "p2", "p3", "p4"])

func place(map, point: Vector2, direction: Vector2 = Vector2.UP) -> void:
	map.leader_position = point
	map.path.assign([point - direction * 102, point])
	map.path_length = 102

func _run() -> void:
	var tests = [_test_solid_regions, _test_ramp_cliffs, _test_height_and_followers,
		_test_pause_and_leader, _test_validation, _test_arrivals_and_sight, _test_depth]
	for test in tests:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("RELEVO: %d grupos, %d verificações, %d falhas" % [tests.size(), checks, failures])
	quit(0 if failures == 0 else 1)

func _test_solid_regions() -> void:
	var map = fresh()
	for feature in map.data["terrain"]:
		if feature["kind"] != "forest" and not (feature["kind"] == "hill" and not feature.has("ramp")):
			continue
		map = fresh()
		var area = Terrain.rect(feature["rect"])
		# Inclui espaços entre as árvores: a massa inteira é inacessível.
		for x in range(int(area.position.x) + 5, int(area.end.x), 20):
			for y in range(int(area.position.y) + 5, int(area.end.y), 20):
				expect(not map.is_walkable(Vector2(x, y)), "Região sólida não tem buracos: " + feature["kind"])
		# Isola a borda: outras colinas podem estar logo ao lado no mapa real.
		var isolated: Dictionary = map.data.duplicate(true)
		isolated["terrain"] = [feature]
		isolated["obstacles"] = []
		map = World.new(isolated, map.party_order)
		var center = area.get_center()
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
			var extent = area.size.x * 0.5 if direction.x != 0 else area.size.y * 0.5
			var start = center - direction * (extent + 20)
			place(map, start)
			map.move(direction, 100) # Não atravessa mesmo com delta grande.
			expect(map.leader_position.is_equal_approx(center - direction * (extent + 12)), "Colisão varrida em todas as bordas")

func _test_ramp_cliffs() -> void:
	var map = fresh()
	for trip in [[Vector2(70, 580), Vector2.RIGHT, Vector2(88, 580)],
		[Vector2(490, 580), Vector2.LEFT, Vector2(472, 580)],
		[Vector2(200, 700), Vector2.UP, Vector2(200, 652)],
		[Vector2(300, 700), Vector2.RIGHT, Vector2(328, 700)],
		[Vector2(480, 700), Vector2.LEFT, Vector2(448, 700)]]:
		place(map, trip[0])
		map.move(trip[1], 100)
		expect(map.leader_position.is_equal_approx(trip[2]), "Não sobe pelo paredão/lateral da rampa")
	place(map, Vector2(388, 790), Vector2.LEFT)
	map.move(Vector2.UP, 220.0 / 180.0)
	expect(map.leader_position.is_equal_approx(Vector2(388, 570)), "Rampa alcança platô em um passo grande")
	map.move(Vector2.LEFT, 100)
	expect(map.leader_position.x == 120, "Não cai do platô pela lateral")
	map.move(Vector2.DOWN, 100)
	expect(map.leader_position.y == 620, "Não desce fora da rampa")
	map.move(Vector2.UP, 100)
	expect(map.leader_position.y == 520, "Não atravessa borda norte")

func _test_height_and_followers() -> void:
	var map = fresh()
	place(map, Vector2(388, 790), Vector2.LEFT)
	var previous = 0.0
	for step in range(110):
		map.move(Vector2.UP, 2.0 / 180.0)
		var height: float = map.elevation_at(map.leader_position)
		expect(height >= previous and height - previous <= 0.801, "Subida contínua, sem salto")
		previous = height
		var positions = map.formation_positions()
		for index in range(4):
			var traveled = 790 - map.leader_position.y
			var behind = index * 34.0
			var expected = Vector2(388, map.leader_position.y + behind) if behind <= traveled else Vector2(388 + behind - traveled, 790)
			expect(positions[index].is_equal_approx(expected) and map.is_walkable(positions[index]), "Fila segue trilha real sobre rampa")
			var expected_height = clampf((760 - expected.y) * 0.4, 0, 48)
			expect(is_equal_approx(map.elevation_at(expected), expected_height), "Cada seguidor sobe no seu instante")
			expect(map.visual_position(expected).is_equal_approx(expected - Vector2(0, expected_height)), "Altura afeta apenas apresentação")
	expect(map.leader_position == Vector2(388, 570), "Posição lógica não recebe altura acumulada")
	for step in range(110):
		map.move(Vector2.DOWN, 2.0 / 180.0)
		var height: float = map.elevation_at(map.leader_position)
		expect(height <= previous and previous - height <= 0.801, "Descida/reversão sem salto")
		previous = height
		for position in map.formation_positions():
			expect(map.is_walkable(position), "Seguidores não cortam paredões na volta")
	expect(map.leader_position == Vector2(388, 790) and previous == 0, "Volta ao chão sem altura residual")

func _test_pause_and_leader() -> void:
	var map = fresh()
	place(map, Vector2(388, 790), Vector2.LEFT)
	map.move(Vector2.UP, 90.0 / 180.0)
	expect(is_equal_approx(map.elevation_at(map.leader_position), 24), "Meio da rampa tem meia altura")
	var positions = map.formation_positions()
	var trail = map.path.duplicate()
	map.menu_open = true
	map.move(Vector2.UP, 1)
	expect(map.formation_positions() == positions and map.path == trail, "Menu pausa subida")
	expect(map.choose_leader("p4") and map.formation_positions() == positions, "Trocar líder mantém trilha/alturas")
	map.dialogue_open = true
	map.move(Vector2.DOWN, 1)
	expect(map.formation_positions() == positions, "Diálogo não altera altura")
	map.dialogue_open = false
	map.transitioning = true
	map.move(Vector2.DOWN, 1)
	expect(map.formation_positions() == positions, "Fade pausa rampa")

func _test_validation() -> void:
	expect(definitions.size() == 5, "Todos os mapas permanecem válidos")
	for mutation in [{"elevation": -1}, {"elevation": "alto"}, {"cliff_thickness": 0},
		{"ramp": {"rect": [340, 650, 96, 120]}}, {"ramp": {"rect": [340, 640, 30, 120]}},
		{"ramp": {"rect": [450, 640, 96, 120]}}, {"ramp": {"rect": [340, 640, 96, -1]}},
		{"ramp": {"rect": [340, 640, "x", 120]}}, {"ramp": null}]:
		var data: Dictionary = definitions["test_world"].duplicate(true)
		data["terrain"][2].merge(mutation, true)
		expect(not Catalog.valid_map(data), "Relevo/rampa inválidos são rejeitados")

func _test_arrivals_and_sight() -> void:
	var map = fresh()
	map.data["entries"]["bad"] = {"position": [200, 610], "facing": [0, -1]}
	expect(map.prepare_arrival("bad", map.party_order).is_empty(), "Chegada não atravessa paredão com a fila")
	map.data["entries"]["forest"] = {"position": [300, 350], "facing": [1, 0]}
	expect(map.prepare_arrival("forest", map.party_order).is_empty(), "Chegada dentro de floresta é recusada")
	place(map, Vector2(200, 685))
	var target = {"id": "target", "kind": "npc", "present": true, "position": Vector2(200, 610), "interaction_distance": 200}
	expect(not map.can_interact_with(target), "Paredão bloqueia interação remota")
	for entry in ["from_town", "from_dungeon"]:
		var plan: Dictionary = map.prepare_arrival(entry, map.party_order)
		expect(not plan.is_empty(), "Chegadas do mundo preservadas")
		map.apply_arrival(plan)
		for point in map.formation_positions():
			expect(map.elevation_at(point) == 0 and map.is_walkable(point), "Chegada limpa altura da rampa")

func _test_depth() -> void:
	var map = fresh()
	var feature: Dictionary = map.data["terrain"][2]
	for point in [Vector2(200, 488), Vector2(388, 550), Vector2(388, 700)]:
		place(map, point)
		var order = Depth.draw_order(map)
		var hill_index = -1
		var member_index = -1
		for index in range(order.size()):
			if order[index].get("definition", {}) == feature:
				hill_index = index
			if order[index]["kind"] == "member" and order[index]["slot"] == 0:
				member_index = index
		expect((member_index < hill_index) == (point.y < 500), "Colina encobre quem está atrás, preserva quem subiu")
