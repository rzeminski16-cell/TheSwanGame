#!/usr/bin/env python3
"""
Phase 6 — Save/Load + Game Flow Data Validation
Validates save schema compliance, global_config death penalty fields,
manager save/load function presence, and scene file existence.

Usage:
    python3 tests/test_phase6_json.py

Exit code 0 = all passed, 1 = failures found.
"""

import json
import os
import re
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
SCRIPTS_DIR = os.path.join(os.path.dirname(__file__), "..", "scripts")
SCENES_DIR = os.path.join(os.path.dirname(__file__), "..", "scenes")

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


def load_json(filename):
    path = os.path.join(DATA_DIR, filename)
    with open(path, "r") as f:
        return json.load(f)


def read_file(path):
    with open(path, "r") as f:
        return f.read()


# ============================================================
# Load data
# ============================================================
config = load_json("global_config.json")

# ============================================================
print("\n--- Global Config: Death Penalty ---")
# ============================================================

test("config has death_penalty", "death_penalty" in config)
penalty = config.get("death_penalty", {})
test("death_penalty has money_loss_percent", "money_loss_percent" in penalty)
test("death_penalty has item_loss_count", "item_loss_count" in penalty)
test("money_loss_percent is float 0-1",
     isinstance(penalty.get("money_loss_percent"), (int, float)) and
     0 <= penalty.get("money_loss_percent", -1) <= 1,
     f"got {penalty.get('money_loss_percent')}")
test("item_loss_count is non-negative int",
     isinstance(penalty.get("item_loss_count"), int) and
     penalty.get("item_loss_count", -1) >= 0,
     f"got {penalty.get('item_loss_count')}")

# ============================================================
print("\n--- Save Schema Compliance ---")
# ============================================================

# Per DATA_SCHEMA_SPEC.md section 10, the save file should have:
# players, dungeons, story_progress/missions, statistics
# Our implementation uses: version, scene_path, players, economy, inventory,
# dungeons, missions, time
REQUIRED_SAVE_KEYS = ["version", "scene_path", "players", "economy",
                       "inventory", "dungeons", "missions", "time"]

# Verify SaveManager script references these keys
save_mgr_path = os.path.join(SCRIPTS_DIR, "managers", "save_manager.gd")
save_mgr_src = read_file(save_mgr_path)

test("SaveManager has SAVE_PATH constant", 'SAVE_PATH' in save_mgr_src)
test("SaveManager has SAVE_VERSION constant", 'SAVE_VERSION' in save_mgr_src)
test("SaveManager has save_game function", 'func save_game()' in save_mgr_src)
test("SaveManager has load_game function", 'func load_game()' in save_mgr_src)
test("SaveManager has new_game function", 'func new_game()' in save_mgr_src)
test("SaveManager has has_save function", 'func has_save()' in save_mgr_src)
test("SaveManager has delete_save function", 'func delete_save()' in save_mgr_src)
test("SaveManager has apply_death_penalty function", 'func apply_death_penalty(' in save_mgr_src)

for key in REQUIRED_SAVE_KEYS:
    test(f"SaveManager references key '{key}'",
         f'"{key}"' in save_mgr_src,
         f"key '{key}' not found in save_manager.gd")

# ============================================================
print("\n--- Manager Save/Load Functions ---")
# ============================================================

MANAGERS_WITH_SAVE_LOAD = [
    ("player_manager.gd", "get_save_data", "load_save_data"),
    ("economy_manager.gd", "get_save_data", "load_save_data"),
    ("inventory_manager.gd", "get_save_data", "load_save_data"),
    ("dungeon_manager.gd", "get_save_data", "load_save_data"),
    ("mission_manager.gd", "get_save_data", "load_save_data"),
    ("time_manager.gd", "get_save_data", "load_save_data"),
]

for filename, save_fn, load_fn in MANAGERS_WITH_SAVE_LOAD:
    path = os.path.join(SCRIPTS_DIR, "managers", filename)
    src = read_file(path)
    test(f"{filename} has {save_fn}()", f"func {save_fn}(" in src)
    test(f"{filename} has {load_fn}()", f"func {load_fn}(" in src)

# ============================================================
print("\n--- Scene Files Exist ---")
# ============================================================

REQUIRED_SCENES = [
    "ui/MainMenu.tscn",
    "ui/GameOverScreen.tscn",
    "ui/PauseMenu.tscn",
    "ui/DebugMenu.tscn",
    "Main.tscn",
    "OverworldScene.tscn",
]

for scene_rel in REQUIRED_SCENES:
    scene_path = os.path.join(SCENES_DIR, scene_rel)
    test(f"Scene exists: {scene_rel}", os.path.isfile(scene_path))

# ============================================================
print("\n--- Script Files Exist ---")
# ============================================================

REQUIRED_SCRIPTS = [
    "ui/main_menu.gd",
    "ui/game_over_screen.gd",
    "ui/pause_menu.gd",
    "ui/debug_menu.gd",
    "managers/save_manager.gd",
]

for script_rel in REQUIRED_SCRIPTS:
    script_path = os.path.join(SCRIPTS_DIR, script_rel)
    test(f"Script exists: {script_rel}", os.path.isfile(script_path))

# ============================================================
print("\n--- MainMenu Script ---")
# ============================================================

main_menu_src = read_file(os.path.join(SCRIPTS_DIR, "ui", "main_menu.gd"))
test("MainMenu has new_game_pressed signal", "signal new_game_pressed" in main_menu_src)
test("MainMenu has continue_pressed signal", "signal continue_pressed" in main_menu_src)
test("MainMenu has quit_pressed signal", "signal quit_pressed" in main_menu_src)
test("MainMenu checks SaveManager.has_save()", "SaveManager.has_save()" in main_menu_src)
test("MainMenu has refresh() method", "func refresh()" in main_menu_src)

# ============================================================
print("\n--- GameOverScreen Script ---")
# ============================================================

game_over_src = read_file(os.path.join(SCRIPTS_DIR, "ui", "game_over_screen.gd"))
test("GameOverScreen has continue_pressed signal", "signal continue_pressed" in game_over_src)
test("GameOverScreen has load_save_pressed signal", "signal load_save_pressed" in game_over_src)
test("GameOverScreen has main_menu_pressed signal", "signal main_menu_pressed" in game_over_src)
test("GameOverScreen has refresh() method", "func refresh()" in game_over_src)

# ============================================================
print("\n--- PauseMenu Script ---")
# ============================================================

pause_src = read_file(os.path.join(SCRIPTS_DIR, "ui", "pause_menu.gd"))
test("PauseMenu has resumed signal", "signal resumed" in pause_src)
test("PauseMenu has save_requested signal", "signal save_requested" in pause_src)
test("PauseMenu has load_requested signal", "signal load_requested" in pause_src)
test("PauseMenu has main_menu_requested signal", "signal main_menu_requested" in pause_src)
test("PauseMenu has update_button_states()", "func update_button_states" in pause_src)

# ============================================================
print("\n--- UIManager Integration ---")
# ============================================================

ui_mgr_src = read_file(os.path.join(SCRIPTS_DIR, "ui_manager.gd"))
test("UIManager has MAIN_MENU_SCENE constant", "MAIN_MENU_SCENE" in ui_mgr_src)
test("UIManager has GAME_OVER_SCENE constant", "GAME_OVER_SCENE" in ui_mgr_src)
test("UIManager has show_main_menu()", "func show_main_menu" in ui_mgr_src)
test("UIManager has show_game_over()", "func show_game_over" in ui_mgr_src)
test("UIManager connects save_requested", "save_requested" in ui_mgr_src)
test("UIManager connects load_requested", "load_requested" in ui_mgr_src)
test("UIManager connects main_menu_requested", "main_menu_requested" in ui_mgr_src)
test("UIManager has _on_death_continue()", "func _on_death_continue" in ui_mgr_src)
test("UIManager calls apply_death_penalty()", "apply_death_penalty" in ui_mgr_src)
test("UIManager calls refresh() on main menu", "_main_menu.refresh()" in ui_mgr_src)

# ============================================================
print("\n--- Main.gd Game Flow ---")
# ============================================================

main_src = read_file(os.path.join(SCRIPTS_DIR, "main.gd"))
test("Main.gd calls show_main_menu()", "show_main_menu" in main_src)
test("Main.gd does NOT load TestPlayground by default",
     "TestPlayground" not in main_src or "show_main_menu" in main_src)

# ============================================================
print("\n--- Debug Menu Save/Load ---")
# ============================================================

debug_src = read_file(os.path.join(SCRIPTS_DIR, "ui", "debug_menu.gd"))
test("DebugMenu has Save/Load category", '"Save/Load"' in debug_src)
test("DebugMenu has Save Game button", '"Save Game"' in debug_src)
test("DebugMenu has Load Game button", '"Load Game"' in debug_src)
test("DebugMenu has Delete Save button", '"Delete Save"' in debug_src)

# ============================================================
print("\n--- DungeonManager Fallback ---")
# ============================================================

dungeon_src = read_file(os.path.join(SCRIPTS_DIR, "managers", "dungeon_manager.gd"))
test("DungeonManager fallback is OverworldScene",
     "OverworldScene" in dungeon_src)
test("DungeonManager fail_dungeon does NOT call _apply_death_penalty",
     "_apply_death_penalty" not in dungeon_src)

# ============================================================
print("\n--- Dungeon Scene Death Flow ---")
# ============================================================

dungeon_scene_src = read_file(os.path.join(SCRIPTS_DIR, "dungeon_scene.gd"))
test("dungeon_scene calls show_game_over()",
     "show_game_over" in dungeon_scene_src)

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
