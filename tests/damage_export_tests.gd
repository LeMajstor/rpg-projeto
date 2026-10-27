extends SceneTree
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
var checks = 0
var failures = 0
var directory = "/private/tmp/rpg-damage-export-tests-" + str(OS.get_process_id())

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var model = Model.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json")))
	model.set_seed(733)
	for count in [1, 10, 100, 1000]:
		var result = model.run(count)
		var original = result.duplicate(true)
		var rng = model.rng_state.duplicate()
		var history_size = model.history.size()
		var path = directory.path_join("amostras-%d" % count)
		var saved = Export.save(path, result)
		expect(saved["error"].is_empty() and saved["path"] == path + ".json", "Grava UTF-8 com extensão JSON")
		var json = JSON.new()
		expect(json.parse(FileAccess.get_file_as_string(saved["path"])) == OK, "Arquivo pode ser analisado por leitor JSON")
		var data: Dictionary = json.data
		expect(data["format"] == Export.FORMAT and data["version"] == 2 and data["formula"]["id"] == "proportional_v1", "Formato e fórmula são identificados e versionados")
		expect(data["samples"].size() == count and data["summary"]["count"] == count, "Todas as amostras são exportadas")
		expect(data["run"]["seed"] == 733 and data["conditions"]["settings"]["seed"] == 733, "Seed real da execução prevalece sobre o padrão inicial")
		expect(data["conditions"]["target"]["name"] == "Pesado · teste", "Acentos e nomes são preservados")
		var total = 0
		var removed = 0
		var criticals = 0
		for index in range(count):
			var sample: Dictionary = data["samples"][index]
			total += int(sample["damage"])
			removed += int(sample["hp_removed"])
			criticals += int(sample["critical"])
			expect(sample["index"] == index + 1 and sample["sequence_index"] == result["sequence_start"] + index + 1, "Índices local e global da sequência são preservados")
			expect(is_equal_approx(sample["raw"], result["samples"][index]["raw"]) and is_equal_approx(sample["variation_roll"], result["samples"][index]["variation_roll"]), "Dano bruto e sorteios mantêm precisão numérica")
		expect(data["summary"]["total"] == total and data["summary"]["hp_removed_total"] == removed and data["summary"]["critical_count"] == criticals, "Totais do JSON conferem com a tabela exportada")
		expect(data["run"]["sequence_first"] == result["sequence_start"] + 1 and data["run"]["sequence_last"] == result["sequence_start"] + count, "Intervalo exportado corresponde à execução contínua")
		for key in ["variance", "critical"]:
			expect(data["run"]["rng_before"][key] is String and data["run"]["rng_before"][key].to_int() == result["rng_before"][key], "Estado RNG anterior não perde bits na leitura do JSON")
			expect(data["run"]["rng_after"][key].to_int() == result["rng_after"][key], "Estado RNG posterior não perde bits na leitura do JSON")
		expect(result == original and model.rng_state == rng and model.history.size() == history_size, "Exportar não altera resultado, histórico ou sorteios")
		DirAccess.remove_absolute(saved["path"])
	var historical: Dictionary = model.history[1]
	model.attacker["physical_attack"] = 999
	model.action["power"] = 3.0
	var payload = Export.document(historical)
	expect(payload["conditions"]["base_stats"]["attacker"]["physical_attack"] == 100 and payload["conditions"]["attacker"]["physical_attack"] == 110 and payload["conditions"]["action"]["power"] == 1.0, "Exportar histórico preserva condições antigas, mesmo após edição")
	payload["conditions"]["attacker"]["physical_attack"] = 1
	payload["samples"][0]["damage"] = 99999
	payload["summary"]["histogram"][0]["count"] = 0
	expect(historical["snapshot"]["attacker"]["physical_attack"] == 110 and historical["samples"][0]["damage"] != 99999 and historical["histogram"][0]["count"] > 0, "Relatório não compartilha estruturas mutáveis com o histórico")
	expect(not Export.save(directory.path_join("vazio.json"), {}).get("error", "").is_empty() and not FileAccess.file_exists(directory.path_join("vazio.json")), "Resultado vazio não cria arquivo")
	expect(not Export.save("", historical)["error"].is_empty(), "Destino vazio é recusado")
	expect(not Export.save(directory.path_join("inexistente/saida.json"), historical)["error"].is_empty(), "Falha de abertura é informada")
	var maximum = historical.duplicate(true)
	maximum["rng_before"]["variance"] = 9223372036854775807
	expect(Export.document(maximum)["run"]["rng_before"]["variance"] == "9223372036854775807", "Estado inteiro de 64 bits é exportado como texto exato")
	DirAccess.remove_absolute(directory)
	print("EXPORTAÇÃO/DANOS: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
