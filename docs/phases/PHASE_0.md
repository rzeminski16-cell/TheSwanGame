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

## Testing

Phase 0 tests are split into **automated** (run via scripts) and **manual** (require a human in the Godot editor).

### Automated Test Scripts

Two test scripts cover all data validation, value correctness, cross-references, autoload existence, manager API availability, and SceneManager functionality.

#### 1. Python JSON Validation (no Godot required)

Validates all 8 JSON data files outside of Godot — structure, required fields, counts, exact values from the blueprint, cross-references, and duplicate ID checks.

```bash
# From project root:
python3 tests/test_phase0_json.py
```

**What it covers (363 checks):**
- All 8 JSON files exist and parse correctly
- Correct counts: 3 enemies, 10 items, 15 skills (5/5/5 split), 2 dungeons, 5 missions, 1 delivery job
- Every value from `global_config.json` matches spec (XP curve, scaling, rent, base stats, soft caps)
- Every enemy stat matches blueprint (Cave Rat, Spitter Crab, Crab King)
- Item rarity, effects, and 25%-cap enforcement
- Skill categories, requirements, max_level
- Dungeon room structure (Crab Cave: 2 combat + 1 boss, Abandoned Tunnel: replayable)
- Mission chain order (tutorial → papers → delivery → crab_cave → rent)
- Loot table weights and item references
- All cross-references valid (enemy→loot_table, loot_table→item, dungeon→enemy, mission→next_mission, skill→requirement)
- No duplicate IDs across all collections

#### 2. GDScript Runtime Tests (requires Godot)

Tests everything that needs the engine running — autoloads in the scene tree, DataManager API calls returning live data, GameState defaults, manager stub methods being callable, SceneManager signals/methods.

```bash
# From command line (headless):
godot --headless --path . --scene tests/TestPhase0Runtime.tscn

# Or from editor:
# Open tests/TestPhase0Runtime.tscn and press F5 (or run scene)
```

**What it covers (~100 checks):**
- All 11 autoload singletons present in the scene tree
- DataManager API returns correct data at runtime (config, enemies, items, skills, loot tables, dungeons, missions, delivery jobs)
- DataManager cross-reference validation produced zero load errors
- GameState default values (is_host=true, player_count=1, is_in_dungeon=false, etc.)
- All stub managers have callable methods returning correct default types
- SceneManager exists under Main, has `change_scene`/`get_current_scene` methods and `scene_changed` signal

---

### Manual Testing Checklist (Human Required)

These tests require visual inspection in the Godot editor and cannot be automated:

#### Editor Verification
- [x] Project opens in Godot 4.x editor without errors in the bottom panel
- [x] No red error messages in the Output panel when the editor loads
- [x] `project.godot` shows all 11 autoloads in Project → Project Settings → Autoload tab
- [x] `scenes/Main.tscn` opens and shows SceneManager, UIManager, AudioManager as children

#### Runtime Visual Verification
- [x] Running the project (F5) opens a game window at 1280x720
- [x] The TestPlayground label text is visible in the window
- [x] Output panel shows DataManager success messages (no red errors)
- [x] Output panel shows "Main: Game starting." followed by correct item/enemy/skill counts
- [x] In the Remote tab (while running), all 11 autoloads are visible under root
- [x] In the Remote tab, Main has SceneManager, UIManager, AudioManager children

#### Input Map Verification
- [x] Project → Project Settings → Input Map shows: move_up (W), move_down (S), move_left (A), move_right (D)
- [x] Input Map shows: interact (E), attack (Left Mouse), ability_1 (Q), ability_2 (R)
- [x] Input Map shows: toggle_inventory (I), toggle_skill_tree (K), pause (Escape)

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
