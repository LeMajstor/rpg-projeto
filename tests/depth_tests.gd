extends SceneTree
const Depth = preload("res://scripts/exploration/exploration_depth.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
var definitions: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	definitions = Catalog.load_definitions()
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func world(id: String = "lab_exterior"):
	return World.new(definitions[id].duplicate(true), ["p1", "p2", "p3", "p4"])

func place(map, position: Vector2) -> void:
	map.leader_position = position
	map.path.assign([position - Vector2(102, 0), position])
	map.path_length = 102

func obstacle_index(order: Array, definition: Dictionary) -> int:
	for index in range(order.size()):
		if order[index]["kind"] == "obstacle" and order[index]["definition"] == definition:
			return index
	return -1

func actor_index(order: Array, slot: int) -> int:
	for index in range(order.size()):
		if order[index]["kind"] == "member" and order[index]["slot"] == slot:
			return index
	return -1

func _run() -> void:
	for test in [_test_authoring, _test_back_and_front, _test_actual_footprints,
		_test_party_curve, _test_entities_and_ties, _test_pure_order]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("PROFUNDIDADE: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_authoring() -> void:
	for id in definitions:
		var data: Dictionary = definitions[id]
		expect(Catalog.valid_map(data), "Mapa válido com metadados visuais")
		for obstacle in data["obstacles"]:
			expect(obstacle.has("visual_height") and Depth.height(obstacle) >= 0, "Altura provisória definida em dados")
			expect(Depth.base_y(obstacle) == Depth.footprint(obstacle).end.y, "Ordenação pela base no chão")
	var data = definitions["lab_exterior"].duplicate(true)
	data["obstacles"][0]["visual_height"] = -1
	expect(not Catalog.valid_map(data), "Altura negativa rejeitada")
	data["obstacles"][0]["visual_height"] = 28
	data["obstacles"][0]["sort_y"] = "invalid"
	expect(not Catalog.valid_map(data), "Base visual inválida rejeitada")
	data["obstacles"][0]["sort_y"] = 500
	expect(Catalog.valid_map(data) and Depth.base_y(data["obstacles"][0]) == 500, "Base visual individual pode ser configurada")

func _test_back_and_front() -> void:
	var map = world()
	for obstacle in map.data["obstacles"]:
		var rect = Depth.footprint(obstacle)
		place(map, Vector2(rect.get_center().x, rect.position.y - 12))
		var order = Depth.draw_order(map)
		expect(actor_index(order, 0) < obstacle_index(order, obstacle), "Personagem atrás é desenhado antes da estrutura")
		place(map, Vector2(rect.get_center().x, rect.end.y + 12))
		order = Depth.draw_order(map)
		expect(actor_index(order, 0) > obstacle_index(order, obstacle), "Personagem na frente é desenhado depois da estrutura")
		place(map, Vector2(rect.get_center().x + rect.size.x, rect.end.y))
		order = Depth.draw_order(map)
		expect(actor_index(order, 0) > obstacle_index(order, obstacle), "Empate tem resultado estável com ator na frente")

func _test_actual_footprints() -> void:
	var map = world()
	var tree: Dictionary
	for obstacle in map.data["obstacles"]:
		if obstacle.get("kind", "") == "tree":
			tree = obstacle
			break
	var rect = Depth.footprint(tree)
	expect(rect.size == Vector2(20, 16), "Árvore usa base do tronco, separada da copa")
	var above = Vector2(rect.get_center().x, rect.position.y - 34)
	place(map, above - Vector2(30, 0))
	map.move(Vector2.RIGHT, 60.0 / 180.0)
	expect(map.leader_position.is_equal_approx(above + Vector2(30, 0)), "Pode caminhar sob projeção visual da copa sem colidir com folhas")
	place(map, above)
	map.move(Vector2.DOWN, 1)
	expect(is_equal_approx(map.leader_position.y, rect.position.y - 12), "Tronco continua sólido")
	var position = map.leader_position
	tree["visual_height"] = 200
	tree["canopy_width"] = 240
	map.move(Vector2.DOWN, 1)
	expect(map.leader_position == position, "Mudar altura/copa não altera colisão")
	var house: Dictionary
	for obstacle in map.data["obstacles"]:
		if obstacle.get("kind", "") == "house":
			house = obstacle
			break
	var footprint = Depth.footprint(house)
	place(map, Vector2(footprint.get_center().x, footprint.end.y + 60))
	map.move(Vector2.UP, 1)
	expect(map.leader_position.y == footprint.end.y + 12, "Casa mantém fundação sólida e acesso livre")

func _test_party_curve() -> void:
	var map = world()
	place(map, Vector2(252.5, 800))
	for segment in [[Vector2.RIGHT, 80.0], [Vector2.DOWN, 64.0], [Vector2.LEFT, 40.0]]:
		map.move(segment[0], segment[1] / 180.0)
	for position in map.formation_positions():
		expect(map.is_walkable(position), "Fila percorre curva em torno da base real da árvore")
	var tree: Dictionary
	for obstacle in map.data["obstacles"]:
		if obstacle.get("kind", "") == "tree" and Depth.footprint(obstacle).end.y == 850:
			tree = obstacle
	var order = Depth.draw_order(map)
	var index = obstacle_index(order, tree)
	expect(actor_index(order, 0) > index and actor_index(order, 3) < index, "Cada integrante pode estar à frente ou atrás da mesma estrutura")

func _test_entities_and_ties() -> void:
	for id in ["test_house", "test_dungeon"]:
		var map = world(id)
		var order = Depth.draw_order(map)
		for index in range(1, order.size()):
			expect(order[index - 1]["depth"] <= order[index]["depth"], "NPCs/monstros/objetos/cenário/fila compartilham profundidade")
		for entity in map.entities:
			if entity["kind"] == "transition":
				expect(not order.any(func(entry): return entry.get("entity", {}).get("id", "") == entity["id"]), "Portal plano fica no chão")
			elif entity.get("object_type", "") != "door":
				expect(order.any(func(entry): return entry.get("entity", {}).get("id", "") == entity["id"] and entry["depth"] == entity["position"].y), "Entidade ordenada pelos pés")
	var map = world("test_dungeon")
	var door = map.entity_by_id("door_01")
	expect(Depth.draw_order(map).any(func(entry): return entry.get("entity", {}).get("id", "") == "door_01"), "Porta fechada participa da oclusão")
	map.toggle_door("door_01")
	expect(door["open"] and not Depth.draw_order(map).any(func(entry): return entry.get("entity", {}).get("id", "") == "door_01"), "Porta aberta é marca no chão e não encobre integrantes")

func _test_pure_order() -> void:
	var map = world("test_dungeon")
	var entities = map.entities.duplicate(true)
	var obstacles = map.obstacles.duplicate()
	var data = map.data.duplicate(true)
	var path = map.path.duplicate()
	var first = Depth.draw_order(map)
	for iteration in range(10):
		expect(Depth.draw_order(map) == first, "Ordenação determinística inclusive em empates")
	expect(map.entities == entities and map.obstacles == obstacles and map.path == path and map.data == data, "Profundidade não altera lógica, rotas, dados ou fila")
