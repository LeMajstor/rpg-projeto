extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
var battle_data: Dictionary
var definitions: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	definitions = Catalog.load_definitions()
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	var config = definitions.duplicate(true)
	return Session.new(battle_data.duplicate(true), config["lab_exterior"], config)

func place(session, position: Vector2) -> void:
	session.world.leader_position = position
	session.world.path.assign([position - Vector2(102, 0), position])
	session.world.path_length = 102

func travel(session, id: String) -> void:
	if id == "dungeon_entrance" and session.area_id == "lab_exterior":
		travel(session, "town_exit")
	if id == "house_entrance" and session.area_id == "test_world":
		travel(session, "enter_town")
	var portal: Dictionary = session.world.entity_by_id(id)
	place(session, portal["position"] + Vector2(0, -40 if id.ends_with("exit") else 40))
	expect(session.begin_transition(id), "Transição disponível: " + id)
	session.tick(session.transition_duration)
	expect(session.state == "exploration", "Transição conclui: " + id)

func close_dialogue(session) -> void:
	for step in range(12):
		if not session.dialogue.opened:
			return
		if session.dialogue.choices().is_empty():
			session.advance_dialogue()
		else:
			session.choose_response(0)
	expect(false, "Diálogo deve concluir")

func snapshots(world) -> Array:
	var result: Array = []
	for entity in world.entities:
		result.append({"route": entity["route_state"].duplicate(true), "position": entity["position"]})
	return result

func finish_action(battle) -> void:
	for step in range(110):
		if battle.action.is_empty():
			break
		battle.tick(1.0 / 120.0)
	expect(battle.action.is_empty(), "Ação do combate conclui")

func win(session) -> void:
	for enemy in session.battle.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	expect(session.battle.submit("all"), "Onda existente aceita")
	finish_action(session.battle)
	expect(session.battle.outcome == "victory" and session.finish_encounter(), "Vitória real e retorno")

func _run() -> void:
	for test in [_test_distribution, _test_routes_and_entries, _test_accessibility,
		_test_house_dialogues, _test_dungeon_objects_and_walk, _test_all_encounters,
		_test_three_area_persistence, _test_escape_and_reset]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("INTERIORES: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_distribution() -> void:
	expect(definitions.size() == 5, "Catálogo contém vila, mundo, duas casas e dungeon")
	var exterior: Dictionary = definitions["lab_exterior"]
	expect(exterior["npcs"].size() == 2 and exterior["encounters"].is_empty() and exterior["objects"].size() == 1, "Vila permite NPCs nas ruas sem monstros")
	expect(exterior["transitions"].size() == 3 and not exterior["obstacles"].is_empty(), "Vila conecta duas casas e mundo, conservando obstáculos")
	var house: Dictionary = definitions["test_house"]
	var dungeon: Dictionary = definitions["test_dungeon"]
	expect(house["npcs"].size() == 3 and house["encounters"].is_empty(), "Casa contém três NPCs e nenhum monstro")
	expect(dungeon["encounters"].size() == 6 and dungeon["npcs"].is_empty(), "Dungeon contém seis encontros e nenhum NPC")
	expect(house["objects"].size() == 1 and house["objects"][0]["object_type"] == "sign", "Placa de teste na casa")
	var types: Array = []
	for object in dungeon["objects"]:
		types.append(object["object_type"])
	expect(types.has("chest") and types.has("door") and types.has("lever"), "Objetos locais conservados na dungeon")
	var presets: Array = []
	for encounter in dungeon["encounters"]:
		presets.append(encounter["battle_preset_id"])
	expect(presets.has("exploration_seeded_open") and presets.has("exploration_seeded_corners") and presets.has("exploration_seeded_sides") and presets.has("exploration_seeded_fullscreen"), "Todos os encontros usam presets com os ritmos atuais")
	var session = fresh()
	place(session, Vector2(945, 185))
	expect(not session.begin_encounter(), "Local antigo do monstro no exterior não inicia luta")

func _test_routes_and_entries() -> void:
	for id in definitions:
		var data: Dictionary = definitions[id]
		expect(Catalog.valid_map(data), "Mapa válido: " + id)
		var world = World.new(data, ["p1", "p2", "p3", "p4"])
		for entry in data["entries"]:
			var plan: Dictionary = world.prepare_arrival(entry, ["p4", "p1", "p2", "p3"])
			expect(not plan.is_empty(), "Entrada segura: " + id + ":" + entry)
			world.apply_arrival(plan)
			for point in world.formation_positions():
				expect(world.is_walkable(point), "Fila livre na chegada")
		for portal in data["transitions"]:
			expect(definitions.has(portal["target_area_id"]) and definitions[portal["target_area_id"]]["entries"].has(portal["target_entry_id"]), "Referência de portal válida")
		for entity in world.entities:
			if entity.get("object_type", "") == "door" or entity.get("solid", false):
				continue
			var state: Dictionary = entity["route_state"].duplicate(true)
			for step in range(200):
				Route.advance(state, 0.1)
				expect(world.is_walkable(Route.position_at(state, entity["position"])), "Posição/rota livre em " + id + ":" + entity["id"])

func reachable(world) -> Dictionary:
	var origin = Vector2(36, 36)
	var start = Vector2i((world.leader_position - origin) / 8)
	var visited = {start: true}
	var pending = [start]
	var head = 0
	while head < pending.size():
		var cell: Vector2i = pending[head]
		head += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if not visited.has(next) and world.is_walkable(origin + Vector2(next) * 8):
				visited[next] = true
				pending.append(next)
	return visited

func accessible(world, entity: Dictionary, cells: Dictionary) -> bool:
	var origin = Vector2(36, 36)
	var center = Vector2i((entity["position"] - origin) / 8)
	var previous: Vector2 = world.leader_position
	for x in range(center.x - 10, center.x + 11):
		for y in range(center.y - 10, center.y + 11):
			if cells.has(Vector2i(x, y)):
				world.leader_position = origin + Vector2(x, y) * 8
				if world.can_interact_with(entity) and world.interaction_candidate().get("id", "") == entity["id"]:
					world.leader_position = previous
					return true
	world.leader_position = previous
	return false

func _test_accessibility() -> void:
	for id in definitions:
		var world = World.new(definitions[id], ["p1", "p2", "p3", "p4"])
		if id != "lab_exterior":
			world.apply_arrival(world.prepare_arrival({"test_house": "from_lab", "test_dungeon": "from_exterior", "test_world": "from_town", "secret_house": "from_town"}[id], world.party_order))
		var cells = reachable(world)
		if id == "test_dungeon":
			expect(accessible(world, world.entity_by_id("lever_01"), cells), "Alavanca alcançável antes da porta")
			expect(accessible(world, world.entity_by_id("test_map_enemy_01"), cells), "M1 alcançável no primeiro setor")
			expect(not accessible(world, world.entity_by_id("test_map_enemy_02"), cells), "Porta fechada separa setor seguinte")
			world.toggle_door("door_01")
			cells = reachable(world)
		for entity in world.entities:
			expect(accessible(world, entity, cells), "Interação alcançável/selecionável: " + id + ":" + entity["id"])

func _test_house_dialogues() -> void:
	for definition in definitions["test_house"]["npcs"]:
		var session = fresh()
		travel(session, "house_entrance")
		var npc = session.world.entity_by_id(definition["id"])
		place(session, npc["position"])
		expect(session.interact() == "dialogue" and session.dialogue.speaker == npc["label"], "Cada NPC conversa dentro da casa")
		var position = session.world.leader_position
		var before = snapshots(session.world)
		session.tick(5)
		session.move(Vector2.RIGHT, 1)
		expect(session.world.leader_position == position and snapshots(session.world) == before, "Conversa pausa fila e patrulhas da casa")
		if definition["id"] == "npc_02":
			expect(session.dialogue.choices().size() == 2 and not session.advance_dialogue(), "Respostas explícitas mantidas")
			session.choose_response(1)
			expect(session.dialogue.node_id == "formation", "Ramo da resposta funciona no novo local")
		close_dialogue(session)
		session.tick(0.2)
		expect(not session.world.dialogue_open, "Fim libera mapa")
	var session = fresh()
	travel(session, "house_entrance")
	place(session, Vector2(550, 395))
	expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "sign", "Placa funciona na casa")

func _test_dungeon_objects_and_walk() -> void:
	var session = fresh()
	travel(session, "dungeon_entrance")
	# Caminho real desde a entrada: sobe pelo corredor, vira à alavanca e passa a porta.
	for segment in [[Vector2.RIGHT, 150.0], [Vector2.UP, 260.0], [Vector2.RIGHT, 23.0]]:
		for step in range(int(segment[1])):
			session.move(segment[0], 1.0 / 180.0)
			for position in session.world.formation_positions():
				expect(session.world.is_walkable(position), "Fila acompanha os corredores sem cortar sólidos")
	expect(session.world.leader_position.is_equal_approx(Vector2(333, 340)), "Alcança alavanca por percurso físico")
	expect(session.interact() == "dialogue" and session.world.entity_by_id("door_01")["open"], "Alavanca abre porta na dungeon")
	close_dialogue(session)
	session.move(Vector2.RIGHT, 147.0 / 180.0)
	expect(session.world.leader_position.is_equal_approx(Vector2(480, 340)), "Passagem aberta permite atravessar")
	var stock = session.battle.inventory.duplicate(true)
	place(session, Vector2(930, 650))
	expect(session.interact() == "dialogue" and session.world.entity_by_id("chest_01")["open"], "Baú funciona no novo setor")
	close_dialogue(session)
	session.interact()
	expect(session.dialogue.dialogue_id == "chest_repeat" and session.battle.inventory == stock, "Baú repetido não cria recompensa")

func _test_all_encounters() -> void:
	for definition in definitions["test_dungeon"]["encounters"]:
		var session = fresh()
		travel(session, "dungeon_entrance")
		session.world.toggle_door("door_01")
		var world = session.world
		var entity = world.entity_by_id(definition["id"])
		place(session, entity["position"])
		var formation = world.formation_positions()
		var before = snapshots(world)
		session.battle.party[0]["hp"] = 91
		session.battle.party[0]["mp"] = 30
		var shared = session.battle
		expect(session.interact() == "battle" and session.battle == shared, "Cada monstro inicia o combate compartilhado")
		expect(session.battle.preset["id"] == definition["battle_preset_id"] and session.active_encounter_area_id == "test_dungeon", "Preset e origem corretos")
		win(session)
		expect(session.world == world and session.area_id == "test_dungeon" and world.formation_positions() == formation, "Vitória retorna à mesma dungeon e fila")
		expect(session.battle.party[0]["hp"] == 91 and session.battle.party[0]["mp"] == 20, "HP e gasto de MP preservados")
		var present = 0
		for other in world.entities:
			if other["kind"] == "encounter" and other["present"]:
				present += 1
		expect(present == 5 and not entity["present"] and snapshots(world) == before, "Somente o ID vencido desaparece, rotas preservadas")

func _test_three_area_persistence() -> void:
	var session = fresh()
	travel(session, "house_entrance")
	session.tick(0.75)
	session.world.menu_open = true
	session.world.choose_leader("p3")
	var order = session.world.party_order.duplicate()
	var house = session.world
	var house_before = snapshots(house)
	travel(session, "house_exit")
	travel(session, "dungeon_entrance")
	var dungeon = session.world
	dungeon.toggle_door("door_01")
	dungeon.entity_by_id("chest_01")["open"] = true
	place(session, Vector2(200, 260))
	session.begin_encounter()
	win(session)
	session.tick(0.7)
	var before = snapshots(dungeon)
	travel(session, "dungeon_exit")
	travel(session, "house_entrance")
	expect(session.world == house and snapshots(house) == house_before, "Casa retoma a mesma instância e patrulhas")
	session.tick(1)
	expect(snapshots(dungeon) == before, "Dungeon inativa não avança")
	travel(session, "house_exit")
	travel(session, "dungeon_entrance")
	expect(session.world == dungeon and dungeon.party_order == order, "Três áreas conservam líder escolhido")
	expect(dungeon.entity_by_id("chest_01")["open"] and dungeon.entity_by_id("door_01")["open"] and not dungeon.entity_by_id("test_map_enemy_01")["present"], "Revisita conserva objetos e vitória")
	var expected = dungeon.entity_by_id("test_map_enemy_03")["route_state"].duplicate(true)
	Route.advance(expected, 0.25)
	session.tick(0.25)
	expect(dungeon.entity_by_id("test_map_enemy_03")["route_state"] == expected, "Rota retoma do progresso exato")

func _test_escape_and_reset() -> void:
	var session = fresh()
	travel(session, "dungeon_entrance")
	place(session, Vector2(200, 260))
	session.begin_encounter()
	for enemy in session.battle.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.data["settings"]["escape_chance"] = 1
	session.battle.party[0]["hp"] = 71
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	session.battle.submit("escape")
	finish_action(session.battle)
	expect(session.finish_encounter() and session.area_id == "test_dungeon", "Fuga retorna à dungeon")
	expect(session.world.entity_by_id("test_map_enemy_01")["present"] and session.battle.party[0]["hp"] == 71, "Fuga mantém monstro e recursos")
	travel(session, "dungeon_exit")
	travel(session, "house_entrance")
	expect(session.battle.party[0]["hp"] == 71, "Visitar casa não cura")
	var reset = fresh()
	expect(reset.area_id == "lab_exterior" and reset.area_worlds.size() == 1, "Reinício começa no exterior limpo")
	travel(reset, "dungeon_entrance")
	expect(reset.world.entity_by_id("test_map_enemy_01")["present"] and not reset.world.entity_by_id("chest_01")["open"] and not reset.world.entity_by_id("door_01")["open"], "Reinício restaura dungeon")
