extends Node
## TimeManager — Day/night cycle (overworld only).
## Day/night durations from global_config.json.
## Pauses during dungeons and cutscenes.

signal day_started(day_number: int)
signal night_started(day_number: int)
signal time_updated(normalized_time: float)
signal week_ended(week_number: int)

var is_active: bool = false
var is_daytime: bool = true

var _elapsed: float = 0.0  # seconds elapsed in current phase (day or night)
var _day_length: float = 0.0  # seconds
var _night_length: float = 0.0  # seconds


func _ready() -> void:
	var day_min: float = DataManager.get_config_value("day_length_minutes", 15)
	var night_min: float = DataManager.get_config_value("night_length_minutes", 7)
	_day_length = day_min * 60.0
	_night_length = night_min * 60.0
	print("TimeManager: Ready (day=%.0fs, night=%.0fs)" % [_day_length, _night_length])


func _process(delta: float) -> void:
	if not is_active:
		return

	_elapsed += delta
	var phase_length: float = _day_length if is_daytime else _night_length

	if _elapsed >= phase_length:
		_elapsed -= phase_length
		if is_daytime:
			is_daytime = false
			night_started.emit(GameState.current_day)
			print("TimeManager: Night %d started" % GameState.current_day)
		else:
			is_daytime = true
			GameState.current_day += 1
			day_started.emit(GameState.current_day)
			print("TimeManager: Day %d started" % GameState.current_day)

			# Check for weekly rent (every 7 days)
			if GameState.current_day > 1 and (GameState.current_day - 1) % 7 == 0:
				var week_num := (GameState.current_day - 1) / 7
				week_ended.emit(week_num)
				print("TimeManager: Week %d ended — rent is due!" % week_num)

	# Update normalized time: day = 0.0–0.5, night = 0.5–1.0
	if phase_length > 0.0:
		var phase_progress: float = _elapsed / phase_length
		if is_daytime:
			GameState.current_time_of_day = phase_progress * 0.5
		else:
			GameState.current_time_of_day = 0.5 + phase_progress * 0.5
		time_updated.emit(GameState.current_time_of_day)


func start_time() -> void:
	is_active = true
	is_daytime = true
	_elapsed = 0.0
	GameState.current_time_of_day = 0.0
	day_started.emit(GameState.current_day)
	print("TimeManager: Time started (Day %d)" % GameState.current_day)


func pause_time() -> void:
	is_active = false


func resume_time() -> void:
	is_active = true


func get_current_day() -> int:
	return GameState.current_day


func get_time_of_day() -> float:
	return GameState.current_time_of_day


func get_time_string() -> String:
	## Returns human-readable time: "Day X — Morning/Afternoon/Evening/Night"
	var phase: String
	var t := GameState.current_time_of_day
	if t < 0.25:
		phase = "Morning"
	elif t < 0.5:
		phase = "Afternoon"
	elif t < 0.75:
		phase = "Evening"
	else:
		phase = "Night"
	return "Day %d — %s" % [GameState.current_day, phase]


func is_night() -> bool:
	return not is_daytime


func advance_to_next_day() -> void:
	## Debug helper: skip to next day start.
	_elapsed = 0.0
	if not is_daytime:
		is_daytime = true
		GameState.current_day += 1
	day_started.emit(GameState.current_day)
	print("TimeManager: Advanced to Day %d" % GameState.current_day)


func advance_to_night() -> void:
	## Debug helper: skip to night.
	_elapsed = 0.0
	is_daytime = false
	night_started.emit(GameState.current_day)
	print("TimeManager: Advanced to Night %d" % GameState.current_day)


# --- Save/Load helpers (Phase 6) ---

func get_save_data() -> Dictionary:
	return {
		"current_day": GameState.current_day,
		"is_daytime": is_daytime,
		"elapsed": _elapsed,
	}


func load_save_data(data: Dictionary) -> void:
	GameState.current_day = int(data.get("current_day", 1))
	is_daytime = bool(data.get("is_daytime", true))
	_elapsed = float(data.get("elapsed", 0.0))
