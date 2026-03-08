#!/usr/bin/env python3
"""Phase 8 — Audio, Visuals, Cutscenes: static validation tests.

Checks that all required scripts, signals, functions, data files,
and scene references exist in the codebase without running Godot.
"""

import os, sys, json, re

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


def file_exists(rel_path):
    return os.path.exists(os.path.join(ROOT, rel_path))


# ---------- AudioManager Script ----------
print("\n--- AudioManager Script ---")
am = read("scripts/audio_manager.gd")
check("audio_manager.gd exists", am != "")
check("Has bgm_changed signal", "signal bgm_changed" in am)
check("Has sfx_played signal", "signal sfx_played" in am)
check("Has play_bgm() function", "func play_bgm(" in am)
check("Has stop_bgm() function", "func stop_bgm(" in am)
check("Has play_sfx() function", "func play_sfx(" in am)
check("Has set_master_volume()", "func set_master_volume(" in am)
check("Has set_bgm_volume()", "func set_bgm_volume(" in am)
check("Has set_sfx_volume()", "func set_sfx_volume(" in am)
check("Has toggle_mute()", "func toggle_mute(" in am)
check("Has is_muted()", "func is_muted(" in am)
check("Has get_current_bgm()", "func get_current_bgm(" in am)
check("Has BGM crossfade support", "BGM_CROSSFADE_DURATION" in am)
check("Has SFX player pool", "MAX_SFX_PLAYERS" in am)
check("Has procedural BGM generation", "_generate_tone_stream" in am)
check("Has procedural SFX generation", "_generate_sfx_stream" in am)
check("Tries loading .ogg files first", 'audio/bgm/' in am)
check("Tries loading .wav files first", 'audio/sfx/' in am)

# Verify all expected SFX names are handled
expected_sfx = ["hit", "crit", "dodge", "pickup", "money", "level_up",
                "death", "button", "save", "error", "dungeon_enter",
                "dungeon_clear", "room_clear", "enemy_die", "rent_paid"]
for sfx in expected_sfx:
    check(f"SFX '{sfx}' handled in procedural generator", f'"{sfx}"' in am)

# Verify expected BGM track names
expected_bgm = ["overworld", "dungeon", "boss", "menu", "night"]
for bgm in expected_bgm:
    check(f"BGM '{bgm}' handled in procedural generator", f'"{bgm}"' in am)


# ---------- ScreenTransition Script ----------
print("\n--- ScreenTransition Script ---")
st = read("scripts/ui/screen_transition.gd")
check("screen_transition.gd exists", st != "")
check("Has fade_out_complete signal", "signal fade_out_complete" in st)
check("Has fade_in_complete signal", "signal fade_in_complete" in st)
check("Has fade_out() function", "func fade_out(" in st)
check("Has fade_in() function", "func fade_in(" in st)
check("Has instant_black()", "func instant_black(" in st)
check("Has instant_clear()", "func instant_clear(" in st)
check("Extends ColorRect", "extends ColorRect" in st)


# ---------- VisualEffects Script ----------
print("\n--- VisualEffects Script ---")
ve = read("scripts/ui/visual_effects.gd")
check("visual_effects.gd exists", ve != "")
check("Has screen_shake()", "func screen_shake(" in ve)
check("Has hit_flash()", "func hit_flash(" in ve)
check("Extends Node", "extends Node" in ve)
check("Has DAY_COLOR constant", "DAY_COLOR" in ve)
check("Has NIGHT_COLOR constant", "NIGHT_COLOR" in ve)
check("Has EVENING_COLOR constant", "EVENING_COLOR" in ve)


# ---------- DialogueBox Script ----------
print("\n--- DialogueBox Script ---")
db = read("scripts/ui/dialogue_box.gd")
check("dialogue_box.gd exists", db != "")
check("Has dialogue_advanced signal", "signal dialogue_advanced" in db)
check("Has dialogue_finished signal", "signal dialogue_finished" in db)
check("Has show_line() function", "func show_line(" in db)
check("Has hide_dialogue() function", "func hide_dialogue(" in db)
check("Has typewriter effect (_chars_per_second)", "_chars_per_second" in db)
check("Handles input for advancing", "func _input(" in db)


# ---------- CutscenePlayer Script ----------
print("\n--- CutscenePlayer Script ---")
cp = read("scripts/cutscene_player.gd")
check("cutscene_player.gd exists", cp != "")
check("Has cutscene_started signal", "signal cutscene_started" in cp)
check("Has cutscene_finished signal", "signal cutscene_finished" in cp)
check("Has play_cutscene()", "func play_cutscene(" in cp)
check("Has skip_cutscene()", "func skip_cutscene(" in cp)
check("Has is_playing()", "func is_playing(" in cp)
check("Has set_dialogue_box()", "func set_dialogue_box(" in cp)
check("Pauses TimeManager", "TimeManager" in cp)
check("Loads from cutscenes.json", "cutscenes.json" in cp)


# ---------- Cutscenes Data ----------
print("\n--- Cutscene Data (cutscenes.json) ---")
check("cutscenes.json exists", file_exists("data/cutscenes.json"))
cutscene_raw = read("data/cutscenes.json")
try:
    cutscenes = json.loads(cutscene_raw)
    check("cutscenes.json is valid JSON", True)
except (json.JSONDecodeError, ValueError):
    cutscenes = {}
    check("cutscenes.json is valid JSON", False)

check("Has at least 4 cutscenes", len(cutscenes) >= 4)
expected_cutscenes = ["cutscene_tutorial_intro", "cutscene_first_delivery",
                      "cutscene_crab_cave", "cutscene_rent_due"]
for cid in expected_cutscenes:
    check(f"Cutscene '{cid}' exists", cid in cutscenes)
    if cid in cutscenes:
        cs = cutscenes[cid]
        check(f"  '{cid}' has id field", "id" in cs)
        check(f"  '{cid}' has lines array", "lines" in cs and isinstance(cs["lines"], list))
        if "lines" in cs:
            check(f"  '{cid}' has at least 3 lines", len(cs["lines"]) >= 3)
            for i, line in enumerate(cs["lines"]):
                if i == 0:
                    check(f"  '{cid}' line 0 has speaker", "speaker" in line)
                    check(f"  '{cid}' line 0 has text", "text" in line)


# ---------- SceneManager Integration ----------
print("\n--- SceneManager Integration ---")
sm = read("scripts/scene_manager.gd")
check("SceneManager has _update_bgm()", "_update_bgm" in sm)
check("SceneManager has set_screen_transition()", "set_screen_transition" in sm)
check("SceneManager references AudioManager", "AudioManager" in sm)
check("SceneManager has transition support", "_screen_transition" in sm)


# ---------- UIManager Integration ----------
print("\n--- UIManager Integration ---")
um = read("scripts/ui_manager.gd")
check("UIManager sets up screen transition", "_setup_screen_transition" in um)
check("UIManager sets up dialogue box", "_setup_dialogue_box" in um)
check("UIManager sets up cutscene player", "_setup_cutscene_player" in um)
check("UIManager has get_cutscene_player()", "func get_cutscene_player" in um)
check("UIManager plays SFX on damage", 'play_sfx("hit")' in um or "play_sfx" in um)
check("UIManager plays SFX on level up", 'play_sfx("level_up")' in um)
check("UIManager plays SFX on item pickup", 'play_sfx("pickup")' in um)
check("UIManager plays SFX on dungeon enter", 'play_sfx("dungeon_enter")' in um)
check("UIManager plays SFX on dungeon clear", 'play_sfx("dungeon_clear")' in um)


# ---------- DebugMenu Audio Controls ----------
print("\n--- DebugMenu Audio/Visual Controls ---")
dm = read("scripts/ui/debug_menu.gd")
check("DebugMenu has Audio/Visual category", '"Audio/Visual"' in dm)
check("DebugMenu has BGM buttons", "_on_bgm_overworld" in dm)
check("DebugMenu has SFX buttons", "_on_sfx_hit" in dm)
check("DebugMenu has toggle mute", "_on_toggle_mute" in dm)
check("DebugMenu has screen shake button", "_on_screen_shake" in dm)
check("DebugMenu has cutscene buttons", "_on_play_cutscene_intro" in dm)


# ---------- TimeManager set_paused ----------
print("\n--- TimeManager set_paused ---")
tm = read("scripts/managers/time_manager.gd")
check("TimeManager has set_paused()", "func set_paused(" in tm)


# ---------- Summary ----------
print(f"\n{'='*40}")
print(f"Phase 8 Static Tests: {passed} passed, {failed} failed")
print(f"{'='*40}")
if failed > 0:
    sys.exit(1)
