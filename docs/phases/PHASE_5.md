# Phase 5: Overworld, Missions, Time, Delivery, Debug Menu

**Goal:** Fully functional overworld with NPCs, mission system with objective tracking and reward chains, day/night time cycle, delivery mini-game, and a categorized debug menu replacing all hotkey-based debug inputs.

**Depends on:** Phase 4 (DungeonManager, scaling, combat system)

---

## What This Phase Delivers

- Fully implemented `TimeManager` — day/night cycle with configurable durations, weekly rent triggers, pause/resume, debug helpers
- Fully implemented `MissionManager` — mission start/complete/fail lifecycle, objective tracking by type, reward granting, auto-chain to next mission
- `OverworldScene` — Bay Campus map with 4 NPCs, 5 locations, interact system, camera follow, dungeon entrances, delivery board
- `Minigame_Delivery` — bird's-eye delivery driving mini-game with delivery points, money rewards per point
- `DebugMenu` — categorized panel (Player, Combat, Economy, Time, Missions, Scenes) replacing all F-key hotkeys
- Updated `UIManager` — mission tracker (top-right), time display (top-center), debug menu toggle (F3), mission signals
- Updated `HUD` — time of day display
- Updated `TestPlayground` — stripped all hotkey handlers, now only uses Debug Menu via F3
- Mission data: 5 story missions chained tutorial → papers → first delivery → crab cave → pay rent
- Full Python test suite (130 tests) and GDScript runtime test suite

---

## File Map

```
scripts/
├── managers/
│   ├── time_manager.gd             # REWRITTEN — full day/night cycle implementation
│   └── mission_manager.gd          # REWRITTEN — full mission lifecycle
├── ui/
│   └── debug_menu.gd               # NEW — categorized debug panel
├── overworld_scene.gd              # NEW — Bay Campus overworld
├── minigame_delivery.gd            # NEW — delivery mini-game
├── ui_manager.gd                   # UPDATED — mission tracker, time display, debug menu
└── test_playground.gd              # UPDATED — hotkeys removed, debug menu only

scenes/
├── OverworldScene.tscn             # NEW — overworld scene
├── Minigame_Delivery.tscn          # NEW — delivery mini-game scene
└── ui/
    └── DebugMenu.tscn              # NEW — debug menu panel

tests/
├── test_phase5_json.py             # Python: 130 checks — missions, delivery, time, cross-refs
├── test_phase5_runtime.gd          # GDScript: TimeManager, MissionManager, economy, save/load
└── TestPhase5Runtime.tscn          # Runtime test scene
```

---

## System Details

### TimeManager

- **Day length:** 15 minutes (configurable via `day_length_minutes` in global_config.json)
- **Night length:** 7 minutes (configurable via `night_length_minutes`)
- **Normalized time:** 0.0–0.5 = day, 0.5–1.0 = night
- **Weekly rent:** Emits `week_ended` signal every 7 days
- **Pause/resume:** Pauses during dungeons, cutscenes; resumes in overworld
- **Debug helpers:** `advance_to_next_day()`, `advance_to_night()`
- **Time display:** "Day X — Morning/Afternoon/Evening/Night"

### MissionManager

- **States:** NOT_STARTED, ACTIVE, COMPLETED, FAILED
- **Objective types:** talk_to_npc, enter_dungeon, collect_item, return_home, deliver_item, reach_location
- **Notify system:** `notify_talk_to_npc(npc_id)`, `notify_reach_location(location_id)`, etc.
- **Auto-chain:** On completion, automatically starts `next_mission_id`
- **Rewards:** Grants money, XP, and items on mission completion
- **Mission tracker:** Real-time objective checklist in UIManager (top-right)

### Mission Chain (Demo)

| # | ID | Name | Objectives | Rewards |
|---|---|---|---|---|
| 1 | mission_tutorial | Move In | Talk to Hannan, Reach player house | 50 money, 50 XP |
| 2 | mission_papers | Find Papers | Talk to Lewis, Return home | 0 money, 100 XP |
| 3 | mission_first_delivery | First Delivery | Talk to Luka, Complete delivery | 50 money, 150 XP |
| 4 | mission_crab_cave | Enter Crab Cave | Enter crab_cave dungeon | 100 money, 200 XP |
| 5 | mission_pay_rent | Pay Rent | Reach rent_box | 0 money, 100 XP |

**Total mission rewards:** 200 money, 600 XP

### OverworldScene

- **NPCs:** Hannan, Lewis, Luka, Jack (with interact areas)
- **Locations:** Player house, Rent box, Crab Cave entrance, Abandoned Tunnel entrance, Delivery board
- **Map size:** 2560×1440 with camera follow and boundary walls
- **Interaction:** E key to talk/interact within range

### Delivery Mini-Game

- **View:** Bird's-eye driving map with road grid
- **Mechanic:** Drive to numbered delivery points, earn money per point
- **Reward:** `base_delivery_reward × (1 + skill bonuses)` per delivery point
- **Demo job:** 3 delivery points, $50 each, no time limit, no risk

### Debug Menu (Replaces Hotkeys)

Toggle with **F3**. Grouped by category:

- **Player:** +XP, Level Up, Heal, Damage, Kill, Give Item, Clear Inventory
- **Combat:** Spawn enemies (Rat, Crab, Boss), Clear all enemies
- **Economy:** +100/+500/+2000 Money, Pay Rent
- **Time:** Start/Pause time, Skip to night, Skip to next day
- **Missions:** Start any mission, Complete current objective
- **Scenes:** Navigate to Overworld, Playground, Dungeons, Delivery

Categories are collapsible by clicking the header.

---

## Testing

### Python Data Validation (130 tests)
```bash
python3 tests/test_phase5_json.py
```

Validates:
- Mission data integrity and field completeness
- Mission chain correctness (5-mission linked list)
- Objective type validity and cross-references
- Mission reward values and totals
- Delivery job fields and config matching
- Time system config (day/night within GDD ranges)
- Rent system config
- Cross-references between missions, dungeons, delivery jobs, NPCs
- Demo content blueprint compliance

### GDScript Runtime Tests
```
godot --headless --path . --scene tests/TestPhase5Runtime.tscn
```

Tests:
- TimeManager existence, lifecycle, day/night transitions, time strings
- MissionManager existence, lifecycle, chain auto-advance
- Objective completion via notify system
- Mission reward granting (money + XP)
- Delivery economy calculations
- Rent/time integration
- Save/load data persistence for both managers

---

## How to Test Manually

1. Run the game — loads TestPlayground by default
2. Press **F3** to open the Debug Menu
3. Under **Scenes**, click "Go to Overworld" to enter Bay Campus
4. Walk with WASD, press **E** near NPCs to interact
5. Mission tracker appears top-right showing current objectives
6. Time display shows current day/period at top-center
7. Walk to Delivery Board and interact to start a delivery
8. Walk to dungeon entrances and interact to enter dungeons
9. Use Debug Menu to test any system in any combination
