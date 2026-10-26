extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Rules = preload("res://scripts/exploration/area_rules.gd")
var definitions: Dictionary
var battle: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	definitions = Catalog.load_definitions()
	battle = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh(config: Dictionary = {}):
	var data = definitions.duplicate(true) if config.is_empty() else config
	return Session.new(battle.duplicate(true), data["lab_exterior"], data)

func place(session, position: Vector2, direction: Vector2 = Vector2.RIGHT) -> void:
	session.world.leader_position = position
	session.world.path.assign([position - direction * 102, position])
	session.world.path_length = 102

func close(session) -> void:
	for index in range(12):
		if not session.dialogue.opened:
			return
		if session.dialogue.choices().is_empty():
			session.advance_dialogue()
		else:
			session.choose_response(0)
	expect(false, "Diálogo termina")

func travel(session, id: String) -> void:
	place(session, session.world.entity_by_id(id)["position"] + Vector2(0, 40))
	expect(session.begin_transition(id), "Acesso funciona: " + id)
	session.tick(session.transition_duration)
	expect(session.state == "exploration", "Transição conclui: " + id)

func examine(session) -> String:
	place(session, Vector2(1177, 720), Vector2.UP)
	expect(session.interact() == "dialogue", "Pedra examinável com interação existente")
	return session.dialogue.dialogue_id

func _run() -> void:
	var tests = [_test_authoring, _test_natural_visit, _test_discovery, _test_npc_positions,
		_test_safe_updates, _test_availability, _test_invalid_rules]
	for test in tests:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("EVENTOS/CIDADE: %d grupos, %d verificações, %d falhas" % [tests.size(), checks, failures])
	quit(0 if failures == 0 else 1)

func _test_authoring() -> void:
	expect(definitions.size() == 5, "Duas casas e as três áreas anteriores")
	var ids = {}
	for id in definitions:
		expect(Catalog.valid_map(definitions[id]), "Definição válida: " + id)
		var session = Session.new(battle, definitions[id], definitions)
		for entry in session.world.data["entries"]:
			expect(not session.world.prepare_arrival(entry, session.world.party_order).is_empty(), "Entrada comporta a fila: " + id + ":" + entry)
		for npc in session.world.data["npcs"]:
			expect(not ids.has(npc["id"]), "NPC não está duplicado em áreas")
			ids[npc["id"]] = true
		for hour in [22, 10]:
			session.clock.set_time(hour, 0)
			var positions: Array[Vector2] = []
			for npc in session.world.entities:
				if npc["kind"] == "npc":
					expect(session.world.is_walkable(npc["position"]) and positions.all(func(point): return point.distance_to(npc["position"]) >= 24), "NPC válido e sem sobreposição em cada horário: " + id)
					positions.append(npc["position"])
	expect(ids.size() == 5, "Mesmos cinco NPCs, sem novos personagens")
	var town: Dictionary = definitions["lab_exterior"]
	expect(town["obstacles"].filter(func(item): return item.get("night_windows", false)).size() == 2, "Duas casas com janelas noturnas")
	expect(town["obstacles"].filter(func(item): return item.get("night_light", false)).size() == 1, "Um poste não interativo")

func _test_natural_visit() -> void:
	var session = fresh()
	var shared = session.clock
	session.tick(60)
	expect(shared.time_text() == "10:00", "Cidade mantém horário diurno")
	travel(session, "secret_house_entrance")
	session.tick(60)
	expect(session.area_id == "secret_house" and session.clock == shared and shared.time_text() == "10:00", "Segunda casa pausa e compartilha horário")
	travel(session, "secret_house_exit")
	travel(session, "house_entrance")
	session.tick(60)
	expect(shared.time_text() == "10:00", "Casa original permanece funcional/pausada")
	travel(session, "house_exit")
	travel(session, "town_exit")
	session.tick(45)
	expect(shared.time_text() == "19:00" and shared.is_night(), "Ciclo natural chega à noite em 45 segundos desde 10:00")
	travel(session, "enter_town")
	expect(session.clock == shared and shared.time_text() == "19:00", "Cidade recebe noite do mapa-múndi")
	expect(session.world.entity_by_id("npc_04")["position"] == Vector2(970, 780), "NPC noturno atualizado antes da revelação")
	travel(session, "town_exit")
	session.tick(60)
	travel(session, "enter_town")
	expect(shared.time_text() == "07:00" and session.world.entity_by_id("npc_04")["placement_key"] == "default", "Retorno natural ao dia restaura posição diurna")

func _test_discovery() -> void:
	var session = fresh()
	var notifications = []
	session.story_flag_changed.connect(func(flag): notifications.append(flag))
	place(session, session.world.entity_by_id("npc_04")["position"])
	expect(session.interact() == "dialogue", "Morador conversa durante o dia")
	var hints: Array[String] = []
	while session.dialogue.opened:
		hints.append(session.dialogue.current()["text"])
		session.advance_dialogue()
	expect(hints.any(func(text): return "luz estranha" in text), "Morador fornece dica diurna sem remover instruções anteriores")
	expect(examine(session) == "stone_day" and session.story_flags.is_empty(), "Durante o dia não revela inscrição")
	close(session)
	session.clock.set_time(22, 0)
	expect(examine(session) == "stone_discover", "Noite revela inscrição")
	expect(session.story_flags.get("house_secret_discovered", false) and notifications == ["house_secret_discovered"], "Descoberta registrada uma vez")
	var text: String = session.dialogue.current()["text"]
	session.clock.set_time(10, 0)
	expect(session.dialogue.current()["text"] == text, "Evento não troca diálogo ativo")
	close(session)
	for hour in [10, 22, 3, 8]:
		session.clock.set_time(hour, 0)
		expect(examine(session) == "stone_known", "Pedra reconhece descoberta em qualquer horário")
		close(session)
		var resident = session.world.entity_by_id("npc_04")
		place(session, resident["position"])
		expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "resident_knows", "Morador reconhece descoberta em qualquer período")
		close(session)
	travel(session, "secret_house_entrance")
	travel(session, "secret_house_exit")
	travel(session, "house_entrance")
	travel(session, "house_exit")
	travel(session, "town_exit")
	session.tick(60)
	travel(session, "enter_town")
	expect(examine(session) == "stone_known" and notifications.size() == 1, "Flag persiste em horários, áreas, retorno e novas interações")
	close(session)
	expect(not session.set_story_flag_once("house_secret_discovered") and notifications.size() == 1, "API idempotente")
	expect(fresh().story_flags.is_empty(), "Reinício explícito restaura teste, sem salvamento inventado")

func _test_npc_positions() -> void:
	var session = fresh()
	var npc = session.world.entity_by_id("npc_04")
	session.tick(0.5)
	var route: Dictionary = npc["route_state"].duplicate(true)
	session.clock.set_time(17, 0)
	expect(npc["route_state"] == route, "Mesmo posicionamento diurno preserva progresso de rota")
	session.clock.set_time(22, 0)
	expect(npc["position"] == Vector2(970, 780) and session.world.is_walkable(npc["position"]), "Posição noturna válida")
	session.tick(10)
	expect(npc["position"] == Vector2(970, 780), "NPC noturno fica parado")
	session.clock.set_time(7, 0)
	expect(npc["position"] == Vector2(900, 500), "Retorna à praça")
	for step in range(100):
		session.tick(0.1)
		expect(session.world.is_walkable(npc["position"]), "Patrulha diurna segue rota válida")
	place(session, session.world.entity_by_id("npc_05")["position"])
	expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "objects", "Outro NPC mantém função diurna")
	close(session)
	session.clock.set_time(22, 0)
	expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "clock_night", "Outro NPC tem diálogo noturno")

func _test_safe_updates() -> void:
	var session = fresh()
	var npc = session.world.entity_by_id("npc_04")
	place(session, npc["position"])
	session.interact()
	var before: Vector2 = npc["position"]
	session.clock.set_time(22, 0)
	expect(npc["position"] == before and session.dialogue.dialogue_id == "patrol", "Mudança em conversa não teleporta interlocutor")
	close(session)
	expect(npc["position"] == Vector2(970, 780), "Aplica atualização ao encerrar conversa")
	place(session, Vector2(1230, 500))
	session.clock.set_time(10, 0)
	place(session, Vector2(970, 780))
	session.clock.set_time(22, 0)
	expect(npc["placement_pending"] and npc["position"] == Vector2(900, 500), "Não materializa NPC sobre integrante")
	session.tick(1)
	expect(npc["position"] == Vector2(900, 500), "NPC aguarda enquanto destino está ocupado")
	place(session, Vector2(1230, 500))
	session.tick(0.01)
	expect(not npc["placement_pending"] and npc["position"] == Vector2(970, 780), "Aplica quando fila libera destino")
	session.state = "cutscene" # Contexto de teste; não cria sistema de cutscene.
	session.clock.set_time(10, 0)
	expect(npc["position"] == Vector2(970, 780), "Cutscene não sofre mudança de posição no meio")
	session.state = "exploration"
	session.tick(0.01)
	expect(npc["placement_key"] == "default", "Retoma atualização após bloqueio")
	var config = definitions.duplicate(true)
	config["lab_exterior"]["npcs"][0]["placement_by_period"]["night"]["position"] = [1050, 650]
	var invalid = fresh(config)
	invalid.clock.set_time(22, 0)
	expect(invalid.world.entity_by_id("npc_04")["placement_pending"], "Destino inválido mantém posição anterior segura")

func _test_availability() -> void:
	var config = definitions.duplicate(true)
	config["lab_exterior"]["objects"][0]["available_when"] = {"periods": ["night"]}
	var session = fresh(config)
	place(session, Vector2(1177, 720), Vector2.UP)
	expect(not session.world.can_interact(), "Disponibilidade separada do diálogo")
	session.clock.set_time(22, 0)
	expect(session.world.can_interact(), "Disponibilidade atualiza por sinal sem recarregar área")
	expect(Rules.matches({"flags_unset": ["x"]}, "day", {}), "Condições declarativas de flag")

func _test_invalid_rules() -> void:
	for change in [{"available_when": {"typo": true}}, {"interaction_rules": [{"dialogue_id": "missing"}]},
		{"interaction_rules": [{"dialogue_id": "stone_day", "set_flag": 2}]},
		{"placement_by_period": {"night": {"position": [1, "x"]}}}, {"solid": "yes"}]:
		var data: Dictionary = definitions["lab_exterior"].duplicate(true)
		data["objects"][0].merge(change, true)
		expect(not Catalog.valid_map(data), "Dados inválidos recusados")
	var broken = definitions.duplicate(true)
	broken["lab_exterior"]["dialogues"]["stone_discover"]["start"] = "missing"
	var session = fresh(broken)
	session.clock.set_time(22, 0)
	place(session, Vector2(1177, 720), Vector2.UP)
	expect(session.interact().is_empty() and session.story_flags.is_empty(), "Falha ao iniciar diálogo não registra descoberta")
