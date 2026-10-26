extends SceneTree
## Exercita os mesmos sinais de botões usados pelo jogador.
var checks = 0
var failures = 0
var lab

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish() -> void:
	for index in range(100):
		lab.model.tick(1.0 / 120.0)
	lab._refresh()

func select_ready(index: int = 0) -> void:
	lab.model.debug_ready_allies()
	lab.cards[index]["button"].pressed.emit()
	expect(lab.model.selected_id == "p%d" % (index + 1), "Botão seleciona aliado pronto")

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	expect(lab.cards.size() == 4, "Interface tem quatro cartões")
	expect(lab.model.party[0]["atb"] < 1.0, "Inicialização real não concede barras prontas")
	expect(not lab.debug_window.visible, "Depuração começa oculta")
	select_ready(3)
	lab.command_buttons[0].pressed.emit()
	expect(lab.aim_id == "attack", "Atacar abre seleção de alvo")
	lab.action_menu.get_child(1).get_child(0).pressed.emit()
	expect(lab.model.action.get("actor_id") == "p4", "Botão de alvo confirma ação do aliado escolhido")
	finish()
	select_ready()
	lab.command_buttons[1].pressed.emit()
	expect(lab.menu_kind == "skills", "Habilidades abre lista")
	lab.action_menu.get_child(0).pressed.emit()
	expect(lab.aim_id == "precise", "Primeira habilidade tem alvo único")
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = lab.board.screen_point(lab.model.enemies[0]["logical_position"])
	lab.board._gui_input(click)
	expect(not lab.model.action.is_empty(), "Clique no campo confirma alvo único")
	finish()
	select_ready()
	lab.command_buttons[1].pressed.emit()
	lab.action_menu.get_child(1).pressed.emit()
	expect(lab.board.aiming_skill.get("target") == "circle", "Área ativa prévia no campo")
	lab.board.target_clicked.emit("", lab.model.enemies[0]["logical_position"])
	expect(not lab.model.action.is_empty(), "Clique fixa centro da área")
	finish()
	select_ready()
	lab.command_buttons[1].pressed.emit()
	lab.action_menu.get_child(2).pressed.emit()
	lab.action_menu.get_child(0).pressed.emit()
	expect(lab.model.action.get("skill", {}).get("target") == "all", "Botão confirma todos os inimigos")
	finish()
	select_ready()
	lab.model.party[1]["hp"] = 10
	lab.command_buttons[2].pressed.emit()
	expect(lab.menu_kind == "items", "Itens abre estoque")
	lab.action_menu.get_child(0).pressed.emit()
	lab.cards[1]["button"].pressed.emit()
	expect(lab.model.action.get("target_id") == "p2", "Cartão do aliado serve como alvo de item")
	finish()
	expect(lab.model.party[1]["hp"] == 75, "Item restaurou HP pelo fluxo da interface")
	lab.mode_picker.item_selected.emit(1)
	expect(lab.model.mode == "Active", "Menu altera modo ATB")
	lab.speed_slider.value = 3.0
	lab._refresh()
	expect(lab.speed_label.text == "3.00×", "Velocidade ajustável visível")
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect(lab.debug_window.visible and "e1" in lab.debug_text.text and "rota" in lab.debug_text.text, "Depuração exibe ATB e rota inimigos")
	lab.debug_window.close_requested.emit()
	lab._refresh()
	expect(not lab.debug_window.visible, "Fechar janela encerra depuração")
	lab.preset_picker.select(1)
	lab._start(false)
	expect(lab.model.preset["id"] == "lab_b", "Novo teste usa preset selecionado")
	select_ready()
	expect(lab.command_buttons[3].disabled, "Fuga desabilitada no preset bloqueado")
	var previous_time = lab.model.simulation_time
	lab._step()
	expect(lab.pause_button.button_pressed, "Passo ativa pausa de depuração")
	expect(lab.model.simulation_time >= previous_time, "Passo executado sem erro")
	lab._cancel()
	expect(lab.model.selected_id.is_empty() and lab.menu_kind.is_empty(), "Cancelar limpa seleção e mira")
	var key = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_2
	lab._unhandled_key_input(key)
	expect(lab.model.selected_id == "p2", "Atalho numérico seleciona aliado pronto")
	key.keycode = KEY_H
	lab._unhandled_key_input(key)
	expect(lab.menu_kind == "skills", "Atalho H abre habilidades")
	print("UI: %d verificações, %d falhas" % [checks, failures])
	lab.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
