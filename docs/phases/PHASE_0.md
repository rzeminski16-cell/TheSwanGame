# Phase 0: Project Skeleton + Data Foundation

**Goal:** A runnable Godot 4.x project with all JSON data loaded through DataManager, all autoload managers registered (most as stubs), and a SceneManager that can swap scenes.

---

## What This Phase Delivers

- `project.godot` with display settings, input map, and all 11 autoloads registered
- 8 JSON data files under `res://data/` with complete demo content
- `DataManager` fully implemented — loads and validates all JSON at startup
- 10 remaining managers as stubs with documented API signatures
- `Main.tscn` root scene with SceneManager, UIManager, AudioManager
- SceneManager capable of dynamic scene transitions
- A `TestPlayground.tscn` for manual verification

---

## File Map

```
project.godot
.gitignore

scenes/
├── Main.tscn                    # Root scene (always loaded)
└── TestPlayground.tscn          # Blank scene for testing transitions

scripts/
├── main.gd                      # Main scene script
├── scene_manager.gd             # Dynamic scene loading
├── ui_manager.gd                # UI layer stub
├── audio_manager.gd             # Audio stub
└── managers/
    ├── data_manager.gd          # FULLY IMPLEMENTED — loads all JSON
    ├── game_state.gd            # Runtime state container (stub)
    ├── save_manager.gd          # Save/load (stub)
    ├── multiplayer_manager.gd   # Multiplayer (stub)
    ├── player_manager.gd        # Player stats/spawning (stub)
    ├── inventory_manager.gd     # Inventory (stub)
    ├── combat_manager.gd        # Combat resolution (stub)
    ├── dungeon_manager.gd       # Dungeon lifecycle (stub)
    ├── economy_manager.gd       # Money tracking (stub)
    ├── time_manager.gd          # Day/night cycle (stub)
    └── mission_manager.gd       # Mission tracking (stub)

data/
├── global_config.json           # Balance tuning (XP curves, scaling, caps)
├── enemies.json                 # 3 enemy definitions
├── items.json                   # 10 passive items
├── skills.json                  # 15 skill tree nodes
├── loot_tables.json             # Drop tables (basic, boss)
├── dungeons.json                # 2 dungeon definitions
├── missions.json                # 5 story missions
└── delivery_jobs.json           # 1 delivery job
```

---

## Developer Guide

### How to Change Game Balance

All balance values live in `res://data/global_config.json`. **Never edit scripts to change numbers.**

| Want to change... | Edit this field in `global_config.json` |
|---|---|
| XP required per level | `base_xp_per_level`, `xp_curve_exponent` |
| How fast dungeons get harder | `dungeon_scaling_per_completion` |
| Enemy health scaling per completion | `enemy_health_scaling` |
| Enemy damage scaling per completion | `enemy_damage_scaling` |
| Enemy count scaling | `enemy_spawn_scaling` |
| Loot quality improvement | `loot_quality_scaling` |
| Delivery pay | `base_delivery_reward` |
| Weekly rent cost | `base_weekly_rent` |
| Max level in demo | `max_player_level_demo` |
| Player starting stats | `player_base_stats.*` |
| Per-level stat growth | `level_up_bonuses.*` |
| Death penalties | `death_penalty.*` |
| Crit/dodge soft caps | `soft_caps.*` |

### How to Add/Modify an Enemy

Edit `res://data/enemies.json`. Each enemy entry has:
```json
{
  "id": "unique_string_id",
  "display_name": "Shown to player",
  "type": "melee | ranged | boss",
  "base_stats": {
    "health": 50,
    "damage": 8,
    "move_speed": 80,
    "attack_speed": 1.0,
    "crit_chance": 0.0,
    "dodge_chance": 0.0
  },
  "xp_reward": 10,
  "money_drop": { "min": 5, "max": 10 },
  "loot_table_id": "basic_dungeon_loot"
}
```
- `type` determines AI behavior (implemented in Phase 2)
- Stats here are **base values** — scaling is applied at runtime from `global_config.json`
- `loot_table_id` must match an entry in `loot_tables.json`

### How to Add/Modify an Item

Edit `res://data/items.json`. Each item:
```json
{
  "id": "unique_string_id",
  "display_name": "Shown to player",
  "rarity": "common | rare | epic",
  "type": "passive",
  "effects": [
    { "stat": "damage", "modifier_type": "percent", "value": 0.10 }
  ],
  "stackable": false
}
```
- Valid stats: `health`, `damage`, `attack_speed`, `move_speed`, `crit_chance`, `dodge_chance`, `stamina`
- `modifier_type`: `flat` (add number) or `percent` (multiply)
- Demo rule: no item may exceed +25% to a single stat

### How to Add/Modify a Skill

Edit `res://data/skills.json`. Each skill node:
```json
{
  "id": "combat_damage_1",
  "category": "combat | economy | personality",
  "display_name": "Shown in skill tree",
  "description": "Tooltip text",
  "effects": [
    { "stat": "damage", "modifier_type": "percent", "value": 0.05 }
  ],
  "max_level": 1,
  "requirements": ["other_skill_id"]
}
```
- `requirements` is an array of skill IDs that must be unlocked first (empty for root nodes)
- Economy skills use special stats: `delivery_reward`, `rent_reduction`, `loot_chance`, `money_drop`, `xp_gain`

### How to Modify Dungeon Structure

Edit `res://data/dungeons.json`. Each dungeon:
```json
{
  "id": "crab_cave",
  "display_name": "Crab Cave",
  "type": "story | replayable",
  "base_difficulty": 1,
  "rooms": [
    {
      "room_type": "combat | boss",
      "enemy_groups": [
        { "enemy_id": "melee_rat", "count": 5 }
      ]
    }
  ],
  "replayable": false
}
```
- Boss rooms use `"enemy_id"` directly instead of `enemy_groups`
- Replayable dungeons persist `completion_count` in save data
- Room order matters — players progress sequentially

### How to Modify Missions

Edit `res://data/missions.json`. Missions chain via `next_mission_id`:
```json
{
  "id": "mission_tutorial",
  "display_name": "Move In",
  "type": "story",
  "objectives": [
    { "type": "talk_to_npc", "npc_id": "hannan" },
    { "type": "reach_location", "location_id": "player_house" }
  ],
  "rewards": { "money": 50, "xp": 50, "items": [] },
  "next_mission_id": "mission_papers"
}
```
- Valid objective types: `talk_to_npc`, `enter_dungeon`, `collect_item`, `return_home`, `deliver_item`, `reach_location`
- Setting `next_mission_id` to `null` means the chain ends

### How the Autoload System Works

All managers are registered in `project.godot` under `[autoload]`. They load **before** any scene and are accessible globally:

```gdscript
# From any script:
DataManager.get_enemy("melee_rat")
GameState.is_in_dungeon
EconomyManager.add_money(player_id, 50)
```

SceneManager and UIManager are **not** autoloads — they are child nodes of `Main.tscn` and accessed via:
```gdscript
get_tree().current_scene.get_node("SceneManager")
# Or via a reference set at _ready() time
```

### How to Add a New Manager

1. Create `res://scripts/managers/your_manager.gd` extending `Node`
2. Register in `project.godot` under `[autoload]`
3. Access globally: `YourManager.method()`
4. Document the API in the phase doc where it's implemented

---

## How DataManager Works (The Only Fully Implemented Manager)

```gdscript
# DataManager loads all JSON files in _ready()
# Access data through typed getter functions:

DataManager.get_config()           # → Dictionary (global_config.json)
DataManager.get_enemy(id)          # → Dictionary (single enemy by id)
DataManager.get_all_enemies()      # → Array[Dictionary]
DataManager.get_item(id)           # → Dictionary (single item by id)
DataManager.get_all_items()        # → Array[Dictionary]
DataManager.get_skill(id)          # → Dictionary
DataManager.get_all_skills()       # → Array[Dictionary]
DataManager.get_loot_table(id)     # → Dictionary
DataManager.get_dungeon(id)        # → Dictionary
DataManager.get_all_dungeons()     # → Array[Dictionary]
DataManager.get_mission(id)        # → Dictionary
DataManager.get_all_missions()     # → Array[Dictionary]
DataManager.get_delivery_jobs()    # → Array[Dictionary]
```

If a JSON file fails to load or has structural issues, DataManager prints an error and the game won't start cleanly. This is intentional — data integrity is critical.

---

## Testing Checklist

### Project Launch
- [ ] Project opens in Godot 4.x editor without errors
- [ ] Running the project shows a window (even if blank/placeholder)
- [ ] No error messages in the Output panel on startup
- [ ] All 11 autoloads visible in the scene tree (Remote tab while running)

### DataManager Validation
- [ ] `DataManager.get_config()` returns a dictionary with all expected keys (`xp_curve_exponent`, `base_xp_per_level`, etc.)
- [ ] `DataManager.get_all_enemies()` returns exactly 3 enemies
- [ ] `DataManager.get_enemy("melee_rat")` returns the Cave Rat with health 50, damage 8
- [ ] `DataManager.get_enemy("ranged_crab")` returns the Spitter Crab
- [ ] `DataManager.get_enemy("crab_king")` returns the Crab King boss
- [ ] `DataManager.get_all_items()` returns exactly 10 items
- [ ] `DataManager.get_item("damage_ring")` returns Rusty Ring with +10% damage
- [ ] `DataManager.get_all_skills()` returns exactly 15 skill nodes
- [ ] Skills are split: 5 combat, 5 economy, 5 personality
- [ ] `DataManager.get_loot_table("basic_dungeon_loot")` returns valid drop table with weights
- [ ] `DataManager.get_all_dungeons()` returns exactly 2 dungeons
- [ ] `DataManager.get_dungeon("crab_cave")` is type "story" with replayable = false
- [ ] `DataManager.get_dungeon("abandoned_tunnel")` is type "replayable"
- [ ] `DataManager.get_all_missions()` returns exactly 5 missions
- [ ] Mission chain: tutorial → papers → delivery → crab_cave → rent (verify `next_mission_id`)
- [ ] `DataManager.get_delivery_jobs()` returns 1 job with base_reward 50

### SceneManager
- [ ] SceneManager can load `TestPlayground.tscn`
- [ ] SceneManager emits `scene_changed` signal
- [ ] Only one gameplay scene is active at a time
- [ ] GameState.current_scene_type updates on scene change

### Manager Stubs
- [ ] Each stub manager loads without errors
- [ ] Each stub has its public API methods defined (they can be empty/return defaults)
- [ ] No manager depends on another manager's implementation (stubs are independent)

### Data Integrity
- [ ] Every `enemy_id` in `dungeons.json` rooms exists in `enemies.json`
- [ ] Every `loot_table_id` in `enemies.json` exists in `loot_tables.json`
- [ ] Every `item_id` in `loot_tables.json` exists in `items.json`
- [ ] Every `next_mission_id` in `missions.json` exists (or is null)
- [ ] Every skill `requirements` ID in `skills.json` exists
- [ ] No duplicate IDs across any JSON file

### JSON Value Verification (spot checks against blueprint)
- [ ] `global_config.json`: `xp_curve_exponent` = 1.5, `base_xp_per_level` = 100
- [ ] `global_config.json`: `base_weekly_rent` = 250, `max_player_level_demo` = 5
- [ ] `global_config.json`: `dungeon_scaling_per_completion` = 0.15
- [ ] Player base stats: health 100, stamina 100, damage 10, move_speed 120
- [ ] Cave Rat: health 50, damage 8, xp_reward 10, money_drop 5-10
- [ ] Crab King: type "boss", xp_reward 150, money_drop 150-250
- [ ] Crab Cave: 2 combat rooms + 1 boss room, replayable = false
- [ ] Abandoned Tunnel: type "replayable", rooms use randomized groups
- [ ] Blood Pendant: +15% damage, -5% dodge (rare item)
- [ ] Golden Idol: +10% all stats (rare item)

---

## Common Tasks After Phase 0

| I want to... | Do this |
|---|---|
| Test if data loads | Run the project, check Output panel for DataManager prints |
| Verify an enemy definition | `print(DataManager.get_enemy("melee_rat"))` in any `_ready()` |
| Change XP curve | Edit `xp_curve_exponent` in `global_config.json`, re-run |
| Add a test enemy | Add entry to `enemies.json`, add to a loot table, reference in a dungeon room |
| Check scene switching | Call `SceneManager.change_scene("res://scenes/TestPlayground.tscn")` |
| See all autoloads | Run game → Remote tab in Scene dock → look under root |
