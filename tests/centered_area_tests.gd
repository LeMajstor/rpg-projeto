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
	var battle = Battle.new(data.duplicate(true))
	battle.start(battle.default_preset_index(), false, 421)
	battle.mode = "Active"
	for enemy in battle.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
		enemy["route_state"] = Route.create([], 0)
	battle.enemies[0]["logical_position"] = Vector2(400, 200)
	battle.enemies[1]["logical_position"] = Vector2(300, 200)
	battle.enemies[2]["logical_position"] = Vector2(560, 200)
	battle.enemies[3]["logical_position"] = Vector2(880, 400)
	battle.party[0]["atb"] = 1.0
	battle.select_actor("p1")
	return battle

func finish(battle) -> void:
	var guard = 0
	while not battle.action.is_empty() and guard < 240:
		battle.tick(STEP)
		guard += 1
	expect(guard < 240, "Ação centrada conclui")

func _run() -> void:
	_test_validation()
	_test_moving_center()
	_test_enemy_and_invalid_center()
	print("ÁREA CENTRADA: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_validation() -> void:
	var battle = fresh()
	var actor: Dictionary = battle.party[0]
	var mp: int = actor["mp"]
	var before: float = actor["atb"]
	expect(not battle.submit("circle", "", Vector2(400, 200)), "Ponto livre não é alvo central")
	expect(not battle.submit("circle", "p1"), "Área ofensiva rejeita aliado como centro")
	expect(not battle.submit("circle", "ausente"), "Centro inexistente rejeitado")
	battle.enemies[0]["hp"] = 0
	expect(not battle.submit("circle", "e1"), "Centro incapacitado rejeitado")
	expect(actor["mp"] == mp and actor["atb"] == before and battle.action.is_empty(), "Falhas não gastam MP nem prontidão")
	var heal = {"target": "circle", "effect": "hp", "radius": 112, "amount": 20}
	expect(battle.targets_for(actor, heal, "e2").is_empty(), "Área de recuperação só aceita o mesmo lado")
	expect(battle.targets_for(actor, heal, "p1").has(actor), "Consulta de recuperação pode centrar em aliado válido")

func _test_moving_center() -> void:
	var battle = fresh()
	var central: Dictionary = battle.enemies[0]
	central["route_state"] = Route.create([[400, 200], [700, 200]], 250)
	var origin: Vector2 = battle.party[0]["logical_position"]
	battle.party[1]["logical_position"] = Vector2(500, 200)
	var before: Array = battle.actors().map(func(actor): return actor["hp"])
	var preview = battle.targets_for(battle.party[0], data["skills"]["circle"], "e1")
	expect(preview.has(central) and preview.has(battle.enemies[1]) and not preview.has(battle.enemies[2]), "Prévia usa raio ao redor do centro atual")
	expect(battle.submit("circle", "e1", Vector2(0, 0)), "Área usa ID do centro, ignorando coordenada livre")
	var guard = 0
	while not battle.action["applied"] and guard < 120:
		battle.tick(STEP)
		expect(battle.action["center"] == central["logical_position"], "Centro acompanha posição lógica em cada tick até impacto")
		guard += 1
	expect(guard < 120 and central["logical_position"].x > 490, "Alvo se deslocou antes do impacto")
	expect(central["hp"] < before[4], "Centro móvel é atingido")
	expect(battle.enemies[1]["hp"] == before[5], "Inimigo que saiu do raio não recebe dano")
	expect(battle.enemies[2]["hp"] < before[6], "Inimigo que entrou no raio recebe dano")
	for index in range(4):
		expect(battle.party[index]["hp"] == before[index], "Aliados nunca recebem dano da área amiga")
	expect(battle.party[0]["logical_position"] == origin, "Área não altera posição lógica do executor")
	finish(battle)
	expect(battle.party[0]["visual_offset"] == Vector2.ZERO and battle.party[0]["atb"] == 0, "Retorno e consumo da ação preservados")

func _test_enemy_and_invalid_center() -> void:
	var battle = fresh()
	var central: Dictionary = battle.party[0]
	battle.party[1]["logical_position"] = central["logical_position"] + Vector2(40, 0)
	battle.enemies[1]["logical_position"] = central["logical_position"]
	var enemy_hp: int = battle.enemies[1]["hp"]
	var ally_hp: int = central["hp"]
	battle.cancel_selection()
	battle._begin_action(battle.enemies[0], data["skills"]["circle"], "p1", Vector2.ZERO, "")
	finish(battle)
	expect(central["hp"] < ally_hp and battle.party[1]["hp"] < battle.party[1]["max_hp"], "Área inimiga atinge apenas aliados no raio")
	expect(battle.enemies[1]["hp"] == enemy_hp, "Inimigos também não causam fogo amigo")
	battle = fresh()
	expect(battle.submit("circle", "e1"), "Ação confirmada com centro válido")
	var mp: int = battle.party[0]["mp"]
	var other_hp: int = battle.enemies[1]["hp"]
	battle.enemies[0]["hp"] = 0
	finish(battle)
	expect(battle.enemies[1]["hp"] == other_hp and battle.party[0]["mp"] == mp, "Centro invalidado após confirmar não retargeteia nem reembolsa custo")
