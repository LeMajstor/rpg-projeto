extends RefCounted
## Território fixo na rota; retomada pelo trecho acessível mais próximo.
const Route = preload("res://scripts/combat/route_motion.gd")
const Territory = preload("res://scripts/exploration/patrol_territory.gd")
const Perception = preload("res://scripts/exploration/encounter_perception.gd")

static func advance(world, entity: Dictionary, delta: float) -> void:
	if not entity.has("awareness"):
		entity["awareness"] = {"state":"patrol", "trail":[], "speed":float(entity["route_state"]["speed"])}
	var awareness: Dictionary = entity["awareness"]
	if Perception.stationary(entity):
		awareness["state"]="static"
		awareness["speed"]=0.0
		return
	var position: Vector2 = entity["position"]
	var rules: Dictionary = Perception.rules(world,entity)
	var radius = float(rules["chase_limit"])
	var sees = entity["interaction_available"] \
		and position.distance_to(world.leader_position) <= float(rules["detection_radius"]) \
		and Territory.contains(entity,world.leader_position,radius) \
		and world.clear_sight(position,world.leader_position)
	if awareness["state"] != "chase" and sees:
		if awareness["state"]=="patrol":
			awareness["trail"]=[position]
		else:
			# Nova percepção mantém uma ligação segura com a rota original.
			var link: Dictionary=Territory.projection(entity,position,world)
			if not link.is_empty():
				awareness["trail"]=[link["point"],position]
			else:
				_record(awareness["trail"],position)
		awareness["state"] = "chase"
	if awareness["state"] == "chase" and (not sees or not Territory.contains(entity,position,radius)):
		awareness["state"] = "return"
	var patrol_speed = float(entity["route_state"]["speed"])
	var desired = float(rules["chase_speed"]) if awareness["state"] == "chase" else (patrol_speed if patrol_speed > 0 or awareness["state"]=="patrol" else 60.0)
	var acceleration = float(rules["chase_speed"]) / float(rules.get("speed_transition_seconds",0.3))
	awareness["speed"] = move_toward(float(awareness.get("speed",patrol_speed)),desired,acceleration*delta)
	if awareness["state"]!="patrol" and entity["route_state"].has("presentation_time"):
		entity["route_state"]["presentation_time"]+=delta
	if awareness["state"] == "patrol":
		var snapshot: Dictionary=entity["route_state"].duplicate(true)
		if entity["route_state"].has("behavior"):
			Route.advance(entity["route_state"],delta)
			awareness["speed"]=entity["route_state"]["behavior"]["current_speed"]
		else:
			Route.advance(entity["route_state"],delta*float(awareness["speed"])/patrol_speed if patrol_speed>0 else 0.0)
		if not _move(world,entity,Route.position_at(entity["route_state"],position)):
			entity["route_state"]=snapshot
	elif awareness["state"] == "chase":
		var target = position.move_toward(world.leader_position,float(awareness["speed"])*delta)
		# Mesmo uma nova detecção não desloca o território definido pela rota.
		if not Territory.contains(entity,target,radius):
			awareness["state"] = "return"
		elif _move(world,entity,target):
			_record(awareness["trail"],entity["position"])
	else:
		var join: Dictionary = Territory.projection(entity,position,world)
		if not join.is_empty():
			var target: Vector2 = position.move_toward(join["point"],float(awareness["speed"])*delta)
			if _move(world,entity,target):
				if entity["position"].is_equal_approx(join["point"]):
					entity["route_state"]["segment"] = join["segment"]
					entity["route_state"]["progress"] = join["progress"]
					if entity["route_state"].has("behavior"):
						var points: Array=entity["route_state"]["points"]
						var distance=0.0
						for index in range(int(join["segment"])):
							distance+=points[index].distance_to(points[index+1])
						distance+=points[int(join["segment"])].distance_to(join["point"])
						Route.Behavior.relocate(entity["route_state"]["behavior"],distance)
					awareness["state"] = "patrol"
					awareness["trail"] = []
				else:
					awareness["trail"]=[join["point"],entity["position"]]
		else:
			# A trilha segura só é usada até existir uma ligação desobstruída com a rota.
			var trail: Array = awareness["trail"]
			while not trail.is_empty() and position.is_equal_approx(trail.back()):
				trail.pop_back()
			if not trail.is_empty():
				_move(world,entity,position.move_toward(trail.back(),float(awareness["speed"])*delta))

static func _move(world, entity: Dictionary, target: Vector2) -> bool:
	var from: Vector2 = entity["position"]
	if not world.can_traverse(from,target):
		return false
	if entity["interaction_available"]:
		var t = world.Contact.fraction(from,target,world.leader_position,world.contact_radius())
		if is_finite(t) and world.clear_sight(from.lerp(target,t),world.leader_position):
			entity["position"] = from.lerp(target,t)
			world.contact_id = entity["id"]
			return true
	entity["position"] = target
	return true

static func _record(trail: Array, position: Vector2) -> void:
	if trail.is_empty():
		trail.append(position)
		return
	if trail.back().is_equal_approx(position):
		return
	if trail.size() >= 2:
		var last: Vector2 = trail.back()-trail[trail.size()-2]
		var next: Vector2 = position-trail.back()
		if absf(last.cross(next)) < 0.00001 and last.dot(next) > 0:
			trail[trail.size()-1] = position
			return
	trail.append(position)
