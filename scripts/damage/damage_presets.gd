extends RefCounted
## Biblioteca de fichas: referências imutáveis e personalizados persistidos em arquivo separado.
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const FORMAT = "rpg.damage_lab.presets"
const VERSION = 1
const DEFAULT_PATH = "user://damage_lab_presets.json"
var definitions: Dictionary
var references: Array[Dictionary] = []
var custom: Array[Dictionary] = []
var storage_path: String
var load_error = ""

func _init(catalog: Dictionary, supplied: Dictionary, path: String = DEFAULT_PATH) -> void:
	definitions = catalog.duplicate(true)
	storage_path = path
	for preset in supplied.get("presets", []):
		if validate_entry(preset, definitions).is_empty():
			references.append(preset.duplicate(true))
	load_custom()

static func _number(value: Variant, low: float, high: float, whole: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and (not whole or float(value) == floorf(float(value)))

static func _known(entries: Array, id: Variant) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			return entry
	return {}

static func validate_entry(value: Variant, catalog: Dictionary) -> String:
	if not value is Dictionary:
		return "Preset inválido."
	if not value.get("id") is String or value["id"].is_empty():
		return "Identificador de preset inválido."
	if not value.get("name") is String or value["name"].strip_edges().is_empty() or value["name"].length() > 80:
		return "Informe um nome de até 80 caracteres."
	if value.get("side", "") not in ["ally", "enemy"] or not value.get("actor") is Dictionary:
		return "Categoria ou ficha inválida."
	if not _number(value.get("revision", 1), 1, 2147483647, true):
		return "Revisão do preset inválida."
	var actor: Dictionary = value["actor"]
	var profile = _known(catalog["profiles"], actor.get("id"))
	if profile.is_empty() or actor.get("side") != value["side"] or profile["side"] != value["side"]:
		return "Ficha não corresponde à categoria do preset."
	if not actor.get("name") is String or not actor.get("color") is String or not Color.html_is_valid(actor["color"]):
		return "Apresentação da ficha inválida."
	for stat in Calculator.STATS:
		var bounds = Calculator.stat_bounds(value["side"], stat)
		if not _number(actor.get(stat), bounds.x, bounds.y, true):
			return "Atributo do preset fora da faixa: " + stat
	if not _number(actor.get("unarmed_critical_multiplier"), 1, 10):
		return "Multiplicador próprio inválido."
	if value["side"] == "enemy":
		return "Monstros não usam equipamentos." if value.has("equipment") else ""
	if not value.get("equipment") is Dictionary:
		return "Equipamento do aliado ausente."
	for category in ["weapon", "armor"]:
		var item = value["equipment"].get(category)
		if not item is Dictionary:
			return "Equipamento do aliado inválido."
		var original = _known(catalog["weapons" if category == "weapon" else "armors"], item.get("id"))
		if original.is_empty() or item.get("equipped") != original["equipped"] or not item.get("name") is String:
			return "Equipamento não pertence ao catálogo atual."
		var bonus = "attack_bonus" if category == "weapon" else "defense_bonus"
		if not _number(item.get(bonus), 0, 999, true) or (not item["equipped"] and item[bonus] != 0):
			return "Bônus de equipamento inválido."
		if category == "weapon":
			if not _number(item.get("critical_chance"), 0, 100) or not _number(item.get("critical_multiplier"), 1, 10):
				return "Crítico da arma inválido."
			if not item["equipped"] and item["critical_chance"] != 0:
				return "Sem arma não fornece chance de equipamento."
	return ""

func load_custom() -> String:
	load_error = ""
	if not FileAccess.file_exists(storage_path):
		custom = []
		return ""
	var file = FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		load_error = "Não foi possível ler os presets personalizados: " + error_string(FileAccess.get_open_error())
		return load_error
	var parser = JSON.new()
	var parsed = parser.parse(file.get_as_text())
	file.close()
	if parsed != OK or not parser.data is Dictionary:
		load_error = "JSON de presets inválido. O arquivo original foi preservado."
		return load_error
	var data: Dictionary = parser.data
	if data.get("format") != FORMAT or data.get("version") != VERSION or not data.get("presets") is Array:
		load_error = "Formato de presets incompatível. O arquivo original foi preservado."
		return load_error
	var loaded: Array[Dictionary] = []
	var ids: Dictionary = {}
	var names: Dictionary = {}
	for preset in references:
		ids[preset["id"]] = true
		names[preset["side"] + ":" + preset["name"].strip_edges().to_lower()] = true
	for preset in data["presets"]:
		var error = validate_entry(preset, definitions)
		if error.is_empty() and not preset["id"].begins_with("user_"):
			error = "Identificador de preset personalizado inválido."
		if not error.is_empty():
			load_error = error + " O arquivo original foi preservado."
			return load_error
		var name_key = preset["side"] + ":" + preset["name"].strip_edges().to_lower()
		if ids.has(preset["id"]) or names.has(name_key):
			load_error = "Presets personalizados duplicados. O arquivo original foi preservado."
			return load_error
		ids[preset["id"]] = true
		names[name_key] = true
		loaded.append(preset.duplicate(true))
	custom = loaded
	return ""

func entries(side: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in ["reference", "custom"]:
		var group = references if source == "reference" else custom
		for preset in group:
			if preset["side"] == side:
				var entry: Dictionary = preset.duplicate(true)
				entry["source"] = source
				result.append(entry)
	return result

func get_entry(id: String) -> Dictionary:
	for side in ["ally", "enemy"]:
		for entry in entries(side):
			if entry["id"] == id:
				return entry
	return {}

func is_custom(id: String) -> bool:
	return not _known(custom, id).is_empty()

func _persist(candidate: Array[Dictionary]) -> String:
	var absolute = ProjectSettings.globalize_path(storage_path)
	var error = DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if error != OK:
		return "Não foi possível criar a pasta dos presets: " + error_string(error)
	var temporary = absolute + ".%d.%d.tmp" % [OS.get_process_id(), Time.get_ticks_usec()]
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Não foi possível gravar os presets: " + error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify({"format": FORMAT, "version": VERSION, "presets": candidate}, "\t", false, true) + "\n")
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, absolute)
	if error != OK:
		DirAccess.remove_absolute(temporary)
		return "Não foi possível salvar os presets: " + error_string(error)
	custom = candidate.duplicate(true)
	return ""

func create(name: String, payload: Dictionary) -> Dictionary:
	var error = load_custom()
	if not error.is_empty():
		return {"error": error}
	name = name.strip_edges()
	for entry in entries(payload.get("side", "")):
		if entry["name"].strip_edges().to_lower() == name.to_lower():
			return {"error": "Já existe um preset com esse nome nesta categoria. Use outro nome ou Atualizar."}
	var preset = payload.duplicate(true)
	preset["id"] = "user_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	while not get_entry(preset["id"]).is_empty():
		preset["id"] += "_1"
	preset["name"] = name
	preset["revision"] = 1
	error = validate_entry(preset, definitions)
	if not error.is_empty():
		return {"error": error}
	var candidate = custom.duplicate(true)
	candidate.append(preset)
	error = _persist(candidate)
	return {"error": error, "preset": get_entry(preset["id"]) if error.is_empty() else {}}

func update(id: String, payload: Dictionary) -> Dictionary:
	var error = load_custom()
	if not error.is_empty():
		return {"error": error}
	if not is_custom(id):
		return {"error": "Presets de referência são protegidos. Use Salvar como para criar sua cópia."}
	var previous = get_entry(id)
	if payload.get("side") != previous["side"]:
		return {"error": "Não é possível mudar a categoria do preset."}
	var preset = payload.duplicate(true)
	preset["id"] = id
	preset["name"] = previous["name"]
	preset["revision"] = int(previous.get("revision", 1)) + 1
	error = validate_entry(preset, definitions)
	if not error.is_empty():
		return {"error": error}
	var candidate = custom.duplicate(true)
	for index in range(candidate.size()):
		if candidate[index]["id"] == id:
			candidate[index] = preset
	error = _persist(candidate)
	return {"error": error, "preset": get_entry(id) if error.is_empty() else {}}
