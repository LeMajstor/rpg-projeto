extends RefCounted
## Fotografias de cinco áreas para regressões que dependem das coordenadas antigas.
static func load_definitions() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/areas_before_dungeon_expansion.json"))
