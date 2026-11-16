extends "res://tests/dungeon_expansion_tests.gd"
const Roster = preload("res://scripts/exploration/encounter_roster.gd")
const Perception = preload("res://scripts/exploration/encounter_perception.gd")

func _initialize() -> void:
	areas=Catalog.load_definitions()
	data=Bridge.exploration_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	call_deferred("run")

func run() -> void:
	expect(areas.size()==6,"Seis áreas vigentes")
	if not areas.has("test_dungeon") or not areas.has("test_dungeon_upper"):
		quit(1)
		return
	test_roster_and_access()
	test_static_sensors()
	test_individual_detection()
	test_safe_stair_paths()
	test_groups_and_floors()
	print("INIMIGOS INDIVIDUAIS: %d verificações, %d falhas"%[checks,failures])
	quit(0 if failures==0 else 1)

func test_roster_and_access() -> void:
	var total=0
	var group_count=0
	var profiles={"heavy":0,"agile":0,"flying":0,"static":0}
	for id in floors:
		var definition: Dictionary=areas[id]
		expect(Catalog.valid_map(definition),"Dados válidos: "+id)
		expect(definition["encounter_groups"].size()==3 and definition["encounters"].size()==9,"Três encontros/nove monstros por piso")
		group_count+=definition["encounter_groups"].size()
		var world=World.new(definition,["p1","p2","p3","p4"])
		var cells=reachable(world)
		if id=="test_dungeon":
			var lever=world.entity_by_id("lever_01")
			expect(cells.has(Vector2i(lever["position"]/20)),"Alavanca acessível antes do portão")
			world.toggle_door("door_01")
			cells=reachable(world)
		for entry in definition["entries"]:
			expect(not world.prepare_arrival(entry,["p1","p2","p3","p4"]).is_empty(),"Entradas seguras para quatro")
		for entity in world.entities:
			var point: Vector2=entity["position"]
			var near=false
			for offset in [Vector2.ZERO,Vector2(40,0),Vector2(-40,0),Vector2(0,40),Vector2(0,-40)]:
				near=near or cells.has(Vector2i(roundi((point.x+offset.x)/20),roundi((point.y+offset.y)/20)))
			expect(near,"Posição alcançável: "+entity["id"])
			if entity["kind"]!="encounter":
				continue
			total+=1
			profiles[entity["movement_profile"]]+=1
			expect(world.is_walkable(point),"Corpo cabe no chão: "+entity["id"])
			var config=Perception.rules(world,entity)
			var expected={"heavy":[32,108,180],"agile":[72,144,240],"flying":[90,162,320],"static":[0,0,0]}[entity["movement_profile"]]
			expect(entity["route_state"]["speed"]==expected[0] and config["chase_speed"]==expected[1] and config["chase_limit"]==expected[2],"Valores aprovados por perfil")
			var route: Array=entity["route_state"]["points"]
			var count=route.size() if entity["route_state"].get("closed",true) else maxi(1,route.size()-1)
			for index in range(count):
				var a: Vector2=route[index]
				var b: Vector2=route[(index+1)%route.size()]
				expect(world.can_traverse(a,b),"Rota não cruza sólido: "+entity["id"]+str(index))
			var preset: Dictionary={}
			for candidate in data["presets"]:
				if candidate["id"]==entity["battle_preset_id"]:
					preset=candidate
			var participant: Dictionary=preset["enemies"].filter(func(p):return p["id"]==entity["battle_actor_id"])[0]
			var type: Dictionary=data["enemy_types"][participant["type"]]
			expect(type["movement_behavior"]==entity["movement_profile"] and type["reference_profile_id"]==entity["reference_profile_id"],"Identidade/tipo vêm do participante da batalha")
			expect(entity["movement_behavior_data"]==data["movement_behaviors"][entity["movement_profile"]],"Mesmo perfil de pausas/ritmo da batalha")
		expect(definition["obstacles"].size()+definition["wall_shapes"].size()>25,"Layout com mais paredes e quinas")
	expect(total==18 and group_count==6 and profiles=={"heavy":4,"agile":3,"flying":4,"static":7},"18 monstros nos seis encontros originais")
	expect(areas["test_world"]["encounters"].is_empty(),"Mundo sem monstros")

func sensor_fixture():
	var map: Dictionary=areas["test_dungeon"].duplicate(true)
	map["obstacles"]=[]
	map["wall_shapes"]=[]
	map["objects"]=[]
	map["transitions"]=[]
	map["spawn"]=[100,500]
	var static_actor: Dictionary=map["encounters"].filter(func(e):return e["movement_profile"]=="static")[0].duplicate(true)
	static_actor["position"]=[500,500]
	static_actor["route"]=[[500,500]]
	static_actor["vision_direction"]=[1,0]
	map["encounters"]=[static_actor]
	return Session.new(data.duplicate(true),map)

func test_static_sensors() -> void:
	for case in [[Vector2(450,500),true],[Vector2(430,500),false],[Vector2(650,500),true],[Vector2(681,500),false],[Vector2(600,600),true],[Vector2(570,630),false],[Vector2(500,561),false]]:
		var session=sensor_fixture()
		var actor: Dictionary=session.world.entities[0]
		var original: Dictionary=actor["route_state"].duplicate(true)
		session.world.leader_position=case[0]
		session.tick(STEP)
		expect((session.state=="battle")==case[1],"Círculo/cone: "+str(case[0]))
		expect(actor["position"]==Vector2(500,500) and actor["route_state"]==original,"Estático não se desloca nem patrulha")
	# Ambas as áreas dependem de visão livre.
	for distance in [50,150]:
		var session=sensor_fixture()
		session.world.obstacles.append(Rect2(520,450,10,100))
		session.world.leader_position=Vector2(500+distance,500)
		session.tick(STEP)
		expect(session.state=="exploration","Parede bloqueia círculo/cone")
	# Movimento longo não pula uma área de ativação; sem contato físico.
	var session=sensor_fixture()
	var world=session.world
	world.leader_position=Vector2(800,500)
	world.path.assign([Vector2(902,500),world.leader_position])
	world.path_length=102
	session.move(Vector2.LEFT,3)
	expect(session.state=="battle" and world.leader_position.is_equal_approx(Vector2(680,500)),"Entrada varrida no cone inicia antes do contato")
	session=sensor_fixture()
	world=session.world
	world.leader_position=Vector2(380,500)
	world.path.assign([Vector2(278,500),world.leader_position])
	world.path_length=102
	session.move(Vector2.RIGHT,3)
	expect(session.state=="battle" and world.leader_position.is_equal_approx(Vector2(440,500)),"Entrada traseira ativa círculo60")
	# Seguidor dentro do círculo e líder fora não dispara.
	session=sensor_fixture()
	world=session.world
	world.obstacles.append(Rect2(550,480,20,40))
	world.leader_position=Vector2(620,500)
	world.path.assign([Vector2(620,602),world.leader_position])
	world.path_length=102
	session.move(Vector2.UP,1)
	expect(session.state=="battle" and world.leader_position.y<480 and world.leader_position.y>430,"Ao sair da sombra da parede, ativa cone no primeiro trecho visível")
	# Seguidor dentro do círculo e líder fora não dispara.
	session=sensor_fixture()
	world=session.world
	world.leader_position=Vector2(500,610)
	world.path.assign([Vector2(500,508),world.leader_position])
	world.path_length=102
	session.tick(STEP)
	expect(session.state=="exploration","Só líder ativa visão, seguidores são ignorados")
	for pause in ["menu_open","dialogue_open","transitioning"]:
		session=sensor_fixture()
		session.world.set(pause,true)
		session.world.leader_position=Vector2(600,500)
		session.tick(STEP)
		expect(session.state=="exploration","Pausa bloqueia sensor: "+pause)
	session=sensor_fixture()
	var statue: Dictionary=session.world.entities[0]
	statue["vision_direction"]=[0,-1]
	session.world.leader_position=Vector2(500,350)
	session.tick(STEP)
	expect(session.state=="battle" and statue["vision_direction"]==[0,-1],"Cone respeita orientação fixa configurada por inimigo")

func test_individual_detection() -> void:
	var session=Session.new(data.duplicate(true),areas["test_dungeon"],areas)
	var world=session.world
	var heavy=world.entity_by_id("test_map_enemy_01_e1")
	var flying=world.entity_by_id("test_map_enemy_01_e2")
	world.leader_position=Vector2(340,760)
	session.tick(0.3)
	expect(heavy["awareness"]["state"]=="chase" and flying["awareness"]["state"]=="patrol","Detecção individual não alerta companheiro distante")
	var frozen=heavy["route_state"].duplicate(true)
	world.menu_open=true
	session.tick(2)
	expect(heavy["route_state"]==frozen,"Menu preserva perfil/RNG de patrulha")
	world.menu_open=false
	# Mesma semente/dados/entradas reproduzem patrulhas e suas pausas.
	var a=Session.new(data.duplicate(true),areas["test_dungeon_upper"],areas)
	var b=Session.new(data.duplicate(true),areas["test_dungeon_upper"],areas)
	for step in range(360):
		a.tick(STEP)
		b.tick(STEP)
	expect(a.world.entities==b.world.entities,"Movimento individual reproduzível por semente")
	# Retomada de um trecho novo não pode ser desfeita pelo relógio do ritmo.
	var actor=a.world.entity_by_id("test_map_enemy_06_e1")
	var route: Dictionary=actor["route_state"]
	var point: Vector2=route["points"][0].lerp(route["points"][1],0.7)
	actor["position"]=point+Vector2(0,-50)
	actor["awareness"]={"state":"return","trail":[point,actor["position"]],"speed":72.0}
	a.world.leader_position=Vector2(220,1280)
	for step in range(200):
		a.world.EncounterMotion.advance(a.world,actor,STEP)
		if actor["awareness"]["state"]=="patrol":
			break
	expect(actor["position"].is_equal_approx(point),"Retomada entra no trecho próximo do ágil")
	a.world.EncounterMotion.advance(a.world,actor,STEP)
	expect(actor["position"].distance_to(point)<2,"Perfil de batalha reancorado não teleporta à distância antiga")

func test_safe_stair_paths() -> void:
	for floor_id in floors:
		var world=World.new(areas[floor_id],["p1","p2","p3"])
		if floor_id=="test_dungeon":
			world.toggle_door("door_01")
		for actor in world.entities:
			if actor["kind"]=="encounter" and not Perception.stationary(actor):
				actor["present"]=false # Avalia somente as barreiras de visão fixas.
		var start=Vector2i(roundi(world.leader_position.x/20),roundi(world.leader_position.y/20))
		var queue: Array[Vector2i]=[start]
		var cells={start:true}
		var cursor=0
		while cursor<queue.size():
			var point=queue[cursor]
			cursor+=1
			for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next: Vector2i=point+direction
				if cells.has(next) or not world.can_traverse(Vector2(point)*20,Vector2(next)*20) or not world.contact_along(Vector2(point)*20,Vector2(next)*20).is_empty():
					continue
				cells[next]=true
				queue.append(next)
		for portal in world.data["transitions"]:
			var near=false
			for offset in [Vector2(0,40),Vector2(0,-40),Vector2(40,0),Vector2(-40,0)]:
				var p=Vector2(portal["position"][0],portal["position"][1])+offset
				near=near or cells.has(Vector2i(roundi(p.x/20),roundi(p.y/20)))
			expect(near,"Há caminho às escadas/saída sem ativar estáticos: "+floor_id+portal["id"])

func test_groups_and_floors() -> void:
	for floor_id in floors:
		for group in areas[floor_id]["encounter_groups"]:
			for slot in ["e1","e2","e3"]:
				var session=Session.new(data.duplicate(true),areas[floor_id],areas)
				var world=session.world
				var actor=world.entity_by_id(group["id"]+"_"+slot)
				world.leader_position=actor["position"]
				session.tick(STEP)
				expect(session.state=="battle" and session.battle.enemies.size()==3 and session.active_encounter_group_id==group["id"],"Qualquer integrante inicia o mesmo encontro completo")
				expect(session.battle.preset["id"]==group["battle_preset_id"] and session.active_encounter_area_id==floor_id,"Preset e andar preservados")
				expect(session.battle.preset["can_escape"]==(group["id"]!="test_map_enemy_02"),"M2 continua sendo único encontro sem fuga")
				session.battle.outcome="escaped" if slot!="e2" else "victory"
				expect(session.finish_encounter(),"Retorno ao piso correto")
				var removed=world.entities.filter(func(e):return e.get("encounter_id","")==group["id"] and not e["present"])
				var other=world.entities.filter(func(e):return e["kind"]=="encounter" and e.get("encounter_id","")!=group["id"] and e["present"])
				expect(removed.size()==3 and other.size()==6,"Vitória/fuga remove só os três integrantes do encontro")
	# Escadas conservam a remoção do grupo e recursos da sessão.
	var session=Session.new(data.duplicate(true),areas["test_dungeon"],areas)
	session.world.remove_encounter_group("test_map_enemy_01")
	session.battle.party[0]["hp"]=21
	session.battle.inventory["remedy_test"]=1
	travel(session,"stairs_up")
	travel(session,"stairs_down")
	expect(session.world.entities.filter(func(e):return e.get("encounter_id","")=="test_map_enemy_01" and not e["present"]).size()==3,"Remoção persiste entre andares")
	expect(session.battle.party[0]["hp"]==21 and session.battle.inventory["remedy_test"]==1,"Escadas não restauram recursos")
