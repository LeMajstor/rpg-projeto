extends SceneTree
const ProfileView=preload("res://tests/fixtures/profile_exploration_view.gd")
const World=preload("res://scripts/exploration/exploration_model.gd")
var report_path=""
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
	call_deferred("run")
func run():
	var screen=load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	var old=screen.map_view
	var view=ProfileView.new()
	view.session=screen.session;view.camera_reference_size=old.camera_reference_size
	view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	old.get_parent().add_child(view);view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	old.get_parent().remove_child(old);old.queue_free();screen.map_view=view
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var report=[]
	for id in ["test_dungeon","test_dungeon_upper"]:
		for location in [Vector2(220,1350),Vector2(560,660) if id=="test_dungeon" else Vector2(1620,570)]:
			for debug in [false,true]:
				var world=World.new(screen.session.area_definitions[id],["p1","p2","p3"])
				world.leader_position=location
				screen.session.world=world;screen.session.area_id=id
				view.show_path=debug
				screen._refresh_map()
				var samples=[];var frames=[];var draws=[];var primitives=[]
				for index in range(100):
					world.advance(1.0/120.0)
					world.contact_id=""
					var begin=Time.get_ticks_usec()
					view.queue_redraw()
					await process_frame
					RenderingServer.force_draw()
					if index>=20:
						samples.append(view.draw_usec);frames.append(Time.get_ticks_usec()-begin)
						draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
						primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
				samples.sort();frames.sort();draws.sort();primitives.sort()
				var row={"area":id,"location":str(location),"debug":debug,"draw_median_usec":samples[40],"draw_p95_usec":samples[76],"frame_median_usec":frames[40],"frame_p95_usec":frames[76],"draw_calls":draws[40],"primitives":primitives[40]}
				report.append(row);print(JSON.stringify(row))
	if not report_path.is_empty():
		var file=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n")
	screen.queue_free();await process_frame;quit()
