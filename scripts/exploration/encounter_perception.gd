extends RefCounted
const Contact = preload("res://scripts/exploration/encounter_contact.gd")

static func stationary(entity: Dictionary) -> bool:
	return entity.get("movement_profile","")=="static"

static func directional(entity: Dictionary) -> bool:
	return entity.get("exploration_behavior",{}).has("vision")

static func direction(entity: Dictionary) -> Vector2:
	if stationary(entity):
		return Vector2(entity["vision_direction"][0],entity["vision_direction"][1]).normalized()
	return entity.get("look_direction",Vector2.RIGHT)

static func initial_direction(entity: Dictionary) -> Vector2:
	var points: Array=entity["route_state"]["points"]
	for index in range(1,points.size()):
		var offset: Vector2=points[index]-points[0]
		if not offset.is_zero_approx():
			return offset.normalized()
	return Vector2.RIGHT

static func _in_sector(offset: Vector2, facing: Vector2, reach: float, degrees: float) -> bool:
	return offset.length_squared()<=reach*reach+0.000001 and absf(facing.angle_to(offset))<=deg_to_rad(degrees*0.5)+0.000001

static func in_vision(entity: Dictionary, point: Vector2) -> bool:
	var config: Dictionary=entity["exploration_behavior"]["vision"]
	var offset: Vector2=point-entity["position"]
	var facing=direction(entity)
	return _in_sector(offset,facing,config["front_range"],config["front_degrees"]) or _in_sector(offset,facing,config["peripheral_range"],config["peripheral_degrees"])

static func sees(world, entity: Dictionary, point: Vector2) -> bool:
	var in_area: bool=in_vision(entity,point) if directional(entity) else entity["position"].distance_to(point)<=float(rules(world,entity)["detection_radius"])
	return in_area and world.clear_sight(entity["position"],point)

static func rules(world,entity: Dictionary) -> Dictionary:
	var result: Dictionary=world.data["encounter_rules"].duplicate()
	result.merge(entity.get("exploration_behavior",{}),true)
	return result

static func in_static_area(entity: Dictionary,point: Vector2,body_radius: float = 0) -> bool:
	if entity["position"].distance_squared_to(point)<=body_radius*body_radius:
		return true
	if directional(entity):
		return in_vision(entity,point)
	# Compatibilidade exclusiva com fixtures dos sensores D158.
	var config: Dictionary=entity["exploration_behavior"]
	var offset: Vector2=point-entity["position"]
	if offset.length()<=float(config["near_radius"]):
		return true
	var facing=Vector2(entity["vision_direction"][0],entity["vision_direction"][1]).normalized()
	return offset.length()<=float(config["cone_range"]) and absf(facing.angle_to(offset))<=deg_to_rad(float(config["cone_degrees"])*0.5)+0.000001

static func static_fraction(entity: Dictionary,from: Vector2,to: Vector2,body_radius: float = 0) -> float:
	if in_static_area(entity,from,body_radius):
		return 0.0
	if directional(entity):
		var vision: Dictionary=entity["exploration_behavior"]["vision"]
		return minf(Contact.fraction(from,to,entity["position"],body_radius),minf(_sector_fraction(entity,from,to,vision["front_range"],vision["front_degrees"]),_sector_fraction(entity,from,to,vision["peripheral_range"],vision["peripheral_degrees"])))
	var config: Dictionary=entity["exploration_behavior"]
	var center: Vector2=entity["position"]
	var best=Contact.fraction(from,to,center,float(config["near_radius"]))
	var facing=Vector2(entity["vision_direction"][0],entity["vision_direction"][1]).normalized()
	var half=deg_to_rad(float(config["cone_degrees"])*0.5)
	# Entrada no cone por arco ou por qualquer uma das duas bordas radiais.
	var arc=Contact.fraction(from,to,center,float(config["cone_range"]))
	if is_finite(arc) and in_static_area(entity,from.lerp(to,arc)):
		best=minf(best,arc)
	for angle in [-half,half]:
		var hit=Geometry2D.segment_intersects_segment(from,to,center,center+facing.rotated(angle)*float(config["cone_range"]))
		if hit!=null and from.distance_to(to)>0:
			best=minf(best,from.distance_to(hit)/from.distance_to(to))
	return best

static func _sector_fraction(entity: Dictionary,from: Vector2,to: Vector2,reach: float,degrees: float) -> float:
	var center: Vector2=entity["position"]
	var facing=direction(entity)
	if _in_sector(from-center,facing,reach,degrees):
		return 0.0
	var best=INF
	var arc=Contact.fraction(from,to,center,reach)
	if is_finite(arc) and _in_sector(from.lerp(to,arc)-center,facing,reach,degrees):
		best=arc
	if from==to:
		return best
	var half=deg_to_rad(degrees*0.5)
	for angle in [-half,half]:
		var hit=Geometry2D.segment_intersects_segment(from,to,center,center+facing.rotated(angle)*reach)
		if hit!=null:
			best=minf(best,from.distance_to(hit)/from.distance_to(to))
	return best
