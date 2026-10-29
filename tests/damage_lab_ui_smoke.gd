extends SceneTree
var screen
var checks = 0
var failures = 0
var capture_directory = ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--visual-captures="):
			capture_directory = arg.trim_prefix("--visual-captures=")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func type_text(value: String) -> void:
	for character in value:
		var event = InputEventKey.new()
		event.keycode = character.unicode_at(0)
		event.unicode = character.unicode_at(0)
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func click(point: Vector2) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func pad(button: JoyButton) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func axis(value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func choose(picker: OptionButton, index: int) -> void:
	picker.select(index)
	picker.item_selected.emit(index)

func choose_id(picker: OptionButton, _entries: Array, id: String) -> void:
	for index in range(picker.item_count):
		if picker.get_item_metadata(index) == id:
			choose(picker, index)
			return
	expect(false, "Equipamento ausente do seletor: " + id)

func finish() -> void:
	for tick in range(60):
		screen._process(1.0 / 60.0)
	expect(not screen.busy and not screen.field.active, "Animação termina e libera edição")

func capture(name: String, viewport: Viewport = null) -> void:
	if capture_directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	await process_frame
	await RenderingServer.frame_post_draw
	if viewport == null:
		viewport = root
	expect(viewport.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK, "Captura " + name)

func _run() -> void:
	root.size = Vector2i(1440, 960)
	var production = FileAccess.get_file_as_string("res://data/lab.json")
	screen = load("res://scenes/damage_lab.tscn").instantiate()
	screen.preset_storage_path = "/private/tmp/rpg-damage-ui-presets-%d.json" % OS.get_process_id()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	expect(screen.export_button.disabled, "Exportação indisponível antes de executar")
	key(KEY_F10)
	expect(not screen.export_dialog.visible and screen.pending_export.is_empty(), "Não abre exportação sem resultado")
	expect(screen.profile_edits.size() == 2 and screen.run_buttons.size() == 4, "Duas fichas e opções 1/10/100/1000")
	for role in ["attacker", "target"]:
		for key in screen.profile_edits[role]:
			var spin: SpinBox = screen.profile_edits[role][key]
			var evasion: bool = key == "evasion_base"
			var small: bool = key in ["ini", "critical_base"]
			var resistance: bool = key in ["intelligence", "vigor"]
			var monster: bool = role == "target"
			expect(spin.min_value == (0 if evasion else 1 if resistance or small or monster else 0) and spin.max_value == (100 if evasion else 99 if small else 999 if resistance else 99999 if monster and key == "hp" else 9999 if monster else 999), "Editor respeita faixa de cada atributo por lado")
	var attack: SpinBox = screen.profile_edits["attacker"]["physical_attack"]
	attack.grab_focus()
	key(KEY_RIGHT)
	expect(screen.model.attacker["physical_attack"] == 101, "Seta ajusta atributo pelo teclado")
	key(KEY_ENTER)
	expect(attack.get_line_edit().has_focus(), "Enter permite digitar valor exato")
	attack.get_line_edit().text = "367"
	key(KEY_ENTER)
	expect(screen.model.attacker["physical_attack"] == 367, "Confirmar edição aplica valor ao próximo teste")
	var defense: SpinBox = screen.profile_edits["target"]["physical_defense"]
	defense.grab_focus()
	var before: int = screen.model.target["physical_defense"]
	pad(JOY_BUTTON_DPAD_RIGHT)
	expect(screen.model.target["physical_defense"] == before + 1, "Controle ajusta atributo")
	screen._reset_case()
	await process_frame
	click(attack.get_line_edit().get_global_rect().get_center())
	expect(attack.get_line_edit().has_focus(), "Clique no número permite digitar diretamente")
	type_text("265")
	key(KEY_ENTER)
	expect(screen.model.attacker["physical_attack"] == 265, "Digitação substitui o valor selecionado pelo clique")
	attack.grab_focus()
	type_text("426")
	key(KEY_TAB)
	expect(screen.model.attacker["physical_attack"] == 426, "Começar a digitar edita sem exigir Enter antes e Tab confirma")
	screen.weapon_chance.grab_focus()
	await process_frame
	await process_frame
	await process_frame
	click(screen.weapon_chance.get_line_edit().get_global_rect().get_center())
	type_text("8,5")
	click(screen.weapon_multiplier.get_line_edit().get_global_rect().get_center())
	expect(is_equal_approx(screen.model.weapon["critical_chance"], 8.5), "Clique em outro campo confirma decimal com vírgula")
	attack.grab_focus()
	type_text("10000")
	key(KEY_ENTER)
	expect(screen.model.attacker["physical_attack"] == 999, "Valor digitado respeita teto do atributo")
	attack.grab_focus()
	type_text("321")
	key(KEY_F7)
	expect(screen.last_result["snapshot"]["base_stats"]["attacker"]["physical_attack"] == 321 and screen.last_result["snapshot"]["attacker"]["physical_attack"] == 331, "Executar lote confirma a digitação e aplica bônus da Bronze")
	screen._reset_case()
	key(KEY_F6)
	expect(screen.busy and screen.last_result["count"] == 1, "F6 executa uma ação visual")
	var run_number: int = screen.model.run_number
	key(KEY_F9)
	expect(screen.model.run_number == run_number, "Não executa lote no meio da animação")
	key(KEY_F10)
	expect(screen.export_button.disabled and not screen.export_dialog.visible, "Não abre exportação durante animação")
	screen._process(0.42)
	expect(screen.field.elapsed >= screen.field.duration * 0.5, "Golpe chega ao impacto")
	await capture("damage-single-impact")
	finish()
	var first = screen.last_result.duplicate(true)
	var first_history_index: int = screen.model.history.size() - 1
	key(KEY_R)
	key(KEY_F6)
	finish()
	expect(screen.last_result["samples"] == first["samples"], "Reiniciar sequência reproduz golpe")
	key(KEY_F7)
	expect(screen.last_result["count"] == 10 and not screen.busy, "Lote 10 executa sem animações acumuladas")
	screen.run_buttons[2].grab_focus()
	pad(JOY_BUTTON_A)
	expect(screen.last_result["count"] == 100 and "100 ações" in screen.summary.text, "Controle executa lote e atualiza resumo")
	key(KEY_F9)
	expect(screen.last_result["count"] == 1000 and screen.samples_tree.get_root().get_child_count() == 1000, "Mil resultados individuais são acessíveis")
	expect(not screen.busy and screen.histogram.result["count"] == 1000, "Histograma atualizado sem mil animações")
	var exported_run: int = screen.last_result["run_number"]
	var rng_before_export: Dictionary = screen.model.rng_state.duplicate()
	key(KEY_F10)
	expect(screen.export_dialog.visible and screen.pending_export["count"] == 1000, "F10 abre salvar JSON da execução selecionada")
	await capture("damage-export-dialog", screen.export_dialog)
	key(KEY_F7)
	expect(screen.model.run_number == exported_run, "Diálogo impede atalhos de executar ao fundo")
	screen.export_dialog.get_cancel_button().pressed.emit()
	expect(not screen.export_dialog.visible and screen.pending_export.is_empty() and screen.model.rng_state == rng_before_export, "Cancelar não exporta nem consome sorteios")
	screen.export_button.grab_focus()
	pad(JOY_BUTTON_A)
	expect(screen.export_dialog.visible, "Controle aciona exportação")
	var export_path = "/private/tmp/rpg-damage-ui-export-%d.json" % OS.get_process_id()
	screen.export_dialog.current_dir = export_path.get_base_dir()
	screen.export_dialog.current_file = export_path.get_file()
	screen.export_dialog.get_ok_button().pressed.emit()
	await process_frame
	var exported = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(exported["samples"].size() == 1000 and exported["run"]["number"] == exported_run and screen.last_export_path == export_path, "Escolher destino grava as mil amostras sem novo cálculo")
	expect("exportadas" in screen.notice.text and screen.model.rng_state == rng_before_export, "Sucesso informa caminho e preserva sequência")
	DirAccess.remove_absolute(export_path)
	await capture("damage-batch-1000")
	screen.result_tabs.current_tab = 1
	await process_frame
	screen.samples_tree.grab_focus()
	pad(JOY_BUTTON_DPAD_DOWN)
	expect(screen.samples_tree.get_selected() != null and "Amostra #1" in screen.sample_detail.text, "Controle inspeciona amostras individuais")
	pad(JOY_BUTTON_DPAD_DOWN)
	expect("Amostra #2" in screen.sample_detail.text, "Navegação atualiza decomposição do cálculo")
	await capture("damage-samples")
	screen.result_tabs.current_tab = 2
	await capture("damage-conditions")
	screen.result_tabs.current_tab = 0
	var saved_attack: int = screen.last_result["snapshot"]["attacker"]["physical_attack"]
	attack.value = 999
	expect(screen.last_result["snapshot"]["attacker"]["physical_attack"] == saved_attack, "Editar ficha não altera condições do histórico")
	choose(screen.history_picker, first_history_index)
	expect(screen.last_result["run_number"] == first["run_number"], "Histórico recupera execução com condições próprias")
	key(KEY_F10)
	screen.export_dialog.file_selected.emit(export_path)
	exported = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(exported["run"]["number"] == first["run_number"] and exported["samples"].size() == 1 and exported["conditions"]["attacker"]["physical_attack"] == first["snapshot"]["attacker"]["physical_attack"], "JSON do histórico não usa edição atual de ATQ F 999")
	DirAccess.remove_absolute(export_path)
	key(KEY_F10)
	screen.export_dialog.file_selected.emit("/private/tmp/pasta-ausente-rpg-%d/amostras.json" % OS.get_process_id())
	expect("Não foi possível" in screen.notice.text and screen.model.rng_state == rng_before_export, "Falha de gravação é exibida sem mudar histórico ou RNG")
	choose(screen.action_picker, 2)
	expect(screen.model.action["damage_type"] == "magical" and not screen.critical_allowed.button_pressed, "Seleciona magia com permissão experimental explícita")
	screen.critical_allowed.button_pressed = true
	choose(screen.critical_mode, 2)
	screen.weapon_multiplier.value = 3
	screen.item_edit.value = 5
	screen.buff_edit.value = 10
	screen.run_buttons[2].pressed.emit()
	expect(screen.last_result["critical_count"] == 0 and not screen.last_result["snapshot"]["action"]["critical_allowed"] and screen.critical_allowed.disabled, "Magia não permite crítico mesmo com modo forçado ou alteração programática")
	await capture("damage-magic-critical")
	var state: Dictionary = screen.model.rng_state.duplicate()
	var history_count: int = screen.model.history.size()
	screen.profile_edits["attacker"]["mp"].value = 0
	key(KEY_F7)
	expect("MP insuficiente" in screen.notice.text and screen.model.rng_state == state and screen.model.history.size() == history_count, "Lote inválido não consome RNG nem cria histórico parcial")
	screen.model.swap_roles()
	screen._sync_controls()
	screen._preview()
	expect(screen.model.attacker["side"] != screen.model.target["side"], "Troca de lados mantém atacante e alvo opostos")
	choose(screen.action_picker, 0) # Modificadores de crítico só se aplicam ao dano físico.
	screen.conversion_edit.grab_focus()
	await process_frame
	await process_frame
	axis(0.8)
	axis(0.0)
	await process_frame
	await process_frame
	expect(is_equal_approx(screen.model.settings["crit_per_point"], 1.1), "Analógico ajusta conversão de CRI e retorna ao repouso")
	var parent = screen.conversion_edit.get_parent()
	while not parent is ScrollContainer:
		parent = parent.get_parent()
	expect(parent.scroll_vertical > 0 and parent.get_global_rect().encloses(screen.conversion_edit.get_global_rect()), "Foco rola o editor e torna visíveis os parâmetros inferiores sem mouse")
	await capture("damage-editor-lower")
	screen._reset_case()
	expect(screen.model.attacker["physical_attack"] == 100 and screen.model.sequence_position == 0, "Restaurar caso recupera presets e sequência")
	expect(FileAccess.get_file_as_string("res://data/lab.json") == production, "Dados do jogo permanecem intactos")
	await process_frame
	await process_frame
	expect(screen.field.get_global_rect().end.x <= root.size.x and screen.result_tabs.get_global_rect().end.y < root.size.y, "Duelo e resultados cabem na janela padrão")
	# Equipamentos pertencem ao aliado, em qualquer lado do duelo.
	screen.profile_edits["attacker"]["physical_attack"].value = 20
	screen.profile_edits["attacker"]["physical_defense"].value = 20
	screen.profile_edits["target"]["physical_attack"].value = 30
	screen.profile_edits["target"]["physical_defense"].value = 35
	screen.profile_edits["target"]["hp"].value = 40
	choose_id(screen.weapon_picker, screen.model.data["weapons"], "sword_bronze")
	choose_id(screen.armor_picker, screen.model.data["armors"], "armor_iron")
	expect("20 + 10 = 30" in screen.composition_labels["attacker"].text and "20 + 16 = 36" in screen.composition_labels["attacker"].text, "Ficha mostra próprio, bônus e total do aliado")
	expect("sem equipamentos" in screen.composition_labels["target"].text and screen.model.target["physical_defense"] == 35, "Ficha do monstro permanece direta")
	screen.weapon_bonus.grab_focus()
	type_text("15")
	key(KEY_ENTER)
	expect(screen.model.weapon["attack_bonus"] == 15 and "20 + 15 = 35" in screen.composition_labels["attacker"].text, "Bônus de arma é digitável e recalcula prévia")
	choose_id(screen.weapon_picker, screen.model.data["weapons"], "sword_bronze")
	screen.variation_toggle.button_pressed = false
	choose(screen.critical_mode, 1)
	key(KEY_F9)
	expect(screen.last_result["mean"] == 14 and screen.last_result["count"] == 1000, "Lote usa ATQ F total 30 contra defesa direta 35")
	screen.profile_edits["attacker"]["physical_attack"].grab_focus()
	await process_frame
	await capture("equipment-totals")
	screen.result_tabs.current_tab = 2
	screen.armor_bonus.grab_focus()
	await process_frame
	await capture("equipment-selectors")
	for control in screen.focus_controls:
		if control is Button and control.text == "Trocar lados":
			control.grab_focus()
			pad(JOY_BUTTON_A)
			break
	expect(screen.model.ally_role() == "target" and screen.model.weapon["id"] == "sword_bronze" and screen.model.armor["id"] == "armor_iron", "Controle inverte lados mantendo equipamento no aliado")
	expect("20 + 16 = 36" in screen.composition_labels["target"].text and "(alvo)" in screen.equipment_title.text, "Prévia e dono do equipamento seguem o aliado alvo")
	screen.enemy_multiplier.value = 3.0
	choose(screen.critical_mode, 2)
	key(KEY_F7)
	expect(screen.last_result["snapshot"]["critical_source"]["kind"] == "innate" and screen.last_result["samples"][0]["critical_multiplier"] == 3.0, "Monstro usa crítico próprio editável sem arma")
	expect(not screen.last_result["snapshot"].has("weapon") and not screen.last_result["snapshot"]["equipment"].has("attacker"), "Snapshot não equipa o monstro ao inverter papéis")
	screen._request_export()
	screen._save_export(export_path)
	exported = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(exported["version"] == 5 and exported["conditions"]["base_stats"]["target"]["physical_defense"] == 20 and exported["conditions"]["composition"]["target"]["effective"]["physical_defense"] == 36, "JSON exporta próprios e totais do aliado alvo")
	expect(exported["conditions"]["equipment"]["target"]["armor"]["id"] == "armor_iron" and not exported["conditions"]["equipment"].has("attacker"), "JSON identifica os itens somente no aliado")
	DirAccess.remove_absolute(export_path)
	screen.profile_edits["target"]["physical_defense"].grab_focus()
	await process_frame
	await capture("equipment-monster-attack")
	expect(not screen.model.choose_equipment("weapon", "none").is_empty() and not screen.model.choose_equipment("armor", "none").is_empty(), "Não permite remover arma ou armadura")
	expect(screen.weapon_bonus.editable and screen.armor_bonus.editable and screen.weapon_chance.editable, "Equipamentos obrigatórios mantêm bônus editáveis")
	expect(screen.model.weapon["id"] == "sword_bronze" and screen.model.armor["id"] == "armor_iron", "Tentativa de remoção preserva os dois itens")
	choose_id(screen.weapon_picker, screen.model.data["weapons"], "sword_runic")
	screen.profile_edits["target"]["physical_attack"].value = 999
	expect("1064 → 999" in screen.composition_labels["target"].text, "Prévia sinaliza limite experimental sem esconder soma")
	screen._reset_case()
	expect(screen.model.armor["id"] == "armor_bronze" and screen.weapon_bonus.value == 10, "Restaurar caso também restaura equipamentos")
	for stat in ["hp", "mp", "physical_attack", "physical_defense", "magic_power", "magic_defense"]:
		screen.profile_edits["target"][stat].value = 9999
		expect(screen.model.target[stat] == 9999, "Monstro alvo aceita quatro dígitos: " + stat)
	var enemy_hp: SpinBox = screen.profile_edits["target"]["hp"]
	enemy_hp.grab_focus()
	type_text("100000")
	key(KEY_ENTER)
	expect(screen.model.target["hp"] == 99999, "Digitação limita HP de monstro a 99999")
	for control in screen.focus_controls:
		if control is Button and control.text == "Trocar lados":
			control.pressed.emit()
			break
	for stat in ["hp", "mp", "physical_attack", "physical_defense", "magic_power", "magic_defense"]:
		expect(screen.profile_edits["attacker"][stat].max_value == (99999 if stat == "hp" else 9999) and screen.profile_edits["attacker"][stat].value == (99999 if stat == "hp" else 9999) and screen.model.attacker[stat] == (99999 if stat == "hp" else 9999), "Trocar lados preserva HP 99999/demais 9999: " + stat)
		expect(screen.profile_edits["target"][stat].max_value == 999 and screen.profile_edits["target"][stat].min_value == 0, "Trocar lados restaura faixa do aliado: " + stat)
	screen.profile_edits["target"]["physical_attack"].grab_focus()
	type_text("1000")
	key(KEY_ENTER)
	expect(screen.model.target["physical_attack"] == 999 and screen.model.attacker["physical_attack"] == 9999, "Aliado continua limitado a 999 sem truncar o monstro")
	key(KEY_F7)
	expect(screen.last_result["snapshot"]["attacker"]["hp"] == 99999 and screen.last_result["snapshot"]["attacker"]["physical_attack"] == 9999, "Lote usa atributos grandes do atacante")
	screen._request_export()
	screen._save_export(export_path)
	exported = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(exported["conditions"]["attacker"]["hp"] == 99999 and exported["conditions"]["base_stats"]["attacker"]["magic_power"] == 9999, "Interface exporta HP com cinco dígitos sem truncar")
	DirAccess.remove_absolute(export_path)
	screen.profile_edits["attacker"]["hp"].grab_focus()
	await process_frame
	await capture("enemy-large-values")
	screen._reset_case()
	screen.result_tabs.current_tab = 0
	screen.profile_edits["target"]["evasion_base"].value = 100
	choose(screen.critical_mode, 2)
	key(KEY_F9)
	expect(screen.last_result["evasion_count"] == 1000 and screen.last_result["total"] == 0 and screen.last_result["critical_count"] == 0, "EVA 100 evita o lote mesmo com crítico forçado")
	expect("Esquivas: 1000" in screen.summary.text and "ESQUIVOU" in screen.calculation.text and screen.samples_tree.get_root().get_first_child().get_text(3) == "Esquiva", "Resumo, cálculo e amostras mostram esquiva")
	expect(screen.field.result["evaded"] and screen.histogram.result["histogram"][0]["evaded"] == 1000, "Duelo e histograma recebem classificação de esquiva")
	screen.profile_edits["target"]["evasion_base"].grab_focus()
	await process_frame
	await capture("evasion-all")
	choose(screen.action_picker, 1)
	key(KEY_F6)
	finish()
	expect(screen.last_result["samples"][0]["mp_after"] == 96 and screen.last_result["samples"][0]["hp_removed"] == 0, "Esquiva visual de técnica preserva HP e consome MP")
	await capture("evasion-single")
	choose(screen.action_picker, 2)
	key(KEY_F7)
	expect(not screen.evasion_allowed.button_pressed and screen.last_result["evasion_count"] == 0, "Magia por padrão não permite esquiva")
	screen.evasion_allowed.button_pressed = true
	key(KEY_F7)
	expect(screen.last_result["evasion_count"] == 10, "Controle de permissão permite comparar esquiva em magia")
	choose(screen.action_picker, 0)
	screen.profile_edits["target"]["evasion_base"].value = 25
	choose(screen.critical_mode, 0)
	key(KEY_R)
	key(KEY_F9)
	expect(screen.last_result["evasion_count"] > 0 and screen.last_result["hit_count"] > 0, "EVA intermediária produz lote misto")
	var evasion_history: Dictionary = screen.last_result.duplicate(true)
	screen._request_export()
	screen._save_export(export_path)
	exported = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(exported["version"] == 5 and exported["conditions"]["target"]["evasion_base"] == 25 and exported["summary"]["evasion_count"] == screen.last_result["evasion_count"], "Interface exporta EVA, condições e resumo completos")
	DirAccess.remove_absolute(export_path)
	screen.profile_edits["target"]["evasion_base"].grab_focus()
	await process_frame
	await capture("evasion-mixed")
	screen.profile_edits["target"]["evasion_base"].value = 0
	expect(evasion_history["snapshot"]["target"]["evasion_base"] == 25 and screen.last_result["samples"] == evasion_history["samples"], "Editar EVA não muda condições nem resultados do histórico")
	screen.model.swap_roles()
	screen._sync_controls()
	expect(screen.profile_edits["target"]["evasion_base"].min_value == 0 and screen.profile_edits["target"]["evasion_base"].max_value == 100, "EVA do aliado também aceita zero a cem após inverter lados")
	expect(FileAccess.get_file_as_string("res://data/lab.json") == production, "Esquiva permanece isolada do combate atual")
	screen.queue_free()
	await process_frame
	print("LAB DANOS/UI: %d verificações, %d falhas" % [checks, failures])
	quit(0 if failures == 0 else 1)
