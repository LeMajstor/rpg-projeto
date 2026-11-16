extends SceneTree
const STEP = 1.0 / 120.0
var lab
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	lab._handle_battle_input(event)

func run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -enemy["ini"]
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	expect(not lab.command_buttons[2].disabled, "Itens disponível na V1")
	key(KEY_I)
	expect(lab.menu_kind == "items" and lab.list_buttons.size() == 1, "Lista somente o item aprovado")
	expect(lab.list_buttons[0].text == "Remédio de teste ×3", "Nome e estoque inicial na interface")
	key(KEY_ENTER)
	expect(lab.menu_kind == "target" and lab.aim_item == "remedy_test", "Confirmar abre mira do Remédio")
	expect(lab._target_candidates() == lab.model.party, "Mira permite aliados vivos, incluindo usuário e alvo limpo")
	key(KEY_ESCAPE)
	expect(lab.menu_kind == "items" and lab.model.inventory["remedy_test"] == 3, "Cancelar mira retorna à lista sem consumir")
	# Estado controlado, sem introduzir magia/aplicação/efeito temporal na entrega.
	lab.model.party[0]["affliction"] = {"id": "poison", "elapsed": 3.0}
	key(KEY_ENTER)
	var mp: int = lab.model.party[0]["mp"]
	key(KEY_ENTER)
	expect(not lab.model.action.is_empty() and lab.model.inventory["remedy_test"] == 2, "Confirmação pelo teclado consome uma unidade")
	expect(not lab.model.party[0]["affliction"].is_empty(), "Estado permanece até aplicação")
	for index in range(120):
		if lab.model.action.is_empty():
			break
		lab.model.tick(STEP)
	lab._refresh()
	expect(lab.model.action.is_empty() and lab.model.party[0]["affliction"].is_empty(), "Ação conclui e remove estado controlado")
	expect(lab.model.party[0]["mp"] == mp and lab.model.party[0]["atb"] == 0, "Não gasta MP; consome ação")
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_I)
	expect(lab.list_buttons[0].text == "Remédio de teste ×2", "Lista reflete estoque restante")
	key(KEY_F5)
	expect(lab.model.inventory["remedy_test"] == 3 and lab.menu_kind.is_empty(), "Novo teste repõe estoque e limpa seleção")
	for affliction_id in ["fear", "confusion"]:
		lab.model.debug_ready_allies()
		lab.model.party[0]["affliction"] = {"id": affliction_id}
		lab._refresh()
		key(KEY_1)
		expect(lab.command_buttons[2].disabled, "Aflição bloqueia comando Itens: " + affliction_id)
		key(KEY_I)
		expect(lab.model.selected_id.is_empty() and lab.menu_kind != "items", "Atalho não contorna bloqueio da seleção manual")
		expect(lab.model.action.is_empty() and lab.model.inventory["remedy_test"] == 3, "Não executa uso bloqueado")
		key(KEY_F5)
	# Referência antiga continua com seus próprios consumíveis.
	lab.preset_picker.select(0)
	lab._start(false)
	lab.model.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_I)
	expect(lab.list_buttons.size() == 3 and lab.list_buttons.all(func(button): return not "Remédio de teste" in button.text), "Lista histórica preservada")
	lab.queue_free()
	await process_frame
	print("REMÉDIO V1 UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
