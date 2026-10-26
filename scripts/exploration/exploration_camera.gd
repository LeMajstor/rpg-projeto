extends RefCounted
## Transformação visual pura; não altera posição, trilha, colisões ou tempo do mapa.
static func scale_for(view_size: Vector2, reference_size: Vector2) -> float:
	var reference = reference_size.max(Vector2.ONE)
	return maxf(0.001, minf(view_size.x / reference.x, view_size.y / reference.y))

static func center_for(target: Vector2, view_size: Vector2, world_size: Vector2, scale: float) -> Vector2:
	var half_view = view_size / maxf(0.001, scale) * 0.5
	var center = world_size * 0.5
	if world_size.x > half_view.x * 2:
		center.x = clampf(target.x, half_view.x, world_size.x - half_view.x)
	if world_size.y > half_view.y * 2:
		center.y = clampf(target.y, half_view.y, world_size.y - half_view.y)
	return center

static func origin_for(target: Vector2, view_size: Vector2, world_size: Vector2, scale: float) -> Vector2:
	return view_size * 0.5 - center_for(target, view_size, world_size, scale) * scale
