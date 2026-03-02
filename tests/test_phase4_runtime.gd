extends Node
## Phase 4 — Runtime Automated Tests
## Tests DungeonManager lifecycle, scaling, room progression, death penalty.
##
## Run: godot --headless --path . --scene tests/TestPhase4Runtime.tscn

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 4 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_dungeon_manager_exists()
	_test_scaling_formulas()
	_test_scaling_cap()
	_test_completion_count_tracking()
	_test_dungeon_queries()
	_test_story_dungeon_single_completion()
	_test_death_penalty()
	_test_save_load_data()

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

func _test_dungeon_manager_exists() -> void:
	_section("DungeonManager Existence")
	_check("DungeonManager singleton exists", DungeonManager != null)
	_check("has start_dungeon method", DungeonManager.has_method("start_dungeon"))
	_check("has complete_dungeon method", DungeonManager.has_method("complete_dungeon"))
	_check("has fail_dungeon method", DungeonManager.has_method("fail_dungeon"))
	_check("has start_next_room method", DungeonManager.has_method("start_next_room"))
	_check("has get_scaling method", DungeonManager.has_method("get_scaling"))
	_check("has is_dungeon_active method", DungeonManager.has_method("is_dungeon_active"))
	_check("has get_completion_count method", DungeonManager.has_method("get_completion_count"))


func _test_scaling_formulas() -> void:
	_section("Scaling Formulas")

	# Reset completion counts
	DungeonManager.load_save_data({})

	# Completion 0: all multipliers should be 1.0
	var s0: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("comp 0: difficulty = 1.0",
		is_equal_approx(s0["difficulty_multiplier"], 1.0),
		"got %.3f" % s0["difficulty_multiplier"])
	_check("comp 0: health = 1.0",
		is_equal_approx(s0["enemy_health_multiplier"], 1.0),
		"got %.3f" % s0["enemy_health_multiplier"])

	# Set completion count to 1 and check
	DungeonManager.load_save_data({"abandoned_tunnel": 1})
	var s1: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("comp 1: difficulty = 1.15",
		is_equal_approx(s1["difficulty_multiplier"], 1.15),
		"got %.3f" % s1["difficulty_multiplier"])
	_check("comp 1: health = 1.12",
		is_equal_approx(s1["enemy_health_multiplier"], 1.12),
		"got %.3f" % s1["enemy_health_multiplier"])
	_check("comp 1: damage = 1.08",
		is_equal_approx(s1["enemy_damage_multiplier"], 1.08),
		"got %.3f" % s1["enemy_damage_multiplier"])
	_check("comp 1: count = 1.10",
		is_equal_approx(s1["enemy_count_multiplier"], 1.10),
		"got %.3f" % s1["enemy_count_multiplier"])
	_check("comp 1: loot quality = 1.10",
		is_equal_approx(s1["loot_quality_multiplier"], 1.10),
		"got %.3f" % s1["loot_quality_multiplier"])

	# Completion 5
	DungeonManager.load_save_data({"abandoned_tunnel": 5})
	var s5: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("comp 5: difficulty = 1.75",
		is_equal_approx(s5["difficulty_multiplier"], 1.75),
		"got %.3f" % s5["difficulty_multiplier"])

	# Reset
	DungeonManager.load_save_data({})


func _test_scaling_cap() -> void:
	_section("Scaling Cap")

	# Set very high completion count
	DungeonManager.load_save_data({"abandoned_tunnel": 20})
	var s: Dictionary = DungeonManager.get_scaling("abandoned_tunnel")
	_check("difficulty capped at 3.0",
		is_equal_approx(s["difficulty_multiplier"], 3.0),
		"got %.3f" % s["difficulty_multiplier"])

	# Health/damage/count are NOT capped (only difficulty is in current spec)
	_check("health NOT capped (scales beyond 3)",
		s["enemy_health_multiplier"] > 3.0,
		"got %.3f" % s["enemy_health_multiplier"])

	DungeonManager.load_save_data({})


func _test_completion_count_tracking() -> void:
	_section("Completion Count Tracking")

	DungeonManager.load_save_data({})
	_check("initial count = 0", DungeonManager.get_completion_count("abandoned_tunnel") == 0)

	DungeonManager.load_save_data({"abandoned_tunnel": 3})
	_check("loaded count = 3",
		DungeonManager.get_completion_count("abandoned_tunnel") == 3)

	_check("unknown dungeon count = 0",
		DungeonManager.get_completion_count("nonexistent") == 0)

	DungeonManager.load_save_data({})


func _test_dungeon_queries() -> void:
	_section("Dungeon Queries")

	# Not active initially
	_check("not active initially", not DungeonManager.is_dungeon_active())
	_check("active dungeon id empty", DungeonManager.get_active_dungeon_id() == "")

	# Test dungeon data loading
	var cc_data: Dictionary = DataManager.get_dungeon("crab_cave")
	_check("crab_cave data loaded", not cc_data.is_empty())
	_check("crab_cave has 3 rooms", cc_data.get("rooms", []).size() == 3)
	_check("crab_cave type is story", cc_data.get("type") == "story")

	var at_data: Dictionary = DataManager.get_dungeon("abandoned_tunnel")
	_check("abandoned_tunnel data loaded", not at_data.is_empty())
	_check("abandoned_tunnel is replayable", at_data.get("replayable") == true)


func _test_story_dungeon_single_completion() -> void:
	_section("Story Dungeon Completion Check")

	DungeonManager.load_save_data({})
	_check("crab_cave not completed initially",
		not DungeonManager.is_dungeon_completed("crab_cave"))

	DungeonManager.load_save_data({"crab_cave": 1})
	_check("crab_cave completed after count=1",
		DungeonManager.is_dungeon_completed("crab_cave"))

	DungeonManager.load_save_data({})


func _test_death_penalty() -> void:
	_section("Death Penalty Config")

	var config: Dictionary = DataManager.get_config()
	var penalty: Dictionary = config.get("death_penalty", {})
	_check("money_loss_percent = 0.10",
		is_equal_approx(float(penalty.get("money_loss_percent", 0)), 0.10),
		"got %s" % str(penalty.get("money_loss_percent")))
	_check("item_loss_count = 1",
		int(penalty.get("item_loss_count", 0)) == 1,
		"got %s" % str(penalty.get("item_loss_count")))

	# Test penalty math: 500 money * 10% = 50 lost
	var money := 500
	var loss := roundi(float(money) * float(penalty.get("money_loss_percent", 0.10)))
	_check("500 money * 10% = 50 lost", loss == 50, "got %d" % loss)


func _test_save_load_data() -> void:
	_section("Save/Load Data")

	DungeonManager.load_save_data({})
	_check("empty save = 0 completions",
		DungeonManager.get_completion_count("crab_cave") == 0)

	var test_data := {"crab_cave": 1, "abandoned_tunnel": 7}
	DungeonManager.load_save_data(test_data)

	var saved: Dictionary = DungeonManager.get_save_data()
	_check("save data includes crab_cave",
		saved.get("crab_cave", 0) == 1,
		"got %s" % str(saved.get("crab_cave")))
	_check("save data includes abandoned_tunnel",
		saved.get("abandoned_tunnel", 0) == 7,
		"got %s" % str(saved.get("abandoned_tunnel")))

	DungeonManager.load_save_data({})
