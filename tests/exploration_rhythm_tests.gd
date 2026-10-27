extends SceneTree
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Session = preload("res://scripts/exploration/exploration_session.gd")
const Route = preload("res://scripts/combat/route_motion.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var definitions: Dictionary
var original: Dictionary
var checks = 0
var failures = 0
var capture_directory = ""
var old_ids = ["lab_a", "lab_b", "lab_motion", "lab_fullscreen"]
var new_ids = ["exploration_seeded_open", "exploration_seeded_corners", "exploration_seeded_sides", "exploration_seeded_fullscreen"]

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	original = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre_rhythm_combat.json"))
	definitions = Catalog.load_definitions()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-captures="):
			capture_directory = arg.trim_prefix("--visual-captures=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func preset(id: String) -> Dictionary:
	for entry in data["presets"]:
		if entry["id"] == id:
			return entry
	return {}

func place(session, position: Vector2) -> void:
	session.world.leader_position = position
	session.world.path.assign([position - Vector2(102, 0), position])
	session.world.path_length = 102

func travel(session, id: String) -> void:
	var portal: Dictionary = session.world.entity_by_id(id)
	place(session, portal["position"] + Vector2(0, 40))
	expect(session.begin_transition(id), "Acesso disponível: " + id)
	session.tick(session.transition_duration)
	expect(session.state == "exploration", "Transição termina: " + id)

func fresh():
	var session = Session.new(data.duplicate(true), definitions["lab_exterior"], definitions)
	travel(session, "town_exit")
	travel(session, "dungeon_entrance")
	session.world.toggle_door("door_01")
	return session

func finish(battle) -> void:
	var guard = 0
	while not battle.action.is_empty() and guard < 240:
		battle.tick(STEP)
		guard += 1
	expect(guard < 240, "Ação termina sem travar")

func capture(lab, name: String) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	lab._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura: " + name)
	expect(lab.debug_window.get_texture().get_image().save_png(capture_directory.path_join(name + "-debug.png")) == OK, "Captura F3: " + name)

func _run() -> void:
	_test_catalog_and_preservation()
	await _test_ui_defaults()
	for encounter in definitions["test_dungeon"]["encounters"]:
		await _test_encounter(encounter)
	print("RITMOS/EXPLORAÇÃO: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_catalog_and_preservation() -> void:
	var total = 0
	for area in definitions.values():
		for encounter in area["encounters"]:
			total += 1
			expect(encounter["battle_preset_id"] in new_ids, "Todo encontro jogável usa preset atual")
			expect(encounter["battle_preset_id"] not in data["legacy_preset_ids"], "Nenhum encontro referencia legado")
	expect(total == 6, "Seis encontros mantidos no catálogo real")
	for index in range(4):
		var current = preset(new_ids[index])
		var before: Dictionary = original["presets"][index]
		for key in ["background", "can_escape"]:
			expect(current[key] == before[key], "Formação/cenário/fuga preservados: " + new_ids[index])
		expect(current["enemies"].size() == before["enemies"].size(), "Quantidade de participantes preservada")
		for actor_index in range(current["enemies"].size()):
			var enemy: Dictionary = current["enemies"][actor_index]
			var old: Dictionary = before["enemies"][actor_index]
			for key in ["id", "profile", "spawn", "actions", "move_to_center_for_fullscreen_skill"]:
				expect(enemy.get(key) == old.get(key), "Identidade, alvo, início e apresentação preservados")
			for key in ["max_hp", "max_mp", "attack", "actions"]:
				expect(data["enemy_types"][enemy["type"]][key] == original["enemy_types"][old["type"]][key], "Atributos/ações do tipo preservados")

func _test_ui_defaults() -> void:
	var lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	expect(lab.model.preset["id"] == "lab_seeded", "Laboratório abre no comportamento por semente")
	expect(lab.definitions["presets"][lab.preset_picker.selected]["id"] == "lab_seeded", "Seletor corresponde à batalha inicial")
	for index in range(data["presets"].size()):
		var id: String = data["presets"][index]["id"]
		expect(lab.preset_picker.get_item_text(index).begins_with("Legado · ") == (id in data["legacy_preset_ids"]), "Modelos anteriores identificados como legados")
	lab.queue_free()
	await process_frame

func _test_encounter(definition: Dictionary) -> void:
	var session = fresh()
	var entity = session.world.entity_by_id(definition["id"])
	place(session, entity["position"])
	var order = session.world.party_order.duplicate()
	var formation = session.world.formation_positions()
	var map_position: Vector2 = entity["position"]
	var map_route: Dictionary = entity["route_state"].duplicate(true)
	session.battle.party[0]["hp"] = 91
	session.battle.party[0]["mp"] = 30
	var shared = session.battle
	expect(session.interact() == "battle" and session.battle == shared, "Encontro usa o combate compartilhado: " + definition["id"])
	expect(shared.preset["id"] == definition["battle_preset_id"], "Preset correto sem substituição aleatória")
	var initial: Array = []
	for enemy in shared.enemies:
		initial.append(enemy["logical_position"])
		var entry: Dictionary = shared.preset["enemies"][initial.size() - 1]
		expect(enemy["ini"] == data["enemy_types"][entry["type"]]["ini"], "Encontro carrega INI atual da ficha do tipo")
		var state: Dictionary = enemy["route_state"]
		if state["speed"] > 0:
			expect(state.has("behavior") and not state["behavior"]["phases"].is_empty(), "Todo inimigo móvel possui o ritmo atual")
			expect(enemy["movement_profile"] in ["heavy", "agile", "flying"], "Tipo usa perfil atual")
			var nearest = INF
			for point in state["points"]:
				expect(point.x > 250 and point.x < 890 and point.y > 40 and point.y < 400, "Percurso cabe no campo")
				for member in shared.party:
					nearest = minf(nearest, point.distance_to(member["logical_position"]))
			expect(nearest > 52, "Rota evita sobreposição dos aliados em repouso")
			if state["kind"] == "air":
				expect(nearest < 120, "Voo amplo permite aproximação do grupo")
		else:
			expect(state["points"].is_empty(), "Estáticos mantêm repouso fixo")
		if enemy["id"] == "e2" and shared.preset["id"] == "exploration_seeded_fullscreen":
			expect(not shared.fullscreen_center_enabled(enemy), "Estático de tela inteira permanece no lugar")
		if enemy["id"] == "e3" and shared.preset["id"] == "exploration_seeded_fullscreen":
			expect(shared.fullscreen_center_enabled(enemy), "Exceção estática de tela inteira preservada")
	# Wait e Active usam o mesmo estado novo na integração real.
	shared.party[0]["atb"] = 1.0
	shared.select_actor("p1")
	var wait_snapshot: Dictionary = shared.enemies[0]["route_state"].duplicate(true)
	session.tick(0.5)
	shared.tick(0.5)
	expect(shared.enemies[0]["route_state"] == wait_snapshot, "Wait pausa o novo ritmo integrado")
	shared.mode = "Active"
	shared.tick(0.5)
	expect(shared.enemies[0]["route_state"] != wait_snapshot, "Active avança o novo ritmo integrado")
	shared.cancel_selection()
	# ATB real agenda a ação inimiga com o mesmo perfil de escolha de alvos.
	shared.enemies[0]["atb"] = 1.0
	shared.tick(STEP)
	expect(shared.action.get("actor_id") == "e1" and shared.decisions.size() == 1, "IA existente executa ação pelo ATB")
	var route_snapshot: Dictionary = shared.enemies[0]["route_state"].duplicate(true)
	var origin: Vector2 = shared.enemies[0]["logical_position"]
	finish(shared)
	expect(shared.enemies[0]["route_state"] == route_snapshot and shared.enemies[0]["logical_position"] == origin and shared.enemies[0]["visual_offset"] == Vector2.ZERO, "Ação integrada retorna à rota exata")
	var expected = route_snapshot.duplicate(true)
	Route.advance(expected, STEP)
	shared.tick(STEP)
	expect(shared.enemies[0]["route_state"] == expected, "Retoma ritmo exatamente do snapshot")
	# A UI integrada recebe a mesma instância; imagens opcionais dos dois tipos de teste.
	var lab = load("res://scenes/combat_lab.tscn").instantiate()
	lab.configure_encounter(shared)
	root.add_child(lab)
	lab.set_process(false)
	expect(lab.model == shared and lab.encounter_mode and not lab.preset_picker.visible, "UI integrada usa o preset do encontro sem seletor manual")
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect("comportamento" in lab.debug_text.text, "F3 do encontro exibe o ritmo atual")
	if definition["id"] in ["test_map_enemy_01", "test_map_enemy_04"]:
		await capture(lab, definition["id"])
	lab.queue_free()
	await process_frame
	expect(entity["position"] == map_position and entity["route_state"] == map_route, "Movimento no mapa permanece pausado e inalterado durante a batalha")
	# Fuga mantém o encontro e recursos; M2 continua bloqueando sem consumir ação.
	for enemy in shared.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	shared.data["settings"]["escape_chance"] = 1.0
	shared.debug_ready_allies()
	shared.select_actor("p1")
	var resources: Array = []
	for member in shared.party:
		resources.append([member["hp"], member["mp"]])
	if shared.preset["can_escape"]:
		expect(shared.submit("escape"), "Fuga disponível preservada")
		finish(shared)
		expect(session.finish_encounter() and entity["present"], "Fuga retorna à dungeon mantendo encontro")
		for index in range(4):
			expect([shared.party[index]["hp"], shared.party[index]["mp"]] == resources[index], "HP/MP persistem na fuga")
		expect(session.world.party_order == order and session.world.formation_positions() == formation, "Retorno preserva liderança, fila e coordenadas do mapa")
		expect(session.begin_encounter(entity["id"]), "Reencontro possível após fuga")
		for index in range(shared.enemies.size()):
			expect(shared.enemies[index]["logical_position"] == initial[index], "Reencontro reproduz formação inicial")
	else:
		expect(not shared.submit("escape") and shared.party[0]["atb"] == 1.0, "M2 bloqueia fuga sem consumir ação")
		shared.cancel_selection()
	# Vitória real continua removendo apenas este encontro e mantendo recursos.
	for enemy in shared.enemies:
		enemy["hp"] = 1
		enemy["ini_modifier"] = -float(enemy["ini"])
	var hp_before: int = shared.party[0]["hp"]
	var mp_before: int = shared.party[0]["mp"]
	shared.debug_ready_allies()
	shared.select_actor("p1")
	expect(shared.submit("all"), "Onda existente continua válida")
	finish(shared)
	expect(shared.outcome == "victory" and session.finish_encounter() and not entity["present"], "Vitória retorna e remove somente o encontro vencido")
	expect(shared.party[0]["hp"] == hp_before and shared.party[0]["mp"] == mp_before - 10, "HP/MP persistem na vitória")
