# PHASE 8 — Audio, Visuals, Cutscenes

## Goal

Add audio feedback (BGM and SFX), visual polish (screen transitions, day/night overlay, screen shake, hit flash), and a cutscene system (scripted dialogue sequences tied to story missions).

---

## Deliverables

### 1. AudioManager (Full Implementation)

**File:** `scripts/audio_manager.gd`

Replaces the Phase 0 stub with a complete audio system:

- **BGM (Background Music)**
  - Two `AudioStreamPlayer` nodes for crossfading between tracks
  - `play_bgm(track_name)` — plays named track with 1-second crossfade
  - `stop_bgm()` — fades out current track
  - `get_current_bgm()` — returns current track name
  - Supported track names: `overworld`, `dungeon`, `boss`, `menu`, `night`

- **SFX (Sound Effects)**
  - Pool of 8 `AudioStreamPlayer` nodes (round-robin polyphony)
  - `play_sfx(sfx_name)` — plays named sound effect
  - 15 SFX events: `hit`, `crit`, `dodge`, `pickup`, `money`, `level_up`, `death`, `button`, `save`, `error`, `dungeon_enter`, `dungeon_clear`, `room_clear`, `enemy_die`, `rent_paid`

- **Volume Controls**
  - `set_master_volume(vol)` — 0.0 to 1.0
  - `set_bgm_volume(vol)` — 0.0 to 1.0
  - `set_sfx_volume(vol)` — 0.0 to 1.0
  - `toggle_mute()` / `is_muted()`

- **Procedural Placeholder Audio**
  - Generates simple sine-wave tones as BGM/SFX placeholders
  - No external audio files required
  - Falls back to procedural audio when `res://audio/bgm/*.ogg` or `res://audio/sfx/*.wav` files are not found
  - Drop in real audio assets and they will automatically be used

- **Signals:** `bgm_changed(track_name)`, `sfx_played(sfx_name)`

### 2. Screen Transitions

**File:** `scripts/ui/screen_transition.gd`

- Full-screen `ColorRect` overlay on UIManager's CanvasLayer
- `fade_out(duration)` — fades to black (emits `fade_out_complete`)
- `fade_in(duration)` — fades from black (emits `fade_in_complete`)
- `instant_black()` / `instant_clear()` — immediate transitions
- Default fade duration: 0.4 seconds
- SceneManager uses transitions automatically on `change_scene()`

### 3. Visual Effects

**File:** `scripts/ui/visual_effects.gd`

- **Day/Night Overlay** — `CanvasModulate` that reads `GameState.current_time_of_day`
  - Morning: warm whites
  - Day: neutral whites
  - Evening: warm orange tint
  - Night: cool blue tint
  - Smooth color lerps between phases

- **Screen Shake** — `screen_shake(intensity, decay)`
  - Offsets the active Camera2D with random displacement
  - Exponential decay to zero
  - Triggered on big hits, boss attacks

- **Hit Flash** — `hit_flash(node, flash_color, duration)`
  - Modulates a Node2D to flash white briefly
  - Returns to original color via tween

### 4. Cutscene System

**Files:**
- `scripts/ui/dialogue_box.gd` — Bottom-screen dialogue panel
- `scripts/cutscene_player.gd` — Cutscene sequencer
- `data/cutscenes.json` — Cutscene data (4 cutscenes)

**DialogueBox:**
- Shows speaker name (gold color) and dialogue text
- Typewriter effect at 40 characters/second
- Press E, Space, Enter, or click to advance/skip
- Hidden when not in use

**CutscenePlayer:**
- `play_cutscene(cutscene_id)` — loads from `cutscenes.json`, shows lines sequentially
- `skip_cutscene()` — immediately finishes
- `is_playing()` — check if cutscene is active
- Pauses `TimeManager` during cutscenes (resumes on finish)
- Signals: `cutscene_started`, `cutscene_finished`

**Cutscene Data (4 cutscenes):**
1. `cutscene_tutorial_intro` — Hannan welcomes the player (5 lines)
2. `cutscene_first_delivery` — Lewis introduces deliveries (5 lines)
3. `cutscene_crab_cave` — Jack talks about the Crab Cave (6 lines)
4. `cutscene_rent_due` — Luka delivers the rent notice (5 lines)

### 5. System Integration

**SceneManager changes:**
- Auto-plays appropriate BGM on scene change (overworld, dungeon, night)
- Uses screen transitions (fade out → change → fade in) when available

**UIManager changes:**
- Creates and manages ScreenTransition, DialogueBox, CutscenePlayer nodes
- Audio SFX triggers wired to game events:
  - Combat: `hit`, `crit`, `dodge` on damage dealt
  - Progression: `level_up`, `pickup` on level/item events
  - Economy: `rent_paid`, `error` on rent events
  - Dungeon: `dungeon_enter`, `dungeon_clear`, `death` on dungeon events
  - UI: `button` on mission start

**TimeManager changes:**
- Added `set_paused(bool)` convenience method

**DebugMenu changes:**
- New "Audio/Visual" category with 11 buttons:
  - Play BGM (Overworld, Dungeon, Boss), Stop BGM
  - Play SFX (Hit, Level Up, Pickup)
  - Toggle Mute, Screen Shake
  - Play Cutscene (Intro, Cave)

---

## File Map

```
scripts/
├── audio_manager.gd              # Full AudioManager (was stub)
├── cutscene_player.gd            # NEW — cutscene sequencer
├── scene_manager.gd              # Updated — BGM + transitions
├── ui_manager.gd                 # Updated — Phase 8 integration
├── managers/
│   └── time_manager.gd           # Updated — set_paused()
└── ui/
    ├── screen_transition.gd      # NEW — fade overlay
    ├── visual_effects.gd         # NEW — day/night, shake, flash
    ├── dialogue_box.gd           # NEW — dialogue panel
    └── debug_menu.gd             # Updated — audio/visual controls

data/
└── cutscenes.json                # NEW — 4 story cutscenes

tests/
├── test_phase8_json.py           # NEW — 117 static checks
├── test_phase8_runtime.gd        # NEW — runtime tests
└── TestPhase8Runtime.tscn        # NEW — test scene
```

---

## Acceptance Criteria

### Static Tests (test_phase8_json.py) — 117 checks
- [x] AudioManager has all required methods, signals, and procedural generators
- [x] All 15 SFX and 5 BGM names are handled
- [x] ScreenTransition has fade_out/fade_in with signals
- [x] VisualEffects has screen_shake, hit_flash, day/night colors
- [x] DialogueBox has typewriter effect and input handling
- [x] CutscenePlayer has play/skip/is_playing with TimeManager integration
- [x] cutscenes.json has 4 valid cutscenes with proper structure
- [x] SceneManager has BGM and transition support
- [x] UIManager creates and manages all Phase 8 subsystems
- [x] DebugMenu has Audio/Visual category with all controls
- [x] TimeManager has set_paused()

### Runtime Tests (test_phase8_runtime.gd)
- [x] AudioManager volume clamping works correctly
- [x] Mute toggle works
- [x] BGM play/stop/get_current_bgm() works
- [x] All 15 SFX names play without error
- [x] ScreenTransition instant_black/instant_clear works
- [x] DialogueBox show/hide works
- [x] CutscenePlayer play/skip lifecycle works
- [x] UIManager has all Phase 8 nodes
- [x] TimeManager set_paused works

### Manual Verification
- [ ] F3 debug menu shows "Audio/Visual" category
- [ ] Clicking "Play BGM: Overworld" produces sound
- [ ] Clicking "Play SFX: Hit" produces a short sound
- [ ] "Toggle Mute" silences all audio
- [ ] "Screen Shake" shakes the camera briefly
- [ ] "Play Cutscene: Intro" shows dialogue box with typewriter text
- [ ] Pressing E advances dialogue lines
- [ ] Scene transitions fade to black between scenes
- [ ] Day/night cycle tints screen colors
