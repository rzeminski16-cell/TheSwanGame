extends Node
## SaveManager — Multi-slot save system with per-character data.
## 5 save slots, each a separate "world" with 4 characters.
## Auto-saves every 15 minutes. Overwrite-on-save per slot.

signal game_saved()
signal game_loaded()
signal save_failed(reason: String)
signal slot_deleted(slot_index: int)

const SAVE_SLOT_COUNT := 5
const SAVE_SLOT_PATH_TEMPLATE := "user://save_slot_%d.json"
const SAVE_VERSION := 3
const AUTOSAVE_INTERVAL := 900.0  # 15 minutes

var _autosave_timer: float = 0.0


func _process(delta: float) -> void:
	# Auto-save only when actively playing (not in menu, dungeon, or paused)
	if GameState.current_save_slot < 1:
		return
	if GameState.is_in_dungeon or GameState.is_paused:
		return

	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		var success := save_game()
		if success:
			print("SaveManager: Auto-saved to slot %d" % GameState.current_save_slot)


func _get_slot_path(slot_index: int) -> String:
	return SAVE_SLOT_PATH_TEMPLATE % slot_index


func save_game(slot_index: int = -1) -> bool:
	if slot_index < 1:
		slot_index = GameState.current_save_slot
	if slot_index < 1 or slot_index > SAVE_SLOT_COUNT:
		save_failed.emit("Invalid save slot")
		return false

	if GameState.is_in_dungeon:
		save_failed.emit("Cannot save during dungeon")
		print("SaveManager: Cannot save during dungeon")
		return false

	# Build per-character data
	var characters_data := {}
	var all_char_ids := DataManager.get_character_ids()
	for char_id in all_char_ids:
		characters_data[char_id] = _get_character_save_data(char_id)

	var save_data := {
		"version": SAVE_VERSION,
		"world_name": GameState.current_world_name,
		"active_character_id": GameState.active_character_id,
		"scene_path": GameState.current_scene_path,
		"characters": characters_data,
		"dungeons": DungeonManager.get_save_data(),
		"missions": MissionManager.get_save_data(),
		"time": TimeManager.get_save_data(),
	}

	var json_string := JSON.stringify(save_data, "  ")
	var file := FileAccess.open(_get_slot_path(slot_index), FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		save_failed.emit("File open failed: %d" % err)
		push_error("SaveManager: Failed to open save file: %d" % err)
		return false

	file.store_string(json_string)
	file.close()

	game_saved.emit()
	print("SaveManager: Game saved to slot %d" % slot_index)
	return true


func load_game(slot_index: int, character_id: String = "") -> bool:
	if not has_save(slot_index):
		print("SaveManager: No save in slot %d" % slot_index)
		return false

	var file := FileAccess.open(_get_slot_path(slot_index), FileAccess.READ)
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

	# Set slot and world info
	GameState.current_save_slot = slot_index
	GameState.current_world_name = save_data.get("world_name", "World")

	# Determine active character
	if character_id == "":
		character_id = save_data.get("active_character_id", "")
	GameState.active_character_id = character_id

	# Single player setup
	GameState.player_count = 1
	GameState.is_multiplayer = false
	GameState.peer_player_map[1] = 1
	GameState.player_peer_map[1] = 1
	GameState.active_peer_ids = [1]

	# Load the active character's data into player_id 1
	var characters: Dictionary = save_data.get("characters", {})
	if characters.has(character_id):
		var char_data: Dictionary = characters[character_id]
		PlayerManager.load_save_data(1, char_data.get("player_data", {}))
		EconomyManager.load_save_data(1, int(char_data.get("economy", 0)))
		InventoryManager.load_save_data(1, char_data.get("inventory", []))
	else:
		PlayerManager.reset_player(1)
		EconomyManager.load_save_data(1, 0)
		InventoryManager.load_save_data(1, [])

	# Restore shared world state
	DungeonManager.load_save_data(save_data.get("dungeons", {}))
	MissionManager.load_save_data(save_data.get("missions", {}))
	TimeManager.load_save_data(save_data.get("time", {}))

	# Change to saved scene
	var scene_path: String = save_data.get("scene_path", "res://scenes/OverworldScene.tscn")
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(scene_path)

	_autosave_timer = 0.0
	game_loaded.emit()
	print("SaveManager: Game loaded from slot %d (character: %s)" % [slot_index, character_id])
	return true


func new_game(slot_index: int, world_name: String, character_id: String) -> void:
	# Delete any existing save in that slot
	delete_save(slot_index)

	# Set state
	GameState.current_save_slot = slot_index
	GameState.current_world_name = world_name
	GameState.active_character_id = character_id
	GameState.player_count = 1
	GameState.is_multiplayer = false
	GameState.peer_player_map[1] = 1
	GameState.player_peer_map[1] = 1
	GameState.active_peer_ids = [1]

	# Reset all managers for a fresh start
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

	# Start tutorial mission and time
	MissionManager.start_mission("mission_tutorial")
	TimeManager.start_time()

	# Save initial state so the slot appears occupied
	save_game(slot_index)

	_autosave_timer = 0.0
	print("SaveManager: New game started in slot %d — '%s' as %s" % [slot_index, world_name, character_id])


func switch_character(character_id: String) -> bool:
	## Save current character's state, then load the new character's data.
	if GameState.current_save_slot < 1:
		return false
	if character_id == GameState.active_character_id:
		return false

	# First, save the current game to persist current character's progress
	var saved := save_game()
	if not saved:
		return false

	# Now load the save, but with the new character
	var slot := GameState.current_save_slot
	var file := FileAccess.open(_get_slot_path(slot), FileAccess.READ)
	if file == null:
		return false

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return false

	var save_data: Dictionary = json.data
	var characters: Dictionary = save_data.get("characters", {})

	# Load new character data into player_id 1
	GameState.active_character_id = character_id
	if characters.has(character_id):
		var char_data: Dictionary = characters[character_id]
		PlayerManager.load_save_data(1, char_data.get("player_data", {}))
		EconomyManager.load_save_data(1, int(char_data.get("economy", 0)))
		InventoryManager.load_save_data(1, char_data.get("inventory", []))
	else:
		PlayerManager.reset_player(1)
		EconomyManager.load_save_data(1, 0)
		InventoryManager.load_save_data(1, [])

	# Update the player sprite color
	var player_node = PlayerManager.get_player_node(1)
	if player_node:
		var sprite = player_node.get_node_or_null("PlaceholderSprite")
		if sprite:
			sprite.color = PlayerManager.get_character_color()

	# Re-apply stats for new character
	PlayerManager._apply_stats_to_node(1)

	print("SaveManager: Switched to character %s" % character_id)
	return true


func apply_death_penalty(player_id: int = 1) -> void:
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


func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(_get_slot_path(slot_index))


func has_any_save() -> bool:
	for i in range(1, SAVE_SLOT_COUNT + 1):
		if has_save(i):
			return true
	return false


func delete_save(slot_index: int) -> void:
	var path := _get_slot_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("SaveManager: Save slot %d deleted" % slot_index)
	slot_deleted.emit(slot_index)


func get_slot_info(slot_index: int) -> Dictionary:
	## Returns lightweight info about a save slot for the UI.
	if not has_save(slot_index):
		return {}

	var file := FileAccess.open(_get_slot_path(slot_index), FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return {}

	var save_data: Dictionary = json.data
	var characters: Dictionary = save_data.get("characters", {})

	# Gather character summaries
	var char_summaries := []
	for char_id in characters:
		var char_data: Dictionary = characters[char_id]
		var pdata: Dictionary = char_data.get("player_data", {})
		var char_def: Dictionary = DataManager.get_character(char_id)
		char_summaries.append({
			"id": char_id,
			"display_name": char_def.get("display_name", char_id),
			"level": pdata.get("level", 1),
		})

	var time_data: Dictionary = save_data.get("time", {})

	return {
		"world_name": save_data.get("world_name", "World"),
		"active_character_id": save_data.get("active_character_id", ""),
		"characters": char_summaries,
		"day": time_data.get("current_day", 1),
	}


func get_all_slot_info() -> Array:
	var result := []
	for i in range(1, SAVE_SLOT_COUNT + 1):
		result.append(get_slot_info(i))
	return result


func _get_character_save_data(char_id: String) -> Dictionary:
	## Gets save data for a specific character.
	## For the active character, pulls from live managers.
	## For inactive characters, reads from the current save file.
	if char_id == GameState.active_character_id:
		return {
			"player_data": PlayerManager.get_save_data(1),
			"economy": EconomyManager.get_save_data(1),
			"inventory": InventoryManager.get_save_data(1),
		}

	# For non-active characters, load from existing save file
	var slot := GameState.current_save_slot
	if slot < 1:
		# New game — return default data
		return _default_character_data()

	var path := _get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return _default_character_data()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _default_character_data()

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return _default_character_data()

	var save_data: Dictionary = json.data
	var characters: Dictionary = save_data.get("characters", {})
	if characters.has(char_id):
		return characters[char_id]
	return _default_character_data()


func _default_character_data() -> Dictionary:
	return {
		"player_data": {"level": 1, "xp": 0, "skill_points": 0, "unlocked_skills": []},
		"economy": 0,
		"inventory": [],
	}
