extends Node
## SaveManager — Serialization and persistence.
## Collects state from all managers, serializes to JSON, restores on load.

signal game_saved()
signal game_loaded()
signal save_failed(reason: String)

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1


func save_game() -> bool:
	if GameState.is_in_dungeon:
		save_failed.emit("Cannot save during dungeon")
		print("SaveManager: Cannot save during dungeon")
		return false

	var save_data := {
		"version": SAVE_VERSION,
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
		save_data["players"][str(player_id)] = PlayerManager.get_save_data(player_id)
		save_data["economy"][str(player_id)] = EconomyManager.get_save_data(player_id)
		save_data["inventory"][str(player_id)] = InventoryManager.get_save_data(player_id)

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

	# Restore scene
	var scene_path: String = save_data.get("scene_path", "res://scenes/OverworldScene.tscn")
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(scene_path)

	game_loaded.emit()
	print("SaveManager: Game loaded from %s" % SAVE_PATH)
	return true


func new_game() -> void:
	delete_save()

	# Reset all managers to fresh state
	PlayerManager.reset_player(1)
	EconomyManager.load_save_data(1, 0)
	InventoryManager.load_save_data(1, [])
	DungeonManager.load_save_data({})
	MissionManager.load_save_data({})
	TimeManager.load_save_data({})

	# Start in overworld
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene("res://scenes/OverworldScene.tscn")

	# Start the tutorial mission
	MissionManager.start_mission("mission_tutorial")
	TimeManager.start_time()

	print("SaveManager: New game started")


func apply_death_penalty() -> void:
	## Apply death penalty: lose money and items per global_config settings.
	var config: Dictionary = DataManager.get_config()
	var penalty: Dictionary = config.get("death_penalty", {})

	var money_loss_pct: float = float(penalty.get("money_loss_percent", 0.10))
	var item_loss_count: int = int(penalty.get("item_loss_count", 1))

	var current_money: int = EconomyManager.get_money(1)
	var money_lost: int = roundi(float(current_money) * money_loss_pct)
	if money_lost > 0:
		EconomyManager.deduct_money(1, money_lost)
		print("SaveManager: Death penalty — lost %d money" % money_lost)

	for i in range(item_loss_count):
		var lost_item := InventoryManager.remove_random_item(1)
		if lost_item != "":
			print("SaveManager: Death penalty — lost item '%s'" % lost_item)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: Save file deleted")
