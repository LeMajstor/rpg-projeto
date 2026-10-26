extends SceneTree
const Lighting = preload("res://scripts/exploration/day_lighting.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func distance(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), maxf(absf(a.b - b.b), absf(a.a - b.a)))

func _run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/day_lighting.json"))
	expect(Lighting.valid_definition(config), "Paleta real válida")
	var lighting = Lighting.new(config)
	expect(lighting.overlay_at(600).a == 0 and lighting.overlay_at(800).a == 0, "Dia preserva desenho anterior")
	expect(lighting.overlay_at(22 * 60).a > 0 and lighting.overlay_at(22 * 60).a < 0.45, "Noite altera ambiente sem ocultar personagens")
	for minute in range(1440):
		var color = lighting.overlay_at(minute)
		expect(color.a >= 0 and color.a <= 0.4, "Escurecimento limitado para legibilidade")
		expect(distance(lighting.overlay_at(minute - 0.001), lighting.overlay_at(minute + 0.001)) < 0.001, "Sem salto nos limites/virada: %d" % minute)
	expect(distance(lighting.overlay_at(1439.999), lighting.overlay_at(0)) < 0.001, "Continuidade à meia-noite")
	expect(lighting.overlay_at(300).a > lighting.overlay_at(360).a and lighting.overlay_at(360).a > lighting.overlay_at(420).a, "Amanhecer clareia gradualmente")
	expect(lighting.overlay_at(1020).a < lighting.overlay_at(1080).a and lighting.overlay_at(1080).a < lighting.overlay_at(1140).a, "Entardecer escurece gradualmente")
	var changed = config.duplicate(true)
	changed["keyframes"][3]["minute"] = 480
	var custom = Lighting.new(changed)
	expect(custom.overlay_at(420).a > 0 and custom.overlay_at(480).a == 0, "Limites visuais editáveis em dados independentes")
	for value in [NAN, INF]:
		expect(lighting.overlay_at(value).a == 0, "Consulta inválida não gera cor inválida")
	for mutation in [{"minute": 0}, {"minute": INF}, {"rgba": [0, 0, 0, 2]}, {"rgba": [0, 0, NAN, 1]}, {"rgba": [1, 2]}]:
		var invalid = config.duplicate(true)
		invalid["keyframes"][1].merge(mutation, true)
		expect(not Lighting.valid_definition(invalid), "Paleta inválida recusada")
	print("ILUMINAÇÃO: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
