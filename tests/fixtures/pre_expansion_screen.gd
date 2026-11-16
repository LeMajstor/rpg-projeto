extends "res://scripts/exploration/exploration_test.gd"
## Usa o combate atual sobre o layout histórico; não pertence ao catálogo jogável.
func _new_session() -> void:
	var battle_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	var definitions = preload("res://tests/fixtures/pre_expansion_catalog.gd").load_definitions()
	session = Session.new(CombatData.exploration_definitions(battle_data),definitions["lab_exterior"],definitions)
	camera_reference_size = Vector2(720,480)
	preferred_axis = "x"
