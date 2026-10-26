extends SceneTree
var screen
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-captures="):
			capture_directory = argument.trim_prefix("--visual-captures=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func place(position: Vector2) -> void:
	screen.session.world.leader_position = position
	screen.session.world.path.assign([position - Vector2(102, 0), position])
	screen.session.world.path_length = 102
	screen.session.world.moving = false
	screen._refresh_map()

func frame_image():
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func sample(image, world: Vector2) -> Color:
	var position = screen.map_view.global_position + screen.map_view.screen_point(world)
	return image.get_pixel(int(position.x), int(position.y))

func capture(name: String) -> void:
	if capture_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	var image = await frame_image()
	expect(image.save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func occlusion(position: Vector2, offset: Vector2, hidden: bool, name: String) -> void:
	place(position)
	expect(screen.session.world.is_walkable(position), "Posição válida para " + name)
	if DisplayServer.get_name() != "headless":
		var actor: Dictionary = screen.session.battle.party[0]
		var original = actor["color"]
		actor["color"] = "ff0000"
		screen.map_view.queue_redraw()
		var red = sample(await frame_image(), position + offset)
		actor["color"] = "0000ff"
		screen.map_view.queue_redraw()
		var blue = sample(await frame_image(), position + offset)
		expect(red.is_equal_approx(blue) == hidden, "Pixels comprovam " + ("oclusão atrás: " if hidden else "ator à frente: ") + name)
		actor["color"] = original
		screen.map_view.queue_redraw()
	await capture(name)

func travel(id: String) -> void:
	if id == "dungeon_entrance" and screen.session.area_id == "lab_exterior":
		travel("town_exit")
	if id == "house_entrance" and screen.session.area_id == "test_world":
		travel("enter_town")
	var portal: Dictionary = screen.session.world.entity_by_id(id)
	place(portal["position"] + Vector2(0, -40 if id.ends_with("exit") else 40))
	screen._try_encounter()
	expect(screen.session.state == "transition", "Entrada permanece acessível")
	screen._physics_process(screen.session.transition_duration)
	expect(screen.session.state == "exploration", "Transição permanece funcional")

func _run() -> void:
	screen = load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var scale = screen.map_view._scale_factor()
	await occlusion(Vector2(292.5, 800), Vector2(0, -28), true, "depth-tree-behind")
	await occlusion(Vector2(292.5, 862), Vector2(0, -44), false, "depth-tree-front")
	await occlusion(Vector2(840, 98), Vector2(0, -20), true, "depth-house-behind")
	await occlusion(Vector2(840, 242), Vector2(0, -20), false, "depth-house-front")
	await occlusion(Vector2(364, 178), Vector2(4, -8), true, "depth-wall-behind")
	await occlusion(Vector2(364, 472), Vector2(4, -20), false, "depth-wall-front")
	place(Vector2(252.5, 800))
	for segment in [[Vector2.RIGHT, 80.0], [Vector2.DOWN, 64.0], [Vector2.LEFT, 40.0]]:
		screen.session.move(segment[0], segment[1] / 180.0)
	screen.session.world.moving = false
	screen._refresh_map()
	for point in screen.session.world.formation_positions():
		expect(screen.session.world.is_walkable(point), "Quatro integrantes em caminho livre junto da árvore")
	await capture("depth-party-around-tree")
	screen.map_view.show_path = true
	screen.map_view.queue_redraw()
	await capture("depth-footprints-debug")
	screen.map_view.show_path = false
	travel("house_entrance")
	expect(screen.session.world.entities.size() == 5, "Casa mantém NPCs e interações")
	await capture("depth-house-interior")
	travel("house_exit")
	travel("dungeon_entrance")
	expect(screen.session.world.entities.size() == 10, "Dungeon mantém encontros e objetos")
	await capture("depth-dungeon")
	expect(is_equal_approx(screen.map_view._scale_factor(), scale), "Profundidade não altera escala da câmera")
	place(Vector2(333, 340))
	screen._try_encounter()
	expect(screen.session.dialogue.opened and screen.session.world.entity_by_id("door_01")["open"], "Alavanca e colisão dinâmica continuam funcionando")
	while screen.session.dialogue.opened:
		screen._advance_dialogue()
	screen._restart()
	expect(screen.session.area_id == "lab_exterior" and not screen.session.world.menu_open, "Reinício preservado")
	screen.queue_free()
	await process_frame
	print("PROFUNDIDADE/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
