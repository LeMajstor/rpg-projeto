extends RefCounted
## Território imutável: união das faixas ao redor dos segmentos da rota em dados.
static func points(entity: Dictionary) -> Array:
	var result: Array = entity["route_state"]["points"]
	return result if not result.is_empty() else [Vector2(entity["default_placement"]["position"][0],entity["default_placement"]["position"][1])]

static func projection(entity: Dictionary, position: Vector2, world = null) -> Dictionary:
	var route = points(entity)
	var best: Dictionary = {}
	var distance = INF
	var count=route.size() if entity["route_state"].get("closed",true) else maxi(1,route.size()-1)
	for index in range(count):
		var a: Vector2 = route[index]
		var b: Vector2 = route[(index+1)%route.size()] if route.size()>1 else a
		var nearest = Geometry2D.get_closest_point_to_segment(position,a,b)
		for candidate in [nearest,a,b]:
			var value: float = position.distance_squared_to(candidate)
			if value >= distance or (world != null and not world.can_traverse(position,candidate)):
				continue
			distance = value
			best = {"point":candidate,"segment":index,"progress":0.0 if a==b else a.distance_to(candidate)/a.distance_to(b),"distance":sqrt(value)}
	return best

static func contains(entity: Dictionary, position: Vector2, radius: float) -> bool:
	return float(projection(entity,position)["distance"]) <= radius + 0.0001
