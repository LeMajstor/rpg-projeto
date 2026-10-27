extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
var definitions: Dictionary

func _initialize() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var model = Model.new(definitions)
	model.attacker["physical_attack"] = 20
	model.attacker["physical_defense"] = 20
	model.target["physical_attack"] = 30
	model.target["physical_defense"] = 35
	model.settings["critical_mode"] = "off"
	model.settings["variation_enabled"] = false
	var before_data = definitions.duplicate(true)
	var expected = [["bronze",10],["iron",16],["steel",24],["mithril",34],["adamant",48],["runic",65]]
	var previous = 0
	for item in expected:
		model.weapon = model.definition("weapons", "sword_" + item[0])
		model.armor = model.definition("armors", "armor_" + item[0])
		var config = model.configuration()
		expect(config["attacker"]["physical_attack"] == 20 + item[1] and config["attacker"]["physical_defense"] == 20 + item[1], "Composição usa bônus de cada material")
		expect(model.attacker["physical_attack"] == 20 and config["base_stats"]["attacker"]["physical_attack"] == 20, "Equipar preserva atributo próprio")
		expect(config["target"]["physical_defense"] == 35 and not config["equipment"].has("target"), "Monstro não recebe equipamento nem bônus")
		var result = model.run(1)
		var attack = 20 + item[1]
		expect(result["samples"][0]["damage"] == maxi(1, roundi(float(attack * attack) / (attack + 35))), "Ataque usa total efetivo na fórmula")
		expect(result["samples"][0]["damage"] > previous, "Progressão física cresce entre materiais")
		previous = result["samples"][0]["damage"]
		model.swap_roles()
		config = model.configuration()
		expect(config["target"]["physical_defense"] == attack and config["equipment"]["target"]["armor"]["id"] == "armor_" + item[0], "Armadura acompanha aliado quando ele vira alvo")
		expect(not config.has("weapon") and not config["equipment"].has("attacker") and config["critical_source"]["kind"] == "innate", "Monstro atacante não possui arma no snapshot")
		result = model.run(1)
		expect(result["samples"][0]["damage"] == maxi(1, roundi(900.0 / (30 + attack))), "Defesa total do aliado reduz dano recebido")
		model.swap_roles()
	model.weapon = model.definition("weapons", "sword_bronze")
	model.armor = model.definition("armors", "armor_iron")
	var physical = model.run(10)
	var rng: Dictionary = model.rng_state.duplicate()
	var position: int = model.sequence_position
	model.weapon["attack_bonus"] = 15
	model.armor["defense_bonus"] = 18
	var preview = model.configuration()
	expect(preview["attacker"]["physical_attack"] == 35 and preview["attacker"]["physical_defense"] == 38, "Bônus podem ser editados para comparar casos")
	expect(model.rng_state == rng and model.sequence_position == position, "Equipar/editar/prever não avança sorteios")
	expect(physical["snapshot"]["equipment"]["attacker"]["weapon"]["attack_bonus"] == 10 and physical["snapshot"]["composition"]["attacker"]["effective"]["physical_attack"] == 30, "Histórico não muda após edição de equipamento")
	var report = Export.document(physical)
	expect(report["version"] == 2 and report["conditions"]["base_stats"]["attacker"]["physical_attack"] == 20 and report["conditions"]["equipment"]["attacker"]["armor"]["defense_bonus"] == 16, "JSON versionado inclui próprios, itens, bônus e totais originais")
	var path = "/private/tmp/rpg-equipment-%d.json" % OS.get_process_id()
	Export.save(path, physical)
	var loaded = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(loaded["conditions"]["composition"]["attacker"]["effective"]["physical_defense"] == 36 and loaded["samples"].size() == 10, "Composição e lote sobrevivem à gravação/leitura JSON")
	DirAccess.remove_absolute(path)
	model.weapon["critical_chance"] = 7.0
	model.weapon["critical_multiplier"] = 3.0
	model.settings["critical_mode"] = "forced"
	var critical = model.run(1)
	expect(critical["chance"] == 12.0 and critical["samples"][0]["critical_multiplier"] == 3.0, "Chance e multiplicador vêm da arma do aliado")
	model.swap_roles()
	model.attacker["critical_base"] = 3
	model.attacker["unarmed_critical_multiplier"] = 2.5
	critical = model.run(1)
	expect(critical["chance"] == 3.0 and critical["samples"][0]["critical_multiplier"] == 2.5, "Crítico próprio do monstro ignora arma do aliado")
	model.swap_roles()
	model.weapon = model.definition("weapons", "none")
	model.armor = model.definition("armors", "none")
	model.attacker["unarmed_critical_multiplier"] = 2.2
	var unarmed = model.run(1)
	expect(unarmed["snapshot"]["attacker"]["physical_attack"] == 20 and unarmed["snapshot"]["attacker"]["physical_defense"] == 20, "Remover equipamento elimina bônus")
	expect(unarmed["chance"] == 5.0 and unarmed["samples"][0]["critical_multiplier"] == 2.2 and unarmed["snapshot"]["critical_source"]["kind"] == "unarmed", "Sem arma usa CRI próprio e parâmetro de teste, sem chance fictícia de item")
	model.weapon = model.definition("weapons", "sword_steel")
	model.armor = model.definition("armors", "armor_mithril")
	model.choose_profile("attacker", "ally_2")
	model.weapon = model.definition("weapons", "sword_bronze")
	model.choose_profile("attacker", "ally_1")
	expect(model.weapon["id"] == "sword_steel" and model.armor["id"] == "armor_mithril", "Cada aliado mantém seu equipamento local ao trocar a seleção")
	model.action["damage_type"] = "magical"
	var magic = model.run(1)
	model.weapon = model.definition("weapons", "sword_runic")
	model.armor = model.definition("armors", "armor_runic")
	var magic_again = model.run(1)
	expect(magic["samples"][0]["damage"] == magic_again["samples"][0]["damage"], "Bônus físicos não alteram MAG/DEF M nem potência da magia")
	model.attacker["physical_attack"] = 999
	model.attacker["physical_defense"] = 999
	preview = model.configuration()
	expect(preview["composition"]["attacker"]["raw_total"]["physical_attack"] == 1064 and preview["attacker"]["physical_attack"] == 999, "Soma e limite efetivo experimental são registrados separadamente")
	expect(Calculator.validate(preview).is_empty(), "Total limitado continua válido na faixa do laboratório")
	model.attacker["physical_attack"] = -1
	expect(not model.run(1)["error"].is_empty(), "Limitar o total não esconde atributo próprio inválido")
	model.attacker["physical_attack"] = 20
	model.weapon["attack_bonus"] = -1
	expect(not model.run(1)["error"].is_empty(), "Bônus negativo inválido não é aceito")
	model.weapon["attack_bonus"] = 0.5
	expect(not model.run(1)["error"].is_empty(), "Bônus fracionário inválido não é arredondado silenciosamente")
	model.reset_case()
	expect(model.armor["id"] == "none" and model.weapon["id"] == definitions["default_weapon"] and model.sequence_position == 0, "Restaurar caso recupera equipamentos padrão e sequência")
	expect(definitions == before_data, "Catálogo não é alterado pelas edições da sessão")
	print("EQUIPAMENTOS/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
