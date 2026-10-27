extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const Behavior = preload("res://scripts/combat/route_behavior.gd")
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

func fresh(seed_value: int = 421, index: int = 10):
	var model = Battle.new(data.duplicate(true))
	model.start(index, false, seed_value)
	model.mode = "Active"
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	return model

func _run() -> void:
	for test in [_test_catalog, _test_enemy_initiative, _test_seeds, _test_behavior_independence, _test_turns_and_pauses,
		_test_hover_and_atb, _test_facing, _test_interruptions, _test_formations, _test_invalid]:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("COMPORTAMENTO/SEMENTE: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_catalog() -> void:
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre_behavior_combat.json"))
	expect(data["presets"].slice(0, 10) == before["presets"], "Todas as opções anteriores preservadas como legados")
	expect(data["legacy_preset_ids"].size() == 10, "Dez presets anteriores identificados como legados")
	for preset in before["presets"]:
		expect(preset["id"] in data["legacy_preset_ids"], "Nenhuma opção anterior permanece atual")
	for key in ["party", "skills", "settings", "items", "profiles", "movement_profiles"]:
		expect(data[key] == before[key], "Regras/dados anteriores preservados: " + key)
	var model = fresh()
	expect(model.default_preset_index() == 10 and model.preset["id"] == "lab_seeded", "Padrão usa nova versão")
	for enemy in model.enemies:
		expect(enemy["facing_policy"] == "focus" and enemy["route_state"].has("behavior"), "Até estáticos têm a política visual atual")

func _test_enemy_initiative() -> void:
	# INI varia nas fichas atuais; movimento não determina a carga de ATB.
	var model = Battle.new(data.duplicate(true))
	model.start(model.default_preset_index(), false, 421)
	model.mode = "Active"
	var heavy: Dictionary = model.enemies[0]
	var agile: Dictionary = model.enemies[1]
	var flying: Dictionary = model.enemies[2]
	var stationary: Dictionary = model.enemies[3]
	expect(agile["ini"] > flying["ini"] and flying["ini"] > heavy["ini"] and heavy["ini"] > stationary["ini"], "Tipos atuais têm INIs distintas para comparar ritmos de ação")
	for step in range(240):
		model.tick(STEP)
	expect(agile["atb"] > flying["atb"] and flying["atb"] > heavy["atb"] and heavy["atb"] > stationary["atb"], "Carga real segue INI, mesmo com ritmos de movimento diferentes")
	var guard = 0
	while model.action.is_empty() and guard < 2400:
		model.tick(STEP)
		guard += 1
	expect(guard < 2400 and model.action.get("actor_id") == agile["id"], "Ágil fica pronto primeiro apesar de não ser o primeiro do preset")
	expect(flying["atb"] < 1.0 and heavy["atb"] < 1.0 and stationary["atb"] < 1.0, "Primeira carga não sincroniza os quatro tipos")
	var initial_order: Array = [agile["id"]]
	var last_actor: String = agile["id"]
	guard = 0
	while initial_order.size() < 4 and guard < 2400:
		model.tick(STEP)
		var acting: String = model.action.get("actor_id", "")
		if not acting.is_empty() and acting != last_actor:
			if acting not in initial_order:
				initial_order.append(acting)
			last_actor = acting
		guard += 1
	expect(initial_order == [agile["id"], flying["id"], heavy["id"], stationary["id"]], "Primeira ação de cada tipo respeita sua INI no agendamento real")
	var equal = Battle.new(data.duplicate(true))
	equal.start(equal.default_preset_index(), false, 421)
	equal.mode = "Active"
	for enemy in equal.enemies:
		enemy["ini_modifier"] = 9.0 - float(enemy["ini"])
	for step in range(240):
		equal.tick(STEP)
	for enemy in equal.enemies:
		expect(is_equal_approx(enemy["atb"], equal.enemies[0]["atb"]), "Mesma INI efetiva produz mesma carga em qualquer perfil de movimento")
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre_behavior_combat.json"))
	for type_id in before["enemy_types"]:
		expect(data["enemy_types"][type_id] == before["enemy_types"][type_id], "Fichas dos legados conservam INI e demais valores")

func _test_seeds() -> void:
	var first = fresh()
	var repeat = fresh()
	var different = fresh(733)
	var action_rng = first.rng.state
	for step in range(7200):
		first.tick(STEP)
		repeat.tick(STEP)
		different.tick(STEP)
		if step % 120 == 0:
			for index in range(4):
				expect(first.enemies[index]["route_state"] == repeat.enemies[index]["route_state"], "Mesma semente/entradas reproduzem movimento e RNG exatamente")
	expect(first.rng.state == action_rng, "Movimento nunca consome RNG de ações/alvos")
	expect(first.enemies[0]["route_state"]["behavior"]["history"] != different.enemies[0]["route_state"]["behavior"]["history"], "Outra semente muda decisões e pausas")
	var counts = {}
	var durations = {}
	for seed_value in range(6):
		var config: Dictionary = data["movement_behaviors"]["heavy"]
		var state = Behavior.create(300, false, 32, config, seed_value)
		Behavior.advance(state, 60.0)
		counts[state["pause_count"]] = true
		for decision in state["history"]:
			if decision["pause"] > 0:
				durations[snappedf(decision["pause"], 0.01)] = true
	expect(counts.size() > 1 and durations.size() > 5, "Semente varia quantidade e duração das pausas")
	var source: Dictionary = first.enemies[2]["route_state"]
	var split = source.duplicate(true)
	var whole = source.duplicate(true)
	for step in range(1200):
		Route.advance(split, STEP)
	Route.advance(whole, 10.0)
	expect(Route.position_at(split, Vector2.ZERO).distance_to(Route.position_at(whole, Vector2.ZERO)) < 0.01, "Integração por fases independe dos frames")
	expect(split["behavior"]["rng_state"] == whole["behavior"]["rng_state"], "Partição do tempo não altera sorteios")

func _test_behavior_independence() -> void:
	var model = fresh()
	var definition: Dictionary = data["enemy_types"]["heavy_seeded"]
	var before = data.duplicate(true)
	var normal = model._movement_settings(definition, {})
	var attempted = model._movement_settings(definition, {"speed": 999, "movement_behavior": "flying", "movement_profile": "agile_test",
		"motion": {"behavior": {"reverse_chance": 0}, "rhythm": {"pattern": "loop"}, "kind": "air"}})
	expect(normal == attempted, "Preset não controla pesos, velocidade ou política de sorteios")
	expect(data == before, "Resolver comportamento não altera dados fonte")
	var config = data.duplicate(true)
	var alternate: Dictionary = config["presets"][10].duplicate(true)
	alternate["id"] = "another_preset"
	alternate["name"] = "Outro cenário"
	for enemy in alternate["enemies"]:
		for point in enemy["route"]:
			point[0] += 10
	config["presets"].append(alternate)
	var other = Battle.new(config)
	other.start(config["presets"].size() - 1, false, 421)
	for index in range(3):
		var first: Dictionary = model.enemies[index]["route_state"]["behavior"]
		var second: Dictionary = other.enemies[index]["route_state"]["behavior"]
		expect(first["rng_state"] == second["rng_state"] and first["history"] == second["history"] and first["config"] == second["config"], "ID/cenário do preset não entram no sorteio; geometria permanece separada")
	# Sorteios de um participante não interferem nos de outro.
	var untouched: Dictionary = model.enemies[1]["route_state"].duplicate(true)
	Route.advance(model.enemies[0]["route_state"], 80)
	expect(model.enemies[1]["route_state"] == untouched, "Cada inimigo possui RNG e cronograma próprios")

func _test_turns_and_pauses() -> void:
	var config: Dictionary = data["movement_behaviors"]["heavy"].duplicate(true)
	config["reverse_chance"] = 1.0
	var state = Behavior.create(100, false, 32, config, 3)
	var found = false
	for step in range(5000):
		Behavior.advance(state, STEP)
		expect(state["distance"] >= 0 and state["distance"] <= 100, "Terrestre permanece no caminho existente")
		if state["direction"] != state["pending_direction"]:
			found = true
			expect(state["movement_phase"] == "pause" and state["current_speed"] == 0, "Inversão espera em repouso antes de mudar sentido")
			var target_direction: int = state["pending_direction"]
			var point: float = state["distance"]
			Behavior.advance(state, state["pause_remaining"])
			expect(state["direction"] == target_direction and state["current_speed"] < 0.001, "Novo sentido começa com velocidade zero")
			expect(absf(state["distance"] - point) < 0.001, "Troca de sentido não teleporta")
			Behavior.advance(state, 0.05)
			expect(state["current_speed"] > 0 and state["current_speed"] < 32, "Retomada acelera gradualmente")
			break
	expect(found, "Sorteio de inversão ocorre")
	var ordinary = Behavior.create(300, false, 32, data["movement_behaviors"]["heavy"], 421)
	Behavior.advance(ordinary, 120)
	var continued = false
	var reversed = false
	for decision in ordinary["history"]:
		continued = continued or not decision["reverse"]
		reversed = reversed or decision["reverse"]
	expect(continued and reversed, "Comportamento alterna continuar e voltar, sem roteiro fixo")

func _test_hover_and_atb() -> void:
	var model = fresh()
	var flyer = model.enemies[2]
	var guard = 0
	while flyer["route_state"]["behavior"]["movement_phase"] != "pause" and guard < 12000:
		model.tick(STEP)
		guard += 1
	expect(guard < 12000, "Voador entra em pausa de comportamento durante o voo")
	var position: Vector2 = flyer["logical_position"]
	var bob = Route.presentation_offset(flyer["route_state"])
	flyer["ini_modifier"] = 0.0
	var atb: float = flyer["atb"]
	model.tick(0.1)
	expect(flyer["logical_position"] == position and Route.presentation_offset(flyer["route_state"]) != bob, "Pairar mantém posição lógica e flutuação visual")
	expect(flyer["atb"] > atb, "ATB carrega enquanto voador paira")
	model.mode = "Wait"
	model.party[0]["atb"] = 1.0
	model.select_actor("p1")
	var saved: Dictionary = flyer["route_state"].duplicate(true)
	model.tick(0.5)
	expect(flyer["route_state"] == saved, "Wait congela pausa, flutuação, cronograma e RNG")

func _test_facing() -> void:
	var model = fresh()
	var enemy = model.enemies[0]
	var focus = model.actor_by_id(enemy["visual_focus_id"])
	expect(not focus.is_empty(), "Inimigo começa atento a um aliado")
	var original_focus: String = focus["id"]
	model.party[0]["logical_position"] = enemy["logical_position"] + Vector2(5, 0)
	model._update_facing()
	expect(enemy["visual_focus_id"] == original_focus, "Foco válido é estável mesmo se outro aliado fica mais próximo")
	focus["hp"] = 0
	model._update_facing()
	expect(enemy["visual_focus_id"] != original_focus and model.actor_by_id(enemy["visual_focus_id"])["hp"] > 0, "Foco incapacitado é substituído")
	model = fresh()
	enemy = model.enemies[0]
	var backpedal = false
	for step in range(4800):
		model.tick(STEP)
		focus = model.actor_by_id(enemy["visual_focus_id"])
		var expected: Vector2 = enemy["logical_position"].direction_to(focus["logical_position"])
		expect(enemy["facing"].dot(expected) > 0.999, "Olhar acompanha aliado, não a direção da rota")
		if enemy["route_state"]["behavior"]["current_speed"] > 1:
			backpedal = backpedal or Route.travel_direction(enemy["route_state"]).dot(enemy["facing"]) < -0.3
	expect(backpedal, "Inimigo pode recuar mantendo atenção no grupo")
	model._begin_action(enemy, model.data["skills"]["attack"], "p4", Vector2.ZERO, "")
	var target = model.actor_by_id("p4")
	for step in range(100):
		var expected: Vector2 = (enemy["logical_position"] + enemy["visual_offset"]).direction_to(target["logical_position"])
		expect(enemy["facing"].dot(expected) > 0.999, "Durante ataque olhar acompanha o alvo efetivo")
		if model.action.is_empty():
			break
		model.tick(STEP)
	var exception = fresh()
	var special = exception.enemies[0]
	special["facing_policy"] = "fixed"
	special["facing"] = Vector2.UP
	exception.tick(0.2)
	expect(special["facing"] == Vector2.UP, "Política fixa permite exceção sem criar conteúdo especial")

func _test_interruptions() -> void:
	for actor_index in [0, 2]:
		for phase in ["initial_pause", "accelerate", "cruise", "decelerate", "pause"]:
			for skill in ["attack", "all"]:
				var model = fresh()
				var enemy = model.enemies[actor_index]
				var guard = 0
				while enemy["route_state"]["behavior"]["movement_phase"] != phase and guard < 15000:
					model.tick(STEP)
					guard += 1
				expect(guard < 15000, "Fase interrompida alcançada: " + phase)
				var saved: Dictionary = enemy["route_state"].duplicate(true)
				var origin: Vector2 = enemy["logical_position"]
				model._begin_action(enemy, model.data["skills"][skill], "p4" if skill == "attack" else "", Vector2.ZERO, "")
				guard = 0
				while not model.action.is_empty() and guard < 240:
					model.tick(STEP)
					expect(enemy["route_state"] == saved and enemy["logical_position"] == origin, "Ataque congela rota, velocidade, pausa e RNG completos")
					guard += 1
				expect(guard < 240 and enemy["visual_offset"] == Vector2.ZERO, "Retorno à origem após melee/tela inteira")
				var expected = saved.duplicate(true)
				Route.advance(expected, STEP)
				model.tick(STEP)
				expect(enemy["route_state"] == expected, "Próximo tick retoma exatamente sorteio/pausa/rota anteriores")

func _test_formations() -> void:
	var formations = {}
	for index in range(10, 15):
		var model = fresh(421, index)
		formations[str(model.preset["allied_slots"])] = true
		for member in model.party:
			var position: Vector2 = member["logical_position"]
			expect(position.x >= 60 and position.x <= 850 and position.y >= 60 and position.y <= 380, "Formação cabe no campo com margem visual")
			for other in model.party:
				if member != other:
					expect(position.distance_to(other["logical_position"]) > 60, "Aliados em repouso não se sobrepõem")
		for enemy in model.enemies:
			var points: Array = enemy["route_state"]["points"]
			if points.is_empty():
				points = [enemy["logical_position"]]
			for point in points:
				expect(point.x >= 40 and point.x <= 890 and point.y >= 40 and point.y <= 400, "Rotas adaptadas à formação ficam no campo")
				for member in model.party:
					expect(point.distance_to(member["logical_position"]) > 52, "Rota %s/%s em %s perto de %s: %.2f" % [model.preset["id"], enemy["id"], point, member["id"], point.distance_to(member["logical_position"])])
		var positions = model.preset["allied_slots"].duplicate(true)
		model.start(index, false, 733)
		expect(model.preset["allied_slots"] == positions, "Semente não sorteia formação")
	expect(formations.size() == 5, "Cinco formações atuais distintas")

func _test_invalid() -> void:
	for patch in [{"pause_seconds": [2, 1]}, {"travel_seconds": [0, 1]}, {"speed_scale": [NAN, 2]}, {"pause_chance": 2}]:
		var config: Dictionary = data["movement_behaviors"]["heavy"].duplicate(true)
		config.merge(patch, true)
		var state = Behavior.create(100, false, 32, config, 0)
		Behavior.advance(state, 100)
		expect(state["phases"].is_empty() and state["movement_phase"] == "static", "Configuração inválida falha imóvel sem travar")
	var degenerate = Behavior.create(0, false, 32, data["movement_behaviors"]["heavy"], 0)
	Behavior.advance(degenerate, 100)
	expect(degenerate["phases"].is_empty(), "Rota degenerada não cria decisões infinitas")
