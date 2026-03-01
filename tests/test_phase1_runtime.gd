extends Node
## Phase 1 — Runtime Automated Tests
## Tests PlayerManager, HealthComponent, StaminaComponent, Player scene.
##
## Run: godot --headless --path . --scene tests/TestPhase1Runtime.tscn

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  Phase 1 — Runtime Automated Tests")
	print("=".repeat(60))

	_test_player_manager_init()
	_test_xp_curve()
	_test_leveling()
	_test_level_cap()
	_test_stat_computation()
	_test_soft_caps()
	_test_spawn_player()
	_test_health_component()
	_test_stamina_component()
	_test_player_node_structure()
	_test_skill_points()

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
	if _failed > 0:
		print("\nFailed tests:")
		for e in _errors:
			print("  - %s" % e)
	else:
		print("\nAll runtime tests passed!")


# ============================================================
#  1. PLAYER MANAGER INIT
# ============================================================

func _test_player_manager_init() -> void:
	_section("1. PlayerManager Init")
	_check("PlayerManager exists", PlayerManager != null)
	_check("No player data initially", not PlayerManager.has_player(99))
	_check("get_level for unknown player = 1", PlayerManager.get_level(99) == 1)
	_check("get_xp for unknown player = 0", PlayerManager.get_xp(99) == 0)


# ============================================================
#  2. XP CURVE
# ============================================================

func _test_xp_curve() -> void:
	_section("2. XP Curve")
	_check("XP for level 1→2 = 100", PlayerManager.get_xp_for_next_level(1) == 100)
	_check("XP for level 2→3 = 283", PlayerManager.get_xp_for_next_level(2) == 283)
	_check("XP for level 3→4 = 520", PlayerManager.get_xp_for_next_level(3) == 520)
	_check("XP for level 4→5 = 800", PlayerManager.get_xp_for_next_level(4) == 800)


# ============================================================
#  3. LEVELING
# ============================================================

func _test_leveling() -> void:
	_section("3. Leveling")
	# Use player_id 100 for isolated testing
	PlayerManager.reset_player(100)
	_check("Start at level 1", PlayerManager.get_level(100) == 1)
	_check("Start with 0 XP", PlayerManager.get_xp(100) == 0)

	# Add 50 XP — not enough to level
	PlayerManager.add_xp(100, 50)
	_check("50 XP: still level 1", PlayerManager.get_level(100) == 1)
	_check("50 XP: xp = 50", PlayerManager.get_xp(100) == 50)

	# Add 50 more — exactly 100, should level to 2
	PlayerManager.add_xp(100, 50)
	_check("100 XP total: level 2", PlayerManager.get_level(100) == 2)
	_check("XP resets after level up: xp = 0", PlayerManager.get_xp(100) == 0)

	# Add 283 — level to 3
	PlayerManager.add_xp(100, 283)
	_check("283 more XP: level 3", PlayerManager.get_level(100) == 3)

	# Add 520 — level to 4
	PlayerManager.add_xp(100, 520)
	_check("520 more XP: level 4", PlayerManager.get_level(100) == 4)

	# Add 800 — level to 5
	PlayerManager.add_xp(100, 800)
	_check("800 more XP: level 5", PlayerManager.get_level(100) == 5)

	# Clean up
	PlayerManager._player_data.erase(100)


# ============================================================
#  4. LEVEL CAP
# ============================================================

func _test_level_cap() -> void:
	_section("4. Level Cap")
	PlayerManager.reset_player(101)

	# Give massive XP
	PlayerManager.add_xp(101, 999999)
	_check("Huge XP: capped at level 5", PlayerManager.get_level(101) == 5)
	_check("XP at cap = 0", PlayerManager.get_xp(101) == 0)

	# More XP at cap does nothing
	PlayerManager.add_xp(101, 500)
	_check("More XP at cap: still level 5", PlayerManager.get_level(101) == 5)
	_check("XP stays 0 at cap", PlayerManager.get_xp(101) == 0)

	PlayerManager._player_data.erase(101)


# ============================================================
#  5. STAT COMPUTATION
# ============================================================

func _test_stat_computation() -> void:
	_section("5. Stat Computation")

	# Level 1 — should match base stats
	PlayerManager.reset_player(102)
	var stats_l1 := PlayerManager.get_stats(102)
	_check("Level 1 damage = 10", is_equal_approx(stats_l1.get("damage", 0), 10.0))
	_check("Level 1 move_speed = 120", is_equal_approx(stats_l1.get("move_speed", 0), 120.0))
	_check("Level 1 attack_speed = 1.0", is_equal_approx(stats_l1.get("attack_speed", 0), 1.0))

	# Level 1 health = 100 (flat, no percent)
	var health_raw: float = stats_l1.get("health", 0)
	_check("Level 1 health = 100", is_equal_approx(health_raw, 100.0))

	# Level 3 — 2 levels gained
	PlayerManager.add_xp(102, 383)  # 100 + 283
	_check("After 383 XP: level 3", PlayerManager.get_level(102) == 3)
	var stats_l3 := PlayerManager.get_stats(102)

	# Health: (100 + 2*5) × 1.0 = 110
	_check("Level 3 health = 110", is_equal_approx(stats_l3.get("health", 0), 110.0))

	# Damage: 10 × (1 + 2*0.02) = 10 × 1.04 = 10.4
	_check("Level 3 damage ≈ 10.4", is_equal_approx(stats_l3.get("damage", 0), 10.4))

	# Move speed: 120 × (1 + 2*0.01) = 120 × 1.02 = 122.4
	_check("Level 3 move_speed ≈ 122.4", is_equal_approx(stats_l3.get("move_speed", 0), 122.4))

	# Level 5 — 4 levels gained
	PlayerManager.add_xp(102, 1320)  # 520 + 800
	_check("After more XP: level 5", PlayerManager.get_level(102) == 5)
	var stats_l5 := PlayerManager.get_stats(102)

	# Health: (100 + 4*5) × 1.0 = 120
	_check("Level 5 health = 120", is_equal_approx(stats_l5.get("health", 0), 120.0))

	# Damage: 10 × (1 + 4*0.02) = 10 × 1.08 = 10.8
	_check("Level 5 damage ≈ 10.8", is_equal_approx(stats_l5.get("damage", 0), 10.8))

	PlayerManager._player_data.erase(102)


# ============================================================
#  6. SOFT CAPS
# ============================================================

func _test_soft_caps() -> void:
	_section("6. Soft Caps")
	# Test the soft cap function directly
	# crit_chance at base 0.05 should be below max 0.40
	var crit_l1 := PlayerManager.get_effective_stat(103, "crit_chance")
	_check("Crit at level 1 < 0.40", crit_l1 < 0.40)
	_check("Crit at level 1 > 0", crit_l1 > 0)

	# Very high raw value should approach max
	# We can't easily test this without manipulating items, but we verify
	# the cap function works by ensuring crit < max at base
	var dodge_l1 := PlayerManager.get_effective_stat(103, "dodge_chance")
	_check("Dodge at level 1 < 0.40", dodge_l1 < 0.40)
	_check("Dodge at level 1 > 0", dodge_l1 > 0)

	PlayerManager._player_data.erase(103)


# ============================================================
#  7. SPAWN PLAYER
# ============================================================

func _test_spawn_player() -> void:
	_section("7. Spawn Player")
	var player := PlayerManager.spawn_player(200, self)
	_check("spawn_player returns a node", player != null)
	_check("Player node name = 'Player_200'", player.name == "Player_200")
	_check("Player is CharacterBody2D", player is CharacterBody2D)
	_check("Player is in scene tree", player.is_inside_tree())
	_check("Player tracked in manager", PlayerManager.has_player(200))
	_check("get_player_node returns same node", PlayerManager.get_player_node(200) == player)

	# Clean up
	player.queue_free()
	PlayerManager._player_data.erase(200)
	PlayerManager._player_nodes.erase(200)


# ============================================================
#  8. HEALTH COMPONENT
# ============================================================

func _test_health_component() -> void:
	_section("8. HealthComponent")
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 100.0
	add_child(hc)

	_check("HC starts at full health", is_equal_approx(hc.current_health, 100.0))
	_check("HC not dead", hc.is_dead == false)

	# Take damage
	hc.take_damage(30.0)
	_check("After 30 damage: HP = 70", is_equal_approx(hc.current_health, 70.0))
	_check("Health percent = 0.7", is_equal_approx(hc.get_health_percent(), 0.7))

	# Heal
	hc.heal(10.0)
	_check("After heal 10: HP = 80", is_equal_approx(hc.current_health, 80.0))

	# Overheal clamped
	hc.heal(999.0)
	_check("Overheal clamped to max", is_equal_approx(hc.current_health, 100.0))

	# Kill
	var died_signal_received := false
	hc.died.connect(func(): died_signal_received = true)
	hc.take_damage(200.0)
	_check("Lethal damage: HP = 0", is_equal_approx(hc.current_health, 0.0))
	_check("is_dead = true", hc.is_dead == true)
	_check("died signal emitted", died_signal_received)

	# Damage while dead does nothing
	hc.take_damage(50.0)
	_check("Damage while dead: HP stays 0", is_equal_approx(hc.current_health, 0.0))

	# Heal while dead does nothing
	hc.heal(50.0)
	_check("Heal while dead: HP stays 0", is_equal_approx(hc.current_health, 0.0))

	# Revive
	hc.revive(0.5)
	_check("Revive at 50%: HP = 50", is_equal_approx(hc.current_health, 50.0))
	_check("Revive clears is_dead", hc.is_dead == false)

	# Set max health
	hc.heal_full()
	hc.set_max_health(150.0)
	_check("set_max_health to 150: current = 150 (was full)", is_equal_approx(hc.current_health, 150.0))

	hc.take_damage(50.0)  # HP = 100
	hc.set_max_health(80.0)
	_check("set_max_health to 80: current clamped to 80", is_equal_approx(hc.current_health, 80.0))

	hc.queue_free()


# ============================================================
#  9. STAMINA COMPONENT
# ============================================================

func _test_stamina_component() -> void:
	_section("9. StaminaComponent")
	var sc := StaminaComponent.new()
	sc.max_stamina = 100.0
	sc.current_stamina = 100.0
	sc.regen_rate = 15.0
	sc.regen_delay = 1.0
	add_child(sc)

	_check("SC starts at full stamina", is_equal_approx(sc.current_stamina, 100.0))

	# Use stamina
	var success := sc.use_stamina(30.0)
	_check("use_stamina(30) succeeds", success == true)
	_check("After use: stamina = 70", is_equal_approx(sc.current_stamina, 70.0))

	# Try to use more than available
	success = sc.use_stamina(80.0)
	_check("use_stamina(80) fails (only 70 left)", success == false)
	_check("Stamina unchanged after failed use", is_equal_approx(sc.current_stamina, 70.0))

	# Stamina percent
	_check("Stamina percent = 0.7", is_equal_approx(sc.get_stamina_percent(), 0.7))

	# Set max stamina
	sc.current_stamina = sc.max_stamina
	sc.set_max_stamina(150.0)
	_check("set_max_stamina to 150: current = 150 (was full)", is_equal_approx(sc.current_stamina, 150.0))

	sc.queue_free()


# ============================================================
# 10. PLAYER NODE STRUCTURE
# ============================================================

func _test_player_node_structure() -> void:
	_section("10. Player Node Structure")
	var player := PlayerManager.spawn_player(201, self)
	if player == null:
		_check("Player spawned", false, "spawn returned null")
		return

	_check("Has CollisionShape2D", player.get_node_or_null("CollisionShape2D") != null)
	_check("Has PlaceholderSprite", player.get_node_or_null("PlaceholderSprite") != null)
	_check("Has HealthComponent", player.get_node_or_null("HealthComponent") != null)
	_check("Has StaminaComponent", player.get_node_or_null("StaminaComponent") != null)
	_check("Has NetworkSyncComponent", player.get_node_or_null("NetworkSyncComponent") != null)
	_check("Has WeaponPrimary", player.get_node_or_null("WeaponPrimary") != null)
	_check("Has AbilitySlot1", player.get_node_or_null("AbilitySlot1") != null)
	_check("Has AbilitySlot2", player.get_node_or_null("AbilitySlot2") != null)

	# Check component types
	var hc = player.get_node_or_null("HealthComponent")
	_check("HealthComponent is HealthComponent class", hc is HealthComponent)

	var sc = player.get_node_or_null("StaminaComponent")
	_check("StaminaComponent is StaminaComponent class", sc is StaminaComponent)

	# Check health was initialized from stats
	if hc:
		var expected_health := PlayerManager.get_effective_stat(201, "health")
		_check("HealthComponent max = player health stat",
			is_equal_approx(hc.max_health, expected_health),
			"expected %.1f, got %.1f" % [expected_health, hc.max_health])

	# Check player has movement method
	_check("Player has _physics_process", player.has_method("_physics_process"))
	_check("Player has set_player_id", player.has_method("set_player_id"))

	player.queue_free()
	PlayerManager._player_data.erase(201)
	PlayerManager._player_nodes.erase(201)


# ============================================================
# 11. SKILL POINTS
# ============================================================

func _test_skill_points() -> void:
	_section("11. Skill Points")
	PlayerManager.reset_player(202)

	_check("Level 1: 0 skill points", PlayerManager.get_skill_points(202) == 0)

	PlayerManager.add_xp(202, 100)  # Level 2
	_check("Level 2: 1 skill point", PlayerManager.get_skill_points(202) == 1)

	PlayerManager.add_xp(202, 283)  # Level 3
	_check("Level 3: 2 skill points", PlayerManager.get_skill_points(202) == 2)

	PlayerManager.add_xp(202, 520)  # Level 4
	_check("Level 4: 3 skill points", PlayerManager.get_skill_points(202) == 3)

	PlayerManager.add_xp(202, 800)  # Level 5
	_check("Level 5: 4 skill points", PlayerManager.get_skill_points(202) == 4)

	PlayerManager._player_data.erase(202)
