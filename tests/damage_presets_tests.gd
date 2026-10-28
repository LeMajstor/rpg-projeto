extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Library = preload("res://scripts/damage/damage_presets.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
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
	var original = definitions.duplicate(true)
	var path = directory.path_join("presets.json")
	var library = Library.new(definitions, path)
	expect(library.load_error.is_empty() and library.entries("ally").is_empty() and library.entries("enemy").is_empty() and not FileAccess.file_exists(path), "Biblioteca começa vazia, sem referências ou arquivo pessoal criado")
	expect(definitions["profiles"].size() == 2, "Somente duas fichas manuais, sem catálogo de exemplos antigos")
	var model = Model.new(definitions)
	# Valores distintos exercitam todos os campos, inclusive zero, limites e cinco dígitos.
	var own = {"hp": 45, "mp": 0, "ini": 17, "physical_attack": 23, "physical_defense": 28, "magic_power": 367, "magic_defense": 999, "critical_base": 8, "evasion_base": 19, "unarmed_critical_multiplier": 2.2}
	for stat in own:
		model.ally()[stat] = own[stat]
	model.weapon = model.definition("weapons", "sword_steel")
	model.armor = model.definition("armors", "armor_mithril")
	model.weapon["attack_bonus"] = 17
	model.weapon["critical_chance"] = 7.5
	model.weapon["critical_multiplier"] = 3.1
	model.armor["defense_bonus"] = 12
	var payload = model.preset_payload("ally")
	var saved = library.create("  Meu aliado · defesa  ", payload)
	expect(saved["error"].is_empty() and FileAccess.file_exists(path), "Salvar cria arquivo persistente e normaliza nome")
	var id: String = saved["preset"]["id"]
	expect(saved["preset"]["name"] == "Meu aliado · defesa" and saved["preset"]["actor"]["name"] == "Meu aliado · defesa", "Nome salvo identifica preset e participante")
	var disk = Library.new(definitions, path)
	var restored = disk.get_entry(id)
	for stat in own:
		expect(restored["actor"][stat] == own[stat], "Reabrir preserva campo: " + stat)
	for kind in ["weapon", "armor"]:
		for field in payload["equipment"][kind]:
			expect(restored["equipment"][kind][field] == payload["equipment"][kind][field], "Reabrir preserva equipamento: " + kind + "/" + field)
	var enemy_saved = library.create("Meu aliado · defesa", model.preset_payload("enemy"))
	expect(enemy_saved["error"].is_empty(), "Categorias independentes permitem o mesmo nome")
	var enemy_id: String = enemy_saved["preset"]["id"]
	model.enemy()["hp"] = 99999
	model.enemy()["magic_power"] = 9999
	model.enemy()["evasion_base"] = 25
	expect(model.apply_preset(library.update(enemy_id, model.preset_payload("enemy"))["preset"]).is_empty(), "Atualiza e carrega monstro")
	model.ally()["mp"] = 100
	model.run(10)
	var rng = model.rng_state.duplicate()
	var settings = model.settings.duplicate(true)
	var action = model.action.duplicate(true)
	var sequence = model.sequence_position
	var enemy_before = model.enemy().duplicate(true)
	model.swap_roles()
	expect(model.apply_preset(restored).is_empty() and model.enemy() == enemy_before, "Carrega aliado no papel de alvo sem alterar monstro")
	for stat in own:
		expect(model.ally()[stat] == own[stat], "Carregamento restaura todos os atributos: " + stat)
	expect(model.configuration()["target"]["physical_attack"] == 40 and model.configuration()["target"]["physical_defense"] == 40, "Totais são recalculados sem somar bônus duas vezes")
	expect(not model.preset_modified("ally") and model.settings == settings and model.action == action and model.rng_state == rng and model.sequence_position == sequence, "Carregar mantém parâmetros, ação, RNG e sequência")
	var historical = model.run(10).duplicate(true)
	model.ally()["hp"] = 55
	expect(model.preset_modified("ally"), "Edição marca preset como alterado")
	var updated = disk.update(id, model.preset_payload("ally"))
	expect(updated["error"].is_empty() and updated["preset"]["revision"] == 2 and disk.custom.size() == 2, "Atualizar mantém ID e avança revisão sem duplicação")
	model.apply_preset(updated["preset"])
	var report = Export.document(historical)
	expect(report["conditions"]["presets"]["target"]["revision"] == 1 and report["conditions"]["target"]["hp"] == 45, "Histórico/JSON conservam revisão e atributos anteriores")
	var content = FileAccess.get_file_as_string(path)
	for name in ["", "   ", "a".repeat(81), "meu aliado · defesa"]:
		expect(not disk.create(name, payload)["error"].is_empty() and FileAccess.get_file_as_string(path) == content, "Nome inválido/duplicado não sobrescreve preset")
	var bad = disk.get_entry(enemy_id)
	bad["actor"]["hp"] = 100000
	var current = model.enemy().duplicate(true)
	expect(not model.apply_preset(bad).is_empty() and model.enemy() == current, "Carga inválida não aplica atributos parcialmente")
	bad = disk.get_entry(enemy_id)
	bad["equipment"] = payload["equipment"]
	expect(not Library.validate_entry(bad, definitions).is_empty(), "Monstro não pode ter equipamentos")
	for side in ["ally", "enemy"]:
		var entry = disk.get_entry(id if side == "ally" else enemy_id)
		for stat in Calculator.STATS:
			entry["actor"][stat] = Calculator.stat_bounds(side, stat).y
		var result = disk.update(entry["id"], entry)
		expect(result["error"].is_empty(), "Salvar limites por categoria")
		var reopened = Library.new(definitions, path).get_entry(entry["id"])
		for stat in Calculator.STATS:
			expect(reopened["actor"][stat] == Calculator.stat_bounds(side, stat).y, "Persistência preserva limite de " + side + "/" + stat)
	# Duas instâncias: excluir relê o disco e conserva o novo preset da outra janela.
	var another = disk.create("Outro monstro", model.preset_payload("enemy"))
	var remaining_id: String = another["preset"]["id"]
	expect(library.remove(id).is_empty() and library.get_entry(id).is_empty() and not library.get_entry(remaining_id).is_empty(), "Excluir relê disco e mantém presets criados em outra instância")
	expect(Library.new(definitions, path).entries("ally").is_empty() and Library.new(definitions, path).entries("enemy").size() == 2, "Exclusão persiste sem afetar outra categoria")
	content = FileAccess.get_file_as_string(path)
	expect(not library.remove(id).is_empty() and not library.remove("").is_empty() and FileAccess.get_file_as_string(path) == content, "Excluir inexistente/manual não modifica arquivo")
	expect(report["conditions"]["presets"]["target"]["id"] == id and historical["snapshot"]["target"]["hp"] == 45, "Exclusão não altera histórico ou relatório anterior")
	model.reset_case()
	expect(model.selected_presets.is_empty() and Library.new(definitions, path).custom.size() == 2, "Restaurar caso preserva presets salvos")
	var good = FileAccess.get_file_as_string(path)
	write(path, "{json inválido")
	var broken = Library.new(definitions, path)
	expect(not broken.load_error.is_empty() and broken.custom.is_empty(), "JSON inválido não cria presets fantasmas")
	expect(not broken.create("Teste", payload)["error"].is_empty() and not broken.remove(enemy_id).is_empty() and FileAccess.get_file_as_string(path) == "{json inválido", "Erro de leitura impede gravar/excluir sem sobrescrever arquivo")
	write(path, good)
	expect(library.remove(enemy_id).is_empty() and library.remove(remaining_id).is_empty() and Library.new(definitions, path).custom.is_empty(), "Excluir todos deixa biblioteca vazia ao reabrir")
	var fresh = library.create("Novo após excluir", model.preset_payload("ally"))
	expect(fresh["error"].is_empty(), "Continua permitindo salvar depois de excluir todos")
	var copy = library.get_entry(fresh["preset"]["id"])
	copy["actor"]["hp"] = 1
	expect(library.get_entry(fresh["preset"]["id"])["actor"]["hp"] != 1 and definitions == original, "Biblioteca não compartilha estado mutável com chamador ou dados")
	var blocker = directory.path_join("arquivo")
	write(blocker, "preservar")
	var impossible = Library.new(definitions, blocker.path_join("presets.json"))
	expect(not impossible.create("Teste", payload)["error"].is_empty() and impossible.custom.is_empty(), "Falha de escrita não confirma salvamento")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(blocker)
	DirAccess.remove_absolute(directory)
	print("PRESETS/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
