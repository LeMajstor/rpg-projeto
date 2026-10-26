extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const Policy = preload("res://scripts/combat/target_policy.gd")

var definitions: Dictionary
var checks = 0
var failures = 0
var groups = 0
const STEP = 1.0 / 120.0

func _initialize() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func _run() -> void:
	for test in [_test_data_and_presets, _test_atb_and_selection, _test_wait_active,
		_test_routes, _test_animation_return, _test_skills_and_costs, _test_area_at_impact,
		_test_items, _test_escape, _test_incapacitation_and_results,
		_test_weighted_policy, _test_enemy_decisions, _test_reproducibility, _test_long_simulation]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("RESULTADO: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh(index: int = 0):
	var battle = Battle.new(definitions.duplicate(true))
	battle.start(index, false, 421)
	for enemy in battle.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	return battle

func finish(battle) -> void:
	var guard = 0
	while not battle.action.is_empty() and guard < 500:
		battle.tick(STEP)
		guard += 1
	expect(guard < 500, "Ação travada")

func ready(battle, id: String = "p1") -> void:
	battle.actor_by_id(id)["atb"] = 1.0
	expect(battle.select_actor(id), "Aliado pronto deve ser selecionável")

func _test_data_and_presets() -> void:
	var battle = fresh()
	expect(battle.party.size() == 4, "Exatamente quatro aliados no laboratório")
	expect(definitions["presets"].size() >= 2, "Dois presets de encontro")
	var original: Array = []
	for actor in battle.actors():
		original.append(actor["logical_position"])
	battle.start(0)
	var repeated: Array = []
	for actor in battle.actors():
		repeated.append(actor["logical_position"])
	expect(original == repeated, "Reencontro deve reproduzir posições")
	battle.start(1)
	expect(battle.party[0]["logical_position"] != original[0], "Presets devem variar formação")
	for preset in definitions["presets"]:
		expect(preset["allied_slots"].size() == 4, "Preset precisa de quatro slots")
		for enemy in preset["enemies"]:
			expect(definitions["profiles"].has(enemy["profile"]), "Perfil referenciado deve existir")
			expect(enemy["route"].is_empty() or enemy["route"][0] == enemy["spawn"], "Início da rota coincide com spawn")

func _test_atb_and_selection() -> void:
	var battle = fresh()
	for index in range(240):
		battle.tick(STEP)
	expect(battle.party[1]["atb"] > battle.party[2]["atb"], "INI maior preenche mais rápido")
	var base = battle.party[0]["ini"]
	battle.party[0]["ini_modifier"] = 3.0
	expect(battle.effective_ini(battle.party[0]) == base + 3.0, "INI efetiva inclui modificador")
	expect(battle.party[0]["ini"] == base, "INI base permanece fixa")
	for index in range(2400):
		battle.tick(STEP)
	for actor in battle.party:
		expect(actor["atb"] == 1.0, "ATB satura em uma carga")
	expect(battle.select_actor("p4"), "Escolher quarto aliado pronto")
	expect(battle.select_actor("p2"), "Mudar para outro aliado pronto")
	battle.cancel_selection()
	expect(battle.party[3]["atb"] == 1.0, "Cancelar não consome ação")
	ready(battle)
	var mp = battle.party[0]["mp"]
	expect(battle.submit("attack", "e1"), "Ataque básico válido")
	expect(not battle.submit("attack", "e1"), "Não pode enviar duas ações do mesmo ator")
	finish(battle)
	expect(battle.party[0]["atb"] == 0.0, "ATB zera ao concluir ação")
	expect(battle.party[0]["mp"] == mp, "Ataque não gasta MP")
	expect(battle.party[1]["atb"] == 1.0, "Outro aliado pronto conserva sua carga")

func _test_wait_active() -> void:
	var battle = fresh()
	ready(battle)
	var before = battle.enemies[0]["route_state"].duplicate(true)
	var charge = battle.party[1]["atb"]
	for index in range(120):
		battle.tick(STEP)
	expect(before == battle.enemies[0]["route_state"], "Wait pausa rota durante seleção")
	expect(charge == battle.party[1]["atb"], "Wait pausa ATB")
	battle.mode = "Active"
	for index in range(120):
		battle.tick(STEP)
	expect(before != battle.enemies[0]["route_state"], "Active mantém rota durante seleção")
	expect(battle.party[1]["atb"] > charge, "Active mantém ATB")
	battle.mode = "Wait"
	battle.cancel_selection()
	before = battle.enemies[0]["route_state"].duplicate(true)
	battle.tick(STEP)
	expect(before != battle.enemies[0]["route_state"], "Wait avança fora da seleção")

func _test_routes() -> void:
	var route = Route.create([[0, 0], [10, 0], [10, 10], [0, 10]], 10)
	Route.advance(route, 4.5)
	expect(route["segment"] == 0 and is_equal_approx(route["progress"], 0.5), "Loop preserva excedente de tempo")
	expect(Route.position_at(route, Vector2.ZERO).is_equal_approx(Vector2(5, 0)), "Interpolação correta")
	var zeros = Route.create([[0, 0], [0, 0]], 10)
	Route.advance(zeros, 100)
	expect(Route.position_at(zeros, Vector2.ONE) == Vector2.ZERO, "Segmentos nulos não travam")
	var fixed = Route.create([], 0)
	expect(Route.position_at(fixed, Vector2(9, 8)) == Vector2(9, 8), "Inimigo estático mantém posição")
	var split = Route.create([[0, 0], [10, 0]], 10)
	var combined = split.duplicate(true)
	for index in range(60):
		Route.advance(split, STEP)
	Route.advance(combined, 0.5)
	expect(Route.position_at(split, Vector2.ZERO).is_equal_approx(Route.position_at(combined, Vector2.ZERO)), "Rota independente de divisão do tempo")

func _test_animation_return() -> void:
	for skill_id in ["attack", "enemy_sweep"]:
		var battle = fresh()
		battle.mode = "Active"
		for index in range(47):
			battle.tick(STEP)
		var enemy = battle.enemies[0]
		var route = enemy["route_state"].duplicate(true)
		var position = enemy["logical_position"]
		battle._begin_action(enemy, battle.data["skills"][skill_id], "p1", Vector2.ZERO, "")
		for index in range(20):
			battle.tick(STEP)
			expect(enemy["logical_position"] == position, "Lógica inimiga fixa durante ataque")
			expect(enemy["route_state"] == route, "Segmento e progresso exatos preservados")
		expect(enemy["visual_offset"].length() > 0, "Animação desloca somente o visual")
		finish(battle)
		expect(enemy["visual_offset"] == Vector2.ZERO, "Visual retorna exatamente à origem")
		expect(enemy["route_state"] == route, "Retorno não reinicia rota")
		battle.tick(STEP)
		expect(enemy["route_state"] != route, "Rota retoma a partir do ponto preservado")
	var battle = fresh()
	var home = battle.party[0]["logical_position"]
	ready(battle)
	battle.submit("attack", "e1")
	for index in range(20):
		battle.tick(STEP)
		expect(battle.party[0]["logical_position"] == home, "Aliado não sai da posição lógica")
	finish(battle)
	expect(battle.party[0]["visual_offset"] == Vector2.ZERO, "Aliado retorna ao idle")

func _test_skills_and_costs() -> void:
	var battle = fresh()
	ready(battle)
	var hp = battle.enemies[0]["hp"]
	var other_hp = battle.enemies[1]["hp"]
	expect(battle.submit("precise", "e1"), "Habilidade física especial válida")
	expect(battle.party[0]["mp"] == battle.party[0]["max_mp"] - 4, "Técnica física gasta MP")
	finish(battle)
	expect(battle.enemies[0]["hp"] < hp and battle.enemies[1]["hp"] == other_hp, "Alvo único afeta só o escolhido")
	ready(battle)
	battle.party[0]["mp"] = 0
	expect(not battle.submit("all"), "MP insuficiente rejeita ação")
	expect(battle.party[0]["atb"] == 1.0, "Falha de validação não consome barra")
	expect(not battle.submit("enemy_sweep", "e1"), "Aliado não acessa ação exclusiva inimiga")
	battle.party[0]["mp"] = 34
	var healths: Array = []
	for enemy in battle.enemies:
		healths.append(enemy["hp"])
	expect(battle.submit("all"), "Habilidade todos válida")
	finish(battle)
	for index in range(battle.enemies.size()):
		expect(battle.enemies[index]["hp"] < healths[index], "Todos os inimigos atingidos")

func _test_area_at_impact() -> void:
	var battle = fresh()
	var enemy = battle.enemies[0]
	enemy["route_state"] = Route.create([[600, 200], [900, 200]], 600)
	enemy["logical_position"] = Vector2(600, 200)
	ready(battle)
	var health = enemy["hp"]
	expect(battle.submit("circle", "", Vector2(600, 200)), "Área inicialmente contém alvo")
	finish(battle)
	expect(enemy["hp"] == health, "Área avalia posição no impacto; inimigo saiu da área")
	battle = fresh()
	ready(battle)
	health = battle.enemies[0]["hp"]
	expect(battle.submit("circle", "", Vector2(680, 155)), "Área válida aceita centro")
	finish(battle)
	expect(battle.enemies[0]["hp"] < health, "Inimigo dentro do raio recebe dano")

func _test_items() -> void:
	var battle = fresh()
	battle.party[1]["hp"] = 10
	ready(battle)
	var mp = battle.party[0]["mp"]
	expect(battle.submit("item", "p2", Vector2.ZERO, "hp"), "Usar item de HP em aliado vivo")
	finish(battle)
	expect(battle.party[1]["hp"] == 75, "Item restaura HP")
	expect(battle.party[0]["mp"] == mp and battle.inventory["hp"] == 5, "Item consome estoque, não MP")
	battle.party[1]["hp"] = 0
	ready(battle)
	expect(not battle.submit("item", "p2", Vector2.ZERO, "hp"), "Item comum não reanima")
	expect(battle.submit("item", "p2", Vector2.ZERO, "revive"), "Item de reanimação aceita incapacitado")
	finish(battle)
	expect(battle.party[1]["hp"] == 45 and battle.party[1]["atb"] < 1.0, "Reanimado retoma carga sem receber ação pronta")
	ready(battle)
	battle.party[1]["mp"] = 0
	expect(battle.submit("item", "p2", Vector2.ZERO, "mp"), "Item de MP válido")
	finish(battle)
	expect(battle.party[1]["mp"] == 18, "Item restaura MP")
	ready(battle)
	battle.inventory["hp"] = 0
	expect(not battle.submit("item", "p1", Vector2.ZERO, "hp"), "Estoque vazio rejeitado")

func _test_escape() -> void:
	for chance in [0.0, 1.0]:
		var battle = fresh()
		battle.data["settings"]["escape_chance"] = chance
		ready(battle)
		expect(battle.submit("escape"), "Fuga permitida aceita ação")
		finish(battle)
		expect(battle.party[0]["atb"] == 0, "Fuga consome ação")
		expect(battle.outcome == ("escaped" if chance == 1 else "running"), "Fuga termina grupo ou mantém batalha")
	var blocked = fresh(1)
	ready(blocked)
	expect(not blocked.submit("escape"), "Preset bloqueia fuga")
	expect(blocked.party[0]["atb"] == 1.0, "Fuga bloqueada não consome ação")

func _test_incapacitation_and_results() -> void:
	var battle = fresh()
	battle.party[1]["hp"] = 0
	battle.party[1]["atb"] = 0.9
	battle.tick(STEP)
	expect(battle.party[1]["atb"] == 0.0, "Incapacitado não carrega barra")
	expect(not battle.select_actor("p2"), "Incapacitado não pode agir")
	battle.party[2]["hp"] = 47
	battle.party[2]["mp"] = 5
	for enemy in battle.enemies:
		enemy["hp"] = 0
	battle.enemies[0]["hp"] = 1
	ready(battle)
	battle.submit("attack", "e1")
	finish(battle)
	expect(battle.outcome == "victory", "Último inimigo derrotado encerra batalha")
	expect(battle.party[1]["hp"] == 0, "Vitória não reanima")
	expect(battle.party[2]["hp"] == 47 and battle.party[2]["mp"] == 5, "Vitória não restaura recursos")
	expect(battle.start(1, true), "Próximo encontro pode preservar grupo")
	expect(battle.party[1]["hp"] == 0 and battle.party[2]["mp"] == 5, "Persistência entre encontros")
	for actor in battle.party:
		actor["hp"] = 0
	battle._check_end()
	expect(battle.outcome == "defeat", "Todos incapacitados causam Game Over")
	expect(not battle.start(0, true), "Grupo derrotado não continua sem restaurar teste")

func _test_weighted_policy() -> void:
	var battle = fresh()
	battle.party[0]["hp"] = 1
	var enemy = battle.enemies[0]
	var values = Policy.weights(enemy, battle.party, definitions["profiles"]["predator"])
	expect(values[0] > values[1], "Predador favorece menor fração de HP")
	enemy["last_target"] = "p3"
	values = Policy.weights(enemy, battle.party, definitions["profiles"]["focus"])
	expect(values[2] > values[0], "Implacável favorece alvo anterior")
	enemy["last_attacker"] = "p4"
	values = Policy.weights(enemy, battle.party, definitions["profiles"]["retaliator"])
	expect(values[3] > values[0], "Retaliador favorece agressor recente")
	values = Policy.weights(enemy, battle.party, definitions["profiles"]["mage_hunter"])
	expect(values[1] > values[2], "Caçador de Magos favorece MP máximo")
	var rng = RandomNumberGenerator.new()
	rng.seed = 9
	var counts = [0, 0]
	for index in range(10000):
		counts[Policy.pick_index([1.0, 4.0], rng)] += 1
	expect(counts[1] > counts[0] * 3 and counts[0] > 1000, "Preferência probabilística não é escolha absoluta")
	expect(Policy.pick_index([], rng) == -1, "Sem candidatos tem retorno seguro")
	expect(Policy.pick_index([0, -1, NAN], rng) in [0, 1, 2], "Pesos inválidos têm fallback seguro")

func _test_enemy_decisions() -> void:
	var battle = fresh()
	battle.party[0]["hp"] = 0
	for index in range(25):
		battle._schedule_enemy(battle.enemies[0])
		expect(battle.decisions.back()["chosen"] != "p1", "IA exclui incapacitado do sorteio")
		battle.action = {}
	for actor in battle.party:
		actor["hp"] = 0
	battle._schedule_enemy(battle.enemies[0])
	expect(battle.action.is_empty() and battle.outcome == "defeat", "Nenhum alvo não trava IA")

func _test_reproducibility() -> void:
	var first = fresh()
	var second = fresh()
	for index in range(100):
		first._schedule_enemy(first.enemies[0])
		second._schedule_enemy(second.enemies[0])
		expect(first.decisions.back() == second.decisions.back(), "Mesma semente e entradas reproduzem decisão")
		first.action = {}
		second.action = {}

func _test_long_simulation() -> void:
	for preset_index in range(2):
		for mode in ["Wait", "Active"]:
			var battle = Battle.new(definitions.duplicate(true))
			battle.start(preset_index)
			battle.mode = mode
			var iterations = 0
			while battle.outcome == "running" and iterations < 30000:
				if battle.action.is_empty():
					for actor in battle.party:
						if battle.is_ready(actor):
							battle.select_actor(actor["id"])
							var opponents = battle.living(battle.enemies)
							if not opponents.is_empty():
								battle.submit("attack", opponents[0]["id"])
							break
				battle.tick(STEP)
				for actor in battle.party:
					expect(actor["logical_position"] == actor["home_position"], "Aliado manteve âncora durante simulação completa")
				iterations += 1
			expect(battle.outcome in ["victory", "defeat"], "Batalha completa sem travamento em %s" % mode)
