extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Policy = preload("res://scripts/damage/damage_action_policy.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab_enemy_02.json"))
	var entry = recipe.duplicate(true)
	entry.merge({"id":"user_enemy02_test","revision":1})
	var model = Model.new(data)
	expect(model.apply_preset(entry).is_empty(),"Novo preset válido")
	for stat in Calculator.STATS:
		expect(model.enemy()[stat] == recipe["actor"][stat],"Atributo direto do novo monstro: "+stat)
	model.choose_action("magic_skill")
	var historical = model.run(10)
	var rng = model.rng_state.duplicate()
	model.swap_roles()
	expect(model.action["id"] == "basic" and model.action["physical_mode"] == "ranged","Inversão ajusta magia anterior para ataque físico à distância")
	expect(model.rng_state == rng and model.history[0] == historical,"Normalizar ação não muda RNG/histórico")
	var config = model.configuration()
	expect(config["damage_stats"]["attack_stat"] == "ranged_attack" and config["damage_stats"]["defense_stat"] == "ranged_defense" and Calculator.validate(config).is_empty(),"Usa ATQ D/DEF D")
	expect(Calculator.critical_chance(config) == 3 and Calculator.critical_source(config)["multiplier"] == 2,"CRI3%/2× do monstro preservados")
	config["action"]["physical_mode"] = "weapon"
	expect(Calculator.damage_stats(config)["mode"] == "ranged" and Calculator.validate(config).is_empty(),"Padrão canônico do inimigo é distância")
	config["action"]["physical_mode"] = "melee"
	config["attacker_policy"] = {}
	config["attacker"]["offensive_policy"] = {}
	expect(not Calculator.validate(config).is_empty(),"Não libera contato forjando metadados")
	for id in ["physical_skill","magic_skill","poison","slow","confusion","fear"]:
		var before = model.action.duplicate(true)
		expect(not model.choose_action(id).is_empty() and model.action == before,"Modelo recusa ação fora do repertório: "+id)
		config = model.configuration()
		config["action"] = model.definition("actions",id)
		expect(not Calculator.validate(config).is_empty(),"Calculadora bloqueia ação proibida: "+id)
	model.restart_sequence()
	var first = model.run(1000)
	model.restart_sequence()
	expect(model.run(1000)["samples"] == first["samples"],"Sequência física reproduzível")
	var report = Export.document(first)
	expect(report["conditions"]["attacker_policy"]["physical_mode"] == "ranged" and report["conditions"]["attacker"]["ini"] == 9,"JSON preserva perfil e INI")
	model.swap_roles()
	for id in ["basic","physical_skill","magic_skill","poison","slow","confusion","fear"]:
		expect(model.choose_action(id).is_empty() and model.run(1)["error"].is_empty(),"Restrição não se aplica ao monstro como alvo: "+id)
	var path = "/private/tmp/rpg-enemy02-%d.json" % OS.get_process_id()
	var library = Library.new(data,path)
	var saved = library.create(recipe["name"],model.preset_payload("enemy"))
	expect(saved["error"].is_empty(),"Salva novo inimigo")
	var contents = FileAccess.get_file_as_string(path)
	var loaded = Library.new(data,path).get_entry(saved["preset"]["id"])
	expect(model.apply_preset(loaded).is_empty() and model.enemy()["id"] == "enemy_ranged","Recarga mantém tipo canônico")
	expect(FileAccess.get_file_as_string(path) == contents,"Ler não regrava")
	model.swap_roles()
	expect(model.action["id"] == "basic" and model.action["physical_mode"] == "ranged","Recarga e inversão mantêm distância")
	var copied = library.create("Cópia renomeada",model.preset_payload("enemy"))
	expect(copied["error"].is_empty() and copied["preset"]["actor"]["id"] == "enemy_ranged","Cópia conserva repertório")
	var old_actor = model.enemy().duplicate(true)
	var payload = model.preset_payload("enemy")
	payload["actor"]["id"] = "heavy"
	expect(not library.update(loaded["id"],payload)["error"].is_empty(),"Atualizar não troca identidade para escapar da restrição")
	model.reset_case()
	model.swap_roles()
	for id in ["basic","magic_skill","poison"]:
		expect(model.choose_action(id).is_empty(),"Monstro #1/manual mantém ferramenta anterior: "+id)
	model.choose_profile("attacker","enemy_ranged")
	expect(model.action["id"] == "basic" and model.action["physical_mode"] == "ranged","Selecionar tipo canônico também normaliza")
	DirAccess.remove_absolute(path)
	print("MONSTRO #2: %d verificações, %d falhas" % [checks,failures])
	quit(0 if failures == 0 else 1)
