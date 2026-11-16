extends SceneTree
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const Battle = preload("res://scripts/combat/battle_model.gd")
const Territory = preload("res://scripts/exploration/patrol_territory.gd")
const STEP = 1.0/120.0
var checks=0
var failures=0
var areas: Dictionary
var data: Dictionary
var floors=["test_dungeon","test_dungeon_upper"]

func _initialize() -> void:
	areas=preload("res://tests/fixtures/pre_individual_catalog.gd").load_definitions()
	data=Bridge.exploration_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	call_deferred("run")

func expect(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)

func fixture():
	var definition: Dictionary=areas["test_dungeon"].duplicate(true)
	definition["obstacles"]=[]
	definition["wall_shapes"]=[]
	definition["objects"]=[]
	definition["transitions"]=[]
	definition["spawn"]=[200,900]
	definition["encounters"]=[{"id":"enemy","label":"Fixture","position":[300,300],"route":[[300,300],[700,300]],"speed":60,"battle_preset_id":"exploration_seeded_open"}]
	return Session.new(data.duplicate(true),definition)

func run() -> void:
	expect(areas.size()==6 and areas.has("test_dungeon_upper"),"Seis áreas, incluindo dois andares")
	if not areas.has("test_dungeon_upper"):
		quit(1)
		return
	test_layouts()
	test_geometry()
	test_territory()
	test_stairs()
	test_parity()
	print("DUNGEON AMPLIADA: %d verificações, %d falhas"%[checks,failures])
	quit(0 if failures==0 else 1)

func reachable(world) -> Dictionary:
	# Malha somente de auditoria de acesso, nunca usada pela navegação do jogo.
	var queue: Array[Vector2i]=[]
	var result: Dictionary={}
	var start=Vector2i(roundi(world.leader_position.x/20),roundi(world.leader_position.y/20))
	queue.append(start)
	result[start]=true
	var cursor=0
	while cursor<queue.size():
		var point=queue[cursor]
		cursor+=1
		for axis in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=point+axis
			if result.has(next) or not world.can_traverse(Vector2(point)*20,Vector2(next)*20):
				continue
			result[next]=true
			queue.append(next)
	return result

func test_layouts() -> void:
	var total=0
	for id in floors:
		var definition: Dictionary=areas[id]
		expect(Catalog.valid_map(definition),"Andar válido: "+id)
		expect(definition["world_size"][0]>1120 and definition["world_size"][1]>760,"Andar ampliado, sem reduzir zoom")
		var world=World.new(definition,["p1","p2","p3","p4"])
		var cells=reachable(world)
		if id=="test_dungeon":
			var lever=world.entity_by_id("lever_01")
			expect(cells.has(Vector2i(roundi(lever["position"].x/20),roundi(lever["position"].y/20))),"Alavanca alcançável antes de abrir portão")
			world.toggle_door("door_01")
			cells=reachable(world)
		expect(cells.size()>1000,"Área ampla conectada ao ponto de entrada")
		for entry in definition["entries"]:
			expect(not world.prepare_arrival(entry,["p1","p2","p3","p4"]).is_empty(),"Escada/entrada comporta quatro: "+id+entry)
		for entity in world.entities:
			var point: Vector2=entity["position"]
			var near=false
			for offset in [Vector2.ZERO,Vector2(40,0),Vector2(-40,0),Vector2(0,40),Vector2(0,-40)]:
				near=near or cells.has(Vector2i(roundi((point.x+offset.x)/20),roundi((point.y+offset.y)/20)))
			expect(near,"Acesso alcançável: "+id+entity["id"])
			if entity["kind"]!="encounter":
				continue
			total+=1
			expect(entity["route_state"]["points"].size()>=3,"Todos os seis inimigos possuem patrulha definida")
			var route: Array=entity["route_state"]["points"]
			for index in range(route.size()):
				var a: Vector2=route[index]
				var b: Vector2=route[(index+1)%route.size()]
				expect(world.can_traverse(a,b),"Rota não cruza sólido: "+entity["id"]+str(index))
				expect(world.is_walkable(a),"Ponto de patrulha cabe no chão")
		expect(areas["test_world"]["encounters"].is_empty(),"Mapa-múndi sem monstros")
	expect(total==6,"Seis encontros preservados, três por piso")

func test_geometry() -> void:
	var session=fixture()
	var world=session.world
	world.data["wall_shapes"]=[{"points":[[400,200],[600,350],[560,450],[360,300]],"rect":[360,200,240,250]}]
	world._rebuild_obstacles()
	expect(not world.clear_sight(Vector2(300,300),Vector2(650,300)),"Parede inclinada bloqueia percepção")
	expect(not world.can_traverse(Vector2(300,300),Vector2(650,300)),"Volume impede atravessar diagonal")
	world.leader_position=Vector2(300,300)
	world.path.assign([Vector2(198,300),world.leader_position])
	world.path_length=102
	world.data["encounter_rules"]["automatic_contact"]=false
	world.move(Vector2.RIGHT,2)
	expect(world.leader_position.x>300 and world.leader_position.x<400 and world.is_walkable(world.leader_position),"Colisão varrida para antes da parede inclinada: "+str(world.leader_position))
	expect(world.clear_sight(Vector2(300,500),Vector2(650,500)),"Espaço abaixo da diagonal permanece livre")
	var invalid: Dictionary=areas["test_dungeon"].duplicate(true)
	invalid["encounter_rules"]["speed_transition_seconds"]=0
	expect(not Catalog.valid_map(invalid),"Transição de velocidade nula recusada")
	invalid=areas["test_dungeon"].duplicate(true)
	invalid["wall_shapes"][0]["points"]=[[0,0],[100,0],[0,0]]
	expect(not Catalog.valid_map(invalid),"Polígono degenerado recusado")

func test_territory() -> void:
	var session=fixture()
	var world=session.world
	var enemy=world.entity_by_id("enemy")
	var geometry=enemy["route_state"]["points"].duplicate()
	expect(Territory.contains(enemy,Vector2(500,530),240) and not Territory.contains(enemy,Vector2(500,550),240),"Território mede distância da rota inteira")
	world.leader_position=Vector2(400,440)
	world.advance(0.4)
	expect(enemy["awareness"]["state"]=="chase","Detecta dentro da faixa original")
	var departure: Vector2=enemy["awareness"]["trail"][0]
	world.leader_position=Vector2(500,540)
	world.advance(0.3)
	world.leader_position=Vector2(1500,1300)
	var before: Vector2=enemy["position"]
	world.advance(STEP)
	expect(enemy["awareness"]["state"]=="return","Perda de visão/alcance encerra perseguição")
	for step in range(400):
		world.advance(STEP)
		if enemy["awareness"]["state"]=="patrol":
			break
	expect(enemy["position"].x>departure.x+5 and is_equal_approx(enemy["position"].y,300),"Retoma trecho mais próximo, sem voltar ao ponto de saída")
	var resumed_x: float=enemy["position"].x
	world.advance(0.1)
	expect(enemy["position"].x>resumed_x,"Continua naturalmente no sentido da rota")
	# Novas percepções durante retorno não criam novas origens territoriais.
	for cycle in range(4):
		world.leader_position=enemy["position"]+Vector2(0,140)
		world.advance(0.2)
		expect(enemy["awareness"]["state"]=="chase","Pode perceber novamente dentro do território")
		world.leader_position=enemy["position"]+Vector2(0,170)
		for step in range(100):
			world.advance(STEP)
			expect(Territory.contains(enemy,enemy["position"],240),"Repetir perseguição não afasta além da faixa original")
		world.leader_position=Vector2(enemy["position"].x,560)
		world.advance(STEP)
		expect(enemy["awareness"]["state"]!="chase","Líder fora do território não provoca nova perseguição")
		expect(enemy["route_state"]["points"]==geometry,"Geometria da patrulha permanece imutável")
		world.leader_position=Vector2(1500,1300)
		world.advance(3)
	# Parede encerra perseguição na mesma atualização.
	world.leader_position=enemy["position"]+Vector2(0,100)
	world.advance(0.2)
	world.obstacles.append(Rect2(enemy["position"]+Vector2(-50,35),Vector2(100,10)))
	world.advance(STEP)
	expect(enemy["awareness"]["state"]!="chase","Quebra de visão por parede cancela perseguição imediatamente")

func travel(session,id: String) -> void:
	var portal=session.world.entity_by_id(id)
	session.world.leader_position=portal["position"]+Vector2(0,40)
	expect(session.begin_transition(id),"Escada/saída disponível: "+id)
	session.tick(session.transition_duration)
	expect(session.state=="exploration","Fade termina: "+id)

func test_stairs() -> void:
	var session=Session.new(data.duplicate(true),areas["test_dungeon"],areas)
	session.world.menu_open=true
	session.world.choose_leader("p3")
	session.battle.party[0]["hp"]=19
	session.battle.party[1]["hp"]=0
	session.battle.party[2]["mp"]=9
	session.battle.inventory["remedy_test"]=1
	session.clock.set_time(23,0)
	var lower=session.world
	lower.entity_by_id("test_map_enemy_01")["present"]=false
	lower.entity_by_id("chest_01")["open"]=true
	travel(session,"stairs_up")
	expect(session.area_id=="test_dungeon_upper" and session.world.party_order[0]=="p3","Subida mantém liderança")
	for p in session.world.formation_positions():
		expect(session.world.is_walkable(p),"Fila segura na escada superior")
	var upper=session.world
	upper.entity_by_id("test_map_enemy_04")["present"]=false
	var frozen=lower.entities.duplicate(true)
	session.tick(2)
	expect(lower.entities==frozen,"Andar inativo pausa perseguições/patrulhas")
	travel(session,"stairs_down")
	expect(session.world==lower and not lower.entity_by_id("test_map_enemy_01")["present"] and lower.entity_by_id("chest_01")["open"],"Retorno preserva encontro removido e objeto")
	expect(session.battle.party[0]["hp"]==19 and session.battle.party[1]["hp"]==0 and session.battle.party[2]["mp"]==9 and session.battle.inventory["remedy_test"]==1,"Andares não restauram HP/MP, KO ou estoque")
	expect(session.clock.time_text()=="23:00","Relógio da sessão continua pausado na dungeon")
	travel(session,"stairs_up")
	expect(session.world==upper and not upper.entity_by_id("test_map_enemy_04")["present"],"Revisita preserva estado do segundo piso")
	# Batalha e fuga no segundo piso voltam à área correta.
	var enemy=upper.entity_by_id("test_map_enemy_05")
	upper.leader_position=enemy["position"]
	session.tick(STEP)
	expect(session.state=="battle" and session.active_encounter_area_id=="test_dungeon_upper","Contato inicia combate no piso correto")
	session.battle.outcome="escaped" # Fixture: testa roteamento/persistência, cálculo de fuga tem suíte própria.
	expect(session.finish_encounter() and session.world==upper and not enemy["present"],"Fuga remove encontro somente no piso de origem")
	var reset=Session.new(data.duplicate(true),areas["test_dungeon"],areas)
	expect(reset.world.entity_by_id("test_map_enemy_01")["present"] and reset.battle.inventory["remedy_test"]==3,"Nova sessão restaura pisos/recursos")

func test_parity() -> void:
	var lab=Battle.new(Bridge.extend_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))))
	lab.start(lab.default_preset_index())
	for id in floors:
		for encounter in areas[id]["encounters"]:
			var session=Session.new(data.duplicate(true),areas[id],areas)
			session.world.leader_position=Vector2(encounter["position"][0],encounter["position"][1])
			session.tick(STEP)
			expect(session.state=="battle" and session.battle.uses_damage_v1(),"Cada encontro dos dois pisos inicia V1")
			for index in range(3):
				for key in ["damage_stats","loadout","skills","max_hp","max_mp","ini"]:
					expect(session.battle.party[index][key]==lab.party[index][key],"Mesmos dados de aliado: "+key)
			for actor in session.battle.enemies:
				var reference: Dictionary=lab.enemies.filter(func(e):return e["reference_profile_id"]==actor["reference_profile_id"])[0]
				for key in ["damage_stats","skills","actions","max_hp","max_mp","ini"]:
					expect(actor[key]==reference[key],"Mesma referência inimiga: "+key)
			expect(session.battle.preset["can_escape"]==(encounter["id"]!="test_map_enemy_02"),"Só M2 mantém bloqueio de fuga")
