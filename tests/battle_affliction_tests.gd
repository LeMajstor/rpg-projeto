extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const DamageLab = preload("res://scripts/damage/damage_lab_model.gd")
const Rules = preload("res://scripts/combat/affliction_rules.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var checks = 0
var failures = 0

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
	for actor in battle.actors():
		actor["ini_modifier"] = -actor["ini"] # Fixture: nenhum agente agenda ações espontâneas.
	return battle

func set_roll(stream, low: float, high: float) -> void:
	for seed_value in range(1, 20000):
		stream.seed = seed_value
		var before: int = stream.state
		var roll: float = stream.randf()
		if roll >= low and roll < high:
			stream.state = before
			return
	expect(false, "Semente de controle encontrada")

func finish(battle) -> void:
	for index in range(120):
		if battle.action.is_empty():
			return
		battle.tick(STEP)
	expect(false, "Ação conclui aproximação/impacto/retorno")

func cast(battle, source_id: String, skill_id: String, target_id: String) -> void:
	var actor = battle.actor_by_id(source_id)
	var skill = battle.skill_for(actor, skill_id)
	if skill_id != "escape":
		expect(not skill.is_empty(), "Repertório oferece " + skill_id)
	if actor["side"] == "ally":
		actor["atb"] = 1.0
		expect(battle.select_actor(source_id) and battle.submit(skill_id, target_id), "Comando válido confirma " + skill_id)
	else:
		expect(actor["mp"] >= skill["mp_cost"], "Inimigo possui MP para a fixture")
		battle._begin_action(actor, skill, target_id, Vector2.ZERO, "")
	finish(battle)

func apply(battle, id: String, target_id: String = "p1", source_id: String = "e1") -> void:
	set_roll(battle.damage_rngs["affliction"], 0.0, 0.01)
	set_roll(battle.damage_rngs["evasion"], 0.99, 1.0)
	cast(battle, source_id, id, target_id)

func test_reference_parity() -> void:
	var lab = DamageLab.new(Bridge.damage_data())
	for entry in Bridge.Reference.entries():
		expect(lab.apply_reference(entry["id"]).is_empty(), "Laboratório carrega referência comum " + entry["name"])
		var definition = Bridge.actor_definition(entry, "test")
		var effective: Dictionary
		if entry["side"] == "ally":
			effective = lab.configuration()[lab.ally_role()]
		else:
			effective = lab.enemy()
		for stat in Bridge.Calculator.STATS:
			expect(effective[stat] == definition["damage_stats"][stat], "Paridade dos 13 atributos: " + stat)
	# Todos os estágios, nas três famílias, com o mesmo resolvedor da ferramenta.
	for entry in Bridge.Reference.entries("ally"):
		for weapon in Bridge.damage_data()["weapons"]:
			if not Bridge.Equipment.can_equip(entry["actor"], weapon, "weapon"):
				continue
			lab.apply_reference(entry["id"])
			lab.choose_equipment("weapon", weapon["id"])
			var definition = Bridge.actor_definition(entry, "p")
			var equipped = Bridge.equip_definition(definition, {"weapon": weapon, "armor": definition["loadout"]["armor"]})
			expect(lab.configuration()[lab.ally_role()] == equipped["damage_stats"], "Seis armas por família preservam composição completa")
		for armor in Bridge.damage_data()["armors"]:
			if not Bridge.Equipment.can_equip(entry["actor"], armor, "armor"):
				continue
			lab.apply_reference(entry["id"])
			lab.choose_equipment("armor", armor["id"])
			var definition = Bridge.actor_definition(entry, "p")
			var equipped = Bridge.equip_definition(definition, {"weapon": definition["loadout"]["weapon"], "armor": armor})
			expect(lab.configuration()[lab.ally_role()] == equipped["damage_stats"], "Seis vestimentas por família preservam composição completa")
	# Esquiva/resistência/aplicação são amostras exatas da calculadora.
	for id in ["poison", "slow", "confusion", "fear"]:
		for seed_value in [1, 421, 733, 918, 1234]:
			var battle = fresh(seed_value)
			lab.apply_reference("reference_ally_3")
			lab.apply_reference("reference_monster_1")
			lab.choose_action(id)
			lab.set_seed(seed_value)
			lab.restart_sequence()
			var expected: Dictionary = lab.run(1)["samples"][0]
			cast(battle, "p3", id, "e1")
			var actual: Dictionary = battle.damage_results.back()
			for key in expected:
				if key != "index":
					expect(actual[key] == expected[key], "Paridade de aflição %s: %s" % [id, key])
			expect((Rules.id(battle.enemies[0]) == id) == expected["affliction"]["applied"], "Estado temporal segue resultado compartilhado")

func test_poison() -> void:
	var intervals = [24.0, 12.0, 7.5, 5.0, 3.75, 3.0, 2.4, 2.0]
	for level in range(1, 9):
		var battle = fresh()
		battle.battle_speed = level
		apply(battle, "poison")
		var actor = battle.party[0]
		expect(actor["hp"] == 40 and actor["affliction"]["elapsed"] == 0, "Aplicação não causa tick imediato nem avança durante animação")
		battle.tick(intervals[level - 1] - STEP)
		expect(actor["hp"] == 40, "Antes do intervalo não há tick")
		battle.tick(STEP)
		expect(actor["hp"] == 38, "5%/tick com intervalo normalizado no nível " + str(level))
	var battle = fresh()
	apply(battle, "poison")
	var actor = battle.party[0]
	battle.tick(2.0)
	var elapsed: float = actor["affliction"]["elapsed"]
	battle.party[1]["atb"] = 1.0
	battle.select_actor("p2")
	battle.tick(10.0)
	expect(actor["affliction"]["elapsed"] == elapsed and actor["hp"] == 40, "Wait congela contagem, sem ticks acumulados")
	battle.cancel_selection()
	battle.battle_speed = 8
	battle.tick(1.2)
	expect(actor["hp"] == 38, "Trocar Battle Speed preserva progresso parcial normalizado")
	battle = fresh()
	apply(battle, "poison")
	battle.data["settings"]["action_duration"] = 5.0
	battle.party[1]["atb"] = 1.0
	battle.select_actor("p2")
	battle.submit("attack", "e2")
	for index in range(610):
		if battle.action.is_empty():
			break
		battle.tick(STEP)
	expect(battle.party[0]["hp"] == 40 and battle.party[0]["affliction"]["elapsed"] == 0, "Ação de 5s não avança Veneno")
	for max_hp in [1, 10, 30, 45, 999]:
		var fixture = {"max_hp": max_hp}
		expect(Rules.poison_damage(fixture, data["affliction_rules"]["poison"]) == {1:1,10:1,30:2,45:2,999:50}[max_hp], "Arredondamento/min1 por tick")
	battle = fresh()
	apply(battle, "poison")
	battle.party[0]["hp"] = 1
	battle.tick(5.0)
	expect(battle.party[0]["hp"] == 0 and battle.party[0]["atb"] == 0, "Veneno pode incapacitar")
	battle.debug_restore()
	expect(battle.party[0]["hp"] == 40 and Rules.id(battle.party[0]).is_empty(), "Reviver pela depuração também remove a aflição")

func test_slow_and_cure() -> void:
	var battle = fresh()
	battle.party[1]["ini_modifier"] = 2
	battle.party[1]["atb"] = 0.4
	var natural: Dictionary = battle.party[1]["damage_base"].duplicate(true)
	apply(battle, "slow", "p2")
	expect(battle.effective_ini(battle.party[1]) == 8 and battle.party[1]["atb"] == 0.4, "INI natural11/2 arredonda6 e soma modificador2 sem alterar carga")
	var basic = battle.skill_for(battle.enemies[1], "attack")
	var config = Bridge.configuration(battle.enemies[1], battle.party[1], basic)
	expect(config["target"]["evasion_base"] == 5 and battle.party[1]["damage_base"] == natural, "Lentidão preserva EVA do couro e ficha natural")
	battle.party[0]["atb"] = 1.0
	battle.select_actor("p1")
	expect(battle.submit("item", "p2", Vector2.ZERO, "remedy_test"), "Cura real de Lentidão pelo comando Itens")
	finish(battle)
	expect(Rules.id(battle.party[1]).is_empty() and battle.effective_ini(battle.party[1]) == 13, "Cura restaura contribuição natural sem empilhar bônus")
	expect(battle.inventory["remedy_test"] == 2 and battle.party[1]["atb"] == 0.4, "Cura não concede carga ou estoque")
	config = Bridge.configuration(battle.enemies[1], battle.party[1], basic)
	expect(config["target"]["evasion_base"] == 12, "EVA natural e couro voltam após cura")
	# A parcela de equipamento sobrevive mesmo se a soma anterior atingia o teto.
	var actor = battle.party[1]
	actor["damage_base"]["evasion_base"] = 99
	actor["damage_stats"]["evasion_base"] = 100
	actor["affliction"] = {"id":"slow"}
	config = Bridge.configuration(battle.enemies[1], actor, basic)
	expect(config["target"]["evasion_base"] == 5, "EVA do equipamento não se perde por subtrair natural de total saturado")

func test_exclusivity() -> void:
	var battle = fresh()
	apply(battle, "poison", "e1", "p3")
	battle.tick(2.0)
	var before: Dictionary = battle.enemies[0]["affliction"].duplicate(true)
	for id in ["poison", "slow", "confusion", "fear"]:
		var mp: int = battle.party[2]["mp"]
		cast(battle, "p3", id, "e1")
		expect(battle.enemies[0]["affliction"] == before and battle.party[2]["mp"] == mp - 4, "Tentativa mantém aflição/contador/origem e gasta MP")
		expect(battle.damage_results.back()["outcome"] == "already_afflicted", "Registro distingue tentativa sem efeito")

func test_fear() -> void:
	var battle = fresh()
	battle.party[0]["atb"] = 0.4
	apply(battle, "fear")
	battle.tick(2)
	expect(battle.party[0]["atb"] == 0.4 and not battle.select_actor("p1"), "Medo congela ATB e bloqueia comandos")
	battle.enemies[0]["hp"] = 0
	battle.tick(STEP)
	expect(Rules.id(battle.party[0]).is_empty() and battle.party[0]["atb"] == 0.4, "Derrotar origem remove Medo sem conceder carga")
	battle.enemies[0]["hp"] = 45
	battle.tick(STEP)
	expect(Rules.id(battle.party[0]).is_empty(), "Reviver origem não restaura Medo")
	battle = fresh()
	apply(battle, "fear", "e1", "p3")
	var enemy = battle.enemies[0]
	var route: Dictionary = enemy["route_state"].duplicate(true)
	battle.tick(2)
	expect(enemy["route_state"] == route, "Medo pausa rota inimiga completa")
	battle.party[2]["hp"] = 0
	var expected = route.duplicate(true)
	Route.advance(expected, STEP)
	battle.tick(STEP)
	expect(Rules.id(enemy).is_empty() and enemy["route_state"] == expected, "Rota retoma exatamente do snapshot após remoção")
	for intelligence_values in [[20,20], [20,25]]:
		battle = fresh()
		apply(battle, "fear", "p1")
		apply(battle, "fear", "p2")
		battle.enemies[0]["mp"] = 4
		cast(battle, "e1", "fear", "p3")
		expect(Rules.id(battle.party[2]).is_empty() and battle.enemies[0]["mp"] == 0 and battle.damage_results.back()["outcome"] == "protected", "Último livre protegido, tentativa consome ação/MP")
		battle.party[0]["damage_stats"]["intelligence"] = intelligence_values[0]
		battle.party[1]["damage_stats"]["intelligence"] = intelligence_values[1]
		battle.party[2]["hp"] = 0
		battle.tick(STEP)
		var chosen = 0 if intelligence_values[0] == intelligence_values[1] else 1
		expect(Rules.id(battle.party[chosen]).is_empty() and Rules.id(battle.party[1 - chosen]) == "fear", "Proteção dinâmica escolhe maior INT e desempata pela ordem")
		battle.party[chosen]["hp"] = 0
		battle.tick(STEP)
		expect(Rules.id(battle.party[1 - chosen]).is_empty(), "Único sobrevivente fica livre de Medo")
	# Recuperação: INT atual contra MAG registrada, não a MAG alterada da origem.
	battle = fresh()
	apply(battle, "fear")
	battle.enemies[0]["damage_stats"]["magic_power"] = 999
	battle.party[0]["damage_stats"]["intelligence"] = 40
	expect(is_equal_approx(Rules.recovery_chance(battle.party[0]), 40.0 / 65.0), "Chance lê INT atual e MAG25 registrada")
	set_roll(battle.recovery_rng, 0, 0.01)
	cast(battle, "e2", "attack", "p1")
	expect(Rules.id(battle.party[0]).is_empty() and battle.party[0]["hp"] < 40, "Dano físico remove Medo ao passar no teste")
	battle = fresh()
	apply(battle, "fear", "e1", "p3")
	set_roll(battle.recovery_rng, 0, 0.01)
	cast(battle, "p3", "magic_skill", "e1")
	expect(Rules.id(battle.enemies[0]).is_empty() and battle.enemies[0]["hp"] > 0, "Dano mágico direto também permite recuperar")
	battle = fresh()
	apply(battle, "fear")
	battle.party[0]["damage_stats"]["evasion_base"] = 100
	var recovery_before: int = battle.recovery_rng.state
	cast(battle, "e2", "attack", "p1")
	expect(Rules.id(battle.party[0]) == "fear" and battle.recovery_rng.state == recovery_before, "Esquiva não faz teste de recuperação")
	battle.party[0]["damage_stats"]["evasion_base"] = 0
	battle.enemies[1]["damage_stats"]["critical_base"] = 100
	set_roll(battle.recovery_rng, 0.74, 0.76)
	var expected_rng = RandomNumberGenerator.new()
	expected_rng.state = battle.recovery_rng.state
	expected_rng.randf()
	cast(battle, "e2", "attack", "p1")
	expect(battle.damage_results.back()["critical"] and Rules.id(battle.party[0]) == "fear" and battle.recovery_rng.state == expected_rng.state, "Crítico faz somente um teste, sem aumentar chance")
	recovery_before = battle.recovery_rng.state
	battle.party[0]["damage_stats"]["evasion_base"] = 0
	battle.party[0]["hp"] = 1
	cast(battle, "e2", "attack", "p1")
	expect(battle.party[0]["hp"] == 0 and battle.recovery_rng.state == recovery_before, "Golpe letal não faz teste de recuperação")
	# Reviver é exercitado com ação fixture; não cria item/magia jogável.
	battle._begin_action(battle.party[1], {"name":"Reviver fixture", "target":"single", "effect":"revive", "amount":1, "mp_cost":0}, "p1", Vector2.ZERO, "")
	finish(battle)
	expect(battle.party[0]["hp"] == 1 and Rules.id(battle.party[0]).is_empty(), "Reviver remove a aflição")
	# Dois aplicadores: derrotar um não cura o Medo do outro.
	battle = fresh()
	apply(battle, "fear", "p1", "e1")
	apply(battle, "fear", "e2", "p3")
	battle.enemies[0]["hp"] = 0
	battle.tick(STEP)
	expect(Rules.id(battle.party[0]).is_empty() and Rules.id(battle.enemies[1]) == "fear", "Remoção por derrota respeita identidade da origem")

func confusion_sequence(seed_value: int) -> Array:
	var battle = fresh(seed_value)
	apply(battle, "confusion")
	for actor in battle.actors():
		actor["hp"] = 500 # Fixture de sobrevivência; não altera catálogo.
	var sequence = []
	var mp: int = battle.party[0]["mp"]
	for index in range(32):
		battle.party[0]["atb"] = 1.0
		battle.tick(STEP)
		expect(not battle.action.is_empty() and battle.action["actor_id"] == "p1", "Confusão age automaticamente")
		sequence.append(battle.action["target_id"])
		expect(battle.action["target_id"] != "p1" and battle.action["skill"]["category"] == "basic", "Sem autoalvo ou habilidades")
		finish(battle)
		expect(battle.party[0]["mp"] == mp and Rules.id(battle.party[0]) == "confusion", "Sem MP; dano/execução não removem Confusão")
	expect(sequence.has("p2") and sequence.has("p3") and sequence.has("e1") and sequence.has("e2"), "Sorteio alcança aliados e inimigos")
	return sequence

func test_cleanup() -> void:
	for result in ["victory", "defeat", "escaped"]:
		var battle = fresh()
		apply(battle, "poison")
		if result == "escaped":
			battle.data["settings"]["escape_chance"] = 1
			cast(battle, "p2", "escape", "")
		elif result == "victory":
			for actor in battle.enemies:
				actor["hp"] = 0
			battle._check_end()
		else:
			for actor in battle.party:
				actor["hp"] = 0
			battle._check_end()
		expect(battle.outcome == result and battle.actors().all(func(actor): return Rules.id(actor).is_empty()), "Fim da batalha remove aflições: " + result)

func run() -> void:
	test_reference_parity()
	test_poison()
	test_slow_and_cure()
	test_exclusivity()
	test_fear()
	expect(confusion_sequence(733) == confusion_sequence(733), "Confusão reproduz sequência por semente")
	test_cleanup()
	print("INTEGRAÇÃO AFLIÇÕES: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
