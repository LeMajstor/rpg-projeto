extends SceneTree
const Catalog=preload("res://scripts/exploration/area_catalog.gd")
const World=preload("res://scripts/exploration/exploration_model.gd")
var report_path=""
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
	call_deferred("run")
func run():
	var definitions=Catalog.load_definitions()
	var report=[]
	for id in ["test_dungeon","test_dungeon_upper"]:
		for location in [Vector2(220,1350),Vector2(560,660) if id=="test_dungeon" else Vector2(1620,570)]:
			var world=World.new(definitions[id],["p1","p2","p3"])
			world.leader_position=location
			var times=[]
			for step in range(600):
				var begin=Time.get_ticks_usec()
				world.move(Vector2.RIGHT if step%240<120 else Vector2.LEFT,1.0/120)
				world.advance(1.0/120)
				world.contact_along(world.leader_position,world.leader_position)
				times.append(Time.get_ticks_usec()-begin)
				world.contact_id="" # Probe não abre tela de batalha.
			times.sort()
			var row={"area":id,"location":str(location),"samples":times.size(),"step_median_usec":times[times.size()/2],"step_p95_usec":times[int(times.size()*0.95)],"step_max_usec":times.back()}
			report.append(row);print(JSON.stringify(row))
	if not report_path.is_empty():
		var file=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n")
	quit()
