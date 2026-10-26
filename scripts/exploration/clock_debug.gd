extends PanelContainer
## Ferramenta de desenvolvimento. Não é menu de pousada nem regra de tempo das áreas.
signal edited
var session
var status: Label
var hours: SpinBox
var minutes: SpinBox
var set_button: Button
var advance_button: Button
var morning_button: Button
var rest_button: Button

func bind_session(value) -> void:
	session = value
	if is_node_ready():
		hours.value = session.clock.hour()
		minutes.value = session.clock.minute()
		refresh()

func _ready() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("182b34")
	style.border_color = Color("829e9d")
	style.set_border_width_all(1)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 12)
	add_theme_stylebox_override("panel", style)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_label(column, "RELÓGIO · DEPURAÇÃO [F3]")
	status = _label(column, "")
	var row = HBoxContainer.new()
	column.add_child(row)
	hours = _spin(row, 0, 23, 1)
	_label(row, ":")
	minutes = _spin(row, 0, 59, 1)
	set_button = _button(row, "Definir horário", _set_time)
	row = HBoxContainer.new()
	column.add_child(row)
	advance_button = _button(row, "Evento: +180 min", _advance_event)
	morning_button = _button(row, "Evento: 08:00", _morning_event)
	rest_button = _button(column, "Descanso: definir 07:00 (somente horário)", _rest)
	_label(column, "Avanço automático somente no mapa-múndi.")
	visibility_changed.connect(_visibility_changed)
	hours.value = session.clock.hour()
	minutes.value = session.clock.minute()
	refresh()

func _label(parent: Node, text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	parent.add_child(label)
	return label

func _spin(parent: Node, low: int, high: int, value: int) -> SpinBox:
	var spin = SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size.x = 74
	parent.add_child(spin)
	# Tab continua sendo o menu de equipe; campos só recebem foco por clique explícito.
	spin.focus_mode = Control.FOCUS_NONE
	spin.get_line_edit().focus_mode = Control.FOCUS_CLICK
	spin.get_line_edit().text_submitted.connect(func(_text): _release_field_focus())
	return spin

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_release_field_focus)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _release_field_focus() -> void:
	var viewport = get_viewport()
	if viewport == null:
		return
	var focus = viewport.gui_get_focus_owner()
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()

func refresh() -> void:
	if status == null or session == null:
		return
	var allowed: bool = session.can_advance_world_time()
	status.text = "%s · %s\nÁrea: %s · automático: %s" % [session.clock.time_text(), session.clock.period_label(),
		session.world.data.get("area_type", "não classificada"), "ativo" if allowed else "pausado"]

func _visibility_changed() -> void:
	if not is_visible_in_tree():
		_release_field_focus()

func _set_time() -> void:
	session.clock.set_time(int(hours.value), int(minutes.value))
	refresh()
	edited.emit()

func _advance_event() -> void:
	session.clock.advance_time(180)
	refresh()
	edited.emit()

func _morning_event() -> void:
	session.clock.set_time(8, 0)
	refresh()
	edited.emit()

func _rest() -> void:
	session.rest_at_inn()
	refresh()
	edited.emit()
