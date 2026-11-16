extends RefCounted
## D157: layout/representação anteriores, somente para regressões históricas.
static func load_definitions() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_individual_enemies.json"))
