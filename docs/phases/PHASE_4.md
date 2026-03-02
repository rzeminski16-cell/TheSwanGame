# Phase 4: Dungeon System — Rooms, Waves, Boss, Scaling

**Goal:** Full dungeon lifecycle with room-by-room progression, enemy wave spawning, boss encounters, per-completion scaling, death penalty, and scene transitions.

**Depends on:** Phase 2 (CombatManager, enemies), Phase 3 (SkillManager, EconomyManager, UIManager notifications)

---

## What This Phase Delivers

- Fully implemented `DungeonManager` — dungeon lifecycle orchestration, room progression, scaling formulas, completion tracking, death penalty, save/load
- `DungeonScene` — enclosed combat arena with walls, player spawn, room/dungeon name UI, player death handling
- Updated `UIManager` — dungeon notifications (started, completed, failed)
- Updated `TestPlayground` — F9 (Crab Cave) and 1 (Abandoned Tunnel) debug keys for dungeon entry
- Scene file `DungeonScene.tscn` — simple Node2D wrapper

---

## File Map

```
scripts/
├── managers/
│   └── dungeon_manager.gd        # UPDATED — full dungeon lifecycle, scaling, death penalty
├── dungeon_scene.gd              # NEW — combat arena scene logic
├── ui_manager.gd                 # UPDATED — dungeon signal notifications
└── test_playground.gd            # UPDATED — F9 and 1 dungeon entry keys

scenes/
└── DungeonScene.tscn             # NEW — dungeon combat arena

tests/
├── test_phase4_json.py           # Python: 93 checks — dungeon data, scaling, rooms, enemies
├── test_phase4_runtime.gd        # GDScript: ~35 checks — DungeonManager API, scaling, save/load
└── TestPhase4Runtime.tscn        # Scene for runtime tests
```

---

## Developer Guide

### How the Dungeon System Works

`DungeonManager` is an autoload singleton that orchestrates the full dungeon lifecycle. It reads dungeon definitions from `dungeons.json` via DataManager.

**Dungeon flow:**
```
1. Player triggers dungeon entry (debug key or game trigger)
2. DungeonManager.start_dungeon(dungeon_id):
   a. Loads dungeon data from DataManager
   b. Checks story dungeon not already completed
   c. Stores return scene path
   d. Calculates scaling (for replayable dungeons)
   e. Updates GameState (is_in_dungeon, dungeon_scaling_data)
   f. Pauses TimeManager
   g. Changes scene to DungeonScene via SceneManager
   h. Emits dungeon_started signal
3. DungeonScene._ready():
   a. Builds arena walls (StaticBody2D, collision layer 1)
   b. Spawns player at bottom center (640, 500), heals to full
   c. Connects DungeonManager room/dungeon signals
   d. Connects player death signal
   e. After 0.5s delay, calls DungeonManager.start_next_room()
4. DungeonManager.start_next_room():
   a. Advances room index
   b. If all rooms done → complete_dungeon()
   c. Emits room_started(index, total)
   d. Spawns enemies via CombatManager (combat or boss room)
   e. Sets _waiting_for_clear = true
5. DungeonManager._process():
   a. Monitors CombatManager.get_active_enemy_count() == 0
   b. On clear: emits room_cleared, starts 1.5s delay
   c. After delay: start_next_room() or complete_dungeon()
6. DungeonManager.complete_dungeon():
   a. Increments completion count
   b. Resets dungeon state
   c. Resumes TimeManager
   d. Emits dungeon_completed
   e. Returns to previous scene
7. On player death:
   a. DungeonManager.fail_dungeon()
   b. Applies death penalty (money + item loss)
   c. Clears all enemies
   d. Returns to previous scene
```

### Dungeon Types

| Type | Example | Replayable | Scales | Boss |
|------|---------|------------|--------|------|
| Story | Crab Cave | No (once only) | No | Yes (Crab King) |
| Replayable | Abandoned Tunnel | Yes | Yes | No |

### Room Types

- **combat** — Spawns enemy groups via `CombatManager.spawn_wave()`
- **boss** — Spawns boss enemy at top center + optional adds

### Dungeon Data Structure

Dungeons are defined in `data/dungeons.json`:

```json
{
    "id": "crab_cave",
    "display_name": "Crab Cave",
    "type": "story",
    "replayable": false,
    "base_difficulty": 1.0,
    "rooms": [
        {
            "room_type": "combat",
            "enemy_groups": [
                { "enemy_id": "melee_rat", "count": 5 }
            ]
        },
        {
            "room_type": "boss",
            "enemy_id": "crab_king",
            "enemy_groups": []
        }
    ]
}
```

- `type`: "story" (one-time) or "replayable" (scales on repeat)
- `replayable`: Controls whether scaling applies and re-entry is allowed
- `rooms`: Ordered array — each room is either "combat" or "boss"
- `enemy_groups`: Array of `{enemy_id, count}` for wave spawning
- Boss rooms use `enemy_id` for the boss and optional `enemy_groups` for adds

### Scaling Formulas

Scaling applies only to **replayable** dungeons. All values come from `global_config.json`:

```
completion_count = number of times dungeon has been completed

difficulty_multiplier = min(1.0 + count × 0.15, 3.0)   # capped
enemy_health_multiplier = 1.0 + count × 0.12            # uncapped
enemy_damage_multiplier = 1.0 + count × 0.08            # uncapped
enemy_count_multiplier = 1.0 + count × 0.10             # uncapped
loot_quality_multiplier = 1.0 + count × 0.10            # uncapped
```

**Config keys:**
- `dungeon_scaling_per_completion`: 0.15
- `enemy_health_scaling`: 0.12
- `enemy_damage_scaling`: 0.08
- `enemy_spawn_scaling`: 0.10
- `loot_quality_scaling`: 0.10
- `difficulty_multiplier_cap`: 3.0

**Example at completion 5:**
- Difficulty: 1.75 (capped at 3.0 max)
- Health: 1.60 (rat 50 HP → 80 HP)
- Damage: 1.40 (rat 8 dmg → 11.2 dmg)
- Count: 1.50 (5 rats → 8 rats)
- Loot quality: 1.50

### Death Penalty

On dungeon failure (player dies), from `global_config.json → death_penalty`:

| Penalty | Value | Example |
|---------|-------|---------|
| Money loss | 10% of current money | 500 money → lose 50 |
| Item loss | 1 random item removed | Random item from inventory |

```gdscript
# Applied automatically by DungeonManager.fail_dungeon()
var money_lost = roundi(current_money * 0.10)
EconomyManager.deduct_money(1, money_lost)
InventoryManager.remove_random_item(1)
```

### DungeonScene Arena Layout

```
┌─────────────────────────────────────┐
│  [Dungeon Name]  Room X/Y          │ ← Labels (z_index 50)
│                                     │
│  ┌─────────────────────────────┐    │
│  │  ARENA (1120×600)           │    │ ← Dark floor (z_index -10)
│  │  Left: 80  Right: 1200     │    │
│  │  Top: 60   Bottom: 660     │    │
│  │                             │    │
│  │  Enemies spawn at (640,360) │    │ ← Center of arena
│  │  Boss spawns at (640,250)   │    │ ← Top center
│  │                             │    │
│  │  Player spawns at (640,500) │    │ ← Bottom center
│  └─────────────────────────────┘    │
│     Walls: StaticBody2D, layer 1   │
└─────────────────────────────────────┘
```

Wall thickness: 20px. Collision layer 1 (environment).

### Signals

**DungeonManager signals:**
```gdscript
signal dungeon_started(dungeon_id: String)
signal dungeon_completed(dungeon_id: String)
signal dungeon_failed(dungeon_id: String)
signal room_started(room_index: int, total_rooms: int)
signal room_cleared(room_index: int)
```

**UIManager handles:** `dungeon_started`, `dungeon_completed`, `dungeon_failed` — shows notification toasts.

**DungeonScene handles:** `room_started`, `room_cleared`, `dungeon_completed` — updates room counter labels.

### How to Enter a Dungeon Programmatically

```gdscript
# Start a dungeon
var success: bool = DungeonManager.start_dungeon("crab_cave")
# Returns false if: unknown id, story dungeon already completed

# Check state
DungeonManager.is_dungeon_active()       # → true/false
DungeonManager.get_active_dungeon_id()   # → "crab_cave"
DungeonManager.get_current_room_index()  # → 0, 1, 2...
DungeonManager.get_total_rooms()         # → 3

# Query completions
DungeonManager.get_completion_count("abandoned_tunnel")  # → 0, 1, 2...
DungeonManager.is_dungeon_completed("crab_cave")         # → true/false

# Get scaling for a dungeon
DungeonManager.get_scaling("abandoned_tunnel")
# → { difficulty_multiplier: 1.15, enemy_health_multiplier: 1.12, ... }
```

### Save/Load

```gdscript
# Get save data (completion counts)
var data = DungeonManager.get_save_data()
# → { "crab_cave": 1, "abandoned_tunnel": 7 }

# Load save data
DungeonManager.load_save_data(data)
```

### How to Add a New Dungeon

1. Add dungeon entry to `data/dungeons.json`
2. Add room definitions with enemy references (must exist in `enemies.json`)
3. If boss room: add `"room_type": "boss"` and `"enemy_id": "boss_id"`
4. Set `"type"` to "story" or "replayable" and `"replayable"` accordingly
5. Add test cases to `test_phase4_json.py`

### UIManager Dungeon Notifications

UIManager connects to DungeonManager signals and shows notifications:

| Signal | Notification |
|--------|-------------|
| `dungeon_started` | "Entering: [Dungeon Name]" |
| `dungeon_completed` | "Dungeon Complete: [Name]!" |
| `dungeon_failed` | "Dungeon Failed: [Name]" |
| `room_started` (via DungeonScene) | "Room X/Y" or "BOSS FIGHT!" |
| `room_cleared` (via DungeonScene) | "Room Cleared!" or "Dungeon Complete!" |

---

## Testing

### Automated Test Scripts

#### 1. Python Dungeon Data Validation (no Godot required)

```bash
python3 tests/test_phase4_json.py
```

**Tests: 93 checks.** What it covers:
- Dungeon data integrity (2 dungeons, all required fields)
- Room structure validation (room types, enemy groups, boss rooms)
- Enemy reference validation (all referenced enemies exist in enemies.json)
- Scaling formula validation (per-completion multipliers, difficulty cap)
- Enemy scaling math (rat/boss stats at various completion counts)
- Loot table references (basic_dungeon_loot, boss_loot, enemy loot tables)
- Death penalty config (money_loss_percent, item_loss_count, penalty math)
- Demo content blueprint compliance (1 story + 1 replayable, boss room, cap)

#### 2. GDScript Runtime Tests (requires Godot)

```bash
godot --headless --path . --scene tests/TestPhase4Runtime.tscn
```

**Tests: ~35 checks.** What it covers:
- DungeonManager singleton existence and API methods
- Scaling formulas at completions 0, 1, 5 (exact values)
- Scaling cap (difficulty capped at 3.0, health NOT capped)
- Completion count tracking (load, query, unknown dungeon)
- Dungeon data queries (crab_cave rooms, abandoned_tunnel replayable)
- Story dungeon single-completion guard
- Death penalty config values and math
- Save/load data round-trip

### Manual Testing Checklist (Human Required)

- [ ] F9 enters Crab Cave — scene changes to dark arena with walls
- [ ] Dungeon name "Crab Cave" displayed at top center
- [ ] Room counter shows "Room 1/3" then updates as rooms clear
- [ ] Enemies spawn in Room 1 (5 rats)
- [ ] Killing all enemies triggers "Room Cleared!" notification
- [ ] After 1.5s delay, Room 2 starts (3 rats + 2 crabs)
- [ ] Room 3 (boss): "BOSS FIGHT!" notification, room label turns red
- [ ] Crab King spawns at top center
- [ ] Defeating boss → "Dungeon Complete!" → returns to TestPlayground
- [ ] Re-pressing F9 → "Cannot enter dungeon" (story, already completed)
- [ ] 1 enters Abandoned Tunnel — 3 combat rooms, no boss
- [ ] After completing Abandoned Tunnel, pressing 1 again enters it (replayable)
- [ ] Player healed to full on dungeon entry
- [ ] Dying in dungeon → "You died!" notification → death penalty applied
- [ ] Death penalty: money reduced by 10%, 1 item lost (check with F10/F7 beforehand)
- [ ] After death, returns to TestPlayground
- [ ] F12 heals player during dungeon (for testing survivability)
- [ ] Multiple Abandoned Tunnel completions increase scaling (enemies get tougher)
- [ ] Walls contain player and enemies within the arena
- [ ] HUD remains visible during dungeon
