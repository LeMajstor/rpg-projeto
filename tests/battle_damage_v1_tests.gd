extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
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

func fresh(seed_value: int = 421):
	var battle = Battle.new(data.duplicate(true))
	battle.start(battle.default_preset_index(), false, seed_value)
	for enemy in battle.enemies:
		enemy["ini_modifier"] = -enemy["ini"]
	return battle

func finish(battle) -> void:
	for index in range(120):
		if battle.action.is_empty():
			return
		battle.tick(STEP)
	expect(false, "Ação deve terminar")

func ready(battle, id: String) -> void:
	battle.actor_by_id(id)["atb"] = 1.0
	expect(battle.select_actor(id), "Seleciona aliado pronto")

func rng_states(battle) -> Array:
	var states = []
	for key in battle.damage_rngs:
		states.append(battle.damage_rngs[key].state)
	return states

func play(mode_name: String, seed_value: int) -> Dictionary:
	var battle = fresh(seed_value)
	battle.mode = mode_name
	for enemy in battle.enemies:
		enemy["ini_modifier"] = 0.0
	for step in range(24000):
		if battle.outcome != "running":
			break
		if battle.action.is_empty():
			for member in battle.party:
				if battle.is_ready(member):
					battle.select_actor(member["id"])
					var id = "magic_skill" if member["id"] == "p3" and member["mp"] >= 7 else "attack"
					battle.submit(id, battle.living(battle.enemies)[0]["id"])
					break
		battle.tick(STEP)
	expect(battle.outcome in ["victory", "defeat"], "Encontro completo termina: " + mode_name)
	expect(battle.actors().all(func(a): return a["hp"] >= 0 and a["mp"] >= 0 and a["atb"] <= 1.0 and a["visual_offset"] == Vector2.ZERO), "Recursos/ATB/retornos válidos após encontro")
	return {"result": battle.outcome, "party": battle.party, "enemies": battle.enemies, "hits": battle.damage_results, "rng": rng_states(battle)}

func run() -> void:
	var battle = fresh()
	expect(battle.party.size() == 3 and battle.enemies.size() == 2, "Três fichas e dois monstros")
	expect(battle.party.map(func(a): return [a["max_hp"], a["max_mp"], a["ini"]]) == [[40,12,9.0],[36,14,11.0],[30,24,7.0]], "Recursos/INI das fichas congeladas")
	expect(battle.party.map(func(a): return a["damage_stats"]["physical_defense"]) == [55,35,18], "Composição física compartilhada")
	expect(battle.party[2]["damage_stats"]["magic_power"] == 40 and battle.party[2]["damage_stats"]["magic_defense"] == 40, "Bônus mágicos compartilhados")
	expect(battle.skill_for(battle.enemies[1], "attack")["delivery"] == "gesture", "Monstro 2 atira sem aproximação")
	expect(battle.skill_for(battle.party[1], "attack")["delivery"] == "gesture", "Arqueiro atira sem aproximação")
	expect(battle.skill_for(battle.party[0], "attack")["delivery"] == "melee", "Espada usa aproximação")
	for member in battle.party:
		ready(battle, member["id"])
		var before = rng_states(battle)
		expect(not battle.submit("poison", "e1") and not battle.submit("precise", "e1"), "Sem aflição/técnica antiga")
		if member["id"] != "p3":
			expect(not battle.submit("magic_skill", "e1"), "Primeiros dois não lançam magia")
		expect(not battle.submit("item", "p1", Vector2.ZERO, "hp"), "Itens antigos não recebem balanceamento implícito")
		battle.cancel_selection()
		expect(before == rng_states(battle), "Recusa/cancelamento não consomem RNG")
	# Paridade exata, incluindo rolagens: os mesmos fluxos do laboratório.
	for actor_id in ["p1", "p2", "p3", "e1", "e2"]:
		for magic in [false, true] if actor_id == "p3" else [false]:
			battle = fresh(733)
			var actor = battle.actor_by_id(actor_id)
			var target = battle.enemies[1] if actor["side"] == "ally" else battle.party[2]
			var skill = battle.skill_for(actor, "magic_skill" if magic else "attack")
			var config = Bridge.configuration(actor, target, skill)
			var expected: Dictionary
			# A validação completa exige composição da tela de danos; sample é o núcleo puro.
			var rolls = []
			for key in {"variance":0x5a4f3d2c,"critical":0x27d4eb2d,"evasion":0x6c8e9cf5,"affliction":0x3b9d72a1}:
				var stream = RandomNumberGenerator.new()
				stream.seed = 733 ^ {"variance":0x5a4f3d2c,"critical":0x27d4eb2d,"evasion":0x6c8e9cf5,"affliction":0x3b9d72a1}[key]
				rolls.append(stream.randf())
			expected = Bridge.Calculator.sample(config, rolls[0], rolls[1], rolls[2], rolls[3])
			var home: Vector2 = actor["logical_position"]
			var route: Dictionary = actor["route_state"].duplicate(true)
			if actor["side"] == "ally":
				ready(battle, actor_id)
				expect(battle.submit("magic_skill" if magic else "attack", target["id"]), "Ação autorizada inicia")
			else:
				battle._begin_action(actor, skill, target["id"], Vector2.ZERO, "")
			expect(target["hp"] == config["target"]["hp"], "Confirmação não causa dano antes do impacto")
			finish(battle)
			var actual: Dictionary = battle.damage_results.back()
			for key in expected:
				expect(actual[key] == expected[key], "Paridade numérica/recursos %s %s" % [actor_id, key])
			expect(actor["logical_position"] == home and actor["visual_offset"] == Vector2.ZERO and actor["route_state"] == route, "Retorno preserva âncora/rota/RNG de movimento")
	# Magia acumula custo/dano, não testa EVA nem crítico, mesmo com atributos extremos.
	battle = fresh()
	var mage = battle.party[2]
	var monster = battle.enemies[0]
	monster["hp"] = 1000
	monster["damage_stats"]["evasion_base"] = 100
	mage["damage_stats"]["critical_base"] = 100
	var previous_hp = 1000
	for index in range(3):
		ready(battle, "p3")
		expect(battle.submit("magic_skill", "e1"), "Até três usos com MP24")
		expect(mage["mp"] == 24 - (index + 1) * 7, "Débito único na confirmação")
		finish(battle)
		var hit: Dictionary = battle.damage_results.back()
		expect(hit["damage"] >= 32 and hit["damage"] <= 39 and not hit["evaded"] and not hit["critical"], "Magia32..39 ignora EVA/crítico")
		expect(monster["hp"] == previous_hp - hit["damage"], "HP acumula entre ações")
		previous_hp = monster["hp"]
	ready(battle, "p3")
	var before = rng_states(battle)
	expect(not battle.submit("magic_skill", "e1") and mage["mp"] == 3 and mage["atb"] == 1.0 and rng_states(battle) == before, "MP insuficiente preserva ação, recursos e RNG")
	battle.cancel_selection()
	# Trocas válidas são pendentes e recalculadas do atributo natural uma única vez.
	var active: Dictionary = mage["damage_stats"].duplicate(true)
	expect(not battle.set_pending_equipment("p1", "weapon", "staff_runic"), "Exclusividade da arma")
	expect(battle.set_pending_equipment("p3", "weapon", "staff_runic"), "Cajado superior selecionável")
	expect(mage["damage_stats"] == active, "Preparação não altera batalha em curso")
	battle.start(battle.default_preset_index(), true)
	expect(battle.party[2]["mp"] == 3 and battle.party[2]["damage_stats"]["magic_power"] == 40, "Próxima luta preserva MP e equipamento ativo")
	battle.start(battle.default_preset_index(), false)
	expect(battle.party[2]["mp"] == 24 and battle.party[2]["damage_stats"]["magic_power"] == 95, "Novo teste aplica estágio sem empilhar bônus")
	battle.start(battle.default_preset_index(), false)
	expect(battle.party[2]["damage_stats"]["magic_power"] == 95, "Reinício não empilha")
	# ATB usa INI efetiva e mantém a saturação em 100%.
	battle = fresh()
	battle.tick(1.0)
	for index in range(3):
		expect(is_equal_approx(battle.party[index]["atb"], [9,11,7][index] * 0.018 * 0.6), "Ritmo ATB por INI")
	var snapshot: Dictionary = battle.enemies[0]["route_state"].duplicate(true)
	ready(battle, "p1")
	battle.tick(2.0)
	expect(battle.enemies[0]["route_state"] == snapshot and battle.party[0]["atb"] == 1.0, "Wait preserva rota e saturação")
	battle.cancel_selection()
	battle.tick(0.1)
	expect(battle.enemies[0]["route_state"] != snapshot, "Rota retoma ao cancelar")
	battle = fresh()
	battle.enemies[0]["damage_stats"]["evasion_base"] = 100
	ready(battle, "p1")
	before = rng_states(battle)
	battle.submit("attack", "e1")
	finish(battle)
	expect(battle.enemies[0]["hp"] == 45 and battle.party[0]["atb"] == 0.0 and battle.damage_results.back()["evaded"] and rng_states(battle) != before, "Esquiva física consome ação e sorteios, sem dano mínimo")
	# KO elimina prontidão e seleção; vitória/derrota pertencem ao ciclo da batalha.
	battle = fresh()
	ready(battle, "p3")
	battle.party[2]["hp"] = 1
	battle.mode = "Active"
	battle._begin_action(battle.enemies[1], battle.skill_for(battle.enemies[1], "attack"), "p3", Vector2.ZERO, "")
	finish(battle)
	expect(battle.party[2]["hp"] == 0 and battle.party[2]["atb"] == 0 and battle.selected_id.is_empty(), "KO cancela seleção e ATB")
	for member in battle.party:
		member["hp"] = 0
	battle._check_end()
	expect(battle.outcome == "defeat" and not battle.start(battle.default_preset_index(), true), "Derrota impede próxima luta")
	battle = fresh()
	battle.party[2]["mp"] = 3
	for enemy in battle.enemies:
		enemy["hp"] = 0
	battle._check_end()
	expect(battle.outcome == "victory" and battle.party[2]["mp"] == 3, "Vitória não cura")
	expect(not battle.start(0, true), "Trocar referência não mistura equipes ao preservar recursos")
	battle.start(0, false)
	expect(battle.party.size() == 4 and not battle.uses_damage_v1(), "Cenário anterior preservado")
	var original = Battle.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	original.start(original.default_preset_index())
	expect(original.preset["id"] == "lab_seeded" and original.party.size() == 4, "Exploração/dados antigos não são migrados implicitamente")
	for mode_name in ["Wait", "Active"]:
		for seed_value in [421, 733, 918]:
			expect(play(mode_name, seed_value) == play(mode_name, seed_value), "Mesmas entradas/semente reproduzem batalha completa")
	print("BATALHA DANOS V1: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
