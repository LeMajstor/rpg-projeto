extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var model = Model.new(definitions)
	model.action = model.definition("actions", "physical_skill")
	model.settings["critical_mode"] = "forced"
	model.target["evasion_base"] = 100
	var config = model.configuration()
	var original = config.duplicate(true)
	var dodged = Calculator.sample(config, 0, 0, 1)
	expect(dodged["evaded"] and dodged["damage"] == 0 and dodged["raw"] == 0 and not dodged["critical"], "EVA 100 evita até crítico forçado; não aplica mínimo 1")
	expect(dodged["hp_after"] == dodged["hp_before"] and dodged["hp_removed"] == 0, "Esquiva preserva HP")
	expect(dodged["mp_before"] - dodged["mp_after"] == 4 and config == original, "Esquiva consome MP da ação sem modificar configuração")
	config["target"]["evasion_base"] = 0
	expect(not Calculator.sample(config, 0, 0, 0)["evaded"], "EVA 0 não esquiva nem no limite inferior do RNG")
	config["attacker"]["physical_attack"] = 0
	expect(Calculator.sample(config, 0, 0, 0)["damage"] == 1, "Acerto continua respeitando mínimo 1")
	config = model.configuration()
	config["target"]["evasion_base"] = 25
	expect(Calculator.sample(config, 0, 0, 0.249)["evaded"] and not Calculator.sample(config, 0, 0, 0.25)["evaded"], "Comparação percentual tem fronteira explícita")
	model.action = model.definition("actions", "magic_skill")
	expect(not model.run(1)["samples"][0]["evaded"], "Magia inicial ignora EVA 100")
	model.settings["item_bonus"] = 100
	model.settings["buff_bonus"] = 100
	expect(Calculator.evasion_chance(model.configuration()) == 0, "Modificadores existentes de CRI não alteram EVA ou permissão da magia")
	model.action["evasion_allowed"] = true
	expect(Calculator.evasion_chance(model.configuration()) == 100, "Bônus de crítico não são somados à EVA do alvo")
	model.settings["item_bonus"] = 0
	model.settings["buff_bonus"] = 0
	expect(model.run(1)["samples"][0]["evaded"], "Permissão em dados permite experimentar esquiva na magia")
	model.action["evasion_allowed"] = false
	expect(model.run(1)["evasion_chance"] == 0, "Desligar permissão zera chance efetiva, preservando EVA própria")
	model.swap_roles()
	model.target["evasion_base"] = 100
	model.attacker["evasion_base"] = 0
	model.action = model.definition("actions", "basic")
	expect(model.run(1)["samples"][0]["evaded"], "Aliado alvo usa sua EVA, independente de EVA do atacante")
	model.swap_roles()
	model.target["evasion_base"] = 100
	model.restart_sequence()
	var all_evaded = model.run(1000)
	expect(all_evaded["evasion_count"] == 1000 and all_evaded["hit_count"] == 0 and all_evaded["critical_count"] == 0 and all_evaded["normal_count"] == 0, "Lote todo evitado separa esquivas, acertos e críticos")
	expect(all_evaded["minimum"] == 0 and all_evaded["maximum"] == 0 and all_evaded["mean"] == 0 and all_evaded["normal_mean"] == 0 and all_evaded["critical_hit_frequency"] == 0, "Lote sem acertos produz estatísticas finitas em zero")
	expect(all_evaded["histogram"].size() == 1 and all_evaded["histogram"][0]["evaded"] == 1000 and all_evaded["histogram"][0]["normal"] == 0, "Histograma classifica esquiva separada de dano normal")
	model.target["evasion_base"] = 25
	model.settings["critical_mode"] = "rolled"
	model.restart_sequence()
	var mixed = model.run(1000)
	model.restart_sequence()
	var repeated = model.run(1000)
	repeated["run_number"] = mixed["run_number"]
	expect(repeated == mixed, "Reinício reproduz amostras, resumo e estados com nova identificação")
	var hits = 0
	var normal_total = 0
	var normal_count = 0
	for sample in mixed["samples"]:
		expect(not (sample["evaded"] and sample["critical"]), "Esquiva nunca conta como crítico")
		if not sample["evaded"]:
			hits += 1
			if not sample["critical"]:
				normal_count += 1
				normal_total += sample["damage"]
	expect(mixed["evasion_count"] > 0 and hits > 0 and mixed["hit_count"] == hits and mixed["normal_count"] == normal_count, "Lote misto apresenta contagens consistentes")
	expect(is_equal_approx(mixed["normal_mean"], float(normal_total) / normal_count), "Média normal exclui esquivas")
	for bin in mixed["histogram"]:
		expect(bin["count"] == bin["normal"] + bin["critical"] + bin["evaded"], "Categorias do histograma somam o total")
	model.restart_sequence()
	var ten = model.run(10)
	var next = model.run(10)
	for i in range(10):
		for field in ["evasion_roll", "critical_roll", "variation_roll", "evaded", "damage"]:
			expect(next["samples"][i][field] == mixed["samples"][i + 10][field], "Continuação preserva três fluxos e resultado")
	model.target["evasion_base"] = 0
	model.restart_sequence()
	var no_evade = model.run(1000)
	for i in range(1000):
		for field in ["critical_roll", "variation_roll", "evasion_roll"]:
			expect(no_evade["samples"][i][field] == mixed["samples"][i][field], "Alterar EVA não muda os fluxos independentes")
	var report = Export.document(mixed)
	expect(report["version"] == 5 and report["summary"]["evasion_count"] == mixed["evasion_count"] and report["conditions"]["target"]["evasion_base"] == 25, "JSON v5 conserva EVA e estatísticas históricas")
	var restored: Dictionary = {}
	for stream in report["run"]["rng_after"]:
		restored[stream] = report["run"]["rng_after"][stream].to_int()
	var resumed = Calculator.run_batch(mixed["snapshot"], 10, mixed["seed"], restored)
	var direct = Calculator.run_batch(mixed["snapshot"], 10, mixed["seed"], mixed["rng_after"])
	expect(resumed["samples"] == direct["samples"] and restored.has("evasion"), "Estados exportados permitem continuar exatamente os três fluxos")
	for invalid in [-1, 101, 0.5, INF, NAN]:
		model.target["evasion_base"] = invalid
		var state = model.rng_state.duplicate()
		var history_size = model.history.size()
		expect(not model.run(10)["error"].is_empty() and model.rng_state == state and model.history.size() == history_size, "EVA inválida não consome RNG ou histórico")
	model.target["evasion_base"] = 0
	model.action["evasion_allowed"] = "sim"
	expect(not model.run(1)["error"].is_empty(), "Permissão inválida é rejeitada")
	model.reset_case()
	var path = "/private/tmp/rpg-evasion-presets-%d.json" % OS.get_process_id()
	var library = Library.new(definitions, path)
	model.ally()["evasion_base"] = 17
	var saved = library.create("Teste EVA", model.preset_payload("ally"))
	var reloaded = Library.new(definitions, path)
	expect(saved["error"].is_empty() and reloaded.get_entry(saved["preset"]["id"])["actor"]["evasion_base"] == 17, "Salvar e reabrir preset preserva EVA própria")
	model.apply_preset(reloaded.get_entry(saved["preset"]["id"]))
	model.ally()["evasion_base"] = 18
	expect(model.preset_modified("ally"), "Editar EVA marca preset como alterado")
	var updated = reloaded.update(saved["preset"]["id"], model.preset_payload("ally"))
	expect(updated["error"].is_empty() and Library.new(definitions, path).custom[0]["actor"]["evasion_base"] == 18, "Atualizar preset também persiste a EVA editada")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	legacy["presets"][0]["actor"].erase("evasion_base")
	var legacy_text = JSON.stringify(legacy)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(legacy_text)
	file.close()
	reloaded = Library.new(definitions, path)
	expect(reloaded.load_error.is_empty() and reloaded.custom.size() == 1 and reloaded.custom[0]["actor"]["evasion_base"] == 0, "Preset antigo sem EVA migra em memória para zero")
	expect(FileAccess.get_file_as_string(path) == legacy_text, "Leitura não sobrescreve arquivo antigo")
	expect(model.apply_preset(legacy["presets"][0]).is_empty() and model.ally()["evasion_base"] == 0, "Aplicação direta aceita preset legado com EVA zero")
	DirAccess.remove_absolute(path)
	print("ESQUIVA/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
