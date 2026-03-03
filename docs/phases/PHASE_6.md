# Phase 6: Save/Load + Game Flow

**Goal:** Full save/load serialization system, main menu screen, game over screen, enhanced pause menu with save/load/quit, and proper game flow from launch to gameplay to death and back.

**Depends on:** Phase 5 (all managers with save/load stubs, overworld, missions, time)

---

## What This Phase Delivers

- Fully implemented `SaveManager` — collects state from all managers, serializes to JSON at `user://save_data.json`, restores on load
- `MainMenu` scene — New Game, Continue, Quit buttons; shown on launch
- `GameOverScreen` scene — death recap with money/item loss, retry (load last save), return to menu
- Enhanced `PauseMenu` — Save Game, Load Game, Main Menu, Resume buttons
- Updated `Main.gd` — starts with MainMenu instead of TestPlayground
- Death → GameOver flow via player death signal
- Debug Menu save/load buttons for testing
- Full Python test suite and GDScript runtime test suite

---

## File Map

```
scripts/
├── managers/
│   └── save_manager.gd              # REWRITTEN — full save/load implementation
├── ui/
│   ├── main_menu.gd                 # NEW — main menu screen
│   ├── game_over_screen.gd          # NEW — death/game over screen
│   ├── pause_menu.gd                # UPDATED — save/load/main menu buttons
│   └── debug_menu.gd                # UPDATED — save/load buttons in new category
├── main.gd                          # UPDATED — starts with MainMenu
└── ui_manager.gd                    # UPDATED — game over screen management

scenes/
├── ui/
│   ├── MainMenu.tscn                # NEW — main menu scene
│   ├── GameOverScreen.tscn          # NEW — game over scene
│   └── PauseMenu.tscn               # EXISTING — no .tscn changes needed
└── Main.tscn                        # EXISTING — no .tscn changes needed

tests/
├── test_phase6_json.py              # Python: save schema validation
├── test_phase6_runtime.gd           # GDScript: save/load round-trip, game flow
└── TestPhase6Runtime.tscn           # Runtime test scene
```

---

## System Details

### SaveManager

Save file format (`user://save_data.json`):
```json
{
  "version": 1,
  "scene_path": "res://scenes/OverworldScene.tscn",
  "players": {
    "1": {
      "level": 3,
      "xp": 450,
      "skill_points": 0,
      "unlocked_skills": ["combat_damage_1"]
    }
  },
  "economy": {
    "1": 320
  },
  "inventory": {
    "1": ["damage_ring"]
  },
  "dungeons": {
    "crab_cave": { "completion_count": 1 }
  },
  "missions": {
    "mission_states": {},
    "objective_status": {},
    "current_mission_id": "mission_crab_cave"
  },
  "time": {
    "current_day": 3,
    "is_daytime": true,
    "elapsed": 42.5
  },
  "statistics": {
    "total_kills": 0,
    "total_money_earned": 0,
    "total_deaths": 0
  }
}
```

- `save_game()` — collects from PlayerManager, EconomyManager, InventoryManager, DungeonManager, MissionManager, TimeManager; writes JSON
- `load_game()` — reads JSON, distributes to each manager via `load_save_data()`
- `has_save()` — checks if save file exists
- `delete_save()` — removes save file (for New Game)
- Save not allowed during dungeon combat (`GameState.is_in_dungeon`)

### MainMenu

- Shown on game launch (replaces TestPlayground as default)
- **New Game** — deletes existing save, resets all managers, loads OverworldScene
- **Continue** — loads save file, restores scene; disabled if no save exists
- **Quit** — exits game
- Dark themed panel centered on screen

### GameOverScreen

- Shown when player dies (outside mission dungeons)
- Displays death message
- **Load Save** — loads last save file
- **Main Menu** — returns to main menu
- Per GDD: no permanent death in demo, lose some money

### Enhanced PauseMenu

- **Resume** — unpause (existing)
- **Save Game** — calls SaveManager.save_game(); disabled during dungeons
- **Load Game** — calls SaveManager.load_game(); disabled if no save
- **Main Menu** — unpause + return to main menu

### Death Flow

- Player HealthComponent `died` signal → UIManager shows GameOverScreen
- Lose percentage of money (configurable via `death_money_loss_percent` in global_config)
- On retry: load last save

---

## Testing

### Python Data Validation
```bash
python3 tests/test_phase6_json.py
```

Validates:
- Save schema structure matches DATA_SCHEMA_SPEC
- global_config has death penalty fields
- All manager save/load function signatures documented

### GDScript Runtime Tests
```
godot --headless --path . --scene tests/TestPhase6Runtime.tscn
```

Tests:
- SaveManager save/load round-trip
- All manager get_save_data/load_save_data
- Save file creation and deletion
- State restoration after load
- Game flow: new game resets state, load restores state

---

## How to Test Manually

1. Run the game — Main Menu appears
2. Click **New Game** — loads OverworldScene with fresh state
3. Play normally: complete missions, earn money, enter dungeons
4. Press **ESC** → **Save Game** to save progress
5. Press **ESC** → **Load Game** to reload last save
6. Press **ESC** → **Main Menu** to return to title screen
7. Click **Continue** on Main Menu to resume from save
8. If player dies: GameOver screen appears with Load Save / Main Menu options
9. Press **F3** → Debug Menu has Save/Load buttons for quick testing
