extends RefCounted
## Faz a ponte de estado, sem duplicar regras de combate.
const Battle = preload("res://scripts/combat/battle_model.gd")
const World = preload("res://scripts/exploration/exploration_model.gd")
const Dialogue = preload("res://scripts/exploration/dialogue_model.gd")
const Catalog = preload("res://scripts/exploration/area_catalog.gd")
const Clock = preload("res://scripts/exploration/world_clock.gd")
const Rules = preload("res://scripts/exploration/area_rules.gd")
signal story_flag_changed(flag: String)

var battle
var world
var dialogue
var clock # Uma instância por partida/sessão, nunca uma por área ou batalha.
var story_flags: Dictionary = {} # Compartilhadas entre áreas até o reinício explícito da sessão.
var _conditions_dirty = true
var active_encounter_id = ""
var active_encounter_area_id = ""
var area_id = ""
var area_definitions: Dictionary = {}
var area_worlds: Dictionary = {}
var transition: Dictionary = {}
var transition_duration = 0.36 # Experimental: escurecer/revelar em duas metades.
var transition_alpha = 0.0
var interaction_error = ""
var state = "exploration"
var notice = "Vila de testes · NPCs nas ruas e na casa · portão a nordeste: mundo aberto · E: interagir."

func _init(battle_data: Dictionary, map_data: Dictionary, definitions: Dictionary = {}, clock_settings: Dictionary = {}) -> void:
	if clock_settings.is_empty():
		clock_settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_clock.json"))
	clock = Clock.new(clock_settings)
	battle = Battle.new(battle_data)
	battle.start(battle.default_preset_index(), false, int(battle_data["settings"]["seed"]))
	var ids: Array = []
	for member in battle.party:
		ids.append(member["id"])
	world = World.new(map_data, ids)
	area_id = str(map_data.get("id", "lab_exterior"))
	area_definitions = definitions.duplicate(true)
	area_definitions[area_id] = map_data
	area_worlds[area_id] = world
	dialogue = Dialogue.new(map_data.get("dialogues", {}))
	clock.period_changed.connect(_conditions_changed)
	_flush_conditions()

func _conditions_changed(_key: String) -> void:
	_conditions_dirty = true
	_flush_conditions()

func _flush_conditions() -> void:
	if not _conditions_dirty or state != "exploration" or dialogue.opened or world.dialogue_open or world.menu_open or world.transitioning:
		return
	_conditions_dirty = not world.apply_conditions(clock.period(), story_flags)

func set_story_flag_once(flag: String) -> bool:
	if flag.is_empty() or story_flags.get(flag, false):
		return false
	story_flags[flag] = true
	_conditions_changed(flag)
	story_flag_changed.emit(flag)
	return true

func tick(delta: float) -> void:
	if delta <= 0 or not is_finite(delta):
		return
	if state == "transition":
		transition["elapsed"] += delta
		var progress = minf(1, transition["elapsed"] / transition["duration"])
		transition_alpha = 1.0 - absf(progress * 2.0 - 1.0)
		if progress >= 0.5 and not transition["committed"]:
			if not _commit_transition():
				return
			transition_alpha = 1.0 # Quadro da troca totalmente coberto, mesmo cruzando a metade.
		if progress >= 1:
			world.transitioning = false
			transition.clear()
			transition_alpha = 0
			state = "exploration"
			_flush_conditions()
	elif state == "exploration":
		_flush_conditions()
		world.advance(delta)
		if can_advance_world_time():
			clock.advance_natural(delta)

static func area_allows_time(definition: Dictionary) -> bool:
	return definition.get("area_type", "") == "overworld" and definition.get("time_advances", false) == true

func can_advance_world_time() -> bool:
	return state == "exploration" and area_allows_time(world.data) \
		and not world.menu_open and not dialogue.opened and not world.dialogue_open and not world.transitioning

func rest_at_inn() -> bool:
	# API temporal para futura coordenação de pousadas; não recupera HP/MP nem cobra pagamento.
	return clock.rest_at_inn()

func begin_transition(id: String = "") -> bool:
	if state != "exploration" or dialogue.opened or world.menu_open:
		return false
	interaction_error = ""
	var portal = world.interaction_candidate() if id.is_empty() else world.entity_by_id(id)
	if portal.get("kind", "") != "transition" or not world.can_interact_with(portal):
		return false
	var target_id = str(portal.get("target_area_id", ""))
	var entry_id = str(portal.get("target_entry_id", ""))
	var definition = area_definitions.get(target_id)
	if not definition is Dictionary or definition.get("id", "") != target_id or not Catalog.valid_map(definition):
		interaction_error = "Transição recusada: área de destino inválida."
		return false
	var destination = area_worlds.get(target_id)
	if destination == null:
		destination = World.new(definition, world.party_order)
	var plan: Dictionary = destination.prepare_arrival(entry_id, world.party_order)
	if plan.is_empty():
		interaction_error = "Transição recusada: entrada de destino inválida ou bloqueada para a fila."
		return false
	if not is_finite(transition_duration) or transition_duration <= 0:
		interaction_error = "Transição recusada: duração inválida."
		return false
	transition = {"destination_id": target_id, "entry_id": entry_id, "destination": destination,
		"order": world.party_order.duplicate(), "elapsed": 0.0, "duration": transition_duration, "committed": false}
	world.moving = false
	world.transitioning = true
	state = "transition"
	return true

func _commit_transition() -> bool:
	# Revalida também o estado atual de sólidos de uma área já visitada.
	var destination = transition["destination"]
	var plan: Dictionary = destination.prepare_arrival(transition["entry_id"], transition["order"])
	if plan.is_empty():
		world.transitioning = false
		transition.clear()
		transition_alpha = 0
		state = "exploration"
		interaction_error = "Transição recusada: a entrada ficou bloqueada."
		return false
	world.transitioning = false
	destination.apply_arrival(plan)
	world = destination
	area_id = transition["destination_id"]
	area_worlds[area_id] = world
	world.transitioning = true
	dialogue = Dialogue.new(world.data.get("dialogues", {}))
	_conditions_dirty = not world.apply_conditions(clock.period(), story_flags)
	transition["committed"] = true
	notice = "%s · WASD / setas: andar · E: interagir" % world.data.get("label", area_id)
	return true

func interact() -> String:
	if state != "exploration":
		return ""
	interaction_error = ""
	_flush_conditions()
	var entity = world.interaction_candidate()
	if entity.is_empty():
		return ""
	if entity["kind"] == "encounter":
		return "battle" if begin_encounter(entity["id"]) else ""
	if entity["kind"] == "transition":
		return "transition" if begin_transition(entity["id"]) else ""
	var dialogue_id: String = entity.get("dialogue_id", "")
	dialogue_id = entity.get("dialogue_by_period", {}).get(clock.period(), dialogue_id)
	var rule = Rules.interaction(entity, clock.period(), story_flags)
	dialogue_id = rule.get("dialogue_id", dialogue_id)
	if entity["kind"] == "object":
		match entity["object_type"]:
			"chest":
				if entity["open"]:
					dialogue_id = entity["repeat_dialogue_id"]
				else:
					entity["open"] = true
			"door", "lever":
				var target: String = entity["id"] if entity["object_type"] == "door" else entity["target_id"]
				dialogue_id = world.toggle_door(target)
				# Indicador da alavanca sempre acompanha a porta, mesmo com acionamento direto.
				for other in world.entities:
					if other.get("object_type", "") == "lever" and other.get("target_id", "") == target:
						other["active"] = world.entity_by_id(target).get("open", false)
	if not dialogue.start(dialogue_id, entity["label"]):
		return ""
	world.dialogue_open = true
	world.moving = false
	# Somente depois de abrir uma fala válida; o diálogo em curso fica capturado.
	if rule.has("set_flag"):
		set_story_flag_once(rule["set_flag"])
	return "dialogue"

func advance_dialogue() -> bool:
	if state != "exploration" or not dialogue.advance():
		return false
	_sync_dialogue()
	return true

func choose_response(index: int) -> bool:
	if state != "exploration" or not dialogue.choose(index):
		return false
	_sync_dialogue()
	return true

func _sync_dialogue() -> void:
	world.dialogue_open = dialogue.opened
	if not dialogue.opened:
		_flush_conditions()
		notice = "Interação encerrada. O mapa retomou; E permite conversar ou interagir novamente."

func move(direction: Vector2, delta: float, preferred_axis: String = "x") -> Vector2:
	if state != "exploration":
		return Vector2.ZERO
	var movement: Vector2 = world.move(direction, delta, preferred_axis)
	_flush_conditions()
	if movement != Vector2.ZERO:
		interaction_error = ""
	return movement

func begin_encounter(id: String = "") -> bool:
	var encounter = world.interaction_candidate() if id.is_empty() else world.entity_by_id(id)
	if state != "exploration" or encounter.get("kind", "") != "encounter" or not world.can_interact_with(encounter):
		return false
	var preset_id: String = encounter["battle_preset_id"]
	var index = -1
	for candidate in range(battle.data["presets"].size()):
		if battle.data["presets"][candidate]["id"] == preset_id:
			index = candidate
			break
	if index < 0:
		notice = "Preset de encontro não encontrado: %s" % preset_id
		return false
	if not battle.start(index, true, int(battle.data["settings"]["seed"])):
		notice = "Grupo incapacitado. Reinicie o teste."
		return false
	world.moving = false
	active_encounter_id = encounter["id"]
	active_encounter_area_id = area_id
	state = "battle"
	return true

func finish_encounter() -> bool:
	if state != "battle" or area_id != active_encounter_area_id:
		return false
	match battle.outcome:
		"victory":
			world.entity_by_id(active_encounter_id)["present"] = false
			notice = "Vitória. Retorno ao mesmo lugar; HP e MP preservados."
		"escaped":
			notice = "Fuga concluída. HP/MP preservados; E permite desafiar o inimigo novamente."
		"defeat":
			state = "defeat"
			notice = "Game Over. Reinicie explicitamente o teste."
			return true
		_:
			return false
	state = "exploration"
	_flush_conditions()
	active_encounter_id = ""
	active_encounter_area_id = ""
	return true
