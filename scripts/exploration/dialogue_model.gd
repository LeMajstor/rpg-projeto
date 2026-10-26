extends RefCounted
## Grafo de falas reutilizável. Não executa scripts, missões ou efeitos de combate.
var definitions: Dictionary
var opened = false
var speaker = ""
var dialogue_id = ""
var node_id = ""

func _init(data: Dictionary) -> void:
	definitions = data

func start(id: String, name: String) -> bool:
	if opened or not definitions.has(id):
		return false
	var entry: Dictionary = definitions[id]
	var first: String = entry.get("start", "")
	if not entry.get("nodes", {}).has(first):
		return false
	dialogue_id = id
	node_id = first
	speaker = name
	opened = true
	return true

func current() -> Dictionary:
	if not opened:
		return {}
	return definitions[dialogue_id]["nodes"][node_id]

func choices() -> Array:
	return current().get("choices", [])

func advance() -> bool:
	if not opened or not choices().is_empty():
		return false
	return _go(current().get("next", ""))

func choose(index: int) -> bool:
	var options = choices()
	if not opened or index < 0 or index >= options.size():
		return false
	return _go(options[index].get("next", ""))

func _go(next: String) -> bool:
	if next.is_empty():
		opened = false
		node_id = ""
		return true
	if not definitions[dialogue_id]["nodes"].has(next):
		return false
	node_id = next
	return true
