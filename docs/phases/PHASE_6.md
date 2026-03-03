# Phase 6: Save/Load + Game Flow

**Goal:** Full save/load serialization system, main menu screen, death screen with player choice, enhanced pause menu with save/load/quit, and proper game flow from launch to gameplay to death and back.

**Depends on:** Phase 5 (all managers with save/load stubs, overworld, missions, time)

---

## What This Phase Delivers

- Fully implemented `SaveManager` — collects state from all managers, serializes to JSON at `user://save_data.json`, restores on load, applies death penalty on demand
- `MainMenu` scene — New Game, Continue, Quit buttons; shown on launch; Continue refreshes each time menu is shown
- `GameOverScreen` scene — shown on player death with 3 options: Continue (penalty + overworld), Load Most Recent, Main Menu
- Enhanced `PauseMenu` — Save Game, Load Game, Main Menu, Resume buttons
- Updated `Main.gd` — starts with MainMenu instead of TestPlayground
- Death penalty deferred to GameOverScreen — only applied if player chooses "Continue"
- Debug Menu save/load buttons for testing
- Full Python test suite and GDScript runtime test suite

---

## File Map

```
scripts/
├── managers/
│   ├── save_manager.gd              # REWRITTEN — full save/load + new_game + apply_death_penalty
│   └── dungeon_manager.gd           # UPDATED — fail_dungeon no longer applies penalty or exits
├── ui/
│   ├── main_menu.gd                 # NEW — main menu screen with refresh()
│   ├── game_over_screen.gd          # NEW — death screen with 3 options
│   ├── pause_menu.gd                # REWRITTEN — save/load/main menu buttons
│   └── debug_menu.gd                # UPDATED — save/load category
├── main.gd                          # UPDATED — starts with MainMenu
├── dungeon_scene.gd                 # UPDATED — shows death screen on player death
└── ui_manager.gd                    # REWRITTEN — MainMenu/GameOverScreen lifecycle

scenes/
├── ui/
│   ├── MainMenu.tscn                # NEW — main menu scene
│   └── GameOverScreen.tscn          # NEW — death screen scene
└── Main.tscn                        # EXISTING — no .tscn changes needed

tests/
├── test_phase6_json.py              # Python: save schema, scene, script validation
├── test_phase6_runtime.gd           # GDScript: save/load round-trip, death penalty
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
  "players": { "1": { "level": 3, "xp": 450, ... } },
  "economy": { "1": 320 },
  "inventory": { "1": ["damage_ring"] },
  "dungeons": { "crab_cave": 1 },
  "missions": { "mission_states": {}, "objective_status": {}, "current_mission_id": "" },
  "time": { "current_day": 3, "is_daytime": true, "elapsed": 42.5 }
}
```

- `save_game()` — collects from all managers, writes JSON; blocked during dungeon
- `load_game()` — reads JSON, distributes to each manager, changes scene
- `new_game()` — resets all managers, loads OverworldScene, starts tutorial
- `apply_death_penalty()` — deducts money and removes items per global_config
- `has_save()` / `delete_save()` — file existence check and removal

### MainMenu

- Shown on game launch (replaces TestPlayground as default)
- **New Game** — deletes save, resets all managers, loads OverworldScene
- **Continue** — loads save; disabled if no save; **refreshes every time menu is shown**
- **Quit** — exits game

### GameOverScreen (Death Screen)

- Shown when player dies in dungeon (replaces auto-return to overworld)
- **Continue** — applies death penalty (lose money + items), returns to OverworldScene
- **Load Most Recent** — loads last save file (no penalty)
- **Main Menu** — returns to main menu (no penalty)
- Game is paused while death screen is visible

### Enhanced PauseMenu

- **Resume** — unpause
- **Save Game** — calls SaveManager.save_game(); disabled during dungeons
- **Load Game** — calls SaveManager.load_game(); disabled if no save
- **Main Menu** — returns to main menu

### Death Flow (Changed from Phase 4)

Previous flow: die → penalty applied → auto-return to overworld
New flow: die → 1s delay → dungeon cleanup (no penalty) → GameOverScreen → player chooses

- `DungeonManager.fail_dungeon()` now only cleans up dungeon state
- Death penalty moved to `SaveManager.apply_death_penalty()` called by UIManager
- `dungeon_scene._on_player_died()` calls `fail_dungeon()` then `show_game_over()`

---

## Testing

### Python Data Validation
```bash
python3 tests/test_phase6_json.py
```

Validates:
- global_config death penalty fields
- SaveManager function signatures and save schema keys
- All manager get_save_data/load_save_data presence
- Scene and script file existence
- MainMenu/GameOverScreen/PauseMenu signal presence
- UIManager integration (death flow, refresh calls)
- Debug Menu save/load category
- DungeonManager no longer applies penalty

### GDScript Runtime Tests
```
godot --headless --path . --scene tests/TestPhase6Runtime.tscn
```

Tests:
- SaveManager existence and methods (including apply_death_penalty)
- All manager save/load round-trips
- Save file creation and JSON validity
- State restoration after load
- New game resets all state
- has_save/delete_save lifecycle
- Death penalty reduces money and removes items correctly

---

## How to Test Manually

1. Run the game — Main Menu appears
2. Click **New Game** — loads OverworldScene with fresh state + tutorial mission
3. Play normally: complete missions, earn money, enter dungeons
4. Press **ESC** → **Save Game** to save progress
5. Press **ESC** → **Main Menu** to return to title screen
6. Click **Continue** on Main Menu (button is now enabled) to resume from save
7. Enter a dungeon, die → **Death Screen** appears with 3 options
8. Choose **Continue** to respawn at overworld with penalty, **Load Most Recent** to reload save, or **Main Menu**
9. Press **F3** → Debug Menu has Save/Load buttons for quick testing
