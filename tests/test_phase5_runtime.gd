extends Node
## Phase 5 — Runtime Automated Tests
## Tests TimeManager, MissionManager, delivery economy, overworld integration.
##
## Run: godot --headless --path . --scene tests/TestPhase5Runtime.tscn

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 5 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_time_manager_exists()
	_test_time_manager_lifecycle()
	_test_time_manager_day_night()
	_test_time_manager_time_string()
	_test_mission_manager_exists()
	_test_mission_lifecycle()
	_test_mission_chain()
	_test_mission_objective_completion()
	_test_mission_rewards()
	_test_delivery_economy()
	_test_rent_with_time()
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


# --- TimeManager Tests ---

func _test_time_manager_exists() -> void:
	_section("TimeManager Existence")
	_check("TimeManager singleton exists", TimeManager != null)
	_check("has start_time method", TimeManager.has_method("start_time"))
	_check("has pause_time method", TimeManager.has_method("pause_time"))
	_check("has resume_time method", TimeManager.has_method("resume_time"))
	_check("has get_time_string method", TimeManager.has_method("get_time_string"))
	_check("has advance_to_next_day method", TimeManager.has_method("advance_to_next_day"))
	_check("has advance_to_night method", TimeManager.has_method("advance_to_night"))
	_check("has week_ended signal", TimeManager.has_signal("week_ended"))
	_check("has day_started signal", TimeManager.has_signal("day_started"))
	_check("has night_started signal", TimeManager.has_signal("night_started"))
	_check("has time_updated signal", TimeManager.has_signal("time_updated"))


func _test_time_manager_lifecycle() -> void:
	_section("TimeManager Lifecycle")

	# Initially inactive
	TimeManager.is_active = false
	_check("initially not active", not TimeManager.is_active)

	# Start
	GameState.current_day = 1
	TimeManager.start_time()
	_check("active after start_time", TimeManager.is_active)
	_check("is_daytime after start", TimeManager.is_daytime)
	_check("time_of_day starts at 0", is_equal_approx(GameState.current_time_of_day, 0.0))

	# Pause
	TimeManager.pause_time()
	_check("not active after pause", not TimeManager.is_active)

	# Resume
	TimeManager.resume_time()
	_check("active after resume", TimeManager.is_active)

	# Clean up
	TimeManager.pause_time()


func _test_time_manager_day_night() -> void:
	_section("TimeManager Day/Night")

	GameState.current_day = 1
	TimeManager.start_time()

	# Advance to night
	TimeManager.advance_to_night()
	_check("is night after advance_to_night", TimeManager.is_night())
	_check("not daytime", not TimeManager.is_daytime)

	# Advance to next day
	TimeManager.advance_to_next_day()
	_check("is daytime after advance_to_next_day", TimeManager.is_daytime)
	_check("day incremented", GameState.current_day >= 2,
		"day = %d" % GameState.current_day)

	TimeManager.pause_time()
	GameState.current_day = 1


func _test_time_manager_time_string() -> void:
	_section("TimeManager Time String")

	GameState.current_day = 3
	GameState.current_time_of_day = 0.0
	_check("morning string", "Morning" in TimeManager.get_time_string())

	GameState.current_time_of_day = 0.3
	_check("afternoon string", "Afternoon" in TimeManager.get_time_string())

	GameState.current_time_of_day = 0.6
	_check("evening string", "Evening" in TimeManager.get_time_string())

	GameState.current_time_of_day = 0.8
	_check("night string", "Night" in TimeManager.get_time_string())

	_check("day number in string", "Day 3" in TimeManager.get_time_string())

	GameState.current_day = 1
	GameState.current_time_of_day = 0.0


# --- MissionManager Tests ---

func _test_mission_manager_exists() -> void:
	_section("MissionManager Existence")
	_check("MissionManager singleton exists", MissionManager != null)
	_check("has start_mission method", MissionManager.has_method("start_mission"))
	_check("has complete_objective method", MissionManager.has_method("complete_objective"))
	_check("has fail_mission method", MissionManager.has_method("fail_mission"))
	_check("has get_mission_state method", MissionManager.has_method("get_mission_state"))
	_check("has get_active_mission_id method", MissionManager.has_method("get_active_mission_id"))
	_check("has notify_talk_to_npc method", MissionManager.has_method("notify_talk_to_npc"))
	_check("has notify_reach_location method", MissionManager.has_method("notify_reach_location"))
	_check("has notify_enter_dungeon method", MissionManager.has_method("notify_enter_dungeon"))
	_check("has notify_deliver_item method", MissionManager.has_method("notify_deliver_item"))
	_check("has notify_return_home method", MissionManager.has_method("notify_return_home"))
	_check("has mission_started signal", MissionManager.has_signal("mission_started"))
	_check("has mission_completed signal", MissionManager.has_signal("mission_completed"))
	_check("has mission_failed signal", MissionManager.has_signal("mission_failed"))
	_check("has objective_completed signal", MissionManager.has_signal("objective_completed"))


func _test_mission_lifecycle() -> void:
	_section("Mission Lifecycle")

	# Reset
	MissionManager.load_save_data({})

	# Start tutorial
	var started := MissionManager.start_mission("mission_tutorial")
	_check("tutorial started successfully", started)
	_check("active mission is tutorial",
		MissionManager.get_active_mission_id() == "mission_tutorial")
	_check("mission state is ACTIVE",
		MissionManager.get_mission_state("mission_tutorial") == MissionManager.MissionState.ACTIVE)

	# Fail unknown mission
	var bad := MissionManager.start_mission("nonexistent_mission")
	_check("unknown mission returns false", not bad)

	# Fail mission
	MissionManager.fail_mission("mission_tutorial")
	_check("failed state",
		MissionManager.get_mission_state("mission_tutorial") == MissionManager.MissionState.FAILED)
	_check("no active mission after fail",
		MissionManager.get_active_mission_id() == "")

	MissionManager.load_save_data({})


func _test_mission_chain() -> void:
	_section("Mission Chain")

	MissionManager.load_save_data({})

	var chain := ["mission_tutorial", "mission_papers", "mission_first_delivery",
		"mission_crab_cave", "mission_pay_rent"]

	# Start the first mission
	MissionManager.start_mission("mission_tutorial")
	_check("chain starts with tutorial",
		MissionManager.get_active_mission_id() == "mission_tutorial")

	# Complete each mission's objectives to verify chain progression
	# Tutorial: talk_to_npc(hannan) + reach_location(player_house)
	MissionManager.complete_objective("mission_tutorial", 0)
	MissionManager.complete_objective("mission_tutorial", 1)

	# Should auto-advance to mission_papers
	_check("auto-advanced to mission_papers",
		MissionManager.get_active_mission_id() == "mission_papers",
		"active = '%s'" % MissionManager.get_active_mission_id())
	_check("tutorial is completed",
		MissionManager.is_mission_completed("mission_tutorial"))

	MissionManager.load_save_data({})


func _test_mission_objective_completion() -> void:
	_section("Objective Completion via Notify")

	MissionManager.load_save_data({})
	MissionManager.start_mission("mission_tutorial")

	# Objective 0: talk_to_npc hannan
	MissionManager.notify_talk_to_npc("hannan")
	var status: Array = MissionManager.get_objective_status("mission_tutorial")
	_check("obj 0 completed by notify", status.size() >= 1 and status[0] == true,
		"status = %s" % str(status))

	# Wrong NPC should not complete obj 1
	MissionManager.notify_talk_to_npc("jack")
	status = MissionManager.get_objective_status("mission_tutorial")
	_check("obj 1 not completed by wrong NPC",
		status.size() >= 2 and status[1] == false,
		"status = %s" % str(status))

	# Correct location
	MissionManager.notify_reach_location("player_house")
	status = MissionManager.get_objective_status("mission_tutorial")
	_check("obj 1 completed by reach_location",
		status.size() >= 2 and status[1] == true,
		"status = %s" % str(status))

	MissionManager.load_save_data({})


func _test_mission_rewards() -> void:
	_section("Mission Rewards")

	MissionManager.load_save_data({})

	# Track starting values
	var start_money := EconomyManager.get_money(1)
	var start_level := PlayerManager.get_level(1)
	var start_xp := PlayerManager.get_xp(1)

	# Start and complete tutorial (rewards: 50 money, 50 xp)
	MissionManager.start_mission("mission_tutorial")
	MissionManager.complete_objective("mission_tutorial", 0)
	MissionManager.complete_objective("mission_tutorial", 1)

	var end_money := EconomyManager.get_money(1)
	_check("tutorial gave 50 money",
		end_money == start_money + 50,
		"money: %d → %d (expected +50)" % [start_money, end_money])

	MissionManager.load_save_data({})


# --- Economy Tests ---

func _test_delivery_economy() -> void:
	_section("Delivery Economy")

	var base_reward: int = DataManager.get_config_value("base_delivery_reward", 50)
	_check("base delivery reward = 50", base_reward == 50)

	# Effective delivery reward
	var effective := EconomyManager.get_delivery_reward(1)
	_check("effective delivery reward >= 50", effective >= 50,
		"got %d" % effective)

	# Total delivery income: 3 delivery points * 50 = 150
	var total_3_deliveries := 3 * effective
	_check("3 deliveries give at least 150 money",
		total_3_deliveries >= 150,
		"got %d" % total_3_deliveries)


func _test_rent_with_time() -> void:
	_section("Rent with Time System")

	var rent := EconomyManager.get_weekly_rent()
	_check("weekly rent = 250", rent == 250, "got %d" % rent)

	# Rent should be payable with delivery income
	# 3 delivery points * 50 = 150 per delivery run
	# Need ~2 delivery runs per week to cover rent
	var income_per_delivery := 3 * EconomyManager.get_delivery_reward(1)
	_check("rent < 2 deliveries income",
		rent < income_per_delivery * 2,
		"rent=%d, 2 deliveries=%d" % [rent, income_per_delivery * 2])


# --- Save/Load ---

func _test_save_load_data() -> void:
	_section("Save/Load Data")

	# TimeManager save/load
	GameState.current_day = 5
	TimeManager.is_daytime = false
	var time_save := TimeManager.get_save_data()
	_check("time save has current_day", time_save.has("current_day"))
	_check("time save current_day = 5", int(time_save["current_day"]) == 5)
	_check("time save is_daytime = false", bool(time_save["is_daytime"]) == false)

	GameState.current_day = 1
	TimeManager.is_daytime = true
	TimeManager.load_save_data(time_save)
	_check("time loaded day = 5", GameState.current_day == 5)
	_check("time loaded is_daytime = false", not TimeManager.is_daytime)

	# Reset
	GameState.current_day = 1
	TimeManager.is_daytime = true

	# MissionManager save/load
	MissionManager.load_save_data({})
	MissionManager.start_mission("mission_tutorial")
	MissionManager.complete_objective("mission_tutorial", 0)

	var mission_save := MissionManager.get_save_data()
	_check("mission save has mission_states", mission_save.has("mission_states"))
	_check("mission save has objective_status", mission_save.has("objective_status"))
	_check("mission save has current_mission_id", mission_save.has("current_mission_id"))

	MissionManager.load_save_data({})
	_check("mission reset after load empty",
		MissionManager.get_active_mission_id() == "")

	MissionManager.load_save_data(mission_save)
	_check("mission restored after load",
		MissionManager.get_active_mission_id() == "mission_tutorial",
		"active = '%s'" % MissionManager.get_active_mission_id())

	MissionManager.load_save_data({})
