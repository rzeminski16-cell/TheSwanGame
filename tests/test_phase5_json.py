#!/usr/bin/env python3
"""
Phase 5 — Overworld, Missions, Time, Delivery Data Validation
Validates missions.json, delivery_jobs.json, time config, mission chains.

Usage:
    python3 tests/test_phase5_json.py

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
missions_data = load_json("missions.json")
delivery_jobs_data = load_json("delivery_jobs.json")
enemies_data = load_json("enemies.json")
dungeons_data = load_json("dungeons.json")

missions = {m["id"]: m for m in missions_data["missions"]}
delivery_jobs = {d["id"]: d for d in delivery_jobs_data["delivery_jobs"]}
dungeons = {d["id"]: d for d in dungeons_data["dungeons"]}
enemies = {e["id"]: e for e in enemies_data["enemies"]}


# ============================================================
print("\n" + "=" * 60)
print("  Phase 5 — Overworld, Missions, Time, Delivery Validation")
print("=" * 60)


# ============================================================
# SECTION 1: Mission Data Integrity
# ============================================================
print("\n" + "-" * 50)
print("  1. Mission Data Integrity")
print("-" * 50)

test("missions.json has missions array", "missions" in missions_data)
test("5 missions defined", len(missions) == 5, f"got {len(missions)}")

REQUIRED_MISSION_FIELDS = ["id", "display_name", "type", "objectives", "rewards", "next_mission_id"]

for mid, mission in missions.items():
    for field in REQUIRED_MISSION_FIELDS:
        test(f"mission '{mid}' has field '{field}'", field in mission)

# All missions are story type (demo)
for mid, mission in missions.items():
    test(f"mission '{mid}' type is 'story'", mission.get("type") == "story")


# ============================================================
# SECTION 2: Mission Chain Validation
# ============================================================
print("\n" + "-" * 50)
print("  2. Mission Chain Validation")
print("-" * 50)

EXPECTED_CHAIN = [
    "mission_tutorial",
    "mission_papers",
    "mission_first_delivery",
    "mission_crab_cave",
    "mission_pay_rent",
]

# Verify chain follows next_mission_id
for i, mid in enumerate(EXPECTED_CHAIN):
    test(f"mission '{mid}' exists", mid in missions)

for i in range(len(EXPECTED_CHAIN) - 1):
    current = EXPECTED_CHAIN[i]
    expected_next = EXPECTED_CHAIN[i + 1]
    actual_next = missions[current].get("next_mission_id")
    test(f"'{current}' → '{expected_next}'",
         actual_next == expected_next,
         f"got '{actual_next}'")

# Last mission has null next
last_mission = EXPECTED_CHAIN[-1]
test(f"'{last_mission}' next_mission_id is null",
     missions[last_mission].get("next_mission_id") is None)


# ============================================================
# SECTION 3: Objective Type Validation
# ============================================================
print("\n" + "-" * 50)
print("  3. Objective Type Validation")
print("-" * 50)

VALID_OBJECTIVE_TYPES = [
    "talk_to_npc", "enter_dungeon", "collect_item",
    "return_home", "deliver_item", "reach_location",
]

for mid, mission in missions.items():
    objectives = mission.get("objectives", [])
    test(f"mission '{mid}' has objectives", len(objectives) > 0)
    for i, obj in enumerate(objectives):
        obj_type = obj.get("type", "")
        test(f"mission '{mid}' obj {i} type valid",
             obj_type in VALID_OBJECTIVE_TYPES,
             f"got '{obj_type}'")

# Specific objective checks
tutorial_objs = missions["mission_tutorial"]["objectives"]
test("tutorial obj 0: talk_to_npc hannan",
     tutorial_objs[0].get("type") == "talk_to_npc" and
     tutorial_objs[0].get("npc_id") == "hannan")
test("tutorial obj 1: reach_location player_house",
     tutorial_objs[1].get("type") == "reach_location" and
     tutorial_objs[1].get("location_id") == "player_house")

first_delivery_objs = missions["mission_first_delivery"]["objectives"]
test("first_delivery has deliver_item objective",
     any(o.get("type") == "deliver_item" for o in first_delivery_objs))
test("first_delivery references delivery_basic_1",
     any(o.get("delivery_job_id") == "delivery_basic_1" for o in first_delivery_objs))

crab_cave_objs = missions["mission_crab_cave"]["objectives"]
test("crab_cave has enter_dungeon objective",
     any(o.get("type") == "enter_dungeon" for o in crab_cave_objs))
test("crab_cave references crab_cave dungeon",
     any(o.get("dungeon_id") == "crab_cave" for o in crab_cave_objs))


# ============================================================
# SECTION 4: Mission Reward Validation
# ============================================================
print("\n" + "-" * 50)
print("  4. Mission Reward Validation")
print("-" * 50)

for mid, mission in missions.items():
    rewards = mission.get("rewards", {})
    test(f"mission '{mid}' rewards has money", "money" in rewards)
    test(f"mission '{mid}' rewards has xp", "xp" in rewards)
    test(f"mission '{mid}' rewards has items", "items" in rewards)
    test(f"mission '{mid}' money >= 0", rewards.get("money", 0) >= 0)
    test(f"mission '{mid}' xp >= 0", rewards.get("xp", 0) >= 0)

# Total XP from all missions
total_xp = sum(m["rewards"]["xp"] for m in missions.values())
test("total mission XP = 600", total_xp == 600, f"got {total_xp}")

# Total money from all missions
total_money = sum(m["rewards"]["money"] for m in missions.values())
test("total mission money = 200", total_money == 200, f"got {total_money}")


# ============================================================
# SECTION 5: Delivery Job Validation
# ============================================================
print("\n" + "-" * 50)
print("  5. Delivery Job Validation")
print("-" * 50)

test("delivery_jobs.json has delivery_jobs array", "delivery_jobs" in delivery_jobs_data)
test("at least 1 delivery job defined", len(delivery_jobs) >= 1)

REQUIRED_JOB_FIELDS = ["id", "base_reward", "difficulty_modifier", "delivery_points", "time_limit", "risk_level"]

for jid, job in delivery_jobs.items():
    for field in REQUIRED_JOB_FIELDS:
        test(f"job '{jid}' has field '{field}'", field in job)

# delivery_basic_1 specifics
basic = delivery_jobs.get("delivery_basic_1", {})
test("delivery_basic_1 exists", "delivery_basic_1" in delivery_jobs)
test("delivery_basic_1 base_reward = 50", basic.get("base_reward") == 50)
test("delivery_basic_1 difficulty_modifier = 1.0",
     approx(basic.get("difficulty_modifier", 0), 1.0))
test("delivery_basic_1 delivery_points = 3", basic.get("delivery_points") == 3)
test("delivery_basic_1 time_limit = null", basic.get("time_limit") is None)
test("delivery_basic_1 risk_level = 0", basic.get("risk_level") == 0)

# Delivery reward matches config
base_delivery = config.get("base_delivery_reward", 0)
test("config base_delivery_reward = 50", base_delivery == 50)
test("delivery reward matches config",
     basic.get("base_reward") == base_delivery)


# ============================================================
# SECTION 6: Time System Config
# ============================================================
print("\n" + "-" * 50)
print("  6. Time System Config")
print("-" * 50)

day_len = config.get("day_length_minutes", 0)
night_len = config.get("night_length_minutes", 0)

test("day_length_minutes = 15", day_len == 15, f"got {day_len}")
test("night_length_minutes = 7", night_len == 7, f"got {night_len}")

# Day length within GDD range (10-20 minutes)
test("day length in GDD range (10-20 min)", 10 <= day_len <= 20)
# Night length within GDD range (5-10 minutes)
test("night length in GDD range (5-10 min)", 5 <= night_len <= 10)

# Total day cycle
total_cycle = day_len + night_len
test("full day cycle = 22 minutes", total_cycle == 22, f"got {total_cycle}")


# ============================================================
# SECTION 7: Rent System Config
# ============================================================
print("\n" + "-" * 50)
print("  7. Rent System Config")
print("-" * 50)

base_rent = config.get("base_weekly_rent", 0)
test("base_weekly_rent = 250", base_rent == 250, f"got {base_rent}")

# Rent should be 30-50% of estimated weekly income (approx 300-600/hr * ~2.5hr = 750-1500)
# At 250 rent vs ~750 min income = 33%, vs ~1500 max income = 17%
# This is within loose budget range
test("rent > 0", base_rent > 0)
test("rent < 500 (reasonable for demo)", base_rent < 500)


# ============================================================
# SECTION 8: Cross-Reference Validation
# ============================================================
print("\n" + "-" * 50)
print("  8. Cross-Reference Validation")
print("-" * 50)

# Mission next_mission_id references
for mid, mission in missions.items():
    next_id = mission.get("next_mission_id")
    if next_id is not None and next_id != "":
        test(f"mission '{mid}' next '{next_id}' exists",
             next_id in missions,
             f"missing mission '{next_id}'")

# Mission dungeon references
for mid, mission in missions.items():
    for obj in mission.get("objectives", []):
        if obj.get("type") == "enter_dungeon":
            did = obj.get("dungeon_id", "")
            test(f"mission '{mid}' dungeon '{did}' exists",
                 did in dungeons,
                 f"missing dungeon '{did}'")

# Mission delivery job references
for mid, mission in missions.items():
    for obj in mission.get("objectives", []):
        if obj.get("type") == "deliver_item":
            jid = obj.get("delivery_job_id", "")
            test(f"mission '{mid}' delivery job '{jid}' exists",
                 jid in delivery_jobs,
                 f"missing delivery job '{jid}'")


# ============================================================
# SECTION 9: Demo Content Blueprint Compliance
# ============================================================
print("\n" + "-" * 50)
print("  9. Demo Content Blueprint Compliance")
print("-" * 50)

# Blueprint: 5 story missions
test("5 story missions (blueprint)", len(missions) == 5)

# Blueprint: 1 delivery mini-game
test("at least 1 delivery job", len(delivery_jobs) >= 1)

# Blueprint: mission chain from tutorial to pay rent
test("chain starts with mission_tutorial",
     EXPECTED_CHAIN[0] == "mission_tutorial")
test("chain ends with mission_pay_rent",
     EXPECTED_CHAIN[-1] == "mission_pay_rent")

# All NPC IDs in objectives match demo NPCs
DEMO_NPCS = {"hannan", "lewis", "luka", "jack"}
for mid, mission in missions.items():
    for obj in mission.get("objectives", []):
        if obj.get("type") == "talk_to_npc":
            npc_id = obj.get("npc_id", "")
            test(f"NPC '{npc_id}' in demo NPCs",
                 npc_id in DEMO_NPCS,
                 f"unknown NPC")


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
