extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Current = preload("res://artifacts/damage-lab-defm/calculator_v1.gd")
const Candidate = preload("res://artifacts/veneno-defm-comparacao-2026-10-28/calculator_proposta.gd")
const Export = preload("res://artifacts/damage-lab-defm/export_v1.gd")
const DIRECTORY = "res://artifacts/veneno-defm-comparacao-2026-10-28"
const SEED_VALUE = 421
const SAMPLE_COUNT = 1000
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func save_json(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(DIRECTORY.path_join(path),FileAccess.WRITE)
	if file == null:
		check(false,"Abre relatório: "+path)
		return
	file.store_string(JSON.stringify(value,"\t",false,true)+"\n")
	file.close()

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original_presets = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var original_calculator = FileAccess.get_file_as_string("res://scripts/damage/damage_calculator.gd")
	var library = Library.new(data)
	check(library.load_error.is_empty(),"Lê biblioteca de presets")
	var attacker: Dictionary = {}
	var target: Dictionary = {}
	for preset in library.custom:
		if preset["name"] == "Monstro #1" and preset["side"] == "enemy": attacker = preset
		if preset["name"] == "Aliado #1" and preset["side"] == "ally": target = preset
	check(not attacker.is_empty() and not target.is_empty(),"Localiza os dois presets reais")
	if failures:
		quit(1)
		return
	var model = Model.new(data)
	check(model.apply_preset(attacker).is_empty(),"Carrega Monstro #1")
	check(model.apply_preset(target).is_empty(),"Carrega Aliado #1")
	if model.attacker["side"] != "enemy": model.swap_roles()
	model.action = model.definition("actions","poison")
	model.set_seed(SEED_VALUE)
	model.restart_sequence()
	var config = model.configuration()
	config["damage_stats"] = Current.damage_stats(config)
	check(config["attacker"]["name"] == "Monstro #1" and config["target"]["name"] == "Aliado #1", "Sentido correto do ataque")
	var current = Current.run_batch(config,SAMPLE_COUNT,SEED_VALUE)
	current["run_number"] = 1
	current["sequence_start"] = 0
	check(current.get("error","").is_empty(),"Executa primeira rodada")
	var candidate = Candidate.run_batch(config,SAMPLE_COUNT,SEED_VALUE)
	check(candidate.get("error","").is_empty(),"Executa segunda rodada experimental")
	if failures:
		quit(1)
		return
	candidate["run_number"] = 2
	candidate["sequence_start"] = 0
	var combined = float(config["target"]["vigor"]) + float(config["target"]["magic_defense"])
	candidate["snapshot"]["damage_stats"]["defense_label"] = "DEF M + VIG"
	candidate["snapshot"]["comparison"] = {"experimental":true,"defense_formula":"magic_defense + vigor","vigor":config["target"]["vigor"],"magic_defense":config["target"]["magic_defense"],"combined_resistance":combined}
	var changed = 0
	for i in range(SAMPLE_COUNT):
		var a: Dictionary = current["samples"][i]
		var b: Dictionary = candidate["samples"][i]
		for key in ["variation_roll","critical_roll","evasion_roll"]:
			check(a[key] == b[key],"Mesmos sorteios antigos por tentativa")
		check(a["affliction"]["roll"] == b["affliction"]["roll"],"Mesmo sorteio de aflição por tentativa")
		check(a["evaded"] == b["evaded"],"EVA idêntica nas duas rodadas")
		check(not b["affliction"]["applied"] or a["affliction"]["applied"],"Adicionar defesa não cria aplicações novas")
		for sample in [a,b]:
			check(sample["damage"] == 0 and sample["hp_removed"] == 0 and sample["hp_before"] == sample["hp_after"] and sample["mp_before"]-sample["mp_after"] == 4 and not sample["critical"],"Recursos preservados e custo4MP")
		b["affliction"]["vigor"] = config["target"]["vigor"]
		b["affliction"]["magic_defense"] = config["target"]["magic_defense"]
		b["affliction"]["combined_resistance"] = combined
		b["affliction"]["resistance_formula"] = "magic_defense + vigor"
		if a["outcome"] != b["outcome"]:
			changed += 1
			check(a["outcome"] == "applied" and b["outcome"] == "resisted", "Mudança apenas de aplicação para resistência")
	check(current["rng_before"] == candidate["rng_before"] and current["rng_after"] == candidate["rng_after"],"Estados RNG iniciais/finais idênticos")
	for result in [current,candidate]:
		check(result["applied_count"]+result["resisted_count"]+result["evasion_count"] == SAMPLE_COUNT,"Contagens completas")
	var first = Export.document(current)
	first["comparison"] = {"round":1,"rule":"current_vigor_only","experimental":false}
	var second = Export.document(candidate)
	second["formula"]["id"] = "affliction_defm_plus_vigor_proposal_v1"
	second["formula"]["affliction"] = "100 * magic_power / (magic_power + target.magic_defense + target.vigor); no probability floor or ceiling"
	second["formula"]["attack_selection"] = "experimental poison application: MAG versus target DEF M + VIG"
	second["formula"]["order"] = ["evasion_check_if_allowed","on_hit_only","MAG_vs_DEF_M_plus_VIG","application_roll_below_chance"]
	second["formula"]["affliction_order"] = second["formula"]["order"].duplicate()
	second["comparison"] = {"round":2,"rule":"proposed_magic_defense_plus_vigor","experimental":true}
	save_json("01-atual-vig-1000x.json",first)
	save_json("02-proposta-defm-vig-1000x.json",second)
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original_presets,"Arquivo pessoal de presets preservado")
	check(FileAccess.get_file_as_string("res://scripts/damage/damage_calculator.gd") == original_calculator,"Calculador do laboratório preservado")
	var rows: Array = []
	for result in [current,candidate]:
		rows.append({"round":rows.size()+1,"count":result["count"],"application_chance":result["application_chance"],"total_application_chance":result["total_application_chance"],"applied_count":result["applied_count"],"resisted_count":result["resisted_count"],"evasion_count":result["evasion_count"],"application_frequency":result["application_frequency"],"application_hit_frequency":result["application_hit_frequency"],"resistance_frequency":result["resistance_frequency"],"evasion_frequency":result["evasion_frequency"]})
	save_json("execucao.json",{"seed":SEED_VALUE,"presets_sha256":original_presets.sha256_text(),"calculator_sha256":original_calculator.sha256_text(),"config":config,"rows":rows,"applications_changed_to_resisted":changed,"presets_unchanged":FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original_presets,"calculator_unchanged":FileAccess.get_file_as_string("res://scripts/damage/damage_calculator.gd")==original_calculator,"checks":checks,"failures":failures})
	print("Monstro MAG ",config["attacker"]["magic_power"]," → Aliado VIG ",config["target"]["vigor"]," / DEF M ",config["target"]["magic_defense"]," / EVA ",config["target"]["evasion_base"])
	for row in rows:
		print("Rodada ",row["round"],": chance após EVA ",row["application_chance"],"%; por tentativa ",row["total_application_chance"],"%; aplicou/resistiu/esquivou ",row["applied_count"],"/",row["resisted_count"],"/",row["evasion_count"],"; observado ",row["application_frequency"],"%")
	print("COMPARAÇÃO: 2.000 tentativas, ",changed," aplicações viraram resistência; ",checks," verificações, ",failures," falhas")
	quit(0 if failures == 0 else 1)
