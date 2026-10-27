extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
var directory = "/private/tmp/rpg-damage-presets-tests-%d" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func write(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _run() -> void:
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var supplied: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_presets.json"))
	var original = supplied.duplicate(true)
	var path = directory.path_join("presets.json")
	var library = Library.new(definitions, supplied, path)
	expect(library.load_error.is_empty() and library.references.size() == 2 and not FileAccess.file_exists(path), "Carregar referências não cria arquivo pessoal vazio")
	var model = Model.new(definitions)
	var settings = model.settings.duplicate(true)
	var action = model.action.duplicate(true)
	model.run(10)
	var rng = model.rng_state.duplicate()
	var sequence = model.sequence_position
	var enemy_before = model.enemy().duplicate(true)
	var ally_reference = library.get_entry("initial_ally_bronze")
	var enemy_reference = library.get_entry("initial_enemy_30")
	expect(model.apply_preset(ally_reference).is_empty() and model.enemy() == enemy_before, "Preset aliado não altera monstro")
	expect(model.ally()["hp"] == 40 and model.ally()["physical_attack"] == 20 and model.weapon["attack_bonus"] == 10 and model.armor["defense_bonus"] == 10, "Referência inicial guarda próprios e equipamentos Bronze")
	var ally_before = model.ally().duplicate(true)
	expect(model.apply_preset(enemy_reference).is_empty() and model.ally() == ally_before, "Preset monstro não altera aliado")
	expect(model.enemy()["hp"] == 30 and model.enemy()["physical_attack"] == 23 and model.enemy()["physical_defense"] == 60, "Referência monstro reúne os dois testes iniciais")
	expect(model.configuration()["attacker"]["physical_attack"] == 30 and model.configuration()["attacker"]["physical_defense"] == 30, "Totais são recalculados sem somar bônus duas vezes")
	expect(model.settings == settings and model.action == action and model.rng_state == rng and model.sequence_position == sequence, "Carregar preserva ação, parâmetros e sequência")
	model.settings["critical_mode"] = "off"
	var historical = model.run(10).duplicate(true)
	expect(historical["minimum"] >= 9 and historical["maximum"] <= 11 and not historical["snapshot"]["presets"]["attacker"]["modified"], "Referências reproduzem dano físico estudado e identificam origem")
	model.ally()["physical_attack"] = 23
	model.ally()["mp"] = 0
	model.ally()["unarmed_critical_multiplier"] = 2.2
	model.weapon["attack_bonus"] = 17
	model.weapon["critical_chance"] = 7.5
	model.weapon["critical_multiplier"] = 3.1
	model.armor["defense_bonus"] = 12
	expect(model.preset_modified("ally"), "Edição não sobrescreve a referência, mas é identificada")
	var payload = model.preset_payload("ally")
	rng = model.rng_state.duplicate()
	var saved = library.create("  Meu aliado · Bronze  ", payload)
	expect(saved["error"].is_empty() and FileAccess.file_exists(path), "Salvar como cria arquivo persistente e normaliza nome")
	var id: String = saved["preset"]["id"]
	expect(saved["preset"]["name"] == "Meu aliado · Bronze" and saved["preset"]["revision"] == 1 and library.is_custom(id), "Preset pessoal tem identidade/revisão próprias")
	var disk = Library.new(definitions, supplied, path)
	var restored = disk.get_entry(id)
	expect(disk.load_error.is_empty() and restored["actor"]["physical_attack"] == 23 and restored["equipment"]["weapon"]["attack_bonus"] == 17, "Reabrir preserva ficha e bônus editados")
	expect(restored["equipment"]["weapon"]["critical_chance"] == 7.5 and restored["equipment"]["weapon"]["critical_multiplier"] == 3.1 and restored["equipment"]["armor"]["defense_bonus"] == 12, "Chance, multiplicador e armadura personalizados persistem")
	model.apply_preset(restored)
	expect(model.configuration()["attacker"]["physical_attack"] == 40 and model.configuration()["attacker"]["physical_defense"] == 32 and model.ally()["physical_attack"] == 23, "Carregar recupera valores próprios, não valores efetivos antigos")
	expect(not model.preset_modified("ally") and model.rng_state == rng, "Aplicar pessoal limpa marca de alteração sem consumir sorteio")
	var custom_history = model.run(10).duplicate(true)
	model.ally()["hp"] = 55
	var updated = disk.update(id, model.preset_payload("ally"))
	expect(updated["error"].is_empty() and updated["preset"]["revision"] == 2 and disk.custom.size() == 1, "Atualizar mantém ID e avança revisão sem duplicar preset")
	model.apply_preset(updated["preset"])
	var exported = Export.document(custom_history)
	expect(exported["conditions"]["presets"]["attacker"]["revision"] == 1 and exported["conditions"]["attacker"]["hp"] == 40, "Histórico/JSON mantêm revisão e valores anteriores à atualização")
	expect(model.configuration()["presets"]["attacker"]["revision"] == 2 and model.ally()["hp"] == 55, "Próximo teste usa revisão atualizada")
	var content = FileAccess.get_file_as_string(path)
	expect(not disk.update("initial_ally_bronze", payload)["error"].is_empty() and FileAccess.get_file_as_string(path) == content, "Atualizar não modifica referências protegidas")
	expect(not disk.create("meu aliado · bronze", payload)["error"].is_empty() and FileAccess.get_file_as_string(path) == content, "Nome duplicado não sobrescreve personalizado")
	for name in ["", "   ", "a".repeat(81)]:
		expect(not disk.create(name, payload)["error"].is_empty(), "Nome vazio ou longo é recusado")
	var enemy_payload = model.preset_payload("enemy")
	enemy_payload["actor"]["hp"] = 9999
	enemy_payload["actor"]["magic_power"] = 9999
	var enemy_saved = library.create("Meu aliado · Bronze", enemy_payload)
	expect(enemy_saved["error"].is_empty(), "Categorias independentes permitem o mesmo nome")
	var concurrent = disk.create("Outro monstro", enemy_payload)
	updated = library.update(id, model.preset_payload("ally"))
	expect(updated["error"].is_empty() and not library.get_entry(concurrent["preset"]["id"]).is_empty() and library.custom.size() == 3, "Releitura antes de gravar preserva novos presets de outra janela")
	model.swap_roles()
	var ally_state = model.ally().duplicate(true)
	var weapon_state = model.weapon.duplicate(true)
	model.apply_preset(enemy_saved["preset"])
	expect(model.attacker["side"] == "enemy" and model.attacker["hp"] == 9999 and model.ally() == ally_state and model.weapon == weapon_state, "Seleção segue categoria ao inverter lados e respeita faixa 9999")
	expect(model.configuration()["presets"]["attacker"]["id"] == enemy_saved["preset"]["id"] and model.configuration()["presets"]["target"]["id"] == id, "Origem dos presets acompanha papéis no snapshot")
	var invalid = enemy_saved["preset"].duplicate(true)
	invalid["actor"]["hp"] = 10000
	var actor_state = model.attacker.duplicate(true)
	expect(not model.apply_preset(invalid).is_empty() and model.attacker == actor_state, "Preset inválido não é aplicado parcialmente")
	invalid = enemy_saved["preset"].duplicate(true)
	invalid["equipment"] = payload["equipment"]
	expect(not Library.validate_entry(invalid, definitions).is_empty(), "Preset de monstro não pode equipar arma/armadura")
	invalid = restored.duplicate(true)
	invalid["equipment"]["weapon"]["id"] = "sword_wood"
	expect(not Library.validate_entry(invalid, definitions).is_empty(), "Item fora do catálogo é recusado")
	model.reset_case()
	expect(model.selected_presets.is_empty() and not Library.new(definitions, supplied, path).get_entry(id).is_empty(), "Restaurar caso não apaga personalizados em disco")
	model.apply_preset(ally_reference)
	model.apply_preset(enemy_reference)
	model.choose_profile("attacker", "ally_2")
	expect(not model.selected_presets.has("ally") and model.selected_presets.has("enemy"), "Seleção manual da ficha limpa só a origem substituída")
	var good = FileAccess.get_file_as_string(path)
	write(path, "{json inválido")
	var broken = Library.new(definitions, supplied, path)
	expect(not broken.load_error.is_empty() and broken.entries("ally").size() == 1, "Arquivo inválido mantém referências disponíveis")
	expect(not broken.create("Recuperação", payload)["error"].is_empty() and FileAccess.get_file_as_string(path) == "{json inválido", "Erro de leitura não sobrescreve arquivo original")
	write(path, good)
	var blocker = directory.path_join("arquivo")
	write(blocker, "preservar")
	var impossible = Library.new(definitions, supplied, blocker.path_join("presets.json"))
	expect(not impossible.create("Teste", payload)["error"].is_empty() and impossible.custom.is_empty() and FileAccess.get_file_as_string(blocker) == "preservar", "Falha de escrita não altera arquivo existente ou confirma preset")
	var copy = library.get_entry("initial_ally_bronze")
	copy["actor"]["hp"] = 1
	expect(library.get_entry("initial_ally_bronze")["actor"]["hp"] == 40 and supplied == original, "Referências e retorno da biblioteca não compartilham estado mutável")
	var disk_data = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(disk_data["format"] == Library.FORMAT and disk_data["presets"].size() == 3, "Arquivo pessoal é separado e contém somente personalizados")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(blocker)
	DirAccess.remove_absolute(directory)
	print("PRESETS/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
