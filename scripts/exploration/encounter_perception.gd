extends RefCounted
const Contact = preload("res://scripts/exploration/encounter_contact.gd")

static func stationary(entity: Dictionary) -> bool:
	return entity.get("movement_profile","")=="static"

static func rules(world,entity: Dictionary) -> Dictionary:
	var result: Dictionary=world.data["encounter_rules"].duplicate()
	result.merge(entity.get("exploration_behavior",{}),true)
	return result

static func in_static_area(entity: Dictionary,point: Vector2) -> bool:
	var config: Dictionary=entity["exploration_behavior"]
	var offset: Vector2=point-entity["position"]
	if offset.length()<=float(config["near_radius"]):
		return true
	var facing=Vector2(entity["vision_direction"][0],entity["vision_direction"][1]).normalized()
	return offset.length()<=float(config["cone_range"]) and absf(facing.angle_to(offset))<=deg_to_rad(float(config["cone_degrees"])*0.5)+0.000001

static func static_fraction(entity: Dictionary,from: Vector2,to: Vector2) -> float:
	if in_static_area(entity,from):
		return 0.0
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
