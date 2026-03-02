#!/usr/bin/env python3
"""
Phase 3 — Skill Tree, Economy, and UI Data Validation
Runs outside Godot. Validates skill tree structure, economy formulas,
skill requirements, modifier aggregation, and rent calculations.

Usage:
    python3 tests/test_phase3_json.py

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
skills_data = load_json("skills.json")
items_data = load_json("items.json")

skills = {s["id"]: s for s in skills_data["skills"]}
items = {i["id"]: i for i in items_data["items"]}


# ============================================================
# SECTION 1: Skill Data Integrity
# ============================================================
print("\n" + "=" * 60)
print("  Phase 3 — Skill Tree, Economy, UI Data Validation")
print("=" * 60)

print("\n" + "-" * 50)
print("  1. Skill Data Integrity")
print("-" * 50)

test("skills.json has skills array", "skills" in skills_data)
test("15 skills total", len(skills) == 15, f"got {len(skills)}")

# Check required fields
REQUIRED_SKILL_FIELDS = ["id", "category", "display_name", "description", "effects", "max_level", "requirements"]
for sid, skill in skills.items():
    for field in REQUIRED_SKILL_FIELDS:
        test(f"skill '{sid}' has field '{field}'", field in skill)

# Check categories
categories = {}
for sid, skill in skills.items():
    cat = skill.get("category", "")
    categories[cat] = categories.get(cat, 0) + 1

test("combat category has 5 skills", categories.get("combat", 0) == 5, f"got {categories.get('combat', 0)}")
test("economy category has 5 skills", categories.get("economy", 0) == 5, f"got {categories.get('economy', 0)}")
test("personality category has 5 skills", categories.get("personality", 0) == 5, f"got {categories.get('personality', 0)}")


# ============================================================
# SECTION 2: Skill Requirements (Tree Structure)
# ============================================================
print("\n" + "-" * 50)
print("  2. Skill Requirements Validation")
print("-" * 50)

for sid, skill in skills.items():
    reqs = skill.get("requirements", [])
    for req_id in reqs:
        test(f"skill '{sid}' requirement '{req_id}' exists", req_id in skills, f"missing skill '{req_id}'")
        # Requirement must be in same category
        if req_id in skills:
            req_cat = skills[req_id].get("category", "")
            skill_cat = skill.get("category", "")
            test(f"skill '{sid}' req '{req_id}' same category", req_cat == skill_cat,
                 f"'{sid}'={skill_cat}, '{req_id}'={req_cat}")

# Check no circular dependencies
def has_circular_dep(skill_id, visited=None):
    if visited is None:
        visited = set()
    if skill_id in visited:
        return True
    visited.add(skill_id)
    for req_id in skills.get(skill_id, {}).get("requirements", []):
        if has_circular_dep(req_id, visited.copy()):
            return True
    return False

for sid in skills:
    test(f"skill '{sid}' no circular dependency", not has_circular_dep(sid))

# Count root skills (no requirements) per category
for cat in ["combat", "economy", "personality"]:
    root_count = sum(1 for s in skills.values()
                     if s.get("category") == cat and len(s.get("requirements", [])) == 0)
    test(f"category '{cat}' has root skill(s)", root_count >= 1, f"got {root_count}")

# Max depth check (no skill deeper than 3 levels)
def get_depth(skill_id, depth=0):
    reqs = skills.get(skill_id, {}).get("requirements", [])
    if not reqs:
        return depth
    return max(get_depth(r, depth + 1) for r in reqs)

for sid in skills:
    depth = get_depth(sid)
    test(f"skill '{sid}' depth <= 3", depth <= 3, f"got depth={depth}")


# ============================================================
# SECTION 3: Skill Effects Validation
# ============================================================
print("\n" + "-" * 50)
print("  3. Skill Effects Validation")
print("-" * 50)

VALID_MODIFIER_TYPES = ["flat", "percent"]

for sid, skill in skills.items():
    effects = skill.get("effects", [])
    test(f"skill '{sid}' has effects", len(effects) > 0)

    for i, effect in enumerate(effects):
        test(f"skill '{sid}' effect[{i}] has stat", "stat" in effect and effect["stat"] != "")
        test(f"skill '{sid}' effect[{i}] has modifier_type",
             effect.get("modifier_type", "") in VALID_MODIFIER_TYPES,
             f"got '{effect.get('modifier_type', '')}'")
        test(f"skill '{sid}' effect[{i}] has value", "value" in effect)
        val = effect.get("value", 0)
        test(f"skill '{sid}' effect[{i}] value > 0", val > 0, f"got {val}")

    # Max level is 1 for demo
    test(f"skill '{sid}' max_level is 1", skill.get("max_level") == 1)


# ============================================================
# SECTION 4: Skill Modifier Aggregation Math
# ============================================================
print("\n" + "-" * 50)
print("  4. Skill Modifier Aggregation")
print("-" * 50)

# Simulate unlocking all combat skills and check aggregated modifiers
combat_mods = {}
for sid, skill in skills.items():
    if skill.get("category") != "combat":
        continue
    for effect in skill.get("effects", []):
        stat = effect["stat"]
        mod_type = effect["modifier_type"]
        value = effect["value"]
        key = f"{stat}_{mod_type}"
        combat_mods[key] = combat_mods.get(key, 0) + value

test("combat skills: damage_percent exists", "damage_percent" in combat_mods)
test("combat skills: damage_percent = 0.05", approx(combat_mods.get("damage_percent", 0), 0.05))
test("combat skills: attack_speed_percent exists", "attack_speed_percent" in combat_mods)
test("combat skills: attack_speed_percent = 0.05", approx(combat_mods.get("attack_speed_percent", 0), 0.05))
test("combat skills: crit_chance_percent = 0.05", approx(combat_mods.get("crit_chance_percent", 0), 0.05))
test("combat skills: health_flat = 10", approx(combat_mods.get("health_flat", 0), 10))
test("combat skills: move_speed_percent = 0.05", approx(combat_mods.get("move_speed_percent", 0), 0.05))

# Economy modifiers
economy_mods = {}
for sid, skill in skills.items():
    if skill.get("category") != "economy":
        continue
    for effect in skill.get("effects", []):
        stat = effect["stat"]
        mod_type = effect["modifier_type"]
        value = effect["value"]
        key = f"{stat}_{mod_type}"
        economy_mods[key] = economy_mods.get(key, 0) + value

test("economy skills: delivery_reward_percent = 0.10", approx(economy_mods.get("delivery_reward_percent", 0), 0.10))
test("economy skills: rent_reduction_percent = 0.10", approx(economy_mods.get("rent_reduction_percent", 0), 0.10))
test("economy skills: loot_chance_percent = 0.05", approx(economy_mods.get("loot_chance_percent", 0), 0.05))
test("economy skills: money_drop_percent = 0.10", approx(economy_mods.get("money_drop_percent", 0), 0.10))
test("economy skills: xp_gain_percent = 0.05", approx(economy_mods.get("xp_gain_percent", 0), 0.05))


# ============================================================
# SECTION 5: Economy Formulas
# ============================================================
print("\n" + "-" * 50)
print("  5. Economy Formulas")
print("-" * 50)

base_rent = config.get("base_weekly_rent", 0)
test("base weekly rent = 250", base_rent == 250, f"got {base_rent}")

base_delivery = config.get("base_delivery_reward", 0)
test("base delivery reward = 50", base_delivery == 50, f"got {base_delivery}")

# Rent with Haggler skill (10% reduction)
rent_reduction = 0.10  # from economy_rent_1
effective_rent = base_rent * (1.0 - rent_reduction)
test("rent with Haggler = 225", effective_rent == 225, f"got {effective_rent}")

# Delivery reward with Smooth Talker (10% bonus)
delivery_bonus = 0.10  # from economy_delivery_1
effective_delivery = base_delivery * (1.0 + delivery_bonus)
test("delivery with Smooth Talker = 55", approx(effective_delivery, 55), f"got {effective_delivery}")


# ============================================================
# SECTION 6: Stat Formula with Skills
# ============================================================
print("\n" + "-" * 50)
print("  6. Stat Computation with Skill Modifiers")
print("-" * 50)

base_stats = config.get("player_base_stats", {})
level_up_bonuses = config.get("level_up_bonuses", {})
soft_caps = config.get("soft_caps", {})

def get_level_bonuses(stat, level):
    flat = 0.0
    percent = 0.0
    levels_gained = level - 1
    if stat in level_up_bonuses:
        flat = level_up_bonuses[stat] * levels_gained
    percent_key = f"{stat}_percent"
    if percent_key in level_up_bonuses:
        percent = level_up_bonuses[percent_key] * levels_gained
    return flat, percent

def apply_soft_cap(stat, raw_value):
    if stat not in soft_caps:
        return raw_value
    cap = soft_caps[stat]
    cap_max = cap["max"]
    scaling = cap["scaling_factor"]
    return cap_max * (1.0 - math.exp(-raw_value / scaling))

def compute_stat(stat, level, item_mods=None, skill_mods=None):
    if item_mods is None:
        item_mods = {}
    if skill_mods is None:
        skill_mods = {}
    base = base_stats.get(stat, 0)
    lf, lp = get_level_bonuses(stat, level)
    flat = lf + item_mods.get(f"{stat}_flat", 0) + skill_mods.get(f"{stat}_flat", 0)
    percent = lp + item_mods.get(f"{stat}_percent", 0) + skill_mods.get(f"{stat}_percent", 0)
    raw = (base + flat) * (1.0 + percent)
    if stat in ["crit_chance", "dodge_chance"]:
        raw = apply_soft_cap(stat, raw)
    return raw

# Level 1, no items, no skills
damage_l1 = compute_stat("damage", 1)
test("damage at L1 = 10.0", approx(damage_l1, 10.0), f"got {damage_l1}")

# Level 3, with damage skill (+5% damage)
damage_l3_skill = compute_stat("damage", 3, skill_mods={"damage_percent": 0.05})
# Expected: (10 + 0) * (1 + 0.04 + 0.05) = 10 * 1.09 = 10.9
test("damage at L3 with Sharpened Instinct = 10.9", approx(damage_l3_skill, 10.9), f"got {damage_l3_skill}")

# Level 3, with health skill (+10 flat health)
health_l3_skill = compute_stat("health", 3, skill_mods={"health_flat": 10})
# Expected: (100 + 10 + 10) * 1 = 120 (level 3 = +10 health flat, skill = +10 flat)
test("health at L3 with Tough Skin = 120.0", approx(health_l3_skill, 120.0), f"got {health_l3_skill}")

# Level 1, with damage ring item (+10% damage) + Sharpened Instinct (+5% damage)
damage_both = compute_stat("damage", 1, item_mods={"damage_percent": 0.10}, skill_mods={"damage_percent": 0.05})
# Expected: 10 * (1 + 0.10 + 0.05) = 10 * 1.15 = 11.5
test("damage with item + skill = 11.5", approx(damage_both, 11.5), f"got {damage_both}")

# Crit chance with skill at Level 1
crit_with_skill = compute_stat("crit_chance", 1, skill_mods={"crit_chance_percent": 0.05})
# raw = 0.05 * (1 + 0.05) = 0.0525, soft capped
expected_crit = 0.40 * (1.0 - math.exp(-0.0525 / 0.08))
test("crit at L1 with Keen Eye uses soft cap", approx(crit_with_skill, expected_crit),
     f"got {crit_with_skill:.4f}, expected {expected_crit:.4f}")


# ============================================================
# SECTION 7: Skill Tree Demo Content Blueprint Compliance
# ============================================================
print("\n" + "-" * 50)
print("  7. Demo Content Blueprint Compliance")
print("-" * 50)

# Blueprint: 15 nodes, 5 per category
test("total skills = 15 (blueprint)", len(skills) == 15)
test("max_player_level = 5 (blueprint)", config.get("max_player_level_demo") == 5)
# Max skill points = 4 (level up from 1→5 = 4 levels = 4 SP)
# Player can unlock at most 4 of 15 skills
max_sp = config.get("max_player_level_demo", 5) - 1
test("max skill points = 4 (from levels 2-5)", max_sp == 4)

# Each skill is 1 point (max_level = 1)
all_single = all(s.get("max_level") == 1 for s in skills.values())
test("all skills cost 1 point", all_single)


# ============================================================
# SECTION 8: Cross-Reference Validation
# ============================================================
print("\n" + "-" * 50)
print("  8. Cross-Reference Validation")
print("-" * 50)

# All skill IDs are unique
all_ids = [s["id"] for s in skills_data["skills"]]
test("no duplicate skill IDs", len(all_ids) == len(set(all_ids)))

# No skill references itself
for sid, skill in skills.items():
    test(f"skill '{sid}' doesn't require itself", sid not in skill.get("requirements", []))

# Validate expected specific skills exist
expected_skills = [
    "combat_damage_1", "combat_attack_speed_1", "combat_crit_1", "combat_health_1", "combat_speed_1",
    "economy_delivery_1", "economy_rent_1", "economy_loot_1", "economy_money_1", "economy_xp_1",
    "personality_dodge_1", "personality_stamina_1", "personality_boss_damage_1",
    "personality_dungeon_speed_1", "personality_elite_damage_1"
]
for sid in expected_skills:
    test(f"expected skill '{sid}' exists", sid in skills)


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
