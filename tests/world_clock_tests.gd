extends SceneTree
const Clock = preload("res://scripts/exploration/world_clock.gd")
var config: Dictionary
var checks = 0
var failures = 0

func _initialize() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_clock.json"))
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var tests = [_test_boundaries, _test_natural_rate, _test_manual_and_rest, _test_signals, _test_configuration]
	for test in tests:
		var before = failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("RELÓGIO: %d grupos, %d verificações, %d falhas" % [tests.size(), checks, failures])
	quit(0 if failures == 0 else 1)

func _test_boundaries() -> void:
	var clock = Clock.new(config)
	expect(clock.time_text() == "10:00" and clock.period() == "day", "Início provisório às 10:00")
	for minute in range(1440):
		clock.set_time(minute / 60, minute % 60)
		var expected = "night"
		if minute >= 300 and minute < 420:
			expected = "dawn"
		elif minute >= 420 and minute < 1020:
			expected = "day"
		elif minute >= 1020 and minute < 1140:
			expected = "dusk"
		expect(clock.period() == expected and clock.is_night() == (expected == "night"), "Período/minuto correto: %d" % minute)

func _test_natural_rate() -> void:
	var clock = Clock.new(config)
	clock.advance_natural(5)
	expect(clock.time_text() == "11:00", "Cinco segundos reais avançam uma hora do jogo")
	clock.advance_natural(120)
	expect(clock.time_text() == "11:00", "Ciclo completo dura dois minutos reais")
	clock.set_time(0, 0)
	clock.advance_natural(60)
	expect(clock.time_text() == "12:00", "Um minuto real corresponde à metade do ciclo")
	clock.set_time(23, 59)
	clock.advance_natural(0.125)
	expect(is_equal_approx(clock.minutes_of_day(), 0.5) and clock.time_text() == "00:00", "Passagem natural atravessa meia-noite com fração preservada")
	var split = Clock.new(config)
	var single = Clock.new(config)
	for index in range(1200):
		split.advance_natural(1.0 / 120.0)
	single.advance_natural(10)
	expect(is_equal_approx(single.minutes_of_day(), split.minutes_of_day()), "Subdivisão não perde tempo")
	var slower = config.duplicate(true)
	slower["day_duration_seconds"] = 240
	clock = Clock.new(slower)
	clock.advance_natural(5)
	expect(clock.time_text() == "10:30", "Duração configurável")

func _test_manual_and_rest() -> void:
	var clock = Clock.new(config)
	clock.set_time(22, 0)
	clock.advance_time(180)
	expect(clock.time_text() == "01:00", "Evento adianta minutos através de meia-noite")
	clock.set_time(8, 0)
	expect(clock.time_text() == "08:00", "Evento define horário arbitrário")
	clock.advance_time(1440 * 10 + 15)
	expect(clock.time_text() == "08:15", "Avanço de vários dias sem calendário")
	for hour in [10, 18, 23, 3, 7]:
		clock.set_time(hour, 0)
		clock.rest_at_inn()
		expect(clock.time_text() == "07:00", "Descanso sempre define 07:00")
	var value = clock.minutes_of_day()
	for invalid in [[-1, 0], [24, 0], [10, -1], [10, 60]]:
		expect(not clock.set_time(invalid[0], invalid[1]) and clock.minutes_of_day() == value, "Hora inválida não modifica estado")
	for invalid in [-1.0, INF, NAN]:
		expect(not clock.advance_time(invalid) and not clock.advance_natural(invalid) and clock.minutes_of_day() == value, "Delta inválido é recusado")

func _test_signals() -> void:
	var clock = Clock.new(config)
	var times = []
	var periods = []
	clock.time_changed.connect(func(value): times.append(value))
	clock.period_changed.connect(func(value): periods.append(value))
	clock.set_time(10, 0)
	clock.advance_natural(0)
	expect(times.is_empty() and periods.is_empty(), "Sem notificação redundante")
	clock.set_time(18, 59)
	clock.advance_time(1)
	clock.advance_time(1)
	expect(times.size() == 3 and periods == ["dusk", "night"], "Sinais de horário e mudança de período")
	clock.rest_at_inn()
	expect(times.back() == 420 and periods.back() == "day", "Descanso notifica os mesmos observadores")

func _test_configuration() -> void:
	expect(Clock.valid_settings(config), "Configuração real válida")
	for change in [{"day_duration_seconds": 0}, {"day_duration_seconds": INF}, {"day_duration_seconds": 1.0e-310}, {"initial_time": [24, 0]}, {"initial_time": [10.5, 0]}, {"periods": []}]:
		var bad = config.duplicate(true)
		bad.merge(change, true)
		expect(not Clock.valid_settings(bad), "Configuração malformada rejeitada")
	var changed = config.duplicate(true)
	for index in range(4):
		changed["periods"][index]["start_minute"] = [240, 480, 960, 1200][index]
	var clock = Clock.new(changed)
	for pair in [[239, "night"], [240, "dawn"], [479, "dawn"], [480, "day"], [960, "dusk"], [1200, "night"]]:
		clock.set_time(pair[0] / 60, pair[0] % 60)
		expect(clock.period() == pair[1], "Limites derivados da configuração")
