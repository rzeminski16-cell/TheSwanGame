extends Node
## GameState — Global runtime state container.
## NO gameplay logic allowed here. Only state storage.

# Current scene tracking
var current_scene_type: String = ""  # "overworld", "dungeon", "minigame", "cutscene"
var current_scene_path: String = ""

# Mission state
var current_mission_id: String = ""

# Multiplayer
var player_count: int = 1
var is_host: bool = true

# Dungeon
var is_in_dungeon: bool = false
var dungeon_scaling_data: Dictionary = {}

# Time
var current_day: int = 1
var current_time_of_day: float = 0.0  # 0.0 to 1.0

# Pause
var is_paused: bool = false


signal state_changed(key: String, value)


func set_state(key: String, value) -> void:
	set(key, value)
	state_changed.emit(key, value)
