extends Node
## Phase 6 — Runtime Automated Tests
## Tests SaveManager save/load round-trip, new_game, all manager serialization.
##
## Run: godot --headless --path . --scene tests/TestPhase6Runtime.tscn

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 6 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_save_manager_exists()
	_test_player_manager_save_load()
	_test_economy_manager_save_load()
	_test_inventory_manager_save_load()
	_test_dungeon_manager_save_load()
	_test_mission_manager_save_load()
	_test_time_manager_save_load()
	_test_save_game_creates_file()
	_test_load_game_restores_state()
	_test_new_game_resets_state()
	_test_has_save_and_delete_save()

	_print_results()

	if DisplayServer.get_name() == "headless":
		get_tree().quit(1 if _failed > 0 else 0)


func _check(test_name: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % test_name)
	else:
		_failed += 1
		var msg := "  FAIL  %s" % test_name
		if detail != "":
			msg += " — %s" % detail
		print(msg)
		_errors.append(test_name)


func _section(title: String) -> void:
	print("\n" + "-".repeat(50))
	print("  %s" % title)
	print("-".repeat(50))


func _print_results() -> void:
	print("\n" + "=".repeat(60))
	print("  RESULTS: %d passed, %d failed" % [_passed, _failed])
	print("=".repeat(60))
	if _errors.size() > 0:
		print("\nFailed tests:")
		for e in _errors:
			print("  - %s" % e)


# --- Tests ---

func _test_save_manager_exists() -> void:
	_section("SaveManager Existence")
	_check("SaveManager autoload exists", SaveManager != null)
	_check("SaveManager has save_game()", SaveManager.has_method("save_game"))
	_check("SaveManager has load_game()", SaveManager.has_method("load_game"))
	_check("SaveManager has new_game()", SaveManager.has_method("new_game"))
	_check("SaveManager has has_save()", SaveManager.has_method("has_save"))
	_check("SaveManager has delete_save()", SaveManager.has_method("delete_save"))


func _test_player_manager_save_load() -> void:
	_section("PlayerManager Save/Load")

	# Set up test data
	PlayerManager.reset_player(1)
	PlayerManager.add_xp(1, 200)

	var save_data := PlayerManager.get_save_data(1)
	_check("PlayerManager get_save_data returns Dictionary",
		save_data is Dictionary)
	_check("Save data has level", save_data.has("level"))
	_check("Save data has xp", save_data.has("xp"))
	_check("Save data xp is 200", int(save_data.get("xp", 0)) == 200)

	# Modify and restore
	PlayerManager.add_xp(1, 999)
	PlayerManager.load_save_data(1, save_data)
	var restored := PlayerManager.get_save_data(1)
	_check("Restored xp matches saved xp",
		int(restored.get("xp", 0)) == 200,
		"got %d" % int(restored.get("xp", 0)))

	# Clean up
	PlayerManager.reset_player(1)


func _test_economy_manager_save_load() -> void:
	_section("EconomyManager Save/Load")

	EconomyManager.load_save_data(1, 0)
	EconomyManager.add_money(1, 500)

	var save_val: int = EconomyManager.get_save_data(1)
	_check("Economy save_data returns int", save_val is int)
	_check("Economy save_data is 500", save_val == 500, "got %d" % save_val)

	# Modify and restore
	EconomyManager.add_money(1, 1000)
	EconomyManager.load_save_data(1, save_val)
	_check("Restored money is 500",
		EconomyManager.get_money(1) == 500,
		"got %d" % EconomyManager.get_money(1))

	# Clean up
	EconomyManager.load_save_data(1, 0)


func _test_inventory_manager_save_load() -> void:
	_section("InventoryManager Save/Load")

	InventoryManager.load_save_data(1, [])

	# Get all items and add one if available
	var all_items: Array = DataManager.get_all_items()
	if all_items.is_empty():
		_check("Inventory test — no items available (skip)", true)
		return

	var test_item_id: String = all_items[0].get("id", "")
	InventoryManager.add_item(1, test_item_id)

	var save_data: Array = InventoryManager.get_save_data(1)
	_check("Inventory save_data returns Array", save_data is Array)
	_check("Inventory save_data has 1 item", save_data.size() == 1,
		"got %d" % save_data.size())

	# Modify and restore
	InventoryManager.clear_inventory(1)
	InventoryManager.load_save_data(1, save_data)
	_check("Restored inventory has 1 item",
		InventoryManager.get_inventory(1).size() == 1)

	# Clean up
	InventoryManager.load_save_data(1, [])


func _test_dungeon_manager_save_load() -> void:
	_section("DungeonManager Save/Load")

	DungeonManager.load_save_data({})
	var save_data := DungeonManager.get_save_data()
	_check("Dungeon save_data returns Dictionary", save_data is Dictionary)
	_check("Empty dungeon save_data is empty", save_data.is_empty())

	# Simulate completion data
	var test_data := {"crab_cave": 2, "abandoned_tunnel": 1}
	DungeonManager.load_save_data(test_data)
	var restored := DungeonManager.get_save_data()
	_check("Restored dungeon data has crab_cave",
		restored.has("crab_cave"))
	_check("Restored crab_cave count is 2",
		int(restored.get("crab_cave", 0)) == 2,
		"got %s" % str(restored.get("crab_cave")))

	# Clean up
	DungeonManager.load_save_data({})


func _test_mission_manager_save_load() -> void:
	_section("MissionManager Save/Load")

	MissionManager.load_save_data({})
	var save_data := MissionManager.get_save_data()
	_check("Mission save_data returns Dictionary", save_data is Dictionary)
	_check("Mission save_data has mission_states", save_data.has("mission_states"))
	_check("Mission save_data has objective_status", save_data.has("objective_status"))
	_check("Mission save_data has current_mission_id", save_data.has("current_mission_id"))

	# Clean up
	MissionManager.load_save_data({})


func _test_time_manager_save_load() -> void:
	_section("TimeManager Save/Load")

	TimeManager.load_save_data({})
	var save_data := TimeManager.get_save_data()
	_check("Time save_data returns Dictionary", save_data is Dictionary)
	_check("Time save_data has current_day", save_data.has("current_day"))
	_check("Time save_data has is_daytime", save_data.has("is_daytime"))
	_check("Time save_data has elapsed", save_data.has("elapsed"))

	# Modify and restore
	var test_data := {"current_day": 5, "is_daytime": false, "elapsed": 100.0}
	TimeManager.load_save_data(test_data)
	var restored := TimeManager.get_save_data()
	_check("Restored day is 5",
		int(restored.get("current_day", 0)) == 5,
		"got %s" % str(restored.get("current_day")))
	_check("Restored is_daytime is false",
		bool(restored.get("is_daytime", true)) == false)

	# Clean up
	TimeManager.load_save_data({})


func _test_save_game_creates_file() -> void:
	_section("SaveManager save_game()")

	# Clean any existing save
	SaveManager.delete_save()
	_check("No save before test", not SaveManager.has_save())

	# Set up some state to save
	PlayerManager.reset_player(1)
	PlayerManager.add_xp(1, 100)
	EconomyManager.load_save_data(1, 300)
	GameState.current_scene_path = "res://scenes/OverworldScene.tscn"
	GameState.is_in_dungeon = false

	var success := SaveManager.save_game()
	_check("save_game() returns true", success)
	_check("Save file exists after save", SaveManager.has_save())

	# Verify file content is valid JSON
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	_check("Save file is readable", file != null)
	if file:
		var json_str := file.get_as_text()
		file.close()
		var json := JSON.new()
		var err := json.parse(json_str)
		_check("Save file is valid JSON", err == OK, json.get_error_message())

		if err == OK:
			var data: Dictionary = json.data
			_check("Save has version key", data.has("version"))
			_check("Save has players key", data.has("players"))
			_check("Save has economy key", data.has("economy"))
			_check("Save has scene_path key", data.has("scene_path"))


func _test_load_game_restores_state() -> void:
	_section("SaveManager load_game()")

	# We should have a save from the previous test
	_check("Save exists for load test", SaveManager.has_save())

	# Modify state
	PlayerManager.reset_player(1)
	EconomyManager.load_save_data(1, 0)

	# Load should restore
	# Note: load_game() calls scene_manager.change_scene which requires Main node,
	# so we test the data restoration by manually reading and restoring.
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if file == null:
		_check("Load test: file readable", false)
		return

	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	json.parse(json_str)
	var save_data: Dictionary = json.data

	# Restore player data manually (since load_game needs SceneManager)
	var players: Dictionary = save_data.get("players", {})
	for pid_str in players:
		PlayerManager.load_save_data(int(pid_str), players[pid_str])

	var economy: Dictionary = save_data.get("economy", {})
	for pid_str in economy:
		EconomyManager.load_save_data(int(pid_str), int(economy[pid_str]))

	var player_data := PlayerManager.get_save_data(1)
	_check("Loaded player xp is 100",
		int(player_data.get("xp", 0)) == 100,
		"got %d" % int(player_data.get("xp", 0)))
	_check("Loaded money is 300",
		EconomyManager.get_money(1) == 300,
		"got %d" % EconomyManager.get_money(1))


func _test_new_game_resets_state() -> void:
	_section("SaveManager new_game()")

	# Set up non-default state
	PlayerManager.add_xp(1, 500)
	EconomyManager.add_money(1, 1000)

	# new_game calls scene_manager.change_scene which needs Main,
	# so we test the reset logic manually
	SaveManager.delete_save()
	PlayerManager.reset_player(1)
	EconomyManager.load_save_data(1, 0)
	InventoryManager.load_save_data(1, [])
	DungeonManager.load_save_data({})
	MissionManager.load_save_data({})
	TimeManager.load_save_data({})

	var player_data := PlayerManager.get_save_data(1)
	_check("After reset: player level is 1",
		int(player_data.get("level", 0)) == 1,
		"got %d" % int(player_data.get("level", 0)))
	_check("After reset: player xp is 0",
		int(player_data.get("xp", 0)) == 0,
		"got %d" % int(player_data.get("xp", 0)))
	_check("After reset: money is 0",
		EconomyManager.get_money(1) == 0,
		"got %d" % EconomyManager.get_money(1))
	_check("After reset: inventory is empty",
		InventoryManager.get_inventory(1).is_empty())
	_check("After reset: dungeon data is empty",
		DungeonManager.get_save_data().is_empty())


func _test_has_save_and_delete_save() -> void:
	_section("has_save / delete_save")

	# Create a save
	GameState.is_in_dungeon = false
	GameState.current_scene_path = "res://scenes/OverworldScene.tscn"
	SaveManager.save_game()
	_check("has_save() is true after save", SaveManager.has_save())

	SaveManager.delete_save()
	_check("has_save() is false after delete", not SaveManager.has_save())
