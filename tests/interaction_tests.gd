extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
var battle_data: Dictionary
var map_data: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	map_data = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_internal_split.json"))["lab_exterior"]
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	return Session.new(battle_data.duplicate(true), map_data.duplicate(true))

func place(session, position: Vector2) -> void:
	# Fixture de posição para isolar interações; movimento real tem testes próprios.
	session.world.leader_position = position
	session.world.path.assign([position - Vector2(102, 0), position])
	session.world.path_length = 102

func close_dialogue(session) -> void:
	for step in range(12):
		if not session.dialogue.opened:
			return
		if session.dialogue.choices().is_empty():
			session.advance_dialogue()
		else:
			session.choose_response(0)
	expect(false, "Diálogo deve terminar sem ciclo")

func routes(session) -> Array:
	var result: Array = []
	for entity in session.world.entities:
		result.append({"route": entity["route_state"].duplicate(true), "position": entity["position"]})
	return result

func _run() -> void:
	for test in [_test_data, _test_reachability, _test_corridors_and_obstacles, _test_patrols_and_pause,
		_test_dialogues, _test_choices, _test_objects, _test_interaction_guards, _test_all_encounters]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("INTERAÇÕES: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func _test_data() -> void:
	var session = fresh()
	expect(map_data["encounters"].size() == 6 and map_data["npcs"].size() == 5 and map_data["objects"].size() == 4, "Quantidades do recorte autorizado")
	var ids = {}
	var presets = {}
	for preset in battle_data["presets"]:
		presets[preset["id"]] = true
	for entity in session.world.entities:
		expect(not ids.has(entity["id"]), "ID único")
		ids[entity["id"]] = true
		if entity["kind"] == "encounter":
			expect(presets.has(entity["battle_preset_id"]), "Encontro referencia preset existente")
		if entity.get("object_type", "") == "door":
			continue
		var route: Dictionary = entity["route_state"].duplicate(true)
		for step in range(120):
			Route.advance(route, 0.1)
			expect(session.world.is_walkable(Route.position_at(route, entity["position"])), "Entidade/rota fora dos sólidos e limites")
	for dialogue in map_data["dialogues"].values():
		expect(dialogue["nodes"].has(dialogue["start"]), "Entrada de diálogo válida")
		for node in dialogue["nodes"].values():
			expect(not node["text"].is_empty(), "Fala preenchida")
			var next_nodes = [node.get("next", "")]
			for choice in node.get("choices", []):
				next_nodes.append(choice.get("next", ""))
			for next in next_nodes:
				expect(next.is_empty() or dialogue["nodes"].has(next), "Referência de fala/resposta válida")

func _test_reachability() -> void:
	# Busca apenas no teste: confirma acesso a todos os elementos no mapa pronto.
	var session = fresh()
	var world = session.world
	var origin = Vector2(36, 36)
	var step = 12.0
	var start = Vector2i((world.leader_position - origin) / step)
	var pending = [start]
	var visited = {start: true}
	var head = 0
	while head < pending.size():
		var cell: Vector2i = pending[head]
		head += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if not visited.has(next) and world.is_walkable(origin + Vector2(next) * step):
				visited[next] = true
				pending.append(next)
	for entity in world.entities:
		var found = false
		var cell = Vector2i((entity["position"] - origin) / step)
		for x in range(cell.x - 6, cell.x + 7):
			for y in range(cell.y - 6, cell.y + 7):
				if visited.has(Vector2i(x, y)):
					world.leader_position = origin + Vector2(x, y) * step
					if world.can_interact_with(entity) and world.interaction_candidate().get("id", "") == entity["id"]:
						found = true
		expect(found, "Há aproximação acessível e selecionável para " + entity["id"])

func _test_corridors_and_obstacles() -> void:
	var session = fresh()
	var world = session.world
	for segment in [[Vector2.DOWN, 200.0], [Vector2.RIGHT, 448.0], [Vector2.DOWN, 120.0]]:
		for step in range(int(segment[1] / 2)):
			session.move(segment[0], 2.0 / 180.0)
			for position in world.formation_positions():
				expect(world.is_walkable(position), "Quatro integrantes não cortam sólidos nos corredores estreitos")
	expect(world.leader_position.is_equal_approx(Vector2(658, 820)), "Percorre corredor horizontal e vertical de 44 unidades")
	place(session, Vector2(40, 360))
	session.move(Vector2.RIGHT, 2)
	expect(world.leader_position.x == 53, "Árvore possui volume sólido")
	place(session, Vector2(450, 280))
	session.move(Vector2.RIGHT, 2)
	expect(world.leader_position.x == 458, "Pedra possui volume sólido")

func _test_patrols_and_pause() -> void:
	var session = fresh()
	var divided = fresh()
	var before = routes(session)
	session.tick(1)
	for step in range(60):
		divided.tick(1.0 / 60.0)
	for index in range(session.world.entities.size()):
		var entity = session.world.entities[index]
		expect(entity["position"].is_equal_approx(divided.world.entities[index]["position"]), "Patrulha determinística independente de frames")
		if entity["route_state"]["speed"] > 0:
			expect(entity["position"] != before[index]["position"], "Patrulha móvel avança")
		else:
			expect(entity["position"] == before[index]["position"], "Entidade estática permanece")
	before = routes(session)
	session.world.menu_open = true
	session.tick(10)
	expect(routes(session) == before, "Menu pausa rotas exatamente")
	session.world.menu_open = false
	var npc = session.world.entity_by_id("npc_04")
	place(session, npc["position"] + Vector2(0, 40))
	expect(session.interact() == "dialogue", "Conversa com NPC móvel")
	before = routes(session)
	session.tick(10)
	expect(routes(session) == before, "Diálogo pausa todas as rotas exatamente")
	close_dialogue(session)
	session.tick(0.5)
	expect(routes(session) != before, "Retoma após encerrar diálogo")
	place(session, session.world.entity_by_id("test_map_enemy_01")["position"] + Vector2(0, 45))
	expect(session.begin_encounter(), "Inicia luta para verificar pausa do mapa")
	before = routes(session)
	session.tick(10)
	expect(routes(session) == before, "Combate congela rotas do mapa")

func _test_dialogues() -> void:
	for definition in map_data["npcs"]:
		var session = fresh()
		var entity = session.world.entity_by_id(definition["id"])
		place(session, entity["position"] + Vector2(0, 42))
		expect(session.interact() == "dialogue", "Cada NPC inicia sua conversa")
		expect(session.dialogue.speaker == entity["label"], "Nome do interlocutor")
		var position = session.world.leader_position
		var history = session.world.path.duplicate()
		session.move(Vector2.RIGHT, 1)
		expect(session.world.leader_position == position and session.world.path == history, "Diálogo bloqueia movimento e trilha")
		expect(not session.begin_encounter("test_map_enemy_01") and session.interact().is_empty(), "Diálogo bloqueia outras interações")
		session.world.menu_open = true
		expect(not session.world.choose_leader("p2"), "Diálogo impede troca de líder mesmo com chamada direta")
		session.world.menu_open = false
		close_dialogue(session)
		expect(not session.world.dialogue_open, "Encerrar libera exploração")
		expect(session.move(Vector2.RIGHT, 0.01) != Vector2.ZERO, "Movimento retorna após diálogo")

func _test_choices() -> void:
	for choice in [0, 1]:
		var session = fresh()
		place(session, Vector2(245, 190))
		session.interact()
		expect(session.dialogue.choices().size() == 2, "Duas respostas disponíveis")
		expect(not session.advance_dialogue(), "Avançar não escolhe resposta automaticamente")
		expect(not session.choose_response(-1) and not session.choose_response(99), "Índices inválidos não mudam o diálogo")
		expect(session.choose_response(choice), "Escolha válida avança")
		expect(session.dialogue.node_id == ("encounters" if choice == 0 else "formation"), "Cada opção leva à sua fala")
		expect(session.advance_dialogue() and session.dialogue.node_id == "end", "Ramo retorna a encerramento comum")
		expect(session.advance_dialogue() and not session.dialogue.opened, "Fim da conversa")

func _test_objects() -> void:
	var session = fresh()
	var stock = session.battle.inventory.duplicate(true)
	place(session, Vector2(900, 660))
	expect(session.interact() == "dialogue" and session.world.entity_by_id("chest_01")["open"], "Baú abre e mostra diálogo")
	close_dialogue(session)
	session.interact()
	expect(session.dialogue.dialogue_id == "chest_repeat", "Repetir baú usa estado aberto")
	close_dialogue(session)
	expect(session.battle.inventory == stock, "Baú não cria inventário ou recompensa")
	place(session, Vector2(1040, 660))
	session.interact()
	expect(session.dialogue.dialogue_id == "sign", "Placa apresenta múltiplas falas")
	expect(session.advance_dialogue() and session.dialogue.opened, "Placa permite avançar")
	close_dialogue(session)
	place(session, Vector2(960, 751))
	session.move(Vector2.RIGHT, 2)
	expect(session.world.leader_position.x == 988, "Porta fechada é sólida")
	place(session, Vector2(920, 795))
	session.interact()
	expect(session.world.entity_by_id("door_01")["open"] and session.world.entity_by_id("lever_01")["active"], "Alavanca abre a porta")
	close_dialogue(session)
	place(session, Vector2(960, 751))
	session.move(Vector2.RIGHT, 80.0 / 180.0)
	expect(session.world.leader_position.x == 1040, "Porta aberta libera passagem")
	session.interact()
	expect(session.dialogue.dialogue_id == "door_blocked" and session.world.entity_by_id("door_01")["open"], "Porta não fecha sobre um seguidor")
	close_dialogue(session)
	place(session, Vector2(970, 751))
	session.interact()
	expect(not session.world.entity_by_id("door_01")["open"] and not session.world.entity_by_id("lever_01")["active"], "Acionamento direto fecha porta e sincroniza alavanca")
	close_dialogue(session)
	session.interact()
	expect(session.world.entity_by_id("door_01")["open"], "Porta pode ser aberta diretamente")
	close_dialogue(session)
	var reset = fresh()
	expect(not reset.world.entity_by_id("chest_01")["open"] and not reset.world.entity_by_id("door_01")["open"], "Nova sessão restaura objetos")

func _test_interaction_guards() -> void:
	var session = fresh()
	expect(session.interact().is_empty(), "Distância impede interação remota")
	place(session, Vector2(960, 751))
	var sign = session.world.entity_by_id("sign_01")
	sign["position"] = Vector2(1050, 751)
	sign["interaction_distance"] = 120
	expect(not session.world.can_interact_with(sign), "Porta fechada bloqueia interação através dela")
	session.world.toggle_door("door_01")
	expect(session.world.can_interact_with(sign), "Porta aberta libera linha de interação")
	sign["position"] = Vector2(325, 490)
	place(session, Vector2(325, 440))
	expect(not session.world.can_interact_with(sign), "Parede sólida bloqueia linha de interação")
	place(session, Vector2(900, 660))
	session.world.menu_open = true
	expect(session.interact().is_empty(), "Menu impede objetos e NPCs")
	session.world.menu_open = false
	var candidate = session.world.interaction_candidate()
	expect(candidate["id"] == "chest_01", "Seleciona elemento mais próximo")
	candidate["present"] = false
	expect(session.world.interaction_candidate().get("id", "") != "chest_01", "Elemento ausente não é selecionado")

func _test_all_encounters() -> void:
	for definition in map_data["encounters"]:
		var session = fresh()
		var entity = session.world.entity_by_id(definition["id"])
		place(session, entity["position"] + Vector2(0, 45))
		session.battle.party[0]["hp"] = 93
		session.battle.party[0]["mp"] = 30
		session.world.entity_by_id("chest_01")["open"] = true
		session.world.toggle_door("door_01")
		var shared = session.battle
		var snapshots = routes(session)
		var formation = session.world.formation_positions()
		expect(session.interact() == "battle", "Cada monstro inicia combate existente")
		expect(session.battle == shared and session.battle.preset["id"] == definition["battle_preset_id"], "Instância compartilhada e preset correto")
		expect(session.battle.party[0]["hp"] == 93 and session.battle.party[0]["mp"] == 30, "Entrada mantém HP/MP")
		for enemy in session.battle.enemies:
			enemy["hp"] = 1
			enemy["ini_modifier"] = -float(enemy["ini"])
		session.battle.debug_ready_allies()
		session.battle.select_actor("p1")
		expect(session.battle.submit("all"), "Onda usa o sistema existente")
		for step in range(100):
			session.battle.tick(1.0 / 120.0)
		expect(session.battle.outcome == "victory" and session.finish_encounter(), "Vitória real retorna")
		var count = 0
		for other in session.world.entities:
			if other["kind"] == "encounter" and other["present"]:
				count += 1
		expect(count == 5 and not entity["present"], "Só o encontro vencido desaparece")
		expect(session.battle.party[0]["hp"] == 93 and session.battle.party[0]["mp"] == 20, "Retorno mantém recursos e custo real")
		expect(routes(session) == snapshots and session.world.formation_positions() == formation, "Retorno preserva rotas, posições e fila")
		expect(session.world.entity_by_id("chest_01")["open"] and session.world.entity_by_id("door_01")["open"], "Combate conserva estados dos objetos")
		expect(not session.begin_encounter(definition["id"]), "Vencido não reabre por ID")
