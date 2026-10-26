extends SceneTree
const World = preload("res://scripts/exploration/exploration_model.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
var battle_data: Dictionary
var map_data: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	battle_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	map_data = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_internal_split.json"))["lab_exterior"]
	call_deferred("_run")

func _run() -> void:
	for test in [_test_cardinal, _test_collision, _test_path_following, _test_history_and_time,
		_test_menu_and_leader, _test_encounter_guards, _test_victory_return, _test_escape_return, _test_defeat]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("EXPLORAÇÃO: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func world(clear_obstacles: bool = false):
	var config = map_data.duplicate(true)
	if clear_obstacles:
		config["obstacles"] = []
	return World.new(config, ["p1", "p2", "p3", "p4"])

func fresh():
	return Session.new(battle_data.duplicate(true), map_data.duplicate(true))

func approach(session) -> void:
	session.move(Vector2.RIGHT, 4.0)
	session.move(Vector2.UP, 1.75)
	expect(session.world.can_interact(), "Percurso livre deve alcançar o encontro")

func finish_action(battle) -> void:
	var guard = 0
	while not battle.action.is_empty() and guard < 200:
		battle.tick(1.0 / 120.0)
		guard += 1
	expect(guard < 200, "Ação reutilizada deve concluir")

func _test_cardinal() -> void:
	var map = world()
	var start = map.leader_position
	var moved = map.move(Vector2(1, 1), 0.1, "x")
	expect(moved == Vector2(18, 0), "Duas direções nunca produzem diagonal")
	moved = map.move(Vector2(1, -1), 0.1, "y")
	expect(moved == Vector2(0, -18), "Eixo mais recente pode ter prioridade vertical")
	map.move(Vector2.LEFT, 0.1)
	map.move(Vector2.DOWN, 0.1)
	expect(map.leader_position == start, "Quatro direções contínuas sem encaixe em grade")
	var positions = map.formation_positions()
	map.move(Vector2.ZERO, 10)
	expect(map.formation_positions() == positions, "Parar preserva a fila")
	expect(map.move(Vector2.RIGHT, 0) == Vector2.ZERO, "Delta nulo não move")

func _test_collision() -> void:
	var config = map_data.duplicate(true)
	config["spawn"] = [210, 300]
	var map = World.new(config, ["p1", "p2", "p3", "p4"])
	map.move(Vector2.RIGHT, 10)
	expect(map.leader_position == Vector2(288, 300), "Colisão varrida impede atravessar bloco mesmo com delta grande")
	map.move(Vector2.RIGHT, 1)
	expect(not map.moving and map.leader_position.x == 288, "Empurrar parede não registra movimento falso")
	map.move(Vector2.DOWN, 1)
	expect(map.leader_position.y == 480, "É possível contornar bloco encostado na borda")
	map.move(Vector2.RIGHT, 1)
	expect(map.leader_position.x > 428, "Passagem abaixo do bloco é livre")
	for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]:
		map.move(direction, 100)
		expect(map.is_walkable(map.leader_position), "Líder respeita limites e obstáculos")
	var initial = world()
	for position in initial.formation_positions():
		expect(initial.is_walkable(position), "Fila inicial deve estar livre de sólidos")

func _test_path_following() -> void:
	var map = world(true)
	map.move(Vector2.RIGHT, 100.0 / 180.0)
	map.move(Vector2.UP, 68.0 / 180.0)
	var positions = map.formation_positions()
	expect(positions[0].is_equal_approx(Vector2(310, 432)), "Líder no fim do caminho")
	expect(positions[1].is_equal_approx(Vector2(310, 466)), "Primeiro seguidor na parte vertical")
	expect(positions[2].is_equal_approx(Vector2(310, 500)), "Segundo seguidor na curva exata")
	expect(positions[3].is_equal_approx(Vector2(276, 500)), "Terceiro conserva trecho horizontal; não corta curva")
	map.move(Vector2.DOWN, 34.0 / 180.0)
	expect(map.formation_positions()[1].is_equal_approx(Vector2(310, 432)), "Retorno sobre o próprio caminho não bloqueia no seguidor")
	# Percurso com quatro curvas em torno dos blocos reais.
	map = world()
	for segment in [[Vector2.RIGHT, 4.0], [Vector2.UP, 2.2], [Vector2.LEFT, 0.4], [Vector2.DOWN, 0.2]]:
		for step in range(int(segment[1] * 120)):
			map.move(segment[0], 1.0 / 120.0)
			for position in map.formation_positions():
				expect(map.is_walkable(position), "Seguidores seguem trilha livre mesmo nas curvas")

func _test_history_and_time() -> void:
	var once = world(true)
	var divided = world(true)
	once.move(Vector2.RIGHT, 1)
	for step in range(120):
		divided.move(Vector2.RIGHT, 1.0 / 120.0)
	for index in range(4):
		expect(once.formation_positions()[index].is_equal_approx(divided.formation_positions()[index]), "Seguimento por distância independe de frames")
	expect(divided.path.size() == 2, "Histórico comprime segmentos colineares")
	for step in range(5000):
		divided.move(Vector2.LEFT if step % 2 == 0 else Vector2.RIGHT, 1.0 / 120.0)
	expect(divided.path.size() < 150, "Histórico descarta caminho anterior à cauda")

func _test_menu_and_leader() -> void:
	var session = fresh()
	var map = session.world
	expect(not map.choose_leader("p3"), "Liderança só muda pelo menu")
	map.menu_open = true
	var positions = map.formation_positions()
	var history = map.path.duplicate()
	map.move(Vector2.RIGHT, 1)
	expect(map.formation_positions() == positions, "Menu pausa exploração")
	expect(not map.choose_leader("unknown"), "Membro externo não pode liderar")
	expect(map.choose_leader("p3"), "Ativo escolhido pode liderar")
	expect(map.party_order == ["p3", "p1", "p2", "p4"], "Fila reorganizada sem duplicar ou perder membro")
	expect(map.formation_positions() == positions and map.path == history, "Troca não teleporta através dos sólidos")
	expect(not map.menu_open, "Escolha fecha menu")
	expect(session.battle.party[0]["id"] == "p1", "Liderança do mapa não troca identidade/slots do combate")
	map.menu_open = true
	map.choose_leader("p1")
	expect(map.party_order.size() == 4, "Protagonista continua ativo ao mudar liderança")

func _test_encounter_guards() -> void:
	var session = fresh()
	expect(not session.begin_encounter(), "Não iniciar batalha longe do inimigo")
	approach(session)
	session.world.menu_open = true
	expect(not session.begin_encounter(), "Menu aberto bloqueia interação")
	session.world.menu_open = false
	var position = session.world.leader_position
	expect(session.begin_encounter(), "Interação próxima inicia combate")
	expect(not session.begin_encounter(), "Não iniciar encontro duplicado")
	session.move(Vector2.LEFT, 1)
	expect(session.world.leader_position == position, "Mapa não se move durante batalha")
	expect(not session.finish_encounter(), "Batalha em curso não permite retorno")
	var invalid = fresh()
	approach(invalid)
	invalid.world.entity_by_id("test_map_enemy_01")["battle_preset_id"] = "invalid"
	expect(not invalid.begin_encounter() and invalid.state == "exploration", "Preset inexistente não inicia batalha errada")

func _test_victory_return() -> void:
	var session = fresh()
	approach(session)
	session.world.menu_open = true
	session.world.choose_leader("p4")
	var positions = session.world.formation_positions()
	var history = session.world.path.duplicate()
	session.battle.party[0]["hp"] = 127
	session.battle.party[0]["mp"] = 19
	session.battle.party[1]["hp"] = 0
	session.battle.inventory["hp"] = 2
	expect(session.begin_encounter(), "Entrar com recursos já gastos")
	expect(session.battle.party[0]["hp"] == 127 and session.battle.party[0]["mp"] == 19, "Entrada não restaura HP/MP")
	for enemy in session.battle.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	for index in range(3):
		session.battle.party[0]["atb"] = 1.0
		session.battle.select_actor("p1")
		session.battle.submit("precise" if index == 0 else "attack", "e%d" % (index + 1))
		finish_action(session.battle)
	expect(session.battle.outcome == "victory", "Vitória usa efeitos do combate existente")
	expect(session.finish_encounter(), "Vitória permite retorno")
	expect(session.state == "exploration" and not session.world.entity_by_id("test_map_enemy_01")["present"], "Vitória remove encontro apenas nesta sessão")
	expect(session.battle.party[0]["hp"] == 127 and session.battle.party[0]["mp"] == 15, "Retorno mantém HP e MP consumido em habilidade")
	expect(session.battle.party[1]["hp"] == 0 and session.battle.inventory["hp"] == 2, "Incapacitação e estoque persistem")
	expect(session.world.formation_positions() == positions and session.world.path == history, "Retorna ao mesmo caminho e coordenadas")
	expect(session.world.party_order[0] == "p4", "Líder escolhido persiste após combate")
	expect(not session.begin_encounter(), "Inimigo vencido não reaparece automaticamente")

func _test_escape_return() -> void:
	var session = fresh()
	approach(session)
	session.begin_encounter()
	for enemy in session.battle.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	session.battle.data["settings"]["escape_chance"] = 0
	session.battle.party[0]["atb"] = 1.0
	session.battle.select_actor("p1")
	session.battle.submit("escape")
	finish_action(session.battle)
	expect(not session.finish_encounter() and session.state == "battle", "Fuga falha mantém combate")
	session.battle.data["settings"]["escape_chance"] = 1
	session.battle.party[0]["hp"] = 75
	session.battle.party[0]["mp"] = 9
	session.battle.party[0]["atb"] = 1.0
	session.battle.select_actor("p1")
	session.battle.submit("escape")
	finish_action(session.battle)
	expect(session.finish_encounter() and session.state == "exploration", "Fuga bem-sucedida retorna")
	expect(session.world.entity_by_id("test_map_enemy_01")["present"], "Fuga mantém inimigo disponível")
	expect(session.battle.party[0]["hp"] == 75 and session.battle.party[0]["mp"] == 9, "Fuga não cura")
	expect(session.begin_encounter(), "Interação explícita permite reencontro após fuga")
	expect(session.battle.preset["id"] == "lab_a", "Reencontro reutiliza mesmo preset")
	expect(session.battle.party[0]["hp"] == 75, "Reencontro mantém recursos")

func _test_defeat() -> void:
	var session = fresh()
	approach(session)
	session.begin_encounter()
	for member in session.battle.party:
		member["hp"] = 0
	session.battle._check_end()
	expect(session.finish_encounter() and session.state == "defeat", "Derrota não devolve grupo curado ao mapa")
	expect(not session.begin_encounter(), "Game Over não permite nova batalha")
	var position = session.world.leader_position
	session.move(Vector2.RIGHT, 1)
	expect(session.world.leader_position == position, "Sem movimentação após derrota")
