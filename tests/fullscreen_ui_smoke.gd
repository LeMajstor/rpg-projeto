extends SceneTree
const STEP = 1.0 / 120.0
var lab
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-captures="):
			capture_directory = argument.trim_prefix("--visual-captures=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	if capture_directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)
	if lab.debug_window.visible:
		lab.debug_window.get_texture().get_image().save_png(capture_directory.path_join(name + "-debug.png"))

func policy(actor_index: int, selected_policy: int) -> void:
	lab.fullscreen_actor_picker.select(actor_index)
	lab.fullscreen_actor_picker.item_selected.emit(actor_index)
	lab.fullscreen_policy_picker.select(selected_policy)
	lab.fullscreen_policy_picker.item_selected.emit(selected_policy)

func cast_ally() -> void:
	lab.model.debug_ready_allies()
	lab.cards[0]["button"].pressed.emit()
	lab.command_buttons[1].pressed.emit()
	lab.action_menu.get_child(2).pressed.emit()
	lab.action_menu.get_child(0).pressed.emit()
	expect(lab.model.action.get("motion", {}).get("presentation", "") == "fullscreen", "Fluxo normal de Onda usa apresentação de tela inteira")

func impact() -> bool:
	var guard = 0
	while not lab.model.action.is_empty() and not lab.model.action["applied"] and guard < 240:
		lab.model.tick(STEP)
		guard += 1
	lab._refresh()
	var applied: bool = not lab.model.action.is_empty() and lab.model.action["applied"]
	expect(applied, "Habilidade alcança impacto pela UI")
	return applied

func finish() -> void:
	var guard = 0
	while not lab.model.action.is_empty() and guard < 240:
		lab.model.tick(STEP)
		guard += 1
	lab._refresh()
	expect(guard < 240, "Retorno termina pela UI")

func _run() -> void:
	lab = load("res://scenes/combat_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	lab.preset_picker.select(3)
	lab._start(false)
	for enemy in lab.model.enemies:
		enemy["ini_modifier"] = -float(enemy["ini"])
	lab.debug_button.button_pressed = true
	lab._refresh()
	expect(lab.model.preset["id"] == "lab_fullscreen", "Preset D acessível pelo menu existente")
	expect(lab.fullscreen_actor_picker.item_count == 7, "Editor oferece quatro aliados e três inimigos")
	expect(lab.board.screen_point(lab.model.visual_center()).distance_to(lab.board.size * 0.5) < 0.001, "Centro lógico da apresentação coincide com centro visual do campo")
	policy(0, 2)
	expect(not lab.model.fullscreen_center_enabled(lab.model.party[0]), "Editor desativa centro só no participante escolhido")
	expect(lab.model.fullscreen_center_enabled(lab.model.party[1]), "Outro aliado mantém configuração")
	cast_ally()
	if not impact():
		quit(1)
		return
	expect(lab.model.party[0]["visual_offset"] == Vector2.ZERO, "Forçar imóvel executa Onda no próprio lugar")
	await capture("fullscreen-stationary-ally")
	finish()
	policy(0, 0)
	expect(lab.model.fullscreen_center_enabled(lab.model.party[0]), "Usar padrão remove alteração temporária")
	cast_ally()
	if not impact():
		quit(1)
		return
	var actor = lab.model.party[0]
	expect(actor["logical_position"] + actor["visual_offset"] == lab.model.visual_center(), "Ator chega ao centro na tela")
	expect("tela inteira" in lab.debug_text.text and "true" in lab.debug_text.text, "Depuração informa decisão capturada para a ação")
	lab.pause_button.button_pressed = true
	var elapsed = lab.model.action["elapsed"]
	var offset = actor["visual_offset"]
	lab._process(0.2)
	expect(lab.model.action["elapsed"] == elapsed and actor["visual_offset"] == offset, "Pausa congela habilidade no centro")
	await capture("fullscreen-center-ally")
	policy(0, 2)
	expect(lab.model.action["motion"]["move_to_center"], "Alterar política na execução não interrompe retorno atual")
	finish()
	expect(actor["visual_offset"] == Vector2.ZERO, "Alteração durante execução não deixa ator no centro")
	policy(5, 1) # Estático comum recebe exceção via UI.
	expect(lab.model.fullscreen_center_enabled(lab.model.enemies[1]), "Editor habilita estático individualmente")
	lab.model._begin_action(lab.model.enemies[1], lab.definitions["skills"]["all"], "", Vector2.ZERO, "")
	if not impact():
		quit(1)
		return
	expect(lab.model.enemies[1]["logical_position"] + lab.model.enemies[1]["visual_offset"] == lab.model.visual_center(), "Estático com override executa no centro")
	await capture("fullscreen-static-exception")
	finish()
	policy(5, 0)
	expect(not lab.model.fullscreen_center_enabled(lab.model.enemies[1]), "Limpar exceção restaura estático no lugar")
	policy(4, 2)
	expect(not lab.model.fullscreen_center_enabled(lab.model.enemies[0]), "Editor também pode impedir um móvel de ir ao centro")
	# Reinício restaura fichas e padrões, sem alterar configuração dos outros presets.
	lab._start(false)
	lab._refresh()
	expect(lab.model.fullscreen_center_enabled(lab.model.party[0]) and lab.model.fullscreen_center_enabled(lab.model.enemies[0]), "Novo teste limpa alterações temporárias")
	lab.preset_picker.select(0)
	lab._start(false)
	lab._refresh()
	expect(lab.fullscreen_actor_picker.item_count == 7 and lab.model.preset["id"] == "lab_a", "Troca de preset preserva o editor e laboratório antigo")
	lab.queue_free()
	await process_frame
	print("TELA INTEIRA/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
