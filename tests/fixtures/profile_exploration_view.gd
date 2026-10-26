extends "res://scripts/exploration/exploration_view.gd"
## Instrumentação exclusiva de teste, incluindo o custo real do callback de desenho.
var draw_usec = 0
var camera_queries = 0
var last_camera_queries = 0

func _origin() -> Vector2:
	camera_queries += 1
	return super._origin()

func _draw() -> void:
	camera_queries = 0
	var begin = Time.get_ticks_usec()
	super._draw()
	draw_usec = Time.get_ticks_usec() - begin
	last_camera_queries = camera_queries
