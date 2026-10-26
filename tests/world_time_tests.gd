extends SceneTree
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
var definitions: Dictionary
var battle_data: Dictionary
var checks = 0
var failures = 0

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
	place(session, session.world.entity_by_id(id)["position"] + Vector2(0, 40))
	expect(session.begin_transition(id), "Inicia viagem: " + id)
	session.tick(session.transition_duration)
	expect(session.state == "exploration", "Conclui viagem: " + id)

func _run() -> void:
	var tests = [_test_classification, _test_current_areas_policy, _test_overworld_and_guards,
		_test_global_transitions_and_events, _test_rest_and_battle, _test_dialogue_query]
	for test in tests:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("TEMPO/ÁREAS: %d grupos, %d verificações, %d falhas" % [tests.size(), checks, failures])
	quit(0 if failures == 0 else 1)

func _test_classification() -> void:
	for definition in [{}, {"is_outdoor": true}, {"area_type": "overworld"},
		{"area_type": "town", "time_advances": true}, {"area_type": "castle", "time_advances": false}]:
		expect(not Session.area_allows_time(definition), "Aparência/nome não autoriza avanço")
	expect(Session.area_allows_time({"area_type": "overworld", "time_advances": true}), "Exige classificação e habilitação explícitas")
	for change in [{"time_advances": "true"}, {"area_type": "town", "time_advances": true},
		{"area_type": 10}, {"lighting_profile": "unknown"}]:
		var bad: Dictionary = definitions["test_world"].duplicate(true)
		bad.merge(change, true)
		expect(not Catalog.valid_map(bad), "Configuração temporal/visual inválida recusada")
	var bad: Dictionary = definitions["lab_exterior"].duplicate(true)
	bad["npcs"][1]["dialogue_by_period"] = {"night": "missing"}
	expect(not Catalog.valid_map(bad), "Variante aponta a diálogo existente")

func _test_current_areas_policy() -> void:
	expect(definitions.size() == 5, "Catálogo atual de cinco áreas")
	for id in definitions:
		var session = Session.new(battle_data, definitions[id], definitions)
		var now: float = session.clock.minutes_of_day()
		var allowed = id == "test_world"
		session.tick(5)
		expect(session.can_advance_world_time() == allowed and session.clock.minutes_of_day() == now + (60 if allowed else 0), "Política temporal da área real: " + id)
		expect(definitions[id].has("area_type") and definitions[id]["time_advances"] == allowed, "Classificação explícita em " + id)

func _test_overworld_and_guards() -> void:
	var session = fresh()
	travel(session, "town_exit")
	var clock = session.clock
	session.tick(5)
	expect(clock.time_text() == "11:00" and session.can_advance_world_time(), "Mapa-múndi real avança naturalmente")
	for guard in ["menu_open", "dialogue_open", "transitioning"]:
		session.world.set(guard, true)
		session.tick(60)
		expect(clock.time_text() == "11:00", "Pausa temporal durante " + guard)
		session.world.set(guard, false)
	for state in ["battle", "defeat"]:
		session.state = state
		session.tick(60)
		expect(clock.time_text() == "11:00", "Pausa temporal no estado " + state)
	session.state = "exploration"
	session.tick(5)
	expect(clock.time_text() == "12:00", "Retoma sem acumular tempo pausado")
	for delta in [0.0, -1.0, NAN, INF]:
		session.tick(delta)
		expect(clock.time_text() == "12:00", "Delta inválido não altera relógio")
	expect(Session.area_allows_time(definitions["test_world"]) and not Session.area_allows_time(definitions["lab_exterior"]), "Somente mapa-múndi real habilitado")

func _test_global_transitions_and_events() -> void:
	var session = fresh()
	var clock = session.clock
	clock.set_time(22, 0)
	travel(session, "house_entrance")
	session.tick(1000)
	expect(session.clock == clock and clock.time_text() == "22:00", "Interior usa o mesmo relógio e o pausa")
	clock.set_time(8, 0) # Exemplo narrativo sem castelo/chefe novos.
	travel(session, "house_exit")
	expect(clock.time_text() == "08:00", "Exterior recebe horário narrativo do interior")
	place(session, session.world.entity_by_id("town_exit")["position"] + Vector2(0, 40))
	expect(session.begin_transition("town_exit"), "Fade inicia")
	session.tick(session.transition_duration * 0.5)
	expect(session.transition_alpha == 1 and session.clock == clock and clock.time_text() == "08:00", "Destino usa horário preservado sob preto total")
	clock.set_time(19, 0)
	session.tick(session.transition_duration * 0.5)
	expect(clock.time_text() == "19:00", "Evento durante fade aplicado antes da revelação; sem avanço residual")
	travel(session, "dungeon_entrance")
	clock.advance_time(360)
	expect(clock.time_text() == "01:00", "Evento avança meia-noite mesmo em dungeon pausada")
	travel(session, "dungeon_exit")
	travel(session, "enter_town")
	expect(session.clock == clock and clock.time_text() == "01:00", "Quatro áreas compartilham horário")

func _test_rest_and_battle() -> void:
	var session = fresh()
	session.battle.party[0]["hp"] = 20
	session.battle.party[0]["mp"] = 1
	session.battle.party[1]["hp"] = 0
	var resources = session.battle.party.duplicate(true)
	for hour in [10, 18, 23, 3, 7]:
		session.clock.set_time(hour, 0)
		expect(session.rest_at_inn() and session.clock.time_text() == "07:00", "API de descanso define 07:00")
	expect(session.battle.party == resources, "API temporal não inventa cura, pagamento ou reanimação")
	travel(session, "town_exit")
	travel(session, "dungeon_entrance")
	place(session, session.world.entity_by_id("test_map_enemy_01")["position"])
	var clock = session.clock
	clock.set_time(23, 0)
	expect(session.begin_encounter(), "Combate real inicia")
	session.tick(100)
	expect(session.clock == clock and clock.time_text() == "23:00", "ATB não é relógio do mundo")
	session.battle.outcome = "escaped"
	expect(session.finish_encounter() and session.clock == clock and clock.time_text() == "23:00", "Retorno do combate preserva horário")

func _test_dialogue_query() -> void:
	var session = fresh()
	place(session, session.world.entity_by_id("npc_05")["position"])
	expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "objects", "Falas diurnas anteriores preservadas")
	session.clock.set_time(22, 0)
	expect(session.dialogue.dialogue_id == "objects", "Mudança de hora não troca fala já aberta")
	while session.dialogue.opened:
		session.advance_dialogue()
	expect(session.interact() == "dialogue" and session.dialogue.dialogue_id == "clock_night", "Mesma tecla/interação consulta variante noturna")
	expect("noite" in session.dialogue.current()["text"], "Exemplo mínimo de consulta do período")
