extends RefCounted
## Relatório de uma execução já calculada; não sorteia nem consulta as fichas atuais.
const FORMAT = "rpg.damage_lab.samples"
const VERSION = 2
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const SUMMARY_KEYS = ["count", "minimum", "maximum", "mean", "total", "hp_removed_total", "critical_count", "critical_frequency", "normal_mean", "critical_mean", "chance", "histogram"]

static func document(result: Dictionary) -> Dictionary:
	if not result.get("error", "").is_empty() or result.get("samples", []).is_empty():
		return {}
	var summary: Dictionary = {}
	for key in SUMMARY_KEYS:
		summary[key] = result[key]
	var samples: Array = result["samples"].duplicate(true)
	for sample in samples:
		sample["sequence_index"] = result["sequence_start"] + sample["index"]
	var conditions: Dictionary = result["snapshot"].duplicate(true)
	conditions["settings"]["seed"] = result["seed"]
	return {
		"format": FORMAT,
		"version": VERSION,
		"exported_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"engine_version": Engine.get_version_info()["string"],
		"formula": {
			"id": "proportional_v1", "status": "experimental",
			"physical": "power * physical_attack^2 / (physical_attack + physical_defense)",
			"magical": "power * magic_power^2 / (magic_power + magic_defense)",
			"zero_offense_base": 0, "order": ["base", "variation", "critical_multiplier", "round_nearest", "minimum_1"],
			"critical_chance_percent": "clamp(critical_base * crit_per_point + critical_source.chance_bonus + item_bonus + buff_bonus, 0, 100)",
			"physical_stats": "ally: clamp(own stat + equipped bonus, 0, effective_stat_limit); enemy: direct stats",
			"attribute_ranges": Calculator.attribute_ranges(),
			"variation": "uniform(1 - variation_percent / 100, 1 + variation_percent / 100) when enabled",
			"resources_per_sample": "restore_initial_hp_mp"
		},
		"run": {
			"number": result["run_number"], "seed": result["seed"],
			"sequence_first": result["sequence_start"] + 1,
			"sequence_last": result["sequence_start"] + result["count"],
			# Estados de 64 bits como texto, preservados ao abrir em leitores JavaScript/JSON.
			"rng_before": _rng_text(result["rng_before"]), "rng_after": _rng_text(result["rng_after"])
		},
		"conditions": conditions,
		"summary": summary.duplicate(true), "samples": samples
	}

static func _rng_text(state: Dictionary) -> Dictionary:
	return {"variance": str(state["variance"]), "critical": str(state["critical"])}

static func save(path: String, result: Dictionary) -> Dictionary:
	var payload = document(result)
	if payload.is_empty():
		return {"error": "Execute uma ação ou lote antes de exportar."}
	if path.strip_edges().is_empty():
		return {"error": "Escolha um arquivo de destino."}
	if path.get_extension().to_lower() != "json":
		path += ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": "Não foi possível abrir o destino: " + error_string(FileAccess.get_open_error())}
	file.store_string(JSON.stringify(payload, "\t", false, true) + "\n")
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		return {"error": "Não foi possível gravar o JSON: " + error_string(error)}
	return {"error": "", "path": ProjectSettings.globalize_path(path), "count": payload["summary"]["count"]}
