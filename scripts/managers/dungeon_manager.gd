extends Node
## DungeonManager — Dungeon lifecycle, room progression, scaling, completion tracking.
## Orchestrates dungeon flow: start → room waves → boss → complete → exit.
## Reads dungeon definitions from DataManager (dungeons.json).
## Scaling applied from global_config.json formulas.

signal dungeon_started(dungeon_id: String)
signal dungeon_completed(dungeon_id: String)
signal dungeon_failed(dungeon_id: String)
signal room_started(room_index: int, total_rooms: int)
signal room_cleared(room_index: int)

var _completion_counts: Dictionary = {}  # dungeon_id → int

# Active dungeon state
var _active_dungeon_id: String = ""
var _active_dungeon_data: Dictionary = {}
var _active_rooms: Array = []
var _active_scaling: Dictionary = {}
var _current_room_index: int = -1
var _waiting_for_clear: bool = false
var _dungeon_active: bool = false
var _room_clear_delay: float = 0.0
var _return_scene: String = ""

const ROOM_CLEAR_DELAY := 1.5  # seconds between rooms
const DUNGEON_SCENE_PATH := "res://scenes/DungeonScene.tscn"


# --- Start / Complete ---

func start_dungeon(dungeon_id: String) -> bool:
	var dungeon_data: Dictionary = DataManager.get_dungeon(dungeon_id)
	if dungeon_data.is_empty():
		push_error("DungeonManager: Unknown dungeon_id '%s'" % dungeon_id)
		return false

	# Story dungeon already completed check
	if dungeon_data.get("type") == "story" and get_completion_count(dungeon_id) >= 1:
		print("DungeonManager: Story dungeon '%s' already completed" % dungeon_id)
		return false

	# Remember where to return
	_return_scene = GameState.current_scene_path

	# Store active state
	_active_dungeon_id = dungeon_id
	_active_dungeon_data = dungeon_data
	_active_rooms = dungeon_data.get("rooms", [])
	_current_room_index = -1
	_waiting_for_clear = false
	_dungeon_active = true
	_room_clear_delay = 0.0

	# Calculate scaling (only for replayable dungeons)
	if dungeon_data.get("replayable", false):
		_active_scaling = get_scaling(dungeon_id)
	else:
		_active_scaling = {}

	# Update GameState
	GameState.is_in_dungeon = true
	GameState.dungeon_scaling_data = _active_scaling

	# Pause time (Phase 5)
	TimeManager.pause_time()

	# Load dungeon scene
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(DUNGEON_SCENE_PATH)

	dungeon_started.emit(dungeon_id)
	print("DungeonManager: Started dungeon '%s' (rooms: %d, scaling: %s)" % [
		dungeon_data.get("display_name", dungeon_id),
		_active_rooms.size(),
		_active_scaling
	])
	return true


func complete_dungeon() -> void:
	if not _dungeon_active:
		return

	var dungeon_id := _active_dungeon_id

	# Increment completion count
	if _active_dungeon_data.get("replayable", false):
		_completion_counts[dungeon_id] = get_completion_count(dungeon_id) + 1
		print("DungeonManager: Replayable dungeon '%s' completion count: %d" % [
			dungeon_id, _completion_counts[dungeon_id]])
	else:
		# Story dungeon: mark as completed (count = 1)
		_completion_counts[dungeon_id] = 1

	_dungeon_active = false
	_waiting_for_clear = false
	GameState.is_in_dungeon = false
	GameState.dungeon_scaling_data = {}
	TimeManager.resume_time()

	dungeon_completed.emit(dungeon_id)
	print("DungeonManager: Dungeon '%s' completed!" % _active_dungeon_data.get("display_name", dungeon_id))

	# Return to previous scene
	_exit_to_previous_scene()


func fail_dungeon() -> void:
	## Clean up dungeon state. Does NOT apply death penalty or change scene —
	## that is handled by the GameOverScreen via UIManager.
	if not _dungeon_active:
		return

	var dungeon_id := _active_dungeon_id

	_dungeon_active = false
	_waiting_for_clear = false
	GameState.is_in_dungeon = false
	GameState.dungeon_scaling_data = {}
	TimeManager.resume_time()

	# Clear remaining enemies
	CombatManager.clear_all_enemies()

	dungeon_failed.emit(dungeon_id)
	print("DungeonManager: Dungeon '%s' failed" % _active_dungeon_data.get("display_name", dungeon_id))


func _exit_to_previous_scene() -> void:
	var target := _return_scene if _return_scene != "" else "res://scenes/OverworldScene.tscn"
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(target)


# --- Room Progression ---

func start_next_room() -> void:
	if not _dungeon_active:
		return

	_current_room_index += 1

	if _current_room_index >= _active_rooms.size():
		# All rooms cleared
		complete_dungeon()
		return

	var room: Dictionary = _active_rooms[_current_room_index]
	var room_type: String = room.get("room_type", "combat")

	room_started.emit(_current_room_index, _active_rooms.size())
	print("DungeonManager: Room %d/%d (%s)" % [
		_current_room_index + 1, _active_rooms.size(), room_type])

	# Spawn enemies for this room
	var scene_parent := _get_dungeon_scene()
	if room_type == "boss":
		_spawn_boss_room(room, scene_parent)
	else:
		_spawn_combat_room(room, scene_parent)

	_waiting_for_clear = true


func _spawn_combat_room(room: Dictionary, parent: Node) -> void:
	var enemy_groups: Array = room.get("enemy_groups", [])
	var spawn_center := Vector2(640, 360)  # Center of arena
	CombatManager.spawn_wave(enemy_groups, spawn_center, _active_scaling, parent)


func _spawn_boss_room(room: Dictionary, parent: Node) -> void:
	var boss_id: String = room.get("enemy_id", "")
	if boss_id == "":
		push_error("DungeonManager: Boss room has no enemy_id")
		return

	# Also spawn any adds defined in the room
	var adds: Array = room.get("enemy_groups", [])
	if adds.size() > 0:
		CombatManager.spawn_wave(adds, Vector2(640, 360), _active_scaling, parent)

	var spawn_pos := Vector2(640, 250)  # Top center of arena
	CombatManager.spawn_enemy(boss_id, spawn_pos, _active_scaling, parent)


func _get_dungeon_scene() -> Node:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm and sm.has_method("get_current_scene") and sm.get_current_scene():
		return sm.get_current_scene()
	return get_tree().current_scene


# --- Process: Monitor Room Clear ---

func _process(delta: float) -> void:
	if not _dungeon_active:
		return

	# Handle room clear delay timer
	if _room_clear_delay > 0.0:
		_room_clear_delay -= delta
		if _room_clear_delay <= 0.0:
			_room_clear_delay = 0.0
			start_next_room()
		return

	if not _waiting_for_clear:
		return

	if CombatManager.get_active_enemy_count() == 0:
		_waiting_for_clear = false
		room_cleared.emit(_current_room_index)
		print("DungeonManager: Room %d cleared!" % (_current_room_index + 1))

		# Check if this was the last room
		if _current_room_index + 1 >= _active_rooms.size():
			# Brief delay then complete
			_room_clear_delay = ROOM_CLEAR_DELAY
		else:
			# Delay before next room
			_room_clear_delay = ROOM_CLEAR_DELAY


# --- Scaling ---

func get_completion_count(dungeon_id: String) -> int:
	return _completion_counts.get(dungeon_id, 0)


func get_scaling(dungeon_id: String) -> Dictionary:
	var count := get_completion_count(dungeon_id)
	var config: Dictionary = DataManager.get_config()

	var diff_mult: float = 1.0 + (count * config.get("dungeon_scaling_per_completion", 0.15))
	var cap: float = config.get("difficulty_multiplier_cap", 3.0)
	diff_mult = minf(diff_mult, cap)

	return {
		"difficulty_multiplier": diff_mult,
		"enemy_health_multiplier": 1.0 + (count * config.get("enemy_health_scaling", 0.12)),
		"enemy_damage_multiplier": 1.0 + (count * config.get("enemy_damage_scaling", 0.08)),
		"enemy_count_multiplier": 1.0 + (count * config.get("enemy_spawn_scaling", 0.10)),
		"loot_quality_multiplier": 1.0 + (count * config.get("loot_quality_scaling", 0.10)),
	}


# --- Queries ---

func is_dungeon_active() -> bool:
	return _dungeon_active


func get_active_dungeon_id() -> String:
	return _active_dungeon_id


func get_active_dungeon_data() -> Dictionary:
	return _active_dungeon_data


func get_current_room_index() -> int:
	return _current_room_index


func get_total_rooms() -> int:
	return _active_rooms.size()


func is_dungeon_completed(dungeon_id: String) -> bool:
	return get_completion_count(dungeon_id) > 0


# --- Save/Load helpers (Phase 6) ---

func get_save_data() -> Dictionary:
	return _completion_counts.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_completion_counts = data.duplicate(true)
