extends RefCounted
## Relatório de uma execução já calculada; não sorteia nem consulta as fichas atuais.
const FORMAT = "rpg.damage_lab.samples"
const VERSION = 5
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const SUMMARY_KEYS = ["count", "minimum", "maximum", "mean", "total", "hp_removed_total", "critical_count", "critical_frequency", "normal_mean", "critical_mean", "chance", "histogram", "evasion_count", "evasion_frequency", "evasion_chance", "hit_count", "normal_count", "critical_hit_frequency"]

static func document(result: Dictionary) -> Dictionary:
	if not result.get("error", "").is_empty() or result.get("samples", []).is_empty():
		return {}
	var summary: Dictionary = {}
	for key in SUMMARY_KEYS:
		summary[key] = result[key]
	for key in ["result_type", "applied_count", "resisted_count", "application_frequency", "resistance_frequency", "application_hit_frequency", "application_chance", "total_application_chance"]:
		if result.has(key):
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
			"id": "affliction_application_v2" if Calculator.is_affliction(conditions) else "proportional_v1", "status": "experimental",
			"physical": "power * physical_attack^2 / (physical_attack + physical_defense)",
			"ranged": "power * ranged_attack^2 / (ranged_attack + ranged_defense)",
			"attack_selection": "damage: physical_mode selects melee/ranged and magical uses MAG/DEF M; affliction: MAG versus target.magic_defense + action.resistance_stat",
			"magical": "power * magic_power^2 / (magic_power + magic_defense)",
			"affliction": "100 * magic_power / (magic_power + target.magic_defense + target[action.resistance_stat]); no probability floor or ceiling",
			"affliction_resistance": "target.magic_defense + specific VIG/INT; sum is not capped; samples record specific_resistance, magic_defense and combined_resistance",
			"affliction_order": ["evasion_check_if_allowed", "on_hit_only", "MAG_vs_DEF_M_plus_VIG_or_INT", "application_roll_below_chance"],
			"affliction_resources": "zero damage and HP removed; action MP spent on evaded/resisted/applied; no ongoing status simulation",
			"total_application_chance_percent": "(1 - effective_evasion_percent / 100) * application_chance_percent",
			"critical_eligibility": "physical damage only; magical damage and affliction never critical",
			"zero_offense_base": 0, "order": ["evasion_check_if_allowed", "on_hit_only", "MAG_vs_DEF_M_plus_VIG_or_INT", "application_roll_below_chance"] if Calculator.is_affliction(conditions) else ["evasion_check", "on_hit_only", "base", "variation", "critical_multiplier", "round_nearest", "minimum_1"],
			"evasion_stats": "ally: clamp(own evasion_base + equipped armor.evasion_bonus, 0, 100); enemy: direct; missing armor bonus is zero",
			"evasion": "effective target.evasion_base percent when action.evasion_allowed; evaded: zero damage, no critical, action MP still spent",
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
	var result: Dictionary = {}
	for key in state:
		result[key] = str(state[key])
	return result

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
