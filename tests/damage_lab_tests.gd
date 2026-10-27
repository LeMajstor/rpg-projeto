extends SceneTree
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Battle = preload("res://scripts/combat/battle_model.gd")
var data: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func config() -> Dictionary:
	var model = Model.new(data)
	model.attacker["physical_attack"] = 90 # Bronze +10 mantém a referência efetiva 100 da fórmula.
	var result = model.configuration()
	result["settings"]["variation_enabled"] = false
	result["settings"]["critical_mode"] = "off"
	result["target"]["physical_defense"] = 100
	return result

func _run() -> void:
	for test in [_test_formula, _test_critical, _test_batches, _test_validation, _test_model_and_isolation]:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("LAB DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_formula() -> void:
	var test = config()
	expect(Calculator.validate(test).is_empty(), "Configuração padrão válida")
	expect(Calculator.sample(test, 0, 0)["damage"] == 50, "Ataque 100 e defesa 100 produzem 50 com potência 1")
	test["target"]["physical_defense"] = 0
	expect(Calculator.sample(test, 0, 0)["damage"] == 100, "Defesa zero preserva dano de referência")
	test["target"]["physical_defense"] = 200
	expect(Calculator.sample(test, 0, 0)["damage"] == 33, "Arredondamento experimental ao inteiro mais próximo")
	test["action"]["power"] = 2.0
	expect(is_equal_approx(Calculator.base_damage(test)["base"], 200.0 / 3.0), "Potência multiplica depois da parcela de defesa")
	for attack in [0, 1, 99, 367, 999]:
		test["attacker"]["physical_attack"] = attack
		var previous = 1e20
		for defense in [0, 1, 99, 500, 999]:
			test["target"]["physical_defense"] = defense
			var sample = Calculator.sample(test, 1, 1)
			expect(is_finite(sample["raw"]) and sample["damage"] >= 1, "Extremos e 0/0 não geram NaN nem dano menor que 1")
			expect(sample["raw"] <= previous, "Aumentar defesa nunca aumenta dano")
			previous = sample["raw"]
	test = config()
	test["attacker"]["magic_power"] = 200
	test["target"]["magic_defense"] = 200
	test["action"]["damage_type"] = "magical"
	expect(Calculator.sample(test, 0, 0)["damage"] == 100, "Magia usa MAG e DEF M")
	test["attacker"]["physical_attack"] = 999
	test["target"]["physical_defense"] = 999
	expect(Calculator.sample(test, 0, 0)["damage"] == 100, "Atributos físicos não influenciam a magia")
	test["target"]["hp"] = 7
	var overkill = Calculator.sample(test, 0, 0)
	expect(overkill["damage"] == 100 and overkill["hp_removed"] == 7 and overkill["hp_after"] == 0, "Dano calculado é separado de HP removido")

func _test_critical() -> void:
	var test = config()
	test["settings"]["critical_mode"] = "rolled"
	expect(Calculator.critical_chance(test) == 10.0, "Chance soma CRI convertido e contribuição da arma")
	expect(Calculator.sample(test, 0.5, 0.09)["critical"], "Sorteio abaixo da chance resulta em crítico")
	expect(not Calculator.sample(test, 0.5, 0.10)["critical"], "Limite de comparação do sorteio é explícito")
	test["weapon"]["critical_multiplier"] = 3.0
	expect(Calculator.sample(test, 0.5, 0)["damage"] == 150, "Multiplicador da arma é aplicado ao dano após defesa")
	test["attacker"]["critical_base"] = 99
	expect(Calculator.sample(test, 0.5, 0)["critical_multiplier"] == 3.0, "CRI do personagem nunca altera multiplicador")
	test["settings"]["item_bonus"] = -100.0
	test["settings"]["buff_bonus"] = -100.0
	expect(Calculator.critical_chance(test) == 0 and not Calculator.sample(test, 0, 0)["critical"], "Chance final limitada inferiormente a zero")
	test["settings"]["buff_bonus"] = 100.0
	test["settings"]["item_bonus"] = 100.0
	expect(Calculator.critical_chance(test) == 100 and Calculator.sample(test, 0, 1)["critical"], "Chance de 100% é garantida inclusive na fronteira do RNG")
	test["settings"]["critical_mode"] = "forced"
	test["action"]["critical_allowed"] = false
	expect(not Calculator.sample(test, 0, 0)["critical"], "Modo forçado respeita elegibilidade da ação")
	test["action"]["critical_allowed"] = true
	expect(Calculator.sample(test, 0, 1)["critical"], "Modo forçado permite inspecionar crítico")
	test["settings"]["variation_enabled"] = true
	test["settings"]["critical_mode"] = "off"
	expect(Calculator.sample(test, 0, 0)["damage"] == 45 and Calculator.sample(test, 1, 0)["damage"] == 55, "Variação uniforme ±10% é aplicada depois da defesa")

func _test_batches() -> void:
	var test = config()
	test["settings"]["variation_enabled"] = true
	test["settings"]["critical_mode"] = "rolled"
	var original = test.duplicate(true)
	var first = Calculator.run_batch(test, 1000, 421)
	var repeat = Calculator.run_batch(test, 1000, 421)
	var different = Calculator.run_batch(test, 1000, 733)
	expect(first == repeat, "Mesma semente e configuração reproduzem lote integral")
	expect(first["samples"] != different["samples"], "Outra semente varia resultados")
	var sum_damage = 0
	var sum_removed = 0
	var criticals = 0
	for sample in first["samples"]:
		sum_damage += sample["damage"]
		sum_removed += sample["hp_removed"]
		criticals += int(sample["critical"])
		expect(sample["hp_before"] == test["target"]["hp"] and sample["mp_before"] == test["attacker"]["mp"], "Amostras independentes restauram condições de recursos")
		expect(sample["damage"] >= first["minimum"] and sample["damage"] <= first["maximum"], "Extremos resumidos abrangem cada amostra")
	expect(sum_damage == first["total"] and sum_removed == first["hp_removed_total"], "Totais e HP removido são consistentes")
	expect(is_equal_approx(first["mean"], float(sum_damage) / 1000) and criticals == first["critical_count"], "Média e frequência observada conferem com amostras")
	var bin_count = 0
	for bucket in first["histogram"]:
		bin_count += bucket["count"]
		expect(bucket["count"] == bucket["normal"] + bucket["critical"], "Histograma separa normais e críticos")
	expect(bin_count == 1000, "Histograma não perde amostras")
	expect(test == original, "Cálculo não modifica fichas nem parâmetros")
	for count in [1, 10, 100, 1000]:
		expect(Calculator.run_batch(test, count, 421)["samples"].size() == count, "Todos os tamanhos de lote executam integralmente")
	var ten = Calculator.run_batch(test, 10, 421)
	var next = Calculator.run_batch(test, 10, 421, ten["rng_after"])
	var twenty = first["samples"].slice(10, 20)
	for index in range(10):
		expect(next["samples"][index]["variation_roll"] == twenty[index]["variation_roll"] and next["samples"][index]["critical_roll"] == twenty[index]["critical_roll"], "Continuação usa o estado exato dos dois fluxos")
	var off = test.duplicate(true)
	off["settings"]["critical_mode"] = "off"
	var off_result = Calculator.run_batch(off, 1000, 421)
	for index in range(1000):
		expect(off_result["samples"][index]["variation_factor"] == first["samples"][index]["variation_factor"], "Alterar modo crítico não altera sorteios da variação")
	var all_one = config()
	all_one["attacker"]["physical_attack"] = 0
	var fixed = Calculator.run_batch(all_one, 1000, 0)
	expect(fixed["histogram"].size() == 1 and fixed["minimum"] == 1 and fixed["maximum"] == 1, "Lote constante produz um único intervalo")

func _test_validation() -> void:
	for role in ["attacker", "target"]:
		for stat in Calculator.STATS:
			var reference = config()
			var bounds = Calculator.stat_bounds(reference[role]["side"], stat)
			for invalid in [bounds.x - 1, bounds.y + 1, INF, NAN]:
				var test = config()
				test[role][stat] = invalid
				expect(not Calculator.run_batch(test, 10, 421).get("error", "").is_empty(), "Valores inválidos são recusados antes de consumir RNG")
	var test = config()
	test["attacker"]["critical_base"] = 0
	expect(not Calculator.validate(test).is_empty(), "CRI mínimo é 1")
	test = config()
	test["target"]["hp"] = 0
	expect(not Calculator.validate(test).is_empty(), "Alvo incapacitado não executa amostra")
	test = config()
	test["action"]["mp_cost"] = 999
	expect(not Calculator.validate(test).is_empty(), "MP insuficiente bloqueia lote inteiro")
	test = config()
	test["target"]["side"] = test["attacker"]["side"]
	expect(not Calculator.validate(test).is_empty(), "Sem fogo amigo também no laboratório")
	expect(not Calculator.run_batch(config(), 12, 421).get("error", "").is_empty(), "Tamanho de lote fora das opções é recusado")

func _test_model_and_isolation() -> void:
	var source = data.duplicate(true)
	var model = Model.new(data)
	var first = model.run(10)
	var second = model.run(100)
	expect(first["sequence_start"] == 0 and second["sequence_start"] == 10, "Execuções consecutivas avançam sequência sem repetir semente por golpe")
	model.restart_sequence()
	expect(model.run(10)["samples"] == first["samples"], "Reiniciar sequência reproduz lote inicial")
	model.attacker["physical_attack"] = 367
	model.target["physical_defense"] = 999
	expect(first["snapshot"]["base_stats"]["attacker"]["physical_attack"] == 100 and first["snapshot"]["attacker"]["physical_attack"] == 110, "Histórico preserva cópia dos valores próprios e efetivos")
	model.choose_profile("attacker", "heavy")
	expect(model.attacker["side"] != model.target["side"], "Selecionar atacante inimigo ajusta alvo para lado oposto")
	var old = model.attacker.duplicate(true)
	model.swap_roles()
	expect(model.target == old, "Troca de lados preserva ficha editada")
	model.reset_case()
	expect(model.history.size() == 3 and model.sequence_position == 0, "Restaurar caso preserva histórico e reinicia RNG")
	var game_text = FileAccess.get_file_as_string("res://data/lab.json")
	var battle = Battle.new(JSON.parse_string(game_text))
	battle.start(battle.default_preset_index(), false, 421)
	var baseline = battle.actors().duplicate(true)
	for index in range(16):
		model.run(10)
	expect(model.history.size() == int(data["settings"]["history_limit"]), "Histórico tem retenção limitada")
	expect(data == source and FileAccess.get_file_as_string("res://data/lab.json") == game_text and battle.actors() == baseline, "Laboratório não modifica dados nem instância do combate atual")
