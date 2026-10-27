extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	var model = Battle.new(data.duplicate(true))
	model.start(4)
	model.mode = "Active"
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	return model

func line_route() -> Dictionary:
	return Route.create([[0, 0], [100, 0]], 20, {"rhythm": {"pattern": "ping_pong",
		"acceleration": 2.0, "deceleration": 2.0, "turn_pause": 1.0,
		"steps": [{"to": 1.0, "pause": 1.0}]}})

func _run() -> void:
	for test in [_test_preservation_and_profiles, _test_analytic_rhythm, _test_determinism,
		_test_flight_and_bounds, _test_wait_active_and_atb, _test_interrupt_every_phase,
		_test_target_geometry, _test_sequences, _test_asymmetric_return, _test_approach_preset,
		_test_invalid_and_degenerate]:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("RITMOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_preservation_and_profiles() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre_rhythm_combat.json"))
	for key in original:
		if key == "presets":
			expect(data[key].slice(0, 4) == original[key], "Presets A–D integralmente preservados")
		elif key == "enemy_types":
			for id in original[key]:
				expect(data[key][id] == original[key][id], "Tipos antigos intactos")
		else:
			expect(data[key] == original[key], "Dados de combate anteriores intactos: " + key)
	var model = fresh()
	expect(model.preset["id"] == "lab_rhythm" and model.enemies.size() == 4, "Comparação E com três ritmos e um estático")
	expect(model.enemies[0]["route_state"]["speed"] < model.enemies[1]["route_state"]["speed"], "Velocidade herdada diferencia pesado/ágil")
	expect(model.enemies[0]["ini"] == model.enemies[1]["ini"], "Demonstração não associa velocidade física à INI")
	var type: Dictionary = data["enemy_types"]["agile_test"]
	var inherited = model._movement_settings(type, {"speed": 90, "motion": {"rhythm": {"turn_pause": 2.0}}})
	expect(inherited["speed"] == 90 and inherited["motion"]["rhythm"]["turn_pause"] == 2.0, "Encontro sobrescreve velocidade e parte do ritmo")
	expect(inherited["motion"]["rhythm"]["acceleration"] == data["movement_profiles"]["agile_test"]["motion"]["rhythm"]["acceleration"] and inherited["motion"]["rhythm"]["steps"].size() == 2, "Ajuste parcial preserva o resto do perfil")
	var pause_before: float = data["movement_profiles"]["agile_test"]["motion"]["rhythm"]["steps"][0]["pause"]
	inherited["motion"]["rhythm"]["steps"][0]["pause"] = 99
	expect(data["movement_profiles"]["agile_test"]["motion"]["rhythm"]["steps"][0]["pause"] == pause_before, "Estado/ajustes nunca alteram dados fonte")
	var override = model._movement_settings(type, {"movement_profile": "heavy_test"})
	expect(override["speed"] == data["movement_profiles"]["heavy_test"]["speed"], "Encontro também pode trocar perfil")
	expect(model.enemies[0]["route_state"]["speed"] < 52 and model.enemies[1]["route_state"]["speed"] < 120 and model.enemies[2]["route_state"]["speed"] < 150, "Três tipos desacelerados em relação ao experimento anterior")
	for index in range(4):
		model.start(index)
		for enemy in model.enemies:
			expect(not enemy["route_state"].has("rhythm"), "Novos ritmos são opt-in nos presets anteriores")

func _test_analytic_rhythm() -> void:
	var route = line_route()
	expect(route["length"] == 100 and not route["closed"], "Ida e volta usa caminho aberto, sem segmento de fechamento")
	Route.advance(route, 1.0)
	expect(is_equal_approx(route["rhythm"]["current_speed"], 10.0), "Metade da aceleração tem metade da velocidade")
	expect(absf(Route.position_at(route, Vector2.ZERO).x - 10.0 * (1.0 - 2.0 / PI)) < 0.0001, "Distância é a integral da velocidade suavizada")
	Route.advance(route, 1.0)
	expect(Route.position_at(route, Vector2.ZERO).is_equal_approx(Vector2(20, 0)), "Aceleração percorre distância correta")
	Route.advance(route, 3.0)
	expect(Route.position_at(route, Vector2.ZERO).is_equal_approx(Vector2(80, 0)), "Trecho de velocidade constante")
	Route.advance(route, 1.0)
	expect(is_equal_approx(route["rhythm"]["current_speed"], 10.0), "Desaceleração reduz velocidade gradualmente")
	Route.advance(route, 1.0)
	expect(Route.position_at(route, Vector2.ZERO) == Vector2(100, 0), "Chega exatamente à extremidade")
	expect(route["rhythm"]["movement_phase"] == "pause" and route["rhythm"]["current_speed"] == 0, "Parada programada tem velocidade zero")
	Route.advance(route, 0.5)
	expect(Route.position_at(route, Vector2.ZERO) == Vector2(100, 0) and is_equal_approx(route["rhythm"]["pause_remaining"], 0.5), "Espera sem deslizar")
	Route.advance(route, 1.5)
	expect(Route.travel_direction(route).x < 0 and Route.position_at(route, Vector2.ZERO).x < 100, "Retorno inverte sentido sem teleporte")
	Route.advance(route, 7.0)
	expect(Route.position_at(route, Vector2.ZERO).is_equal_approx(Vector2.ZERO), "Ciclo completo retorna exatamente ao início")

func _test_determinism() -> void:
	var model = fresh()
	for index in range(3):
		var source: Dictionary = model.enemies[index]["route_state"].duplicate(true)
		var split = source.duplicate(true)
		var whole = source.duplicate(true)
		for step in range(2400):
			Route.advance(split, STEP)
		Route.advance(whole, 20.0)
		expect(Route.position_at(split, Vector2.ZERO).distance_to(Route.position_at(whole, Vector2.ZERO)) < 0.001, "Posição independe de subdivisão do tempo")
		expect(absf(split["rhythm"]["current_speed"] - whole["rhythm"]["current_speed"]) < 0.001, "Velocidade independe dos frames")
		var huge = source.duplicate(true)
		var reduced = source.duplicate(true)
		var duration: float = source["rhythm"]["cycle_duration"]
		var delay: float = source["rhythm"]["initial_pause_remaining"]
		Route.advance(huge, 1000000.0 + delay)
		Route.advance(reduced, fmod(1000000.0, duration) + delay)
		expect(Route.position_at(huge, Vector2.ZERO).distance_to(Route.position_at(reduced, Vector2.ZERO)) < 0.001, "Passo enorme conserva sobra sem travar")
	var first: Array = []
	for enemy in model.enemies:
		first.append(enemy["route_state"].duplicate(true))
	for step in range(360):
		model.tick(STEP)
	var seed_after = model.rng.state
	model.start(4)
	expect(model.rng.state == seed_after, "Movimento não consome RNG de ações/alvos")
	for index in range(4):
		expect(model.enemies[index]["route_state"] == first[index], "Reinício reproduz perfil, início, relógios e pausas")

func _test_flight_and_bounds() -> void:
	var model = fresh()
	var flight: Dictionary = model.enemies[2]["route_state"]
	var minimum = INF
	var maximum = 0.0
	var last_position = Route.position_at(flight, Vector2.ZERO)
	for step in range(3600):
		for enemy in model.enemies.slice(0, 3):
			Route.advance(enemy["route_state"], STEP)
			var pos = Route.position_at(enemy["route_state"], Vector2.ZERO)
			expect(pos.x > 390 and pos.x < 890 and pos.y > 40 and pos.y < 400, "Percurso permanece no campo inimigo")
		var position = Route.position_at(flight, Vector2.ZERO)
		var speed: float = flight["rhythm"]["current_speed"]
		minimum = minf(minimum, speed)
		maximum = maxf(maximum, speed)
		expect(speed > 0.0 and position.distance_to(last_position) < 1.5, "Voo contínuo sem parada nem salto no fechamento")
		last_position = position
	expect(maximum - minimum > 30, "Voo possui mudança de ritmo perceptível")
	var static_route: Dictionary = model.enemies[3]["route_state"].duplicate(true)
	Route.advance(model.enemies[3]["route_state"], 50)
	expect(model.enemies[3]["route_state"] == static_route, "Participante estático preservado")

func _test_wait_active_and_atb() -> void:
	var model = fresh()
	model.party[0]["atb"] = 1.0
	model.mode = "Wait"
	model.select_actor("p1")
	var saved: Array = []
	for enemy in model.enemies:
		saved.append(enemy["route_state"].duplicate(true))
	model.tick(1.0)
	for index in range(4):
		expect(model.enemies[index]["route_state"] == saved[index], "Wait congela todas as etapas/velocidades/pausas")
	model.mode = "Active"
	model.tick(0.1)
	expect(model.enemies[0]["route_state"] != saved[0], "Active mantém cronograma durante seleção")
	model.cancel_selection()
	var enemy = model.enemies[0]
	var guard = 0
	while enemy["route_state"]["rhythm"]["movement_phase"] != "pause" and guard < 3000:
		model.tick(STEP)
		guard += 1
	expect(guard < 3000, "Alcança pausa programada")
	enemy["ini_modifier"] = 0.0
	var pos: Vector2 = enemy["logical_position"]
	var atb: float = enemy["atb"]
	model.tick(0.1)
	expect(enemy["logical_position"] == pos and enemy["atb"] > atb, "Pausa de movimento não pausa ATB")
	var unchanged = enemy["route_state"].duplicate(true)
	model.tick(0.0)
	expect(enemy["route_state"] == unchanged, "Tempo zero não avança estado")

func _test_interrupt_every_phase() -> void:
	for phase in ["initial_pause", "accelerate", "cruise", "decelerate", "pause", "backward"]:
		for skill_id in ["attack", "enemy_sweep", "all"]:
			var model = fresh()
			var enemy = model.enemies[0]
			var guard = 0
			while guard < 4000:
				var rhythm: Dictionary = enemy["route_state"]["rhythm"]
				if (phase == "backward" and rhythm["direction"] == -1 and rhythm["current_speed"] > 0) or (phase != "backward" and rhythm["movement_phase"] == phase):
					break
				model.tick(STEP)
				guard += 1
			expect(guard < 4000, "Estado de interrupção alcançado: " + phase)
			var saved: Dictionary = enemy["route_state"].duplicate(true)
			var origin: Vector2 = enemy["logical_position"]
			var hp: int = model.party[0]["hp"]
			model._begin_action(enemy, model.data["skills"][skill_id], "p1" if skill_id == "attack" else "", Vector2.ZERO, "")
			guard = 0
			while not model.action.is_empty() and guard < 240:
				model.tick(STEP)
				expect(enemy["route_state"] == saved and enemy["logical_position"] == origin, "Ação congela integralmente ritmo/rota: " + phase + "/" + skill_id)
				guard += 1
			expect(guard < 240 and model.party[0]["hp"] < hp, "Efeito executa e ação termina")
			expect(enemy["visual_offset"] == Vector2.ZERO and enemy["route_state"] == saved, "Retorno exato sem reiniciar velocidade/pausa")
			var expected = saved.duplicate(true)
			Route.advance(expected, STEP)
			model.tick(STEP)
			expect(enemy["route_state"] == expected, "Retomada corresponde exatamente ao próximo passo do snapshot")

func _test_target_geometry() -> void:
	var model = fresh()
	model.tick(0.5)
	var enemy = model.enemies[2]
	var logical: Vector2 = enemy["logical_position"]
	var bob = Route.presentation_offset(enemy["route_state"])
	expect(bob.length() > 1.0, "Flutuação visual existe")
	var skill = {"target": "circle", "effect": "damage", "radius": 0.1}
	var targets = model.targets_in_radius(model.party[0], skill, logical)
	expect(targets.size() == 1 and targets[0]["id"] == enemy["id"], "Mira de área usa posição lógica apesar da flutuação")
	expect(model.targets_in_radius(model.party[0], skill, logical + bob).is_empty(), "Offset visual não desloca geometria de efeito")
	var saved: Dictionary = enemy["route_state"].duplicate(true)
	model._begin_action(enemy, model.data["skills"]["all"], "", Vector2.ZERO, "")
	while not model.action.is_empty():
		model.tick(STEP)
	expect(enemy["route_state"] == saved and Route.presentation_offset(enemy["route_state"]) == bob, "Apresentação visual também retorna à fase preservada")

func _test_invalid_and_degenerate() -> void:
	for config in [{"steps": []}, {"steps": [{"to": 0.5}]}, {"steps": [{"to": 1, "speed_scale": 0}]},
		{"steps": [{"to": 1, "pause": -1}]}, {"pattern": "unknown"}, {"acceleration": NAN},
		{"pattern": "sequence", "steps": [{"to": 0.5}]},
		{"pattern": "sequence", "steps": [{"to": 0.5}, {"to": 0.5}, {"to": 0}]},
		{"steps": [{"to": 1, "return_speed_scale": 0}]}, {"steps": [{"to": 1, "return_pause": -1}]}]:
		var route = Route.create([[0, 0], [100, 0]], 20, {"rhythm": config})
		Route.advance(route, 1000000)
		expect(route["rhythm"]["phases"].is_empty() and Route.position_at(route, Vector2.ZERO) == Vector2.ZERO, "Configuração inválida fica imóvel sem travar")
	for points in [[], [[0, 0]], [[0, 0], [0, 0]]]:
		var route = Route.create(points, 20, {"rhythm": {"pattern": "ping_pong"}})
		Route.advance(route, 1000000)
		expect(route["rhythm"]["phases"].is_empty(), "Geometria degenerada não cria cronograma infinito")
	var short = Route.create([[0, 0], [0.01, 0]], 100, {"rhythm": {"pattern": "ping_pong"}})
	Route.advance(short, 1000000)
	expect(is_finite(Route.position_at(short, Vector2.ZERO).x), "Rota curta comprime rampas sem divisão por zero")

func _test_sequences() -> void:
	var options = {"rhythm": {"pattern": "sequence", "acceleration": 0.5, "deceleration": 0.5,
		"steps": [{"to": 0.4, "pause": 1.0}, {"to": 0.2, "pause": 2.0, "end_speed_scale": 1.0},
		{"to": 1.0, "pause": 3.0}, {"to": 0.0, "pause": 4.0, "end_speed_scale": 1.0}]}}
	var route = Route.create([[0, 0], [100, 0]], 20, options)
	expect(not route["closed"] and not route["rhythm"]["phases"].is_empty(), "Sequência usa rota aberta e aceita retornos parciais")
	var holds: Array = []
	var total = 0.0
	for phase in route["rhythm"]["phases"]:
		if phase["label"] == "pause":
			holds.append([phase["origin"], phase["duration"]])
		Route.advance(route, phase["duration"])
		total += phase["duration"]
		var pos: Vector2 = Route.position_at(route, Vector2.ZERO)
		expect(pos.x >= -0.001 and pos.x <= 100.001, "Retornos parciais respeitam geometria")
	expect(holds == [[40.0, 1.0], [20.0, 2.0], [100.0, 3.0], [0.0, 4.0]], "Marcos visitados em ordem assimétrica com pausas distintas")
	expect(Route.position_at(route, Vector2.ZERO).length() < 0.001, "Emenda da sequência retorna ao início sem teleporte")
	var split = Route.create([[0, 0], [100, 0]], 20, options)
	var whole = split.duplicate(true)
	for step in range(3000):
		Route.advance(split, STEP)
	Route.advance(whole, 25.0)
	expect(Route.position_at(split, Vector2.ZERO).distance_to(Route.position_at(whole, Vector2.ZERO)) < 0.001, "Sequência assimétrica independe dos frames")
	# Sem pausas, reversões ainda precisam frear, mesmo com velocidade final configurada.
	var turn = Route.create([[0, 0], [100, 0]], 20, {"rhythm": {"pattern": "sequence",
		"steps": [{"to": 1.0, "end_speed_scale": 1.0}, {"to": 0.0, "end_speed_scale": 1.0}]}})
	var previous: Dictionary = turn["rhythm"]["phases"].back()
	for phase in turn["rhythm"]["phases"]:
		if phase["direction"] != previous["direction"]:
			expect(phase["v0"] == 0 and previous["v1"] == 0, "Inversão de sentido parte do repouso inclusive na emenda")
		previous = phase

func _test_asymmetric_return() -> void:
	var route = Route.create([[0, 0], [100, 0]], 20, {"rhythm": {"pattern": "ping_pong", "turn_pause": 3.0,
		"steps": [{"to": 0.5, "pause": 1.0, "return_pause": 2.0, "speed_scale": 1.0, "return_speed_scale": 0.5},
		{"to": 1.0, "pause": 4.0, "return_speed_scale": 0.75}]}})
	var holds: Array = []
	var return_cruise: Array = []
	for phase in route["rhythm"]["phases"]:
		if phase["label"] == "pause":
			holds.append(phase["duration"])
		if phase["label"] == "cruise" and phase["direction"] == -1:
			return_cruise.append(phase["v0"])
	expect(holds == [1.0, 4.0, 2.0, 3.0], "Ida e volta possuem pausas diferentes em cada marco")
	expect(return_cruise == [15.0, 10.0], "Retorno permite velocidades diferentes das de ida")

func _test_approach_preset() -> void:
	var model = fresh()
	model.start(5)
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	expect(model.preset["id"] == "lab_approach", "Preset F oferece aproximações e voo amplo")
	var flight: Dictionary = model.enemies[2]["route_state"]
	var min_distance = INF
	var max_distance = 0.0
	for point in flight["points"]:
		expect(point.x > 250 and point.x < 890 and point.y > 40 and point.y < 400, "Voo amplo permanece no campo")
		for member in model.party:
			min_distance = minf(min_distance, point.distance_to(member["logical_position"]))
			expect(point.distance_to(member["logical_position"]) > 52, "Voo programado evita sobrepor aliados em repouso")
		max_distance = maxf(max_distance, point.distance_to(model.party[1]["logical_position"]))
	expect(min_distance < 120 and max_distance > 500, "Voador alterna aproximação real e afastamento amplo")
	var initial: Array = []
	for member in model.party:
		initial.append(member["logical_position"])
	var best = INF
	for step in range(9600):
		model.tick(STEP)
		best = minf(best, model.enemies[2]["logical_position"].distance_to(model.party[1]["logical_position"]))
		for index in range(4):
			expect(model.party[index]["logical_position"] == initial[index], "Aproximação inimiga não desloca aliados")
	expect(best < 120, "Voador alcança trecho próximo durante a simulação")
	# Atacar no trecho próximo mantém origem, percurso e retomada exatos.
	var guard = 0
	while model.enemies[2]["logical_position"].distance_to(model.party[1]["logical_position"]) > 120 and guard < 9600:
		model.tick(STEP)
		guard += 1
	expect(guard < 9600, "Trecho próximo é reencontrado de forma determinística")
	var flyer = model.enemies[2]
	var saved: Dictionary = flyer["route_state"].duplicate(true)
	var origin: Vector2 = flyer["logical_position"]
	model._begin_action(flyer, model.data["skills"]["attack"], "p2", Vector2.ZERO, "")
	guard = 0
	while not model.action.is_empty() and guard < 240:
		model.tick(STEP)
		guard += 1
	expect(guard < 240 and flyer["route_state"] == saved and flyer["logical_position"] == origin and flyer["visual_offset"] == Vector2.ZERO, "Melee próximo retorna à mesma rota ampla")
