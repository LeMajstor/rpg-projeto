extends RefCounted
## Movimento e fila independentes do combate e da renderização.
## O histórico armazena o caminho REAL do líder, depois da colisão.
const Route = preload("res://scripts/combat/route_motion.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Terrain = preload("res://scripts/exploration/terrain_geometry.gd")
const Rules = preload("res://scripts/exploration/area_rules.gd")

var data: Dictionary
var party_order: Array[String] = []
var leader_position = Vector2.ZERO
var facing = Vector2.RIGHT
var path: Array[Vector2] = [] # Mais antigo -> mais recente.
var path_length = 0.0
var distance_walked = 0.0
var moving = false
var menu_open = false
var dialogue_open = false
var transitioning = false
var arrival_transition_lock = ""
var entities: Array[Dictionary] = []
var obstacles: Array[Rect2] = []
var bounds: Rect2

func _init(definitions: Dictionary, member_ids: Array) -> void:
	data = definitions
	for id in member_ids:
		party_order.append(str(id))
	bounds = _rect(data["walkable_bounds"])
	for group in ["encounters", "npcs", "objects", "transitions"]:
		for definition in data.get(group, []):
			var entity: Dictionary = definition.duplicate(true)
			entity["kind"] = {"encounters": "encounter", "npcs": "npc", "objects": "object", "transitions": "transition"}[group]
			entity["present"] = true
			entity["open"] = false
			entity["active"] = false
			entity["position"] = _point(definition["position"])
			entity["route_state"] = Route.create(definition.get("route", [definition["position"]]), float(definition.get("speed", 0)))
			entity["default_placement"] = {"position": definition["position"], "route": definition.get("route", [definition["position"]]), "speed": definition.get("speed", 0)}
			entity["placement_key"] = "default"
			entity["placement_pending"] = false
			entity["interaction_available"] = true
			entities.append(entity)
	_rebuild_obstacles()
	leader_position = _point(data["spawn"])
	# Trilha inicial num trecho livre, validado nos testes do mapa.
	var tail = leader_position - Vector2.RIGHT * float(data["follower_gap"]) * (party_order.size() - 1)
	path.assign([tail, leader_position])
	path_length = tail.distance_to(leader_position)

static func cardinal(direction: Vector2, preferred_axis: String = "x") -> Vector2:
	if direction.x != 0 and (preferred_axis == "x" or direction.y == 0):
		return Vector2(signf(direction.x), 0)
	if direction.y != 0:
		return Vector2(0, signf(direction.y))
	return Vector2.ZERO

func move(direction: Vector2, delta: float, preferred_axis: String = "x") -> Vector2:
	moving = false
	if menu_open or dialogue_open or transitioning or delta <= 0:
		return Vector2.ZERO
	var axis = cardinal(direction, preferred_axis)
	if axis == Vector2.ZERO:
		return Vector2.ZERO
	facing = axis
	var target = _move_with_collision(axis * float(data["move_speed"]) * delta)
	var movement = target - leader_position
	if movement.length_squared() < 0.000001:
		return Vector2.ZERO
	leader_position = target
	moving = true
	distance_walked += movement.length()
	_record_position(target)
	_release_arrival_lock()
	return movement

func _move_with_collision(offset: Vector2) -> Vector2:
	var radius = float(data["leader_half_extent"])
	var result = leader_position
	if offset.x != 0:
		result.x = clampf(result.x + offset.x, bounds.position.x + radius, bounds.end.x - radius)
		for obstacle in obstacles:
			var expanded = obstacle.grow(radius)
			if result.y <= expanded.position.y or result.y >= expanded.end.y:
				continue
			if offset.x > 0 and leader_position.x <= expanded.position.x:
				result.x = minf(result.x, expanded.position.x)
			elif offset.x < 0 and leader_position.x >= expanded.end.x:
				result.x = maxf(result.x, expanded.end.x)
	else:
		result.y = clampf(result.y + offset.y, bounds.position.y + radius, bounds.end.y - radius)
		for obstacle in obstacles:
			var expanded = obstacle.grow(radius)
			if result.x <= expanded.position.x or result.x >= expanded.end.x:
				continue
			if offset.y > 0 and leader_position.y <= expanded.position.y:
				result.y = minf(result.y, expanded.position.y)
			elif offset.y < 0 and leader_position.y >= expanded.end.y:
				result.y = maxf(result.y, expanded.end.y)
	return result

func _record_position(position: Vector2) -> void:
	var movement = position - path.back()
	path_length += movement.length()
	if path.size() >= 2:
		var previous = path.back() - path[path.size() - 2]
		if absf(previous.cross(movement)) < 0.00001 and previous.dot(movement) > 0:
			path[path.size() - 1] = position
		else:
			path.append(position)
	else:
		path.append(position)
	var retained = float(data["follower_gap"]) * (party_order.size() - 1)
	while path.size() > 2:
		var first_length = path[0].distance_to(path[1])
		if path_length - first_length < retained:
			break
		path_length -= first_length
		path.remove_at(0)

func position_behind(distance: float) -> Vector2:
	var remaining = maxf(0.0, distance)
	for index in range(path.size() - 1, 0, -1):
		var length = path[index].distance_to(path[index - 1])
		if length < 0.000001:
			continue
		if remaining <= length:
			return path[index].lerp(path[index - 1], remaining / length)
		remaining -= length
	return path[0]

func formation_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(party_order.size()):
		result.append(position_behind(float(data["follower_gap"]) * index))
	return result

func elevation_at(position: Vector2) -> float:
	return Terrain.elevation_at(data.get("terrain", []), position)

func visual_position(position: Vector2) -> Vector2:
	# A trilha e a colisão continuam em coordenadas de chão, sem deslocamento acumulado.
	return position - Vector2(0, elevation_at(position))

func choose_leader(id: String) -> bool:
	if not menu_open or dialogue_open or transitioning or not party_order.has(id):
		return false
	party_order.erase(id)
	party_order.push_front(id)
	# Mantém coordenadas e trilha: novas identidades ocupam os mesmos slots.
	menu_open = false
	return true

func can_interact() -> bool:
	return not interaction_candidate().is_empty()

func entity_by_id(id: String) -> Dictionary:
	for entity in entities:
		if entity["id"] == id:
			return entity
	return {}

func advance(delta: float) -> void:
	if menu_open or dialogue_open or transitioning or delta <= 0:
		return
	for entity in entities:
		if not entity["present"] or entity["placement_pending"] or entity["kind"] not in ["npc", "encounter"]:
			continue
		Route.advance(entity["route_state"], delta)
		entity["position"] = Route.position_at(entity["route_state"], entity["position"])

func interaction_candidate() -> Dictionary:
	var nearest: Dictionary = {}
	var distance = INF
	for entity in entities:
		if not can_interact_with(entity):
			continue
		var candidate_distance = leader_position.distance_to(entity["position"])
		if candidate_distance < distance:
			distance = candidate_distance
			nearest = entity
	return nearest

func can_interact_with(entity: Dictionary) -> bool:
	if entity.is_empty() or not entity["present"] or menu_open or dialogue_open or transitioning:
		return false
	if not entity.get("interaction_available", true):
		return false
	if entity["kind"] == "transition" and entity["id"] == arrival_transition_lock:
		return false
	if leader_position.distance_to(entity["position"]) > float(entity.get("interaction_distance", data.get("interaction_distance", 64))):
		return false
	# A própria porta não oculta seu ponto de interação; outras paredes o fazem.
	for obstacle in data["obstacles"]:
		if _blocks_sight(_rect(obstacle["rect"]), leader_position, entity["position"]):
			return false
	for feature in data.get("terrain", []):
		for obstacle in Terrain.collision_rects(feature):
			if _blocks_sight(obstacle, leader_position, entity["position"]):
				return false
	for other in entities:
		if other != entity and (other.get("solid", false) or (other.get("object_type", "") == "door" and not other["open"])):
			if _blocks_sight(_rect(other["rect"]), leader_position, entity["position"]):
				return false
	return true

func prepare_arrival(entry_id: String, order: Array) -> Dictionary:
	var entry = data.get("entries", {}).get(entry_id)
	if not entry is Dictionary or not Catalog.numbers(entry.get("position"), 2) or not Catalog.numbers(entry.get("facing"), 2):
		return {}
	var position = _point(entry["position"])
	var direction = _point(entry["facing"])
	if direction not in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		return {}
	var tail = position - direction * float(data["follower_gap"]) * (order.size() - 1)
	# Valida todo o trecho inicial, não apenas os slots: evita fila cruzando paredes.
	if not is_walkable(position) or not is_walkable(tail):
		return {}
	for obstacle in obstacles:
		if _blocks_sight(obstacle.grow(float(data["leader_half_extent"])), tail, position):
			return {}
	var lock_id = str(entry.get("arrival_transition_id", ""))
	if not lock_id.is_empty() and entity_by_id(lock_id).get("kind", "") != "transition":
		return {}
	return {"position": position, "tail": tail, "facing": direction, "order": order.duplicate(), "lock_id": lock_id}

func apply_arrival(plan: Dictionary) -> void:
	party_order.assign(plan["order"])
	leader_position = plan["position"]
	facing = plan["facing"]
	path.assign([plan["tail"], leader_position])
	path_length = plan["tail"].distance_to(leader_position)
	distance_walked = 0
	moving = false
	menu_open = false
	dialogue_open = false
	arrival_transition_lock = plan["lock_id"]
	_release_arrival_lock()

func _release_arrival_lock() -> void:
	var portal = entity_by_id(arrival_transition_lock)
	if portal.is_empty() or leader_position.distance_to(portal["position"]) > float(portal.get("interaction_distance", data.get("interaction_distance", 64))):
		arrival_transition_lock = ""

func _blocks_sight(rect: Rect2, from: Vector2, to: Vector2) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var corners = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in range(4):
		if Geometry2D.segment_intersects_segment(from, to, corners[index], corners[(index + 1) % 4]) != null:
			return true
	return false

func toggle_door(id: String) -> String:
	var door = entity_by_id(id)
	if door.get("object_type", "") != "door":
		return ""
	if door["open"]:
		var rect = _rect(door["rect"]).grow(float(data["leader_half_extent"]))
		for position in formation_positions():
			if rect.has_point(position):
				return "door_blocked"
	door["open"] = not door["open"]
	_rebuild_obstacles()
	return "door_open" if door["open"] else "door_closed"

func _rebuild_obstacles() -> void:
	obstacles.clear()
	for obstacle in data["obstacles"]:
		obstacles.append(_rect(obstacle["rect"]))
	for feature in data.get("terrain", []):
		obstacles.append_array(Terrain.collision_rects(feature))
	for entity in entities:
		if entity.get("solid", false) or (entity.get("object_type", "") == "door" and not entity["open"]):
			obstacles.append(_rect(entity["rect"]))

func apply_conditions(period: String, flags: Dictionary) -> bool:
	var complete = true
	for entity in entities:
		entity["interaction_available"] = Rules.matches(entity.get("available_when", {}), period, flags)
		if entity["kind"] != "npc":
			continue
		var key = period if entity.get("placement_by_period", {}).has(period) else "default"
		if key == entity["placement_key"]:
			entity["placement_pending"] = false
			continue # Não reinicia patrulha quando só muda uma flag ou o minuto.
		var placement: Dictionary = entity["default_placement"] if key == "default" else entity["placement_by_period"][key]
		var position = _point(placement["position"])
		var points: Array = placement.get("route", [placement["position"]])
		var safe = is_walkable(position)
		for index in range(points.size()):
			var point = _point(points[index])
			safe = safe and is_walkable(point)
			var previous = position if index == 0 else _point(points[index - 1])
			for obstacle in obstacles:
				safe = safe and not _blocks_sight(obstacle.grow(float(data["leader_half_extent"]) - 0.001), previous, point)
		for member in formation_positions():
			safe = safe and member.distance_to(position) >= float(data["leader_half_extent"]) * 2
		for other in entities:
			if other != entity and other["kind"] == "npc" and other["present"]:
				safe = safe and other["position"].distance_to(position) >= float(data["leader_half_extent"]) * 2
		if not safe:
			entity["placement_pending"] = true
			complete = false # Fica onde estava até a fila liberar o destino; não duplica nem busca caminho.
			continue
		entity["position"] = position
		entity["route_state"] = Route.create(points, float(placement.get("speed", 0)))
		entity["placement_key"] = key
		entity["placement_pending"] = false
	return complete

func is_walkable(position: Vector2) -> bool:
	var radius = float(data["leader_half_extent"])
	var inner = bounds.grow(-radius)
	if position.x < inner.position.x or position.x > inner.end.x or position.y < inner.position.y or position.y > inner.end.y:
		return false
	for obstacle in obstacles:
		var expanded = obstacle.grow(radius)
		if position.x > expanded.position.x and position.x < expanded.end.x and position.y > expanded.position.y and position.y < expanded.end.y:
			return false
	return true

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _rect(value: Array) -> Rect2:
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
