extends SceneTree
const ProfileView = preload("res://tests/fixtures/profile_exploration_view.gd")
const UnculledView = preload("res://tests/fixtures/unculled_exploration_view.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
var checks = 0
var failures = 0
var report_path = ""
var report: Array[Dictionary] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			report_path = arg.trim_prefix("--report=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func measure(screen, label: String) -> void:
	var samples: Array[int] = []
	var camera_counts: Array[int] = []
	for index in range(16):
		screen.map_view.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		samples.append(screen.map_view.draw_usec)
		camera_counts.append(screen.map_view.last_camera_queries)
	samples.sort()
	var result = {"area": label, "draw_median_usec": samples[samples.size() / 2], "draw_max_usec": samples.back(), "camera_queries_max": camera_counts.max()}
	report.append(result)
	print(JSON.stringify(result))
	# Orçamento de trabalho determinístico; tempo é reportado, sem limite de FPS dependente da máquina.
	expect(camera_counts.max() <= 1, "Câmera deve ser calculada uma vez por desenho: " + label)

func _run() -> void:
	var screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var old = screen.map_view
	var view = ProfileView.new()
	view.session = screen.session
	view.camera_reference_size = old.camera_reference_size
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	old.get_parent().add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	old.get_parent().remove_child(old)
	old.queue_free()
	screen.map_view = view
	await measure(screen, "vila")
	expect(screen.session.clock.time_text() == "10:00", "Relógio fica pausado no loop normal da vila")
	var portal: Dictionary = screen.session.world.entity_by_id("town_exit")
	screen.session.world.leader_position = portal["position"] + Vector2(0, 40)
	expect(screen.session.begin_transition("town_exit"), "Entrada no mundo inicia normalmente")
	var start = Time.get_ticks_msec()
	while screen.session.state == "transition" and Time.get_ticks_msec() - start < 5000:
		await process_frame
	expect(screen.session.area_id == "test_world" and screen.session.state == "exploration" and not screen.transition_overlay.visible, "Fade conclui usando o relógio normal do jogo")
	var clock_before: float = screen.session.clock.minutes_of_day()
	await measure(screen, "entrada_mundo")
	expect(screen.session.clock.minutes_of_day() > clock_before, "Loop normal avança tempo automaticamente no mapa-múndi, sem F3")
	screen.session.clock.set_time(22, 0)
	await measure(screen, "entrada_mundo_noite")
	screen.session.clock.set_time(10, 0)
	for location in [["floresta", Vector2(620, 330)], ["rampa", Vector2(388, 700)], ["platô", Vector2(388, 550)]]:
		screen.session.world.leader_position = location[1]
		screen.session.world.path.assign([location[1] + Vector2(0, 102), location[1]])
		screen.session.world.path_length = 102
		await measure(screen, location[0])
	var center: Vector2 = view.camera_center()
	var position: Vector2 = screen.session.world.leader_position
	screen.session.move(Vector2.DOWN, 0.1)
	expect(screen.session.world.leader_position != position and view.camera_center() != center, "Movimento/câmera continuam respondendo no mundo")
	var point = Vector2(500, 600)
	expect(view.world_point(view.screen_point(point)).is_equal_approx(point), "Projeção pública permanece atual fora do desenho")
	view.camera_reference_size *= 0.9
	view.size += Vector2(20, 10)
	expect(view.world_point(view.screen_point(point)).is_equal_approx(point), "Mudança de escala/tamanho invalida transformação fora do desenho")
	await verify_dungeon_render(screen)
	if not report_path.is_empty():
		var file = FileAccess.open(report_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	screen.queue_free()
	await process_frame
	print("RENDER: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func render_target(view, session, dimensions: Vector2i) -> SubViewport:
	var target = SubViewport.new()
	target.size = dimensions
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	view.session = session
	target.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return target

func compare_views(screen, dimensions: Vector2i, label: String, debug: bool = false) -> void:
	var actual_view = ProfileView.new()
	var reference_view = UnculledView.new()
	actual_view.show_path = debug
	reference_view.show_path = debug
	var actual = render_target(actual_view, screen.session, dimensions)
	var reference = render_target(reference_view, screen.session, dimensions)
	var world = screen.session.world
	var entities: Array = world.entities.duplicate(true)
	var path: Array = world.path.duplicate()
	for frame in range(3):
		actual_view.queue_redraw()
		reference_view.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
	var actual_image = actual.get_texture().get_image()
	var reference_image = reference.get_texture().get_image()
	expect(not actual_image.is_empty() and actual_image.get_pixelv(dimensions/2).a > 0, "Renderização real preenchida: " + label)
	expect(actual_image.get_data() == reference_image.get_data(), "Pixels idênticos ao desenho sem descarte: " + label)
	expect(world.entities == entities and world.path == path, "Renderização não muda monstros, rotas ou fila: " + label)
	expect(actual_view.last_camera_queries == 1, "Uma consulta de câmera mesmo com paredes irregulares: " + label)
	if label == "test_dungeon_upper/escada" and not debug:
		var actual_calls = actual.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		var reference_calls = reference.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		expect(actual_calls < reference_calls, "Escada superior desenha menos comandos com os mesmos pixels")
		print(JSON.stringify({"area":label,"view_size":str(dimensions),"culled_draw_calls":actual_calls,"unculled_draw_calls":reference_calls}))
	actual.queue_free()
	reference.queue_free()
	await process_frame

func verify_dungeon_render(screen) -> void:
	screen.set_physics_process(false)
	# Mesma sessão congelada nas duas vistas: apenas o descarte visual muda.
	for id in ["test_dungeon", "test_dungeon_upper"]:
		var world = World.new(screen.session.area_definitions[id], ["p1","p2","p3"])
		screen.session.world = world
		screen.session.area_id = id
		var locations = [Vector2(220,1350),Vector2(560,660),Vector2(1170,1010),Vector2(2120,420)] if id == "test_dungeon" else [Vector2(220,1350),Vector2(1620,570),Vector2(1320,1290),Vector2(2100,1380)]
		for dimensions in [Vector2i(720,480),Vector2i(1392,594)]:
			for index in range(locations.size()):
				world.leader_position = locations[index]
				world.path.assign([locations[index]-Vector2(102,0),locations[index]])
				world.path_length = 102
				await compare_views(screen,dimensions,id+("/escada" if index==0 else "/ponto"+str(index)))
		world.leader_position = locations[1]
		await compare_views(screen,Vector2i(1392,594),id+"/F3",true)
	# A base está fora da câmera, mas o topo alto ainda invade a borda inferior.
	var definition: Dictionary = screen.session.area_definitions["test_dungeon_upper"].duplicate(true)
	definition["obstacles"] = []
	definition["encounters"] = []
	definition["objects"] = []
	definition["transitions"] = []
	definition["wall_shapes"] = [{"rect":[500,1160,200,100],"points":[[500,1160],[700,1160],[650,1260],[540,1250]],"visual_height":180}]
	screen.session.world = World.new(definition,["p1","p2","p3"])
	screen.session.world.leader_position = Vector2(600,900)
	await compare_views(screen,Vector2i(720,480),"topo alto na borda")
