extends RefCounted
## Único horário da sessão. Não conhece áreas, ATB, cenas, cores ou tempo de sistema.
signal time_changed(minutes_of_day: float)
signal period_changed(period_id: String)
const MINUTES_PER_DAY = 24 * 60
const INN_WAKE_HOUR = 7 # Regra confirmada, não o início configurável do período "dia".
var _minutes = 0.0
var _minutes_per_second = 1.0
var _periods: Array = []

func _init(settings: Dictionary) -> void:
	assert(valid_settings(settings), "Configuração inválida do relógio global")
	_periods = settings["periods"].duplicate(true)
	_minutes_per_second = MINUTES_PER_DAY / float(settings["day_duration_seconds"])
	_minutes = float(settings["initial_time"][0]) * 60 + float(settings["initial_time"][1])

static func valid_settings(settings: Dictionary) -> bool:
	var initial = settings.get("initial_time")
	if not initial is Array or initial.size() != 2:
		return false
	for value in initial:
		if not _number(value) or float(value) != floorf(float(value)):
			return false
	if initial[0] < 0 or initial[0] > 23 or initial[1] < 0 or initial[1] > 59:
		return false
	var duration = settings.get("day_duration_seconds")
	if not _number(duration) or duration <= 0:
		return false
	if not is_finite(MINUTES_PER_DAY / float(duration)):
		return false
	var periods = settings.get("periods")
	if not periods is Array or periods.size() < 4:
		return false
	var ids = {}
	var previous = -1.0
	for definition in periods:
		if not definition is Dictionary or not definition.get("id") is String or not definition.get("label") is String:
			return false
		var start = definition.get("start_minute")
		if not _number(start) or float(start) != floorf(float(start)) or start < 0 or start >= MINUTES_PER_DAY or start <= previous:
			return false
		if definition["id"].is_empty() or ids.has(definition["id"]):
			return false
		ids[definition["id"]] = true
		previous = float(start)
	return ["dawn", "day", "dusk", "night"].all(func(id): return ids.has(id))

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func minutes_of_day() -> float:
	return _minutes

func hour() -> int:
	return int(_minutes / 60)

func minute() -> int:
	return int(_minutes) % 60

func time_text() -> String:
	return "%02d:%02d" % [hour(), minute()]

func period() -> String:
	return str(_period_definition()["id"])

func period_label() -> String:
	return str(_period_definition()["label"])

func _period_definition() -> Dictionary:
	var selected: Dictionary = _periods.back() # Último período atravessa a meia-noite.
	for definition in _periods:
		if _minutes < float(definition["start_minute"]):
			break
		selected = definition
	return selected

func is_night() -> bool:
	return period() == "night"

func set_time(hours: int, minutes: int) -> bool:
	if hours < 0 or hours > 23 or minutes < 0 or minutes > 59:
		return false
	_apply(float(hours * 60 + minutes))
	return true

func advance_time(minutes: float) -> bool:
	if not is_finite(minutes) or minutes < 0:
		return false
	# Reduz antes de somar para evitar overflow mesmo com avanços muito grandes.
	_apply(fposmod(_minutes + fposmod(minutes, MINUTES_PER_DAY), MINUTES_PER_DAY))
	return true

func advance_natural(seconds: float) -> bool:
	if not is_finite(seconds) or seconds < 0:
		return false
	return advance_time(seconds * _minutes_per_second)

func rest_at_inn() -> bool:
	# Não avança até a próxima manhã: define 07:00 mesmo se já passou desse horário.
	return set_time(INN_WAKE_HOUR, 0)

func _apply(value: float) -> void:
	if value == _minutes:
		return
	var previous = period()
	_minutes = value
	time_changed.emit(_minutes)
	if period() != previous:
		period_changed.emit(period())
