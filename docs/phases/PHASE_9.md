# PHASE 9 — Integration Testing + Balance Pass

## Goal

Validate that all 9 phases work together as a cohesive system. Cross-reference every data file, verify balance math, confirm no orphan references, and ensure the full game loop (new game → overworld → dungeon → boss → rent) functions end-to-end.

---

## Deliverables

### 1. Cross-System Integration Tests (test_phase9_integration.py)

**182 static checks** covering 8 categories:

1. **Cross-Data Referential Integrity** — Every enemy references a valid loot table, every loot table references valid items, every dungeon references valid enemies, mission chains are unbroken, skill prerequisites exist, cutscene triggers reference valid missions.

2. **Balance Math Validation** — XP curve is monotonically increasing and within reasonable bounds, player stats at max level are balanced, enemy HP vs player damage produces fair fight lengths, boss is challenging but beatable, economy supports rent payments, death penalty is not catastrophic, item effects respect the 25% cap.

3. **Content Completeness** — Verifies all demo content from DEMO_CONTENT_BLUEPRINT.md exists: 3 enemies + 1 boss, 10 items, 15 skills (5/5/5 split), 2 dungeons, 5 missions, 4 cutscenes, 2 loot tables.

4. **Script Cross-System References** — All 16 key scripts and 7 key scenes exist, SaveManager initializes single-player peer mapping, SceneManager calls AudioManager, UIManager wires SFX to events, CutscenePlayer pauses TimeManager.

5. **Orphan Detection** — Every item appears in at least one loot table, every enemy appears in at least one dungeon, mission chain has exactly one start and one terminal node.

6. **Crab Cave Dungeon Validation** — 2 combat rooms + 1 boss room, boss is Crab King.

7. **Autoload Registration** — All 11 autoloads registered in project.godot.

8. **Loot Table Weight Sanity** — All weights are positive, totals are non-zero.

### 2. Runtime Integration Tests (test_phase9_runtime.gd)

Tests the full game systems running in the Godot engine:

- All 11 autoloads accessible
- DataManager loads all data (3 enemies, 10 items, 15 skills, 2 dungeons, 5 missions)
- New game player setup (level 1, 0 XP, correct base stats)
- XP and leveling (level 1→5, 4 skill points, XP curve)
- Economy flow (add money, pay rent, insufficient funds rejection)
- Inventory with stat effects (equip item → stat boost → remove → stat reverts)
- Dungeon scaling (completion increments difficulty)
- Combat damage formula (weighted drop resolution)
- Mission chain (start → complete objectives → auto-progress to next)
- TimeManager flow (start, pause, night, day advance)
- AudioManager integration (BGM, SFX, volume)
- Save/load roundtrip (save state → reset → load → verify restoration)

### 3. Balance Pass

All balance numbers verified against design constraints:

| Metric | Value | Target Range | Status |
|--------|-------|-------------|--------|
| XP Level 1→2 | 100 | 50-200 | OK |
| XP Level 4→5 | 1118 | 500-2000 | OK |
| Max HP (Level 5) | 120 | 110-200 | OK |
| Max Damage (Level 5) | 10.8 | 10-20 | OK |
| Cave Rat TTK (Level 1) | 5 hits | 2-15 | OK |
| Crab King TTK (Level 5) | 46 hits | 25-80 | OK |
| Boss kills player in | 5 hits | 3-15 | OK |
| Deliveries for rent | 5 | 3-10 | OK |
| Crab Cave total money | ~285 | 50-400 | OK |
| Death money loss | 10% | 5-20% | OK |
| Day length | 15 min | 10-20 | OK |
| Night length | 7 min | 5-10 | OK |
| Item effect cap | ≤25% | ≤25% | OK |
| Difficulty scaling cap | 3.0x | 2.0-5.0x | OK |

### 4. Phase 8 Test Fix

- Fixed missing `sys` import in `test_phase8_json.py`
- Updated VisualEffects tests to match refactored Node base class

---

## File Map

```
tests/
├── test_phase9_integration.py    # NEW — 182 cross-system checks
├── test_phase9_runtime.gd        # NEW — runtime integration tests
└── TestPhase9Runtime.tscn        # NEW — test scene
```

---

## Running All Tests

```bash
# Run all static tests (Phases 0-9)
for f in tests/test_phase*_json.py tests/test_phase9_integration.py; do
    python3 "$f"
done

# Run runtime tests in Godot
# Open project → change main scene to TestPhase9Runtime.tscn → F5
```

---

## Acceptance Criteria

- [x] All Phase 0-8 static tests pass (0 failures across ~900 checks)
- [x] Phase 9 integration tests pass (182/182)
- [x] Phase 9 runtime tests cover full game loop
- [x] Balance numbers are within design spec ranges
- [x] No orphan data references
- [x] No broken mission/skill/loot chains
- [x] All 11 autoloads registered
- [x] Save/load roundtrip preserves all state
