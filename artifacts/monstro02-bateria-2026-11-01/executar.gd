extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const DIRECTORY = "res://artifacts/monstro02-bateria-2026-11-01"
const SEEDS = [421,733,112,2026,31415]
const TRIALS = 1000
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func write_json(path: String, value: Variant) -> void:
	var file = FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Abre artefato")
	if file != null:
		if value is Dictionary and value.has("checks"):
			value["checks"] = checks
		file.store_string(JSON.stringify(value,"" if "survival-" in path else "\t",false,true)+"\n")
		file.close()

func survival(config: Dictionary, seed_value: int, normal_only: bool) -> Dictionary:
	config = config.duplicate(true)
	if normal_only:
		config["settings"]["critical_mode"] = "off"
		config["action"]["evasion_allowed"] = false
	var rng: Dictionary = {}
	var trials: Array = []
	var hp = int(config["target"]["hp"])
	var remaining = hp
	var attempts = 0
	var hits = 0
	var crits = 0
	var evades = 0
	var spent = 0
	var total_attempts = 0
	var total_hits = 0
	var generated = 0
	var attempt_histogram: Dictionary = {}
	var hit_histogram: Dictionary = {}
	var pool_hashes: Array = []
	var steps: Array = []
	while trials.size() < TRIALS:
		# O laboratório restaura recursos por amostra. O observador abaixo acumula
		# damage em HP local; não modifica o modelo nem implementa combate novo.
		var batch = Calculator.run_batch(config,1000,seed_value,rng)
		check(batch.get("error","").is_empty(),"Lote para observação de sobrevivência válido")
		if not batch.get("error","").is_empty(): return {}
		rng = batch["rng_after"]
		generated += 1000
		pool_hashes.append(JSON.stringify(batch["samples"]).sha256_text())
		for sample in batch["samples"]:
			check(spent+int(config["action"]["mp_cost"]) <= int(config["attacker"]["mp"]),"MP suficiente na sequência acumulada")
			spent += int(config["action"]["mp_cost"])
			steps.append([sample["variation_roll"],sample["critical_roll"],sample["evasion_roll"],sample["damage"],sample["critical"],sample["evaded"]])
			attempts += 1
			total_attempts += 1
			hits += int(not sample["evaded"])
			total_hits += int(not sample["evaded"])
			crits += int(sample["critical"])
			evades += int(sample["evaded"])
			remaining = maxi(0,remaining-int(sample["damage"]))
			check(remaining >= 0 and attempts == hits+evades,"Observador acumula dano e conta tentativas/acertos")
			if remaining == 0:
				trials.append({"trial":trials.size()+1,"attempts":attempts,"hits":hits,"criticals":crits,"evasions":evades,"last_damage":sample["damage"],"last_critical":sample["critical"],"steps":steps,"mp_spent":spent,"mp_remaining":int(config["attacker"]["mp"])-spent})
				attempt_histogram[str(attempts)] = int(attempt_histogram.get(str(attempts),0))+1
				hit_histogram[str(hits)] = int(hit_histogram.get(str(hits),0))+1
				steps = []
				remaining = hp
				attempts = 0
				hits = 0
				crits = 0
				evades = 0
				spent = 0
				if trials.size() == TRIALS: break
	return {"normal_only":normal_only,"seed":seed_value,"trial_count":trials.size(),"hp":hp,"trials":trials,"attempt_histogram":attempt_histogram,"hit_histogram":hit_histogram,"attempts_used":total_attempts,"hits_used":total_hits,"mean_attempts":float(total_attempts)/TRIALS,"mean_hits":float(total_hits)/TRIALS,"generated_samples":generated,"unused_final_buffer":generated-total_attempts,"rng_after_generated_buffer":Export._rng_text(rng),"pool_hashes":pool_hashes,"config":config}

var shot_rows: Array = []
var survival_rows: Array = []
var data: Dictionary

func run_case(monster: Dictionary, ally: Dictionary, outgoing: bool, action_id: String, case_id: String) -> void:
	for seed_value in SEEDS:
		var model = Model.new(data)
		check(model.apply_preset(monster).is_empty() and model.apply_preset(ally).is_empty(),"Carrega os dois presets")
		if not outgoing: model.swap_roles()
		check(model.choose_action(action_id).is_empty(),"Ação permitida no repertório")
		model.settings["critical_mode"] = "rolled"
		model.settings["variation_enabled"] = true
		model.settings["variation_percent"] = 10.0
		model.settings["item_bonus"] = 0
		model.settings["buff_bonus"] = 0
		model.set_seed(seed_value)
		model.restart_sequence()
		var result = model.run(1000)
		check(result.get("error","").is_empty(),"Lote válido")
		if not result.get("error","").is_empty(): continue
		var config: Dictionary = result["snapshot"]
		check(config["attacker"]["side"] == ("ally" if outgoing else "enemy"),"Sentido correto")
		if monster["actor"]["id"] == "enemy_ranged" and not outgoing:
			check(config["action"]["id"] == "basic" and config["damage_stats"]["mode"] == "ranged","Novo monstro usa apenas distância")
		for sample in result["samples"]:
			check(sample["mp_before"]-sample["mp_after"] == config["action"]["mp_cost"] and sample["hp_before"]-sample["hp_after"] == sample["hp_removed"],"Recursos por amostra corretos")
		model.restart_sequence()
		check(model.run(1000)["samples"] == result["samples"],"Reprodução exata da semente")
		var filename = "%s-seed-%d.json" % [case_id,seed_value]
		check(Export.save(DIRECTORY.path_join(filename),result)["error"].is_empty(),"Exporta relatório completo")
		shot_rows.append({"case_id":case_id,"enemy":monster["name"],"ally":ally["name"],"ally_id":ally["actor"]["character_id"],"outgoing":outgoing,"action_id":action_id,"mode":config["damage_stats"]["mode"],"seed":seed_value,"report":filename,"count":result["count"],"mean":result["mean"],"total":result["total"],"normal_count":result["normal_count"],"critical_count":result["critical_count"],"evasion_count":result["evasion_count"],"applied_count":result["applied_count"],"resisted_count":result["resisted_count"]})
		if not Calculator.is_affliction(config):
			var conditions: Array = [true,false] if config["action"]["damage_type"] == "physical" else [false]
			for normal_only in conditions:
				var observed = survival(config,seed_value,normal_only)
				check(not observed.is_empty(),"Observação acumulada válida")
				if observed.is_empty(): continue
				var file = "%s-seed-%d-survival-%s.json" % [case_id,seed_value,"normal" if normal_only else "mixed"]
				write_json(DIRECTORY.path_join(file),observed)
				survival_rows.append({"case_id":case_id,"enemy":monster["name"],"ally":ally["name"],"outgoing":outgoing,"action_id":action_id,"seed":seed_value,"normal_only":normal_only,"report":file,"trial_count":observed["trial_count"],"mean_attempts":observed["mean_attempts"],"mean_hits":observed["mean_hits"]})
	print(case_id," concluído: cinco sementes, 5.000 tentativas")

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var library = Library.new(data)
	check(library.load_error.is_empty(),"Biblioteca válida")
	var monsters: Array = []
	for name in ["Monstro #1","Monstro #2 — Distância"]:
		var found = library.custom.filter(func(p): return p["name"] == name and p["side"] == "enemy")
		check(found.size() == 1,"Monstro encontrado sem ambiguidade: "+name)
		if found.size() == 1: monsters.append(found[0])
	var allies: Array = []
	for id in ["ally_1","ally_2","ally_3"]:
		var found = library.custom.filter(func(p): return p["side"] == "ally" and p["actor"].get("character_id") == id)
		check(found.size() == 1,"Aliado encontrado sem ambiguidade")
		if found.size() == 1: allies.append(found[0])
	if failures:
		quit(1)
		return
	for index in range(monsters.size()):
		var monster: Dictionary = monsters[index]
		var prefix = "m%d" % (index+1)
		for ally in allies:
			var id: String = ally["actor"]["character_id"]
			run_case(monster,ally,false,"basic",prefix+"-incoming-"+id)
			run_case(monster,ally,true,"basic",prefix+"-physical-"+id)
			if id == "ally_3":
				for action_id in ["magic_skill","poison","slow","confusion","fear"]:
					run_case(monster,ally,true,action_id,prefix+"-mage-"+action_id)
	check(shot_rows.size() == 110 and survival_rows.size() == 130,"Matriz completa")
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original,"Biblioteca pessoal preservada")
	write_json(DIRECTORY.path_join("execucao.json"),{"presets":monsters+allies,"presets_sha256":original.sha256_text(),"presets_file_unchanged":FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original,"seeds":SEEDS,"shot_rows":shot_rows,"survival_rows":survival_rows,"checks":checks,"failures":failures})
	print("BATERIA MONSTRO #2/REFERÊNCIA: ",shot_rows.size()*1000," tentativas; ",survival_rows.size()*TRIALS," sequências; ",checks," verificações, ",failures," falhas")
	quit(0 if failures == 0 else 1)
