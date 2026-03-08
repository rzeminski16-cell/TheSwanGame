extends Node
## SaveManager — Serialization and persistence.
## Collects state from all managers, serializes to JSON, restores on load.
## Version 2: multiplayer support (player_count, multiplayer flag).

signal game_saved()
signal game_loaded()
signal save_failed(reason: String)

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 2


func save_game() -> bool:
	if GameState.is_in_dungeon:
		save_failed.emit("Cannot save during dungeon")
		print("SaveManager: Cannot save during dungeon")
		return false

	var save_data := {
		"version": SAVE_VERSION,
		"multiplayer": GameState.is_multiplayer,
		"player_count": GameState.player_count,
		"scene_path": GameState.current_scene_path,
		"players": {},
		"economy": {},
		"inventory": {},
		"dungeons": DungeonManager.get_save_data(),
		"missions": MissionManager.get_save_data(),
		"time": TimeManager.get_save_data(),
	}

	# Save per-player data
	for player_id in range(1, GameState.player_count + 1):
		var pid_str := str(player_id)
		save_data["players"][pid_str] = PlayerManager.get_save_data(player_id)
		save_data["economy"][pid_str] = EconomyManager.get_save_data(player_id)
		save_data["inventory"][pid_str] = InventoryManager.get_save_data(player_id)

	# Save player names if multiplayer
	if GameState.is_multiplayer:
		save_data["player_names"] = GameState.player_names.duplicate()

	var json_string := JSON.stringify(save_data, "  ")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		save_failed.emit("File open failed: %d" % err)
		push_error("SaveManager: Failed to open save file: %d" % err)
		return false

	file.store_string(json_string)
	file.close()

	game_saved.emit()
	print("SaveManager: Game saved to %s" % SAVE_PATH)
	return true


func load_game() -> bool:
	if not has_save():
		print("SaveManager: No save file found")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading")
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save JSON: %s" % json.get_error_message())
		return false

	var save_data: Dictionary = json.data
	if not save_data is Dictionary:
		push_error("SaveManager: Save data is not a dictionary")
		return false

	# Restore player count from save
	var saved_player_count: int = int(save_data.get("player_count", 1))
	GameState.player_count = saved_player_count

	# Restore per-player data
	var players: Dictionary = save_data.get("players", {})
	var economy: Dictionary = save_data.get("economy", {})
	var inventory: Dictionary = save_data.get("inventory", {})

	for player_id_str in players:
		var pid := int(player_id_str)
		PlayerManager.load_save_data(pid, players[player_id_str])

	for player_id_str in economy:
		var pid := int(player_id_str)
		EconomyManager.load_save_data(pid, int(economy[player_id_str]))

	for player_id_str in inventory:
		var pid := int(player_id_str)
		InventoryManager.load_save_data(pid, inventory[player_id_str])

	# Restore manager state
	DungeonManager.load_save_data(save_data.get("dungeons", {}))
	MissionManager.load_save_data(save_data.get("missions", {}))
	TimeManager.load_save_data(save_data.get("time", {}))

	# Restore player names if present
	if save_data.has("player_names"):
		GameState.player_names = save_data["player_names"]

	# Initialize single-player peer assignment if not in multiplayer
	if not GameState.is_multiplayer:
		GameState.peer_player_map[1] = 1
		GameState.player_peer_map[1] = 1
		GameState.active_peer_ids = [1]

	# Restore scene
	var scene_path: String = save_data.get("scene_path", "res://scenes/OverworldScene.tscn")
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(scene_path)

	game_loaded.emit()
	print("SaveManager: Game loaded from %s (player_count: %d)" % [SAVE_PATH, saved_player_count])
	return true


func new_game() -> void:
	delete_save()

	# Reset all players
	for player_id in range(1, GameState.player_count + 1):
		PlayerManager.reset_player(player_id)
		EconomyManager.load_save_data(player_id, 0)
		InventoryManager.load_save_data(player_id, [])

	DungeonManager.load_save_data({})
	MissionManager.load_save_data({})
	TimeManager.load_save_data({})

	# Initialize single-player peer assignment if not in multiplayer
	if not GameState.is_multiplayer:
		GameState.peer_player_map[1] = 1
		GameState.player_peer_map[1] = 1
		GameState.active_peer_ids = [1]

	# Start in overworld
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene("res://scenes/OverworldScene.tscn")

	# Start the tutorial mission
	MissionManager.start_mission("mission_tutorial")
	TimeManager.start_time()

	print("SaveManager: New game started (player_count: %d)" % GameState.player_count)


func apply_death_penalty(player_id: int = 1) -> void:
	## Apply death penalty to a specific player: lose money and items.
	var config: Dictionary = DataManager.get_config()
	var penalty: Dictionary = config.get("death_penalty", {})

	var money_loss_pct: float = float(penalty.get("money_loss_percent", 0.10))
	var item_loss_count: int = int(penalty.get("item_loss_count", 1))

	var current_money: int = EconomyManager.get_money(player_id)
	var money_lost: int = roundi(float(current_money) * money_loss_pct)
	if money_lost > 0:
		EconomyManager.deduct_money(player_id, money_lost)
		print("SaveManager: Death penalty (player %d) — lost %d money" % [player_id, money_lost])

	for i in range(item_loss_count):
		var lost_item := InventoryManager.remove_random_item(player_id)
		if lost_item != "":
			print("SaveManager: Death penalty (player %d) — lost item '%s'" % [player_id, lost_item])


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: Save file deleted")
