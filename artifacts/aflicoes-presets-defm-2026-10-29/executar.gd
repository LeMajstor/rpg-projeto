extends SceneTree
const Library = preload("res://scripts/damage/damage_presets.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const DIRECTORY = "res://artifacts/aflicoes-presets-defm-2026-10-29"
const SAMPLE_COUNT = 1000
const SEED_VALUE = 421
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func write_json(path: String, document: Variant) -> void:
	var file = FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Abre artefato de resultado: "+path)
	if file == null: return
	if document is Dictionary and document.has("checks"):
		document["checks"] = checks
	file.store_string(JSON.stringify(document,"\t",false,true)+"\n")
	file.close()

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json"))
	var original = FileAccess.get_file_as_string(Library.DEFAULT_PATH)
	var library = Library.new(data)
	check(library.load_error.is_empty(),"Lê presets salvos: "+library.load_error)
	if failures:
		quit(1)
		return
	var rows: Array = []
	var blocked: Array = []
	var inventory: Array = []
	for preset in library.custom:
		inventory.append(preset.duplicate(true))
	for attacker in library.custom:
		for target in library.custom:
			if attacker["id"] == target["id"]: continue
			if attacker["side"] == target["side"]:
				# A regra de lados é validada pelo calculador; não modificar facção para simular aliados se atacando.
				var invalid = Model.new(data).configuration()
				invalid["attacker"] = attacker["actor"].duplicate(true)
				invalid["target"] = target["actor"].duplicate(true)
				var error = Calculator.validate(invalid)
				check("sem fogo amigo" in error,"Mesmo lado bloqueado antes de executar")
				blocked.append({"attacker":attacker["name"],"target":target["name"],"reason":error})
				continue
			for action_id in ["poison","slow","confusion","fear"]:
				var model = Model.new(data)
				check(model.apply_preset(attacker).is_empty(),"Carrega atacante "+attacker["name"])
				check(model.apply_preset(target).is_empty(),"Carrega alvo "+target["name"])
				if model.attacker["side"] != attacker["side"]: model.swap_roles()
				check(model.attacker["name"] == attacker["name"] and model.target["name"] == target["name"],"Sentido correto do confronto")
				model.action = model.definition("actions",action_id)
				model.set_seed(SEED_VALUE)
				model.restart_sequence()
				var result = model.run(SAMPLE_COUNT)
				check(result.get("error","").is_empty(),"Executa lote "+action_id)
				if not result.get("error","").is_empty(): continue
				var snapshot: Dictionary = result["snapshot"]
				var expected_stat = "vigor" if action_id in ["poison","slow"] else "intelligence"
				check(snapshot["action"]["resistance_stat"] == expected_stat and snapshot["action"]["mp_cost"] == 4 and snapshot["action"]["evasion_allowed"],"Regras da magia preservadas")
				check(result["applied_count"]+result["resisted_count"]+result["evasion_count"] == SAMPLE_COUNT,"Contagens exclusivas e completas")
				check(result["total"] == 0 and result["hp_removed_total"] == 0 and result["critical_count"] == 0,"Sem dano/remoção de HP/crítico")
				for sample in result["samples"]:
					check(sample["mp_before"]-sample["mp_after"] == 4 and sample["hp_before"] == sample["hp_after"] and sample["damage"] == 0 and sample["hp_removed"] == 0 and not sample["critical"],"Recursos e recorte por tentativa")
					check(sample["affliction"]["resistance_stat"] == expected_stat and sample["affliction"]["tested"] == not sample["evaded"],"Esquiva anterior à resistência")
					check(sample["affliction"]["magic_defense"] == snapshot["target"]["magic_defense"] and sample["affliction"]["specific_resistance"] == snapshot["target"][expected_stat] and sample["affliction"]["combined_resistance"] == snapshot["target"]["magic_defense"]+snapshot["target"][expected_stat],"Parcelas de DEF M e resistência específica corretas")
				model.restart_sequence()
				check(model.run(SAMPLE_COUNT)["samples"] == result["samples"],"Reprodução integral da mesma semente")
				var index = rows.size()+1
				var file_name = "%02d-%s.json" % [index,action_id]
				check(Export.save(DIRECTORY.path_join(file_name),result)["error"].is_empty(),"Exporta amostras completas JSONv5")
				var row = {"index":index,"attacker_id":attacker["id"],"attacker":attacker["name"],"target_id":target["id"],"target":target["name"],"action_id":action_id,"action":snapshot["action"]["name"],"count":SAMPLE_COUNT,"seed":SEED_VALUE,"magic_power":snapshot["attacker"]["magic_power"],"resistance_stat":expected_stat,"specific_resistance":snapshot["target"][expected_stat],"magic_defense":snapshot["target"]["magic_defense"],"resistance":snapshot["target"][expected_stat]+snapshot["target"]["magic_defense"],"effective_evasion":snapshot["target"]["evasion_base"],"mp_cost":snapshot["action"]["mp_cost"],"attacker_mp":snapshot["attacker"]["mp"],"application_chance":result["application_chance"],"total_application_chance":result["total_application_chance"],"applied_count":result["applied_count"],"resisted_count":result["resisted_count"],"evasion_count":result["evasion_count"],"application_frequency":result["application_frequency"],"application_hit_frequency":result["application_hit_frequency"],"resistance_frequency":result["resistance_frequency"],"evasion_frequency":result["evasion_frequency"],"report":file_name}
				rows.append(row)
				print(attacker["name"]," → ",target["name"]," · ",action_id,": esperado ",snappedf(result["total_application_chance"],.01),"%; observado ",result["application_frequency"],"%; aplicou/resistiu/esquivou ",result["applied_count"],"/",result["resisted_count"],"/",result["evasion_count"])
	check(FileAccess.get_file_as_string(Library.DEFAULT_PATH) == original,"Arquivo pessoal de presets preservado integralmente")
	write_json(DIRECTORY.path_join("execucao.json"),{"seed":SEED_VALUE,"sample_count":SAMPLE_COUNT,"preset_inventory":inventory,"presets_sha256":original.sha256_text(),"presets_file_unchanged":FileAccess.get_file_as_string(Library.DEFAULT_PATH)==original,"rows":rows,"blocked_pairs":blocked,"checks":checks,"failures":failures})
	print("AFLIÇÕES ENTRE PRESETS: ",rows.size()," lotes, ",rows.size()*SAMPLE_COUNT," tentativas; ",blocked.size()," pares bloqueados por lado; ",checks," verificações, ",failures," falhas")
	quit(0 if failures == 0 else 1)
