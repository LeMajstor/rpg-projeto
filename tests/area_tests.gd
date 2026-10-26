extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
var battle_data: Dictionary
var definitions: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_internal_split.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh(config: Dictionary = {}):
	var data = definitions.duplicate(true) if config.is_empty() else config.duplicate(true)
	return Session.new(battle_data.duplicate(true), data["lab_exterior"], data)

func place(session, position: Vector2) -> void:
	session.world.leader_position = position
	session.world.path.assign([position - Vector2(102, 0), position])
	session.world.path_length = 102

func finish_transition(session) -> void:
	for step in range(60):
		if session.state != "transition":
			break
		session.tick(1.0 / 120.0)
	expect(session.state == "exploration" and session.transition.is_empty(), "Transição conclui e libera controles")

func enter(session) -> void:
	place(session, Vector2(840, 290))
	expect(session.interact() == "transition", "Entrada da casa inicia transição")
	finish_transition(session)
	expect(session.area_id == "test_house", "Destino é a casa")

func leave(session) -> void:
	place(session, Vector2(360, 385))
	expect(session.interact() == "transition", "Saída da casa inicia transição")
	finish_transition(session)
	expect(session.area_id == "lab_exterior", "Retorna ao laboratório externo")

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
	expect(battle.action.is_empty(), "Ação termina no combate compartilhado")

func _run() -> void:
	for test in [_test_catalog_and_entries, _test_round_trip_and_formation, _test_transition_phases,
		_test_persistence_and_patrols, _test_guards, _test_invalid_destinations, _test_revalidate_and_rearm,
		_test_battle_in_destination, _test_reset]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("ÁREAS: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_catalog_and_entries() -> void:
	expect(definitions.size() == 2, "Catálogo contém apenas exterior e casa")
	var session = fresh()
	for id in definitions:
		var config: Dictionary = definitions[id]
		expect(Catalog.valid_map(config) and config["id"] == id, "Definição válida com ID coerente")
		var world = session.World.new(config, session.world.party_order)
		for entry_id in config["entries"]:
			var plan: Dictionary = world.prepare_arrival(entry_id, ["p1", "p2", "p3", "p4"])
			expect(not plan.is_empty(), "Entrada comporta a fila inteira")
			world.apply_arrival(plan)
			for point in world.formation_positions():
				expect(world.is_walkable(point), "Slot de chegada fora de sólidos")
		for portal in config["transitions"]:
			expect(definitions.has(portal["target_area_id"]), "Portal referencia área existente")
			expect(definitions[portal["target_area_id"]]["entries"].has(portal["target_entry_id"]), "Portal referencia entrada existente")
	var invalid = definitions["test_house"].duplicate(true)
	invalid["spawn"] = [0]
	expect(not Catalog.valid_map(invalid), "Mapa malformado rejeitado")
	invalid = definitions["test_house"].duplicate(true)
	invalid["transitions"].append(invalid["transitions"][0])
	expect(not Catalog.valid_map(invalid), "IDs duplicados rejeitados")

func _test_round_trip_and_formation() -> void:
	var session = fresh()
	session.world.menu_open = true
	session.world.choose_leader("p3")
	var order = session.world.party_order.duplicate()
	var shared = session.battle
	session.battle.party[0]["hp"] = 87
	session.battle.party[0]["mp"] = 13
	session.battle.party[1]["hp"] = 0
	session.battle.inventory["hp"] = 1
	enter(session)
	expect(session.battle == shared, "Troca não recria modelo do combate")
	expect(session.world.party_order == order and session.world.facing == Vector2.UP, "Líder/ordem preservados e direção definida pelo destino")
	var expected = [Vector2(360, 300), Vector2(360, 334), Vector2(360, 368), Vector2(360, 402)]
	expect(session.world.formation_positions() == expected, "Quatro integrantes na trilha local de chegada")
	expect(session.world.path == [Vector2(360, 402), Vector2(360, 300)], "Histórico do exterior não cruza áreas")
	session.move(Vector2.UP, 0.1)
	for position in session.world.formation_positions():
		expect(session.world.is_walkable(position), "Seguimento retoma livre no interior")
	session.world.menu_open = true
	expect(session.world.choose_leader("p4"), "Menu permite mudar líder dentro da casa")
	order = session.world.party_order.duplicate()
	leave(session)
	expect(session.world.party_order == order and session.world.facing == Vector2.RIGHT, "Retorno conserva identidade e usa direção externa")
	expect(session.world.formation_positions() == [Vector2(840, 310), Vector2(806, 310), Vector2(772, 310), Vector2(738, 310)], "Fila externa reconstruída fora da casa")
	expect(session.battle.party[0]["hp"] == 87 and session.battle.party[0]["mp"] == 13, "HP e MP não restaurados")
	expect(session.battle.party[1]["hp"] == 0 and session.battle.inventory["hp"] == 1, "Incapacitação e estoque preservados")

func _test_transition_phases() -> void:
	var session = fresh()
	place(session, Vector2(840, 290))
	var world = session.world
	var original = world.formation_positions()
	var route = snapshots(world)
	expect(session.begin_transition(), "API de transição válida")
	expect(not session.begin_transition() and session.interact().is_empty(), "Solicitações duplicadas são bloqueadas")
	expect(session.move(Vector2.RIGHT, 1) == Vector2.ZERO and world.move(Vector2.RIGHT, 1) == Vector2.ZERO, "Sessão e modelo bloqueiam movimento")
	world.menu_open = true
	expect(not world.choose_leader("p4"), "Nem chamada direta muda liderança durante fade")
	world.menu_open = false
	session.tick(session.transition_duration * 0.25)
	expect(session.area_id == "lab_exterior" and is_equal_approx(session.transition_alpha, 0.5), "Escurece mantendo origem")
	session.tick(session.transition_duration * 0.25)
	expect(session.area_id == "test_house" and is_equal_approx(session.transition_alpha, 1.0), "Troca no preto total")
	expect(world.formation_positions() == original and snapshots(world) == route, "Origem não perde posições ou progresso")
	session.tick(session.transition_duration * 0.25)
	expect(session.state == "transition" and is_equal_approx(session.transition_alpha, 0.5), "Revela destino ainda com entrada bloqueada")
	session.tick(session.transition_duration * 0.25)
	expect(session.state == "exploration" and session.transition_alpha == 0 and not session.world.transitioning, "Fim remove bloqueio e overlay")
	var once = fresh()
	var divided = fresh()
	for candidate in [once, divided]:
		place(candidate, Vector2(840, 290))
		candidate.begin_transition()
	once.tick(10)
	for step in range(60):
		if divided.state == "transition":
			divided.tick(1.0 / 120.0)
	expect(once.area_id == divided.area_id and once.world.formation_positions() == divided.world.formation_positions(), "Delta grande conclui uma única transição")

func _test_persistence_and_patrols() -> void:
	var session = fresh()
	var exterior = session.world
	session.tick(0.73)
	exterior.entity_by_id("chest_01")["open"] = true
	exterior.toggle_door("door_01")
	exterior.entity_by_id("lever_01")["active"] = true
	# Vitória real antes de trocar de área.
	place(session, Vector2(945, 230))
	expect(session.begin_encounter(), "Encontro externo começa")
	for enemy in session.battle.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	session.battle.submit("all")
	finish_action(session.battle)
	expect(session.finish_encounter(), "Vitória real externa")
	var before = snapshots(exterior)
	enter(session)
	session.tick(20)
	expect(snapshots(exterior) == before, "Patrulhas de área inativa ficam exatamente pausadas")
	leave(session)
	expect(session.world == exterior and snapshots(exterior) == before, "Revisita reutiliza a instância de estado")
	expect(exterior.entity_by_id("chest_01")["open"] and exterior.entity_by_id("door_01")["open"] and exterior.entity_by_id("lever_01")["active"], "Objetos persistem entre áreas")
	expect(not exterior.entity_by_id("test_map_enemy_01")["present"] and exterior.entity_by_id("test_map_enemy_02")["present"], "Vitória mantém apenas o ID vencido ausente")
	var expected = exterior.entity_by_id("npc_04")["route_state"].duplicate(true)
	Route.advance(expected, 0.25)
	session.tick(0.25)
	expect(exterior.entity_by_id("npc_04")["route_state"] == expected, "Patrulha retoma exatamente do progresso anterior")

func _test_guards() -> void:
	var session = fresh()
	expect(not session.begin_transition("house_entrance"), "Não transporta remotamente por ID")
	place(session, Vector2(840, 290))
	session.world.menu_open = true
	expect(not session.begin_transition(), "Menu impede transição")
	session.world.menu_open = false
	session.dialogue.start("welcome", "NPC 1")
	session.world.dialogue_open = true
	expect(not session.begin_transition("house_entrance"), "Diálogo impede transição")
	session.advance_dialogue()
	session.advance_dialogue()
	place(session, Vector2(945, 230))
	session.begin_encounter()
	expect(not session.begin_transition("house_entrance"), "Batalha impede transição")
	for member in session.battle.party:
		member["hp"] = 0
	session.battle._check_end()
	session.finish_encounter()
	expect(not session.begin_transition("house_entrance"), "Game Over impede transição")

func _test_invalid_destinations() -> void:
	for invalid in ["area", "entry", "solid", "tail", "segment", "facing", "format", "duration"]:
		var session = fresh()
		place(session, Vector2(840, 290))
		var portal = session.world.entity_by_id("house_entrance")
		var config: Dictionary = session.area_definitions["test_house"]
		match invalid:
			"area": portal["target_area_id"] = "missing"
			"entry": portal["target_entry_id"] = "missing"
			"solid": config["entries"]["from_lab"]["position"] = [200, 180]
			"tail": config["entries"]["from_lab"]["position"] = [360, 410]
			"segment": config["obstacles"].append({"rect": [345, 342, 30, 8], "label": ""})
			"facing": config["entries"]["from_lab"]["facing"] = [1, 1]
			"format": config["spawn"] = "bad"
			"duration": session.transition_duration = 0
		var world = session.world
		var position = world.leader_position
		var path = world.path.duplicate()
		var party = session.battle.party.duplicate(true)
		expect(not session.begin_transition(), "Destino inválido recusado: " + invalid)
		expect(session.world == world and session.state == "exploration" and not world.transitioning, "Falha deixa origem e controles utilizáveis: " + invalid)
		expect(world.leader_position == position and world.path == path and session.battle.party == party, "Falha não perde estado: " + invalid)
		expect(session.transition.is_empty() and session.transition_alpha == 0 and session.area_worlds.size() == 1, "Falha não deixa cache parcial ou overlay: " + invalid)
		expect(session.move(Vector2.RIGHT, 0.01) != Vector2.ZERO, "Pode continuar andando após erro: " + invalid)

func _test_revalidate_and_rearm() -> void:
	var session = fresh()
	enter(session)
	var house = session.world
	leave(session)
	place(session, Vector2(840, 290))
	expect(session.begin_transition(), "Reentrada começa")
	house.obstacles.append(Rect2(345, 290, 30, 30))
	session.tick(session.transition_duration)
	expect(session.state == "exploration" and session.area_id == "lab_exterior" and not session.world.transitioning, "Revalidação de área visitada aborta com segurança")
	var config = definitions.duplicate(true)
	config["test_house"]["entries"]["from_lab"]["position"] = [360, 390]
	config["test_house"]["entries"]["from_lab"]["facing"] = [0, 1]
	session = fresh(config)
	enter(session)
	expect(session.world.arrival_transition_lock == "house_exit" and not session.begin_transition("house_exit"), "Chegada próxima bloqueia retorno imediato")
	session.move(Vector2.UP, 0.2)
	expect(session.world.arrival_transition_lock.is_empty(), "Sair do alcance rearma o portal")
	session.move(Vector2.DOWN, 0.2)
	expect(session.begin_transition("house_exit"), "Nova aproximação permite retorno explícito")
	finish_transition(session)

func _test_battle_in_destination() -> void:
	# Só a fixture de teste põe um encontro na casa, sem acrescentar conteúdo jogável.
	var config = definitions.duplicate(true)
	config["test_house"]["encounters"] = [{"id": "interior_test_enemy", "label": "Teste", "position": [470, 290], "battle_preset_id": "lab_a", "interaction_distance": 72}]
	var session = fresh(config)
	enter(session)
	var house = session.world
	var exterior = session.area_worlds["lab_exterior"]
	place(session, Vector2(435, 290))
	expect(session.interact() == "battle" and session.active_encounter_area_id == "test_house", "Combate na segunda área identifica origem correta")
	var formation = house.formation_positions()
	for enemy in session.battle.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.data["settings"]["escape_chance"] = 1.0
	session.battle.party[0]["hp"] = 79
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	session.battle.submit("escape")
	finish_action(session.battle)
	expect(session.finish_encounter() and session.world == house and house.formation_positions() == formation, "Fuga retorna à mesma casa e fila")
	expect(session.battle.party[0]["hp"] == 79 and house.entity_by_id("interior_test_enemy")["present"], "Fuga mantém HP e encontro")
	expect(session.begin_encounter("interior_test_enemy"), "Reencontro explícito no interior")
	for enemy in session.battle.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.debug_ready_allies()
	session.battle.select_actor("p1")
	session.battle.submit("all")
	finish_action(session.battle)
	expect(session.finish_encounter() and session.world == house and not house.entity_by_id("interior_test_enemy")["present"], "Vitória permanece na área correta")
	expect(exterior.entity_by_id("test_map_enemy_01")["present"], "Vitória em outra área não altera exterior")
	leave(session)
	enter(session)
	expect(not session.world.entity_by_id("interior_test_enemy")["present"] and session.battle.party[0]["hp"] == 79, "Revisita conserva resultado e recursos")

func _test_reset() -> void:
	var session = fresh()
	session.world.entity_by_id("chest_01")["open"] = true
	enter(session)
	var reset = fresh()
	expect(reset.area_id == "lab_exterior" and reset.area_worlds.size() == 1, "Nova sessão inicia só com estado externo")
	expect(not reset.world.entity_by_id("chest_01")["open"] and not reset.world.entity_by_id("door_01")["open"], "Reinício restaura objetos")
	expect(reset.world.entity_by_id("test_map_enemy_01")["present"] and reset.battle.party[0]["hp"] == reset.battle.party[0]["max_hp"], "Reinício restaura encontros e recursos")
