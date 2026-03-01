#!/usr/bin/env python3
"""
Phase 0 — JSON Data Validation Tests
Runs outside Godot. Validates all JSON files in data/ for structure,
required fields, value correctness, and cross-reference integrity.

Usage:
    python3 tests/test_phase0_json.py

Exit code 0 = all passed, 1 = failures found.
"""

import json
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


def load_json(filename):
    path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(path):
        return None
    with open(path, "r") as f:
        return json.load(f)


def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


# ============================================================
#  1. FILE EXISTENCE
# ============================================================
section("1. File Existence")

REQUIRED_FILES = [
    "global_config.json",
    "enemies.json",
    "items.json",
    "skills.json",
    "loot_tables.json",
    "dungeons.json",
    "missions.json",
    "delivery_jobs.json",
]

for f in REQUIRED_FILES:
    path = os.path.join(DATA_DIR, f)
    test(f"File exists: {f}", os.path.exists(path))

# Load all data
config = load_json("global_config.json") or {}
enemies_data = load_json("enemies.json") or {}
items_data = load_json("items.json") or {}
skills_data = load_json("skills.json") or {}
loot_data = load_json("loot_tables.json") or {}
dungeons_data = load_json("dungeons.json") or {}
missions_data = load_json("missions.json") or {}
delivery_data = load_json("delivery_jobs.json") or {}

enemies = {e["id"]: e for e in enemies_data.get("enemies", [])}
items = {i["id"]: i for i in items_data.get("items", [])}
skills = {s["id"]: s for s in skills_data.get("skills", [])}
loot_tables = {t["id"]: t for t in loot_data.get("loot_tables", [])}
dungeons = {d["id"]: d for d in dungeons_data.get("dungeons", [])}
missions = {m["id"]: m for m in missions_data.get("missions", [])}
delivery_jobs = delivery_data.get("delivery_jobs", [])


# ============================================================
#  2. STRUCTURE VALIDATION
# ============================================================
section("2. Structure Validation")

test("global_config.json is a dict", isinstance(config, dict))
test("enemies.json has 'enemies' array", isinstance(enemies_data.get("enemies"), list))
test("items.json has 'items' array", isinstance(items_data.get("items"), list))
test("skills.json has 'skills' array", isinstance(skills_data.get("skills"), list))
test("loot_tables.json has 'loot_tables' array", isinstance(loot_data.get("loot_tables"), list))
test("dungeons.json has 'dungeons' array", isinstance(dungeons_data.get("dungeons"), list))
test("missions.json has 'missions' array", isinstance(missions_data.get("missions"), list))
test("delivery_jobs.json has 'delivery_jobs' array", isinstance(delivery_data.get("delivery_jobs"), list))


# ============================================================
#  3. COUNT VALIDATION
# ============================================================
section("3. Count Validation")

test("Exactly 3 enemies", len(enemies) == 3, f"got {len(enemies)}")
test("Exactly 10 items", len(items) == 10, f"got {len(items)}")
test("Exactly 15 skills", len(skills) == 15, f"got {len(skills)}")
test("Exactly 2 loot tables", len(loot_tables) == 2, f"got {len(loot_tables)}")
test("Exactly 2 dungeons", len(dungeons) == 2, f"got {len(dungeons)}")
test("Exactly 5 missions", len(missions) == 5, f"got {len(missions)}")
test("Exactly 1 delivery job", len(delivery_jobs) == 1, f"got {len(delivery_jobs)}")

# Skill category counts
combat_skills = [s for s in skills.values() if s.get("category") == "combat"]
economy_skills = [s for s in skills.values() if s.get("category") == "economy"]
personality_skills = [s for s in skills.values() if s.get("category") == "personality"]
test("5 combat skills", len(combat_skills) == 5, f"got {len(combat_skills)}")
test("5 economy skills", len(economy_skills) == 5, f"got {len(economy_skills)}")
test("5 personality skills", len(personality_skills) == 5, f"got {len(personality_skills)}")


# ============================================================
#  4. GLOBAL CONFIG VALUES (from ECONOMY_AND_SCALING_SPEC / BLUEPRINT)
# ============================================================
section("4. Global Config Value Verification")

test("xp_curve_exponent = 1.5", config.get("xp_curve_exponent") == 1.5)
test("base_xp_per_level = 100", config.get("base_xp_per_level") == 100)
test("dungeon_scaling_per_completion = 0.15", config.get("dungeon_scaling_per_completion") == 0.15)
test("enemy_health_scaling = 0.12", config.get("enemy_health_scaling") == 0.12)
test("enemy_damage_scaling = 0.08", config.get("enemy_damage_scaling") == 0.08)
test("enemy_spawn_scaling = 0.10", config.get("enemy_spawn_scaling") == 0.10)
test("loot_quality_scaling = 0.10", config.get("loot_quality_scaling") == 0.10)
test("base_delivery_reward = 50", config.get("base_delivery_reward") == 50)
test("base_weekly_rent = 250", config.get("base_weekly_rent") == 250)
test("max_player_level_demo = 5", config.get("max_player_level_demo") == 5)

# Player base stats
pbs = config.get("player_base_stats", {})
test("Player base health = 100", pbs.get("health") == 100)
test("Player base stamina = 100", pbs.get("stamina") == 100)
test("Player base damage = 10", pbs.get("damage") == 10)
test("Player base attack_speed = 1.0", pbs.get("attack_speed") == 1.0)
test("Player base move_speed = 120", pbs.get("move_speed") == 120)
test("Player base crit_chance = 0.05", pbs.get("crit_chance") == 0.05)
test("Player base dodge_chance = 0.05", pbs.get("dodge_chance") == 0.05)

# Death penalty
dp = config.get("death_penalty", {})
test("Death penalty money_loss_percent exists", "money_loss_percent" in dp)
test("Death penalty item_loss_count exists", "item_loss_count" in dp)

# Soft caps
sc = config.get("soft_caps", {})
test("Soft cap for crit_chance exists", "crit_chance" in sc)
test("Soft cap for dodge_chance exists", "dodge_chance" in sc)


# ============================================================
#  5. ENEMY VALUE VERIFICATION
# ============================================================
section("5. Enemy Value Verification")

# Cave Rat
rat = enemies.get("melee_rat", {})
test("Cave Rat exists", "melee_rat" in enemies)
test("Cave Rat display_name = 'Cave Rat'", rat.get("display_name") == "Cave Rat")
test("Cave Rat type = 'melee'", rat.get("type") == "melee")
rat_stats = rat.get("base_stats", {})
test("Cave Rat health = 50", rat_stats.get("health") == 50)
test("Cave Rat damage = 8", rat_stats.get("damage") == 8)
test("Cave Rat xp_reward = 10", rat.get("xp_reward") == 10)
test("Cave Rat money_drop min = 5", rat.get("money_drop", {}).get("min") == 5)
test("Cave Rat money_drop max = 10", rat.get("money_drop", {}).get("max") == 10)

# Spitter Crab
crab = enemies.get("ranged_crab", {})
test("Spitter Crab exists", "ranged_crab" in enemies)
test("Spitter Crab type = 'ranged'", crab.get("type") == "ranged")
test("Spitter Crab display_name = 'Spitter Crab'", crab.get("display_name") == "Spitter Crab")

# Crab King
king = enemies.get("crab_king", {})
test("Crab King exists", "crab_king" in enemies)
test("Crab King type = 'boss'", king.get("type") == "boss")
test("Crab King xp_reward = 150", king.get("xp_reward") == 150)
test("Crab King money_drop min = 150", king.get("money_drop", {}).get("min") == 150)
test("Crab King money_drop max = 250", king.get("money_drop", {}).get("max") == 250)

# Enemy type validation
VALID_ENEMY_TYPES = {"melee", "ranged", "boss"}
for eid, e in enemies.items():
    test(f"Enemy '{eid}' has valid type", e.get("type") in VALID_ENEMY_TYPES, f"got '{e.get('type')}'")

# Required fields on all enemies
ENEMY_REQUIRED = ["id", "display_name", "type", "base_stats", "xp_reward", "money_drop", "loot_table_id"]
for eid, e in enemies.items():
    for field in ENEMY_REQUIRED:
        test(f"Enemy '{eid}' has field '{field}'", field in e)

ENEMY_STAT_FIELDS = ["health", "damage", "move_speed", "attack_speed", "crit_chance", "dodge_chance"]
for eid, e in enemies.items():
    stats = e.get("base_stats", {})
    for sf in ENEMY_STAT_FIELDS:
        test(f"Enemy '{eid}' stat '{sf}' exists", sf in stats)


# ============================================================
#  6. ITEM VALUE VERIFICATION
# ============================================================
section("6. Item Value Verification")

VALID_RARITIES = {"common", "rare", "epic"}
VALID_MOD_TYPES = {"flat", "percent"}
VALID_STATS = {"health", "stamina", "damage", "attack_speed", "move_speed", "crit_chance", "dodge_chance"}

for iid, item in items.items():
    test(f"Item '{iid}' has valid rarity", item.get("rarity") in VALID_RARITIES, f"got '{item.get('rarity')}'")
    test(f"Item '{iid}' type = 'passive'", item.get("type") == "passive")
    effects = item.get("effects", [])
    test(f"Item '{iid}' has at least 1 effect", len(effects) >= 1)
    for eff in effects:
        test(f"Item '{iid}' effect has valid modifier_type", eff.get("modifier_type") in VALID_MOD_TYPES)

# Specific items
dr = items.get("damage_ring", {})
test("Rusty Ring display_name correct", dr.get("display_name") == "Rusty Ring")
test("Rusty Ring +10% damage", dr.get("effects", [{}])[0].get("value") == 0.10)

bp = items.get("blood_pendant", {})
test("Blood Pendant is rare", bp.get("rarity") == "rare")
bp_effects = {e["stat"]: e["value"] for e in bp.get("effects", [])}
test("Blood Pendant +15% damage", bp_effects.get("damage") == 0.15)
test("Blood Pendant -5% dodge", bp_effects.get("dodge_chance") == -0.05)

gi = items.get("golden_idol", {})
test("Golden Idol is rare", gi.get("rarity") == "rare")
gi_effects = {e["stat"]: e["value"] for e in gi.get("effects", [])}
test("Golden Idol +10% all stats (6 effects)", len(gi.get("effects", [])) == 6)
for stat_name in ["health", "damage", "attack_speed", "move_speed", "crit_chance", "dodge_chance"]:
    test(f"Golden Idol +10% {stat_name}", gi_effects.get(stat_name) == 0.10)

# No item exceeds 25% single-stat bonus (percent modifiers only)
for iid, item in items.items():
    for eff in item.get("effects", []):
        if eff.get("modifier_type") == "percent":
            test(
                f"Item '{iid}' percent effect on '{eff.get('stat')}' <= 25%",
                abs(eff.get("value", 0)) <= 0.25,
                f"got {eff.get('value')}",
            )


# ============================================================
#  7. SKILL VALIDATION
# ============================================================
section("7. Skill Validation")

VALID_CATEGORIES = {"combat", "economy", "personality"}

for sid, skill in skills.items():
    test(f"Skill '{sid}' has valid category", skill.get("category") in VALID_CATEGORIES)
    test(f"Skill '{sid}' has display_name", "display_name" in skill)
    test(f"Skill '{sid}' has description", "description" in skill)
    test(f"Skill '{sid}' has effects", len(skill.get("effects", [])) >= 1)
    test(f"Skill '{sid}' max_level = 1", skill.get("max_level") == 1)
    # Validate requirements reference existing skills
    for req in skill.get("requirements", []):
        test(f"Skill '{sid}' requirement '{req}' exists", req in skills)


# ============================================================
#  8. DUNGEON VALIDATION
# ============================================================
section("8. Dungeon Validation")

# Crab Cave
cc = dungeons.get("crab_cave", {})
test("Crab Cave exists", "crab_cave" in dungeons)
test("Crab Cave type = 'story'", cc.get("type") == "story")
test("Crab Cave replayable = false", cc.get("replayable") == False)
cc_rooms = cc.get("rooms", [])
combat_rooms = [r for r in cc_rooms if r.get("room_type") == "combat"]
boss_rooms = [r for r in cc_rooms if r.get("room_type") == "boss"]
test("Crab Cave has 2 combat rooms", len(combat_rooms) == 2, f"got {len(combat_rooms)}")
test("Crab Cave has 1 boss room", len(boss_rooms) == 1, f"got {len(boss_rooms)}")

# Abandoned Tunnel
at = dungeons.get("abandoned_tunnel", {})
test("Abandoned Tunnel exists", "abandoned_tunnel" in dungeons)
test("Abandoned Tunnel type = 'replayable'", at.get("type") == "replayable")
test("Abandoned Tunnel replayable = true", at.get("replayable") == True)
at_rooms = at.get("rooms", [])
test("Abandoned Tunnel has rooms", len(at_rooms) >= 3, f"got {len(at_rooms)}")

# Validate all enemy references in dungeons
for did, dun in dungeons.items():
    for ri, room in enumerate(dun.get("rooms", [])):
        if room.get("room_type") == "boss":
            eid = room.get("enemy_id", "")
            if eid:
                test(f"Dungeon '{did}' room {ri} boss '{eid}' exists in enemies", eid in enemies)
        for group in room.get("enemy_groups", []):
            eid = group.get("enemy_id", "")
            test(f"Dungeon '{did}' room {ri} enemy '{eid}' exists in enemies", eid in enemies)


# ============================================================
#  9. MISSION VALIDATION
# ============================================================
section("9. Mission Validation")

VALID_OBJECTIVE_TYPES = {"talk_to_npc", "enter_dungeon", "collect_item", "return_home", "deliver_item", "reach_location"}

expected_chain = ["mission_tutorial", "mission_papers", "mission_first_delivery", "mission_crab_cave", "mission_pay_rent"]
for mid in expected_chain:
    test(f"Mission '{mid}' exists", mid in missions)

# Verify chain order
for i, mid in enumerate(expected_chain):
    m = missions.get(mid, {})
    expected_next = expected_chain[i + 1] if i + 1 < len(expected_chain) else None
    actual_next = m.get("next_mission_id")
    test(
        f"Mission '{mid}' next_mission_id = {expected_next}",
        actual_next == expected_next,
        f"got '{actual_next}'",
    )

# Validate objective types
for mid, m in missions.items():
    for oi, obj in enumerate(m.get("objectives", [])):
        test(
            f"Mission '{mid}' objective {oi} has valid type",
            obj.get("type") in VALID_OBJECTIVE_TYPES,
            f"got '{obj.get('type')}'",
        )

# Rewards exist
for mid, m in missions.items():
    rewards = m.get("rewards", {})
    test(f"Mission '{mid}' has rewards dict", isinstance(rewards, dict))
    test(f"Mission '{mid}' rewards has 'money'", "money" in rewards)
    test(f"Mission '{mid}' rewards has 'xp'", "xp" in rewards)


# ============================================================
# 10. LOOT TABLE VALIDATION
# ============================================================
section("10. Loot Table Validation")

test("basic_dungeon_loot exists", "basic_dungeon_loot" in loot_tables)
test("boss_loot exists", "boss_loot" in loot_tables)

for ltid, lt in loot_tables.items():
    drops = lt.get("drops", [])
    test(f"Loot table '{ltid}' has drops", len(drops) > 0)
    total_weight = sum(d.get("weight", 0) for d in drops)
    test(f"Loot table '{ltid}' total weight > 0", total_weight > 0, f"got {total_weight}")
    for drop in drops:
        iid = drop.get("item_id", "")
        test(f"Loot table '{ltid}' item '{iid}' exists in items", iid in items)
        test(f"Loot table '{ltid}' item '{iid}' weight > 0", drop.get("weight", 0) > 0)

# Validate enemy loot table references
for eid, e in enemies.items():
    ltid = e.get("loot_table_id", "")
    test(f"Enemy '{eid}' loot_table_id '{ltid}' exists", ltid in loot_tables)


# ============================================================
# 11. DELIVERY JOB VALIDATION
# ============================================================
section("11. Delivery Job Validation")

test("At least 1 delivery job", len(delivery_jobs) >= 1)
dj = delivery_jobs[0] if delivery_jobs else {}
test("Delivery job has id", "id" in dj)
test("Delivery job base_reward = 50", dj.get("base_reward") == 50)
test("Delivery job delivery_points = 3", dj.get("delivery_points") == 3)


# ============================================================
# 12. DUPLICATE ID CHECK (across all collections)
# ============================================================
section("12. Duplicate ID Check")

all_ids = {}
for collection_name, collection in [
    ("enemies", enemies),
    ("items", items),
    ("skills", skills),
    ("loot_tables", loot_tables),
    ("dungeons", dungeons),
    ("missions", missions),
]:
    for entry_id in collection.keys():
        if entry_id in all_ids:
            test(
                f"No duplicate ID '{entry_id}'",
                False,
                f"found in both '{all_ids[entry_id]}' and '{collection_name}'",
            )
        else:
            all_ids[entry_id] = collection_name

test("No duplicate IDs found across collections", len(all_ids) == sum(len(c) for c in [enemies, items, skills, loot_tables, dungeons, missions]))


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
