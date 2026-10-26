extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
const Depth = preload("res://scripts/exploration/exploration_depth.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
var definitions: Dictionary
var battle_data: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	definitions = Catalog.load_definitions()
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	var config = definitions.duplicate(true)
	return Session.new(battle_data.duplicate(true), config["lab_exterior"], config)

func place(session, point: Vector2) -> void:
	session.world.leader_position = point
	session.world.path.assign([point - Vector2(102, 0), point])
	session.world.path_length = 102

func travel(session, id: String) -> void:
	var portal: Dictionary = session.world.entity_by_id(id)
	place(session, portal["position"] + Vector2(0, 40))
	expect(session.begin_transition(id), "Acesso disponível: " + id)
	session.tick(session.transition_duration)
	expect(session.state == "exploration", "Viagem concluída: " + id)

func close_dialogue(session) -> void:
	for step in range(12):
		if not session.dialogue.opened:
			return
		if session.dialogue.choices().is_empty():
			session.advance_dialogue()
		else:
			session.choose_response(0)
	expect(false, "Diálogo termina")

func finish_action(battle) -> void:
	for step in range(110):
		if battle.action.is_empty():
			return
		battle.tick(1.0 / 120.0)
	expect(false, "Ação deve concluir")

func _run() -> void:
	for test in [_test_topology_and_content, _test_authoring, _test_physical_route,
		_test_landscape_collision, _test_street_npcs, _test_world_has_no_encounters,
		_test_four_area_persistence, _test_reset]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("MUNDO/VILA: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_topology_and_content() -> void:
	expect(definitions.size() == 5, "Cinco áreas: vila, duas casas, mundo e dungeon")
	var edges = {}
	var npc_ids = {}
	for id in definitions:
		var data: Dictionary = definitions[id]
		edges[id] = []
		for portal in data["transitions"]:
			edges[id].append(portal["target_area_id"])
		for npc in data["npcs"]:
			expect(not npc_ids.has(npc["id"]), "NPC só existe em uma área")
			npc_ids[npc["id"]] = id
		expect(data["encounters"].is_empty() or id == "test_dungeon", "Monstros comuns apenas na dungeon")
	expect(edges["lab_exterior"] == ["test_house", "test_world", "secret_house"], "Vila conecta as duas casas e mundo, sem dungeon direta")
	expect(edges["test_house"] == ["lab_exterior"] and edges["secret_house"] == ["lab_exterior"], "Duas casas retornam à vila")
	expect(edges["test_world"] == ["lab_exterior", "test_dungeon"], "Mundo conecta retorno à vila e dungeon")
	expect(edges["test_dungeon"] == ["test_world"], "Dungeon retorna ao mundo aberto")
	expect(npc_ids.size() == 5 and definitions["lab_exterior"]["npcs"].size() == 2 and definitions["test_house"]["npcs"].size() == 3, "Mesmos cinco NPCs distribuídos em casa e ruas")
	expect(definitions["test_world"]["npcs"].is_empty() and definitions["test_world"]["objects"].is_empty(), "Mundo contém paisagem e acessos")
	expect(definitions["test_dungeon"]["encounters"].size() == 6, "Seis encontros existentes mantidos")

func _test_authoring() -> void:
	for id in definitions:
		var data: Dictionary = definitions[id]
		expect(Catalog.valid_map(data), "Mapa válido: " + id)
		var map = World.new(data, ["p1", "p2", "p3", "p4"])
		for entry_id in data["entries"]:
			var plan: Dictionary = map.prepare_arrival(entry_id, map.party_order)
			expect(not plan.is_empty(), "Quatro integrantes cabem em " + id + ":" + entry_id)
			map.apply_arrival(plan)
			for point in map.formation_positions():
				expect(map.is_walkable(point), "Chegada fora de sólidos")
		for portal in data["transitions"]:
			expect(definitions.has(portal["target_area_id"]) and definitions[portal["target_area_id"]]["entries"].has(portal["target_entry_id"]), "Destino de acesso válido")
	var data: Dictionary = definitions["test_world"].duplicate(true)
	var kinds: Array = []
	for feature in data["terrain"]:
		kinds.append(feature["kind"])
	expect(kinds.has("forest") and kinds.has("hill") and kinds.has("path") and kinds.has("sand"), "Mundo contém florestas, colinas, caminhos e costa")
	data["terrain"][0]["rect"] = [1, 2]
	expect(not Catalog.valid_map(data), "Terreno visual malformado rejeitado")
	data = definitions["test_world"].duplicate(true)
	data["obstacles"][0]["ground_only"] = "bad"
	expect(not Catalog.valid_map(data), "Camada de chão inválida rejeitada")

func _test_physical_route() -> void:
	var session = fresh()
	for segment in [[Vector2.RIGHT, 1020.0], [Vector2.UP, 216.0]]:
		session.move(segment[0], segment[1] / 180.0)
	expect(session.world.leader_position == Vector2(1230, 284), "Caminho inicial alcança portão da vila")
	expect(session.interact() == "transition", "E no portão inicia saída")
	session.tick(session.transition_duration)
	expect(session.area_id == "test_world" and session.world.leader_position == Vector2(380, 1020), "Sai da vila no ponto correto do mundo")
	for segment in [[Vector2.RIGHT, 420.0], [Vector2.UP, 540.0], [Vector2.RIGHT, 740.0], [Vector2.UP, 46.0]]:
		for step in range(int(segment[1] / 2)):
			session.move(segment[0], 2.0 / 180.0)
			for point in session.world.formation_positions():
				expect(session.world.is_walkable(point), "Fila percorre caminho do mundo sem cortar sólidos")
	expect(session.world.leader_position.is_equal_approx(Vector2(1540, 434)), "Caminho leva à entrada da dungeon")
	expect(session.interact() == "transition", "Dungeon acessível a partir do mundo")
	session.tick(session.transition_duration)
	expect(session.area_id == "test_dungeon", "Chega ao interior da dungeon")
	travel(session, "dungeon_exit")
	expect(session.area_id == "test_world" and session.world.leader_position == Vector2(1540, 480), "Saída da dungeon retorna ao mundo")
	travel(session, "enter_town")
	expect(session.area_id == "lab_exterior" and session.world.leader_position == Vector2(1230, 310), "Interação no mundo permite entrar novamente na vila")

func _test_landscape_collision() -> void:
	var session = fresh()
	travel(session, "town_exit")
	var map = session.world
	place(session, Vector2(1600, 600))
	map.move(Vector2.RIGHT, 2)
	expect(map.leader_position.x == 1668, "Mar é sólido neste protótipo")
	place(session, Vector2(800, 130))
	map.move(Vector2.DOWN, 2)
	expect(map.leader_position.y == 168, "Base da montanha é sólida")
	place(session, Vector2(70, 585))
	map.move(Vector2.RIGHT, 100.0 / 180.0)
	expect(map.leader_position == Vector2(88, 585), "Colina bloqueia entrada pelo paredão")
	var order = Depth.draw_order(map)
	for obstacle in map.data["obstacles"]:
		if obstacle["kind"] == "water":
			expect(obstacle["ground_only"] and not order.any(func(entry): return entry.get("definition", {}) == obstacle), "Água fica no chão, sem oclusão sobre atores")
	expect(map.data["obstacles"].any(func(obstacle): return obstacle["kind"] == "mountain"), "Montanhas configuradas em dados")
	expect(map.data["obstacles"].any(func(obstacle): return obstacle["kind"] == "tree"), "Florestas usam árvores com profundidade e bases reais")

func _test_street_npcs() -> void:
	var session = fresh()
	for definition in definitions["lab_exterior"]["npcs"]:
		var npc = session.world.entity_by_id(definition["id"])
		place(session, npc["position"])
		expect(session.interact() == "dialogue" and session.dialogue.speaker == npc["label"], "NPC da rua usa diálogo existente")
		var position = session.world.leader_position
		var route = session.world.entity_by_id("npc_04")["route_state"].duplicate(true)
		session.move(Vector2.RIGHT, 1)
		session.tick(1)
		expect(session.world.leader_position == position and session.world.entity_by_id("npc_04")["route_state"] == route, "Diálogo externo pausa grupo e patrulha")
		close_dialogue(session)
	session.tick(0.5)
	expect(session.world.entity_by_id("npc_04")["position"] != Vector2(900, 500), "NPC de rua retoma patrulha")
	travel(session, "house_entrance")
	place(session, Vector2(380, 230))
	expect(session.interact() == "dialogue" and session.dialogue.choices().size() == 2, "NPCs e respostas permanecem na casa")

func _test_world_has_no_encounters() -> void:
	var session = fresh()
	travel(session, "town_exit")
	var bars = session.battle.party.duplicate(true)
	for point in [Vector2(380, 1020), Vector2(800, 480), Vector2(1540, 480), Vector2(1620, 1020)]:
		place(session, point)
		session.tick(30)
		expect(not session.begin_encounter() and session.state == "exploration", "Mundo não dispara encontros por tempo/proximidade")
	expect(session.battle.party == bars, "Percorrer o mundo não altera ATB, HP/MP ou combate")

func _test_four_area_persistence() -> void:
	var session = fresh()
	session.world.menu_open = true
	session.world.choose_leader("p4")
	var order = session.world.party_order.duplicate()
	session.battle.party[0]["hp"] = 82
	session.battle.party[0]["mp"] = 30
	session.battle.party[1]["hp"] = 0
	var shared = session.battle
	session.tick(0.6)
	var town = session.world
	var npc_route = town.entity_by_id("npc_04")["route_state"].duplicate(true)
	travel(session, "house_entrance")
	travel(session, "house_exit")
	travel(session, "town_exit")
	travel(session, "dungeon_entrance")
	var dungeon = session.world
	dungeon.toggle_door("door_01")
	dungeon.entity_by_id("chest_01")["open"] = true
	place(session, Vector2(200, 260))
	expect(session.begin_encounter() and session.active_encounter_area_id == "test_dungeon", "Batalha mantém origem dungeon")
	for enemy in session.battle.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	session.battle.submit("all")
	finish_action(session.battle)
	expect(session.finish_encounter() and session.world == dungeon, "Vitória retorna à dungeon")
	travel(session, "dungeon_exit")
	travel(session, "enter_town")
	expect(session.world == town and town.entity_by_id("npc_04")["route_state"] == npc_route, "Vila inativa conserva progresso da patrulha")
	travel(session, "house_entrance")
	travel(session, "house_exit")
	travel(session, "town_exit")
	travel(session, "dungeon_entrance")
	expect(session.area_worlds.size() == 4 and session.battle == shared and session.world.party_order == order, "Uma sessão preserva quatro áreas, equipe e combate compartilhado")
	expect(session.battle.party[0]["hp"] == 82 and session.battle.party[0]["mp"] == 20 and session.battle.party[1]["hp"] == 0, "HP/MP, gasto e incapacitação persistem em todas as viagens")
	expect(dungeon.entity_by_id("chest_01")["open"] and dungeon.entity_by_id("door_01")["open"] and not dungeon.entity_by_id("test_map_enemy_01")["present"], "Objetos e encontro vencido persistem")

func _test_reset() -> void:
	var session = fresh()
	travel(session, "town_exit")
	travel(session, "dungeon_entrance")
	session.world.entity_by_id("chest_01")["open"] = true
	var reset = fresh()
	expect(reset.area_id == "lab_exterior" and reset.area_worlds.size() == 1, "Reinício começa na vila e descarta outros estados")
	travel(reset, "town_exit")
	travel(reset, "dungeon_entrance")
	expect(not reset.world.entity_by_id("chest_01")["open"] and reset.world.entity_by_id("test_map_enemy_01")["present"], "Reinício restaura dungeon sem mudar topologia")
