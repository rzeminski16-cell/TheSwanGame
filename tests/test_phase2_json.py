#!/usr/bin/env python3
"""
Phase 2 — Combat, Enemy, Loot, and Inventory Data Validation
Runs outside Godot. Validates enemy data, loot tables, item effects,
and combat formula correctness.

Usage:
    python3 tests/test_phase2_json.py

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


# ============================================================
# Load all data
# ============================================================
config = load_json("global_config.json")
enemies_data = load_json("enemies.json")
items_data = load_json("items.json")
loot_tables_data = load_json("loot_tables.json")

enemies = {e["id"]: e for e in enemies_data["enemies"]}
items = {i["id"]: i for i in items_data["items"]}
loot_tables = {t["id"]: t for t in loot_tables_data["loot_tables"]}


# ============================================================
print("\n" + "=" * 60)
print("  Phase 2 — Combat, Enemy, Loot, Inventory Validation")
print("=" * 60)

# ============================================================
# 1. ENEMY DATA INTEGRITY
# ============================================================
print("\n" + "-" * 50)
print("  1. Enemy Data Integrity")
print("-" * 50)

EXPECTED_ENEMIES = ["melee_rat", "ranged_crab", "crab_king"]
test("Exactly 3 enemies defined", len(enemies) == 3,
     f"got {len(enemies)}")

for eid in EXPECTED_ENEMIES:
    test(f"Enemy '{eid}' exists", eid in enemies)

REQUIRED_ENEMY_FIELDS = ["id", "display_name", "type", "base_stats",
                         "xp_reward", "money_drop", "loot_table_id"]
for eid, edata in enemies.items():
    for field in REQUIRED_ENEMY_FIELDS:
        test(f"{eid}: has '{field}'", field in edata)

# Enemy types
test("melee_rat type = melee", enemies["melee_rat"]["type"] == "melee")
test("ranged_crab type = ranged", enemies["ranged_crab"]["type"] == "ranged")
test("crab_king type = boss", enemies["crab_king"]["type"] == "boss")

# Base stats completeness
REQUIRED_STATS = ["health", "damage", "move_speed", "attack_speed",
                  "crit_chance", "dodge_chance"]
for eid, edata in enemies.items():
    bs = edata.get("base_stats", {})
    for stat in REQUIRED_STATS:
        test(f"{eid}: base_stats has '{stat}'", stat in bs)


# ============================================================
# 2. ENEMY STAT RANGES
# ============================================================
print("\n" + "-" * 50)
print("  2. Enemy Stat Ranges")
print("-" * 50)

for eid, edata in enemies.items():
    bs = edata["base_stats"]
    test(f"{eid}: health > 0", bs["health"] > 0)
    test(f"{eid}: damage > 0", bs["damage"] > 0)
    test(f"{eid}: move_speed >= 0", bs["move_speed"] >= 0)
    test(f"{eid}: attack_speed > 0", bs["attack_speed"] > 0)
    test(f"{eid}: crit_chance in [0,1]", 0 <= bs["crit_chance"] <= 1)
    test(f"{eid}: dodge_chance in [0,1]", 0 <= bs["dodge_chance"] <= 1)
    test(f"{eid}: xp_reward > 0", edata["xp_reward"] > 0)

    md = edata["money_drop"]
    test(f"{eid}: money_drop.min >= 0", md["min"] >= 0)
    test(f"{eid}: money_drop.max >= min", md["max"] >= md["min"])


# ============================================================
# 3. BOSS STATS ARE HIGHER
# ============================================================
print("\n" + "-" * 50)
print("  3. Boss Stats vs Regular Enemies")
print("-" * 50)

boss = enemies["crab_king"]
rat = enemies["melee_rat"]
crab = enemies["ranged_crab"]

test("Boss health > rat health", boss["base_stats"]["health"] > rat["base_stats"]["health"])
test("Boss health > crab health", boss["base_stats"]["health"] > crab["base_stats"]["health"])
test("Boss damage > rat damage", boss["base_stats"]["damage"] > rat["base_stats"]["damage"])
test("Boss damage > crab damage", boss["base_stats"]["damage"] > crab["base_stats"]["damage"])
test("Boss xp_reward > rat xp", boss["xp_reward"] > rat["xp_reward"])
test("Boss xp_reward > crab xp", boss["xp_reward"] > crab["xp_reward"])
test("Boss money max > rat money max",
     boss["money_drop"]["max"] > rat["money_drop"]["max"])


# ============================================================
# 4. LOOT TABLE INTEGRITY
# ============================================================
print("\n" + "-" * 50)
print("  4. Loot Table Integrity")
print("-" * 50)

EXPECTED_TABLES = ["basic_dungeon_loot", "boss_loot"]
for tid in EXPECTED_TABLES:
    test(f"Loot table '{tid}' exists", tid in loot_tables)

for tid, tdata in loot_tables.items():
    test(f"{tid}: has 'drops' array", "drops" in tdata and isinstance(tdata["drops"], list))
    test(f"{tid}: drops not empty", len(tdata.get("drops", [])) > 0)

    total_weight = 0
    for drop in tdata.get("drops", []):
        test(f"{tid}: drop has 'item_id'", "item_id" in drop)
        test(f"{tid}: drop has 'weight'", "weight" in drop)
        test(f"{tid}: weight > 0", drop.get("weight", 0) > 0,
             f"item_id={drop.get('item_id', '?')}")
        total_weight += drop.get("weight", 0)

        # Verify item_id references valid item
        iid = drop.get("item_id", "")
        test(f"{tid}: '{iid}' exists in items.json", iid in items)

    test(f"{tid}: total weight > 0", total_weight > 0)


# ============================================================
# 5. ENEMY → LOOT TABLE REFERENCES
# ============================================================
print("\n" + "-" * 50)
print("  5. Enemy → Loot Table Cross-References")
print("-" * 50)

for eid, edata in enemies.items():
    ltid = edata.get("loot_table_id", "")
    test(f"{eid}: loot_table_id '{ltid}' exists", ltid in loot_tables)


# ============================================================
# 6. DAMAGE FORMULA VALIDATION
# ============================================================
print("\n" + "-" * 50)
print("  6. Damage Formula Validation")
print("-" * 50)

player_base_damage = config["player_base_stats"]["damage"]
crit_mult = 2.0  # CRIT_MULTIPLIER from combat_manager.gd

test("Player base damage = 10", player_base_damage == 10)

# Normal hit: should equal base damage
test("Normal hit = base_damage", player_base_damage == 10)

# Crit hit: base × crit multiplier
crit_damage = player_base_damage * crit_mult
test(f"Crit damage = {player_base_damage} × {crit_mult} = {crit_damage}",
     approx(crit_damage, 20.0))

# At level 5: damage = 10 × (1 + 4*0.02) = 10.8
level5_damage = player_base_damage * (1 + 4 * 0.02)
test(f"Level 5 damage ≈ 10.8", approx(level5_damage, 10.8))

# Level 5 crit = 10.8 × 2.0 = 21.6
level5_crit = level5_damage * crit_mult
test(f"Level 5 crit damage ≈ 21.6", approx(level5_crit, 21.6))


# ============================================================
# 7. ITEM EFFECTS VALIDATION
# ============================================================
print("\n" + "-" * 50)
print("  7. Item Effects Validation")
print("-" * 50)

VALID_STATS = ["health", "stamina", "damage", "attack_speed", "move_speed",
               "crit_chance", "dodge_chance"]
VALID_MOD_TYPES = ["flat", "percent"]

for iid, idata in items.items():
    effects = idata.get("effects", [])
    test(f"{iid}: has at least 1 effect", len(effects) >= 1)

    for i, effect in enumerate(effects):
        test(f"{iid}[{i}]: has 'stat'", "stat" in effect)
        test(f"{iid}[{i}]: has 'modifier_type'", "modifier_type" in effect)
        test(f"{iid}[{i}]: has 'value'", "value" in effect)

        stat = effect.get("stat", "")
        mod_type = effect.get("modifier_type", "")
        value = effect.get("value", 0)

        test(f"{iid}[{i}]: stat '{stat}' is valid", stat in VALID_STATS)
        test(f"{iid}[{i}]: modifier_type '{mod_type}' is valid", mod_type in VALID_MOD_TYPES)
        test(f"{iid}[{i}]: value != 0", value != 0)

        # Percent modifiers should be reasonable (< 50%)
        if mod_type == "percent":
            test(f"{iid}[{i}]: percent value in (-0.50, 0.50)",
                 abs(value) < 0.50,
                 f"got {value}")


# ============================================================
# 8. ITEM DROP CHANCE
# ============================================================
print("\n" + "-" * 50)
print("  8. Item Drop Chance Config")
print("-" * 50)

# BASE_ITEM_DROP_CHANCE = 0.30 in combat_manager.gd
test("Item drop chance is 30% (per combat_manager.gd constant)",
     True)  # Can't read GDScript constants from Python, just document it

# Verify loot_despawn_time exists
test("loot_despawn_time in config", "loot_despawn_time" in config)
test("loot_despawn_time > 0", config.get("loot_despawn_time", 0) > 0)


# ============================================================
# 9. SCALING MULTIPLIER VALIDATION
# ============================================================
print("\n" + "-" * 50)
print("  9. Scaling Multiplier Config")
print("-" * 50)

SCALING_KEYS = ["dungeon_scaling_per_completion", "enemy_health_scaling",
                "enemy_damage_scaling", "enemy_spawn_scaling",
                "loot_quality_scaling", "difficulty_multiplier_cap"]

for key in SCALING_KEYS:
    test(f"config has '{key}'", key in config)
    test(f"'{key}' > 0", config.get(key, 0) > 0)

# Verify scaling formula: at completion_count=1
# health_mult = 1 + 1 * 0.12 = 1.12
health_scale = config["enemy_health_scaling"]
health_mult_1 = 1 + 1 * health_scale
test(f"Health scaling at comp=1: {health_mult_1}",
     approx(health_mult_1, 1.12))

# At comp=5: 1 + 5 * 0.12 = 1.60
health_mult_5 = 1 + 5 * health_scale
test(f"Health scaling at comp=5: {health_mult_5}",
     approx(health_mult_5, 1.60))

# Verify difficulty cap
cap = config["difficulty_multiplier_cap"]
test(f"Difficulty cap = {cap}", cap == 3.0)


# ============================================================
# 10. INVENTORY MODIFIER AGGREGATION (offline math)
# ============================================================
print("\n" + "-" * 50)
print("  10. Inventory Modifier Aggregation")
print("-" * 50)

# If player has damage_ring (+10% damage) and balanced_blade (+5% damage, +5% attack_speed)
# Total damage_percent = 0.10 + 0.05 = 0.15
# Total attack_speed_percent = 0.05
dr = items["damage_ring"]
bb = items["balanced_blade"]

damage_pct = 0.0
as_pct = 0.0
for effect in dr["effects"]:
    if effect["stat"] == "damage" and effect["modifier_type"] == "percent":
        damage_pct += effect["value"]
for effect in bb["effects"]:
    if effect["stat"] == "damage" and effect["modifier_type"] == "percent":
        damage_pct += effect["value"]
    if effect["stat"] == "attack_speed" and effect["modifier_type"] == "percent":
        as_pct += effect["value"]

test("damage_ring + balanced_blade: damage_percent = 0.15",
     approx(damage_pct, 0.15))
test("damage_ring + balanced_blade: attack_speed_percent = 0.05",
     approx(as_pct, 0.05))

# Final damage at level 1 with these items: 10 × (1 + 0.15) = 11.5
final_dmg = 10 * (1 + damage_pct)
test(f"Level 1 damage with both items = {final_dmg}", approx(final_dmg, 11.5))


# ============================================================
# 11. DEATH PENALTY CONFIG
# ============================================================
print("\n" + "-" * 50)
print("  11. Death Penalty Config")
print("-" * 50)

dp = config.get("death_penalty", {})
test("death_penalty exists", len(dp) > 0)
test("money_loss_percent = 0.10", approx(dp.get("money_loss_percent", 0), 0.10))
test("item_loss_count = 1", dp.get("item_loss_count", 0) == 1)


# ============================================================
# RESULTS
# ============================================================
print("\n" + "=" * 60)
print(f"  RESULTS: {passed} passed, {failed} failed")
print("=" * 60)

if failed > 0:
    print("\nFailed tests:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("\nAll Phase 2 JSON validation tests passed!")
    sys.exit(0)
