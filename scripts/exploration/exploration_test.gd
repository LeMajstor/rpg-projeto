extends Control
const Session = preload("res://scripts/exploration/exploration_session.gd")
const MapView = preload("res://scripts/exploration/exploration_view.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const CombatScene = preload("res://scenes/combat_lab.tscn")
const ClockDebug = preload("res://scripts/exploration/clock_debug.gd")

var session
var map_ui: Control
var map_view
var combat_ui
var menu_panel: PanelContainer
var leader_buttons: Array[Button] = []
var party_labels: Array[Label] = []
var message_label: Label
var leader_label: Label
var interact_button: Button
var dialogue_overlay: Control
var dialogue_panel: PanelContainer
var dialogue_speaker: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var dialogue_choice_buttons: Array[Button] = []
var dialogue_next: Button
var dialogue_signature = ""
var transition_overlay: ColorRect
var area_label: Label
var map_frame: Control
var camera_reference_size = Vector2(720, 480)
var preferred_axis = "x"
var capture_path = ""
var capture_frames = 0
var clock_panel

func _ready() -> void:
	_new_session()
	_build_ui()
	_refresh_map()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")

func _new_session() -> void:
	var battle_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json"))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/areas.json"))
	var definitions = Catalog.load_definitions()
	var initial_id: String = catalog["initial_area_id"]
	session = Session.new(battle_data, definitions[initial_id], definitions)
	session.transition_duration = float(catalog.get("transition_duration", 0.36))
	camera_reference_size = Vector2(720, 480)
	var reference = catalog.get("camera_reference_size", [720, 480])
	if Catalog.numbers(reference, 2) and reference[0] > 0 and reference[1] > 0:
		camera_reference_size = Vector2(reference[0], reference[1])
	preferred_axis = "x"

func _build_ui() -> void:
	var app_theme = Theme.new()
	app_theme.default_font_size = 16
	theme = app_theme
	var background = ColorRect.new()
	background.color = Color("0c181e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	map_ui = Control.new()
	map_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(map_ui)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	map_ui.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	column.add_child(_label("EXPLORAÇÃO / LABORATÓRIO AMPLIADO", 27, Color("e7f0ed")))
	column.add_child(_label("Casa e vila: NPCs · mundo aberto: florestas, colinas e mar · dungeon: 6 encontros · gráficos provisórios", 15, Color("99bdb7")))
	area_label = _label("", 15, Color("efd49b"))
	column.add_child(area_label)
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 14)
	column.add_child(toolbar)
	_button(toolbar, "Equipe / trocar líder [Tab]", _toggle_menu)
	interact_button = _button(toolbar, "Interagir [E]", _try_encounter)
	_button(toolbar, "Reiniciar teste", _restart)
	leader_label = _label("", 16, Color("efd49b"))
	leader_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toolbar.add_child(leader_label)
	map_frame = Control.new()
	map_frame.custom_minimum_size = Vector2(760, 420)
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.clip_contents = true
	column.add_child(map_frame)
	map_view = MapView.new()
	map_view.session = session
	map_view.camera_reference_size = camera_reference_size
	map_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_frame.add_child(map_view)
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label = _label("", 15, Color("eccd95"))
	column.add_child(message_label)
	var party_row = HBoxContainer.new()
	party_row.add_theme_constant_override("separation", 12)
	column.add_child(party_row)
	for member in session.battle.party:
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style = StyleBoxFlat.new()
		style.bg_color = Color("1b3036")
		style.set_corner_radius_all(7)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		panel.add_theme_stylebox_override("panel", style)
		party_row.add_child(panel)
		var label = _label("", 15, Color(member["color"]))
		panel.add_child(label)
		party_labels.append(label)
	column.add_child(_label("WASD / setas: andar   ·   Tab / Esc: equipe   ·   E: interagir / avançar fala   ·   F3: trilha, colisões e rotas", 14, Color("93adae")))
	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	menu_panel.offset_left = -240
	menu_panel.offset_top = -180
	menu_panel.offset_right = 240
	menu_panel.offset_bottom = 180
	menu_panel.custom_minimum_size = Vector2(480, 360)
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color("182b34")
	menu_style.set_border_width_all(2)
	menu_style.border_color = Color("829e9d")
	menu_style.set_corner_radius_all(10)
	for side in ["left", "right", "top", "bottom"]:
		menu_style.set("content_margin_" + side, 22)
	menu_panel.add_theme_stylebox_override("panel", menu_style)
	map_ui.add_child(menu_panel)
	var menu_column = VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 10)
	menu_panel.add_child(menu_column)
	menu_column.add_child(_label("LÍDER DE EXPLORAÇÃO", 22, Color("f0dfb4")))
	menu_column.add_child(_label("Os quatro continuam ativos. O mapa pausa neste menu.", 14))
	for member in session.battle.party:
		leader_buttons.append(_button(menu_column, member["short_name"], _choose_leader.bind(member["id"])))
	_button(menu_column, "Fechar [Tab / Esc]", _toggle_menu)
	if OS.is_debug_build():
		clock_panel = ClockDebug.new()
		clock_panel.bind_session(session)
		clock_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		clock_panel.offset_left = -470
		clock_panel.offset_right = -24
		clock_panel.offset_top = 200
		clock_panel.hide()
		clock_panel.edited.connect(_refresh_map)
		map_ui.add_child(clock_panel)
	_build_dialogue()
	transition_overlay = ColorRect.new()
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color.BLACK
	transition_overlay.hide()
	add_child(transition_overlay)

func _build_dialogue() -> void:
	dialogue_overlay = Control.new()
	dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_ui.add_child(dialogue_overlay)
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_overlay.add_child(shade)
	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.1
	dialogue_panel.anchor_right = 0.9
	dialogue_panel.anchor_top = 1
	dialogue_panel.anchor_bottom = 1
	dialogue_panel.offset_top = -320
	dialogue_panel.offset_bottom = -36
	var style = StyleBoxFlat.new()
	style.bg_color = Color("182b34")
	style.border_color = Color("dfc38c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 22)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_overlay.add_child(dialogue_panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	dialogue_panel.add_child(column)
	dialogue_speaker = _label("", 23, Color("f0dfb4"))
	column.add_child(dialogue_speaker)
	dialogue_text = _label("", 19)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(dialogue_text)
	dialogue_choices = VBoxContainer.new()
	dialogue_choices.add_theme_constant_override("separation", 8)
	column.add_child(dialogue_choices)
	dialogue_next = _button(column, "Avançar [E / Enter]", _advance_dialogue)
	column.add_child(_label("Mapa pausado durante a conversa · respostas: clique ou teclas numéricas", 13, Color("99bdb7")))

func _label(text: String, font_size: int, color: Color = Color("c2d5d0")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _physics_process(delta: float) -> void:
	if session.state not in ["exploration", "transition"]:
		return
	var direction = Vector2(
		float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT)),
		float(_held(KEY_S, KEY_DOWN)) - float(_held(KEY_W, KEY_UP)))
	if _clock_field_focused():
		direction = Vector2.ZERO
	session.move(direction, delta, preferred_axis)
	session.tick(delta)
	_refresh_map()

func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)

func _toggle_menu() -> void:
	if session.state != "exploration" or session.dialogue.opened:
		return
	session.world.menu_open = not session.world.menu_open
	session.world.moving = false
	_refresh_map()

func _choose_leader(id: String) -> void:
	if session.state == "exploration" and not session.dialogue.opened and session.world.choose_leader(id):
		session.notice = "Líder alterado. A fila conserva o caminho e as posições."
	_refresh_map()

func _try_encounter() -> void:
	if session.dialogue.opened:
		_advance_dialogue()
		return
	var result: String = session.interact()
	if result != "battle":
		_refresh_map()
		return
	map_ui.hide()
	combat_ui = CombatScene.instantiate()
	combat_ui.configure_encounter(session.battle)
	combat_ui.battle_finished.connect(_on_battle_finished)
	combat_ui.restart_exploration_requested.connect(_restart)
	add_child(combat_ui)

func _advance_dialogue() -> void:
	session.advance_dialogue()
	_refresh_map()

func _choose_response(index: int) -> void:
	session.choose_response(index)
	_refresh_map()

func _refresh_dialogue() -> void:
	dialogue_overlay.visible = session.dialogue.opened
	if not session.dialogue.opened:
		dialogue_signature = ""
		return
	var signature: String = session.dialogue.dialogue_id + ":" + session.dialogue.node_id
	if signature == dialogue_signature:
		return
	dialogue_signature = signature
	dialogue_speaker.text = session.dialogue.speaker
	dialogue_text.text = session.dialogue.current().get("text", "")
	for child in dialogue_choices.get_children():
		dialogue_choices.remove_child(child)
		child.queue_free()
	dialogue_choice_buttons.clear()
	var options: Array = session.dialogue.choices()
	for index in range(options.size()):
		dialogue_choice_buttons.append(_button(dialogue_choices, "%d · %s" % [index + 1, options[index]["text"]], _choose_response.bind(index)))
	dialogue_next.visible = options.is_empty()
	dialogue_next.text = "Encerrar [E / Enter]" if session.dialogue.current().get("next", "").is_empty() else "Avançar [E / Enter]"

func _on_battle_finished(_result: String) -> void:
	if not session.finish_encounter():
		return
	if session.state == "defeat":
		return # Game Over permanece na tela de combate até reinício explícito.
	_remove_combat()
	map_ui.show()
	_refresh_map()

func _remove_combat() -> void:
	if is_instance_valid(combat_ui):
		remove_child(combat_ui)
		combat_ui.queue_free()
	combat_ui = null

func _restart() -> void:
	_remove_combat()
	_new_session()
	map_view.session = session
	map_view.camera_reference_size = camera_reference_size
	map_view.show_path = false
	if clock_panel != null:
		clock_panel.bind_session(session)
		clock_panel.hide()
	map_ui.show()
	_refresh_map()

func _refresh_map() -> void:
	if map_ui == null:
		return
	menu_panel.visible = session.world.menu_open
	area_label.text = "Área: %s" % session.world.data.get("label", session.area_id)
	transition_overlay.visible = session.state == "transition"
	transition_overlay.color.a = session.transition_alpha
	_refresh_dialogue()
	interact_button.disabled = not session.world.can_interact()
	var candidate: Dictionary = session.world.interaction_candidate()
	interact_button.text = "Interagir [E]" if candidate.is_empty() else "%s [E]" % candidate["label"]
	leader_label.text = "Líder: %s" % session.battle.actor_by_id(session.world.party_order[0])["short_name"]
	message_label.text = "E · %s%s" % [candidate["label"], " / iniciar combate" if candidate["kind"] == "encounter" else " / interagir"] if not candidate.is_empty() else session.notice
	if not session.interaction_error.is_empty():
		message_label.text = session.interaction_error
	for index in range(session.battle.party.size()):
		var member = session.battle.party[index]
		var leader = member["id"] == session.world.party_order[0]
		party_labels[index].text = "%s%s\nHP %d/%d   MP %d/%d" % [member["short_name"], " · LÍDER" if leader else "", member["hp"], member["max_hp"], member["mp"], member["max_mp"]]
		leader_buttons[index].text = "%s%s" % [member["short_name"], " · líder atual" if leader else ""]
	map_view.queue_redraw()
	if clock_panel != null:
		clock_panel.refresh()

func _clock_field_focused() -> bool:
	var focus = get_viewport().gui_get_focus_owner()
	return clock_panel != null and focus != null and clock_panel.is_ancestor_of(focus)

func _unhandled_key_input(event: InputEvent) -> void:
	if session.state != "exploration" or not event is InputEventKey or not event.pressed or event.echo:
		return
	if _clock_field_focused() and event.keycode != KEY_F3:
		return
	if session.dialogue.opened:
		if event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_advance_dialogue()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_choose_response(int(event.keycode - KEY_1))
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_W, KEY_S, KEY_UP, KEY_DOWN:
			preferred_axis = "y"
		KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT:
			preferred_axis = "x"
		KEY_TAB, KEY_ESCAPE:
			_toggle_menu()
		KEY_E:
			_try_encounter()
		KEY_F3:
			map_view.show_path = not map_view.show_path
			if clock_panel != null:
				clock_panel.visible = map_view.show_path
				if not clock_panel.visible and _clock_field_focused():
					get_viewport().gui_get_focus_owner().release_focus()
	_refresh_map()

func _process(_delta: float) -> void:
	if capture_path.is_empty():
		return
	capture_frames += 1
	if capture_frames == 12:
		_capture.call_deferred()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var error = get_viewport().get_texture().get_image().save_png(capture_path)
	print("EXPLORATION CAPTURE ", error, " ", capture_path)
	get_tree().quit(error)
