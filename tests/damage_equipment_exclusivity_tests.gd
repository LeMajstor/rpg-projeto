extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
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
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_ally_02.json"))
	var path = "/private/tmp/rpg-exclusivity-%d.json" % OS.get_process_id()
	var model = Model.new(data)
	var library = Library.new(data, path)
	var first = library.create("Aliado #1", model.preset_payload("ally"))["preset"]
	var second = library.create("Aliado #2", recipe)["preset"]
	expect(first["actor"]["id"] == second["actor"]["id"] and Equipment.character_id(first["actor"]) != Equipment.character_id(second["actor"]), "Personagem distinto do modelo de ficha reutilizado")
	for category in ["weapon", "armor"]:
		var item: Dictionary = recipe["equipment"][category].duplicate(true)
		expect(not Equipment.can_equip(first["actor"], item) and Equipment.can_equip(second["actor"], item), "Arco/couro exclusivos do segundo aliado")
		var renamed: Dictionary = first["actor"].duplicate(true)
		renamed["name"] = "Aliado #2"
		expect(not Equipment.can_equip(renamed, item), "Nome não libera equipamento exclusivo")
		item.erase("allowed_character_ids")
		expect(not Equipment.can_equip(first["actor"], item), "Remover restrição da cópia não contorna catálogo canônico")
		var illegal = first.duplicate(true)
		illegal["equipment"][category] = item
		var actor_before = model.ally().duplicate(true)
		var content = FileAccess.get_file_as_string(path)
		expect(not model.apply_preset(illegal).is_empty() and model.ally() == actor_before, "Preset incompatível recusado sem carga parcial")
		expect(not library.create("Inválido", illegal)["error"].is_empty() and FileAccess.get_file_as_string(path) == content, "Salvar não grava equipamento incompatível")
		var original: Dictionary = model.weapon.duplicate(true) if category == "weapon" else model.armor.duplicate(true)
		if category == "weapon": model.weapon = item
		else: model.armor = item
		expect((model.weapon if category == "weapon" else model.armor) == original, "Setter do modelo impede equipamento incompatível")
		expect(not model.choose_equipment(category, item["id"]).is_empty(), "Seleção por ID também recusa equipamento exclusivo")
	var root_weapon = model.configuration()
	root_weapon["weapon"] = recipe["equipment"]["weapon"].duplicate(true)
	expect(not Calculator.validate(root_weapon).is_empty(), "Arma ofensiva isolada também respeita exclusividade")
	# Mesmo acesso direto ao estado não permite executar ação com equipamento inválido.
	for target_ally in [false, true]:
		model.reset_case()
		if target_ally: model.swap_roles()
		var state = model.rng_state.duplicate()
		var history_size = model.history.size()
		model.loadouts["ally_1"]["weapon"] = recipe["equipment"]["weapon"].duplicate(true)
		expect(not model.run(10)["error"].is_empty() and model.rng_state == state and model.history.size() == history_size, "Calculadora bloqueia exclusividade como atacante/alvo antes de sortear")
	model.reset_case()
	expect(model.apply_preset(second).is_empty() and model.weapon["id"] == "compound_bow" and model.armor["id"] == "leather_set", "Segundo aliado continua carregando seu conjunto")
	model.enemy()["physical_defense"] = 40
	var result = model.run(10)
	expect(result["error"].is_empty() and result["chance"] == 19 and result["snapshot"]["attacker"]["evasion_base"] == 12, "Exclusividade não muda números do segundo aliado")
	var report = Export.document(result)
	expect(report["conditions"]["equipment"]["attacker"]["owner_id"] == "ally_2" and report["conditions"]["attacker"]["character_id"] == "ally_2", "Exportação identifica personagem dono, não só template")
	model.choose_profile("attacker", "ally_1")
	expect(model.weapon["id"] == "sword_bronze" and model.armor["id"] == "armor_bronze", "Estado de equipamentos não vaza do segundo para o primeiro")
	model.apply_preset(second)
	model.swap_roles()
	expect(model.configuration()["equipment"]["target"]["owner_id"] == "ally_2" and model.run(1)["error"].is_empty(), "Troca de lados preserva dono e equipamento válido")
	var copy = library.create("Cópia com outro nome", model.preset_payload("ally"))
	expect(copy["error"].is_empty() and Equipment.character_id(copy["preset"]["actor"]) == "ally_2", "Salvar cópia preserva identidade do segundo aliado")
	var disk = Library.new(data, path)
	var loaded = disk.get_entry(copy["preset"]["id"])
	expect(model.apply_preset(loaded).is_empty() and model.weapon["id"] == "compound_bow", "Reabertura/carga da cópia preserva permissão")
	var contents = FileAccess.get_file_as_string(path)
	expect(not library.update(first["id"], recipe)["error"].is_empty() and FileAccess.get_file_as_string(path) == contents, "Atualizar não troca o personagem de um preset")
	var unknown = first.duplicate(true)
	unknown["actor"]["character_id"] = "inventado"
	expect(not model.apply_preset(unknown).is_empty(), "Identidade desconhecida é recusada")
	var legacy = first.duplicate(true)
	legacy["actor"].erase("character_id")
	expect(model.apply_preset(legacy).is_empty() and Equipment.character_id(model.ally()) == "ally_1", "Preset anterior sem identidade explícita mantém primeiro aliado")
	expect(model.choose_equipment("weapon", "sword_iron").is_empty(), "Armas comuns continuam disponíveis")
	model.apply_preset(second)
	expect(not model.choose_equipment("weapon", "sword_bronze").is_empty() and not model.choose_equipment("armor", "armor_bronze").is_empty(), "Segundo aliado recusa espadas e armaduras de metal")
	expect(model.weapon["id"] == "compound_bow" and model.armor["id"] == "leather_set", "Seleção incompatível preserva arco e couro")
	# Nenhum caminho público aceita slots vazios, itens desligados ou categorias trocadas.
	for preset in [first, second]:
		model.apply_preset(preset)
		for category in ["weapon", "armor"]:
			var item: Dictionary = preset["equipment"][category]
			var other: Dictionary = preset["equipment"]["armor" if category == "weapon" else "weapon"]
			for invalid in [{}, {"id": "none", "equipped": false}, other]:
				var original = model.preset_payload("ally")
				if category == "weapon": model.weapon = invalid
				else: model.armor = invalid
				expect(model.preset_payload("ally") == original, "Slot obrigatório recusa item vazio/inadequado e mantém estado")
			var disabled = item.duplicate(true)
			disabled["equipped"] = false
			expect(not Equipment.can_equip(model.ally(), disabled, category), "ID válido com equipped=false não conta como equipamento")
			var bad = preset.duplicate(true)
			bad["equipment"][category] = disabled
			expect(not library.create("Slot desligado", bad)["error"].is_empty() and not model.apply_preset(bad).is_empty(), "Salvar/carregar recusam slot desligado")
			bad["equipment"].erase(category)
			expect(not library.create("Slot ausente", bad)["error"].is_empty() and not model.apply_preset(bad).is_empty(), "Salvar/carregar recusam slot ausente")
			for target_ally in [false, true]:
				model.apply_preset(preset)
				if (model.ally_role() == "target") != target_ally: model.swap_roles()
				var config = model.configuration()
				config["equipment"][model.ally_role()].erase(category)
				expect(not Calculator.validate(config).is_empty(), "Ação recusa slot ausente com aliado atacante ou alvo")
		# Compatibilidade com antigos presets 'none' sem reescrever a ficha recebida.
		var empty = preset.duplicate(true)
		empty["equipment"] = {"weapon": {"id": "none", "equipped": false}, "armor": {"id": "none", "equipped": false}}
		var before_empty = empty.duplicate(true)
		expect(model.apply_preset(empty).is_empty(), "Preset antigo sem equipamento recebe padrões compatíveis")
		expect(model.weapon == Equipment.default_item(model.ally(), "weapon") and model.armor == Equipment.default_item(model.ally(), "armor"), "Compatibilidade preenche ambos os slots para o personagem correto")
		expect(empty == before_empty and model.run(1)["error"].is_empty(), "Conversão não modifica entrada e resulta em ação válida")
		var config = model.configuration()
		config.erase("equipment")
		expect(not Calculator.validate(config).is_empty(), "Calculadora exige conjunto completo de equipamento")
	# O caminho de leitura da biblioteca aplica a mesma compatibilidade em memória.
	var old_file = first.duplicate(true)
	old_file["equipment"]["armor"] = {"id": "none", "equipped": false}
	var legacy_content = JSON.stringify({"format": Library.FORMAT, "version": Library.VERSION, "presets": [old_file]})
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(legacy_content)
	file.close()
	var legacy_library = Library.new(data, path)
	expect(legacy_library.load_error.is_empty() and legacy_library.custom[0]["equipment"]["armor"]["id"] == "armor_bronze", "Biblioteca abre preset legado já com armadura equipada")
	expect(FileAccess.get_file_as_string(path) == legacy_content, "Leitura de compatibilidade preserva arquivo original")
	DirAccess.remove_absolute(path)
	print("EXCLUSIVIDADE: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
