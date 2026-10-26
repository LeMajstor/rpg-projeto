extends Control
signal battle_finished(result: String)
signal restart_exploration_requested
const Battle = preload("res://scripts/combat/battle_model.gd")
const Field = preload("res://scripts/ui/battlefield.gd")

var model
var definitions: Dictionary
var board
var preset_picker: OptionButton
var mode_picker: OptionButton
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
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	root.add_child(controls)
	pause_button = CheckButton.new()
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.text = "Pausa [Espaço]"
	controls.add_child(pause_button)
	controls.add_child(_label("Velocidade", 14))
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
	board.target_clicked.connect(_on_field_clicked)
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
	command_buttons.append(_add_button(grid, "Atacar [A]", func(): _choose_action("attack")))
	command_buttons.append(_add_button(grid, "Habilidades [H]", func(): _set_menu("skills")))
	command_buttons.append(_add_button(grid, "Itens [I]", func(): _set_menu("items")))
	command_buttons.append(_add_button(grid, "Fugir [F]", _escape))
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
	var footer = "1–4: aliado pronto   ·   clique: alvo / centro da área   ·   Esc: cancelar seleção"
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
	var button = _add_button(box, "Aliado %d" % (index + 1), func(): _on_party_clicked(index))
	var stats = _label("", 13)
	box.add_child(stats)
	var hp = _bar(Color("64cfac"))
	box.add_child(hp)
	var mp = _bar(Color("8199ee"))
	box.add_child(mp)
	var atb = _bar(Color("edc776"))
	box.add_child(atb)
	cards.append({"button": button, "stats": stats, "hp": hp, "mp": mp, "atb": atb})

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

func _start(preserve: bool) -> void:
	if encounter_mode:
		return # O ciclo do encontro pertence à sessão, não ao laboratório.
	if model.start(preset_picker.selected, preserve, int(seed_input.value)):
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

func _set_menu(kind: String) -> void:
	if model.selected_id.is_empty() or not model.action.is_empty():
		return
	_clear_aim()
	menu_kind = kind
	_refresh()

func _choose_action(id: String, item: String = "") -> void:
	if model.selected_id.is_empty() or not model.action.is_empty():
		return
	aim_id = id
	aim_item = item
	menu_kind = "target"
	board.aiming_skill = _aim_skill()
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
		_clear_aim()
	_refresh()

func _on_field_clicked(id: String, point: Vector2) -> void:
	if menu_kind == "target":
		_confirm(id, point)
	elif not id.is_empty() and model.select_actor(id):
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
	var state = "SELEÇÃO / TEMPO PAUSADO" if model.is_waiting() else "SIMULAÇÃO EM CURSO"
	if pause_button.button_pressed:
		state = "PAUSA DE DEPURAÇÃO"
	if model.outcome != "running":
		state = "BATALHA ENCERRADA"
	status_label.text = state
	continue_button.disabled = model.outcome not in ["victory", "escaped"]
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
		card["button"].text = "[%d] %s · %s" % [index + 1, actor["short_name"], tag]
		card["button"].disabled = model.outcome != "running" or not model.action.is_empty() or (not ready and aim_item.is_empty())
		card["stats"].text = "HP %d/%d   MP %d/%d   INI %.0f\nATB %.0f%%" % [actor["hp"], actor["max_hp"], actor["mp"], actor["max_mp"], model.effective_ini(actor), actor["atb"] * 100]
		card["hp"].value = float(actor["hp"]) / actor["max_hp"] * 100
		card["mp"].value = float(actor["mp"]) / actor["max_mp"] * 100
		card["atb"].value = actor["atb"] * 100
	var key = "%s|%s|%s|%s|%s|%s|%s" % [model.selected_id, menu_kind, aim_id, aim_item, str(model.inventory), str(_target_status()), str(model.action.is_empty())]
	if key != last_menu_key:
		last_menu_key = key
		_rebuild_action_menu()
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
	var actor = model.actor_by_id(model.selected_id)
	if actor.is_empty():
		var help = _label("Espere uma barra completar.\nEscolha qualquer aliado PRONTO\npara abrir seus comandos.", 14)
		action_menu.add_child(help)
		return
	var busy = not model.action.is_empty()
	if menu_kind == "skills":
		for id in actor["skills"]:
			var skill = definitions["skills"][id]
			var button = _add_button(action_menu, "%s · %d MP" % [skill["name"], skill["mp_cost"]], _choose_action.bind(id))
			button.disabled = busy or actor["mp"] < skill["mp_cost"]
	elif menu_kind == "items":
		for id in definitions["items"]:
			var button = _add_button(action_menu, "%s ×%d" % [definitions["items"][id]["name"], model.inventory[id]], _choose_action.bind("item", id))
			button.disabled = busy or model.inventory[id] <= 0
	elif menu_kind == "target":
		var skill = _aim_skill()
		if skill["target"] == "all":
			var button = _add_button(action_menu, "Confirmar: todos os inimigos", _confirm)
			button.disabled = busy
		elif skill["target"] == "circle":
			action_menu.add_child(_label("Mova o mouse sobre o campo.\nClique para fixar o centro da área.\nOs atingidos são avaliados no impacto.", 14, Color("a4d8f8")))
		else:
			action_menu.add_child(_label("Escolha o alvo:", 14))
			var group = model.party if not aim_item.is_empty() else model.enemies
			var row = HBoxContainer.new()
			action_menu.add_child(row)
			for target in group:
				var valid = not model.targets_for(actor, skill, target["id"]).is_empty()
				var button = _add_button(row, target["id"].to_upper(), _confirm.bind(target["id"], target["logical_position"]))
				button.disabled = not valid or busy
				button.tooltip_text = target["name"]
	else:
		action_menu.add_child(_label("Escolha um comando.\nWait pausa enquanto você seleciona.\nActive mantém inimigos em movimento.", 14))
	var back = _add_button(action_menu, "Cancelar seleção [Esc]", _cancel)
	back.disabled = busy

func _refresh_debug() -> void:
	_sync_fullscreen_editor()
	var lines: Array[String] = []
	lines.append("Semente da batalha: %d" % model.simulation_seed)
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
	model.cancel_selection()
	_clear_aim()
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var focus = get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			_on_party_clicked(event.keycode - KEY_1)
		KEY_A:
			_choose_action("attack")
		KEY_H:
			_set_menu("skills")
		KEY_I:
			_set_menu("items")
		KEY_F:
			_escape()
		KEY_ESCAPE:
			_cancel()
		KEY_F3:
			debug_button.button_pressed = not debug_button.button_pressed
		KEY_F5:
			_start(false)
		KEY_SPACE:
			pause_button.button_pressed = not pause_button.button_pressed
	_refresh()
