extends Node
## Phase 0 — Runtime Automated Tests
## Attach this to TestPhase0Runtime.tscn.
## Runs all tests in _ready(), prints results, then quits.
##
## Run from command line:
##   godot --headless --path . -s tests/test_phase0_runtime.gd
## Or run the TestPhase0Runtime.tscn scene from the editor.

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 0 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_autoloads_exist()
	_test_data_manager_config()
	_test_data_manager_enemies()
	_test_data_manager_items()
	_test_data_manager_skills()
	_test_data_manager_loot_tables()
	_test_data_manager_dungeons()
	_test_data_manager_missions()
	_test_data_manager_delivery_jobs()
	_test_data_manager_cross_references()
	_test_game_state_defaults()
	_test_manager_stubs_callable()
	_test_scene_manager()

	_print_results()

	# Auto-quit when run headless
	if DisplayServer.get_name() == "headless":
		if _failed > 0:
			get_tree().quit(1)
		else:
			get_tree().quit(0)


# ============================================================
#  HELPERS
# ============================================================

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
	if _failed > 0:
		print("\nFailed tests:")
		for e in _errors:
			print("  - %s" % e)
	else:
		print("\nAll runtime tests passed!")


# ============================================================
#  1. AUTOLOAD EXISTENCE
# ============================================================

func _test_autoloads_exist() -> void:
	_section("1. Autoloads Exist in Scene Tree")
	var expected := [
		"GameState", "DataManager", "SaveManager", "MultiplayerManager",
		"PlayerManager", "InventoryManager", "CombatManager",
		"DungeonManager", "EconomyManager", "TimeManager", "MissionManager"
	]
	for name in expected:
		var node = get_node_or_null("/root/" + name)
		_check("Autoload '%s' exists" % name, node != null)


# ============================================================
#  2. DATAMANAGER — CONFIG
# ============================================================

func _test_data_manager_config() -> void:
	_section("2. DataManager — Config")
	var config := DataManager.get_config()
	_check("Config is non-empty dict", config.size() > 0)
	_check("Config has xp_curve_exponent", config.has("xp_curve_exponent"))
	_check("xp_curve_exponent = 1.5", is_equal_approx(config.get("xp_curve_exponent", 0), 1.5))
	_check("base_xp_per_level = 100", config.get("base_xp_per_level", 0) == 100)
	_check("base_weekly_rent = 250", config.get("base_weekly_rent", 0) == 250)
	_check("max_player_level_demo = 5", config.get("max_player_level_demo", 0) == 5)
	_check("dungeon_scaling_per_completion = 0.15", is_equal_approx(config.get("dungeon_scaling_per_completion", 0), 0.15))

	var pbs = config.get("player_base_stats", {})
	_check("Player base health = 100", pbs.get("health", 0) == 100)
	_check("Player base stamina = 100", pbs.get("stamina", 0) == 100)
	_check("Player base damage = 10", pbs.get("damage", 0) == 10)
	_check("Player base move_speed = 120", pbs.get("move_speed", 0) == 120)
	_check("Player base crit_chance = 0.05", is_equal_approx(pbs.get("crit_chance", 0), 0.05))
	_check("Player base dodge_chance = 0.05", is_equal_approx(pbs.get("dodge_chance", 0), 0.05))


# ============================================================
#  3. DATAMANAGER — ENEMIES
# ============================================================

func _test_data_manager_enemies() -> void:
	_section("3. DataManager — Enemies")
	var all_enemies := DataManager.get_all_enemies()
	_check("Exactly 3 enemies", all_enemies.size() == 3, "got %d" % all_enemies.size())

	var rat := DataManager.get_enemy("melee_rat")
	_check("Cave Rat found", rat.size() > 0)
	_check("Cave Rat display_name", rat.get("display_name") == "Cave Rat")
	_check("Cave Rat type = melee", rat.get("type") == "melee")
	_check("Cave Rat health = 50", rat.get("base_stats", {}).get("health", 0) == 50)
	_check("Cave Rat damage = 8", rat.get("base_stats", {}).get("damage", 0) == 8)
	_check("Cave Rat xp_reward = 10", rat.get("xp_reward", 0) == 10)
	_check("Cave Rat money_drop min = 5", rat.get("money_drop", {}).get("min", 0) == 5)
	_check("Cave Rat money_drop max = 10", rat.get("money_drop", {}).get("max", 0) == 10)

	var crab := DataManager.get_enemy("ranged_crab")
	_check("Spitter Crab found", crab.size() > 0)
	_check("Spitter Crab type = ranged", crab.get("type") == "ranged")

	var king := DataManager.get_enemy("crab_king")
	_check("Crab King found", king.size() > 0)
	_check("Crab King type = boss", king.get("type") == "boss")
	_check("Crab King xp_reward = 150", king.get("xp_reward", 0) == 150)
	_check("Crab King money_drop min = 150", king.get("money_drop", {}).get("min", 0) == 150)
	_check("Crab King money_drop max = 250", king.get("money_drop", {}).get("max", 0) == 250)

	var missing := DataManager.get_enemy("nonexistent_enemy")
	_check("Missing enemy returns empty dict", missing.size() == 0)


# ============================================================
#  4. DATAMANAGER — ITEMS
# ============================================================

func _test_data_manager_items() -> void:
	_section("4. DataManager — Items")
	var all_items := DataManager.get_all_items()
	_check("Exactly 10 items", all_items.size() == 10, "got %d" % all_items.size())

	var ring := DataManager.get_item("damage_ring")
	_check("Rusty Ring found", ring.size() > 0)
	_check("Rusty Ring display_name", ring.get("display_name") == "Rusty Ring")
	var ring_effect = ring.get("effects", [{}])[0]
	_check("Rusty Ring +10% damage", is_equal_approx(ring_effect.get("value", 0), 0.10))

	var bp := DataManager.get_item("blood_pendant")
	_check("Blood Pendant found", bp.size() > 0)
	_check("Blood Pendant rarity = rare", bp.get("rarity") == "rare")

	var gi := DataManager.get_item("golden_idol")
	_check("Golden Idol found", gi.size() > 0)
	_check("Golden Idol rarity = rare", gi.get("rarity") == "rare")
	_check("Golden Idol has 6 effects", gi.get("effects", []).size() == 6)


# ============================================================
#  5. DATAMANAGER — SKILLS
# ============================================================

func _test_data_manager_skills() -> void:
	_section("5. DataManager — Skills")
	var all_skills := DataManager.get_all_skills()
	_check("Exactly 15 skills", all_skills.size() == 15, "got %d" % all_skills.size())

	var combat := DataManager.get_skills_by_category("combat")
	var economy := DataManager.get_skills_by_category("economy")
	var personality := DataManager.get_skills_by_category("personality")
	_check("5 combat skills", combat.size() == 5, "got %d" % combat.size())
	_check("5 economy skills", economy.size() == 5, "got %d" % economy.size())
	_check("5 personality skills", personality.size() == 5, "got %d" % personality.size())

	var s := DataManager.get_skill("combat_damage_1")
	_check("Skill combat_damage_1 found", s.size() > 0)
	_check("Skill max_level = 1", s.get("max_level", 0) == 1)
	_check("Skill has no requirements (root node)", s.get("requirements", []).size() == 0)

	var s2 := DataManager.get_skill("combat_crit_1")
	_check("Skill combat_crit_1 requires combat_damage_1", s2.get("requirements", []).has("combat_damage_1"))


# ============================================================
#  6. DATAMANAGER — LOOT TABLES
# ============================================================

func _test_data_manager_loot_tables() -> void:
	_section("6. DataManager — Loot Tables")
	var basic := DataManager.get_loot_table("basic_dungeon_loot")
	_check("basic_dungeon_loot found", basic.size() > 0)
	_check("basic_dungeon_loot has drops", basic.get("drops", []).size() > 0)

	var boss := DataManager.get_loot_table("boss_loot")
	_check("boss_loot found", boss.size() > 0)
	_check("boss_loot has drops", boss.get("drops", []).size() > 0)

	# Verify all weights are positive
	for drop in basic.get("drops", []):
		_check("basic_dungeon_loot item '%s' weight > 0" % drop.get("item_id", "?"), drop.get("weight", 0) > 0)


# ============================================================
#  7. DATAMANAGER — DUNGEONS
# ============================================================

func _test_data_manager_dungeons() -> void:
	_section("7. DataManager — Dungeons")
	var all_d := DataManager.get_all_dungeons()
	_check("Exactly 2 dungeons", all_d.size() == 2, "got %d" % all_d.size())

	var cc := DataManager.get_dungeon("crab_cave")
	_check("Crab Cave found", cc.size() > 0)
	_check("Crab Cave type = story", cc.get("type") == "story")
	_check("Crab Cave replayable = false", cc.get("replayable") == false)
	var cc_rooms = cc.get("rooms", [])
	var combat_count := 0
	var boss_count := 0
	for room in cc_rooms:
		if room.get("room_type") == "combat":
			combat_count += 1
		elif room.get("room_type") == "boss":
			boss_count += 1
	_check("Crab Cave 2 combat rooms", combat_count == 2, "got %d" % combat_count)
	_check("Crab Cave 1 boss room", boss_count == 1, "got %d" % boss_count)

	var at := DataManager.get_dungeon("abandoned_tunnel")
	_check("Abandoned Tunnel found", at.size() > 0)
	_check("Abandoned Tunnel type = replayable", at.get("type") == "replayable")
	_check("Abandoned Tunnel replayable = true", at.get("replayable") == true)


# ============================================================
#  8. DATAMANAGER — MISSIONS
# ============================================================

func _test_data_manager_missions() -> void:
	_section("8. DataManager — Missions")
	var all_m := DataManager.get_all_missions()
	_check("Exactly 5 missions", all_m.size() == 5, "got %d" % all_m.size())

	# Verify chain
	var chain := ["mission_tutorial", "mission_papers", "mission_first_delivery", "mission_crab_cave", "mission_pay_rent"]
	for i in range(chain.size()):
		var m := DataManager.get_mission(chain[i])
		_check("Mission '%s' found" % chain[i], m.size() > 0)
		var expected_next = chain[i + 1] if i + 1 < chain.size() else null
		var actual_next = m.get("next_mission_id")
		_check("Mission '%s' → next = '%s'" % [chain[i], str(expected_next)], actual_next == expected_next, "got '%s'" % str(actual_next))


# ============================================================
#  9. DATAMANAGER — DELIVERY JOBS
# ============================================================

func _test_data_manager_delivery_jobs() -> void:
	_section("9. DataManager — Delivery Jobs")
	var jobs := DataManager.get_delivery_jobs()
	_check("At least 1 delivery job", jobs.size() >= 1, "got %d" % jobs.size())
	if jobs.size() > 0:
		_check("Delivery job base_reward = 50", jobs[0].get("base_reward", 0) == 50)
		_check("Delivery job delivery_points = 3", jobs[0].get("delivery_points", 0) == 3)


# ============================================================
# 10. DATAMANAGER — CROSS-REFERENCE (via load_errors)
# ============================================================

func _test_data_manager_cross_references() -> void:
	_section("10. DataManager — Cross-Reference Validation")
	_check("DataManager has zero load errors", DataManager._load_errors.size() == 0,
		"errors: %s" % str(DataManager._load_errors))


# ============================================================
# 11. GAMESTATE DEFAULTS
# ============================================================

func _test_game_state_defaults() -> void:
	_section("11. GameState Defaults")
	_check("current_scene_type starts empty", GameState.current_scene_type == "")
	_check("is_in_dungeon starts false", GameState.is_in_dungeon == false)
	_check("is_paused starts false", GameState.is_paused == false)
	_check("is_host starts true", GameState.is_host == true)
	_check("player_count starts 1", GameState.player_count == 1)
	_check("current_day starts 1", GameState.current_day == 1)


# ============================================================
# 12. MANAGER STUBS — METHODS CALLABLE
# ============================================================

func _test_manager_stubs_callable() -> void:
	_section("12. Manager Stubs — Methods Callable")

	# PlayerManager
	_check("PlayerManager.get_stats(1) callable", PlayerManager.get_stats(1) is Dictionary)
	_check("PlayerManager.get_level(1) callable", PlayerManager.get_level(1) is int)
	_check("PlayerManager.get_xp(1) callable", PlayerManager.get_xp(1) is int)

	# InventoryManager
	_check("InventoryManager.get_inventory(1) callable", InventoryManager.get_inventory(1) is Array)
	_check("InventoryManager.get_passive_modifiers(1) callable", InventoryManager.get_passive_modifiers(1) is Dictionary)

	# EconomyManager
	_check("EconomyManager.get_money(1) callable", EconomyManager.get_money(1) is int)
	_check("EconomyManager.get_weekly_rent() callable", EconomyManager.get_weekly_rent() > 0)

	# DungeonManager
	_check("DungeonManager.get_completion_count('crab_cave') callable", DungeonManager.get_completion_count("crab_cave") is int)
	var scaling := DungeonManager.get_scaling("crab_cave")
	_check("DungeonManager.get_scaling() returns dict", scaling is Dictionary)
	_check("Scaling has difficulty_multiplier", scaling.has("difficulty_multiplier"))

	# TimeManager
	_check("TimeManager.get_current_day() callable", TimeManager.get_current_day() is int)

	# MissionManager
	_check("MissionManager.get_active_mission_id() callable", MissionManager.get_active_mission_id() is String)
	_check("MissionManager.is_mission_completed() callable", MissionManager.is_mission_completed("test") is bool)

	# SaveManager
	_check("SaveManager.has_save() callable", SaveManager.has_save() is bool)

	# MultiplayerManager
	_check("MultiplayerManager.is_host() callable", MultiplayerManager.is_host() is bool)
	_check("MultiplayerManager.get_peer_ids() callable", MultiplayerManager.get_peer_ids() is Array)


# ============================================================
# 13. SCENE MANAGER
# ============================================================

func _test_scene_manager() -> void:
	_section("13. SceneManager")
	# SceneManager is a child of Main.tscn, find it
	var sm = get_node_or_null("/root/Main/SceneManager")
	_check("SceneManager exists under Main", sm != null)
	if sm:
		_check("SceneManager has change_scene method", sm.has_method("change_scene"))
		_check("SceneManager has get_current_scene method", sm.has_method("get_current_scene"))
		_check("SceneManager has scene_changed signal", sm.has_signal("scene_changed"))
