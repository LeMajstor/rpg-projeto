extends Window
## Seleções pendentes: somente Iniciar/Novo teste aplica equipamento à batalha.
signal start_requested
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
var model
var summaries: Array[Dictionary] = []
var first_picker: OptionButton

func _ready() -> void:
	title = "Preparar batalha V1 · equipamentos"
	size = Vector2i(1000, 680)
	transient = true
	exclusive = true
	close_requested.connect(hide)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var hint = Label.new()
	hint.text = "Escolha arma e vestimenta. Iniciar restaura HP/MP e aplica as escolhas.\nA batalha fica pausada durante a preparação. Tab percorre os controles."
	box.add_child(hint)
	for preset in model.data["presets"]:
		if preset.get("damage_ruleset", "") != "damage_lab_v1":
			continue
		for definition in preset["party"]:
			var title_label = Label.new()
			title_label.text = definition["name"]
			title_label.add_theme_font_size_override("font_size", 20)
			box.add_child(title_label)
			var row = HBoxContainer.new()
			box.add_child(row)
			for category in ["weapon", "armor"]:
				var picker = OptionButton.new()
				picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				picker.custom_minimum_size.x = 450
				if first_picker == null:
					first_picker = picker
				var current: Dictionary = model.pending_loadouts.get(definition["id"], definition["loadout"])
				for item in Bridge.damage_data()["weapons" if category == "weapon" else "armors"]:
					if not Bridge.Equipment.can_equip(definition["damage_base"], item, category):
						continue
					picker.add_item(item["name"])
					picker.set_item_metadata(picker.item_count - 1, item["id"])
					if item["id"] == current[category]["id"]:
						picker.select(picker.item_count - 1)
				picker.item_selected.connect(func(index):
					model.set_pending_equipment(definition["id"], category, picker.get_item_metadata(index))
					refresh_summaries())
				row.add_child(picker)
			var summary = Label.new()
			summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(summary)
			summaries.append({"definition": definition, "label": summary, "row": row})
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var buttons = HBoxContainer.new()
	box.add_child(buttons)
	var start_button = Button.new()
	start_button.text = "Iniciar V1 com estes equipamentos"
	start_button.pressed.connect(func(): hide(); start_requested.emit())
	buttons.add_child(start_button)
	var back = Button.new()
	back.text = "Voltar sem reiniciar"
	back.pressed.connect(hide)
	buttons.add_child(back)
	refresh_summaries()

func refresh_summaries() -> void:
	for entry in summaries:
		var definition: Dictionary = entry["definition"]
		var loadout: Dictionary = model.pending_loadouts.get(definition["id"], definition["loadout"])
		var base: Dictionary = definition["damage_base"]
		var effective: Dictionary = Bridge.equip_definition(definition, loadout)["damage_stats"]
		entry["label"].text = "HP %d · MP %d · INI %d   |   naturais → efetivos\nATQ F %d → %d · ATQ D %d → %d · DEF F %d → %d · DEF D %d → %d\nMAG %d → %d · DEF M %d → %d · EVA %d → %d%% · crítico %.0f%% / %.1f×" % [base["hp"], base["mp"], base["ini"], base["physical_attack"], effective["physical_attack"], base["ranged_attack"], effective["ranged_attack"], base["physical_defense"], effective["physical_defense"], base["ranged_defense"], effective["ranged_defense"], base["magic_power"], effective["magic_power"], base["magic_defense"], effective["magic_defense"], base["evasion_base"], effective["evasion_base"], base["critical_base"] + loadout["weapon"]["critical_chance"], loadout["weapon"]["critical_multiplier"]]

func open() -> void:
	refresh_summaries()
	popup_centered()
	first_picker.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
		set_input_as_handled()
