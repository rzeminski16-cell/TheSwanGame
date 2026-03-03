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
var is_multiplayer: bool = false
var active_peer_ids: Array = []      # List of connected peer IDs
var peer_player_map: Dictionary = {} # peer_id → player_id (1-4)
var player_peer_map: Dictionary = {} # player_id → peer_id (reverse lookup)
var player_names: Dictionary = {}    # player_id → display name
var host_peer_id: int = 1            # Which peer is the host

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


func get_player_id_for_peer(peer_id: int) -> int:
	return peer_player_map.get(peer_id, -1)


func get_peer_id_for_player(player_id: int) -> int:
	return player_peer_map.get(player_id, -1)


func reset_multiplayer() -> void:
	is_multiplayer = false
	active_peer_ids.clear()
	peer_player_map.clear()
	player_peer_map.clear()
	player_names.clear()
	host_peer_id = 1
	player_count = 1
	is_host = true
