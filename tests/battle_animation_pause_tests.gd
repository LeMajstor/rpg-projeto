extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var checks = 0
var failures = 0
var data: Dictionary

func _initialize() -> void:
	data = Bridge.extend_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh(preset_id: String, mode_name: String, duration: float = 5.0):
	var definitions = data.duplicate(true)
	definitions["settings"]["action_duration"] = duration
	var battle = Battle.new(definitions)
	for index in range(definitions["presets"].size()):
		if definitions["presets"][index]["id"] == preset_id:
			battle.start(index, false, 733)
	battle.mode = mode_name
	battle.tick(0.2)
	for actor in battle.actors():
		actor["hp"] = 10000 # Fixture: nenhum impacto encerra a batalha.
		actor["atb"] = 0.25
	return battle

func snapshot(battle) -> Array:
	return battle.actors().map(func(actor): return {
		"atb": actor["atb"], "position": actor["logical_position"],
		"route": actor["route_state"].duplicate(true)
	})

func test_action(preset_id: String, mode_name: String, actor_id: String, skill_id: String) -> void:
	var battle = fresh(preset_id, mode_name)
	var actor = battle.actor_by_id(actor_id)
	var target = battle.enemies[0] if actor["side"] == "ally" else battle.party[0]
	actor["atb"] = 1.0
	battle.party[1]["atb"] = 1.0
	var skill = battle.skill_for(actor, skill_id)
	if actor["side"] == "ally":
		expect(battle.select_actor(actor_id), "Seleciona executor pronto")
		expect(battle.submit(skill_id, target["id"]), "Ação de teste inicia")
	else:
		battle._begin_action(actor, skill, target["id"], Vector2.ZERO, "")
	var before = snapshot(battle)
	var time_before: float = battle.simulation_time
	var hp_before: int = target["hp"]
	var saw_impact = false
	var saw_visual_motion = false
	var frozen = true
	var guard = 0
	while not battle.action.is_empty() and guard < 610:
		battle.tick(STEP)
		for index in range(battle.actors().size()):
			var current = battle.actors()[index]
			frozen = frozen and current["logical_position"] == before[index]["position"] and current["route_state"] == before[index]["route"]
			if not battle.action.is_empty() or current["id"] != actor_id:
				frozen = frozen and current["atb"] == before[index]["atb"]
		frozen = frozen and battle.simulation_time == time_before
		if not battle.action.is_empty():
			saw_impact = saw_impact or battle.action["applied"]
			saw_visual_motion = saw_visual_motion or actor["visual_offset"] != Vector2.ZERO
		guard += 1
	expect(guard >= 600 and guard < 610, "Apresentação de 5 segundos conclui pelo relógio próprio")
	expect(frozen, "ATB, posições e estado completo de todas as rotas/relógios/RNG ficam congelados")
	expect(saw_impact and target["hp"] < hp_before, "Impacto da própria ação continua aplicando dano")
	if skill.get("delivery", "melee") == "melee" or skill.get("presentation", "") == "fullscreen":
		expect(saw_visual_motion, "A animação visual avança enquanto a batalha está congelada")
	expect(actor["atb"] == 0 and actor["visual_offset"] == Vector2.ZERO, "Ação consome prontidão e retorna à origem")
	var expected_route: Dictionary = battle.enemies[0]["route_state"].duplicate(true)
	Route.advance(expected_route, STEP)
	battle.tick(STEP)
	expect(battle.enemies[0]["route_state"] == expected_route, "Retoma rota/RNG exatamente um passo após o retorno")
	expect(is_equal_approx(battle.simulation_time, time_before + STEP), "Sem recuperar os 5 segundos pausados ao retomar")
	expect(battle.party[0]["atb"] > (0.0 if actor_id == "p1" else 0.25), "ATB retoma após execução")

func test_ready_enemy() -> void:
	var battle = fresh("lab_seeded", "Active", 0.8)
	battle.party[0]["atb"] = 1.0
	battle.select_actor("p1")
	battle.submit("attack", "e1")
	battle.enemies[1]["atb"] = 1.0
	for index in range(20):
		battle.tick(STEP)
	expect(battle.action["actor_id"] == "p1" and battle.completed_actions == 0, "Inimigo pronto não interrompe ação em curso")
	for index in range(100):
		if battle.completed_actions > 0:
			break
		battle.tick(STEP)
	expect(battle.completed_actions == 1 and battle.action.get("actor_id", "") == battle.enemies[1]["id"], "Inimigo já pronto pode executar após o retorno")

func test_selection() -> void:
	for mode_name in ["Wait", "Active"]:
		var battle = fresh("lab_seeded", mode_name)
		battle.party[0]["atb"] = 1.0
		battle.select_actor("p1")
		var before = snapshot(battle)
		battle.tick(0.2)
		expect((snapshot(battle) == before) == (mode_name == "Wait"), "D132 preserva diferença Wait/Active durante seleção")

func run() -> void:
	for mode_name in ["Wait", "Active"]:
		for preset_id in ["lab_seeded", "lab_motion", "lab_damage_v1"]:
			test_action(preset_id, mode_name, "p1", "attack")
			test_action(preset_id, mode_name, "e1", "attack")
			if preset_id == "lab_seeded":
				test_action(preset_id, mode_name, "p1", "all")
			elif preset_id != "lab_motion":
				test_action(preset_id, mode_name, "p3", "magic_skill")
	test_ready_enemy()
	test_selection()
	print("PAUSA EM ANIMAÇÕES: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
