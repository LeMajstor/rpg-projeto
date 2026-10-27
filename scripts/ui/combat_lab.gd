extends Control
signal battle_finished(result: String)
signal restart_exploration_requested
const Hand = preload("res://scripts/ui/battle_hand.gd")
const Battle = preload("res://scripts/combat/battle_model.gd")
const Field = preload("res://scripts/ui/battlefield.gd")

var model
var definitions: Dictionary
var board
var preset_picker: OptionButton
var mode_picker: OptionButton
var battle_speed_picker: OptionButton
var seed_input: SpinBox
var speed_slider: HSlider
var speed_label: Label
var pause_button: CheckButton
var debug_button: CheckButton
var continue_button: Button
var status_label: Label
var selection_label: Label
var command_buttons: Array[Button] = []
var cards: Array[Dictionary] = []
var action_menu: VBoxContainer
var event_text: RichTextLabel
var debug_panel: VBoxContainer
var debug_window: Window
var debug_text: RichTextLabel
var ai_text: RichTextLabel
var debug_actor: OptionButton
var hp_edit: SpinBox
var ini_edit: SpinBox
var fullscreen_actor_picker: OptionButton
var fullscreen_policy_picker: OptionButton
var fullscreen_policy_label: Label
var fullscreen_actor_ids: Array[String] = []
var fullscreen_actor_signature = ""
var menu_kind = ""
var aim_id = ""
var aim_item = ""
var accumulator = 0.0
var last_menu_key = ""
var last_events = ""
var last_debug_selection = ""
var capture_frames = 0
var capture_path = ""
var encounter_mode = false
var result_reported = false
var encounter_restart: Button

var party_focus_id = ""
var command_index = 0
var list_index = 0
var target_focus_id = ""
var target_return_menu = ""
var settings_open = false
var settings_index = 0
var list_buttons: Array[Button] = []
var settings_rows: Array[Button] = []
var joy_axes = Vector2.ZERO
var held_direction = Vector2.ZERO
var repeat_remaining = 0.0

func configure_encounter(shared_model) -> void:
	# Chamado ANTES de adicionar a cena à árvore. O grupo não é recriado.
	assert(not is_inside_tree())
	encounter_mode = true
	model = shared_model

func _ready() -> void:
	# Janela nativa independente: pode ser movida para fora do campo de batalha.
	get_viewport().gui_embed_subwindows = false
	if encounter_mode:
		definitions = model.data
	else:
		definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
		model = Battle.new(definitions)
	_build_ui()
	Input.joy_connection_changed.connect(func(_device, connected):
		if not connected:
			_reset_navigation_hold())
	if not encounter_mode:
		preset_picker.select(model.default_preset_index())
		model.start(preset_picker.selected, false, int(seed_input.value))
	else:
		mode_picker.select(0 if model.mode == "Wait" else 1)
		board.result_hint = "Retornando ao mapa após o encerramento da ação."
	_refresh()
	if encounter_mode:
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--preset="):
			var id = argument.trim_prefix("--preset=")
			for index in range(definitions["presets"].size()):
				if definitions["presets"][index]["id"] == id:
					preset_picker.select(index)
					_start(false)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
			model.debug_ready_allies()
			model.select_actor("p2")
		if argument == "--debug-view":
			debug_button.button_pressed = true
		if argument == "--paused":
			pause_button.button_pressed = true

func _build_ui() -> void:
	var theme = Theme.new()
	theme.default_font_size = 16
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("20364b")
	button_style.set_border_width_all(1)
	button_style.border_color = Color("3e5872")
	button_style.set_corner_radius_all(7)
	button_style.content_margin_left = 12
	button_style.content_margin_right = 12
	button_style.content_margin_top = 9
	button_style.content_margin_bottom = 9
	theme.set_stylebox("normal", "Button", button_style)
	var hover = button_style.duplicate()
	hover.bg_color = Color("304e67")
	theme.set_stylebox("hover", "Button", hover)
	var disabled = button_style.duplicate()
	disabled.bg_color = Color("152232")
	disabled.border_color = Color("263648")
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_color("font_disabled_color", "Button", Color("718195"))
	self.theme = theme
	var background = ColorRect.new()
	background.color = Color("0b121e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	scroll.add_child(margin)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)
	var heading = HBoxContainer.new()
	root.add_child(heading)
	var title = _label("ENCONTRO / COMBATE" if encounter_mode else "LABORATÓRIO / COMBATE", 27, Color("e2edf8"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("GODOT + GDSCRIPT   •   PROTÓTIPO MECÂNICO", 13, Color("87a6c2")))
	root.add_child(_label("Dados de teste · sem conteúdo definitivo · aliados fixos / inimigos em rotas programadas", 14, Color("9bb0c8")))
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	root.add_child(toolbar)
	preset_picker = OptionButton.new()
	preset_picker.visible = not encounter_mode
	for preset in definitions["presets"]:
		var legacy: bool = preset["id"] in definitions.get("legacy_preset_ids", [])
		preset_picker.add_item(("Legado · " if legacy else "") + preset["name"])
		if legacy:
			preset_picker.set_item_tooltip(preset_picker.item_count - 1, "Referência histórica; os encontros atuais usam os novos ritmos.")
	toolbar.add_child(preset_picker)
	mode_picker = OptionButton.new()
	mode_picker.add_item("Wait / Espera")
	mode_picker.add_item("Active / Ativo")
	mode_picker.item_selected.connect(func(index): model.mode = "Wait" if index == 0 else "Active")
	toolbar.add_child(mode_picker)
	var seed_label = _label("Semente", 14)
	seed_label.visible = not encounter_mode
	toolbar.add_child(seed_label)
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 99999999
	seed_input.value = definitions["settings"]["seed"]
	seed_input.custom_minimum_size.x = 125
	seed_input.visible = not encounter_mode
	toolbar.add_child(seed_input)
	var new_test = _add_button(toolbar, "Novo teste [F5]", func(): _start(false))
	new_test.visible = not encounter_mode
	continue_button = _add_button(toolbar, "Próxima luta · manter HP/MP", func(): _start(true))
	continue_button.visible = not encounter_mode
	if encounter_mode:
		toolbar.add_child(_label("Grupo e recursos compartilhados com a exploração", 14))
		encounter_restart = _add_button(toolbar, "Reiniciar percurso de teste", func(): restart_exploration_requested.emit())
	var battle_settings = HBoxContainer.new()
	battle_settings.add_theme_constant_override("separation", 12)
	root.add_child(battle_settings)
	battle_settings.add_child(_label("Battle Speed", 16))
	battle_speed_picker = OptionButton.new()
	battle_speed_picker.focus_mode = Control.FOCUS_NONE
	for level in range(1, 9):
		var suffix = " · Mais lento" if level == 1 else (" · Mais rápido" if level == 8 else "")
		if level == int(definitions.get("battle_speed", {}).get("default", 4)):
			suffix += " · Padrão"
		battle_speed_picker.add_item(str(level) + suffix)
	battle_speed_picker.select(model.battle_speed - 1)
	battle_speed_picker.item_selected.connect(func(index): model.battle_speed = index + 1)
	battle_settings.add_child(battle_speed_picker)
	battle_settings.add_child(_label("Velocidade de carga do ATB · aliados e inimigos", 14, Color("9bb0c8")))
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	root.add_child(controls)
	pause_button = CheckButton.new()
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.text = "Pausa [Espaço]"
	controls.add_child(pause_button)
	controls.add_child(_label("Simulação (teste)", 14))
	speed_slider = HSlider.new()
	speed_slider.min_value = 0.25
	speed_slider.max_value = 4.0
	speed_slider.step = 0.25
	speed_slider.value = 1.0
	speed_slider.custom_minimum_size.x = 150
	controls.add_child(speed_slider)
	speed_label = _label("1.00×", 14)
	controls.add_child(speed_label)
	_add_button(controls, "Passo +1/60 s", _step)
	debug_button = CheckButton.new()
	debug_button.focus_mode = Control.FOCUS_NONE
	debug_button.text = "Depuração [F3]"
	controls.add_child(debug_button)
	status_label = _label("", 14, Color("f3d696"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(status_label)
	var center = HBoxContainer.new()
	center.add_theme_constant_override("separation", 16)
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board = Field.new()
	board.model = model
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(board)
	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 370
	sidebar.add_theme_constant_override("separation", 8)
	center.add_child(sidebar)
	selection_label = _label("Selecione um aliado pronto", 18, Color("e5edf7"))
	sidebar.add_child(selection_label)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	sidebar.add_child(grid)
	command_buttons.append(_game_button(grid, "Atacar", func(): _choose_action("attack")))
	command_buttons.append(_game_button(grid, "Habilidades", func(): _set_menu("skills")))
	command_buttons.append(_game_button(grid, "Itens", func(): _set_menu("items")))
	command_buttons.append(_game_button(grid, "Fugir", _escape))
	for button in command_buttons:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_menu = VBoxContainer.new()
	action_menu.custom_minimum_size.y = 145
	action_menu.add_theme_constant_override("separation", 5)
	sidebar.add_child(action_menu)
	debug_window = Window.new()
	debug_window.title = "Depuração · laboratório de combate"
	debug_window.size = Vector2i(620, 800)
	debug_window.position = Vector2i(790, 50)
	debug_window.visible = false
	debug_window.transient = true
	debug_window.close_requested.connect(func(): debug_button.button_pressed = false)
	add_child(debug_window)
	var debug_margin = MarginContainer.new()
	debug_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		debug_margin.add_theme_constant_override("margin_" + side, 14)
	debug_window.add_child(debug_margin)
	debug_panel = VBoxContainer.new()
	debug_panel.add_theme_constant_override("separation", 5)
	debug_margin.add_child(debug_panel)
	debug_panel.add_child(_label("DEPURAÇÃO · ATB inimigo visível apenas aqui", 17, Color("efbe98")))
	var cheats = HBoxContainer.new()
	debug_panel.add_child(cheats)
	_add_button(cheats, "Aliados prontos", func(): model.debug_ready_allies())
	_add_button(cheats, "Restaurar HP/MP", func(): model.debug_restore())
	var edits = HBoxContainer.new()
	debug_panel.add_child(edits)
	debug_actor = OptionButton.new()
	for member in definitions["party"]:
		debug_actor.add_item(member["short_name"])
	edits.add_child(debug_actor)
	edits.add_child(_label("HP", 12))
	hp_edit = SpinBox.new()
	hp_edit.max_value = 9999
	hp_edit.custom_minimum_size.x = 84
	edits.add_child(hp_edit)
	edits.add_child(_label("ΔINI", 12))
	ini_edit = SpinBox.new()
	ini_edit.min_value = -100
	ini_edit.max_value = 100
	ini_edit.custom_minimum_size.x = 80
	edits.add_child(ini_edit)
	_add_button(debug_panel, "Aplicar HP / modificador de INI", _apply_debug_edits)
	var fullscreen_row = HBoxContainer.new()
	debug_panel.add_child(fullscreen_row)
	fullscreen_row.add_child(_label("Centro:", 13))
	fullscreen_actor_picker = OptionButton.new()
	fullscreen_actor_picker.custom_minimum_size.x = 180
	fullscreen_actor_picker.item_selected.connect(func(_index): _sync_fullscreen_editor())
	fullscreen_row.add_child(fullscreen_actor_picker)
	fullscreen_policy_picker = OptionButton.new()
	for choice in ["Usar padrão", "Forçar: centro", "Forçar: imóvel"]:
		fullscreen_policy_picker.add_item(choice)
	fullscreen_policy_picker.item_selected.connect(_set_fullscreen_policy)
	fullscreen_row.add_child(fullscreen_policy_picker)
	fullscreen_policy_label = _label("", 13, Color("a8d7e8"))
	fullscreen_policy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fullscreen_policy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_panel.add_child(fullscreen_policy_label)
	debug_text = _rich(300, 14)
	debug_text.scroll_following = false
	debug_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_panel.add_child(debug_text)
	debug_panel.add_child(_label("ÚLTIMAS ESCOLHAS DA IA / PESOS", 12, Color("efbe98")))
	ai_text = _rich(130, 13)
	debug_panel.add_child(ai_text)
	sidebar.add_child(_label("REGISTRO DA BATALHA", 12, Color("8ca9c4")))
	event_text = _rich(120, 13)
	event_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(event_text)
	var team = GridContainer.new()
	team.columns = 4
	team.add_theme_constant_override("h_separation", 12)
	root.add_child(team)
	for index in range(4):
		_build_card(team, index)
	var footer = "Setas / direcional: navegar · Enter / Z / botão sul: confirmar · Esc / X / botão leste: voltar · Tab / Start: opções"
	footer += "   ·   retorno automático após vitória/fuga" if encounter_mode else "   ·   F5: reiniciar recursos do teste"
	root.add_child(_label(footer, 13, Color("8da5bf")))

func _build_card(parent: Node, index: int) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("142235")
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	var button = _game_button(box, "Aliado %d" % (index + 1), func(): _on_party_clicked(index))
	var stats = _label("", 13)
	box.add_child(stats)
	var hp = _bar(Color("64cfac"))
	box.add_child(hp)
	var mp = _bar(Color("8199ee"))
	box.add_child(mp)
	var atb = _bar(Color("edc776"))
	box.add_child(atb)
	cards.append({"style": style, "button": button, "stats": stats, "hp": hp, "mp": mp, "atb": atb})

func _label(text: String, font_size: int = 16, color: Color = Color("b8ccdf")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _rich(height: float, font_size: int) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.custom_minimum_size = Vector2(0, height)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.scroll_following = true
	label.selection_enabled = true
	return label

func _bar(color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var background = fill.duplicate()
	background.bg_color = Color("25364c")
	bar.add_theme_stylebox_override("background", background)
	return bar

func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _game_button(parent: Node, text: String, callback: Callable) -> Button:
	var button = _add_button(parent, text, callback)
	# Somente o fluxo de navegação pode ativar comandos do jogador.
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hand = Hand.new()
	button.add_child(hand)
	hand.anchor_top = 0.5
	hand.anchor_bottom = 0.5
	hand.offset_left = 4
	hand.offset_right = 36
	hand.offset_top = -14
	hand.offset_bottom = 14
	button.set_meta("battle_hand", hand)
	return button

func _start(preserve: bool) -> void:
	if encounter_mode:
		return # O ciclo do encontro pertence à sessão, não ao laboratório.
	if model.start(preset_picker.selected, preserve, int(seed_input.value)):
		party_focus_id = ""
		command_index = 0
		settings_open = false
		_reset_navigation_hold()
		_clear_aim()
		accumulator = 0.0
		last_debug_selection = ""
		_refresh()

func _clear_aim() -> void:
	menu_kind = ""
	aim_id = ""
	aim_item = ""
	last_menu_key = ""
	board.aiming_skill = {}
	board.aiming_target_id = ""
	target_focus_id = ""

func _set_menu(kind: String) -> void:
	if model.selected_id.is_empty() or not model.action.is_empty():
		return
	_clear_aim()
	menu_kind = kind
	list_index = 0
	_refresh()

func _choose_action(id: String, item: String = "") -> void:
	if model.selected_id.is_empty() or not model.action.is_empty():
		return
	var actor = model.actor_by_id(model.selected_id)
	var skill: Dictionary = model.item_skill(item) if not item.is_empty() else definitions["skills"].get(id, {})
	if skill.is_empty() or actor["mp"] < skill.get("mp_cost", 0) or (not item.is_empty() and model.inventory.get(item, 0) <= 0):
		return
	target_return_menu = menu_kind if menu_kind in ["skills", "items"] else ""
	aim_id = id
	aim_item = item
	menu_kind = "target"
	board.aiming_skill = skill
	target_focus_id = ""
	last_menu_key = ""
	_refresh()

func _aim_skill() -> Dictionary:
	if not aim_item.is_empty():
		return model.item_skill(aim_item)
	return definitions["skills"].get(aim_id, {})

func _on_party_clicked(index: int) -> void:
	var member = model.party[index]
	if menu_kind == "target" and not aim_item.is_empty():
		_confirm(member["id"], member["logical_position"])
	elif model.select_actor(member["id"]):
		party_focus_id = member["id"]
		command_index = 0
		_clear_aim()
	_refresh()

func _confirm(id: String = "", point: Vector2 = Vector2.ZERO) -> void:
	if model.submit(aim_id, id, point, aim_item):
		_clear_aim()
	else:
		model.log_event("Comando não confirmado: verifique prontidão, alvo, MP ou estoque.")
	_refresh()

func _escape() -> void:
	if model.submit("escape"):
		_clear_aim()
	_refresh()

func _process(delta: float) -> void:
	if model == null:
		return
	_repeat_navigation(delta)
	if not pause_button.button_pressed:
		accumulator += minf(delta, 0.25) * speed_slider.value
		var step: float = definitions["settings"]["fixed_step"]
		while accumulator >= step:
			model.tick(step)
			accumulator -= step
	_refresh()
	if not capture_path.is_empty():
		capture_frames += 1
		if capture_frames == 12:
			_capture.call_deferred()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var error = get_viewport().get_texture().get_image().save_png(capture_path)
	if debug_window.visible:
		debug_window.get_texture().get_image().save_png(capture_path.get_basename() + "-window.png")
	print("CAPTURE ", error, " ", capture_path)
	get_tree().quit(error)

func _step() -> void:
	pause_button.button_pressed = true
	for index in range(2):
		model.tick(float(definitions["settings"]["fixed_step"]))
	_refresh()

func _refresh() -> void:
	if model.party.is_empty():
		return
	board.debug_visible = debug_button.button_pressed
	debug_window.visible = debug_button.button_pressed
	speed_label.text = "%.2f×" % speed_slider.value
	battle_speed_picker.select(model.battle_speed - 1)
	var state = "SELEÇÃO / TEMPO PAUSADO" if model.is_waiting() else "SIMULAÇÃO EM CURSO"
	if pause_button.button_pressed:
		state = "PAUSA DE DEPURAÇÃO"
	if model.outcome != "running":
		state = "BATALHA ENCERRADA"
	status_label.text = state
	continue_button.disabled = model.outcome not in ["victory", "escaped"]
	_sync_navigation()
	var selected = model.actor_by_id(model.selected_id)
	selection_label.text = "Selecione um aliado pronto" if selected.is_empty() else "%s · ATB pronto" % selected["short_name"]
	if model.selected_id.is_empty() and not menu_kind.is_empty():
		_clear_aim()
	for button in command_buttons:
		button.disabled = selected.is_empty() or not model.action.is_empty() or model.outcome != "running"
	command_buttons[3].disabled = command_buttons[3].disabled or not model.preset.get("can_escape", true)
	command_buttons[3].tooltip_text = "Fuga bloqueada neste preset" if not model.preset.get("can_escape", true) else "Consome a ação; tenta retirar todo o grupo"
	for index in range(cards.size()):
		var actor = model.party[index]
		var card = cards[index]
		var ready = model.is_ready(actor)
		var tag = "INCAPACITADO" if actor["hp"] == 0 else ("PRONTO" if ready else "carregando")
		card["button"].text = "    [%d] %s · %s" % [index + 1, actor["short_name"], tag]
		card["button"].disabled = model.outcome != "running" or not model.action.is_empty() or (not ready and aim_item.is_empty())
		card["stats"].text = "HP %d/%d   MP %d/%d   INI %.0f\nATB %.0f%%" % [actor["hp"], actor["max_hp"], actor["mp"], actor["max_mp"], model.effective_ini(actor), actor["atb"] * 100]
		card["hp"].value = float(actor["hp"]) / actor["max_hp"] * 100
		card["mp"].value = float(actor["mp"]) / actor["max_mp"] * 100
		card["atb"].value = actor["atb"] * 100
		var chosen = actor["id"] == model.selected_id or actor["id"] == model.action.get("actor_id", "")
		card["style"].set_border_width_all(2 if chosen else 0)
		card["style"].border_color = Color("ffdf8f")
	var key = str([model.selected_id, menu_kind, aim_id, aim_item, model.inventory, _target_status(), model.action.is_empty(), target_focus_id, settings_open, model.mode, model.battle_speed])
	if key != last_menu_key:
		last_menu_key = key
		_rebuild_action_menu()
	_sync_hands()
	var event_string = "\n".join(model.events)
	if event_string != last_events:
		last_events = event_string
		event_text.text = event_string
	if debug_button.button_pressed:
		_refresh_debug()
	board.queue_redraw()
	if encounter_mode:
		encounter_restart.visible = model.outcome == "defeat"
		if model.outcome == "defeat":
			board.result_hint = "Game Over · reinicie o percurso de teste."
		if model.outcome in ["victory", "escaped", "defeat"] and not result_reported:
			result_reported = true
			battle_finished.emit.call_deferred(model.outcome)

func _target_status() -> Array:
	var status: Array = []
	for actor in model.actors():
		status.append([actor["id"], actor["hp"] > 0, actor["mp"]])
	return status

func _rebuild_action_menu() -> void:
	for child in action_menu.get_children():
		action_menu.remove_child(child)
		child.queue_free()
	list_buttons.clear()
	settings_rows.clear()
	if settings_open:
		settings_rows.append(_game_button(action_menu, "Modo: " + model.mode, func(): _adjust_setting(1)))
		settings_rows.append(_game_button(action_menu, "Battle Speed: %d / 8" % model.battle_speed, func(): _adjust_setting(1)))
		action_menu.add_child(_label("↑↓ escolher · ←→ ajustar
Tab / Start / cancelar: voltar", 14))
		return
	var actor = model.actor_by_id(model.selected_id)
	if actor.is_empty():
		action_menu.add_child(_label("Espere uma barra completar.
←→ escolhe um card PRONTO.
Confirme para escolher a ação.", 14))
		return
	var busy = not model.action.is_empty()
	if menu_kind == "skills":
		for id in actor["skills"]:
			var skill = definitions["skills"][id]
			var button = _game_button(action_menu, "%s · %d MP" % [skill["name"], skill["mp_cost"]], _choose_action.bind(id))
			button.disabled = busy or actor["mp"] < skill["mp_cost"]
			list_buttons.append(button)
	elif menu_kind == "items":
		for id in definitions["items"]:
			var button = _game_button(action_menu, "%s ×%d" % [definitions["items"][id]["name"], model.inventory[id]], _choose_action.bind("item", id))
			button.disabled = busy or model.inventory[id] <= 0 or model.target_candidates(actor, model.item_skill(id)).is_empty()
			list_buttons.append(button)
	elif menu_kind == "target":
		var skill = _aim_skill()
		var target = model.actor_by_id(target_focus_id)
		var name: String = target.get("short_name", "Nenhum alvo válido")
		if skill.get("target", "") == "all":
			name = "Todos os alvos válidos"
		var text = "%s
←→ / ↑↓ mudar alvo · confirmar para agir" % name
		if skill.get("target", "") == "circle":
			text += "
Área acompanha o alvo até o impacto."
		var description = _label(text, 14, Color("a4d8f8"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_menu.add_child(description)
	else:
		action_menu.add_child(_label("Escolha um comando à direita.
Wait pausa durante a seleção.
Active mantém o combate em curso.", 14))
	var back = _game_button(action_menu, "Voltar [Esc / botão leste]", _cancel)
	back.disabled = busy

func _refresh_debug() -> void:
	_sync_fullscreen_editor()
	var lines: Array[String] = []
	lines.append("Semente da batalha: %d" % model.simulation_seed)
	lines.append("Battle Speed: %d/8 | carga ATB %.2f×" % [model.battle_speed, model.atb_rate_multiplier()])
	for actor in model.actors():
		var pos: Vector2 = actor["logical_position"]
		var offset: Vector2 = actor["visual_offset"]
		var route = actor["route_state"]
		lines.append("%s | ATB %5.1f%% | HP %d | INI %.1f" % [actor["id"], actor["atb"] * 100, actor["hp"], model.effective_ini(actor)])
		lines.append("  lógico (%.2f,%.2f) Δvisual (%.2f,%.2f)" % [pos.x, pos.y, offset.x, offset.y])
		if actor["side"] == "enemy":
			lines.append("  rota %s/%s s%d t=%.6f dir=%d | %s" % [route["kind"], route["curve"], route["segment"], route["progress"], route["direction"], actor["profile"]])
			if route.has("rhythm"):
				var rhythm: Dictionary = route["rhythm"]
				var labels = {"accelerate": "acelera", "decelerate": "desacelera", "cruise": "percurso", "pause": "pausa", "initial_pause": "pausa inicial", "static": "estático"}
				lines.append("  ritmo %s | v %.1f u/s | etapa %d %s | sentido %d | pausa %.2fs" % [actor["movement_profile"], rhythm["current_speed"], rhythm["phase_index"] + 1, labels.get(rhythm["movement_phase"], rhythm["movement_phase"]), rhythm["direction"], rhythm["pause_remaining"]])
				if model.action.get("actor_id", "") == actor["id"]:
					lines.append("  rota suspensa pela ação; velocidade acima preservada para retomada")
			if route.has("behavior"):
				var behavior: Dictionary = route["behavior"]
				lines.append("  comportamento %s | %s | v %.1f u/s | sentido %d → %d" % [actor["movement_profile"], behavior["movement_phase"], behavior["current_speed"], behavior["direction"], behavior["pending_direction"]])
				lines.append("  pausa %.2fs | decisões %d | paradas %d | inversões %d | foco %s" % [behavior["pause_remaining"], behavior["decision_count"], behavior["pause_count"], behavior["reversal_count"], actor["visual_focus_id"]])
				if not behavior["history"].is_empty():
					var choice: Dictionary = behavior["history"].back()
					lines.append("  último sorteio: %s | pausa %.2fs | percurso %.1f u" % ["inverter" if choice["reverse"] else "continuar", choice["pause"], choice["distance"]])
				if model.action.get("actor_id", "") == actor["id"]:
					lines.append("  movimento e sorteios suspensos durante a ação")
	if not model.action.is_empty():
		var motion = model.action["motion"]
		lines.append("AÇÃO %s: %s | alvo visual %s" % [model.action["actor_id"], motion["phase"], model.action["visual_target_id"]])
		lines.append("  origem %s → contato %s" % [str(motion["origin"]), str(motion["contact"])])
		if motion.get("presentation", "") == "fullscreen":
			lines.append("  tela inteira | ir ao centro nesta ação: %s" % str(motion["move_to_center"]))
	debug_text.text = "\n".join(lines)
	var choices: Array[String] = []
	for index in range(maxi(0, model.decisions.size() - 8), model.decisions.size()):
		var decision = model.decisions[index]
		choices.append("%.2fs %s / %s → %s (%s)\n%s" % [decision["time"], decision["enemy"], decision["profile"], decision["chosen"], decision["action"], " · ".join(decision["weights"])])
	ai_text.text = "\n".join(choices) if not choices.is_empty() else "As decisões aparecem quando os inimigos agem."
	var id: String = model.party[debug_actor.selected]["id"]
	if id != last_debug_selection:
		var actor = model.actor_by_id(id)
		hp_edit.value = actor["hp"]
		ini_edit.value = actor["ini_modifier"]
		last_debug_selection = id

func _sync_fullscreen_editor() -> void:
	var names: Array[String] = []
	for actor in model.actors():
		names.append("%s · %s" % [actor["id"], actor["short_name"]])
	var signature = "|".join(names)
	if signature != fullscreen_actor_signature:
		var index = fullscreen_actor_picker.selected
		fullscreen_actor_signature = signature
		fullscreen_actor_picker.clear()
		fullscreen_actor_ids.clear()
		for actor in model.actors():
			fullscreen_actor_ids.append(actor["id"])
			fullscreen_actor_picker.add_item("%s · %s" % [actor["id"], actor["short_name"]])
		fullscreen_actor_picker.select(clampi(index, 0, fullscreen_actor_ids.size() - 1))
	if fullscreen_actor_ids.is_empty():
		return
	var actor = model.actor_by_id(fullscreen_actor_ids[fullscreen_actor_picker.selected])
	var override = actor.get("fullscreen_center_override")
	fullscreen_policy_picker.select(0 if override == null else (1 if override else 2))
	fullscreen_policy_label.text = "Tela inteira · base: %s | efetivo: %s · mudanças valem na próxima ação" % ["centro" if actor[Battle.CENTER_SETTING] else "no lugar", "centro" if model.fullscreen_center_enabled(actor) else "no lugar"]

func _set_fullscreen_policy(index: int) -> void:
	if fullscreen_actor_ids.is_empty():
		return
	var value: Variant = null
	if index > 0:
		value = index == 1
	var id = fullscreen_actor_ids[fullscreen_actor_picker.selected]
	if model.set_fullscreen_center_override(id, value):
		model.log_event("DEPURAÇÃO: %s tela inteira = %s" % [id, ["padrão", "centro", "no lugar"][index]])
	_sync_fullscreen_editor()

func _apply_debug_edits() -> void:
	if model.outcome != "running":
		return
	var actor = model.party[debug_actor.selected]
	actor["hp"] = clampi(int(hp_edit.value), 0, int(actor["max_hp"]))
	actor["ini_modifier"] = ini_edit.value
	if actor["hp"] == 0:
		actor["atb"] = 0.0
		if model.selected_id == actor["id"]:
			model.cancel_selection()
	model.log_event("DEPURAÇÃO: %s HP=%d ΔINI=%.1f" % [actor["id"], actor["hp"], actor["ini_modifier"]])
	if model.action.is_empty():
		model._check_end()
	_refresh()

func _cancel() -> void:
	if settings_open:
		settings_open = false
	elif not model.action.is_empty():
		return
	elif menu_kind == "target":
		var previous = target_return_menu
		_clear_aim()
		menu_kind = previous
	elif menu_kind in ["skills", "items"]:
		_clear_aim()
	else:
		model.cancel_selection()
		_clear_aim()
	_refresh()

func _target_candidates() -> Array:
	return model.target_candidates(model.actor_by_id(model.selected_id), _aim_skill())

func _sync_navigation() -> void:
	var ready = model.party.filter(func(actor): return model.is_ready(actor))
	if not ready.any(func(actor): return actor["id"] == party_focus_id):
		party_focus_id = "" if ready.is_empty() else ready[0]["id"]
	if not model.selected_id.is_empty() and not model.is_ready(model.actor_by_id(model.selected_id)):
		model.cancel_selection()
	if model.selected_id.is_empty():
		if not menu_kind.is_empty():
			_clear_aim()
		return
	if menu_kind == "target":
		var candidates = _target_candidates()
		if candidates.is_empty():
			var previous = target_return_menu
			_clear_aim()
			menu_kind = previous
		else:
			if not candidates.any(func(actor): return actor["id"] == target_focus_id):
				target_focus_id = candidates[0]["id"]
			board.aiming_target_id = target_focus_id

func _enabled_index(buttons: Array, current: int, step: int = 1) -> int:
	if buttons.is_empty():
		return -1
	for offset in range(1, buttons.size() + 1):
		var index = posmod(current + offset * step, buttons.size())
		if not buttons[index].disabled:
			return index
	return -1

func _sync_hands() -> void:
	var free = model.action.is_empty() and model.outcome == "running"
	for index in range(cards.size()):
		cards[index]["button"].get_meta("battle_hand").active = free and not settings_open and model.selected_id.is_empty() and model.party[index]["id"] == party_focus_id
	if command_index >= 0 and command_buttons[command_index].disabled and free:
		command_index = maxi(0, _enabled_index(command_buttons, command_index))
	for index in range(command_buttons.size()):
		command_buttons[index].get_meta("battle_hand").active = free and not settings_open and not model.selected_id.is_empty() and menu_kind.is_empty() and index == command_index
	if not list_buttons.is_empty():
		list_index = clampi(list_index, 0, list_buttons.size() - 1)
		if list_buttons[list_index].disabled and free:
			list_index = maxi(0, _enabled_index(list_buttons, list_index))
	for index in range(list_buttons.size()):
		list_buttons[index].get_meta("battle_hand").active = free and not settings_open and index == list_index and not list_buttons[index].disabled
	for index in range(settings_rows.size()):
		settings_rows[index].get_meta("battle_hand").active = settings_open and index == settings_index
	board.aiming_skill = _aim_skill() if menu_kind == "target" and not settings_open else {}
	board.aiming_target_id = target_focus_id if menu_kind == "target" and not settings_open else ""

func _navigate(direction: Vector2) -> void:
	if settings_open:
		if direction.y != 0:
			settings_index = posmod(settings_index + int(direction.y), 2)
		else:
			_adjust_setting(int(direction.x))
	elif not model.action.is_empty() or model.outcome != "running":
		return
	elif model.selected_id.is_empty():
		var ready = model.party.filter(func(actor): return model.is_ready(actor))
		if ready.is_empty():
			return
		var current = 0
		for index in range(ready.size()):
			if ready[index]["id"] == party_focus_id:
				current = index
		var step = int(direction.x if direction.x != 0 else direction.y)
		party_focus_id = ready[posmod(current + step, ready.size())]["id"]
	elif menu_kind == "target":
		var candidates = _target_candidates()
		if candidates.is_empty() or _aim_skill().get("target", "") == "all":
			return
		var current = 0
		for index in range(candidates.size()):
			if candidates[index]["id"] == target_focus_id:
				current = index
		var step = int(direction.x if direction.x != 0 else direction.y)
		target_focus_id = candidates[posmod(current + step, candidates.size())]["id"]
	elif menu_kind in ["skills", "items"]:
		list_index = maxi(0, _enabled_index(list_buttons, list_index, int(direction.y if direction.y != 0 else direction.x)))
	else:
		var step = int(direction.x) if direction.x != 0 else int(direction.y) * 2
		command_index = maxi(0, _enabled_index(command_buttons, command_index, step))
	_refresh()

func _confirm_navigation() -> void:
	if settings_open:
		_adjust_setting(1)
		return
	if model.outcome != "running":
		if encounter_mode:
			if model.outcome == "defeat":
				restart_exploration_requested.emit.call_deferred()
		else:
			_start(model.outcome in ["victory", "escaped"])
		return
	if not model.action.is_empty():
		return
	if model.selected_id.is_empty():
		for index in range(model.party.size()):
			if model.party[index]["id"] == party_focus_id:
				_on_party_clicked(index)
				return
	elif menu_kind == "target":
		_confirm("" if _aim_skill().get("target", "") == "all" else target_focus_id)
	elif menu_kind in ["skills", "items"]:
		if not list_buttons.is_empty() and not list_buttons[list_index].disabled:
			list_buttons[list_index].pressed.emit()
	elif not command_buttons[command_index].disabled:
		command_buttons[command_index].pressed.emit()

func _adjust_setting(step: int) -> void:
	if settings_index == 0:
		model.mode = "Active" if model.mode == "Wait" else "Wait"
		mode_picker.select(0 if model.mode == "Wait" else 1)
	else:
		model.battle_speed += step
	_refresh()

func _reset_navigation_hold() -> void:
	joy_axes = Vector2.ZERO
	held_direction = Vector2.ZERO
	repeat_remaining = 0.0

func _hold_navigation(direction: Vector2) -> void:
	if held_direction == direction:
		return
	held_direction = direction
	repeat_remaining = 0.35
	if direction != Vector2.ZERO:
		_navigate(direction)

func _repeat_navigation(delta: float) -> void:
	if get_viewport().gui_get_focus_owner() is LineEdit:
		_reset_navigation_hold()
		return
	if held_direction == Vector2.ZERO:
		return
	repeat_remaining -= delta
	if repeat_remaining <= 0.0:
		repeat_remaining = 0.12
		_navigate(held_direction)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_navigation_hold()

func _input(event: InputEvent) -> void:
	if _handle_battle_input(event):
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if _handle_battle_input(event):
		get_viewport().set_input_as_handled()

func _handle_battle_input(event: InputEvent) -> bool:
	if model == null or get_viewport().gui_get_focus_owner() is LineEdit:
		return false
	if event is InputEventJoypadMotion:
		if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			return false
		var axis = 0 if event.axis == JOY_AXIS_LEFT_X else 1
		joy_axes[axis] = event.axis_value
		var direction = Vector2.ZERO
		var threshold = 0.30 if held_direction != Vector2.ZERO else 0.55
		if joy_axes.length() >= threshold:
			direction = Vector2(signf(joy_axes.x), 0) if absf(joy_axes.x) >= absf(joy_axes.y) else Vector2(0, signf(joy_axes.y))
		_hold_navigation(direction)
		return true
	if event is InputEventJoypadButton:
		var directions = {JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT, JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN}
		if directions.has(event.button_index):
			if event.pressed:
				_hold_navigation(directions[event.button_index])
			elif held_direction == directions[event.button_index]:
				_hold_navigation(Vector2.ZERO)
			return true
		if not event.pressed:
			return false
		match event.button_index:
			JOY_BUTTON_A: _confirm_navigation()
			JOY_BUTTON_B: _cancel()
			JOY_BUTTON_START:
				settings_open = not settings_open
				_refresh()
			_: return false
		return true
	if not event is InputEventKey or not event.pressed:
		return false
	var directions = {KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT, KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN}
	if directions.has(event.keycode):
		_navigate(directions[event.keycode])
		return true
	if event.echo:
		return true
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_Z: _confirm_navigation()
		KEY_ESCAPE, KEY_X: _cancel()
		KEY_TAB:
			settings_open = not settings_open
		KEY_1, KEY_2, KEY_3, KEY_4:
			if not settings_open:
				_on_party_clicked(event.keycode - KEY_1)
		KEY_A:
			if not settings_open: _choose_action("attack")
		KEY_H:
			if not settings_open: _set_menu("skills")
		KEY_I:
			if not settings_open: _set_menu("items")
		KEY_F:
			if not settings_open: _escape()
		KEY_F3: debug_button.button_pressed = not debug_button.button_pressed
		KEY_F5: _start(false)
		KEY_SPACE: pause_button.button_pressed = not pause_button.button_pressed
		_: return false
	_refresh()
	return true
