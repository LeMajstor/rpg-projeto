extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const BOW_IDS = ["compound_bow", "bow_oak", "bow_ash", "bow_yew", "bow_ancient", "bow_runic"]
const TRAJE_IDS = ["leather_set", "leather_reinforced", "leather_hunting", "leather_scout", "leather_ranger", "leather_runic"]
const ATTACK = [10, 15, 22, 31, 44, 58]
const DEFENSE = [5, 8, 12, 17, 24, 33]
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
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original_data = data.duplicate(true)
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var model = Model.new(data)
	var path = "/private/tmp/rpg-equipment-scales-%d.json" % OS.get_process_id()
	var library = Library.new(data, path)
	var first = model.ally().duplicate(true)
	expect(data["weapons"].size() == 12 and data["armors"].size() == 12, "Seis itens de cada família, sem slots vazios")
	for index in range(6):
		for category in ["weapon", "armor"]:
			var id: String = BOW_IDS[index] if category == "weapon" else TRAJE_IDS[index]
			var item = model.definition("weapons" if category == "weapon" else "armors", id)
			expect(not item.is_empty() and Equipment.can_equip(recipe["actor"], item, category), "Cada estágio é válido para segundo aliado")
			expect(not Equipment.can_equip(first, item, category) and not model.choose_equipment(category, id).is_empty(), "Nenhum estágio é permitido ao primeiro aliado")
			item.erase("allowed_character_ids")
			expect(not Equipment.can_equip(first, item, category), "Remover metadados não libera estágio para outro personagem")
			var illegal = model.preset_payload("ally")
			illegal.merge({"id": "test", "name": "Inválido", "revision": 1})
			illegal["equipment"][category] = item
			expect(not Library.validate_entry(illegal, data).is_empty(), "Preset não permite estágio exclusivo no primeiro aliado")
			var bonus: String = "attack_bonus" if category == "weapon" else "defense_bonus"
			expect(item[bonus] == (ATTACK[index] if category == "weapon" else DEFENSE[index]), "Curva de bônus aprovada em cada estágio")
			expect((item["critical_chance"] == 12 and item["critical_multiplier"] == 1.6) if category == "weapon" else item["evasion_bonus"] == 5, "Secundários constantes em todos os estágios")
	expect(model.apply_preset({"id": "initial", "revision": 1, "side": "ally", "name": recipe["name"], "actor": recipe["actor"], "equipment": recipe["equipment"]}).is_empty(), "Preset inicial permanece compatível")
	var own = model.ally().duplicate(true)
	var ids: Array[String] = []
	for weapon_index in range(6):
		for armor_index in range(6):
			var rng = model.rng_state.duplicate()
			expect(model.choose_equipment("weapon", BOW_IDS[weapon_index]).is_empty() and model.choose_equipment("armor", TRAJE_IDS[armor_index]).is_empty(), "Seleciona qualquer combinação arco/traje")
			expect(model.rng_state == rng and model.ally() == own, "Troca preserva atributos próprios e RNG")
			var config = model.configuration()
			expect(Calculator.validate(config).is_empty(), "Combinação completa é válida")
			expect(config["attacker"]["ranged_attack"] == 20 + ATTACK[weapon_index] and config["attacker"]["physical_defense"] == 30 + DEFENSE[armor_index] and config["attacker"]["ranged_defense"] == 30 + [10,16,24,34,48,65][armor_index] and config["attacker"]["evasion_base"] == 12, "Composição correta sem acumular equipamentos anteriores")
			expect(Calculator.critical_chance(config) == 19 and Calculator.critical_source(config)["multiplier"] == 1.6, "Crítico preservado em todas as combinações")
			var historical = model.run(10)
			expect(historical["error"].is_empty(), "Lote válido com cada par")
			var report = Export.document(historical)
			expect(report["conditions"]["equipment"]["attacker"]["weapon"]["id"] == BOW_IDS[weapon_index] and report["conditions"]["equipment"]["attacker"]["armor"]["id"] == TRAJE_IDS[armor_index] and report["conditions"]["equipment"]["attacker"]["owner_id"] == "ally_2", "JSON identifica itens e dono corretos")
			var saved = library.create("Par %d-%d" % [weapon_index, armor_index], model.preset_payload("ally"))
			expect(saved["error"].is_empty(), "Grava qualquer par de estágios")
			ids.append(saved["preset"]["id"])
			model.swap_roles()
			config = model.configuration()
			expect(Calculator.validate(config).is_empty() and config["target"]["physical_defense"] == 30 + DEFENSE[armor_index] and config["target"]["evasion_base"] == 12 and not config.has("weapon"), "Inversão mantém proteção no aliado alvo")
			expect(model.run(1)["error"].is_empty() and historical["snapshot"]["equipment"]["attacker"]["armor"]["id"] == TRAJE_IDS[armor_index], "Execução inimiga válida e histórico anterior imutável")
			model.swap_roles()
	var contents = FileAccess.get_file_as_string(path)
	var reopened = Library.new(data, path)
	expect(reopened.load_error.is_empty() and reopened.custom.size() == 36, "Todos os pares persistem entre sessões")
	for index in range(ids.size()):
		expect(model.apply_preset(reopened.get_entry(ids[index])).is_empty(), "Recarrega cada preset salvo")
		var expected_actor = own.duplicate(true)
		expected_actor["name"] = reopened.get_entry(ids[index])["name"]
		expect(model.weapon["id"] == BOW_IDS[index / 6] and model.armor["id"] == TRAJE_IDS[index % 6] and JSON.parse_string(JSON.stringify(model.ally())) == JSON.parse_string(JSON.stringify(expected_actor)), "Recarga recupera os IDs e próprios sem bônus duplicados")
	expect(FileAccess.get_file_as_string(path) == contents, "Leitura não regrava presets")
	# Nomes antigos recebem apenas a apresentação nova; bônus editados continuam editados.
	var legacy = recipe.duplicate(true)
	legacy.merge({"id": "user_legacy", "revision": 7})
	legacy["equipment"]["weapon"]["name"] = "Arco composto"
	legacy["equipment"]["armor"]["name"] = "Conjunto de couro"
	legacy["equipment"]["weapon"]["attack_bonus"] = 13
	legacy["equipment"]["armor"]["defense_bonus"] = 6
	legacy["equipment"]["armor"]["evasion_bonus"] = 4
	var before_legacy = legacy.duplicate(true)
	expect(model.apply_preset(legacy).is_empty(), "IDs originais continuam carregando com nomes antigos")
	expect(model.weapon["name"] == "Arco Composto de Madeira" and model.armor["name"] == "Traje de Couro", "Nome de exibição atualizado por ID")
	expect(model.weapon["attack_bonus"] == 13 and model.armor["defense_bonus"] == 6 and model.armor["evasion_bonus"] == 4 and model.selected_presets["ally"]["revision"] == 7, "Normalização de nomes preserva bônus editados e revisão")
	expect(legacy == before_legacy and data == original_data, "Carga não modifica origem nem catálogo")
	DirAccess.remove_absolute(path)
	print("ESCALAS/EQUIPAMENTOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
