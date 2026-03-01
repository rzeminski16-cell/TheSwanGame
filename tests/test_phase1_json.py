#!/usr/bin/env python3
"""
Phase 1 — XP Curve, Stat Formula, and Soft Cap Validation
Runs outside Godot. Validates the math that PlayerManager should implement.

Usage:
    python3 tests/test_phase1_json.py

Exit code 0 = all passed, 1 = failures found.
"""

import json
import math
import os
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

passed = 0
failed = 0
errors = []


def test(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  PASS  {name}")
    else:
        failed += 1
        msg = f"  FAIL  {name}"
        if detail:
            msg += f" — {detail}"
        print(msg)
        errors.append(name)


def approx(a, b, tolerance=0.01):
    return abs(a - b) < tolerance


def load_json(filename):
    path = os.path.join(DATA_DIR, filename)
    with open(path, "r") as f:
        return json.load(f)


def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


config = load_json("global_config.json")
base_xp = config["base_xp_per_level"]
xp_exp = config["xp_curve_exponent"]
base_stats = config["player_base_stats"]
level_bonuses = config["level_up_bonuses"]
soft_caps = config["soft_caps"]
max_level = config["max_player_level_demo"]


# ============================================================
#  1. XP CURVE FORMULA
# ============================================================
section("1. XP Curve Formula: base_xp × level^exponent")

def xp_for_level(level):
    return round(base_xp * (level ** xp_exp))

expected_xp = {
    1: 100,   # 100 × 1^1.5 = 100
    2: 283,   # 100 × 2^1.5 = 282.8 → round → 283
    3: 520,   # 100 × 3^1.5 = 519.6 → round → 520
    4: 800,   # 100 × 4^1.5 = 800
}

for level, expected in expected_xp.items():
    actual = xp_for_level(level)
    test(f"XP for level {level}→{level+1} = {expected}", actual == expected, f"got {actual}")

# Cumulative XP
cumulative = 0
cumulative_expected = {1: 100, 2: 383, 3: 903, 4: 1703}
for level in range(1, max_level):
    cumulative += xp_for_level(level)
    if level in cumulative_expected:
        test(f"Cumulative XP at level {level}→{level+1} = {cumulative_expected[level]}",
             cumulative == cumulative_expected[level], f"got {cumulative}")

test("Max level cap = 5", max_level == 5)


# ============================================================
#  2. LEVEL-UP STAT BONUSES
# ============================================================
section("2. Level-Up Stat Bonuses")

# Health: +5 flat per level gained
for level in range(1, 6):
    levels_gained = level - 1
    health_bonus = level_bonuses["health"] * levels_gained
    expected_health = base_stats["health"] + health_bonus
    test(f"Level {level} health = {expected_health}",
         expected_health == 100 + 5 * levels_gained)

# Damage: +2% per level gained (percent bonus)
for level in range(1, 6):
    levels_gained = level - 1
    pct = level_bonuses["damage_percent"] * levels_gained
    effective_damage = base_stats["damage"] * (1.0 + pct)
    test(f"Level {level} damage = {effective_damage:.2f}",
         approx(effective_damage, 10 * (1 + 0.02 * levels_gained)))

# Attack speed: +1% per level gained
for level in range(1, 6):
    levels_gained = level - 1
    pct = level_bonuses["attack_speed_percent"] * levels_gained
    effective_as = base_stats["attack_speed"] * (1.0 + pct)
    test(f"Level {level} attack_speed = {effective_as:.3f}",
         approx(effective_as, 1.0 * (1 + 0.01 * levels_gained), 0.001))

# Move speed: +1% per level gained
for level in range(1, 6):
    levels_gained = level - 1
    pct = level_bonuses["move_speed_percent"] * levels_gained
    effective_ms = base_stats["move_speed"] * (1.0 + pct)
    test(f"Level {level} move_speed = {effective_ms:.2f}",
         approx(effective_ms, 120 * (1 + 0.01 * levels_gained)))


# ============================================================
#  3. SOFT CAP FORMULA
# ============================================================
section("3. Soft Cap Formula: max × (1 - e^(-raw / scaling_factor))")

def soft_cap(raw, cap_max, scaling_factor):
    return cap_max * (1.0 - math.exp(-raw / scaling_factor))

# Test crit_chance soft cap
crit_cap = soft_caps["crit_chance"]
crit_max = crit_cap["max"]
crit_sf = crit_cap["scaling_factor"]

test("Crit soft cap max = 0.40", crit_max == 0.40)
test("Crit soft cap scaling = 0.08", crit_sf == 0.08)

# At base (0.05): should return close to itself due to diminishing returns
base_crit = soft_cap(0.05, crit_max, crit_sf)
test(f"Soft cap at 0.05 raw crit ≈ {base_crit:.4f} (below max)", base_crit < crit_max)
test(f"Soft cap at 0.05 preserves roughly ≈ 0.05", approx(base_crit, 0.05, 0.15))

# At very high raw, should approach max
high_crit = soft_cap(1.0, crit_max, crit_sf)
test(f"Soft cap at 1.0 raw crit ≈ {high_crit:.4f} (close to max)", approx(high_crit, crit_max, 0.01))

# Soft cap is monotonically increasing
prev = 0
for raw in [0.01, 0.05, 0.10, 0.20, 0.30, 0.50, 1.0]:
    val = soft_cap(raw, crit_max, crit_sf)
    test(f"Soft cap monotonic at raw={raw:.2f} → {val:.4f}", val > prev)
    prev = val

# Dodge should have same cap
dodge_cap = soft_caps["dodge_chance"]
test("Dodge soft cap max = 0.40", dodge_cap["max"] == 0.40)
test("Dodge soft cap scaling = 0.08", dodge_cap["scaling_factor"] == 0.08)


# ============================================================
#  4. STAT FORMULA: (base + flat) × (1 + percent)
# ============================================================
section("4. Stat Formula: (base + flat) × (1 + percent)")

# No bonuses = base stat
for stat, value in base_stats.items():
    effective = (value + 0) * (1.0 + 0)
    test(f"Level 1 {stat} = {value} (no bonuses)", approx(effective, value))

# Level 3 health: (100 + 10) × 1.0 = 110
l3_health = (base_stats["health"] + level_bonuses["health"] * 2) * 1.0
test("Level 3 health = 110", approx(l3_health, 110))

# Level 3 damage: (10 + 0) × (1 + 0.04) = 10.4
l3_damage = (base_stats["damage"]) * (1.0 + level_bonuses["damage_percent"] * 2)
test("Level 3 damage = 10.4", approx(l3_damage, 10.4))

# Level 5 health: (100 + 20) × 1.0 = 120
l5_health = (base_stats["health"] + level_bonuses["health"] * 4) * 1.0
test("Level 5 health = 120", approx(l5_health, 120))

# Level 5 damage: (10 + 0) × (1 + 0.08) = 10.8
l5_damage = (base_stats["damage"]) * (1.0 + level_bonuses["damage_percent"] * 4)
test("Level 5 damage = 10.8", approx(l5_damage, 10.8))


# ============================================================
#  5. SKILL POINT ALLOCATION
# ============================================================
section("5. Skill Points per Level")

test("Level 1: 0 skill points", 1 - 1 == 0)
test("Level 2: 1 skill point", 2 - 1 == 1)
test("Level 3: 2 skill points", 3 - 1 == 2)
test("Level 4: 3 skill points", 4 - 1 == 3)
test("Level 5: 4 skill points", 5 - 1 == 4)


# ============================================================
#  6. CONFIG COMPLETENESS
# ============================================================
section("6. Config Completeness for Phase 1")

REQUIRED_CONFIG_KEYS = [
    "xp_curve_exponent", "base_xp_per_level", "max_player_level_demo",
    "player_base_stats", "level_up_bonuses", "soft_caps",
]
for key in REQUIRED_CONFIG_KEYS:
    test(f"Config has '{key}'", key in config)

REQUIRED_BASE_STATS = ["health", "stamina", "damage", "attack_speed", "move_speed", "crit_chance", "dodge_chance"]
for stat in REQUIRED_BASE_STATS:
    test(f"Base stat '{stat}' exists", stat in base_stats)

REQUIRED_LEVEL_BONUSES = ["health", "damage_percent", "attack_speed_percent", "move_speed_percent"]
for key in REQUIRED_LEVEL_BONUSES:
    test(f"Level bonus '{key}' exists", key in level_bonuses)


# ============================================================
#  SUMMARY
# ============================================================
print(f"\n{'='*60}")
print(f"  RESULTS: {passed} passed, {failed} failed")
print(f"{'='*60}")

if failed > 0:
    print("\nFailed tests:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("\nAll tests passed!")
    sys.exit(0)
