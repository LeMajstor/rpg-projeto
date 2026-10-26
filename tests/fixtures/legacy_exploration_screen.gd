extends "res://scripts/exploration/exploration_test.gd"
## Fixture exclusiva de regressão: conserva percursos e casos anteriores à redistribuição.
func _new_session() -> void:
	var battle_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_internal_split.json"))
	session = Session.new(battle_data, definitions["lab_exterior"], definitions)
	preferred_axis = "x"
