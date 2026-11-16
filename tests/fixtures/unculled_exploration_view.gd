extends "res://scripts/exploration/exploration_view.gd"
## Referência gráfica: desenha toda a geometria, inclusive fora da câmera.
func _visible_rect(_rect: Rect2) -> bool:
	return true
