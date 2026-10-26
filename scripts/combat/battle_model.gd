extends RefCounted
## Simulação sem dependência da cena/UI. tick() recebe tempo de simulação.
const Route = preload("res://scripts/combat/route_motion.gd")
const Policy = preload("res://scripts/combat/target_policy.gd")
const AttackMotion = preload("res://scripts/combat/attack_motion.gd")
const FullscreenMotion = preload("res://scripts/combat/fullscreen_motion.gd")
const BATTLEFIELD_SIZE = Vector2(920, 440)
const CENTER_SETTING = "move_to_center_for_fullscreen_skill"

var data: Dictionary
var party: Array = []
var enemies: Array = []
var inventory: Dictionary = {}
var preset: Dictionary = {}
var rng = RandomNumberGenerator.new()
var mode = "Wait"
var outcome = "idle"
var selected_id = ""
var action: Dictionary = {}
var events: Array[String] = []
var decisions: Array[Dictionary] = []
var simulation_time = 0.0
var completed_actions = 0
var simulation_seed = 421

func _init(definitions: Dictionary) -> void:
	data = definitions

func default_preset_index() -> int:
	for index in range(data["presets"].size()):
		if data["presets"][index]["id"] == data.get("default_preset_id", ""):
			return index
	return 0

func start(preset_index: int, preserve_party: bool = false, random_seed: int = 421) -> bool:
	if preserve_party and (party.is_empty() or living(party).is_empty()):
		return false
	preset = data["presets"][clampi(preset_index, 0, data["presets"].size() - 1)]
	rng.seed = random_seed
	simulation_seed = random_seed
	if not preserve_party:
		party.clear()
		for definition in data["party"]:
			party.append(_make_actor(definition, "ally", definition["id"]))
		inventory.clear()
		for id in data["items"]:
			inventory[id] = int(data["items"][id]["quantity"])
	for index in range(party.size()):
		var member = party[index]
		member["logical_position"] = _vector(preset["allied_slots"][index])
		member["home_position"] = member["logical_position"]
		member["visual_offset"] = Vector2.ZERO
		member["atb"] = 0.0
		member["last_attacker"] = ""
		member["last_target"] = ""
	enemies.clear()
	for entry in preset["enemies"]:
		var enemy = _make_actor(data["enemy_types"][entry["type"]], "enemy", entry["id"])
		enemy["name"] = "%s · %s" % [entry["id"].to_upper(), enemy["name"]]
		enemy["short_name"] = enemy["name"]
		enemy["profile"] = entry["profile"]
		enemy["logical_position"] = _vector(entry["spawn"])
		enemy["home_position"] = enemy["logical_position"]
		var movement = _movement_settings(data["enemy_types"][entry["type"]], entry)
		if movement["motion"].has("behavior"):
			movement["motion"]["seed"] = random_seed ^ int((str(entry["id"]) + ":movement").hash())
		enemy["movement_profile"] = movement["profile"]
		enemy["facing_policy"] = entry.get("facing_policy", enemy.get("facing_policy", "legacy"))
		enemy["route_state"] = Route.create(entry["route"], movement["speed"], movement["motion"])
		enemy["logical_position"] = Route.position_at(enemy["route_state"], enemy["logical_position"])
		if entry.has(CENTER_SETTING):
			enemy[CENTER_SETTING] = bool(entry[CENTER_SETTING])
		elif not data["enemy_types"][entry["type"]].has(CENTER_SETTING):
			enemy[CENTER_SETTING] = enemy["route_state"]["speed"] > 0 and enemy["route_state"]["length"] > 0
		if entry.has("actions"):
			enemy["actions"] = entry["actions"].duplicate(true)
		enemies.append(enemy)
	selected_id = ""
	action = {}
	events.clear()
	decisions.clear()
	simulation_time = 0.0
	completed_actions = 0
	outcome = "running"
	_update_facing()
	log_event("%s | semente %d | valores experimentais" % [preset["name"], random_seed])
	return true

func _movement_settings(definition: Dictionary, entry: Dictionary) -> Dictionary:
	if definition.has("movement_behavior"):
		var id: String = definition["movement_behavior"]
		var behavior: Dictionary = data["movement_behaviors"][id].duplicate(true)
		var motion = {"kind": behavior["kind"], "curve": "smooth",
			"behavior": behavior, "presentation": behavior.get("presentation", {}).duplicate(true)}
		# O encontro pode descrever geometria, mas não interferir na política/sorteios.
		for source in [definition.get("motion", {}), entry.get("motion", {})]:
			for key in ["curve", "samples_per_segment", "center", "radii", "samples", "start_angle"]:
				if source.has(key):
					motion[key] = source[key].duplicate(true) if source[key] is Array else source[key]
		return {"profile": id, "speed": float(behavior["speed"]), "motion": motion}
	var profile: String = entry.get("movement_profile", definition.get("movement_profile", ""))
	var defaults: Dictionary = data.get("movement_profiles", {}).get(profile, {})
	var motion: Dictionary = defaults.get("motion", {}).duplicate(true)
	for source in [definition.get("motion", {}), entry.get("motion", {})]:
		for key in source:
			if source[key] is Dictionary and motion.get(key) is Dictionary:
				motion[key].merge(source[key].duplicate(true), true)
			else:
				motion[key] = source[key].duplicate(true) if source[key] is Array or source[key] is Dictionary else source[key]
	return {"profile": profile, "speed": float(entry.get("speed", definition.get("speed", defaults.get("speed", 0.0)))), "motion": motion}

func _make_actor(definition: Dictionary, side: String, id: String) -> Dictionary:
	var actor = definition.duplicate(true)
	actor.merge({"id": id, "side": side, "hp": int(definition["max_hp"]),
		"mp": int(definition["max_mp"]), "atb": 0.0, "ini_modifier": 0.0,
		"logical_position": Vector2.ZERO, "home_position": Vector2.ZERO,
		"visual_offset": Vector2.ZERO, "route_state": Route.create([], 0.0),
		"facing": Vector2.RIGHT if side == "ally" else Vector2.LEFT,
		"visual_focus_id": "",
		"last_attacker": "", "last_target": "",
		CENTER_SETTING: bool(definition.get(CENTER_SETTING, side == "ally")),
		"fullscreen_center_override": null}, true)
	return actor

func fullscreen_center_enabled(actor: Dictionary) -> bool:
	var override = actor.get("fullscreen_center_override")
	if override is bool:
		return override
	return bool(actor.get(CENTER_SETTING, false))

func set_fullscreen_center_override(id: String, value: Variant = null) -> bool:
	var actor = actor_by_id(id)
	if actor.is_empty() or (value != null and not value is bool):
		return false
	# A decisão da ação atual já foi capturada; alterações valem na próxima.
	actor["fullscreen_center_override"] = value
	return true

func visual_center() -> Vector2:
	return BATTLEFIELD_SIZE * 0.5

func actors() -> Array:
	return party + enemies

func actor_by_id(id: String) -> Dictionary:
	for actor in actors():
		if actor["id"] == id:
			return actor
	return {}

func living(group: Array) -> Array:
	return group.filter(func(actor): return actor["hp"] > 0)

func effective_ini(actor: Dictionary) -> float:
	return maxf(0.0, float(actor["ini"]) + actor["ini_modifier"])

func is_ready(actor: Dictionary) -> bool:
	return not actor.is_empty() and actor["hp"] > 0 and actor["atb"] >= 1.0 and action.get("actor_id", "") != actor["id"]

func is_waiting() -> bool:
	return mode == "Wait" and not selected_id.is_empty() and is_ready(actor_by_id(selected_id))

func select_actor(id: String) -> bool:
	var actor = actor_by_id(id)
	if outcome != "running" or not action.is_empty() or actor.get("side", "") != "ally" or not is_ready(actor):
		return false
	selected_id = id
	return true

func cancel_selection() -> void:
	selected_id = ""

func tick(delta: float) -> void:
	if outcome != "running" or delta <= 0.0:
		return
	if not selected_id.is_empty() and not is_ready(actor_by_id(selected_id)):
		selected_id = ""
	var waiting = is_waiting()
	if not waiting:
		simulation_time += delta
		for actor in actors():
			if actor["hp"] <= 0:
				actor["atb"] = 0.0
				continue
			if action.get("actor_id", "") == actor["id"]:
				continue
			actor["atb"] = minf(1.0, actor["atb"] + effective_ini(actor) * float(data["settings"]["atb_per_ini"]) * delta)
			if actor["side"] == "enemy":
				Route.advance(actor["route_state"], delta)
				actor["logical_position"] = Route.position_at(actor["route_state"], actor["logical_position"])
	_update_facing()
	# Uma animação já iniciada pode concluir mesmo ao trocar para Wait.
	if not action.is_empty():
		_advance_action(delta)
	if outcome == "running" and action.is_empty() and not is_waiting():
		for enemy in enemies:
			if is_ready(enemy):
				_schedule_enemy(enemy)
				break

func _update_facing() -> void:
	for actor in actors():
		if actor["side"] == "enemy" and actor.get("facing_policy", "legacy") != "legacy":
			if action.get("actor_id", "") == actor["id"]:
				continue
			match actor["facing_policy"]:
				"focus":
					var target = actor_by_id(actor["visual_focus_id"])
					if target.is_empty() or target["hp"] <= 0 or target["side"] != "ally":
						target = _nearest_opponent(actor, actor["logical_position"])
						actor["visual_focus_id"] = target.get("id", "")
					if not target.is_empty():
						_face_point(actor, actor["logical_position"], target["logical_position"])
				"travel":
					var direction = Route.travel_direction(actor["route_state"])
					if direction != Vector2.ZERO:
						actor["facing"] = direction
			continue # "fixed" conserva orientação de repouso; não cria um inimigo especial.
		var route: Dictionary = actor["route_state"]
		if actor["side"] == "enemy" and route.has("rhythm") and action.get("actor_id", "") != actor["id"]:
			if route["rhythm"]["current_speed"] > 0.01:
				actor["facing"] = Route.travel_direction(route)
			continue
		var opponents = living(enemies if actor["side"] == "ally" else party)
		var closest_distance = INF
		for other in opponents:
			var distance: float = actor["logical_position"].distance_squared_to(other["logical_position"])
			if distance < closest_distance:
				closest_distance = distance
				actor["facing"] = actor["logical_position"].direction_to(other["logical_position"])

func _nearest_opponent(actor: Dictionary, origin: Vector2) -> Dictionary:
	var target: Dictionary = {}
	var distance = INF
	for other in living(party if actor["side"] == "enemy" else enemies):
		var candidate: float = origin.distance_squared_to(other["logical_position"])
		if candidate < distance:
			distance = candidate
			target = other
	return target

func _face_point(actor: Dictionary, origin: Vector2, point: Vector2) -> void:
	if origin.distance_squared_to(point) > 0.000001:
		actor["facing"] = origin.direction_to(point)

func targets_for(actor: Dictionary, skill: Dictionary, target_id: String = "", center: Vector2 = Vector2.ZERO) -> Array:
	var group = enemies if actor["side"] == "ally" else party
	if skill.get("effect", "damage") != "damage":
		group = party if actor["side"] == "ally" else enemies
	var candidates = []
	for target in group:
		var eligible: bool = target["hp"] == 0 if skill.get("effect", "") == "revive" else target["hp"] > 0
		if not eligible:
			continue
		match skill.get("target", "single"):
			"single":
				if target["id"] == target_id:
					candidates.append(target)
			"circle":
				if target["logical_position"].distance_to(center) <= float(skill["radius"]):
					candidates.append(target)
			"all":
				candidates.append(target)
	return candidates

func item_skill(id: String) -> Dictionary:
	if not data["items"].has(id):
		return {}
	var item = data["items"][id].duplicate(true)
	item["target"] = "single"
	item["mp_cost"] = 0
	return item

func submit(skill_id: String, target_id: String = "", center: Vector2 = Vector2.ZERO, item_id: String = "") -> bool:
	var actor = actor_by_id(selected_id)
	if outcome != "running" or not action.is_empty() or not is_ready(actor):
		return false
	if skill_id == "escape":
		if not preset.get("can_escape", true):
			log_event("Fuga bloqueada neste preset; ação preservada.")
			return false
		_begin_action(actor, {"name": "Fugir", "target": "all", "mp_cost": 0, "effect": "escape"}, "", Vector2.ZERO, "")
		selected_id = ""
		return true
	var skill: Dictionary
	if not item_id.is_empty():
		if not data["items"].has(item_id) or inventory.get(item_id, 0) <= 0:
			return false
		skill = item_skill(item_id)
	else:
		if not data["skills"].has(skill_id):
			return false
		if skill_id != "attack" and not actor.get("skills", []).has(skill_id):
			return false
		skill = data["skills"][skill_id]
	if actor["mp"] < skill.get("mp_cost", 0) or targets_for(actor, skill, target_id, center).is_empty():
		return false
	_begin_action(actor, skill, target_id, center, item_id)
	selected_id = ""
	return true

func _begin_action(actor: Dictionary, skill: Dictionary, target_id: String, center: Vector2, item_id: String) -> void:
	actor["mp"] -= int(skill.get("mp_cost", 0))
	if not item_id.is_empty():
		inventory[item_id] -= 1
	var target = actor_by_id(target_id)
	var visual_target_id = target_id
	var aim = center
	if not target.is_empty():
		aim = target["logical_position"]
	elif skill.get("target", "") == "all":
		var group = living(enemies if actor["side"] == "ally" else party)
		if not group.is_empty():
			# Alvo de aproximação apenas visual; não altera alvos/pesos do efeito.
			var nearest = INF
			for member in group:
				var distance: float = actor["logical_position"].distance_squared_to(member["logical_position"])
				if distance < nearest:
					nearest = distance
					aim = member["logical_position"]
					visual_target_id = member["id"]
	var melee: bool = skill.get("delivery", "melee" if skill.get("category", "") in ["basic", "physical"] else "gesture") == "melee"
	var motion: Dictionary
	if skill.get("presentation", "") == "fullscreen":
		visual_target_id = ""
		motion = FullscreenMotion.create(actor["logical_position"], visual_center(), fullscreen_center_enabled(actor), data["settings"])
	else:
		motion = AttackMotion.create(actor["logical_position"], aim, melee, data["settings"])
	if skill.get("effect", "") == "escape":
		motion["gesture_offset"] = Vector2(-70, 0)
	action = {"actor_id": actor["id"], "skill": skill, "target_id": target_id,
		"visual_target_id": visual_target_id, "center": center, "elapsed": 0.0,
		"applied": false, "motion": motion, "impact_points": [],
		"route_snapshot": actor["route_state"].duplicate(true), "origin": actor["logical_position"]}
	if actor["side"] == "enemy" and actor.get("facing_policy", "legacy") != "legacy":
		_face_action(actor)
	log_event("%s → %s" % [actor["short_name"], skill["name"]])

func _face_action(actor: Dictionary) -> void:
	var reference = actor_by_id(action["target_id"])
	if reference.is_empty() or reference["hp"] <= 0:
		reference = _nearest_opponent(actor, actor["logical_position"] + actor["visual_offset"])
	if not reference.is_empty():
		_face_point(actor, actor["logical_position"] + actor["visual_offset"], reference["logical_position"])

func _advance_action(delta: float) -> void:
	var actor = actor_by_id(action["actor_id"])
	action["elapsed"] += delta
	var duration: float = maxf(0.05, float(data["settings"]["action_duration"]))
	var progress: float = minf(1.0, action["elapsed"] / duration)
	var aim: Vector2 = action["center"]
	var visual_target = actor_by_id(action["visual_target_id"])
	if not visual_target.is_empty():
		aim = visual_target["logical_position"]
	if action["motion"].get("presentation", "") == "fullscreen":
		actor["visual_offset"] = FullscreenMotion.sample(action["motion"], progress)
	else:
		actor["visual_offset"] = AttackMotion.sample(action["motion"], progress, aim)
	if actor["side"] == "enemy" and actor.get("facing_policy", "legacy") != "legacy":
		_face_action(actor)
	elif action["motion"]["melee"]:
		actor["facing"] = (actor["logical_position"] + actor["visual_offset"]).direction_to(aim)
	if not action["applied"] and progress >= action["motion"]["impact"]:
		action["applied"] = true
		_apply_action(actor)
	if progress >= 1.0:
		var escaped: bool = action.get("escaped", false)
		actor["visual_offset"] = Vector2.ZERO
		actor["atb"] = 0.0
		# O progresso não foi alterado durante a ação; não recalcular a rota.
		assert(actor["logical_position"] == action["origin"], "A animação alterou a posição lógica do ator.")
		assert(actor["route_state"] == action["route_snapshot"], "A rota avançou durante a ação.")
		action = {}
		completed_actions += 1
		_check_end()
		if escaped and outcome == "running":
			outcome = "escaped"
			selected_id = ""

func _apply_action(actor: Dictionary) -> void:
	var skill = action["skill"]
	if skill["effect"] == "escape":
		if rng.randf() < float(data["settings"]["escape_chance"]):
			action["escaped"] = true
			log_event("Fuga bem-sucedida: todo o grupo escapou.")
		else:
			log_event("Fuga falhou: a ação será consumida.")
		return
	var targets = targets_for(actor, skill, action["target_id"], action["center"])
	for target in targets:
		action["impact_points"].append(target["logical_position"])
	var result: Array[String] = []
	for target in targets:
		match skill["effect"]:
			"damage":
				var damage = maxi(1, int(actor["attack"]) + int(skill.get("power", 0)))
				target["hp"] = maxi(0, target["hp"] - damage)
				target["last_attacker"] = actor["id"]
				if target["hp"] == 0:
					target["atb"] = 0.0
					if selected_id == target["id"]:
						selected_id = ""
				result.append("%s −%d HP" % [target["short_name"], damage])
			"hp", "revive":
				target["hp"] = mini(int(target["max_hp"]), target["hp"] + int(skill["amount"]))
				result.append("%s +HP" % target["short_name"])
			"mp":
				target["mp"] = mini(int(target["max_mp"]), target["mp"] + int(skill["amount"]))
				result.append("%s +MP" % target["short_name"])
	if targets.is_empty():
		log_event("Nenhum alvo atingido no instante do impacto.")
	else:
		log_event(" | ".join(result))

func _check_end() -> void:
	if living(party).is_empty():
		outcome = "defeat"
		selected_id = ""
		log_event("GAME OVER · grupo incapacitado. Reinicie o teste.")
	elif living(enemies).is_empty():
		outcome = "victory"
		selected_id = ""
		log_event("VITÓRIA · HP/MP preservados; nenhuma recuperação automática.")

func _schedule_enemy(enemy: Dictionary) -> void:
	var choices: Array = []
	var action_weights: Array = []
	for entry in enemy.get("actions", []):
		if data["skills"].has(entry["id"]) and enemy["mp"] >= data["skills"][entry["id"]]["mp_cost"]:
			choices.append(entry["id"])
			action_weights.append(entry["weight"])
	if choices.is_empty():
		choices = ["attack"]
		action_weights = [1.0]
	var skill_id = choices[Policy.pick_index(action_weights, rng)]
	var skill = data["skills"][skill_id]
	var candidates = living(party)
	if candidates.is_empty():
		_check_end()
		return
	var distribution: Array[String] = []
	var target_id = ""
	var detail = "todos os aliados válidos"
	if skill["target"] == "all":
		distribution.append("Ação em todos: sem sorteio de alvo individual.")
	else:
		var profile = data["profiles"].get(enemy["profile"], {"kind": "uniform"})
		var values = Policy.weights(enemy, candidates, profile)
		var target: Dictionary = candidates[Policy.pick_index(values, rng)]
		target_id = target["id"]
		detail = target_id
		enemy["last_target"] = target_id
		var total = 0.0
		for weight in values:
			total += weight
		for index in range(candidates.size()):
			distribution.append("%s %.1f%%" % [candidates[index]["id"], values[index] / total * 100.0])
	decisions.append({"enemy": enemy["id"], "profile": enemy["profile"], "action": skill_id,
		"chosen": detail, "weights": distribution, "time": simulation_time})
	if decisions.size() > 80:
		decisions.pop_front()
	_begin_action(enemy, skill, target_id, Vector2.ZERO, "")

func log_event(message: String) -> void:
	events.append("[%05.1f] %s" % [simulation_time, message])
	if events.size() > 100:
		events.pop_front()

func debug_ready_allies() -> void:
	for member in living(party):
		if action.get("actor_id", "") != member["id"]:
			member["atb"] = 1.0
	log_event("DEPURAÇÃO: aliados vivos prontos.")

func debug_restore() -> void:
	for member in party:
		member["hp"] = int(member["max_hp"])
		member["mp"] = int(member["max_mp"])
	log_event("DEPURAÇÃO: HP/MP restaurados, inclusive incapacitados.")

func _vector(point: Array) -> Vector2:
	return Vector2(float(point[0]), float(point[1]))
