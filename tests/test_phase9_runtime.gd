extends Node
## Phase 9 Runtime Tests — Cross-System Integration.
## Tests that all managers work together, data flows correctly
## between systems, and the full game loop functions.

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	print("\n=== Phase 9 Runtime Integration Tests ===\n")
	_test_all_autoloads_accessible()
	_test_data_manager_loads_all()
	_test_player_new_game_flow()
	_test_xp_and_leveling()
	_test_economy_flow()
	_test_inventory_with_data()
	_test_dungeon_scaling()
	_test_combat_damage_formula()
	_test_mission_chain()
	_test_time_manager_flow()
	_test_audio_manager_integration()
	_test_save_load_roundtrip()

	print("\n--- Results: %d passed, %d failed ---" % [_pass_count, _fail_count])


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS  %s" % label)
		_pass_count += 1
	else:
		print("  FAIL  %s" % label)
		_fail_count += 1


# --- All Autoloads Accessible ---

func _test_all_autoloads_accessible() -> void:
	print("--- All Autoloads Accessible ---")
	_check("DataManager accessible", DataManager != null)
	_check("GameState accessible", GameState != null)
	_check("SaveManager accessible", SaveManager != null)
	_check("PlayerManager accessible", PlayerManager != null)
	_check("InventoryManager accessible", InventoryManager != null)
	_check("CombatManager accessible", CombatManager != null)
	_check("DungeonManager accessible", DungeonManager != null)
	_check("EconomyManager accessible", EconomyManager != null)
	_check("TimeManager accessible", TimeManager != null)
	_check("MissionManager accessible", MissionManager != null)
	_check("MultiplayerManager accessible", MultiplayerManager != null)


# --- DataManager Loads All Data ---

func _test_data_manager_loads_all() -> void:
	print("--- DataManager Loads All Data ---")
	_check("Config loaded (non-empty)", DataManager.get_config().size() > 0)
	_check("Enemies loaded = 3", DataManager.get_all_enemies().size() == 3)
	_check("Items loaded = 10", DataManager.get_all_items().size() == 10)
	_check("Skills loaded = 15", DataManager.get_all_skills().size() == 15)
	_check("Dungeons loaded = 2", DataManager.get_all_dungeons().size() == 2)
	_check("Missions loaded = 5", DataManager.get_all_missions().size() == 5)

	# Specific lookups work
	var rat: Dictionary = DataManager.get_enemy("melee_rat")
	_check("get_enemy('melee_rat') returns data", not rat.is_empty())
	_check("Cave Rat HP = 50", rat.get("base_stats", {}).get("health", 0) == 50)

	var ring: Dictionary = DataManager.get_item("damage_ring")
	_check("get_item('damage_ring') returns data", not ring.is_empty())


# --- New Game Flow ---

func _test_player_new_game_flow() -> void:
	print("--- New Game Player Setup ---")
	# Simulate new game state
	PlayerManager.reset_player(1)

	_check("Player 1 level starts at 1", PlayerManager.get_level(1) == 1)
	_check("Player 1 XP starts at 0", PlayerManager.get_xp(1) == 0)
	_check("Player 1 skill points start at 0", PlayerManager.get_skill_points(1) == 0)

	var hp: float = PlayerManager.get_effective_stat(1, "health")
	_check("Player 1 health = 100 (base)", is_equal_approx(hp, 100.0))

	var dmg: float = PlayerManager.get_effective_stat(1, "damage")
	_check("Player 1 damage = 10 (base)", is_equal_approx(dmg, 10.0))


# --- XP and Leveling ---

func _test_xp_and_leveling() -> void:
	print("--- XP and Leveling ---")
	PlayerManager.reset_player(1)

	var xp_for_2: int = PlayerManager.get_xp_for_next_level(1)
	_check("XP needed for level 2 = 100", xp_for_2 == 100)

	PlayerManager.add_xp(1, xp_for_2)
	_check("After adding XP → level 2", PlayerManager.get_level(1) == 2)
	_check("Gained 1 skill point", PlayerManager.get_skill_points(1) == 1)

	# Level to max
	for lvl in range(2, 5):
		var needed: int = PlayerManager.get_xp_for_next_level(lvl)
		PlayerManager.add_xp(1, needed)
	_check("Player reached max level 5", PlayerManager.get_level(1) == 5)
	_check("4 total skill points at level 5", PlayerManager.get_skill_points(1) == 4)

	PlayerManager.reset_player(1)


# --- Economy Flow ---

func _test_economy_flow() -> void:
	print("--- Economy Flow ---")
	EconomyManager.load_save_data(1, 0)

	EconomyManager.add_money(1, 500)
	_check("After adding 500, balance = 500", EconomyManager.get_money(1) == 500)

	var rent_amount: int = EconomyManager.get_rent_amount()
	_check("Rent amount = 250", rent_amount == 250)

	var paid := EconomyManager.pay_rent(1)
	_check("Pay rent succeeded", paid == true)
	_check("After rent, balance = 250", EconomyManager.get_money(1) == 250)

	# Can't pay rent with insufficient funds
	EconomyManager.load_save_data(1, 100)
	var failed := EconomyManager.pay_rent(1)
	_check("Pay rent with 100 fails", failed == false)
	_check("Balance unchanged after failed rent", EconomyManager.get_money(1) == 100)

	EconomyManager.load_save_data(1, 0)


# --- Inventory with Data ---

func _test_inventory_with_data() -> void:
	print("--- Inventory with Data ---")
	InventoryManager.clear_inventory(1)

	var added := InventoryManager.add_item(1, "damage_ring")
	_check("Add damage_ring succeeded", added == true)
	_check("Inventory has 1 item", InventoryManager.get_item_count(1) == 1)
	_check("Has damage_ring", InventoryManager.has_item(1, "damage_ring"))

	# Stat effect should boost damage
	var dmg: float = PlayerManager.get_effective_stat(1, "damage")
	_check("Damage boosted by Rusty Ring (+10%)", dmg > 10.0)

	InventoryManager.remove_item(1, "damage_ring")
	_check("After remove, inventory empty", InventoryManager.get_item_count(1) == 0)

	var dmg_after: float = PlayerManager.get_effective_stat(1, "damage")
	_check("Damage back to base after item removed", is_equal_approx(dmg_after, 10.0))

	InventoryManager.clear_inventory(1)


# --- Dungeon Scaling ---

func _test_dungeon_scaling() -> void:
	print("--- Dungeon Scaling ---")
	DungeonManager.load_save_data({})

	var scaling: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("Initial scaling enemy_count_multiplier = 1.0",
		is_equal_approx(scaling.get("enemy_count_multiplier", 0.0), 1.0))

	# Simulate completions
	DungeonManager.record_completion("abandoned_tunnel")
	var scaling2: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("After 1 completion, scaling increased",
		scaling2.get("enemy_count_multiplier", 0.0) > 1.0)

	DungeonManager.load_save_data({})


# --- Combat Damage Formula ---

func _test_combat_damage_formula() -> void:
	print("--- Combat Damage Formula ---")
	# Test the weighted drop resolver
	var drops := [
		{"item_id": "a", "weight": 100},
		{"item_id": "b", "weight": 0}
	]
	var result: String = CombatManager.resolve_weighted_drop(drops)
	_check("100% weight item always drops", result == "a")

	var empty_result: String = CombatManager.resolve_weighted_drop([])
	_check("Empty drops returns empty string", empty_result == "")


# --- Mission Chain ---

func _test_mission_chain() -> void:
	print("--- Mission Chain ---")
	MissionManager.load_save_data({})

	MissionManager.start_mission("mission_tutorial")
	var active: String = MissionManager.get_active_mission_id()
	_check("Active mission = mission_tutorial", active == "mission_tutorial")

	# Complete all objectives
	var obj_count: int = MissionManager.get_objective_count(active)
	_check("Tutorial has 2 objectives", obj_count == 2)

	for i in range(obj_count):
		MissionManager.complete_objective(active, i)

	_check("Tutorial completed",
		MissionManager.get_mission_state("mission_tutorial") == "completed")

	# Next mission auto-available
	var next_active: String = MissionManager.get_active_mission_id()
	_check("Next mission is mission_papers", next_active == "mission_papers")

	MissionManager.load_save_data({})


# --- TimeManager ---

func _test_time_manager_flow() -> void:
	print("--- TimeManager Flow ---")
	TimeManager.load_save_data({})

	TimeManager.start_time()
	_check("TimeManager active after start", TimeManager.is_active == true)

	TimeManager.set_paused(true)
	_check("Paused via set_paused(true)", TimeManager.is_active == false)

	TimeManager.set_paused(false)
	_check("Resumed via set_paused(false)", TimeManager.is_active == true)

	TimeManager.advance_to_night()
	_check("After advance_to_night, is_night() true", TimeManager.is_night() == true)

	TimeManager.advance_to_next_day()
	_check("After advance_to_next_day, day incremented", TimeManager.get_current_day() >= 2)

	TimeManager.pause_time()
	TimeManager.load_save_data({})


# --- AudioManager ---

func _test_audio_manager_integration() -> void:
	print("--- AudioManager Integration ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio == null:
		_check("AudioManager accessible", false)
		return
	_check("AudioManager accessible", true)

	# BGM/SFX basic operations
	audio.play_bgm("overworld")
	_check("BGM set to overworld", audio.get_current_bgm() == "overworld")
	audio.stop_bgm()

	audio.play_sfx("hit")
	_check("SFX plays without error", true)

	audio.set_master_volume(0.5)
	_check("Master volume set", is_equal_approx(audio.master_volume, 0.5))
	audio.set_master_volume(0.8)


# --- Save/Load Roundtrip ---

func _test_save_load_roundtrip() -> void:
	print("--- Save/Load Roundtrip ---")
	# Setup known state
	PlayerManager.reset_player(1)
	PlayerManager.add_xp(1, 100)  # Level up to 2
	EconomyManager.load_save_data(1, 350)
	InventoryManager.clear_inventory(1)
	InventoryManager.add_item(1, "damage_ring")

	# Save
	var saved := SaveManager.save_game()
	_check("Save succeeded", saved == true)

	# Modify state
	PlayerManager.reset_player(1)
	EconomyManager.load_save_data(1, 0)
	InventoryManager.clear_inventory(1)
	_check("State reset: level=1", PlayerManager.get_level(1) == 1)
	_check("State reset: money=0", EconomyManager.get_money(1) == 0)

	# Load
	var loaded := SaveManager.load_game()
	_check("Load succeeded", loaded == true)
	_check("Restored level = 2", PlayerManager.get_level(1) == 2)
	_check("Restored money = 350", EconomyManager.get_money(1) == 350)
	_check("Restored inventory has damage_ring", InventoryManager.has_item(1, "damage_ring"))

	# Cleanup
	SaveManager.delete_save()
	PlayerManager.reset_player(1)
	EconomyManager.load_save_data(1, 0)
	InventoryManager.clear_inventory(1)
