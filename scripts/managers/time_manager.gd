extends Node
## TimeManager — Day/night cycle (overworld only).
## Full implementation in Phase 5.

signal day_started(day_number: int)
signal night_started(day_number: int)
signal time_updated(normalized_time: float)

var is_active: bool = false
var is_daytime: bool = true


func start_time() -> void:
	# Phase 5: Begin day/night cycle
	push_warning("TimeManager.start_time() not yet implemented")


func pause_time() -> void:
	is_active = false


func resume_time() -> void:
	is_active = true


func get_current_day() -> int:
	return GameState.current_day


func get_time_of_day() -> float:
	return GameState.current_time_of_day
