extends SceneTree
const World = preload("res://scripts/exploration/exploration_model.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const STEP = 1.0 / 120.0
var checks = 0
var failures = 0
var areas: Dictionary
var battle_data: Dictionary

func _initialize() -> void:
	areas = preload("res://tests/fixtures/pre_individual_catalog.gd").load_definitions()
	battle_data = Bridge.exploration_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func definition() -> Dictionary:
	var map: Dictionary = areas["test_dungeon"].duplicate(true)
	map["spawn"] = [100, 300]
	map["obstacles"] = []
	map["wall_shapes"] = []
	map["objects"] = []
	map["npcs"] = []
	map["transitions"] = []
	map["encounters"] = [{"id":"enemy", "label":"Fixture", "position":[300,300], "battle_preset_id":"exploration_seeded_open"}]
	return map

func fresh(map: Dictionary = {}):
	return Session.new(battle_data.duplicate(true), definition() if map.is_empty() else map)

func finish(battle) -> void:
	for step in range(240):
		if battle.action.is_empty():
			return
		battle.tick(STEP)
	expect(false, "Apresentação conclui")

func run() -> void:
	test_detection_and_return()
	test_speed_and_pause()
	test_fixed_chase_limit()
	test_contact()
	test_escape_and_persistence()
	test_catalog()
	print("PERSEGUIÇÃO EXPLORAÇÃO: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_detection_and_return() -> void:
	var session = fresh()
	var world = session.world
	var enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(481,300)
	world.advance(STEP)
	expect(enemy["awareness"]["state"] == "patrol" and enemy["position"] == Vector2(300,300), "181 unidades não detectam")
	world.leader_position = Vector2(480,300)
	var route = enemy["route_state"].duplicate(true)
	world.advance(STEP)
	expect(enemy["awareness"]["state"] == "chase" and enemy["position"].x>300 and enemy["position"].x<=301.2, "180 unidades detectam e perseguem a 144/s")
	expect(enemy["route_state"] == route, "Perseguição congela progresso da patrulha")
	world.advance(0.25)
	var origin: Vector2 = enemy["awareness"]["trail"][0]
	world.leader_position = Vector2(900,600)
	world.advance(2)
	expect(enemy["position"] == origin and enemy["awareness"]["state"] == "patrol", "Fora de 180 retorna sem teleporte")
	expect(enemy["route_state"] == route, "Retorno preserva snapshot da rota estática")
	# Parede entre os centros impede detectar dentro do raio.
	var map = definition()
	map["obstacles"] = [{"rect":[360,250,20,100]}]
	session = fresh(map)
	world = session.world
	enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(420,300)
	world.advance(3)
	expect(enemy["position"] == Vector2(300,300) and enemy["awareness"]["state"] == "patrol", "Parede bloqueia percepção")
	# Uma porta abre e fecha a linha de percepção, sem nova cópia de obstáculos.
	map["obstacles"] = []
	map["objects"] = [{"id":"door", "label":"Fixture", "position":[370,300], "object_type":"door", "rect":[360,250,20,100]}]
	session = fresh(map)
	world = session.world
	enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(420,300)
	world.advance(STEP)
	expect(enemy["awareness"]["state"] == "patrol", "Porta fechada bloqueia visão")
	world.toggle_door("door")
	world.advance(0.1)
	expect(enemy["awareness"]["state"] == "chase", "Porta aberta permite detectar")
	world.toggle_door("door")
	world.advance(0.1)
	expect(enemy["awareness"]["state"] != "chase" and enemy["position"].x <= 314.5, "Perder visão interrompe perseguição")
	# Se fechar a porta atrás do perseguidor, ele espera e retorna após reabertura.
	world.toggle_door("door")
	world.leader_position = Vector2(480,300)
	world.advance(0.9)
	expect(enemy["position"].x > 392, "Inimigo cruzou a porta aberta")
	world.leader_position = Vector2(700,600)
	expect(world.toggle_door("door") == "door_closed", "Porta pode fechar após passagem do inimigo")
	var blocked_position: Vector2 = enemy["position"]
	world.advance(0.5)
	expect(enemy["position"].x >= 392 and enemy["position"].x <= blocked_position.x and enemy["awareness"]["state"] == "return", "Retorno aproxima-se e espera sem atravessar porta fechada")
	blocked_position = enemy["position"]
	world.advance(0.5)
	expect(enemy["position"] == blocked_position, "Porta bloqueada não consome a trilha de retorno")
	world.toggle_door("door")
	world.advance(3)
	expect(enemy["position"] == Vector2(300,300) and enemy["awareness"]["state"] == "patrol", "Reabrir porta permite completar retorno")
	enemy["position"] = Vector2(370,300)
	expect(world.toggle_door("door") == "door_blocked", "Porta não fecha sobre corpo do inimigo")
	# Patrulha móvel sai de um segmento parcial e retoma exatamente ali.
	map = definition()
	map["encounters"][0]["route"] = [[300,300],[350,300],[350,350]]
	map["encounters"][0]["speed"] = 40
	session = fresh(map)
	world = session.world
	enemy = world.entity_by_id("enemy")
	world.advance(0.25)
	route = enemy["route_state"].duplicate(true)
	origin = enemy["position"]
	world.leader_position = origin + Vector2(100,60)
	world.advance(0.2)
	world.leader_position = enemy["position"] + Vector2(60,100)
	world.advance(0.2)
	world.leader_position = Vector2(900,600)
	for step in range(120):
		world.advance(STEP)
		expect(world.is_walkable(enemy["position"]), "Retorno pela trilha permanece no chão livre")
		if enemy["awareness"]["state"] == "patrol":
			break
	expect(is_equal_approx(world.EncounterMotion.Territory.projection(enemy,enemy["position"])["distance"],0.0), "Retoma trecho da patrulha mais próximo")
	var previous_position: Vector2=enemy["position"]
	world.advance(STEP)
	expect(enemy["position"].distance_to(previous_position)>0 and enemy["position"].distance_to(previous_position)<=144*STEP+0.001 and is_equal_approx(world.EncounterMotion.Territory.projection(enemy,enemy["position"])["distance"],0.0), "Patrulha continua na rota com transição de velocidade")

func test_speed_and_pause() -> void:
	var session = fresh()
	var world = session.world
	var enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(400,300)
	world.advance(STEP)
	var before = enemy.duplicate(true)
	for pause in ["menu_open", "dialogue_open", "transitioning"]:
		world.set(pause, true)
		world.advance(1)
		expect(enemy == before, "Pausa preserva estado e posição: " + pause)
		world.set(pause, false)
	world.menu_open = true
	expect(world.choose_leader("p3") and world.party_order[0] == "p3", "Líder atual vem do menu")
	world.leader_position = Vector2(400,340)
	var start: Vector2 = enemy["position"]
	world.advance(STEP)
	expect((enemy["position"] - start).normalized().distance_to((world.leader_position - start).normalized())<0.005, "Persegue posição do líder atual, sem procurar protagonista na fila")
	# Caminho livre: líder ganha distância e sai do alcance.
	session = fresh()
	world = session.world
	enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(400,300)
	var initial = world.leader_position.distance_to(enemy["position"])
	for step in range(300):
		session.move(Vector2.RIGHT, STEP)
		session.tick(STEP)
	expect(session.state == "exploration" and world.leader_position.distance_to(enemy["position"]) > initial, "Líder consegue escapar andando")
	expect(enemy["awareness"]["state"] != "chase", "Distância crescente encerra perseguição")
	# Uma quina pode bloquear o corpo, mesmo quando os centros se enxergam.
	var map = definition()
	map["obstacles"] = [{"rect":[340,310,60,60]}]
	session = fresh(map)
	world = session.world
	enemy = world.entity_by_id("enemy")
	world.leader_position = Vector2(430,300)
	world.advance(0.2)
	expect(world.is_walkable(enemy["position"]), "Perseguidor não atravessa sólido")

func test_fixed_chase_limit() -> void:
	var session = fresh()
	var world = session.world
	var enemy = world.entity_by_id("enemy")
	# Território atual em torno da rota original, não da última perseguição.
	world.leader_position = Vector2(450,300)
	world.advance(0.2)
	expect(enemy["awareness"]["state"] == "chase", "Persegue dentro do território")
	world.leader_position = Vector2(560,300)
	world.advance(STEP)
	expect(enemy["awareness"]["state"] != "chase", "Fora de240 da rota original interrompe perseguição")
	expect(world.EncounterMotion.Territory.contains(enemy,enemy["position"],240), "Inimigo permanece no território original")
	world.leader_position = Vector2(900,600)
	world.advance(3)
	expect(enemy["position"] == Vector2(300,300), "Rota estática permanece no ponto original")

func test_contact() -> void:
	var session = fresh()
	var world = session.world
	world.leader_position = Vector2(380,300)
	world.path.assign([Vector2(278,300),world.leader_position])
	world.path_length = 102
	expect(world.formation_positions()[2].distance_to(Vector2(300,300)) < world.contact_radius(), "Fixture põe seguidor sobre inimigo")
	session.tick(STEP)
	expect(session.state == "exploration", "Contato com seguidor não inicia batalha")
	expect(not session.begin_encounter("enemy") and session.interact().is_empty(), "E e proximidade não substituem contato do líder")
	# O líder cruza um inimigo com delta longo: para no primeiro contato.
	session = fresh()
	world = session.world
	var moved: Vector2 = session.move(Vector2.RIGHT, 3)
	expect(session.state == "battle" and session.active_encounter_id == "enemy", "Movimento dispara combate sem E")
	expect(world.leader_position.is_equal_approx(Vector2(276,300)) and moved.is_equal_approx(Vector2(176,0)), "Contato varrido não pula o inimigo nem avança além do impacto")
	expect(not session.begin_encounter("enemy"), "Não inicia batalha duplicada")
	var positions = world.formation_positions()
	session.move(Vector2.RIGHT, 1)
	session.tick(1)
	expect(world.formation_positions() == positions, "Mapa congelado em batalha")
	# Inimigo alcança líder parado; tick inicia a mesma batalha compartilhada.
	session = fresh()
	world = session.world
	world.leader_position = Vector2(360,300)
	var model = session.battle
	session.tick(1)
	expect(session.state == "battle" and session.battle == model and model.uses_damage_v1(), "Perseguidor encosta e inicia modelo atual")
	expect(is_equal_approx(world.leader_position.distance_to(world.entity_by_id("enemy")["position"]), world.contact_radius()), "Inimigo para no primeiro contato")
	# Nem contato numérico através de uma parede permite combate.
	var map = definition()
	map["obstacles"] = [{"rect":[309,250,2,100]}]
	session = fresh(map)
	session.world.leader_position = Vector2(320,300)
	session.tick(STEP)
	expect(session.state == "exploration", "Parede impede contato através dela")
	# Contatos simultâneos: ordem estável e só um encontro.
	map = definition()
	var other: Dictionary = map["encounters"][0].duplicate(true)
	other["id"] = "other"
	map["encounters"].append(other)
	session = fresh(map)
	session.world.leader_position = Vector2(300,300)
	session.tick(STEP)
	expect(session.active_encounter_id == "enemy", "Empate resolve pela ordem do catálogo")

func test_escape_and_persistence() -> void:
	var session = fresh()
	session.world.leader_position = Vector2(300,300)
	session.tick(STEP)
	var battle = session.battle
	for actor in battle.actors():
		actor["ini_modifier"] = -actor["ini"]
	battle.party[0]["hp"] = 17
	battle.party[1]["hp"] = 0
	battle.party[2]["mp"] = 11
	battle.inventory["remedy_test"] = 1
	battle.data["settings"]["escape_chance"] = 0.0
	battle.party[0]["atb"] = 1
	battle.select_actor("p1")
	expect(battle.submit("escape"), "Tentativa de fuga usa regra compartilhada")
	finish(battle)
	expect(not session.finish_encounter() and session.world.entity_by_id("enemy")["present"], "Fuga falha mantém luta e encontro")
	battle.data["settings"]["escape_chance"] = 1.0
	battle.party[0]["atb"] = 1
	battle.select_actor("p1")
	battle.submit("escape")
	finish(battle)
	expect(session.finish_encounter() and battle.outcome == "escaped" and not session.world.entity_by_id("enemy")["present"], "Fuga bem-sucedida remove encontro sem virar vitória")
	session.tick(1)
	expect(session.state == "exploration" and not session.begin_encounter("enemy"), "Contato anterior não reinicia luta")
	expect(battle.party[0]["hp"] == 17 and battle.party[1]["hp"] == 0 and battle.party[2]["mp"] == 11 and battle.inventory["remedy_test"] == 1, "HP/MP, KO e estoque preservados")
	# Cache real da sessão guarda o encontro removido entre visitas.
	session = Session.new(battle_data.duplicate(true), areas["test_dungeon"], areas)
	var enemy = session.world.entity_by_id("test_map_enemy_01")
	enemy["present"] = false
	var dungeon = session.world
	var portal = session.world.entity_by_id("dungeon_exit")
	session.world.leader_position = portal["position"] + Vector2(0,-40)
	expect(session.begin_transition("dungeon_exit"), "Saída real da dungeon")
	session.tick(session.transition_duration)
	portal = session.world.entity_by_id("dungeon_entrance")
	session.world.leader_position = portal["position"] + Vector2(0,40)
	expect(session.begin_transition("dungeon_entrance"), "Retorno real à dungeon")
	session.tick(session.transition_duration)
	expect(session.world == dungeon and not enemy["present"], "Revisita não restaura encontro removido")
	expect(fresh().world.entity_by_id("enemy")["present"], "Nova sessão restaura encontros")

func test_catalog() -> void:
	for id in areas:
		expect(Catalog.valid_map(areas[id]), "Área válida: " + id)
	expect(areas["test_dungeon"]["encounter_rules"]["detection_radius"] == 180 and areas["test_dungeon"]["encounter_rules"]["chase_speed"] == 144, "Valores aprovados centralizados")
	expect(not areas["test_world"].has("encounter_rules") and areas["test_world"]["encounters"].is_empty(), "Mapa-múndi continua sem inimigos/perseguição")
	for key in ["detection_radius", "chase_limit", "chase_speed"]:
		for value in [0, -1, NAN, INF, "invalid"]:
			var map = definition()
			map["encounter_rules"][key] = value
			expect(not Catalog.valid_map(map), "Parâmetro inválido recusado: " + key)
	var map = definition()
	map["encounter_rules"]["chase_speed"] = map["move_speed"]
	expect(not Catalog.valid_map(map), "Validação exige perseguidor mais lento")
