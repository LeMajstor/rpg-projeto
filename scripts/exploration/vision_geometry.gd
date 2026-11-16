extends RefCounted
## Contorno visual da visão: raios limitados aos sólidos próximos, somente na depuração.
static func sector(origin: Vector2, direction: Vector2, reach: float, degrees: float, blockers: Array[PackedVector2Array]) -> PackedVector2Array:
	var half=deg_to_rad(degrees*0.5)
	var angles: Array[float]=[]
	var steps=maxi(4,ceili(degrees/6.0))
	for index in range(steps+1):
		angles.append(lerpf(-half,half,float(index)/steps))
	# Raios nos cantos preservam as sombras de quinas e portas estreitas.
	for shape in blockers:
		for point in shape:
			var angle=direction.angle_to(point-origin)
			for offset in [-0.0002,0.0,0.0002]:
				if angle+offset>-half and angle+offset<half:
					angles.append(angle+offset)
	angles.sort()
	var result=PackedVector2Array([origin])
	for angle in angles:
		var target=origin+direction.rotated(angle)*reach
		var endpoint=target
		var nearest=reach*reach
		for shape in blockers:
			for index in range(shape.size()):
				var hit=Geometry2D.segment_intersects_segment(origin,target,shape[index],shape[(index+1)%shape.size()])
				if hit!=null:
					var distance: float=origin.distance_squared_to(hit)
					if distance<nearest:
						nearest=distance
						endpoint=hit
		if not result[-1].is_equal_approx(endpoint):
			result.append(endpoint)
	return result
