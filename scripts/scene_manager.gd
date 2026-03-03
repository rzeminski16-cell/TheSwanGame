extends Node
## SceneManager — Dynamic scene loading.
## Child of Main.tscn (not an autoload).
## Only one gameplay scene is active at a time.
## In multiplayer, host triggers scene changes for all clients via MultiplayerManager.

signal scene_changed(new_scene_path: String)
signal scene_loading_started(scene_path: String)

var _current_scene: Node = null


func _ready() -> void:
	print("SceneManager: Ready.")


func change_scene(scene_path: String) -> void:
	scene_loading_started.emit(scene_path)

	# Remove current scene if any
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null

	# Load and instantiate new scene
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("SceneManager: Failed to load scene: " + scene_path)
		return

	_current_scene = packed_scene.instantiate()
	add_child(_current_scene)

	# Update GameState
	_update_scene_type(scene_path)
	GameState.current_scene_path = scene_path

	scene_changed.emit(scene_path)
	print("SceneManager: Changed to " + scene_path)


func change_scene_synced(scene_path: String) -> void:
	## Host-only: change scene on all peers simultaneously.
	if GameState.is_multiplayer and MultiplayerManager.is_host():
		MultiplayerManager.request_change_scene(scene_path)
	else:
		change_scene(scene_path)


func get_current_scene() -> Node:
	return _current_scene


func _update_scene_type(scene_path: String) -> void:
	if "Overworld" in scene_path:
		GameState.current_scene_type = "overworld"
		GameState.is_in_dungeon = false
	elif "Dungeon" in scene_path:
		GameState.current_scene_type = "dungeon"
		GameState.is_in_dungeon = true
	elif "Delivery" in scene_path:
		GameState.current_scene_type = "minigame"
		GameState.is_in_dungeon = false
	elif "Cutscene" in scene_path:
		GameState.current_scene_type = "cutscene"
		GameState.is_in_dungeon = false
	else:
		GameState.current_scene_type = "unknown"
		GameState.is_in_dungeon = false
