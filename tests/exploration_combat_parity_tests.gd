extends SceneTree
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const Battle = preload("res://scripts/combat/battle_model.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Rules = preload("res://scripts/combat/affliction_rules.gd")
const Fixture = preload("res://tests/fixtures/current_combat.gd")
var checks = 0
var failures = 0
var raw: Dictionary
var data: Dictionary
var areas: Dictionary

func _initialize() -> void:
	raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	data = Bridge.exploration_definitions(raw)
	areas = preload("res://tests/fixtures/pre_expansion_catalog.gd").load_definitions()
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh():
	var session = Session.new(data.duplicate(true), areas["test_dungeon"], areas)
	session.world.toggle_door("door_01")
	return session

func begin(session, encounter: Dictionary) -> void:
	var position = Vector2(encounter["position"][0], encounter["position"][1])
	session.world.leader_position = position
	session.world.path.assign([position - Vector2(102, 0), position])
	session.world.path_length = 102
	expect(session.begin_encounter(encounter["id"]), "Encontro real inicia: " + encounter["id"])

func finish(battle) -> void:
	for step in range(240):
		if battle.action.is_empty():
			return
		battle.tick(1.0 / 120.0)
	expect(false, "Ação conclui")

func freeze_charging(battle) -> void:
	for actor in battle.actors():
		actor["ini_modifier"] = -actor["ini"]

func cast(battle, source: Dictionary, skill_id: String, target: Dictionary) -> void:
	if source["side"] == "ally":
		source["atb"] = 1.0
		expect(battle.select_actor(source["id"]) and battle.submit(skill_id, target["id"]), "Comando atual disponível: " + skill_id)
	else:
		battle._begin_action(source, battle.skill_for(source, skill_id), target["id"], Vector2.ZERO, "")
	finish(battle)

func run() -> void:
	var original = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	expect(raw == original, "Montagem não altera catálogo histórico nem entrada")
	expect(areas["test_world"]["encounters"].is_empty(), "Mapa-múndi continua sem monstros comuns")
	var lab = Battle.new(Bridge.extend_definitions(raw))
	lab.start(lab.default_preset_index())
	for encounter in areas["test_dungeon"]["encounters"]:
		var session = fresh()
		begin(session, encounter)
		var battle = session.battle
		expect(battle.uses_damage_v1() and battle.party.size() == 3, "Mesma V1 e três fichas aprovadas")
		expect(session.world.party_order == ["p1", "p2", "p3"], "Mesmos integrantes na fila e no combate")
		expect(battle.available_item_ids() == ["remedy_test"] and battle.inventory == {"remedy_test":3}, "Só o consumível atual; três por sessão")
		for index in range(battle.party.size()):
			var actor: Dictionary = battle.party[index]
			for key in ["damage_base", "damage_stats", "loadout", "skills", "max_hp", "max_mp", "ini", "reference_profile_id"]:
				expect(actor[key] == lab.party[index][key], "Aliado compartilha " + key)
			expect(battle.skill_for(actor, "all").is_empty() and battle.skill_for(actor, "precise").is_empty(), "Sem ações legadas concedidas")
		var before: Dictionary
		for candidate in raw["presets"]:
			if candidate["id"] == battle.preset["id"]:
				before = candidate
		expect(battle.preset["background"] == before["background"] and battle.preset["can_escape"] == before["can_escape"], "Cenário e fuga preservados")
		expect(battle.preset["allied_slots"] == before["allied_slots"].slice(0, 3), "Posições lógicas dos três aliados preservadas")
		expect(battle.enemies.size() == before["enemies"].size(), "Quantidade de inimigos preservada")
		for index in range(battle.enemies.size()):
			var actor: Dictionary = battle.enemies[index]
			var old: Dictionary = before["enemies"][index]
			var entry: Dictionary = battle.preset["enemies"][index]
			for key in ["id", "route", "spawn", "profile", "move_to_center_for_fullscreen_skill"]:
				expect(entry.get(key) == old.get(key), "Identidade espacial preservada: " + key)
			expect(actor["movement_profile"] == raw["enemy_types"][old["type"]]["movement_behavior"], "Movimento separado dos atributos")
			var counterpart: Dictionary = lab.enemies.filter(func(enemy): return enemy["reference_profile_id"] == actor["reference_profile_id"])[0]
			for key in ["damage_stats", "damage_base", "max_hp", "max_mp", "ini", "actions", "skills"]:
				expect(actor[key] == counterpart[key], "Monstro compartilha " + key)
			expect(not entry.has("actions") and battle.skill_for(actor, "all").is_empty(), "Sem ondas antigas substituindo repertório atual")
		freeze_charging(battle)
		# Resultados idênticos ao laboratório, com as mesmas entradas/semente.
		for skill_id in ["attack", "magic_skill", "poison", "slow", "confusion", "fear"]:
			battle.start(_preset_index(battle, encounter["battle_preset_id"]), false, 918)
			lab.start(lab.default_preset_index(), false, 918)
			freeze_charging(battle)
			freeze_charging(lab)
			var source_index = 0 if skill_id == "attack" else 2
			var target: Dictionary = battle.enemies[0]
			var other: Dictionary = lab.enemies.filter(func(enemy): return enemy["reference_profile_id"] == target["reference_profile_id"])[0]
			cast(battle, battle.party[source_index], skill_id, target)
			cast(lab, lab.party[source_index], skill_id, other)
			var actual: Dictionary = battle.damage_results.back()
			var expected: Dictionary = lab.damage_results.back()
			for key in ["damage", "evaded", "critical", "outcome", "affliction", "mp_before", "mp_after"]:
				expect(actual.get(key) == expected.get(key), "Paridade exata em encontro " + skill_id + ": " + key)
			expect(target["hp"] == other["hp"] and battle.party[source_index]["mp"] == lab.party[source_index]["mp"], "Impacto/custo idênticos")
	_test_persistence()
	print("PARIDADE EXPLORAÇÃO: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _preset_index(battle, id: String) -> int:
	for index in range(battle.data["presets"].size()):
		if battle.data["presets"][index]["id"] == id:
			return index
	return -1

func _test_persistence() -> void:
	var session = fresh()
	var encounter: Dictionary = areas["test_dungeon"]["encounters"][0]
	session.world.menu_open = true
	expect(session.world.choose_leader("p3"), "Liderança pelo menu com os três integrantes")
	session.battle.party[0]["hp"] = 25
	session.battle.party[1]["hp"] = 0
	session.battle.party[2]["mp"] = 17
	session.set_story_flag_once("parity_fixture")
	session.clock.set_time(22, 0)
	begin(session, encounter)
	var battle = session.battle
	freeze_charging(battle)
	var order = session.world.party_order.duplicate()
	var trail = session.world.path.duplicate()
	var entities = session.world.entities.duplicate(true)
	for entity in entities:
		if entity["id"] == encounter["id"]:
			entity["present"] = false # D153: resultado esperado após fuga.
	# Estado aplicado por comando real; só controlar os sorteios, sem mudar fichas.
	for key in ["evasion", "affliction"]:
		var stream = battle.damage_rngs[key]
		for seed_value in range(20000):
			stream.seed = seed_value
			var saved: int = stream.state
			var roll: float = stream.randf()
			if (key == "evasion" and roll > 0.99) or (key == "affliction" and roll < 0.01):
				stream.state = saved
				break
	cast(battle, battle.enemies[0], "poison", battle.party[0])
	expect(Rules.id(battle.party[0]) == "poison", "Veneno aplicado no encontro real")
	battle.tick(5.0)
	expect(battle.party[0]["hp"] == 23, "Tick usa 5% do mesmo HP máximo")
	battle.party[2]["atb"] = 1.0
	expect(battle.select_actor("p3") and battle.submit("item", "p1", Vector2.ZERO, "remedy_test"), "Remédio disponível na exploração")
	expect(battle.inventory["remedy_test"] == 2 and Rules.id(battle.party[0]) == "poison", "Débito na confirmação; cura no impacto")
	finish(battle)
	expect(Rules.id(battle.party[0]).is_empty() and battle.party[0]["hp"] == 23 and battle.party[2]["mp"] == 17, "Cura sem HP/MP")
	# Outra aflição precisa desaparecer na fuga e no reencontro.
	battle.party[0]["affliction"] = {"id":"slow", "source_id":"e1"}
	battle.data["settings"]["escape_chance"] = 1.0
	battle.party[2]["atb"] = 1.0
	expect(battle.select_actor("p3") and battle.submit("escape"), "Fuga com recursos gastos")
	finish(battle)
	expect(session.finish_encounter() and session.state == "exploration", "Retorno à área correta")
	expect(battle.party[0]["hp"] == 23 and battle.party[1]["hp"] == 0 and battle.party[2]["mp"] == 17 and battle.inventory["remedy_test"] == 2, "HP/MP, KO e estoque preservados")
	expect(session.world.party_order == order and session.world.path == trail and session.world.entities == entities, "Fila, trilha e estado da dungeon preservados")
	expect(session.clock.time_text() == "22:00" and session.story_flags["parity_fixture"], "Horário e flag preservados")
	expect(not session.begin_encounter(encounter["id"]), "Fuga remove encontro e impede reencontro")
	begin(session, areas["test_dungeon"]["encounters"][1])
	expect(battle.party[0]["hp"] == 23 and battle.inventory["remedy_test"] == 2 and battle.actors().all(func(actor): return Rules.id(actor).is_empty()), "Próximo encontro não restaura recursos nem reaplica aflição")
	expect(Fixture.win_by_basics(battle) and session.finish_encounter(), "Vitória real retorna")
	expect(not session.world.entity_by_id(encounter["id"])["present"] and battle.party[1]["hp"] == 0, "Vitória remove só encontro e não revive")
	begin(session, areas["test_dungeon"]["encounters"][2])
	expect(battle.inventory["remedy_test"] == 2 and battle.party[0]["hp"] == 23, "Próximo encontro não repõe estoque nem HP")
	for actor in battle.party:
		actor["hp"] = 0
		actor["affliction"] = {"id":"poison", "elapsed":0.0}
	battle._check_end()
	expect(session.finish_encounter() and session.state == "defeat" and battle.party.all(func(actor): return Rules.id(actor).is_empty()), "Derrota conserva Game Over e limpa aflições")
	var restarted = fresh()
	expect(restarted.battle.inventory["remedy_test"] == 3 and restarted.battle.party.all(func(actor): return actor["hp"] == actor["max_hp"] and actor["mp"] == actor["max_mp"]), "Somente nova sessão restaura condições iniciais")
