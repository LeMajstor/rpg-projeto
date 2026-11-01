extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const DIRECTORY = "res://artifacts/monstro-fisico-tres-aliados-2026-11-01"
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
				trials.append({"trial":trials.size()+1,"attempts":attempts,"hits":hits,"criticals":crits,"evasions":evades,"last_damage":sample["damage"],"last_critical":sample["critical"],"steps":steps})
				attempt_histogram[str(attempts)] = int(attempt_histogram.get(str(attempts),0))+1
				hit_histogram[str(hits)] = int(hit_histogram.get(str(hits),0))+1
				steps = []
				remaining = hp
				attempts = 0
				hits = 0
				crits = 0
				evades = 0
				if trials.size() == TRIALS: break
	return {"normal_only":normal_only,"seed":seed_value,"trial_count":trials.size(),"hp":hp,"trials":trials,"attempt_histogram":attempt_histogram,"hit_histogram":hit_histogram,"attempts_used":total_attempts,"hits_used":total_hits,"mean_attempts":float(total_attempts)/TRIALS,"mean_hits":float(total_hits)/TRIALS,"generated_samples":generated,"unused_final_buffer":generated-total_attempts,"rng_after_generated_buffer":Export._rng_text(rng),"pool_hashes":pool_hashes,"config":config}

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var library = Library.new(data)
	check(library.load_error.is_empty(),"Biblioteca válida")
	var monster: Dictionary = {}
	var allies: Array = []
	for preset in library.custom:
		if preset["side"] == "enemy" and preset["name"] == "Monstro #1": monster = preset
	for character_id in ["ally_1","ally_2","ally_3"]:
		var matches = library.custom.filter(func(p): return p["side"] == "ally" and p["actor"].get("character_id") == character_id)
		check(matches.size() == 1,"Uma ficha para cada aliado da comparação")
		if matches.size() == 1: allies.append(matches[0])
	check(not monster.is_empty() and allies.size() == 3,"Monstro #1 e três aliados encontrados")
	if failures:
		quit(1)
		return
	var rows: Array = []
	var survival_rows: Array = []
	var inventory: Array = [monster]+allies
	for mode in ["melee","ranged"]:
		for target in allies:
			for seed_value in SEEDS:
				var model = Model.new(data)
				check(model.apply_preset(monster).is_empty() and model.apply_preset(target).is_empty(),"Carrega presets sem edição")
				if model.attacker["side"] != "enemy": model.swap_roles()
				model.action = model.definition("actions","basic")
				model.action["physical_mode"] = mode
				model.settings["critical_mode"] = "rolled"
				model.settings["variation_enabled"] = true
				model.settings["variation_percent"] = 10.0
				model.settings["item_bonus"] = 0
				model.settings["buff_bonus"] = 0
				model.set_seed(seed_value)
				model.restart_sequence()
				var result = model.run(1000)
				check(result.get("error","").is_empty(),"Executa mil ataques físicos")
				if not result.get("error","").is_empty(): continue
				var config: Dictionary = result["snapshot"]
				check(config["attacker"]["name"] == "Monstro #1" and config["target"]["name"] == target["name"],"Sentido correto")
				check(config["action"]["mp_cost"] == 0 and Calculator.critical_chance(config) == 3 and Calculator.critical_source(config)["multiplier"] == 2,"Ataque básico/CRI3%/multiplicador2×")
				for sample in result["samples"]:
					check(sample["mp_before"] == sample["mp_after"] and sample["hp_before"]-sample["hp_after"] == sample["hp_removed"],"Recursos por amostra")
					check((not sample["critical"] and sample["damage"] == 0) if sample["evaded"] else sample["damage"] >= 1,"Esquiva impede crítico/dano")
				model.restart_sequence()
				check(model.run(1000)["samples"] == result["samples"],"Reprodução integral por semente")
				var filename = "%s-%s-seed-%d.json" % [target["actor"]["character_id"],mode,seed_value]
				check(Export.save(DIRECTORY.path_join(filename),result)["error"].is_empty(),"Exporta JSON completo")
				rows.append({"target":target["name"],"character_id":target["actor"]["character_id"],"mode":mode,"seed":seed_value,"report":filename,"count":result["count"],"total":result["total"],"mean":result["mean"],"normal_count":result["normal_count"],"critical_count":result["critical_count"],"evasion_count":result["evasion_count"],"critical_hit_frequency":result["critical_hit_frequency"]})
				for normal_only in [true,false]:
					var observed = survival(config,seed_value,normal_only)
					check(not observed.is_empty(),"Simula sobrevivência")
					if observed.is_empty(): continue
					var survival_file = "%s-%s-seed-%d-survival-%s.json" % [target["actor"]["character_id"],mode,seed_value,"normal" if normal_only else "mixed"]
					write_json(DIRECTORY.path_join(survival_file),observed)
					survival_rows.append({"target":target["name"],"character_id":target["actor"]["character_id"],"mode":mode,"seed":seed_value,"normal_only":normal_only,"report":survival_file,"trial_count":observed["trial_count"],"mean_attempts":observed["mean_attempts"],"mean_hits":observed["mean_hits"]})
			print("Concluído: ",mode," → ",target["name"],"; cinco sementes, 5.000 golpes e 10.000 sequências de sobrevivência")
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original,"Arquivo pessoal preservado integralmente")
	write_json(DIRECTORY.path_join("execucao.json"),{"presets":inventory,"presets_sha256":original.sha256_text(),"presets_file_unchanged":FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original,"seeds":SEEDS,"shot_rows":rows,"survival_rows":survival_rows,"checks":checks,"failures":failures})
	print("FÍSICO/TRÊS ALIADOS: ",rows.size()*1000," ataques; ",survival_rows.size()*TRIALS," sequências; ",checks," verificações, ",failures," falhas")
	quit(0 if failures == 0 else 1)
