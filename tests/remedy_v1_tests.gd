extends SceneTree
const Battle = preload("res://scripts/combat/battle_model.gd")
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
const STEP = 1.0 / 120.0
var data: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	data = Bridge.extend_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh():
	var battle = Battle.new(data.duplicate(true))
	battle.start(battle.default_preset_index())
	for enemy in battle.enemies:
		enemy["ini_modifier"] = -enemy["ini"]
	return battle

func ready(battle, id: String = "p1") -> void:
	battle.actor_by_id(id)["atb"] = 1.0
	expect(battle.select_actor(id), "Seleciona executor pronto")

func finish(battle) -> void:
	for index in range(120):
		if battle.action.is_empty():
			return
		battle.tick(STEP)
	expect(false, "Animação do item deve concluir")

func rng_snapshot(battle) -> Array:
	var states = [battle.rng.state]
	for key in battle.damage_rngs:
		states.append(battle.damage_rngs[key].state)
	return states

func run() -> void:
	# Fixtures de estado: aplicação, ticks e efeitos das aflições ainda não integrados.
	for affliction_id in ["poison", "slow", "confusion", "fear"]:
		var battle = fresh()
		var target = battle.party[1]
		target["affliction"] = {"id": affliction_id, "source_id": "e1", "elapsed": 2.5}
		target["hp"] = 12
		target["mp"] = 2
		var stats: Dictionary = target["damage_stats"].duplicate(true)
		var base: Dictionary = target["damage_base"].duplicate(true)
		var route: Dictionary = target["route_state"].duplicate(true)
		var before_rng = rng_snapshot(battle)
		ready(battle)
		var mp: int = battle.party[0]["mp"]
		expect(battle.inventory == {"remedy_test": 3}, "Novo teste recebe somente 3 Remédios na V1")
		expect(battle.submit("item", "p2", Vector2.ZERO, "remedy_test"), "Remédio aceita aliado vivo com " + affliction_id)
		expect(battle.inventory["remedy_test"] == 2 and battle.party[0]["mp"] == mp, "Consome uma unidade na confirmação, sem MP")
		expect(target["affliction"]["id"] == affliction_id, "Não cura antes do momento de aplicação")
		while not battle.action.is_empty() and not battle.action["applied"]:
			battle.tick(STEP)
		expect(target["affliction"].is_empty(), "Remove a aflição e suas contagens/origem no impacto")
		expect(target["hp"] == 12 and target["mp"] == 2, "Cura não recupera HP ou MP")
		expect(battle.inventory["remedy_test"] == 2 and rng_snapshot(battle) == before_rng, "Sem consumo duplo, esquiva, resistência ou sorteios")
		finish(battle)
		expect(target["damage_stats"] == stats and target["damage_base"] == base, "Não regrava atributos naturais, equipamentos ou totais")
		expect(target["route_state"] == route and battle.party[0]["visual_offset"] == Vector2.ZERO and battle.party[0]["atb"] == 0, "Retorno, rota e consumo da ação preservados")
	# Autocura disponível somente nas condições aprovadas.
	for affliction_id in ["poison", "slow", "confusion", "fear"]:
		var battle = fresh()
		battle.party[0]["affliction"] = {"id": affliction_id}
		if affliction_id in ["poison", "slow"]:
			ready(battle)
		else:
			battle.party[0]["atb"] = 1.0
			expect(not battle.select_actor("p1"), "Medo/Confusão também impedem seleção manual")
		var accepted = battle.submit("item", "p1", Vector2.ZERO, "remedy_test")
		expect(accepted == (affliction_id in ["poison", "slow"]), "Medo/Confusão bloqueiam o uso; Veneno/Lentidão permitem autocura")
		if accepted:
			finish(battle)
			expect(battle.party[0]["affliction"].is_empty(), "Autocura remove o estado")
		else:
			expect(battle.inventory["remedy_test"] == 3 and battle.party[0]["atb"] == 1 and battle.action.is_empty(), "Comando bloqueado não consome recursos")
	# Alvo limpo consome; alvos inválidos e estoque vazio não executam.
	var battle = fresh()
	ready(battle)
	battle.party[1]["hp"] = 0
	for target_id in ["p2", "e1", "ausente"]:
		expect(not battle.submit("item", target_id, Vector2.ZERO, "remedy_test"), "Rejeita incapacitado/inimigo/inexistente")
	expect(battle.inventory["remedy_test"] == 3, "Recusa preserva estoque")
	battle.party[1]["hp"] = 12
	for index in range(3):
		ready(battle)
		expect(battle.submit("item", "p2", Vector2.ZERO, "remedy_test"), "Permite usar em alvo sem aflição")
		finish(battle)
		expect(battle.inventory["remedy_test"] == 2 - index and battle.party[1]["hp"] == 12, "Uso sem aflição consome item/ação, sem cura de HP")
	ready(battle)
	var before_rng = rng_snapshot(battle)
	expect(not battle.submit("item", "p1", Vector2.ZERO, "remedy_test") and battle.party[0]["atb"] == 1 and rng_snapshot(battle) == before_rng, "Sem estoque, não executa nem consome ação/RNG")
	battle.cancel_selection()
	battle.party[0]["mp"] = 1
	for enemy in battle.enemies:
		enemy["hp"] = 0
	battle._check_end()
	expect(battle.start(battle.default_preset_index(), true) and battle.inventory["remedy_test"] == 0 and battle.party[0]["mp"] == 1, "Próxima luta preserva estoque esgotado e recursos")
	battle.start(battle.default_preset_index(), false)
	expect(battle.inventory == {"remedy_test": 3}, "Novo teste repõe 3 unidades")
	ready(battle)
	before_rng = rng_snapshot(battle)
	battle.cancel_selection()
	expect(battle.inventory["remedy_test"] == 3 and rng_snapshot(battle) == before_rng, "Cancelar antes de confirmar não consome")
	# Referências antigas e exploração conservam seus próprios consumíveis.
	for item_id in ["hp", "mp", "revive"]:
		expect(battle.item_skill(item_id).is_empty(), "Consumível antigo não é disponibilizado na V1")
	battle.start(0)
	expect(not battle.inventory.has("remedy_test") and battle.item_skill("remedy_test").is_empty(), "Legados não recebem item exclusivo da V1")
	var original = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	expect(battle.inventory.keys() == original["items"].keys(), "Estoque legado preserva catálogo original")
	print("REMÉDIO V1: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
