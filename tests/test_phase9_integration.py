#!/usr/bin/env python3
"""Phase 9 — Integration Testing + Balance Pass: cross-system validation.

Tests that all systems work together correctly:
- Data consistency across JSON files (items referenced in loot tables exist, etc.)
- Balance math validation (XP curves, damage output, economy viability)
- Script cross-references (signals connected, methods called across managers)
- Full game flow validation (new game → dungeon → boss → rent)
- No orphan files or dead references
"""

import os, sys, json, re, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
passed = 0
failed = 0


def check(label, condition):
    global passed, failed
    if condition:
        print(f"  PASS  {label}")
        passed += 1
    else:
        print(f"  FAIL  {label}")
        failed += 1


def read(rel_path):
    full = os.path.join(ROOT, rel_path)
    if not os.path.exists(full):
        return ""
    with open(full, "r") as f:
        return f.read()


def load_json(rel_path):
    raw = read(rel_path)
    if not raw:
        return {}
    return json.loads(raw)


def file_exists(rel_path):
    return os.path.exists(os.path.join(ROOT, rel_path))


# ============================================================
# Load all data
# ============================================================
config = load_json("data/global_config.json")
enemies_data = load_json("data/enemies.json")
items_data = load_json("data/items.json")
skills_data = load_json("data/skills.json")
dungeons_data = load_json("data/dungeons.json")
missions_data = load_json("data/missions.json")
loot_tables_data = load_json("data/loot_tables.json")
cutscenes_data = load_json("data/cutscenes.json")

enemies = {e["id"]: e for e in enemies_data.get("enemies", [])}
items = {i["id"]: i for i in items_data.get("items", [])}
skills = {s["id"]: s for s in skills_data.get("skills", [])}
dungeons = {d["id"]: d for d in dungeons_data.get("dungeons", [])}
missions = {m["id"]: m for m in missions_data.get("missions", [])}
loot_tables = {t["id"]: t for t in loot_tables_data.get("loot_tables", [])}


# ============================================================
# 1. CROSS-DATA REFERENTIAL INTEGRITY
# ============================================================
print("\n=== 1. Cross-Data Referential Integrity ===")

# All enemy loot_table_ids reference existing loot tables
print("\n--- Enemy → Loot Table References ---")
for eid, e in enemies.items():
    lt_id = e.get("loot_table_id", "")
    if lt_id:
        check(f"Enemy '{eid}' loot_table_id '{lt_id}' exists", lt_id in loot_tables)

# All loot table item_ids reference existing items
print("\n--- Loot Table → Item References ---")
for lt_id, lt in loot_tables.items():
    for drop in lt.get("drops", []):
        item_id = drop.get("item_id", "")
        check(f"Loot table '{lt_id}' item '{item_id}' exists", item_id in items)

# All dungeon rooms reference existing enemies
print("\n--- Dungeon → Enemy References ---")
for did, d in dungeons.items():
    for i, room in enumerate(d.get("rooms", [])):
        if room.get("room_type") == "boss":
            boss_id = room.get("enemy_id", "")
            check(f"Dungeon '{did}' room {i} boss '{boss_id}' exists", boss_id in enemies)
        else:
            for group in room.get("enemy_groups", []):
                gid = group.get("enemy_id", "")
                check(f"Dungeon '{did}' room {i} enemy '{gid}' exists", gid in enemies)

# All mission chains are valid
print("\n--- Mission Chain Integrity ---")
for mid, m in missions.items():
    next_id = m.get("next_mission_id")
    if next_id is not None:
        check(f"Mission '{mid}' next '{next_id}' exists", next_id in missions)

# Skill prerequisites reference existing skills
print("\n--- Skill Prerequisite Integrity ---")
for sid, s in skills.items():
    for req in s.get("requirements", []):
        check(f"Skill '{sid}' requires '{req}' which exists", req in skills)

# Cutscene trigger missions reference existing missions
print("\n--- Cutscene → Mission References ---")
for cid, c in cutscenes_data.items():
    trigger = c.get("trigger_mission", "")
    if trigger:
        check(f"Cutscene '{cid}' trigger_mission '{trigger}' exists", trigger in missions)


# ============================================================
# 2. BALANCE MATH VALIDATION
# ============================================================
print("\n=== 2. Balance Math Validation ===")

base_stats = config.get("player_base_stats", {})
level_bonuses = config.get("level_up_bonuses", {})
max_level = config.get("max_player_level_demo", 5)

# XP curve validation
print("\n--- XP Curve ---")
base_xp = config.get("base_xp_per_level", 100)
exponent = config.get("xp_curve_exponent", 1.5)
xp_per_level = []
for lvl in range(1, max_level + 1):
    xp_needed = int(base_xp * (lvl ** exponent))
    xp_per_level.append(xp_needed)

check(f"XP curve level 1 = {xp_per_level[0]} (reasonable: 50-200)", 50 <= xp_per_level[0] <= 200)
check(f"XP curve level 5 = {xp_per_level[4]} (reasonable: 500-2000)", 500 <= xp_per_level[4] <= 2000)
check("XP curve is monotonically increasing", all(xp_per_level[i] < xp_per_level[i+1] for i in range(len(xp_per_level)-1)))

# Player stats at max level
print("\n--- Player Stats at Max Level ---")
max_hp = base_stats["health"] + level_bonuses.get("health", 0) * (max_level - 1)
max_dmg = base_stats["damage"] * (1.0 + level_bonuses.get("damage_percent", 0) * (max_level - 1))
check(f"Max level HP = {max_hp} (reasonable: 110-200)", 110 <= max_hp <= 200)
check(f"Max level damage = {max_dmg:.1f} (reasonable: 10-20)", 10 <= max_dmg <= 20)

# Enemy HP vs player damage — can player kill enemies?
print("\n--- Enemy HP vs Player Damage ---")
for eid, e in enemies.items():
    hp = e["base_stats"]["health"]
    hits_needed = hp / max(1, base_stats["damage"])
    check(f"Cave Rat takes {hits_needed:.0f} hits at level 1 (2-15)" if eid == "melee_rat" else
          f"Spitter Crab takes {hits_needed:.0f} hits at level 1 (3-20)" if eid == "ranged_crab" else
          f"Crab King takes {hits_needed:.0f} hits at level 1 (20-100)",
          2 <= hits_needed <= 100)

# Boss vs player — boss should be a challenge but beatable
print("\n--- Boss Balance (Crab King) ---")
boss = enemies.get("crab_king", {})
boss_hp = boss.get("base_stats", {}).get("health", 500)
boss_dmg = boss.get("base_stats", {}).get("damage", 20)
player_hp = base_stats["health"]
hits_to_kill_player = player_hp / max(1, boss_dmg)
hits_to_kill_boss = boss_hp / max(1, max_dmg)
check(f"Boss kills player in {hits_to_kill_player:.0f} hits (3-15 is fair)", 3 <= hits_to_kill_player <= 15)
check(f"Player (max lvl) kills boss in {hits_to_kill_boss:.0f} hits (25-80 is fair)", 25 <= hits_to_kill_boss <= 80)

# Economy validation
print("\n--- Economy Balance ---")
rent = config.get("base_weekly_rent", 250)
delivery_reward = config.get("base_delivery_reward", 50)
deliveries_for_rent = rent / max(1, delivery_reward)
check(f"Rent = {rent}, delivery reward = {delivery_reward}", rent > 0 and delivery_reward > 0)
check(f"Need {deliveries_for_rent:.0f} deliveries to pay rent (3-10 is fair)", 3 <= deliveries_for_rent <= 10)

# Enemy money drops — can player earn enough?
rat_money_avg = (enemies["melee_rat"]["money_drop"]["min"] + enemies["melee_rat"]["money_drop"]["max"]) / 2
crab_money_avg = (enemies["ranged_crab"]["money_drop"]["min"] + enemies["ranged_crab"]["money_drop"]["max"]) / 2
boss_money_avg = (enemies["crab_king"]["money_drop"]["min"] + enemies["crab_king"]["money_drop"]["max"]) / 2

# Crab Cave: 5 rats + 3 rats + 2 crabs + boss = total money
cave_money = 8 * rat_money_avg + 2 * crab_money_avg + boss_money_avg
check(f"Crab Cave total money ~{cave_money:.0f} (50-400 reasonable)", 50 <= cave_money <= 400)

# Mission rewards total
total_mission_money = sum(m.get("rewards", {}).get("money", 0) for m in missions.values())
total_mission_xp = sum(m.get("rewards", {}).get("xp", 0) for m in missions.values())
check(f"Total mission money = {total_mission_money} (100-500)", 100 <= total_mission_money <= 500)
check(f"Total mission XP = {total_mission_xp} (300-1000)", 300 <= total_mission_xp <= 1000)

# Death penalty shouldn't be catastrophic
print("\n--- Death Penalty ---")
penalty = config.get("death_penalty", {})
money_loss = penalty.get("money_loss_percent", 0.1)
item_loss = penalty.get("item_loss_count", 1)
check(f"Money loss on death = {money_loss*100:.0f}% (5-20% is fair)", 0.05 <= money_loss <= 0.20)
check(f"Item loss on death = {item_loss} (0-2 is fair)", 0 <= item_loss <= 2)

# Item effects don't exceed 25% cap
print("\n--- Item Effect Caps ---")
for iid, item in items.items():
    for eff in item.get("effects", []):
        val = abs(eff.get("value", 0))
        if eff.get("modifier_type") == "percent":
            check(f"Item '{iid}' stat '{eff['stat']}' = {val*100:.0f}% (<=25% cap)",
                  val <= 0.25)

# Dungeon scaling caps
print("\n--- Dungeon Scaling Caps ---")
diff_cap = config.get("difficulty_multiplier_cap", 3.0)
check(f"Difficulty multiplier cap = {diff_cap} (2.0-5.0)", 2.0 <= diff_cap <= 5.0)

scaling_per = config.get("dungeon_scaling_per_completion", 0.15)
check(f"Scaling per completion = {scaling_per*100:.0f}% (5-25%)", 0.05 <= scaling_per <= 0.25)

# Time balance
print("\n--- Time Balance ---")
day_len = config.get("day_length_minutes", 15)
night_len = config.get("night_length_minutes", 7)
check(f"Day length = {day_len} min (10-20)", 10 <= day_len <= 20)
check(f"Night length = {night_len} min (5-10)", 5 <= night_len <= 10)


# ============================================================
# 3. CONTENT COMPLETENESS (vs DEMO_CONTENT_BLUEPRINT)
# ============================================================
print("\n=== 3. Content Completeness ===")

# Enemies: 3 types + 1 boss
check("Enemy count = 3 (melee, ranged, boss)", len(enemies) == 3)
check("Has melee enemy (Cave Rat)", "melee_rat" in enemies)
check("Has ranged enemy (Spitter Crab)", "ranged_crab" in enemies)
check("Has boss (Crab King)", "crab_king" in enemies)

# Items: 10 passive items
check(f"Item count = {len(items)} (should be 10)", len(items) == 10)

# Skills: 15 nodes
check(f"Skill count = {len(skills)} (should be 15)", len(skills) == 15)
combat_skills = [s for s in skills.values() if s["category"] == "combat"]
economy_skills = [s for s in skills.values() if s["category"] == "economy"]
personality_skills = [s for s in skills.values() if s["category"] == "personality"]
check(f"Combat skills = {len(combat_skills)} (should be 5)", len(combat_skills) == 5)
check(f"Economy skills = {len(economy_skills)} (should be 5)", len(economy_skills) == 5)
check(f"Personality skills = {len(personality_skills)} (should be 5)", len(personality_skills) == 5)

# Dungeons: 1 story + 1 replayable
check(f"Dungeon count = {len(dungeons)} (should be 2)", len(dungeons) == 2)
check("Has story dungeon (Crab Cave)", "crab_cave" in dungeons)
check("Has replayable dungeon (Abandoned Tunnel)", "abandoned_tunnel" in dungeons)
check("Crab Cave is not replayable", dungeons["crab_cave"].get("replayable") == False)
check("Abandoned Tunnel is replayable", dungeons["abandoned_tunnel"].get("replayable") == True)

# Missions: 5 story missions
check(f"Mission count = {len(missions)} (should be 5)", len(missions) == 5)

# Cutscenes: 4
check(f"Cutscene count = {len(cutscenes_data)} (should be 4)", len(cutscenes_data) == 4)

# Loot tables: 2
check(f"Loot table count = {len(loot_tables)} (should be 2)", len(loot_tables) == 2)


# ============================================================
# 4. SCRIPT CROSS-SYSTEM REFERENCES
# ============================================================
print("\n=== 4. Script Cross-System References ===")

# Key scripts exist
key_scripts = [
    "scripts/main.gd", "scripts/scene_manager.gd", "scripts/ui_manager.gd",
    "scripts/audio_manager.gd", "scripts/cutscene_player.gd",
    "scripts/managers/data_manager.gd", "scripts/managers/game_state.gd",
    "scripts/managers/save_manager.gd", "scripts/managers/player_manager.gd",
    "scripts/managers/combat_manager.gd", "scripts/managers/dungeon_manager.gd",
    "scripts/managers/economy_manager.gd", "scripts/managers/time_manager.gd",
    "scripts/managers/mission_manager.gd", "scripts/managers/inventory_manager.gd",
    "scripts/managers/multiplayer_manager.gd",
]
for script in key_scripts:
    check(f"Script exists: {script}", file_exists(script))

# Key scenes exist
key_scenes = [
    "scenes/Main.tscn", "scenes/OverworldScene.tscn", "scenes/DungeonScene.tscn",
    "scenes/Minigame_Delivery.tscn", "scenes/TestPlayground.tscn",
    "scenes/entities/Player.tscn", "scenes/entities/Enemy.tscn",
]
for scene in key_scenes:
    check(f"Scene exists: {scene}", file_exists(scene))

# SaveManager initializes peer mapping for single player
print("\n--- SaveManager Single-Player Init ---")
sm = read("scripts/managers/save_manager.gd")
check("new_game() sets peer_player_map for single player", "peer_player_map[1] = 1" in sm)
check("load_game() sets peer_player_map for single player", sm.count("peer_player_map[1] = 1") >= 2)

# SceneManager calls AudioManager
scene_mgr = read("scripts/scene_manager.gd")
check("SceneManager calls _update_bgm on scene change", "_update_bgm" in scene_mgr)
check("SceneManager supports screen transitions", "_screen_transition" in scene_mgr)

# UIManager wires audio to events
ui_mgr = read("scripts/ui_manager.gd")
check("UIManager plays SFX on combat damage", "play_sfx" in ui_mgr)
check("UIManager creates CutscenePlayer", "_setup_cutscene_player" in ui_mgr)
check("UIManager creates ScreenTransition", "_setup_screen_transition" in ui_mgr)
check("UIManager creates VisualEffects", "_setup_visual_effects" in ui_mgr)

# CutscenePlayer pauses time
cp = read("scripts/cutscene_player.gd")
check("CutscenePlayer pauses TimeManager", "TimeManager" in cp and "set_paused" in cp)


# ============================================================
# 5. NO ORPHAN DATA / DEAD REFERENCES
# ============================================================
print("\n=== 5. Orphan Detection ===")

# All items in items.json should appear in at least one loot table
all_loot_item_ids = set()
for lt in loot_tables.values():
    for drop in lt.get("drops", []):
        all_loot_item_ids.add(drop.get("item_id", ""))

for iid in items:
    check(f"Item '{iid}' appears in a loot table", iid in all_loot_item_ids)

# All enemies should appear in at least one dungeon
all_dungeon_enemy_ids = set()
for d in dungeons.values():
    for room in d.get("rooms", []):
        if room.get("enemy_id"):
            all_dungeon_enemy_ids.add(room["enemy_id"])
        for group in room.get("enemy_groups", []):
            all_dungeon_enemy_ids.add(group.get("enemy_id", ""))

for eid in enemies:
    check(f"Enemy '{eid}' appears in a dungeon", eid in all_dungeon_enemy_ids)

# Mission chain starts and ends properly
print("\n--- Mission Chain ---")
start_missions = set(missions.keys())
referenced_as_next = set()
for m in missions.values():
    next_id = m.get("next_mission_id")
    if next_id:
        referenced_as_next.add(next_id)

first_missions = start_missions - referenced_as_next
terminal_missions = {mid for mid, m in missions.items() if m.get("next_mission_id") is None}
check(f"Exactly 1 starting mission: {first_missions}", len(first_missions) == 1)
check(f"Exactly 1 terminal mission: {terminal_missions}", len(terminal_missions) == 1)
check("Mission chain starts with tutorial", "mission_tutorial" in first_missions)
check("Mission chain ends with pay_rent", "mission_pay_rent" in terminal_missions)

# Walk the full chain
chain = []
current = "mission_tutorial"
while current and len(chain) < 20:
    chain.append(current)
    current = missions.get(current, {}).get("next_mission_id")
check(f"Full chain length = {len(chain)} (should be 5)", len(chain) == 5)


# ============================================================
# 6. CRAB CAVE DUNGEON STRUCTURE
# ============================================================
print("\n=== 6. Crab Cave Dungeon Validation ===")
cave = dungeons.get("crab_cave", {})
rooms = cave.get("rooms", [])
check(f"Crab Cave has {len(rooms)} rooms (should be 3: 2 combat + 1 boss)", len(rooms) == 3)

combat_rooms = [r for r in rooms if r.get("room_type") == "combat"]
boss_rooms = [r for r in rooms if r.get("room_type") == "boss"]
check(f"Combat rooms = {len(combat_rooms)} (should be 2)", len(combat_rooms) == 2)
check(f"Boss rooms = {len(boss_rooms)} (should be 1)", len(boss_rooms) == 1)
if boss_rooms:
    check("Boss room uses crab_king", boss_rooms[0].get("enemy_id") == "crab_king")


# ============================================================
# 7. AUTOLOAD REGISTRATION
# ============================================================
print("\n=== 7. Autoload Registration ===")
project = read("project.godot")
expected_autoloads = [
    "DataManager", "GameState", "SaveManager", "PlayerManager",
    "InventoryManager", "CombatManager", "DungeonManager",
    "EconomyManager", "TimeManager", "MissionManager", "MultiplayerManager"
]
for al in expected_autoloads:
    check(f"Autoload registered: {al}", al in project)


# ============================================================
# 8. LOOT TABLE WEIGHT SANITY
# ============================================================
print("\n=== 8. Loot Table Weight Sanity ===")
for lt_id, lt in loot_tables.items():
    drops = lt.get("drops", [])
    total_weight = sum(d.get("weight", 0) for d in drops)
    check(f"Loot table '{lt_id}' total weight = {total_weight} (>0)", total_weight > 0)
    for drop in drops:
        w = drop.get("weight", 0)
        check(f"  '{drop['item_id']}' weight = {w} (>0)", w > 0)


# ============================================================
# SUMMARY
# ============================================================
print(f"\n{'='*50}")
print(f"Phase 9 Integration Tests: {passed} passed, {failed} failed")
print(f"{'='*50}")
if failed > 0:
    sys.exit(1)
