extends SceneTree
const ProfileView = preload("res://tests/fixtures/profile_exploration_view.gd")
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
		await RenderingServer.frame_post_draw
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
	if not report_path.is_empty():
		var file = FileAccess.open(report_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	screen.queue_free()
	await process_frame
	print("RENDER: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
