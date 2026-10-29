extends Control
const Equipment = preload("res://scripts/damage/damage_equipment.gd")
const Model = preload("res://scripts/damage/damage_lab_model.gd")
const Calculator = preload("res://scripts/damage/damage_calculator.gd")
const Export = preload("res://scripts/damage/damage_export.gd")
const PresetLibrary = preload("res://scripts/damage/damage_presets.gd")
const Field = preload("res://scripts/ui/damage_field.gd")
const Histogram = preload("res://scripts/ui/damage_histogram.gd")
const ATTRIBUTES = [["HP", "hp"], ["MP", "mp"], ["INI", "ini"], ["ATQ F", "physical_attack"], ["DEF F", "physical_defense"], ["ATQ D", "ranged_attack"], ["DEF D", "ranged_defense"], ["MAG", "magic_power"], ["DEF M", "magic_defense"], ["INT", "intelligence"], ["VIG", "vigor"], ["CRI", "critical_base"], ["EVA", "evasion_base"]]
const CRITICAL_MODES = ["rolled", "off", "forced"]
var model
var preset_library
var preset_storage_path = PresetLibrary.DEFAULT_PATH
var preset_pickers: Dictionary = {}
var preset_load_buttons: Dictionary = {}
var preset_save_buttons: Dictionary = {}
var preset_update_buttons: Dictionary = {}
var preset_delete_buttons: Dictionary = {}
var preset_status: Dictionary = {}
var preset_dialog: ConfirmationDialog
var preset_name_edit: LineEdit
var preset_error: Label
var pending_preset: Dictionary = {}
var field
var histogram
var profile_labels: Dictionary = {}
var profile_edits: Dictionary = {}
var weapon_picker: OptionButton
var armor_picker: OptionButton
var weapon_bonus: SpinBox
var armor_bonus: SpinBox
var armor_ranged_bonus: SpinBox
var armor_evasion_bonus: SpinBox
var enemy_multiplier: SpinBox
var equipment_title: Label
var enemy_critical_title: Label
var composition_labels: Dictionary = {}
var action_picker: OptionButton
var physical_mode_picker: OptionButton
const PHYSICAL_MODES = ["weapon", "melee", "ranged"]
var seed_edit: SpinBox
var weapon_chance: SpinBox
var weapon_multiplier: SpinBox
var power_edit: SpinBox
var mp_cost_edit: SpinBox
var evasion_allowed: CheckBox
var critical_allowed: CheckBox
var variation_toggle: CheckBox
var variation_edit: SpinBox
var item_edit: SpinBox
var buff_edit: SpinBox
var conversion_edit: SpinBox
var critical_mode: OptionButton
var chance_label: Label
var notice: Label
var field_caption: Label
var history_picker: OptionButton
var export_button: Button
var export_dialog: FileDialog
var pending_export: Dictionary = {}
var last_export_path = ""
var summary: RichTextLabel
var calculation: RichTextLabel
var sample_detail: RichTextLabel
var conditions: RichTextLabel
var samples_tree: Tree
var result_tabs: TabContainer
var run_buttons: Array[Button] = []
var edit_controls: Array[Control] = []
var focus_controls: Array[Control] = []
var last_result: Dictionary = {}
var syncing = false
var busy = false
var joy_axis = Vector2.ZERO
var held_direction = Vector2.ZERO
var repeat_timer = 0.0

func _ready() -> void:
	model = Model.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/damage_lab.json")))
	preset_library = PresetLibrary.new(model.data, preset_storage_path)
	_build_ui()
	_rebuild_preset_lists()
	_sync_controls()
	_preview()
	if not preset_library.load_error.is_empty():
		notice.text = preset_library.load_error
	seed_edit.grab_focus()
	Input.joy_connection_changed.connect(func(_id, connected):
		if not connected: _reset_hold())

func _build_ui() -> void:
	var app_theme = Theme.new()
	app_theme.default_font_size = 14
	theme = app_theme
	var style = StyleBoxFlat.new()
	style.bg_color = Color("20364b")
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	app_theme.set_stylebox("normal", "Button", style)
	var bg = ColorRect.new()
	bg.color = Color("0b121e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(_label("LABORATÓRIO / DANOS E AFLIÇÕES", 26, Color("e5eef8")))
	root.add_child(_label("Proporcional v1 · fichas e parâmetros experimentais · independente do combate da exploração", 14, Color("a6bdd3")))
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)
	seed_edit = _number(toolbar, "Semente", 0, 2147483647, 1, func(value):
		if not syncing:
			model.set_seed(int(value))
			_preview())
	seed_edit.custom_minimum_size.x = 110
	_button(toolbar, "Reiniciar sequência", func():
		model.restart_sequence()
		notice.text = "Sequência reiniciada. Repetir o caso reproduz os mesmos sorteios.")
	for count in [1, 10, 100, 1000]:
		var button = _button(toolbar, "%d× [F%d]" % [count, 6 + run_buttons.size()], _execute.bind(count))
		run_buttons.append(button)
	_button(toolbar, "Trocar lados", func():
		model.swap_roles()
		_sync_controls()
		_preview())
	_button(toolbar, "Restaurar caso [F5]", _reset_case)
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var editor = VBoxContainer.new()
	editor.custom_minimum_size.x = 580
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.size_flags_stretch_ratio = 1.0
	editor.add_theme_constant_override("separation", 8)
	var editor_scroll = ScrollContainer.new()
	editor_scroll.custom_minimum_size.x = 600
	editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_stretch_ratio = 1.0
	editor_scroll.follow_focus = true
	editor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(editor_scroll)
	editor_scroll.add_child(editor)
	var presets_row = HBoxContainer.new()
	presets_row.add_theme_constant_override("separation", 10)
	editor.add_child(presets_row)
	for side in ["ally", "enemy"]:
		var box = _panel(presets_row, "PRESET DO ALIADO" if side == "ally" else "PRESET DO MONSTRO")
		var load_row = HBoxContainer.new()
		box.add_child(load_row)
		var picker = _select(load_row, ["Ficha atual / manual"], _choose_preset.bind(side))
		picker.fit_to_longest_item = false
		picker.clip_text = true
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_pickers[side] = picker
		preset_load_buttons[side] = _button(load_row, "Carregar", _reload_preset.bind(side))
		var buttons = HBoxContainer.new()
		box.add_child(buttons)
		preset_save_buttons[side] = _button(buttons, "Salvar…", _request_preset_save.bind(side))
		preset_update_buttons[side] = _button(buttons, "Atualizar", _update_preset.bind(side))
		preset_delete_buttons[side] = _button(buttons, "Excluir", _delete_preset.bind(side))
		preset_status[side] = _label("Ficha atual", 12, Color("b9d8e7"))
		box.add_child(preset_status[side])
	preset_dialog = ConfirmationDialog.new()
	preset_dialog.title = "Salvar preset"
	preset_dialog.exclusive = true
	preset_dialog.dialog_hide_on_ok = false
	preset_dialog.get_ok_button().text = "Salvar preset"
	preset_dialog.get_cancel_button().text = "Cancelar"
	var name_box = VBoxContainer.new()
	name_box.add_child(_label("Nome do preset (até 80 caracteres)", 14))
	preset_name_edit = LineEdit.new()
	preset_name_edit.max_length = 80
	preset_name_edit.select_all_on_focus = true
	preset_name_edit.text_submitted.connect(func(_value): preset_dialog.get_ok_button().pressed.emit())
	name_box.add_child(preset_name_edit)
	preset_error = _label("", 13, Color("edcf91"))
	preset_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_box.add_child(preset_error)
	preset_dialog.add_child(name_box)
	preset_dialog.confirmed.connect(_confirm_preset_save)
	preset_dialog.canceled.connect(_cancel_preset_save)
	add_child(preset_dialog)
	editor.add_child(_label("PRÓXIMO TESTE · aliado: próprios · monstro: diretos", 16, Color("f1d995")))
	var profiles = HBoxContainer.new()
	profiles.add_theme_constant_override("separation", 10)
	editor.add_child(profiles)
	for role in ["attacker", "target"]:
		var box = _panel(profiles, "ATACANTE" if role == "attacker" else "ALVO")
		var actor_label = _label("", 14)
		actor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(actor_label)
		profile_labels[role] = actor_label
		profile_edits[role] = {}
		for attr in ATTRIBUTES:
			var bounds = Calculator.stat_bounds("ally", attr[1])
			profile_edits[role][attr[1]] = _number(box, attr[0], bounds.x, bounds.y, 1, _edit_stat.bind(role, attr[1]))
		profile_edits[role]["evasion_base"].tooltip_text = "EVA própria, sem bônus de armadura. Neste laboratório: 1 EVA = 1%. O total aparece abaixo da ficha. Sem progressão automática implementada neste laboratório."
		var composition_label = _label("", 13, Color("b9d8e7"))
		composition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(composition_label)
		composition_labels[role] = composition_label
	var weapon_box = _panel(editor, "ARMA DO ALIADO · valores de teste")
	equipment_title = weapon_box.get_child(0)
	weapon_picker = _select(weapon_box, model.data["weapons"].map(func(entry): return entry["name"]), _choose_weapon)
	var weapon_row = HBoxContainer.new()
	weapon_box.add_child(weapon_row)
	weapon_bonus = _number(weapon_row, "ATQ F +", 0, 999, 1, func(value):
		if not syncing:
			model.weapon["attack_bonus"] = int(value)
			_preview())
	weapon_chance = _number(weapon_row, "Chance (%)", 0, 100, 0.1, func(value):
		if not syncing:
			model.weapon["critical_chance"] = value
			_preview())
	weapon_multiplier = _number(weapon_row, "Multiplicador", 1, 10, 0.1, func(value):
		if not syncing:
			if model.weapon.get("equipped", true):
				model.weapon["critical_multiplier"] = value
			else:
				model.ally()["unarmed_critical_multiplier"] = value
			_preview())
	var armor_box = _panel(editor, "ARMADURA DO ALIADO · valores de teste")
	armor_picker = _select(armor_box, model.data["armors"].map(func(entry): return entry["name"]), _choose_armor)
	armor_bonus = _number(armor_box, "DEF F +", 0, 999, 1, func(value):
		if not syncing:
			model.armor["defense_bonus"] = int(value)
			_preview())
	armor_ranged_bonus = _number(armor_box, "DEF D +", 0, 999, 1, func(value):
		if not syncing:
			model.armor["ranged_defense_bonus"] = int(value)
			_preview())
	armor_evasion_bonus = _number(armor_box, "EVA +", 0, 100, 1, func(value):
		if not syncing:
			model.armor["evasion_bonus"] = int(value)
			_preview())
	var enemy_box = _panel(editor, "CRÍTICO DO MONSTRO · parâmetro de teste")
	enemy_critical_title = enemy_box.get_child(0)
	enemy_multiplier = _number(enemy_box, "Crit. ×", 1, 10, 0.1, func(value):
		if not syncing:
			model.enemy()["unarmed_critical_multiplier"] = value
			_preview())
	var action_box = _panel(editor, "AÇÃO · potência em multiplicador")
	action_picker = _select(action_box, model.data["actions"].map(func(entry): return entry["name"]), _choose_action)
	var action_row = HBoxContainer.new()
	action_box.add_child(action_row)
	# A seleção explícita permite comparar disparos/contato sem trocar personagem ou arma.
	physical_mode_picker = _select(action_box, ["Físico: da arma (monstro: contato)", "Físico: corpo a corpo", "Físico: distância"], func(index):
		if not syncing:
			model.action["physical_mode"] = PHYSICAL_MODES[index]
			_preview())
	physical_mode_picker.tooltip_text = "Seleciona ATQ F/DEF F ou ATQ D/DEF D. Magia sempre usa MAG/DEF M; distância não depende das coordenadas."
	power_edit = _number(action_row, "Potência ×", 0, 10, 0.1, func(value):
		if not syncing:
			model.action["power"] = value
			_preview())
	mp_cost_edit = _number(action_row, "Custo MP", 0, 999, 1, func(value):
		if not syncing:
			model.action["mp_cost"] = int(value)
			_preview())
	critical_allowed = CheckBox.new()
	critical_allowed.text = "Esta ação permite crítico (somente dano físico)"
	critical_allowed.toggled.connect(func(value):
		if not syncing:
			model.action["critical_allowed"] = value
			_preview())
	action_box.add_child(critical_allowed)
	_register(critical_allowed)
	evasion_allowed = CheckBox.new()
	evasion_allowed.text = "Esta ação permite esquiva (experimental)"
	evasion_allowed.toggled.connect(func(value):
		if not syncing:
			model.action["evasion_allowed"] = value
			_preview())
	action_box.add_child(evasion_allowed)
	_register(evasion_allowed)
	action_box.add_child(_label("Esquiva usa a EVA total do alvo: própria + bônus da armadura.", 12))
	var randomness = _panel(editor, "SORTEIOS E MODIFICADORES · parâmetros experimentais")
	var random_row = HBoxContainer.new()
	randomness.add_child(random_row)
	variation_toggle = CheckBox.new()
	variation_toggle.text = "Variação ligada"
	variation_toggle.toggled.connect(func(value):
		if not syncing:
			model.settings["variation_enabled"] = value
			_preview())
	random_row.add_child(variation_toggle)
	_register(variation_toggle)
	variation_edit = _number(random_row, "± (%)", 0, 100, 0.1, _edit_setting.bind("variation_percent"))
	critical_mode = _select(randomness, ["Crítico: sorteado", "Crítico: desligado", "Crítico: forçado"], func(index):
		if not syncing:
			model.settings["critical_mode"] = CRITICAL_MODES[index]
			_preview())
	chance_label = _label("", 13, Color("b9d8e7"))
	chance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	randomness.add_child(chance_label)
	var modifiers = HBoxContainer.new()
	randomness.add_child(modifiers)
	item_edit = _number(modifiers, "Item CRI (p.p.)", -100, 100, 0.1, _edit_setting.bind("item_bonus"))
	buff_edit = _number(modifiers, "Buff CRI (p.p.)", -100, 100, 0.1, _edit_setting.bind("buff_bonus"))
	conversion_edit = _number(randomness, "1 CRI vale (%)", 0, 10, 0.1, _edit_setting.bind("crit_per_point"))
	conversion_edit.tooltip_text = "Regra aprovada: 1 CRI = 1% de chance-base. Este ajuste permite comparar alternativas apenas no laboratório."
	var output = VBoxContainer.new()
	output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output.size_flags_stretch_ratio = 1.35
	output.add_theme_constant_override("separation", 8)
	body.add_child(output)
	field_caption = _label("PRÉVIA DO PRÓXIMO TESTE", 15, Color("b7d2e4"))
	output.add_child(field_caption)
	field = Field.new()
	field.strike_finished.connect(func(): _set_busy(false))
	output.add_child(field)
	var history_row = HBoxContainer.new()
	output.add_child(history_row)
	history_row.add_child(_label("Resultado", 14))
	history_picker = _select(history_row, ["Nenhuma execução"], _select_history)
	history_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button = _button(history_row, "Exportar JSON [F10]", _request_export)
	export_button.disabled = true
	export_dialog = FileDialog.new()
	export_dialog.title = "Exportar amostras em JSON"
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.filters = PackedStringArray(["*.json ; Amostras do laboratório"])
	export_dialog.use_native_dialog = false
	export_dialog.exclusive = true
	export_dialog.get_ok_button().text = "Salvar JSON"
	export_dialog.get_cancel_button().text = "Cancelar"
	export_dialog.file_selected.connect(_save_export)
	export_dialog.canceled.connect(_cancel_export)
	add_child(export_dialog)
	result_tabs = TabContainer.new()
	result_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_tabs.custom_minimum_size = Vector2(0, 340)
	output.add_child(result_tabs)
	var summary_box = VBoxContainer.new()
	summary_box.name = "Resumo"
	result_tabs.add_child(summary_box)
	summary = _rich(summary_box, 118)
	histogram = Histogram.new()
	histogram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_box.add_child(histogram)
	calculation = _rich(summary_box, 120)
	var samples_box = VBoxContainer.new()
	samples_box.name = "Amostras"
	result_tabs.add_child(samples_box)
	samples_tree = Tree.new()
	samples_tree.columns = 7
	samples_tree.column_titles_visible = true
	samples_tree.hide_root = true
	samples_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for index in range(7):
		samples_tree.set_column_title(index, ["#", "Dano", "HP −", "Resultado", "Var. ×", "Crit. %", "Crit. ×"][index])
		samples_tree.set_column_custom_minimum_width(index, 42 if index == 0 else 65)
	samples_tree.item_selected.connect(_select_sample)
	samples_box.add_child(samples_tree)
	_register(samples_tree, false)
	sample_detail = _rich(samples_box, 120)
	var conditions_box = VBoxContainer.new()
	conditions_box.name = "Condições"
	result_tabs.add_child(conditions_box)
	conditions = _rich(conditions_box, 320)
	conditions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_register(result_tabs.get_tab_bar(), false)
	summary.text = "Execute uma ação ou lote.\nAs condições de cada execução ficam registradas no histórico."
	notice = _label("INI é informativa: este laboratório usa ações manuais, sem ATB.", 13, Color("edcf91"))
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(notice)
	root.add_child(_label("Clique ou selecione o campo e digite · Enter / Tab: confirmar · ←→: ajustar · controle: direcional + botão sul · F6–F9: executar · R: reiniciar sequência", 12, Color("94acc4")))

func _label(text: String, font_size: int = 14, color: Color = Color("c2d3e4")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel(parent: Node, title: String) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("132235")
	style.set_corner_radius_all(7)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 10)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(_label(title, 12, Color("e9cf95")))
	return box

func _register(control: Control, editable: bool = true) -> void:
	control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(_reveal_focused.bind(control))
	focus_controls.append(control)
	if editable:
		edit_controls.append(control)

func _reveal_focused(control: Control) -> void:
	# O texto e a categoria podem alterar a altura dos painéis após o foco inicial.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	var focused = get_viewport().gui_get_focus_owner()
	if focused != control and (focused == null or not control.is_ancestor_of(focused)):
		return
	var parent = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			return
		parent = parent.get_parent()

func _number(parent: Node, label: String, low: float, high: float, step: float, callback: Callable) -> SpinBox:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var caption = _label(label, 13)
	caption.custom_minimum_size.x = 58
	row.add_child(caption)
	var spin = SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = step
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.custom_minimum_size.x = 90
	spin.value_changed.connect(callback)
	var input = spin.get_line_edit()
	input.focus_mode = Control.FOCUS_CLICK
	input.select_all_on_focus = true
	input.focus_exited.connect(_apply_number_text.bind(spin))
	spin.tooltip_text = "Clique no valor ou selecione o campo e digite. Enter confirma."
	row.add_child(spin)
	_register(spin)
	return spin

func _select(parent: Node, names: Array, callback: Callable) -> OptionButton:
	var picker = OptionButton.new()
	for name in names:
		picker.add_item(str(name))
	picker.item_selected.connect(callback)
	parent.add_child(picker)
	_register(picker)
	return picker

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	_register(button)
	return button

func _rich(parent: Node, height: float) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.custom_minimum_size.y = height
	label.add_theme_font_size_override("normal_font_size", 13)
	label.selection_enabled = true
	parent.add_child(label)
	return label

func _select_id(picker: OptionButton, entries: Array, id: String) -> void:
	for index in range(entries.size()):
		if entries[index]["id"] == id:
			picker.select(index)
			return

func _sync_equipment_pickers() -> void:
	for category in ["weapon", "armor"]:
		var picker: OptionButton = weapon_picker if category == "weapon" else armor_picker
		var entries: Array = model.data["weapons" if category == "weapon" else "armors"]
		var selected: String = model.weapon["id"] if category == "weapon" else model.armor["id"]
		picker.clear()
		for item in entries:
			if not Equipment.can_equip(model.ally(), item):
				continue
			picker.add_item(item["name"])
			var index = picker.item_count - 1
			picker.set_item_metadata(index, item["id"])
			if item["id"] == selected:
				picker.select(index)

func _sync_controls() -> void:
	syncing = true
	for role in ["attacker", "target"]:
		var actor: Dictionary = model.attacker if role == "attacker" else model.target
		profile_labels[role].text = actor["name"]
		for character in model.data["characters"]:
			if character["id"] == Equipment.character_id(actor):
				profile_labels[role].tooltip_text = "Personagem: " + character["name"]
				break
		for stat in profile_edits[role]:
			var bounds = Calculator.stat_bounds(actor["side"], stat)
			profile_edits[role][stat].min_value = bounds.x
			profile_edits[role][stat].max_value = bounds.y
			profile_edits[role][stat].value = actor[stat]
	_sync_equipment_pickers()
	_select_id(action_picker, model.data["actions"], model.action["id"])
	seed_edit.value = model.seed_value
	weapon_chance.value = model.weapon["critical_chance"]
	weapon_bonus.value = model.weapon["attack_bonus"]
	armor_bonus.value = model.armor["defense_bonus"]
	armor_ranged_bonus.value = model.armor["ranged_defense_bonus"]
	weapon_bonus.get_parent().get_child(0).text = "ATQ D +" if Equipment.attack_mode(model.weapon) == "ranged" else "ATQ F +"
	physical_mode_picker.select(PHYSICAL_MODES.find(model.action.get("physical_mode", "weapon")))
	physical_mode_picker.disabled = busy or model.action["damage_type"] == "magical"
	armor_evasion_bonus.value = model.armor.get("evasion_bonus", 0)
	weapon_multiplier.value = model.weapon["critical_multiplier"] if model.weapon.get("equipped", true) else model.ally()["unarmed_critical_multiplier"]
	enemy_multiplier.value = model.enemy()["unarmed_critical_multiplier"]
	equipment_title.text = "ARMA DO ALIADO · %s (%s)" % [model.ally()["name"], "atacante" if model.ally_role() == "attacker" else "alvo"]
	enemy_critical_title.text = "CRÍTICO PRÓPRIO · %s · teste sem equipamento" % model.enemy()["name"]
	power_edit.value = model.action["power"]
	mp_cost_edit.value = model.action["mp_cost"]
	critical_allowed.button_pressed = model.action["critical_allowed"]
	evasion_allowed.button_pressed = model.action["evasion_allowed"]
	variation_toggle.button_pressed = model.settings["variation_enabled"]
	variation_edit.value = model.settings["variation_percent"]
	item_edit.value = model.settings["item_bonus"]
	buff_edit.value = model.settings["buff_bonus"]
	conversion_edit.value = model.settings["crit_per_point"]
	critical_mode.select(CRITICAL_MODES.find(model.settings["critical_mode"]))
	# Mesmo quando o valor não mudou, descartar texto pendente anterior ao carregamento.
	for control in edit_controls:
		if control is SpinBox:
			control.get_line_edit().text = str(int(control.value)) if control.step == 1 else str(control.value)
	syncing = false
	_sync_equipment_enabled()
	_refresh_preset_controls()

func _rebuild_preset_lists() -> void:
	for side in ["ally", "enemy"]:
		var picker: OptionButton = preset_pickers[side]
		picker.clear()
		picker.add_item("Ficha atual / manual")
		picker.set_item_metadata(0, "")
		for preset in preset_library.entries(side):
			picker.add_item(preset["name"])
			picker.set_item_metadata(picker.item_count - 1, preset["id"])

func _refresh_preset_controls() -> void:
	for side in ["ally", "enemy"]:
		var selected: Dictionary = model.selected_presets.get(side, {})
		var picker: OptionButton = preset_pickers[side]
		picker.select(0)
		for index in range(1, picker.item_count):
			if picker.get_item_metadata(index) == selected.get("id", ""):
				picker.select(index)
		picker.tooltip_text = selected.get("name", "A ficha atual pode ser salva como preset.")
		var modified: bool = model.preset_modified(side)
		preset_status[side].text = "Salvo" + (" · alterado" if modified else "") if not selected.is_empty() else "Ficha atual / manual"
		preset_update_buttons[side].disabled = busy or not modified or not preset_library.is_custom(selected.get("id", "")) or not preset_library.load_error.is_empty()
		preset_load_buttons[side].disabled = busy or selected.is_empty() or not preset_library.load_error.is_empty()
		preset_delete_buttons[side].disabled = busy or not preset_library.is_custom(selected.get("id", "")) or not preset_library.load_error.is_empty()
		preset_save_buttons[side].disabled = busy or not preset_library.load_error.is_empty()
		preset_save_buttons[side].tooltip_text = preset_library.load_error

func _reload_preset(side: String) -> void:
	_choose_preset(preset_pickers[side].selected, side)

func _choose_preset(index: int, side: String) -> void:
	if syncing or busy:
		return
	_commit_edit()
	var id: String = preset_pickers[side].get_item_metadata(index)
	if id.is_empty():
		model.selected_presets.erase(side)
		model.preset_baselines.erase(side)
		_refresh_preset_controls()
		return
	var error: String = preset_library.load_custom()
	if not error.is_empty():
		notice.text = error
		_refresh_preset_controls()
		return
	var entry: Dictionary = preset_library.get_entry(id)
	if entry.is_empty():
		model.selected_presets.erase(side)
		model.preset_baselines.erase(side)
		_rebuild_preset_lists()
		_refresh_preset_controls()
		notice.text = "Este preset foi excluído. A ficha atual foi mantida."
		return
	error = model.apply_preset(entry)
	if not error.is_empty():
		notice.text = error
		return
	_sync_controls()
	_preview()
	notice.text = "Preset carregado: %s. Ação, parâmetros e sequência preservados." % entry["name"]

func _request_preset_save(side: String) -> void:
	if busy or export_dialog.visible or preset_dialog.visible:
		return
	_commit_edit()
	_reset_hold()
	pending_preset = model.preset_payload(side)
	preset_error.text = ""
	var selected: Dictionary = model.selected_presets.get(side, {})
	preset_name_edit.text = "Cópia de " + selected["name"] if not selected.is_empty() else ("Aliado personalizado" if side == "ally" else "Monstro personalizado")
	preset_dialog.title = "Salvar preset do aliado" if side == "ally" else "Salvar preset do monstro"
	preset_dialog.popup_centered(Vector2i(500, 190))
	preset_name_edit.grab_focus.call_deferred()

func _confirm_preset_save() -> void:
	if pending_preset.is_empty():
		return
	var result: Dictionary = preset_library.create(preset_name_edit.text, pending_preset)
	if not result["error"].is_empty():
		preset_error.text = result["error"]
		return
	var side: String = pending_preset["side"]
	model.apply_preset(result["preset"])
	pending_preset = {}
	preset_dialog.hide()
	_rebuild_preset_lists()
	_sync_controls()
	_preview()
	notice.text = "Preset salvo: %s. Disponível nas próximas sessões." % result["preset"]["name"]
	preset_save_buttons[side].grab_focus()

func _cancel_preset_save() -> void:
	var side: String = pending_preset.get("side", "ally")
	pending_preset = {}
	preset_dialog.hide()
	preset_save_buttons[side].grab_focus()

func _update_preset(side: String) -> void:
	if busy or export_dialog.visible or preset_dialog.visible:
		return
	_commit_edit()
	var selected: Dictionary = model.selected_presets.get(side, {})
	var result: Dictionary = preset_library.update(selected.get("id", ""), model.preset_payload(side))
	if not result["error"].is_empty():
		notice.text = result["error"]
		_refresh_preset_controls()
		return
	model.apply_preset(result["preset"])
	_rebuild_preset_lists()
	_sync_controls()
	_preview()
	notice.text = "Preset atualizado: %s · revisão %d." % [result["preset"]["name"], result["preset"]["revision"]]

func _delete_preset(side: String) -> void:
	if busy or export_dialog.visible or preset_dialog.visible:
		return
	_commit_edit()
	var selected: Dictionary = model.selected_presets.get(side, {})
	var error: String = preset_library.remove(selected.get("id", ""))
	if not error.is_empty():
		notice.text = error
		_refresh_preset_controls()
		return
	model.selected_presets.erase(side)
	model.preset_baselines.erase(side)
	_rebuild_preset_lists()
	_sync_controls()
	_preview()
	notice.text = "Preset excluído: %s. A ficha atual foi mantida para edição." % selected["name"]
	preset_save_buttons[side].grab_focus()

func _sync_equipment_enabled() -> void:
	physical_mode_picker.disabled = busy or model.action["damage_type"] == "magical"
	weapon_bonus.editable = not busy and model.weapon.get("equipped", true)
	weapon_chance.editable = not busy and model.weapon.get("equipped", true)
	armor_bonus.editable = not busy and model.armor.get("equipped", false)
	armor_ranged_bonus.editable = not busy and model.armor.get("equipped", false)
	armor_evasion_bonus.editable = not busy and model.armor.get("equipped", false)
	_sync_action_enabled()

func _sync_action_enabled() -> void:
	var affliction: bool = Calculator.is_affliction(model.configuration())
	var physical: bool = model.action["damage_type"] == "physical"
	power_edit.editable = not busy and not affliction
	critical_allowed.disabled = busy or not physical
	if not physical:
		critical_allowed.set_pressed_no_signal(false)
	critical_mode.disabled = busy or not physical
	for control in [item_edit, buff_edit, conversion_edit]:
		control.editable = not busy and physical
	variation_toggle.disabled = busy or affliction
	variation_edit.editable = not busy and not affliction

func _refresh_composition(config: Dictionary) -> void:
	for role in ["attacker", "target"]:
		var allied: bool = config[role]["side"] == "ally"
		for stat in ["physical_attack", "physical_defense", "ranged_attack", "ranged_defense"]:
			var caption: Label = profile_edits[role][stat].get_parent().get_child(0)
			caption.text = {"physical_attack": "ATQ F", "physical_defense": "DEF F", "ranged_attack": "ATQ D", "ranged_defense": "DEF D"}[stat]
		if not allied:
			composition_labels[role].text = "Atributos diretos · sem equipamentos"
			continue
		var composition: Dictionary = config["composition"][role]
		var lines: Array[String] = []
		for stat in ["physical_attack", "physical_defense", "ranged_attack", "ranged_defense"]:
			var line = "%s: %d + %d = %d" % [{"physical_attack": "ATQ F", "physical_defense": "DEF F", "ranged_attack": "ATQ D", "ranged_defense": "DEF D"}[stat], composition["base"][stat], composition["bonuses"][stat], composition["raw_total"][stat]]
			if composition["raw_total"][stat] != composition["effective"][stat]:
				line += " → %d (limite de teste)" % composition["effective"][stat]
			lines.append(line)
		var eva_line = "EVA: %d + %d = %d%%" % [composition["base"]["evasion_base"], composition["bonuses"]["evasion_base"], composition["raw_total"]["evasion_base"]]
		if composition["raw_total"]["evasion_base"] != composition["effective"]["evasion_base"]:
			eva_line += " → %d%% (limite de teste)" % composition["effective"]["evasion_base"]
		lines.append(eva_line)
		composition_labels[role].text = "\n".join(lines)

func _preview() -> void:
	if syncing:
		return
	var config: Dictionary = model.configuration()
	_sync_action_enabled()
	_refresh_composition(config)
	_refresh_preset_controls()
	field.preview(config)
	field_caption.text = "PRÉVIA DO PRÓXIMO TESTE"
	if not model.history.is_empty():
		notice.text = "Condições do próximo teste atualizadas. Resultados anteriores permanecem no histórico."
	if Calculator.is_affliction(config):
		var selected = Calculator.damage_stats(config)
		var chance = Calculator.application_chance(config)
		var resistance = Calculator.application_resistance(config)
		chance_label.text = "%s · MAG %d\nResistência: DEF M %d + %s %d = %d\nAplicar após EVA: %.2f%% · esquiva: %.2f%%\nAplicação por tentativa, incluindo EVA: %.2f%%\nSem dano direto ou crítico · custo %d MP" % [config["action"]["name"], config["attacker"]["magic_power"], resistance["magic_defense"], "VIG" if selected["defense_stat"] == "vigor" else "INT", resistance["specific"], resistance["total"], chance, Calculator.evasion_chance(config), (1.0 - Calculator.evasion_chance(config) / 100.0) * chance, config["action"]["mp_cost"]]
		return
	chance_label.text = "Crítico do atacante: %.2f%% · bônus da origem: %.2f p.p.\nEsquiva do alvo nesta ação: %.2f%% · EVA total %d\n1 CRI = 1%%; conversão ajustável só para testes." % [Calculator.critical_chance(config), config["critical_source"]["chance_bonus"], Calculator.evasion_chance(config), config["target"]["evasion_base"]]
	var selected = Calculator.damage_stats(config)
	chance_label.text += "\nFonte do dano: %s / %s" % [selected["attack_label"], selected["defense_label"]]

func _choose_weapon(index: int) -> void:
	if index < 0 or index >= weapon_picker.item_count:
		return
	if not syncing:
		var error: String = model.choose_equipment("weapon", weapon_picker.get_item_metadata(index))
		if not error.is_empty():
			notice.text = error
			return
		_sync_controls()
		_preview()

func _choose_armor(index: int) -> void:
	if index < 0 or index >= armor_picker.item_count:
		return
	if not syncing:
		var error: String = model.choose_equipment("armor", armor_picker.get_item_metadata(index))
		if not error.is_empty():
			notice.text = error
			return
		_sync_controls()
		_preview()

func _choose_action(index: int) -> void:
	if not syncing:
		model.action = model.data["actions"][index].duplicate(true)
		_sync_controls()
		_preview()

func _edit_stat(value: float, role: String, stat: String) -> void:
	if not syncing:
		var actor: Dictionary = model.attacker if role == "attacker" else model.target
		actor[stat] = int(value)
		_preview()

func _edit_setting(value: float, key: String) -> void:
	if not syncing:
		model.settings[key] = value
		_preview()

func _reset_case() -> void:
	if busy:
		return
	model.reset_case()
	_sync_controls()
	_preview()
	notice.text = "Caso e sequência restaurados; histórico preservado."

func _execute(count: int) -> void:
	if busy:
		return
	_commit_edit()
	var result: Dictionary = model.run(count)
	if not result.get("error", "").is_empty():
		notice.text = result["error"]
		return
	_rebuild_history()
	_show_result(result)
	field_caption.text = "EXECUÇÃO #%d · %d amostra(s) · %s" % [result["run_number"], count, result["snapshot"]["action"]["name"]]
	field.start(result["snapshot"], result["samples"].back(), count == 1)
	if count == 1:
		_set_busy(true)
	notice.text = "Execução #%d · semente %d · amostras da sequência %d–%d · HP/MP restaurados a cada amostra." % [result["run_number"], result["seed"], result["sequence_start"] + 1, result["sequence_start"] + count]

func _set_busy(value: bool) -> void:
	busy = value
	for control in edit_controls:
		if control is SpinBox:
			control.editable = not value
		elif control is BaseButton:
			control.disabled = value
	export_button.disabled = value or last_result.is_empty()
	_sync_equipment_enabled()
	_refresh_preset_controls()

func _request_export() -> void:
	if busy or last_result.is_empty() or export_dialog.visible or preset_dialog.visible:
		return
	_commit_edit()
	_reset_hold()
	pending_export = last_result.duplicate(true)
	var directory = ProjectSettings.globalize_path("res://exports/damage-lab")
	if not last_export_path.is_empty():
		directory = last_export_path.get_base_dir()
	var error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		pending_export = {}
		notice.text = "Não foi possível abrir a pasta de exportação: " + error_string(error)
		return
	export_dialog.current_dir = directory
	export_dialog.current_file = "danos-execucao-%03d-seed-%d-%dx.json" % [pending_export["run_number"], pending_export["seed"], pending_export["count"]]
	export_dialog.popup_centered(Vector2i(900, 600))

func _save_export(path: String) -> void:
	var result = Export.save(path, pending_export)
	export_dialog.hide()
	pending_export = {}
	if result["error"].is_empty():
		last_export_path = result["path"]
		notice.text = "%d amostra(s) exportadas: %s" % [result["count"], last_export_path]
	else:
		notice.text = result["error"]
	export_button.grab_focus()

func _cancel_export() -> void:
	pending_export = {}
	export_dialog.hide()
	export_button.grab_focus()

func _rebuild_history() -> void:
	history_picker.clear()
	for result in model.history:
		if result.get("result_type") == "affliction":
			history_picker.add_item("#%d · %d× · aplicou %d · %s" % [result["run_number"], result["count"], result["applied_count"], result["snapshot"]["action"]["name"]])
		else:
			history_picker.add_item("#%d · %d× · média %.2f · %s" % [result["run_number"], result["count"], result["mean"], result["snapshot"]["target"]["name"]])
	history_picker.select(model.history.size() - 1)

func _select_history(index: int) -> void:
	if not busy and index < model.history.size():
		_show_result(model.history[index])
		field.start(last_result["snapshot"], last_result["samples"].back(), false)
		field_caption.text = "HISTÓRICO · EXECUÇÃO #%d" % last_result["run_number"]

func _show_result(result: Dictionary) -> void:
	last_result = result
	export_button.disabled = busy
	if result.get("result_type") == "affliction":
		_show_affliction_result(result)
		return
	_sample_columns(false)
	var config: Dictionary = result["snapshot"]
	var mode = {"rolled": "sorteado", "off": "desligado", "forced": "forçado"}[config["settings"]["critical_mode"]]
	if not config["action"]["critical_allowed"]:
		mode = "ação impede crítico"
	summary.text = "%d ações · mínimo %d · máximo %d · média por ação %.2f\nEsquivas: %d / %d (%.2f%%) · chance %.2f%% · acertos %d\nCríticos: %d (%.2f%% dos acertos) · chance %.2f%% · %s\nMédia normal %.2f · crítica %.2f (somente acertos)\nΣ dano %d · Σ HP removido %d (alvo restaurado por amostra)" % [result["count"], result["minimum"], result["maximum"], result["mean"], result["evasion_count"], result["count"], result["evasion_frequency"], result["evasion_chance"], result["hit_count"], result["critical_count"], result["critical_hit_frequency"], result["chance"], mode, result["normal_mean"], result["critical_mean"], result["total"], result["hp_removed_total"]]
	histogram.result = result
	histogram.queue_redraw()
	samples_tree.clear()
	var tree_root = samples_tree.create_item()
	for sample in result["samples"]:
		var row = samples_tree.create_item(tree_root)
		row.set_metadata(0, sample["index"] - 1)
		var values = [str(sample["index"]), str(sample["damage"]), str(sample["hp_removed"]), "Esquiva" if sample["evaded"] else "Crítico" if sample["critical"] else "Normal", "%.3f" % sample["variation_factor"], "%.2f" % (sample["critical_roll"] * 100), "%.1f" % sample["critical_multiplier"]]
		for column in range(values.size()):
			row.set_text(column, values[column])
	var lines: Array[String] = []
	lines.append("EXECUÇÃO #%d · %d× · semente %d · início %d" % [result["run_number"], result["count"], result["seed"], result["sequence_start"] + 1])
	for role in ["attacker", "target"]:
		lines.append("\n%s: %s" % ["ATACANTE" if role == "attacker" else "ALVO", config[role]["name"]])
		if config.get("presets", {}).has(role):
			var preset: Dictionary = config["presets"][role]
			lines.append("Preset: %s · revisão %d%s" % [preset["name"], preset["revision"], " · alterado para este teste" if preset["modified"] else ""])
		var stats: Array[String] = []
		for attr in ATTRIBUTES:
			stats.append("%s %d" % [attr[0], config[role][attr[1]]])
		lines.append(" · ".join(stats))
		if config.get("equipment", {}).has(role):
			var composition: Dictionary = config["composition"][role]
			var equipment: Dictionary = config["equipment"][role]
			lines.append("Próprio + bônus → efetivo: ATQ F %d + %d → %d · DEF F %d + %d → %d" % [composition["base"]["physical_attack"], composition["bonuses"]["physical_attack"], composition["effective"]["physical_attack"], composition["base"]["physical_defense"], composition["bonuses"]["physical_defense"], composition["effective"]["physical_defense"]])
			lines.append("ATQ D %d + %d → %d · DEF D %d + %d → %d" % [composition["base"]["ranged_attack"], composition["bonuses"]["ranged_attack"], composition["effective"]["ranged_attack"], composition["base"]["ranged_defense"], composition["bonuses"]["ranged_defense"], composition["effective"]["ranged_defense"]])
			lines.append("EVA própria %d + armadura %d → efetiva %d%%" % [composition["base"]["evasion_base"], composition["bonuses"]["evasion_base"], composition["effective"]["evasion_base"]])
			if equipment["weapon"].get("equipped", true):
				lines.append("Arma: %s · chance %.2f%% · crítico %.2f× · armadura: %s" % [equipment["weapon"]["name"], equipment["weapon"]["critical_chance"], equipment["weapon"]["critical_multiplier"], equipment["armor"]["name"]])
			else:
				lines.append("Sem arma · crítico próprio de teste %.2f× · armadura: %s" % [config[role]["unarmed_critical_multiplier"], equipment["armor"]["name"]])
	var source = Calculator.critical_source(config)
	lines.append("\nCrítico do atacante: %s · bônus %.2f p.p. · multiplicador %.2f×" % [source["name"], source["chance_bonus"], source["multiplier"]])
	lines.append("Ação: %s · %s · potência %.2f× · %d MP · permite crítico: %s" % [config["action"]["name"], "física" if config["action"]["damage_type"] == "physical" else "mágica", config["action"]["power"], config["action"]["mp_cost"], "sim" if config["action"]["critical_allowed"] else "não"])
	var selected_stats = Calculator.damage_stats(config)
	lines.append("Fonte de dano: %s contra %s · modalidade %s" % [selected_stats["attack_label"], selected_stats["defense_label"], selected_stats["mode"]])
	lines.append("Esquiva: EVA total do alvo %d · chance nesta ação %.2f%% · permite esquiva: %s" % [config["target"]["evasion_base"], result["evasion_chance"], "sim" if config["action"]["evasion_allowed"] else "não"])
	lines.append("Variação: %s ±%.2f%% · CRI→%% %.2f · item %+.2f p.p. · buff %+.2f p.p. · crítico %s" % ["ligada" if config["settings"]["variation_enabled"] else "desligada", config["settings"]["variation_percent"], config["settings"]["crit_per_point"], config["settings"]["item_bonus"], config["settings"]["buff_bonus"], mode])
	conditions.text = "\n".join(lines)
	_show_sample(result["samples"].back())

func _show_sample(sample: Dictionary) -> void:
	if sample.has("affliction"):
		_show_affliction_sample(sample)
		return
	var base: Dictionary = sample["base"]
	var text = "Amostra #%d · %s\nOfensiva %.0f × potência %.2f × parcela %.4f = base %.4f\nDefesa %.0f · variação %.4f× → %.4f · crítico %.2f× → %.4f\nArredondar e mínimo 1 → %d de dano · HP removido %d · HP %d → %d · MP %d → %d" % [sample["index"], "CRÍTICO" if sample["critical"] else "NORMAL", base["attack"], base["power"], base["ratio"], base["base"], base["defense"], sample["variation_factor"], sample["varied"], sample["critical_multiplier"], sample["raw"], sample["damage"], sample["hp_removed"], sample["hp_before"], sample["hp_after"], sample["mp_before"], sample["mp_after"]]
	text += "\nAtributos: %s contra %s" % [base.get("attack_stat", "physical_attack"), base.get("defense_stat", "physical_defense")]
	if sample["evaded"]:
		text = "Amostra #%d · ESQUIVOU!\nChance de esquiva %.2f%% · sorteio %.2f%%\nDano 0 · sem crítico · mínimo 1 não se aplica\nHP %d → %d · MP %d → %d (ação consumida)" % [sample["index"], sample["evasion_chance"], sample["evasion_roll"] * 100, sample["hp_before"], sample["hp_after"], sample["mp_before"], sample["mp_after"]]
	else:
		text += "\nEsquiva: chance %.2f%% · sorteio %.2f%% · golpe acertou" % [sample["evasion_chance"], sample["evasion_roll"] * 100]
	calculation.text = text
	sample_detail.text = text

func _sample_columns(affliction: bool) -> void:
	var titles = ["#", "Resultado", "EVA %", "Sorteio EVA", "Aplicar %", "Sorteio apl.", "MP −"] if affliction else ["#", "Dano", "HP −", "Resultado", "Var. ×", "Crit. %", "Crit. ×"]
	for index in range(titles.size()):
		samples_tree.set_column_title(index, titles[index])
		samples_tree.set_column_custom_minimum_width(index, 42 if index == 0 else 78 if affliction else 65)

func _affliction_outcome(sample: Dictionary) -> String:
	return {"evaded": "Esquivou", "resisted": "Resistiu", "applied": "Aplicou"}[sample["outcome"]]

func _show_affliction_result(result: Dictionary) -> void:
	var config: Dictionary = result["snapshot"]
	var source = Calculator.damage_stats(config)
	_sample_columns(true)
	summary.text = "%s · %d tentativas · %d MP por amostra\nEsquivou: %d (%.2f%%) · Resistiu: %d (%.2f%%) · Aplicou: %d (%.2f%%)\nChance calculada após EVA: %.2f%% · total por tentativa: %.2f%%\nAplicações entre os %d testes de resistência: %.2f%%\nSem dano direto · HP preservado · sem crítico" % [config["action"]["name"], result["count"], config["action"]["mp_cost"], result["evasion_count"], result["evasion_frequency"], result["resisted_count"], result["resistance_frequency"], result["applied_count"], result["application_frequency"], result["application_chance"], result["total_application_chance"], result["hit_count"], result["application_hit_frequency"]]
	histogram.result = result
	histogram.queue_redraw()
	samples_tree.clear()
	var tree_root = samples_tree.create_item()
	for sample in result["samples"]:
		var row = samples_tree.create_item(tree_root)
		row.set_metadata(0, sample["index"] - 1)
		var values = [str(sample["index"]), _affliction_outcome(sample), "%.2f" % sample["evasion_chance"], "%.2f" % (sample["evasion_roll"] * 100.0), "%.2f" % sample["affliction"]["chance"], "%.2f" % (sample["affliction"]["roll"] * 100.0) if sample["affliction"]["tested"] else "—", str(sample["mp_before"] - sample["mp_after"])]
		for column in range(values.size()):
			row.set_text(column, values[column])
	var lines: Array[String] = ["EXECUÇÃO #%d · %d× · semente %d · início %d" % [result["run_number"], result["count"], result["seed"], result["sequence_start"] + 1]]
	for role in ["attacker", "target"]:
		lines.append("\n%s: %s" % ["ATACANTE" if role == "attacker" else "ALVO", config[role]["name"]])
		if config.get("presets", {}).has(role):
			var preset: Dictionary = config["presets"][role]
			lines.append("Preset: %s · revisão %d%s" % [preset["name"], preset["revision"], " · alterado para este teste" if preset["modified"] else ""])
		var stats: Array[String] = []
		for attr in ATTRIBUTES:
			stats.append("%s %d" % [attr[0], config[role][attr[1]]])
		lines.append(" · ".join(stats))
		if config[role]["side"] == "ally":
			var composition: Dictionary = config["composition"][role]
			lines.append("EVA própria %d + armadura %d → efetiva %d%%" % [composition["base"]["evasion_base"], composition["bonuses"]["evasion_base"], composition["effective"]["evasion_base"]])
	lines.append("\nAção: %s · %d MP · sem dano direto · sem crítico" % [config["action"]["name"], config["action"]["mp_cost"]])
	var resistance = Calculator.application_resistance(config)
	lines.append("Teste: MAG %d contra %s %d" % [config["attacker"]["magic_power"], source["defense_label"], resistance["total"]])
	lines.append("Resistência: DEF M %d + %s %d = %d" % [resistance["magic_defense"], "VIG" if source["defense_stat"] == "vigor" else "INT", resistance["specific"], resistance["total"]])
	lines.append("Chance = 100 × MAG / (MAG + %s) · sem limites adicionais" % source["defense_label"])
	lines.append("Esquiva: %.2f%% · permite EVA: %s · aplicação após EVA: %.2f%% · total por tentativa: %.2f%%" % [result["evasion_chance"], "sim" if config["action"]["evasion_allowed"] else "não", result["application_chance"], result["total_application_chance"]])
	lines.append("HP/MP restaurados por amostra. O teste registra aplicação; não simula duração ou efeito contínuo.")
	conditions.text = "\n".join(lines)
	_show_sample(result["samples"].back())

func _show_affliction_sample(sample: Dictionary) -> void:
	var effect: Dictionary = sample["affliction"]
	var label = "VIG" if effect["resistance_stat"] == "vigor" else "INT"
	var text = "Amostra #%d · %s\nEsquiva: %.2f%% · sorteio %.2f%%\nResistência: DEF M %.0f + %s %.0f = %.0f\nMAG %.0f / (MAG %.0f + DEF M %.0f + %s %.0f) × 100 = %.4f%%\nChance por tentativa incluindo EVA: %.4f%%" % [sample["index"], _affliction_outcome(sample), sample["evasion_chance"], sample["evasion_roll"] * 100.0, effect["magic_defense"], label, effect["specific_resistance"], effect["combined_resistance"], effect["magic_power"], effect["magic_power"], effect["magic_defense"], label, effect["specific_resistance"], effect["chance"], effect["total_chance"]]
	text += "\nSorteio de aplicação: %.4f%%" % (effect["roll"] * 100.0) if effect["tested"] else "\nTeste de resistência não realizado: alvo esquivou."
	text += "\nDano 0 · sem crítico · HP %d → %d · MP %d → %d" % [sample["hp_before"], sample["hp_after"], sample["mp_before"], sample["mp_after"]]
	calculation.text = text
	sample_detail.text = text

func _select_sample() -> void:
	var row = samples_tree.get_selected()
	if row != null and not last_result.is_empty():
		_show_sample(last_result["samples"][int(row.get_metadata(0))])

func _process(delta: float) -> void:
	field.advance(delta)
	if held_direction != Vector2.ZERO:
		repeat_timer -= delta
		if repeat_timer <= 0:
			repeat_timer = 0.12
			_navigate(held_direction)

func _focused() -> Control:
	var current = get_viewport().gui_get_focus_owner()
	for control in focus_controls:
		if control == current or (current != null and control.is_ancestor_of(current)):
			return control
	return null

func _apply_number_text(spin: SpinBox) -> void:
	var value = spin.get_line_edit().text.replace(",", ".")
	if value.is_valid_float():
		spin.value = float(value)

func _commit_edit() -> void:
	var current = get_viewport().gui_get_focus_owner()
	if current is LineEdit and current.get_parent() is SpinBox:
		var spin: SpinBox = current.get_parent()
		_apply_number_text(spin)
		current.focus_mode = Control.FOCUS_CLICK
		spin.grab_focus()

func _move_focus(step: int) -> void:
	_commit_edit()
	var index = focus_controls.find(_focused())
	for offset in range(1, focus_controls.size() + 1):
		var next = focus_controls[posmod(index + step * offset, focus_controls.size())]
		if next.is_visible_in_tree() and (not next is BaseButton or not next.disabled) and (not next is SpinBox or next.editable):
			next.grab_focus()
			return

func _navigate(direction: Vector2) -> void:
	if busy:
		return
	var focus = _focused()
	if focus == samples_tree and direction.y != 0:
		var row = samples_tree.get_selected()
		var next: TreeItem
		if row == null:
			next = samples_tree.get_root().get_first_child() if samples_tree.get_root() != null else null
		else:
			next = row.get_next() if direction.y > 0 else row.get_prev()
		if next != null:
			next.select(0)
			samples_tree.scroll_to_item(next)
	elif direction.y != 0:
		_move_focus(int(direction.y))
	elif focus is SpinBox and focus.editable:
		focus.value += direction.x * focus.step
	elif focus is OptionButton:
		var index = posmod(focus.selected + int(direction.x), focus.item_count)
		focus.select(index)
		focus.item_selected.emit(index)
	elif focus is CheckBox:
		focus.button_pressed = not focus.button_pressed
	elif focus == result_tabs.get_tab_bar():
		result_tabs.current_tab = posmod(result_tabs.current_tab + int(direction.x), result_tabs.get_tab_count())

func _activate_focus(keyboard: bool) -> void:
	if busy:
		return
	var focus = _focused()
	if focus is SpinBox:
		if keyboard and focus.editable:
			focus.get_line_edit().focus_mode = Control.FOCUS_ALL
			focus.get_line_edit().grab_focus()
			focus.get_line_edit().select_all()
	elif focus is OptionButton:
		_navigate(Vector2.RIGHT)
	elif focus is CheckBox:
		focus.button_pressed = not focus.button_pressed
	elif focus is Button:
		focus.pressed.emit()

func _reset_hold() -> void:
	joy_axis = Vector2.ZERO
	held_direction = Vector2.ZERO
	repeat_timer = 0.0

func _hold(direction: Vector2) -> void:
	if direction != held_direction:
		held_direction = direction
		repeat_timer = 0.35
		if direction != Vector2.ZERO:
			_navigate(direction)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_hold()

func _input(event: InputEvent) -> void:
	if (export_dialog != null and export_dialog.visible) or (preset_dialog != null and preset_dialog.visible):
		return # O diálogo recebe teclado/controle sem alterar o caso ao fundo.
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		joy_axis[0 if event.axis == JOY_AXIS_LEFT_X else 1] = event.axis_value
		var direction = Vector2.ZERO
		if joy_axis.length() >= (0.3 if held_direction != Vector2.ZERO else 0.55):
			direction = Vector2(signf(joy_axis.x), 0) if absf(joy_axis.x) >= absf(joy_axis.y) else Vector2(0, signf(joy_axis.y))
		_hold(direction)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		var directions = {JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT, JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN}
		if directions.has(event.button_index):
			if event.pressed: _hold(directions[event.button_index])
			elif held_direction == directions[event.button_index]: _hold(Vector2.ZERO)
		elif event.pressed:
			match event.button_index:
				JOY_BUTTON_A: _activate_focus(false)
				JOY_BUTTON_B: _commit_edit()
				JOY_BUTTON_START: _execute(1)
				JOY_BUTTON_LEFT_SHOULDER: _move_focus(-1)
				JOY_BUTTON_RIGHT_SHOULDER: _move_focus(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10] and not event.echo:
			if event.keycode == KEY_F5: _reset_case()
			elif event.keycode == KEY_F10: _request_export()
			else: _execute([1, 10, 100, 1000][event.keycode - KEY_F6])
		elif get_viewport().gui_get_focus_owner() is LineEdit:
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]: _commit_edit()
			elif event.keycode == KEY_TAB: _move_focus(-1 if event.shift_pressed else 1)
			else: return
		elif event.keycode == KEY_TAB:
			_move_focus(-1 if event.shift_pressed else 1)
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not event.echo:
			_activate_focus(true)
		elif _focused() is SpinBox and not busy and not event.ctrl_pressed and not event.meta_pressed and event.unicode > 0 and char(event.unicode) in "0123456789-.,":
			_activate_focus(true)
			return # A entrada nativa recebe o primeiro caractere no campo recém-focado.
		elif event.keycode == KEY_R and not event.echo:
			model.restart_sequence()
			notice.text = "Sequência reiniciada."
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			if _focused() == samples_tree: return
			_navigate({KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT, KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN}[event.keycode])
		else:
			return
		get_viewport().set_input_as_handled()
