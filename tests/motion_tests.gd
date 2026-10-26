extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const Attack = preload("res://scripts/combat/attack_motion.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func _run() -> void:
	for test in [_test_legacy_presets, _test_smooth_route, _test_flight_and_speed,
		_test_attack_phases, _test_moving_melee_target, _test_exact_route_resume,
		_test_wait_and_active, _test_reset_and_missing_target, _test_large_step]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("MOVIMENTO/MELEE: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh():
	var model = Battle.new(data.duplicate(true))
	model.start(2)
	model.mode = "Active"
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	return model

func finish(model) -> void:
	var guard = 0
	while not model.action.is_empty() and guard < 240:
		model.tick(STEP)
		guard += 1
	expect(guard < 240, "Ação deve terminar sem travar")

func _test_legacy_presets() -> void:
	var legacy: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy_presets.json"))
	expect(data["presets"].size() >= 3, "Demonstração adicionada sem remover presets")
	for index in range(legacy.size()):
		expect(data["presets"][index] == legacy[index], "Preset A/B deve permanecer integralmente idêntico")
	var model = fresh()
	for enemy in model.enemies:
		var points = enemy["route_state"]["points"]
		for point in points:
			expect(point.x >= 390 and point.x <= 880 and point.y >= 40 and point.y <= 395, "Rotas da demonstração ficam na região inimiga e dentro do campo")
		var origin = enemy["logical_position"]
		model.start(2)
		expect(model.actor_by_id(enemy["id"])["logical_position"] == origin, "Novo encontro reproduz início da curva")

func _test_smooth_route() -> void:
	var controls = [[0, 0], [100, 0], [100, 100], [0, 100]]
	var options = {"curve": "smooth", "kind": "ground", "samples_per_segment": 32}
	var route = Route.create(controls, 50, options)
	expect(route["points"].size() == 128, "Curva é amostrada de maneira determinística")
	expect(route == Route.create(controls, 50, options), "Mesmos dados produzem mesma rota, sem RNG")
	var points = route["points"]
	for index in range(points.size()):
		var incoming: Vector2 = (points[index] - points[(index - 1 + points.size()) % points.size()]).normalized()
		var outgoing: Vector2 = (points[(index + 1) % points.size()] - points[index]).normalized()
		expect(incoming.dot(outgoing) > 0.98, "Tangente suave inclusive no fechamento do loop")
	var split = route.duplicate(true)
	for step in range(1200):
		Route.advance(split, STEP)
	Route.advance(route, 10)
	expect(Route.position_at(route, Vector2.ZERO).distance_to(Route.position_at(split, Vector2.ZERO)) < 0.01, "Velocidade da curva independe da divisão do tempo")
	var degenerate = Route.create([[0, 0], [0, 0], [0, 0]], 99, options)
	Route.advance(degenerate, 1000000)
	expect(Route.position_at(degenerate, Vector2.ONE) == Vector2.ZERO, "Curva degenerada não trava")

func _test_flight_and_speed() -> void:
	var route = Route.create([[300, 200]], 120, {"curve":"ellipse", "kind":"air", "center":[200, 200], "radii":[100, 100]})
	for point in route["points"]:
		expect(absf(point.distance_to(Vector2(200, 200)) - 100) < 0.001, "Raios iguais permitem voo circular")
	var origin = Route.position_at(route, Vector2.ZERO)
	for step in range(120):
		var before = Route.position_at(route, Vector2.ZERO)
		Route.advance(route, STEP)
		var distance = before.distance_to(Route.position_at(route, Vector2.ZERO))
		expect(distance > 0.98 and distance <= 1.001, "Voo mantém velocidade por distância também nas curvas")
	Route.advance(route, (route["length"] - 120.0) / 120.0)
	expect(Route.position_at(route, Vector2.ZERO).distance_to(origin) < 0.01, "Voo fecha o loop sem salto")
	var static_route = Route.create([], 0, {"kind":"static"})
	Route.advance(static_route, 100)
	expect(Route.position_at(static_route, Vector2(300, 200)) == Vector2(300, 200), "Estático não é obrigado a se mover")

func _test_attack_phases() -> void:
	var motion = Attack.create(Vector2(100, 100), Vector2(700, 100), true, data["settings"])
	var approach = Attack.sample(motion, 0.25, Vector2(700, 100))
	expect(motion["phase"] == "approach" and approach.x > 0 and approach.x < 556, "Aproximação interpolada")
	var contact = Attack.sample(motion, 0.5, Vector2(700, 100))
	expect(contact == Vector2(556, 0) and motion["phase"] == "impact", "Melee chega a 44 unidades, sem antigo limite de 100")
	expect(motion["effect_strength"] == 1.0, "Impacto gera efeito provisório")
	expect(Attack.sample(motion, 0.6, Vector2(900, 100)) == contact, "Ponto de contato congela após chegada")
	var returning = Attack.sample(motion, 0.8, Vector2(900, 100))
	expect(motion["phase"] == "return" and returning.x < contact.x and returning.x > 0, "Retorno interpolado para origem preservada")
	expect(Attack.sample(motion, 1, Vector2(900, 100)) == Vector2.ZERO, "Retorno termina exatamente em offset zero")
	var close = Attack.create(Vector2.ZERO, Vector2(20, 0), true, data["settings"])
	expect(Attack.sample(close, 0.5, Vector2(20, 0)) == Vector2.ZERO, "Alvo já próximo não empurra atacante para trás")

func _test_moving_melee_target() -> void:
	var model = fresh()
	var actor = model.party[0]
	var target = model.enemies[1]
	var origin = actor["logical_position"]
	var target_start = target["logical_position"]
	var health = target["hp"]
	actor["atb"] = 1.0
	model.select_actor(actor["id"])
	expect(model.submit("precise", target["id"]), "Melee contra alvo voador é válido")
	var guard = 0
	while not model.action.is_empty() and not model.action["applied"] and guard < 240:
		expect(target["hp"] == health, "Dano não ocorre durante aproximação")
		expect(actor["logical_position"] == origin, "Aproximação não altera âncora lógica aliada")
		model.tick(STEP)
		guard += 1
	var impacted: bool = not model.action.is_empty() and model.action["applied"]
	expect(impacted, "Ataque deve chegar ao impacto dentro da duração prevista")
	if not impacted:
		return
	var visual: Vector2 = actor["logical_position"] + actor["visual_offset"]
	expect(absf(visual.distance_to(target["logical_position"]) - float(data["settings"]["melee_stop_distance"])) < 0.01, "Contato considera posição atual do alvo móvel")
	expect(target["logical_position"] != target_start, "Alvo continua voando durante aproximação")
	expect(actor["visual_offset"].length() > 100, "Sprite realmente percorre a distância até o inimigo")
	expect(target["hp"] == health - actor["attack"] - data["skills"]["precise"]["power"], "Efeito aplicado uma única vez ao chegar")
	expect(model.action["impact_points"].size() == 1, "Efeito visual usa o alvo atingido")
	finish(model)
	expect(actor["logical_position"] == origin and actor["visual_offset"] == Vector2.ZERO, "Aliado volta ao mesmo repouso")
	expect(actor["atb"] == 0 and actor["mp"] == actor["max_mp"] - 4, "Custos e ciclo ATB preservados")

func _test_exact_route_resume() -> void:
	for actor_index in [0, 1, 2]:
		for skill_id in ["attack", "enemy_sweep"]:
			var model = fresh()
			for step in range(37):
				model.tick(STEP)
			var enemy = model.enemies[actor_index]
			var origin = enemy["logical_position"]
			var saved = enemy["route_state"].duplicate(true)
			var before_hp = model.party[0]["hp"]
			model._begin_action(enemy, model.data["skills"][skill_id], "p1" if skill_id == "attack" else "", Vector2.ZERO, "")
			var guard = 0
			while not model.action.is_empty() and guard < 240:
				model.tick(STEP)
				expect(enemy["route_state"] == saved, "Segmento e progresso exatos congelados durante aproximação/impacto/retorno")
				expect(enemy["logical_position"] == origin, "Posição lógica inimiga não muda durante ação")
				guard += 1
			expect(guard < 240 and model.party[0]["hp"] < before_hp, "Ataque único/múltiplo conclui com efeito")
			expect(enemy["visual_offset"] == Vector2.ZERO, "Terrestre/voador/estático retorna exatamente à origem")
			var expected = saved.duplicate(true)
			Route.advance(expected, STEP)
			model.tick(STEP)
			expect(enemy["route_state"] == expected, "Rota retoma exatamente como avançar um passo do snapshot")

func _test_wait_and_active() -> void:
	var model = fresh()
	model.mode = "Wait"
	model.party[0]["atb"] = 1.0
	model.select_actor("p1")
	var saved: Array = []
	for enemy in model.enemies:
		saved.append(enemy["route_state"].duplicate(true))
	for step in range(60):
		model.tick(STEP)
	for index in range(3):
		expect(model.enemies[index]["route_state"] == saved[index], "Wait pausa curvas e voo na seleção")
	model.mode = "Active"
	model.enemies[1]["atb"] = 1.0
	model.tick(STEP)
	expect(not model.action.is_empty(), "Active permite inimigo agir durante seleção")
	model.mode = "Wait"
	var attacker = model.actor_by_id(model.action["actor_id"])
	var route = attacker["route_state"].duplicate(true)
	finish(model)
	expect(attacker["route_state"] == route and attacker["visual_offset"] == Vector2.ZERO, "Ação já iniciada conclui sem avançar rota ao mudar para Wait")
	expect(model.is_waiting(), "Seleção aliada continua pausando ATB/rotas após retorno")

func _test_reset_and_missing_target() -> void:
	var model = fresh()
	model.party[0]["atb"] = 1.0
	model.select_actor("p1")
	model.submit("attack", "e1")
	model.tick(0.2)
	expect(model.party[0]["visual_offset"] != Vector2.ZERO, "Reset será exercitado durante aproximação")
	model.start(2)
	expect(model.action.is_empty() and model.party[0]["visual_offset"] == Vector2.ZERO, "Novo teste remove deslocamento anterior")
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	model.party[0]["atb"] = 1.0
	model.select_actor("p1")
	model.submit("attack", "e1")
	model.enemies[0]["hp"] = 0
	finish(model)
	expect(model.party[0]["visual_offset"] == Vector2.ZERO and model.enemies[0]["hp"] == 0, "Alvo incapacitado antes do contato não impede retorno")

func _test_large_step() -> void:
	var model = fresh()
	model.party[0]["atb"] = 1.0
	model.select_actor("p1")
	var hp = model.enemies[0]["hp"]
	model.submit("attack", "e1")
	model.tick(2)
	expect(model.action.is_empty() and model.party[0]["visual_offset"] == Vector2.ZERO, "Passo maior que ação termina no repouso")
	expect(model.enemies[0]["hp"] == hp - model.party[0]["attack"] - 4 and model.completed_actions == 1, "Passo grande não duplica impacto")
