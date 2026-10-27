extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var checks = 0
var failures = 0
var groups = 0

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	call_deferred("_run")

func _run() -> void:
	for test in [_test_defaults, _test_enemy_scheduler, _test_ally_center_and_effect, _test_static_and_exception,
		_test_mobile_resume, _test_runtime_override, _test_persistence,
		_test_presentation_independent_of_targets, _test_melee_preserved, _test_outcomes_and_large_step]:
		var before = failures
		test.call()
		groups += 1
		print("%s %s" % ["PASS" if failures == before else "FAIL", test.get_method()])
	print("TELA INTEIRA: %d grupos, %d verificações, %d falhas" % [groups, checks, failures])
	quit(0 if failures == 0 else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func fresh(preset: int = 3):
	var model = Battle.new(data.duplicate(true))
	model.start(preset)
	model.mode = "Active"
	for enemy in model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	return model

func start_ally(model, id: String = "p1") -> void:
	model.actor_by_id(id)["atb"] = 1.0
	expect(model.select_actor(id) and model.submit("all"), "Aliado pronto consegue usar Onda")

func impact(model) -> bool:
	var guard = 0
	while not model.action.is_empty() and not model.action["applied"] and guard < 240:
		model.tick(STEP)
		guard += 1
	var applied: bool = not model.action.is_empty() and model.action["applied"]
	expect(applied, "Ação alcança o impacto")
	return applied

func finish(model) -> void:
	var guard = 0
	while not model.action.is_empty() and guard < 240:
		model.tick(STEP)
		guard += 1
	expect(guard < 240, "Ação retorna sem travar")

func _test_defaults() -> void:
	var model = fresh()
	for actor in model.party:
		expect(model.fullscreen_center_enabled(actor), "Personagens usam centro por padrão")
	expect(model.fullscreen_center_enabled(model.enemies[0]), "Móvel usa centro por padrão")
	expect(not model.fullscreen_center_enabled(model.enemies[1]), "Estático fica no lugar por padrão")
	expect(model.fullscreen_center_enabled(model.enemies[2]), "Exceção estática usa configuração individual")
	var first = model.enemies[1]
	var second = model.enemies[2]
	expect(first["name"].contains("Estático") and second["name"].contains("Estático"), "Exceção não depende de outro tipo de inimigo")
	var config = data.duplicate(true)
	config["party"][0][Battle.CENTER_SETTING] = false
	config["presets"][3]["enemies"][0][Battle.CENTER_SETTING] = false
	config["enemy_types"]["static"][Battle.CENTER_SETTING] = true
	config["presets"][3]["enemies"][1][Battle.CENTER_SETTING] = false
	model = Battle.new(config)
	model.start(3)
	expect(not model.fullscreen_center_enabled(model.party[0]) and model.fullscreen_center_enabled(model.party[1]), "Configuração de ficha é individual")
	expect(not model.fullscreen_center_enabled(model.enemies[0]), "Móvel também pode ser configurado para ficar")
	expect(not model.fullscreen_center_enabled(model.enemies[1]), "Entrada individual prevalece sobre padrão do tipo")
	var definition = data["party"][0].duplicate(true)
	definition.erase(Battle.CENTER_SETTING)
	expect(model._make_actor(definition, "ally", "test")[Battle.CENTER_SETTING], "Ficha antiga sem propriedade recebe padrão compatível")

func _test_enemy_scheduler() -> void:
	for index in range(3):
		var model = fresh()
		var actor = model.enemies[index]
		actor["atb"] = 1.0
		model.tick(STEP)
		expect(model.action.get("actor_id", "") == actor["id"], "ATB inimigo agenda o participante pronto")
		expect(model.action.get("skill", {}).get("presentation", "") == "fullscreen", "Lista do preset D seleciona Onda pelo fluxo normal da IA")
		expect(model.action["motion"]["move_to_center"] == model.fullscreen_center_enabled(actor), "IA respeita configuração individual na apresentação")
		finish(model)
		expect(actor["mp"] == actor["max_mp"] - 10 and actor["atb"] == 0, "Conjuração inimiga mantém custo e ciclo ATB")

func _test_ally_center_and_effect() -> void:
	var model = fresh()
	var actor = model.party[0]
	var origin = actor["logical_position"]
	var route = actor["route_state"].duplicate(true)
	var health: Array = []
	for enemy in model.enemies:
		health.append(enemy["hp"])
	start_ally(model)
	expect(model.action["motion"]["presentation"] == "fullscreen" and not model.action["motion"]["melee"], "Tela inteira usa apresentação própria")
	if not impact(model):
		return
	expect(actor["logical_position"] + actor["visual_offset"] == model.visual_center(), "Sprite chega exatamente ao centro visual")
	expect(actor["logical_position"] == origin and actor["route_state"] == route, "Origem e rota não se deslocam")
	for index in range(model.enemies.size()):
		expect(model.enemies[index]["hp"] == health[index] - actor["attack"] - data["skills"]["all"]["power"], "Efeito atinge todos independentemente da posição do ator")
	var enemy = model.enemies[0]
	var location: Vector2 = actor["logical_position"]
	var query = {"target":"circle", "radius":1.0, "effect":"damage"}
	expect(model.targets_in_radius(enemy, query, location).has(actor), "Outras consultas de área continuam usando a âncora lógica")
	finish(model)
	expect(actor["logical_position"] == origin and actor["visual_offset"] == Vector2.ZERO, "Aliado retorna ao repouso exato")
	expect(actor["mp"] == actor["max_mp"] - 10 and actor["atb"] == 0, "Custo/ATB permanecem iguais")

func _test_static_and_exception() -> void:
	for index in [1, 2]:
		var model = fresh()
		var actor = model.enemies[index]
		var origin = actor["logical_position"]
		var route = actor["route_state"].duplicate(true)
		var hp = model.party[0]["hp"]
		model._begin_action(actor, model.data["skills"]["all"], "", Vector2.ZERO, "")
		var guard = 0
		while not model.action.is_empty() and guard < 240:
			model.tick(STEP)
			expect(actor["logical_position"] == origin and actor["route_state"] == route, "Estático preserva âncora e rota mesmo com exceção")
			if index == 1:
				expect(actor["visual_offset"] == Vector2.ZERO, "Estático desabilitado fica totalmente imóvel")
			elif not model.action.is_empty() and model.action["motion"]["phase"] == "impact":
				expect(actor["logical_position"] + actor["visual_offset"] == model.visual_center(), "Estático habilitado também chega ao centro")
			guard += 1
		expect(guard < 240 and actor["visual_offset"] == Vector2.ZERO, "Estático conclui e retorna")
		expect(model.party[0]["hp"] < hp, "Habilidade produz efeito também sem deslocamento")

func _test_mobile_resume() -> void:
	for index in [0, 1]:
		var model = fresh(2) # Terrestre suave e voo elíptico do preset C.
		for step in range(47):
			model.tick(STEP)
		var actor = model.enemies[index]
		var origin = actor["logical_position"]
		var route = actor["route_state"].duplicate(true)
		model._begin_action(actor, model.data["skills"]["all"], "", Vector2.ZERO, "")
		var guard = 0
		while not model.action.is_empty() and guard < 240:
			model.tick(STEP)
			expect(actor["route_state"] == route and actor["logical_position"] == origin, "Móvel congela progresso durante aproximação, execução e retorno")
			if not model.action.is_empty() and model.action["motion"]["phase"] == "impact":
				expect(actor["logical_position"] + actor["visual_offset"] == model.visual_center(), "Móvel usa centro no impacto")
			guard += 1
		expect(guard < 240 and actor["visual_offset"] == Vector2.ZERO, "Móvel retorna exatamente à origem")
		var expected = route.duplicate(true)
		Route.advance(expected, STEP)
		model.tick(STEP)
		expect(actor["route_state"] == expected, "Retomada coincide exatamente com avanço de um passo do snapshot")

func _test_runtime_override() -> void:
	var model = fresh()
	var actor = model.party[0]
	expect(actor[Battle.CENTER_SETTING], "Protagonista não recebe restrição narrativa por antecipação")
	expect(model.set_fullscreen_center_override("p1", false) and not model.fullscreen_center_enabled(actor), "API permite impedir deslocamento temporariamente")
	start_ally(model)
	model.set_fullscreen_center_override("p1", true)
	expect(not model.action["motion"]["move_to_center"], "Mudança depois da confirmação não altera ação atual")
	if not impact(model):
		return
	expect(actor["visual_offset"] == Vector2.ZERO and actor[Battle.CENTER_SETTING], "Override desliga só a apresentação, sem alterar base")
	finish(model)
	start_ally(model)
	model.set_fullscreen_center_override("p1", false)
	if not impact(model):
		return
	expect(actor["logical_position"] + actor["visual_offset"] == model.visual_center(), "Próxima ação usa override que estava ativo ao confirmar")
	finish(model)
	expect(actor["visual_offset"] == Vector2.ZERO, "Mudança no meio da ação não deixa deslocamento residual")
	expect(model.set_fullscreen_center_override("p1") and model.fullscreen_center_enabled(actor), "Limpar condição restaura configuração base")
	expect(not model.set_fullscreen_center_override("unknown", true), "ID inválido é rejeitado")
	expect(not model.set_fullscreen_center_override("p1", "false"), "Somente bool ou null são aceitos")

func _test_persistence() -> void:
	var model = fresh()
	model.set_fullscreen_center_override("p1", false)
	model.start(0, true)
	expect(not model.fullscreen_center_enabled(model.party[0]), "Alteração de estado pode persistir entre encontros")
	model.start(0, false)
	expect(model.fullscreen_center_enabled(model.party[0]) and model.party[0]["fullscreen_center_override"] == null, "Novo teste reconstrói a configuração inicial")
	expect(data["party"][0][Battle.CENTER_SETTING], "Estado temporário não escreve na definição")

func _test_presentation_independent_of_targets() -> void:
	var model = fresh()
	for enemy in model.enemies:
		enemy["route_state"]["speed"] = 0.0
	var actor = model.party[0]
	var hp = model.enemies[1]["hp"]
	var test_skill = model.data["skills"]["all"].duplicate(true)
	test_skill["target"] = "circle"
	test_skill["radius"] = 1.0
	test_skill["mp_cost"] = 0
	var center: Vector2 = model.enemies[0]["logical_position"]
	model._begin_action(actor, test_skill, "e1", center, "")
	if not impact(model):
		return
	expect(actor["logical_position"] + actor["visual_offset"] == model.visual_center(), "Centro de apresentação independe do centro da área")
	expect(model.enemies[0]["hp"] < model.enemies[0]["max_hp"] and model.enemies[1]["hp"] == hp, "Efeito respeita geometria original mesmo com apresentação de tela inteira")
	finish(model)
	# Sem marcação de apresentação, acertar todos não implica ir ao centro.
	var skill = model.data["skills"]["all"].duplicate(true)
	skill.erase("presentation")
	skill["mp_cost"] = 0
	model._begin_action(actor, skill, "", Vector2.ZERO, "")
	expect(not model.action["motion"].has("presentation"), "Target all sozinho não ativa apresentação ao centro")
	finish(model)

func _test_melee_preserved() -> void:
	for override in [true, false]:
		var model = fresh()
		model.set_fullscreen_center_override("p1", override)
		model.party[0]["atb"] = 1.0
		model.select_actor("p1")
		model.submit("attack", "e1")
		expect(model.action["motion"]["melee"] and not model.action["motion"].has("presentation"), "Opção de tela inteira não altera ataque melee")
		if not impact(model):
			return
		var visual: Vector2 = model.party[0]["logical_position"] + model.party[0]["visual_offset"]
		expect(absf(visual.distance_to(model.enemies[0]["logical_position"]) - 44) < 0.01, "Melee continua chegando perto do alvo")
		finish(model)
		model._begin_action(model.enemies[0], model.data["skills"]["enemy_sweep"], "", Vector2.ZERO, "")
		expect(model.action["motion"]["melee"], "Varredura continua melee mesmo afetando todos")
		finish(model)

func _test_outcomes_and_large_step() -> void:
	var model = fresh()
	for enemy in model.enemies:
		enemy["hp"] = 1
	start_ally(model)
	if not impact(model):
		return
	expect(model.outcome == "running", "Vitória aguarda retorno visual")
	finish(model)
	expect(model.outcome == "victory" and model.party[0]["visual_offset"] == Vector2.ZERO, "Vitória conclui sem deixar ator no centro")
	model = fresh()
	start_ally(model)
	model.tick(2.0)
	expect(model.action.is_empty() and model.completed_actions == 1 and model.party[0]["visual_offset"] == Vector2.ZERO, "Passo grande aplica uma vez e restaura apresentação")
