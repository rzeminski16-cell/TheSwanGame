# Phase 4: Dungeon System — Rooms, Waves, Boss, Scaling

**Goal:** Full dungeon lifecycle with room-by-room progression, enemy wave spawning, boss fights, per-completion scaling, death penalty, and a combat arena scene.

**Depends on:** Phase 3 (SkillManager, EconomyManager, UIManager, CombatManager)

---

## What This Phase Delivers

- Fully implemented `DungeonManager` — dungeon start/complete/fail lifecycle, room progression, scaling formulas, completion tracking, death penalty
- `DungeonScene` — combat arena with walls, player spawning, room/dungeon UI labels, player death handling
- `DungeonScene.tscn` — scene file for the dungeon arena
- Updated `UIManager` — dungeon start/complete/fail notification toasts
- Updated TestPlayground with dungeon entry debug keys (F9 = Crab Cave, 1 = Abandoned Tunnel)

---

## File Map

```
scripts/
├── managers/
│   └── dungeon_manager.gd          # UPDATED — full dungeon lifecycle, scaling, death penalty
└── dungeon_scene.gd                # NEW — combat arena with walls and room UI

scenes/
└── DungeonScene.tscn               # NEW — dungeon arena scene

scripts/
├── ui_manager.gd                   # UPDATED — dungeon notification signal handlers
└── test_playground.gd              # UPDATED — F9/1 dungeon entry keys

tests/
├── test_phase4_json.py             # Python: 93 checks — dungeon data, scaling, loot, death penalty
├── test_phase4_runtime.gd          # GDScript: ~35 checks — DungeonManager API, scaling, save/load
└── TestPhase4Runtime.tscn          # Scene for runtime tests
```

---

## Developer Guide

### How the Dungeon System Works

`DungeonManager` is an autoload singleton that orchestrates the full dungeon lifecycle. It reads dungeon definitions from `dungeons.json` via DataManager.

**Dungeon flow:**
```
1. Player triggers dungeon entry (e.g. F9 in TestPlayground)
2. DungeonManager.start_dungeon(dungeon_id):
   a. Validates dungeon exists and isn't a completed story dungeon
   b. Stores return scene path
   c. Calculates scaling (replayable dungeons only)
   d. Updates GameState (is_in_dungeon, dungeon_scaling_data)
   e. Pauses TimeManager
   f. Loads DungeonScene via SceneManager
3. DungeonScene._ready():
   a. Builds arena walls (StaticBody2D, collision layer 1)
   b. Spawns player at bottom center (640, 500), heals to full
   c. Connects to DungeonManager signals
   d. After 0.5s delay, calls DungeonManager.start_next_room()
4. Room loop (DungeonManager._process):
   a. start_next_room() spawns enemies via CombatManager
   b. Monitors CombatManager.get_active_enemy_count() == 0
   c. On room clear: 1.5s delay → next room or complete
5. After last room cleared → DungeonManager.complete_dungeon():
   a. Increments completion count
   b. Exits to previous scene
6. On player death → DungeonManager.fail_dungeon():
   a. Applies death penalty (10% money + 1 random item)
   b. Clears remaining enemies
   c. Exits to previous scene
```

### Dungeon Types

| Type | Example | Replayable | Scales | Boss |
|------|---------|------------|--------|------|
| Story | Crab Cave | No (once only) | No | Yes (Crab King) |
| Replayable | Abandoned Tunnel | Yes | Yes | No |

### Room Types

- **combat** — Spawns enemy groups via `CombatManager.spawn_wave()`
- **boss** — Spawns boss enemy at top center + optional adds

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
```
difficulty = min(1.0 + 5 × 0.15, 3.0) = 1.75
health = 1.0 + 5 × 0.12 = 1.60
damage = 1.0 + 5 × 0.08 = 1.40
count = 1.0 + 5 × 0.10 = 1.50
loot = 1.0 + 5 × 0.10 = 1.50
```

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

### How to Enter a Dungeon Programmatically

```gdscript
# Start a dungeon
var success = DungeonManager.start_dungeon("crab_cave")

# Check dungeon state
DungeonManager.is_dungeon_active()         # → true/false
DungeonManager.get_active_dungeon_id()     # → "crab_cave"
DungeonManager.get_current_room_index()    # → 0, 1, 2...
DungeonManager.get_total_rooms()           # → 3

# Check completion
DungeonManager.get_completion_count("abandoned_tunnel")  # → 0, 1, 2...
DungeonManager.is_dungeon_completed("crab_cave")         # → true/false

# Get scaling for a dungeon
DungeonManager.get_scaling("abandoned_tunnel")
# → { difficulty_multiplier: 1.15, enemy_health_multiplier: 1.12, ... }
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

### Save/Load

```gdscript
# Get save data (completion counts)
var data = DungeonManager.get_save_data()
# → { "crab_cave": 1, "abandoned_tunnel": 7 }

# Load save data
DungeonManager.load_save_data(data)
```

### How to Add a New Dungeon

1. Add dungeon definition to `data/dungeons.json`:
```json
{
    "id": "new_dungeon",
    "display_name": "New Dungeon",
    "type": "replayable",
    "base_difficulty": 2,
    "replayable": true,
    "rooms": [
        {
            "room_type": "combat",
            "enemy_groups": [
                { "enemy_id": "melee_rat", "count": 4 }
            ]
        }
    ]
}
```
2. All enemy IDs must exist in `data/enemies.json`
3. Boss rooms use `"room_type": "boss"` with an `"enemy_id"` field
4. Optionally add a debug key in `test_playground.gd`

---

## Testing

### Automated Test Scripts

#### 1. Python Dungeon Data Validation (no Godot required)

```bash
python3 tests/test_phase4_json.py
```

**Tests: 93 checks.** What it covers:
- Dungeon data integrity (required fields, correct types)
- Room structure validation (room types, enemy groups, boss rooms)
- Enemy reference validation (all enemy IDs exist in enemies.json)
- Scaling formula validation (per-completion multipliers, difficulty cap)
- Enemy scaling math (rat/boss stats at various completion counts)
- Loot table references (basic_dungeon_loot, boss_loot, enemy loot tables)
- Death penalty config (money_loss_percent, item_loss_count, penalty math)
- Demo content blueprint compliance (2 dungeons, story/replayable types)

#### 2. GDScript Runtime Tests (requires Godot)

```bash
godot --headless --path . --scene tests/TestPhase4Runtime.tscn
```

**Tests: ~35 checks.** What it covers:
- DungeonManager singleton existence and API methods
- Scaling formula correctness at various completion counts
- Difficulty multiplier cap at 3.0
- Completion count tracking and persistence
- Dungeon data loading and queries
- Story dungeon single-completion guard
- Death penalty config validation
- Save/load data round-trip

### Manual Testing Checklist (Human Required)

- [ ] Run TestPlayground — F9 enters Crab Cave
- [ ] Crab Cave: dungeon name label at top center, room counter visible
- [ ] Room 1: 5 rats spawn in arena center area
- [ ] Killing all rats → "Room Cleared!" → 1.5s delay → Room 2
- [ ] Room 2: 3 rats + 2 crabs spawn
- [ ] Room 3: boss room — "BOSS FIGHT!" notification, Crab King spawns
- [ ] Defeating Crab King → "Dungeon Complete!" → returns to TestPlayground
- [ ] F9 again → cannot re-enter Crab Cave (story dungeon, completed)
- [ ] Press 1 → enters Abandoned Tunnel
- [ ] 3 combat rooms, no boss
- [ ] Complete → returns to TestPlayground
- [ ] Press 1 again → can re-enter (replayable dungeon)
- [ ] Second run: enemies should be slightly tougher (scaled)
- [ ] Walls contain player and enemies within the arena
- [ ] Player death in dungeon → "You died! Penalty applied..." notification
- [ ] Death penalty: money reduced by 10%, 1 random item lost
- [ ] After death: returns to TestPlayground
- [ ] UIManager notifications appear for dungeon start/complete/fail
- [ ] HUD remains visible during dungeon
