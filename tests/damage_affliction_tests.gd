extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var data: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	call_deferred("_run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	_test_rules_and_resources()
	_test_reproducibility_and_export()
	_test_presets_and_validation()
	print("AFLIÇÕES/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_rules_and_resources() -> void:
	var model = Model.new(data)
	for id in ["poison", "slow", "confusion", "fear"]:
		model.action = model.definition("actions", id)
		model.settings["critical_mode"] = "forced"
		var config = model.configuration()
		var stat = "vigor" if id in ["poison", "slow"] else "intelligence"
		expect(config["action"]["mp_cost"] == 4 and config["action"]["evasion_allowed"] and not config["action"]["critical_allowed"], "Quatro magias: 4MP, EVA permitida e nenhum crítico")
		expect(Calculator.damage_stats(config)["defense_stat"] == stat, "Resistência correta por aflição")
		config["attacker"]["magic_power"] = 100
		config["target"][stat] = 60
		config["target"]["magic_defense"] = 40
		config["target"]["evasion_base"] = 20
		var original = config.duplicate(true)
		var applied = Calculator.sample(config, 0, 0, .2, .499999)
		var resisted = Calculator.sample(config, 1, 0, .2, .5)
		var evaded = Calculator.sample(config, 1, 0, .199999, 0)
		expect(applied["outcome"] == "applied" and resisted["outcome"] == "resisted" and evaded["outcome"] == "evaded", "Fronteiras: EVA primeiro, depois sorteio estritamente abaixo da chance")
		expect(not evaded["affliction"]["tested"] and not evaded["affliction"]["applied"] and not evaded["affliction"]["resisted"], "Esquiva encerra a tentativa sem teste de resistência")
		expect(is_equal_approx(applied["affliction"]["chance"], 50) and is_equal_approx(applied["affliction"]["total_chance"], 40), "Chance condicional50% e por tentativa40% com EVA20")
		for sample in [applied, resisted, evaded]:
			expect(sample["damage"] == 0 and sample["hp_removed"] == 0 and sample["hp_after"] == sample["hp_before"] and not sample["critical"] and sample["mp_before"] - sample["mp_after"] == 4, "Todos os resultados preservam HP, gastam4MP e ignoram crítico/mínimo1")
		expect(config == original, "Amostra não aplica status contínuo nem altera os participantes")
		for pair in [[500,80,20,83.3333333333],[999,80,20,90.9008189263],[999,30,20,95.2335557674],[150,80,20,60.0],[1,899,100,.1],[999,1,1,99.8001998002],[0,80,20,0.0]]:
			config["attacker"]["magic_power"] = pair[0]
			config["target"][stat] = pair[1]
			config["target"]["magic_defense"] = pair[2]
			expect(is_equal_approx(Calculator.application_chance(config), pair[3]), "Curva aprovada, sem pisos/tetos artificiais")
		config["attacker"]["magic_power"] = 20
		config["target"][stat] = 10
		config["target"]["physical_defense"] = 9999
		config["target"]["ranged_defense"] = 9999
		config["target"]["magic_defense"] = 10
		config["target"]["intelligence" if stat == "vigor" else "vigor"] = 999
		expect(Calculator.application_chance(config) == 50, "DEF F/D e a resistência específica não escolhida não afetam aplicação")
		config["target"]["magic_defense"] = 30
		expect(is_equal_approx(Calculator.application_chance(config),100.0/3), "Aumentar DEF M reduz aplicação nas quatro magias")
		config["target"]["evasion_base"] = 100
		expect(Calculator.sample(config,0,0,1,0)["evaded"], "EVA100 impede a aplicação mesmo com sorteio favorável")
		config["action"]["evasion_allowed"] = false
		expect(Calculator.sample(config,0,0,0,0)["affliction"]["applied"], "Permissão por magia ignora EVA mas mantém teste de resistência")
		expect(Calculator.sample(config,0,0,0,1)["affliction"]["resisted"], "Ignorar EVA não garante aplicação")
	model.action = model.definition("actions", "magic_skill")
	model.action["critical_allowed"] = true
	var magic = model.configuration()
	expect(not Calculator.sample(magic,0,0,1)["critical"] and Calculator.critical_chance(magic) == 0, "Magia de dano também respeita regra de crítico apenas físico")

func _test_reproducibility_and_export() -> void:
	var model = Model.new(data)
	model.action = model.definition("actions", "poison")
	model.attacker["magic_power"] = 20
	model.target["vigor"] = 20
	model.target["magic_defense"] = 20
	model.target["evasion_base"] = 25
	var batch = model.run(1000)
	expect(batch["applied_count"] + batch["resisted_count"] + batch["evasion_count"] == 1000, "Três resultados exclusivos cobrem todas as tentativas")
	expect(batch["total"] == 0 and batch["hp_removed_total"] == 0 and batch["critical_count"] == 0 and batch["normal_count"] == 0, "Lote não fabrica dano, crítico ou acertos normais")
	expect(absf(batch["application_frequency"] - 25.0) < 5 and is_equal_approx(batch["total_application_chance"],25.0), "Frequência observada coerente com EVA25 e resistência DEF M20+VIG20")
	var bins = 0
	for bin in batch["histogram"]: bins += bin["count"]
	expect(bins == 1000, "Histograma por resultado conserva contagens")
	model.restart_sequence()
	expect(model.run(1000)["samples"] == batch["samples"], "Mesma configuração/semente reproduz aplicações e resistências")
	model.restart_sequence()
	model.run(10)
	var next = model.run(10)
	for i in range(10):
		expect(next["samples"][i]["affliction"] == batch["samples"][i+10]["affliction"], "Lotes consecutivos preservam fluxo exato de aflição")
	var report = Export.document(batch)
	expect(report["version"] == 5 and report["formula"]["id"] == "affliction_application_v2" and not "minimum_1" in report["formula"]["order"] and report["formula"].has("affliction") and report["conditions"]["target"]["vigor"] == 20 and report["summary"]["applied_count"] == batch["applied_count"], "JSONv5 contém regra, resistência e estatísticas")
	var restored: Dictionary = {}
	for stream in report["run"]["rng_after"]:
		restored[stream] = report["run"]["rng_after"][stream].to_int()
	expect(restored.has("affliction") and Calculator.run_batch(batch["snapshot"],10,batch["seed"],restored) == Calculator.run_batch(batch["snapshot"],10,batch["seed"],batch["rng_after"]), "Quarto RNG exportado como texto permite retomada exata")
	model.target["vigor"] = 999
	model.target["evasion_base"] = 0
	model.restart_sequence()
	var changed = model.run(1000)
	for i in range(1000):
		for roll in ["variation_roll", "critical_roll", "evasion_roll"]:
			expect(changed["samples"][i][roll] == batch["samples"][i][roll], "Editar resistência/EVA não altera fluxos antigos")
		expect(changed["samples"][i]["affliction"]["roll"] == batch["samples"][i]["affliction"]["roll"], "Editar ficha não altera sorteios da aflição")
	expect(batch["snapshot"]["target"]["vigor"] == 20 and batch["snapshot"]["target"]["evasion_base"] == 25, "Histórico preserva condições anteriores")
	model.target["evasion_base"] = 100
	model.restart_sequence()
	var blocked = model.run(10)
	expect(blocked["evasion_count"] == 10 and blocked["hit_count"] == 0 and blocked["application_hit_frequency"] == 0, "Lote totalmente esquivado não divide por zero nem conta resistência")
	model.set_seed(733)
	model.target["evasion_base"] = 25
	expect(model.run(10)["samples"][0]["affliction"]["roll"] != batch["samples"][0]["affliction"]["roll"], "Semente diferente muda o fluxo de aflição")

func _test_presets_and_validation() -> void:
	var path = "/private/tmp/rpg-affliction-presets-%d.json" % OS.get_process_id()
	var model = Model.new(data)
	var legacy = {"id":"user_legacy_affliction", "name":"Aliado #1", "side":"ally", "revision":2, "actor":model.attacker.duplicate(true), "equipment":{"weapon":model.weapon.duplicate(true), "armor":model.armor.duplicate(true)}}
	legacy["actor"].erase("intelligence")
	legacy["actor"].erase("vigor")
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":Library.FORMAT,"version":Library.VERSION,"presets":[legacy]}))
	file.close()
	var original_file = FileAccess.get_file_as_string(path)
	var library = Library.new(data,path)
	expect(library.load_error.is_empty() and model.apply_preset(library.custom[0]).is_empty(), "Preset legado recebe atributos novos ao carregar")
	expect(model.ally()["intelligence"] == 20 and model.ally()["vigor"] == 25 and library.custom[0]["revision"] == 2 and FileAccess.get_file_as_string(path) == original_file, "Referência primeiro20/25 sem regravar arquivo ou revisão")
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	recipe["id"] = "user_second_affliction"
	expect(model.apply_preset(recipe).is_empty() and model.ally()["intelligence"] == 20 and model.ally()["vigor"] == 20, "Referência segundo20/20")
	expect(model.enemy()["intelligence"] == 15 and model.enemy()["vigor"] == 20, "Referência monstro15/20")
	model.ally()["intelligence"] = 37
	model.ally()["vigor"] = 41
	var saved = library.create("Resistência editada",model.preset_payload("ally"))
	library = Library.new(data,path)
	expect(saved["error"].is_empty() and model.apply_preset(library.get_entry(saved["preset"]["id"])).is_empty() and model.ally()["intelligence"] == 37 and model.ally()["vigor"] == 41, "Salvar/reabrir conserva INT/VIG personalizados")
	model.swap_roles()
	expect(model.target["intelligence"] == 37 and model.target["vigor"] == 41, "Inversão mantém os atributos no participante")
	model.action = model.definition("actions","fear")
	for role in ["attacker", "target"]:
		for stat in ["intelligence", "vigor"]:
			expect(Calculator.stat_bounds(model.configuration()[role]["side"],stat) == Vector2i(1,999), "INT/VIG1..999 nos dois lados")
			for invalid in [0,1000,-1,.5,NAN,INF]:
				var config = model.configuration()
				config[role][stat] = invalid
				expect(not Calculator.run_batch(config,10,421)["error"].is_empty(), "Atributo inválido recusado antes dos sorteios")
	var config = model.configuration()
	config["action"]["power"] = 1
	expect(not Calculator.validate(config).is_empty(), "Recorte recusa aflição combinada com dano")
	config = model.configuration()
	config["action"]["resistance_stat"] = "magic_defense"
	expect(not Calculator.validate(config).is_empty(), "Resistência não autorizada recusada")
	model.attacker["mp"] = 3
	var before_rng = model.rng_state.duplicate()
	var history_size = model.history.size()
	expect(not model.run(10)["error"].is_empty() and model.rng_state == before_rng and model.history.size() == history_size, "MP insuficiente não gasta RNG nem adiciona histórico")
	DirAccess.remove_absolute(path)
