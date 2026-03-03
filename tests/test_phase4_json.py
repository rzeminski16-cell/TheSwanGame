#!/usr/bin/env python3
"""
Phase 4 — Dungeon System Data Validation
Validates dungeon definitions, scaling formulas, room structure, enemy references.

Usage:
    python3 tests/test_phase4_json.py

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
dungeons_data = load_json("dungeons.json")
enemies_data = load_json("enemies.json")
loot_tables_data = load_json("loot_tables.json")

dungeons = {d["id"]: d for d in dungeons_data["dungeons"]}
enemies = {e["id"]: e for e in enemies_data["enemies"]}
loot_tables = {lt["id"]: lt for lt in loot_tables_data["loot_tables"]}


# ============================================================
print("\n" + "=" * 60)
print("  Phase 4 — Dungeon System Data Validation")
print("=" * 60)


# ============================================================
# SECTION 1: Dungeon Data Integrity
# ============================================================
print("\n" + "-" * 50)
print("  1. Dungeon Data Integrity")
print("-" * 50)

test("dungeons.json has dungeons array", "dungeons" in dungeons_data)
test("2 dungeons defined", len(dungeons) == 2, f"got {len(dungeons)}")

REQUIRED_DUNGEON_FIELDS = ["id", "display_name", "type", "base_difficulty", "rooms", "replayable"]

for did, dungeon in dungeons.items():
    for field in REQUIRED_DUNGEON_FIELDS:
        test(f"dungeon '{did}' has field '{field}'", field in dungeon)

# Specific dungeons exist
test("crab_cave exists", "crab_cave" in dungeons)
test("abandoned_tunnel exists", "abandoned_tunnel" in dungeons)

# Type validation
test("crab_cave is story type", dungeons["crab_cave"].get("type") == "story")
test("abandoned_tunnel is replayable type", dungeons["abandoned_tunnel"].get("type") == "replayable")

test("crab_cave not replayable", dungeons["crab_cave"].get("replayable") == False)
test("abandoned_tunnel is replayable", dungeons["abandoned_tunnel"].get("replayable") == True)


# ============================================================
# SECTION 2: Room Structure Validation
# ============================================================
print("\n" + "-" * 50)
print("  2. Room Structure Validation")
print("-" * 50)

# Crab Cave: 3 rooms (2 combat + 1 boss)
cc_rooms = dungeons["crab_cave"]["rooms"]
test("crab_cave has 3 rooms", len(cc_rooms) == 3, f"got {len(cc_rooms)}")
test("crab_cave room 1 is combat", cc_rooms[0].get("room_type") == "combat")
test("crab_cave room 2 is combat", cc_rooms[1].get("room_type") == "combat")
test("crab_cave room 3 is boss", cc_rooms[2].get("room_type") == "boss")

# Boss room has enemy_id
test("crab_cave boss room has enemy_id", "enemy_id" in cc_rooms[2])
test("crab_cave boss is crab_king", cc_rooms[2].get("enemy_id") == "crab_king")

# Crab Cave room 1: 5 melee_rat
cc_r1_groups = cc_rooms[0].get("enemy_groups", [])
test("crab_cave room 1 has enemy_groups", len(cc_r1_groups) > 0)
test("crab_cave room 1 has melee_rat", cc_r1_groups[0].get("enemy_id") == "melee_rat")
test("crab_cave room 1 has 5 rats", cc_r1_groups[0].get("count") == 5)

# Crab Cave room 2: 3 melee_rat + 2 ranged_crab
cc_r2_groups = cc_rooms[1].get("enemy_groups", [])
test("crab_cave room 2 has 2 groups", len(cc_r2_groups) == 2)
test("crab_cave room 2 group 1: 3 rats", cc_r2_groups[0].get("count") == 3)
test("crab_cave room 2 group 2: 2 crabs", cc_r2_groups[1].get("count") == 2)

# Abandoned Tunnel: 3 rooms (all combat, no boss)
at_rooms = dungeons["abandoned_tunnel"]["rooms"]
test("abandoned_tunnel has 3 rooms", len(at_rooms) == 3, f"got {len(at_rooms)}")
for i, room in enumerate(at_rooms):
    test(f"abandoned_tunnel room {i+1} is combat", room.get("room_type") == "combat")

# Count total enemies in abandoned tunnel
at_total = 0
for room in at_rooms:
    for group in room.get("enemy_groups", []):
        at_total += group.get("count", 0)
test("abandoned_tunnel has 14 base enemies", at_total == 14, f"got {at_total}")


# ============================================================
# SECTION 3: Enemy Reference Validation
# ============================================================
print("\n" + "-" * 50)
print("  3. Enemy Reference Validation")
print("-" * 50)

for did, dungeon in dungeons.items():
    for i, room in enumerate(dungeon.get("rooms", [])):
        if room.get("room_type") == "boss":
            eid = room.get("enemy_id", "")
            test(f"dungeon '{did}' boss '{eid}' exists in enemies.json",
                 eid in enemies, f"missing enemy '{eid}'")
        for group in room.get("enemy_groups", []):
            eid = group.get("enemy_id", "")
            test(f"dungeon '{did}' room {i+1} enemy '{eid}' exists",
                 eid in enemies, f"missing enemy '{eid}'")


# ============================================================
# SECTION 4: Scaling Formula Validation
# ============================================================
print("\n" + "-" * 50)
print("  4. Scaling Formula Validation")
print("-" * 50)

# Config values
dsc = config.get("dungeon_scaling_per_completion", 0)
ehs = config.get("enemy_health_scaling", 0)
eds = config.get("enemy_damage_scaling", 0)
ess = config.get("enemy_spawn_scaling", 0)
lqs = config.get("loot_quality_scaling", 0)
cap = config.get("difficulty_multiplier_cap", 3.0)

test("dungeon_scaling_per_completion = 0.15", approx(dsc, 0.15))
test("enemy_health_scaling = 0.12", approx(ehs, 0.12))
test("enemy_damage_scaling = 0.08", approx(eds, 0.08))
test("enemy_spawn_scaling = 0.10", approx(ess, 0.10))
test("loot_quality_scaling = 0.10", approx(lqs, 0.10))
test("difficulty_multiplier_cap = 3.0", approx(cap, 3.0))


def calc_scaling(completion_count):
    return {
        "difficulty_multiplier": min(1.0 + completion_count * dsc, cap),
        "enemy_health_multiplier": 1.0 + completion_count * ehs,
        "enemy_damage_multiplier": 1.0 + completion_count * eds,
        "enemy_count_multiplier": 1.0 + completion_count * ess,
        "loot_quality_multiplier": 1.0 + completion_count * lqs,
    }


# Completion 0 (first run)
s0 = calc_scaling(0)
test("comp 0: difficulty = 1.0", approx(s0["difficulty_multiplier"], 1.0))
test("comp 0: health = 1.0", approx(s0["enemy_health_multiplier"], 1.0))
test("comp 0: damage = 1.0", approx(s0["enemy_damage_multiplier"], 1.0))
test("comp 0: count = 1.0", approx(s0["enemy_count_multiplier"], 1.0))

# Completion 1
s1 = calc_scaling(1)
test("comp 1: difficulty = 1.15", approx(s1["difficulty_multiplier"], 1.15))
test("comp 1: health = 1.12", approx(s1["enemy_health_multiplier"], 1.12))
test("comp 1: damage = 1.08", approx(s1["enemy_damage_multiplier"], 1.08))
test("comp 1: count = 1.10", approx(s1["enemy_count_multiplier"], 1.10))
test("comp 1: loot quality = 1.10", approx(s1["loot_quality_multiplier"], 1.10))

# Completion 5
s5 = calc_scaling(5)
test("comp 5: difficulty = 1.75", approx(s5["difficulty_multiplier"], 1.75))
test("comp 5: health = 1.60", approx(s5["enemy_health_multiplier"], 1.60))

# Cap test (high completion count)
s20 = calc_scaling(20)
test("comp 20: difficulty capped at 3.0", approx(s20["difficulty_multiplier"], 3.0))


# ============================================================
# SECTION 5: Enemy Scaling Math
# ============================================================
print("\n" + "-" * 50)
print("  5. Enemy Scaling Math")
print("-" * 50)

# melee_rat at completion 0
rat = enemies["melee_rat"]["base_stats"]
test("rat base health = 50", rat["health"] == 50)
test("rat base damage = 8", rat["damage"] == 8)

# melee_rat at completion 3
s3 = calc_scaling(3)
scaled_rat_hp = rat["health"] * s3["enemy_health_multiplier"]
scaled_rat_dmg = rat["damage"] * s3["enemy_damage_multiplier"]
test("rat health at comp 3 = 68.0", approx(scaled_rat_hp, 68.0),
     f"got {scaled_rat_hp}")
test("rat damage at comp 3 = 9.92", approx(scaled_rat_dmg, 9.92),
     f"got {scaled_rat_dmg}")

# crab_king at completion 0
boss = enemies["crab_king"]["base_stats"]
test("boss base health = 500", boss["health"] == 500)
test("boss base damage = 20", boss["damage"] == 20)

# Enemy count scaling at completion 2
s2 = calc_scaling(2)
# 5 rats * 1.20 = 6 (rounded)
scaled_count = round(5 * s2["enemy_count_multiplier"])
test("5 rats at comp 2 = 6 enemies", scaled_count == 6, f"got {scaled_count}")


# ============================================================
# SECTION 6: Loot Table References
# ============================================================
print("\n" + "-" * 50)
print("  6. Loot Table References")
print("-" * 50)

test("basic_dungeon_loot exists", "basic_dungeon_loot" in loot_tables)
test("boss_loot exists", "boss_loot" in loot_tables)

# Boss loot biased toward rare
boss_loot = loot_tables["boss_loot"]["drops"]
basic_loot = loot_tables["basic_dungeon_loot"]["drops"]

test("boss loot has drops", len(boss_loot) > 0)
test("basic loot has drops", len(basic_loot) > 0)

# Boss loot should have higher weight for rare items
boss_rare_weight = sum(d["weight"] for d in boss_loot
                       if d["item_id"] in ["blood_pendant", "golden_idol"])
basic_rare_weight = sum(d["weight"] for d in basic_loot
                        if d["item_id"] in ["blood_pendant", "golden_idol"])
test("boss loot has higher rare weights than basic",
     boss_rare_weight > basic_rare_weight,
     f"boss={boss_rare_weight}, basic={basic_rare_weight}")

# All loot enemies reference valid loot tables
for eid, enemy in enemies.items():
    lt_id = enemy.get("loot_table_id", "")
    if lt_id:
        test(f"enemy '{eid}' loot table '{lt_id}' exists",
             lt_id in loot_tables)


# ============================================================
# SECTION 7: Death Penalty Config
# ============================================================
print("\n" + "-" * 50)
print("  7. Death Penalty Config")
print("-" * 50)

penalty = config.get("death_penalty", {})
test("death_penalty.money_loss_percent exists", "money_loss_percent" in penalty)
test("death_penalty.money_loss_percent = 0.10",
     approx(penalty.get("money_loss_percent", 0), 0.10))
test("death_penalty.item_loss_count exists", "item_loss_count" in penalty)
test("death_penalty.item_loss_count = 1", penalty.get("item_loss_count") == 1)

# Death penalty math
money = 500
loss = round(money * penalty.get("money_loss_percent", 0.10))
test("death penalty on 500 money = 50 lost", loss == 50, f"got {loss}")


# ============================================================
# SECTION 8: Demo Content Blueprint Compliance
# ============================================================
print("\n" + "-" * 50)
print("  8. Demo Content Blueprint Compliance")
print("-" * 50)

# Blueprint: 2 dungeons (1 story, 1 replayable)
test("2 dungeons total (blueprint)", len(dungeons) == 2)
story_count = sum(1 for d in dungeons.values() if d.get("type") == "story")
replay_count = sum(1 for d in dungeons.values() if d.get("type") == "replayable")
test("1 story dungeon", story_count == 1)
test("1 replayable dungeon", replay_count == 1)

# Crab Cave: 2 combat + 1 boss room
test("crab_cave has boss room", any(r.get("room_type") == "boss" for r in cc_rooms))

# Abandoned Tunnel: no boss
test("abandoned_tunnel has no boss",
     all(r.get("room_type") != "boss" for r in at_rooms))

# Max difficulty level in demo: 5 (cap at 3.0 multiplier)
test("difficulty cap at 3.0 (spec)", approx(cap, 3.0))

# Rarity scaling config
rarity_scaling = config.get("rarity_scaling_per_completion", {})
test("rarity rare bonus = 0.02",
     approx(rarity_scaling.get("rare_bonus", 0), 0.02))
test("rarity epic bonus = 0.01",
     approx(rarity_scaling.get("epic_bonus", 0), 0.01))
test("epic chance cap = 0.20",
     approx(config.get("epic_chance_cap", 0), 0.20))


# ============================================================
# Results
# ============================================================
print("\n" + "=" * 60)
print(f"  RESULTS: {passed} passed, {failed} failed")
print("=" * 60)

if errors:
    print("\nFailed tests:")
    for e in errors:
        print(f"  - {e}")

sys.exit(1 if failed > 0 else 0)
