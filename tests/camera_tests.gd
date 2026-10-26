extends SceneTree
const Camera = preload("res://scripts/exploration/exploration_camera.gd")
const View = preload("res://scripts/exploration/exploration_view.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
var checks = 0
var failures = 0
var groups = 0
var definitions: Dictionary
var battle_data: Dictionary

func _initialize() -> void:
	definitions = Catalog.load_definitions()
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	for test in [_test_scale_reference, _test_tracking_and_limits, _test_projection,
		_test_views_same_distance, _test_model_untouched]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("CÂMERA: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_scale_reference() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/areas.json"))
	var house: Dictionary = definitions["test_house"]
	var reference = Vector2(catalog["camera_reference_size"][0], catalog["camera_reference_size"][1])
	expect(reference == Vector2(house["world_size"][0], house["world_size"][1]), "Referência corresponde à casa anterior")
	for view_size in [Vector2(1392, 594), Vector2(960, 600), Vector2(760, 420), Vector2(1600, 1000)]:
		var previous_house_scale = minf(view_size.x / 720.0, view_size.y / 480.0)
		expect(is_equal_approx(Camera.scale_for(view_size, reference), previous_house_scale), "Mantém escala visual anterior da casa em cada janela")
	expect(is_equal_approx(Camera.scale_for(Vector2(1392, 594), reference), 1.2375), "Escala de referência verificada na janela padrão")
	expect(Camera.scale_for(Vector2.ZERO, reference) > 0, "Layout ainda sem tamanho não divide por zero")

func _test_tracking_and_limits() -> void:
	var view_size = Vector2(1392, 594)
	var scale = Camera.scale_for(view_size, Vector2(720, 480))
	var world = Vector2(1440, 900)
	var target = Vector2(720, 450)
	expect(Camera.center_for(target, view_size, world, scale).is_equal_approx(target), "Segue líder no interior dos limites")
	var moved = target + Vector2(0, 18)
	expect(Camera.center_for(moved, view_size, world, scale).is_equal_approx(moved), "Segue movimento cardinal sem atraso acumulado")
	var half_view = view_size / scale * 0.5
	expect(Camera.center_for(Vector2.ZERO, view_size, world, scale).is_equal_approx(half_view), "Limites superior/esquerdo")
	expect(Camera.center_for(world, view_size, world, scale).is_equal_approx(world - half_view), "Limites inferior/direito")
	var dungeon = Vector2(1120, 760)
	expect(Camera.center_for(Vector2(560, 400), view_size, dungeon, scale).is_equal_approx(Vector2(560, 400)), "Dungeon acompanha verticalmente na mesma escala")
	expect(Camera.center_for(Vector2(160, 600), view_size, dungeon, scale).is_equal_approx(Vector2(560, 520)), "Chegada da dungeon respeita borda inferior e centraliza eixo curto")
	var house = Vector2(720, 480)
	for point in [Vector2.ZERO, Vector2(360, 300), house]:
		expect(Camera.center_for(point, view_size, house, scale).is_equal_approx(house * 0.5), "Casa que cabe na janela permanece centralizada sem zoom extra")

func _test_projection() -> void:
	for view_size in [Vector2(1392, 594), Vector2(760, 420), Vector2(1600, 1000)]:
		var scale = Camera.scale_for(view_size, Vector2(720, 480))
		for world_size in [Vector2(1440, 900), Vector2(1120, 760), Vector2(720, 480), Vector2(320, 200)]:
			for target in [Vector2.ZERO, world_size * 0.5, world_size]:
				var center = Camera.center_for(target, view_size, world_size, scale)
				var origin = Camera.origin_for(target, view_size, world_size, scale)
				expect((origin + center * scale).is_equal_approx(view_size * 0.5), "Centro visual consistente")
				var half_view = view_size / scale * 0.5
				if world_size.x >= half_view.x * 2:
					expect(center.x - half_view.x >= -0.001 and center.x + half_view.x <= world_size.x + 0.001, "Não ultrapassa limites horizontais")
				if world_size.y >= half_view.y * 2:
					expect(center.y - half_view.y >= -0.001 and center.y + half_view.y <= world_size.y + 0.001, "Não ultrapassa limites verticais")

func _test_views_same_distance() -> void:
	var session = Session.new(battle_data.duplicate(true), definitions["lab_exterior"], definitions)
	var view = View.new()
	view.session = session
	root.add_child(view)
	view.size = Vector2(1392, 594)
	var size_of_actor = 0.0
	for id in definitions:
		session.world = World.new(definitions[id], ["p1", "p2", "p3", "p4"])
		var projected_height = view.screen_point(Vector2(0, 48)).distance_to(view.screen_point(Vector2.ZERO))
		if size_of_actor == 0:
			size_of_actor = projected_height
		expect(is_equal_approx(projected_height, size_of_actor), "Sprite de mesma altura em " + id)
		for point in [Vector2(36, 36), session.world.leader_position, Vector2(500, 400)]:
			expect(view.world_point(view.screen_point(point)).is_equal_approx(point), "Conversão de coordenadas reversível com câmera")
	view.free()

func _test_model_untouched() -> void:
	var session = Session.new(battle_data.duplicate(true), definitions["test_dungeon"], definitions)
	var world = session.world
	var path = world.path.duplicate()
	var entities = world.entities.duplicate(true)
	var party = session.battle.party.duplicate(true)
	var position = world.leader_position
	var view = View.new()
	view.session = session
	root.add_child(view)
	view.size = Vector2(1392, 594)
	for step in range(10):
		view.camera_center()
		view.screen_point(Vector2(step * 10, step * 20))
		view.world_point(Vector2(step * 30, 100))
		view.queue_redraw()
	expect(world.path == path and world.entities == entities and world.leader_position == position, "Câmera não altera mapa, rotas ou fila")
	expect(session.battle.party == party and session.state == "exploration", "Câmera não altera recursos nem tempo do combate")
	view.free()
