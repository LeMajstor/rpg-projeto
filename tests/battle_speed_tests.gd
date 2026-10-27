extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
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

func fresh(level: int = 4):
	var model = Battle.new(data.duplicate(true))
	model.start(model.default_preset_index(), false, 421)
	model.battle_speed = level
	model.mode = "Active"
	return model

func advance(model, seconds: float) -> void:
	for tick in range(roundi(seconds / STEP)):
		model.tick(STEP)

func _run() -> void:
	_test_levels()
	_test_mid_charge_and_wait()
	_test_motion_and_action()
	_test_lifecycle()
	print("BATTLE SPEED: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_levels() -> void:
	var defaults = Battle.new(data.duplicate(true))
	expect(defaults.battle_speed == 4, "Padrão atual é 4")
	var previous_scale: Array = [0.25, 0.4, 0.6, 0.8, 1.0, 1.25, 1.5, 2.0]
	for old_level in range(1, 8):
		var shifted = fresh(old_level + 1)
		expect(shifted.atb_rate_multiplier() == previous_scale[old_level - 1], "Reescala preserva ritmo anterior no nível seguinte: %d → %d" % [old_level, old_level + 1])
	var previous_rate = 0.0
	var previous_charge = 0.0
	for level in range(1, 9):
		var model = fresh(level)
		var rate: float = model.atb_rate_multiplier()
		expect(rate > previous_rate, "1 é mais lento e cada nível seguinte é mais rápido")
		advance(model, 2.0)
		expect(model.party[0]["atb"] > previous_charge, "Carga real aumenta com nível")
		for actor in model.actors():
			var old_rate: float = model.effective_ini(actor) * float(data["settings"]["atb_per_ini"])
			expect(is_equal_approx(actor["atb"], old_rate * rate * 2.0), "Multiplicador afeta aliados e inimigos usando INI efetiva")
		if level == 6:
			expect(rate == 1.0, "Nível 6 preserva o ritmo original de referência")
		previous_rate = rate
		previous_charge = model.party[0]["atb"]
	var reference = fresh(6)
	var slower = fresh(4)
	advance(reference, 2.0)
	advance(slower, 2.0)
	expect(slower.party[0]["atb"] < reference.party[0]["atb"], "Padrão 4 é mais lento que a referência 6")
	defaults.battle_speed = 0
	expect(defaults.battle_speed == 1, "Limite inferior é 1")
	defaults.battle_speed = 9
	expect(defaults.battle_speed == 8, "Limite superior é 8")

func _test_mid_charge_and_wait() -> void:
	var model = fresh(5)
	advance(model, 1.0)
	var before: float = model.party[0]["atb"]
	var snapshot: Dictionary = model.enemies[0]["route_state"].duplicate(true)
	var rng_state: int = model.rng.state
	model.battle_speed = 1
	expect(model.party[0]["atb"] == before and model.enemies[0]["route_state"] == snapshot and model.rng.state == rng_state, "Trocar nível preserva carga parcial, rota e RNG")
	advance(model, 1.0)
	var first_increment: float = model.party[0]["atb"] - before
	before = model.party[0]["atb"]
	model.battle_speed = 8
	advance(model, 1.0)
	expect(model.party[0]["atb"] - before > first_increment, "Novo nível vale para a carga seguinte sem reiniciar barra")
	model.party[0]["atb"] = 1.0
	model.mode = "Wait"
	model.select_actor("p1")
	before = model.enemies[0]["atb"]
	snapshot = model.enemies[0]["route_state"].duplicate(true)
	model.battle_speed = 3
	advance(model, 1.0)
	expect(model.enemies[0]["atb"] == before and model.enemies[0]["route_state"] == snapshot, "Battle Speed não contorna Wait")
	model.cancel_selection()
	advance(model, 1.0)
	expect(model.enemies[0]["atb"] > before and model.party[0]["atb"] == 1.0, "Cancelar retoma carga; barra pronta permanece saturada")

func _test_motion_and_action() -> void:
	var slow = fresh(1)
	var fast = fresh(8)
	advance(slow, 2.0)
	advance(fast, 2.0)
	expect(slow.simulation_time == fast.simulation_time, "Battle Speed não escala o relógio da simulação")
	for index in range(slow.enemies.size()):
		expect(slow.enemies[index]["route_state"] == fast.enemies[index]["route_state"], "Rotas, ritmos e sorteios de movimento independem do nível")
	for skill in ["attack", "all"]:
		slow = fresh(1)
		fast = fresh(8)
		for model in [slow, fast]:
			model._begin_action(model.party[0], data["skills"][skill], "e1" if skill == "attack" else "", Vector2.ZERO, "")
		advance(slow, 0.4)
		advance(fast, 0.4)
		expect(slow.action["elapsed"] == fast.action["elapsed"] and slow.party[0]["visual_offset"] == fast.party[0]["visual_offset"], "Melee/tela inteira usam a mesma duração e apresentação")
		advance(slow, 0.5)
		advance(fast, 0.5)
		expect(slow.action.is_empty() and fast.action.is_empty(), "Ação termina no mesmo tempo em todos os níveis")
		expect(slow.party[0]["visual_offset"] == Vector2.ZERO and fast.party[0]["visual_offset"] == Vector2.ZERO, "Retorno visual exato preservado")
		expect(slow.enemies[0]["hp"] == fast.enemies[0]["hp"] and slow.party[0]["mp"] == fast.party[0]["mp"], "Battle Speed não muda dano ou custos")

func _test_lifecycle() -> void:
	var model = fresh(2)
	model.party[0]["hp"] = 80
	model.party[0]["mp"] = 10
	model.start(model.default_preset_index(), true, 733)
	expect(model.battle_speed == 2 and model.party[0]["hp"] == 80 and model.party[0]["mp"] == 10, "Próxima luta preserva configuração e recursos")
	model.start(model.default_preset_index(), false, 421)
	expect(model.battle_speed == 2, "Novo teste do laboratório preserva escolha de velocidade")
