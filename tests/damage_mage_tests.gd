extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const STAFFS = ["staff_wood", "staff_oak", "staff_ash", "staff_yew", "staff_ancient", "staff_runic"]
const ROBES = ["robe_simple", "robe_sewn", "robe_embroidered", "robe_enchanted", "robe_arcane", "robe_runic"]
const MAIN = [10,16,24,34,48,65]
const MINOR = [2,3,5,7,10,13]
var checks = 0
var failures = 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func same_exported(a: Variant, b: Variant) -> bool:
	# JSON decimaliza doubles; tolerar apenas a precisão perdida no relatório salvo.
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a)-float(b)) <= 1e-12 * maxf(1.0,absf(float(b)))
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same_exported(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in range(a.size()):
			if not same_exported(a[i],b[i]): return false
		return true
	return a == b

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_03.json"))
	var entry = recipe.duplicate(true)
	entry.merge({"id":"user_mage_test", "revision":1})
	var model = Model.new(data)
	var first = model.ally().duplicate(true)
	var second: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))["actor"]
	expect(model.apply_preset(entry).is_empty(), "Ficha do mago válida")
	expect(model.configuration()["attacker"]["magic_power"] == 40 and model.configuration()["attacker"]["magic_defense"] == 40, "MAG/DEF M naturais30 +10 =40")
	expect(model.configuration()["attacker"]["physical_defense"] == 18 and model.configuration()["attacker"]["ranged_defense"] == 18 and model.configuration()["attacker"]["physical_attack"] == 14, "Defesas naturais16+2, contato12+2")
	expect(model.ally()["hp"] == 30 and model.ally()["ini"] == 7 and model.ally()["mp"] == 24 and model.ally()["vigor"] == 15 and model.ally()["evasion_base"] == 3, "Direção de fragilidade e recursos preservada")
	# D118: críticos físicos modestos; dano normal, chance e magias preservados.
	model.enemy()["physical_defense"] = 40
	model.enemy()["evasion_base"] = 3
	model.action = model.definition("actions","basic")
	model.settings["critical_mode"] = "off"
	var crit_config = model.configuration()
	expect(Calculator.sample(crit_config,0,0,1)["damage"] == 3 and Calculator.sample(crit_config,1,0,1)["damage"] == 4, "Normal do cajado permanece3–4")
	model.settings["critical_mode"] = "forced"
	crit_config = model.configuration()
	expect(Calculator.sample(crit_config,0,0,1)["damage"] == 5 and Calculator.sample(crit_config,1,0,1)["damage"] == 6, "Crítico1,5× do cajado é5–6")
	model.settings["critical_mode"] = "rolled"
	expect(Calculator.critical_chance(model.configuration()) == 3, "Chance física continua3%")
	var physical = model.run(1000)
	var physical_report = Export.document(physical)
	expect(physical_report["conditions"]["equipment"]["attacker"]["weapon"]["critical_multiplier"] == 1.5 and physical_report["conditions"]["critical_source"]["multiplier"] == 1.5, "Histórico/JSON identificam1,5×")
	for action_id in ["poison","slow","confusion","fear","magic_skill"]:
		model.action = model.definition("actions",action_id)
		model.restart_sequence()
		var current = model.run(1000)
		var old_config = model.configuration()
		old_config["equipment"]["attacker"]["weapon"]["critical_multiplier"] = 2.0
		old_config["weapon"]["critical_multiplier"] = 2.0
		var old_magic_batch = Calculator.run_batch(old_config,1000,421)
		expect(current["samples"] == old_magic_batch["samples"] and current["critical_count"] == 0, "Multiplicador físico não muda magia/aflições")
	model.reset_case()
	model.apply_preset(entry)
	var own = model.ally().duplicate(true)
	var path = "/private/tmp/rpg-mage-%d.json" % OS.get_process_id()
	var library = Library.new(data,path)
	for wi in range(6):
		for ai in range(6):
			var rng = model.rng_state.duplicate()
			expect(model.choose_equipment("weapon",STAFFS[wi]).is_empty() and model.choose_equipment("armor",ROBES[ai]).is_empty(), "Seleciona par de estágios independentes")
			model.action = model.definition("actions","basic")
			var config = model.configuration()
			expect(Calculator.validate(config).is_empty() and model.ally() == own and model.rng_state == rng, "Troca não altera base/RNG")
			expect(config["attacker"]["magic_power"] == 30+MAIN[wi] and config["attacker"]["magic_defense"] == 30+MAIN[ai], "Composição mágica sem acumular estágios")
			expect(config["attacker"]["physical_attack"] == 12+MINOR[wi] and config["attacker"]["physical_defense"] == 16+MINOR[ai] and config["attacker"]["ranged_defense"] == 16+MINOR[ai] and config["attacker"]["evasion_base"] == 3, "Secundários físicos e EVA constantes")
			expect(Calculator.critical_chance(config) == 3 and Calculator.critical_source(config)["multiplier"] == 1.5 and Equipment.attack_mode(model.weapon) == "melee", "Crítico apenas físico e cajado de contato")
			for category in ["weapon","armor"]:
				var item: Dictionary = model.weapon.duplicate(true) if category == "weapon" else model.armor.duplicate(true)
				item.erase("allowed_character_ids")
				expect(not Equipment.can_equip(first,item,category) and not Equipment.can_equip(second,item,category), "Exclusividade canônica mesmo sem metadados")
			var saved = library.create("Mago %d-%d" % [wi,ai],model.preset_payload("ally"))
			expect(saved["error"].is_empty(), "Salva qualquer par")
			var loaded = Library.new(data,path).get_entry(saved["preset"]["id"])
			expect(model.apply_preset(loaded).is_empty() and model.configuration()["attacker"]["magic_power"] == 30+MAIN[wi], "Reabre par sem duplicar bônus")
			model.ally()["name"] = own["name"]
			for action_id in ["magic_skill","poison","slow","confusion","fear"]:
				model.action = model.definition("actions",action_id)
				model.restart_sequence()
				var result = model.run(10)
				expect(result["error"].is_empty() and result["critical_count"] == 0, "Magia/aflição usa equipamento e não tem crítico")
				var historical = result.duplicate(true)
				var report = Export.document(result)
				expect(report["conditions"]["base_stats"]["attacker"]["magic_power"] == 30 and report["conditions"]["composition"]["attacker"]["bonuses"]["magic_power"] == MAIN[wi], "JSON separa MAG própria e bônus")
				model.restart_sequence()
				expect(model.run(10)["samples"] == result["samples"], "Reprodução por semente")
				model.swap_roles()
				var reverse = model.configuration()
				expect(reverse["target"]["magic_defense"] == 30+MAIN[ai] and reverse["target"]["magic_power"] == 30+MAIN[wi] and not reverse.has("weapon"), "Equipamento mágico acompanha alvo")
				var incoming = model.run(1)
				expect(incoming["error"].is_empty() and historical == result, "Lote invertido mantém histórico imutável")
				model.swap_roles()
	# Testar contribuição de cada bônus, independentemente do outro.
	model.apply_preset(entry)
	model.action = model.definition("actions","poison")
	var chance = Calculator.application_chance(model.configuration())
	model.weapon["magic_attack_bonus"] = 20
	expect(Calculator.application_chance(model.configuration()) > chance, "MAG do cajado aumenta aplicação")
	model.swap_roles()
	chance = Calculator.application_chance(model.configuration())
	model.armor["magic_defense_bonus"] = 20
	expect(Calculator.application_chance(model.configuration()) < chance, "DEF M da veste reduz aplicação inimiga")
	model.ally()["magic_power"] = 999
	model.ally()["magic_defense"] = 999
	var capped = model.configuration()
	expect(capped["target"]["magic_power"] == 999 and capped["target"]["magic_defense"] == 999 and capped["composition"]["target"]["raw_total"]["magic_defense"] == 1019, "Limite efetivo999 preserva soma bruta")
	model.swap_roles()
	model.apply_preset(entry)
	for category in ["weapon","armor"]:
		var field = Equipment.magic_bonus_field(category)
		for invalid in [-1,1000,.5,INF,NAN,"10"]:
			var bad = entry.duplicate(true)
			bad["equipment"][category][field] = invalid
			var before = model.configuration()
			expect(not model.apply_preset(bad).is_empty() and model.configuration() == before, "Bônus inválido recusado sem carga parcial")
			before["equipment"]["attacker"][category][field] = invalid
			expect(not Calculator.validate(before).is_empty(), "Calculadora recusa bônus inválido antes do RNG")
	expect(not model.choose_equipment("weapon","sword_bronze").is_empty() and not model.choose_equipment("armor","leather_set").is_empty(), "Mago não usa famílias anteriores")
	model.reset_case()
	var forged = model.configuration()
	forged["equipment"]["attacker"]["weapon"]["magic_attack_bonus"] = 10
	expect(not Calculator.validate(forged).is_empty(), "Não injeta MAG em espada sem suporte canônico")
	# Compatibilidade real: mesmos quatro RNGs e amostras anteriores, sem regravar biblioteca.
	var baseline_path = "res://artifacts/damage-lab-mage/presets-baseline.json"
	var baseline = FileAccess.get_file_as_string(baseline_path)
	var old = Library.new(data,baseline_path)
	expect(old.load_error.is_empty() and old.custom.size() == 3, "Lê três presets reais legados")
	for index in range(1,17):
		var old_action = ["poison","slow","confusion","fear"][(index-1)%4]
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/aflicoes-presets-defm-2026-10-29/%02d-%s.json" % [index,old_action]))
		model = Model.new(data)
		for role in ["attacker","target"]:
			expect(model.apply_preset(old.get_entry(previous["conditions"]["presets"][role]["id"])).is_empty(), "Recarrega preset real do estudo anterior")
		if model.attacker["side"] != previous["conditions"]["attacker"]["side"]: model.swap_roles()
		model.action = model.definition("actions",old_action)
		model.set_seed(421)
		model.restart_sequence()
		var now = model.run(1000)
		for i in range(1000):
			var expected: Dictionary = previous["samples"][i].duplicate(true)
			expected.erase("sequence_index")
			expect(same_exported(now["samples"][i],expected), "Amostra histórica anterior preservada integralmente na precisão JSON")
	expect(FileAccess.get_file_as_string(baseline_path) == baseline, "Leitura preserva arquivo/revisões anteriores")
	DirAccess.remove_absolute(path)
	print("MAGO: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
