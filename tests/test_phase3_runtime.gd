extends Node
## Phase 3 — Runtime Automated Tests
## Tests SkillManager, EconomyManager rent, UI wiring, stat integration.
##
## Run: godot --headless --path . --scene tests/TestPhase3Runtime.tscn

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 3 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_skill_manager_exists()
	_test_skill_unlock_basic()
	_test_skill_requirements()
	_test_skill_modifiers_aggregate()
	_test_skill_modifiers_in_stats()
	_test_economy_rent_basic()
	_test_economy_rent_with_skill()
	_test_economy_delivery_reward()
	_test_economy_money_drop_bonus()
	_test_skill_points_deduction()
	_test_cannot_unlock_without_sp()
	_test_cannot_unlock_twice()
	_test_available_skills_query()

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


# --- Test Helpers ---

func _reset_player() -> void:
	PlayerManager.reset_player(1)
	SkillManager.invalidate_cache(1)


# --- Tests ---

func _test_skill_manager_exists() -> void:
	_section("SkillManager Existence")
	_check("SkillManager singleton exists", SkillManager != null)
	_check("SkillManager has unlock_skill", SkillManager.has_method("unlock_skill"))
	_check("SkillManager has can_unlock_skill", SkillManager.has_method("can_unlock_skill"))
	_check("SkillManager has is_skill_unlocked", SkillManager.has_method("is_skill_unlocked"))
	_check("SkillManager has get_skill_modifiers", SkillManager.has_method("get_skill_modifiers"))


func _test_skill_unlock_basic() -> void:
	_section("Skill Unlock — Basic")
	_reset_player()

	# Give player a skill point
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 1
	PlayerManager.load_save_data(1, data)

	_check("player has 1 SP", PlayerManager.get_skill_points(1) == 1)

	# combat_damage_1 has no requirements, should be unlockable
	var can := SkillManager.can_unlock_skill(1, "combat_damage_1")
	_check("can unlock combat_damage_1 with 1 SP", can)

	var result := SkillManager.unlock_skill(1, "combat_damage_1")
	_check("unlock_skill returns true", result)
	_check("skill is now unlocked", SkillManager.is_skill_unlocked(1, "combat_damage_1"))
	_check("SP reduced to 0", PlayerManager.get_skill_points(1) == 0)


func _test_skill_requirements() -> void:
	_section("Skill Requirements")
	_reset_player()

	# combat_crit_1 requires combat_damage_1
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 3
	PlayerManager.load_save_data(1, data)

	# Should not be able to unlock combat_crit_1 without combat_damage_1
	_check("cannot unlock combat_crit_1 without prereq",
		not SkillManager.can_unlock_skill(1, "combat_crit_1"))

	# Unlock combat_damage_1 first
	SkillManager.unlock_skill(1, "combat_damage_1")

	# Now combat_crit_1 should be available
	_check("can unlock combat_crit_1 after prereq",
		SkillManager.can_unlock_skill(1, "combat_crit_1"))

	SkillManager.unlock_skill(1, "combat_crit_1")
	_check("combat_crit_1 is unlocked", SkillManager.is_skill_unlocked(1, "combat_crit_1"))
	_check("SP is now 1", PlayerManager.get_skill_points(1) == 1)


func _test_skill_modifiers_aggregate() -> void:
	_section("Skill Modifier Aggregation")
	_reset_player()

	# Unlock two combat skills
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 2
	PlayerManager.load_save_data(1, data)

	SkillManager.unlock_skill(1, "combat_damage_1")  # +5% damage
	SkillManager.unlock_skill(1, "combat_health_1")   # +10 flat health

	var mods: Dictionary = SkillManager.get_skill_modifiers(1)
	_check("damage_percent = 0.05",
		is_equal_approx(mods.get("damage_percent", 0.0), 0.05),
		"got %.4f" % mods.get("damage_percent", 0.0))
	_check("health_flat = 10",
		is_equal_approx(mods.get("health_flat", 0.0), 10.0),
		"got %.1f" % mods.get("health_flat", 0.0))


func _test_skill_modifiers_in_stats() -> void:
	_section("Skill Modifiers Affect Stats")
	_reset_player()

	var base_damage := PlayerManager.get_effective_stat(1, "damage")

	# Unlock damage skill
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 1
	PlayerManager.load_save_data(1, data)
	SkillManager.unlock_skill(1, "combat_damage_1")

	var new_damage := PlayerManager.get_effective_stat(1, "damage")
	# Should be base * 1.05
	var expected := base_damage * 1.05
	_check("damage increased after skill unlock",
		new_damage > base_damage,
		"was %.2f, now %.2f, expected %.2f" % [base_damage, new_damage, expected])
	_check("damage matches expected formula",
		is_equal_approx(new_damage, expected),
		"got %.2f, expected %.2f" % [new_damage, expected])


func _test_economy_rent_basic() -> void:
	_section("Economy — Rent")
	_reset_player()

	var base_rent := EconomyManager.get_weekly_rent_base()
	_check("base rent = 250", base_rent == 250, "got %d" % base_rent)

	# Give player enough money and pay rent
	EconomyManager.add_money(1, 500)
	var before := EconomyManager.get_money(1)
	var success := EconomyManager.pay_rent(1)
	var after := EconomyManager.get_money(1)

	_check("pay_rent succeeds with enough money", success)
	_check("money deducted correctly", after == before - base_rent,
		"before=%d, after=%d, rent=%d" % [before, after, base_rent])

	# Try to pay rent without enough money
	# Reset money state
	EconomyManager.load_save_data(1, 0)
	var fail := EconomyManager.pay_rent(1)
	_check("pay_rent fails without enough money", not fail)


func _test_economy_rent_with_skill() -> void:
	_section("Economy — Rent with Haggler Skill")
	_reset_player()

	# Unlock Haggler skill (rent_reduction 10%)
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 1
	PlayerManager.load_save_data(1, data)
	SkillManager.unlock_skill(1, "economy_rent_1")

	var effective_rent := EconomyManager.get_effective_rent(1)
	# 250 * (1 - 0.10) = 225
	_check("rent reduced to 225 with Haggler", effective_rent == 225,
		"got %d" % effective_rent)


func _test_economy_delivery_reward() -> void:
	_section("Economy — Delivery Reward")
	_reset_player()

	var base_reward := EconomyManager.get_delivery_reward(1)
	_check("base delivery reward = 50", base_reward == 50, "got %d" % base_reward)

	# Unlock Smooth Talker (+10% delivery reward)
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 1
	PlayerManager.load_save_data(1, data)
	SkillManager.unlock_skill(1, "economy_delivery_1")

	var boosted := EconomyManager.get_delivery_reward(1)
	_check("delivery reward = 55 with Smooth Talker", boosted == 55,
		"got %d" % boosted)


func _test_economy_money_drop_bonus() -> void:
	_section("Economy — Money Drop Bonus")
	_reset_player()

	var base_bonus := EconomyManager.get_money_drop_bonus(1)
	_check("no money drop bonus initially", is_equal_approx(base_bonus, 0.0),
		"got %.2f" % base_bonus)

	# Unlock Penny Pincher (requires economy_rent_1)
	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 2
	PlayerManager.load_save_data(1, data)
	SkillManager.unlock_skill(1, "economy_rent_1")
	SkillManager.unlock_skill(1, "economy_money_1")

	var boosted := EconomyManager.get_money_drop_bonus(1)
	_check("money drop bonus = 0.10 with Penny Pincher",
		is_equal_approx(boosted, 0.10),
		"got %.2f" % boosted)


func _test_skill_points_deduction() -> void:
	_section("Skill Points Deduction")
	_reset_player()

	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 3
	PlayerManager.load_save_data(1, data)

	_check("starts with 3 SP", PlayerManager.get_skill_points(1) == 3)
	SkillManager.unlock_skill(1, "combat_damage_1")
	_check("2 SP after first unlock", PlayerManager.get_skill_points(1) == 2)
	SkillManager.unlock_skill(1, "combat_health_1")
	_check("1 SP after second unlock", PlayerManager.get_skill_points(1) == 1)


func _test_cannot_unlock_without_sp() -> void:
	_section("Cannot Unlock Without Skill Points")
	_reset_player()

	# 0 SP by default
	_check("cannot unlock with 0 SP",
		not SkillManager.can_unlock_skill(1, "combat_damage_1"))

	var result := SkillManager.unlock_skill(1, "combat_damage_1")
	_check("unlock_skill returns false with 0 SP", not result)


func _test_cannot_unlock_twice() -> void:
	_section("Cannot Unlock Same Skill Twice")
	_reset_player()

	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 2
	PlayerManager.load_save_data(1, data)

	SkillManager.unlock_skill(1, "combat_damage_1")
	_check("cannot re-unlock combat_damage_1",
		not SkillManager.can_unlock_skill(1, "combat_damage_1"))

	var result := SkillManager.unlock_skill(1, "combat_damage_1")
	_check("unlock_skill returns false for duplicate", not result)
	_check("SP not wasted on duplicate", PlayerManager.get_skill_points(1) == 1)


func _test_available_skills_query() -> void:
	_section("Available Skills Query")
	_reset_player()

	var data := PlayerManager.get_save_data(1)
	data["skill_points"] = 4
	PlayerManager.load_save_data(1, data)

	# Initially, root skills (no requirements) should be available
	var available := SkillManager.get_available_skills(1)
	_check("root skills available initially", available.size() > 0,
		"got %d" % available.size())

	# All available should have no requirements or met requirements
	var all_avail_valid := true
	for skill in available:
		for req_id in skill.get("requirements", []):
			if not SkillManager.is_skill_unlocked(1, req_id):
				all_avail_valid = false
				break
	_check("all available skills have met requirements", all_avail_valid)

	# Count root skills (no requirements): should be 6 (2 per category)
	var root_count := 0
	for skill in DataManager.get_all_skills():
		if skill.get("requirements", []).size() == 0:
			root_count += 1
	_check("root skills count correct in available",
		available.size() == root_count,
		"available=%d, roots=%d" % [available.size(), root_count])
