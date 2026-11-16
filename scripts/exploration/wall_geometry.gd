extends RefCounted
## Paredes convexas em dados: colisão varrida e visão usam a geometria do chão.
static func polygon(points: Array) -> PackedVector2Array:
	var result = PackedVector2Array()
	for point in points:
		result.append(Vector2(float(point[0]), float(point[1])))
	return result

static func expanded(shape: PackedVector2Array, extent: float) -> PackedVector2Array:
	var corners = PackedVector2Array()
	for point in shape:
		for offset in [Vector2(-extent,-extent),Vector2(extent,-extent),Vector2(extent,extent),Vector2(-extent,extent)]:
			corners.append(point + offset)
	return Geometry2D.convex_hull(corners)

static func blocks(shape: PackedVector2Array, from: Vector2, to: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(from, shape) or Geometry2D.is_point_in_polygon(to, shape):
		return true
	for index in range(shape.size()):
		if Geometry2D.segment_intersects_segment(from, to, shape[index], shape[(index+1)%shape.size()]) != null:
			return true
	return false

static func sweep(from: Vector2, to: Vector2, shapes: Array[PackedVector2Array]) -> Vector2:
	if from.is_equal_approx(to):
		return from
	var direction = (to-from).normalized()
	var length = from.distance_to(to)
	var allowed = length
	for shape in shapes:
		if Geometry2D.is_point_in_polygon(from + direction * 0.001, shape):
			return from
		for index in range(shape.size()):
			var hit = Geometry2D.segment_intersects_segment(from, to, shape[index], shape[(index+1)%shape.size()])
			if hit != null:
				allowed = minf(allowed, maxf(0, from.distance_to(hit)-0.05))
	return from + direction * allowed

static func valid(points: Variant) -> bool:
	if not points is Array or points.size() < 3:
		return false
	for point in points:
		if not point is Array or point.size()!=2:
			return false
		for value in point:
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
	var shape = polygon(points)
	if Geometry2D.triangulate_polygon(shape).is_empty():
		return false
	# Cada parede é convexa; combinações permitem corredores e contornos irregulares.
	var hull = Geometry2D.convex_hull(shape)
	return hull.size() == shape.size()+1
