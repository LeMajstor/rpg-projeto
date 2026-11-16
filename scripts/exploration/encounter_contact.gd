extends RefCounted
## Contato no chão: volumes provisórios iguais ao volume lógico do líder.
## Primeiro impacto de um segmento contra um círculo, sem depender de frames.
static func fraction(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
	var offset = from - center
	var c = offset.length_squared() - radius * radius
	if c <= 0:
		return 0.0
	var movement = to - from
	var a = movement.length_squared()
	if a <= 0:
		return INF
	var b = offset.dot(movement)
	var discriminant = b * b - a * c
	if discriminant < 0:
		return INF
	var t = (-b - sqrt(discriminant)) / a
	return t if t >= 0 and t <= 1 else INF
