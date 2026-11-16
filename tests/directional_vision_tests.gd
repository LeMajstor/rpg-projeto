extends "res://tests/individual_enemies_tests.gd"
const Geometry = preload("res://scripts/exploration/vision_geometry.gd")
const View = preload("res://scripts/exploration/exploration_view.gd")

func run() -> void:
	test_shapes_and_contacts()
	test_moving_eyes()
	test_occlusion_and_contours()
	test_vision_validation()
	test_debug_cache_and_doors()
	print("VISÃO DIRECIONAL: %d verificações, %d falhas"%[checks,failures])
	quit(0 if failures==0 else 1)

func moving_fixture(profile: String="heavy"):
	var definition: Dictionary=sensor_fixture().world.data.duplicate(true)
	var actor: Dictionary={}
	for id in floors:
		for candidate in areas[id]["encounters"]:
			if candidate["movement_profile"]==profile:
				actor=candidate.duplicate(true)
	actor["position"]=[500,500]
	actor["route"]=[[500,500],[700,500],[700,700]]
	definition["encounters"]=[actor]
	return Session.new(data.duplicate(true),definition)

func test_shapes_and_contacts() -> void:
	for profile in ["heavy","agile","flying","static"]:
		var session=sensor_fixture() if profile=="static" else moving_fixture(profile)
		var actor: Dictionary=session.world.entities[0]
		for case in [[Vector2(680,500),true],[Vector2(681,500),false],[Vector2(620,620),true],[Vector2(570,620),false],[Vector2(500,560),true],[Vector2(500,561),false],[Vector2(510,550),true],[Vector2(490,550),false],[Vector2(450,500),false],[Vector2(480,500),false]]:
			expect(Perception.in_vision(actor,case[0])==case[1],profile+" campo orientado: "+str(case[0]))
		var snapshot: Dictionary=actor["route_state"].duplicate(true)
		expect(not session.begin_encounter(actor["id"]),"Início remoto não ignora alcance")
		for from_back in [Vector2(450,500),Vector2(475,500),Vector2(476,500),Vector2(480,500)]:
			var contact: Dictionary=session.world.contact_along(from_back,from_back)
			expect((not contact.is_empty())==(from_back.x>=476),"Contato físico pelas costas preservado: "+profile)
		expect(snapshot==actor["route_state"],"Consultas de visão não consomem RNG: "+profile)
		# Seguidor dentro do campo; líder a110 na lateral não é visto.
		session.world.leader_position=Vector2(500,610)
		session.world.path.assign([Vector2(500,508),Vector2(500,610)])
		session.world.path_length=102
		session.tick(STEP)
		expect(session.state=="exploration" and actor.get("awareness",{}).get("state","")!="chase","Somente o líder participa da detecção: "+profile)
	# Varredura atravessa toda a periférica sem pular a entrada lateral.
	var session=sensor_fixture()
	session.world.leader_position=Vector2(500,700)
	session.world.path.assign([Vector2(500,802),Vector2(500,700)])
	session.world.path_length=102
	session.move(Vector2.UP,2)
	expect(session.state=="battle" and session.world.leader_position.is_equal_approx(Vector2(500,560)),"Entrada lateral na periférica60 ocorre antes do contato")

func test_moving_eyes() -> void:
	for profile in ["heavy","agile","flying"]:
		for case in [[Vector2(650,500),true],[Vector2(500,550),true],[Vector2(450,500),false],[Vector2(500,570),false]]:
			var session=moving_fixture(profile)
			var actor: Dictionary=session.world.entities[0]
			session.world.leader_position=case[0]
			session.tick(STEP)
			expect((actor["awareness"]["state"]=="chase")==case[1],"Móvel percebe campo frontal/periférico individual: "+profile+str(case[0]))
		var session=moving_fixture(profile)
		var actor: Dictionary=session.world.entities[0]
		var world=session.world
		expect(Perception.direction(actor).is_equal_approx(Vector2.RIGHT),"Olhar inicial segue primeiro trecho: "+profile)
		world.leader_position=Vector2(1000,1000)
		world.EncounterMotion._move(world,actor,Vector2(500,460))
		expect(Perception.direction(actor).is_equal_approx(Vector2.UP),"Olhar acompanha deslocamento real: "+profile)
		world.obstacles.append(Rect2(450,400,100,20))
		world.EncounterMotion._move(world,actor,Vector2(500,380))
		expect(Perception.direction(actor).is_equal_approx(Vector2.UP),"Tentativa bloqueada não altera olhar: "+profile)
		# Conserva o olhar no repouso, sem enxergar o líder às costas.
		actor["position"]=Vector2(500,500)
		world.advance(0.00001)
		expect(Perception.direction(actor).is_equal_approx(Vector2.UP),"Pausa conserva orientação: "+profile)
		for pause in ["menu_open","dialogue_open","transitioning"]:
			world.set(pause,true)
			var frozen: Dictionary=actor.duplicate(true)
			world.advance(1)
			expect(actor==frozen,"Pausa congela olhar/rota/RNG: "+pause)
			world.set(pause,false)
		# Não gira para um alvo oculto antes de decidir se o enxerga.
		session=moving_fixture(profile)
		world=session.world
		actor=world.entities[0]
		world.leader_position=Vector2(650,500)
		session.tick(STEP)
		world.leader_position=Vector2(400,500)
		session.tick(STEP)
		expect(actor["awareness"]["state"]!="chase","Perder campo orientado encerra perseguição: "+profile)
		session=moving_fixture(profile)
		world=session.world
		actor=world.entities[0]
		world.leader_position=Vector2(650,500)
		session.tick(STEP)
		world.obstacles.append(Rect2(550,450,20,100))
		session.tick(STEP)
		expect(actor["awareness"]["state"]!="chase","Parede encerra perseguição na atualização seguinte: "+profile)

func test_occlusion_and_contours() -> void:
	var session=sensor_fixture()
	var world=session.world
	var actor: Dictionary=world.entities[0]
	world.obstacles.append(Rect2(550,480,20,40))
	world.data["wall_shapes"]=[{"rect":[500,535,80,15],"points":[[500,535],[575,540],[580,550],[500,545]],"visual_height":28}]
	world.wall_polygons.clear()
	world.wall_polygons.append(world.Walls.polygon(world.data["wall_shapes"][0]["points"]))
	for case in [[Vector2(650,500),false],[Vector2(620,430),true],[Vector2(500,558),false],[Vector2(500,445),true]]:
		expect(Perception.sees(world,actor,case[0])==case[1],"Paredes retas/inclinadas recortam ambas as visões: "+str(case[0]))
	var original: Array=world.entities.duplicate(true)
	var polygons: Array[PackedVector2Array]=[]
	for prefix in ["front","peripheral"]:
		var config: Dictionary=actor["exploration_behavior"]["vision"]
		var polygon=Geometry.sector(actor["position"],Perception.direction(actor),config[prefix+"_range"],config[prefix+"_degrees"],world.sight_blockers(actor["position"],180))
		expect(not Geometry2D.triangulate_polygon(polygon).is_empty(),"Contorno recortado forma polígono válido")
		polygons.append(polygon)
	var tested=0
	var mismatches=[]
	for x in range(325,680,7):
		for y in range(325,680,7):
			var point=Vector2(x,y)
			var offset: Vector2=point-actor["position"]
			# Margem para o arco aproximado de6° e fronteiras de paredes/ângulos.
			if absf(offset.length()-60)<1 or absf(offset.length()-180)<1 or absf(absf(Vector2.RIGHT.angle_to(offset))-PI/4)<0.02 or absf(offset.x)<1:
				continue
			var on_wall=false
			for shape in world.sight_blockers(point,0.1):
				on_wall=on_wall or Geometry2D.is_point_in_polygon(point,shape)
			if on_wall:continue
			var drawn=Geometry2D.is_point_in_polygon(point,polygons[0]) or Geometry2D.is_point_in_polygon(point,polygons[1])
			if drawn!=Perception.sees(world,actor,point):mismatches.append("%s desenho=%s detecção=%s"%[point,drawn,Perception.sees(world,actor,point)])
			tested+=1
	expect(tested>2000,"Auditoria geométrica cobre milhares de posições")
	expect(mismatches.is_empty(),"Contorno F3 concorda com detecção exata: "+str(mismatches.slice(0,5)))
	expect(world.entities==original,"Construção visual não altera monstros/RNG")
	world.obstacles.append(Rect2(2000,2000,100,100))
	expect(world.sight_blockers(actor["position"],180).size()==2,"Raios visuais descartam obstáculos distantes antes de intersectar arestas")

func test_vision_validation() -> void:
	for key in ["front_range","front_degrees","peripheral_range","peripheral_degrees"]:
		for value in [0,-1,INF,NAN,"inválido"]:
			var definition: Dictionary=areas["test_dungeon"].duplicate(true)
			definition["encounters"][0]["exploration_behavior"]["vision"][key]=value
			expect(not Catalog.valid_map(definition),"Rejeita visão inválida: "+key+str(value))
	for change in [{"peripheral_degrees":181},{"front_degrees":181},{"front_range":50},{"front_degrees":150,"peripheral_degrees":120}]:
		var definition: Dictionary=areas["test_dungeon"].duplicate(true)
		definition["encounters"][0]["exploration_behavior"]["vision"].merge(change,true)
		expect(not Catalog.valid_map(definition),"Faixas/aberturas mantêm semântica frontal e lateral")
	for id in floors:
		expect(Catalog.valid_map(areas[id]),"Catálogo direcional válido: "+id)
		for actor in areas[id]["encounters"]:
			expect(actor["exploration_behavior"]["vision"]==JSON.parse_string(FileAccess.get_file_as_string("res://data/exploration_enemy_behaviors.json"))["vision"],"Configuração comum aos18 participantes")

func test_debug_cache_and_doors() -> void:
	var session=sensor_fixture()
	var world=session.world
	var actor: Dictionary=world.entities[0]
	var view=View.new()
	view.session=session
	root.add_child(view)
	var door={"id":"test_door","kind":"object","object_type":"door","rect":[550,480,20,40],"position":Vector2(560,500),"present":true,"open":false}
	world.entities.append(door)
	world._rebuild_obstacles()
	var hidden=view._vision_polygons(world,actor)
	expect(not Geometry2D.is_point_in_polygon(Vector2(650,500),hidden[0]),"F3 respeita porta fechada")
	var revision: int=world.obstacle_revision
	world.toggle_door("test_door")
	var visible=view._vision_polygons(world,actor)
	expect(world.obstacle_revision>revision and Geometry2D.is_point_in_polygon(Vector2(650,500),visible[0]),"Abrir porta invalida recorte em cache")
	actor["vision_direction"]=[0,-1]
	var turned=view._vision_polygons(world,actor)
	expect(Geometry2D.is_point_in_polygon(Vector2(500,350),turned[0]) and not Geometry2D.is_point_in_polygon(Vector2(650,500),turned[0]),"Mudança de orientação invalida campo visual")
	view.free()
