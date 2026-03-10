# Phase 10: Quest Log UI, Multi-Quest System, Quest Expansion

**Goal:** Quest log popup panel with Active/Completed/Debug tabs, expandable mission boxes with objective tracking, quest tracking system (multiple active quests with one tracked for HUD), expanded mission data model, 13 new quest definitions covering all mission types, and enhanced debug tools for quest management.

**Depends on:** Phase 5 (MissionManager, OverworldScene, NPCs, delivery mini-game)

---

## What This Phase Delivers

- `QuestLogPanel` — full quest log popup (L key toggle) with 3 tabs: Active, Completed, Debug
- Expandable mission boxes showing name, recommended level, quest type, description, objective breakdown, track button, and rewards
- Rewritten `MissionManager` — supports multiple simultaneous active quests with one tracked quest for HUD display
- Quest unlock system — missions unlock based on prerequisite completion and character restrictions
- Kill count tracking — global enemy kill tracker for hunt missions
- 10 new objective types: kill_enemies, survive_waves, investigate, solve_puzzle, solve_riddle, defend_location, timed_objective, stealth, dialogue_choice, make_choice
- Expanded mission data model — quest_type, description, recommended_level, character_restriction, unlock_conditions, unlock_requirements, quest_origin, per-objective descriptions
- 13 new quest definitions (quest_001–quest_013) covering delivery, hunt, survival, boss investigation, fetch, diplomacy, relationship, puzzle, riddle, defense, timed, infiltration, and choice mission types
- Updated `GameState` — tracked_mission_id and active_mission_ids fields
- Updated `UIManager` — quest log toggle, ESC closes quest log, mission tracker uses tracked quest
- Updated `DebugMenu` — complete tracked mission, start all unlockable, print all missions, open quest log
- Updated `project.godot` — toggle_quest_log input action (L key)

---

## File Map

```
scripts/
├── managers/
│   ├── mission_manager.gd          # REWRITTEN — multi-quest, tracking, unlock system, new objectives
│   └── game_state.gd               # UPDATED — tracked_mission_id, active_mission_ids
├── ui/
│   ├── quest_log_panel.gd          # NEW — quest log popup with 3 tabs
│   └── debug_menu.gd               # UPDATED — 4 new mission debug buttons
├── ui_manager.gd                   # UPDATED — quest log toggle, ESC close, tracked mission tracker
└── main.gd                         # UPDATED — L key binding

scenes/
└── ui/
    └── QuestLogPanel.tscn          # NEW — quest log panel scene

data/
└── missions.json                   # REWRITTEN — expanded model, 18 total missions

project.godot                       # UPDATED — toggle_quest_log input action
```

---

## System Details

### Quest Log Panel

Toggle with **L key**. Centered popup panel with dark theme matching existing UI panels.

| Tab | Content |
|-----|---------|
| Active | All currently active quests — click to expand, track button |
| Completed | All finished quests — click to expand, view objectives |
| Debug | All missions in game with state, unlock conditions, force-start buttons, bulk actions |

**Mission box (collapsed):** Quest name (colored by type), recommended level badge, quest type label, tracking indicator.

**Mission box (expanded):** Description text, objective breakdown with [x]/[ ] checkmarks, "Track This Quest" button, rewards summary.

**Quest type colors:**
- Gold: Main Quest
- White: Side Quest
- Purple: Character Quest

**Debug tab controls:**
- "Complete Tracked" — force-completes the currently tracked mission
- "Start All Unlockable" — starts every mission whose prerequisites are met
- "Reset All" — clears all mission state

### Multi-Quest MissionManager

The mission system now supports multiple simultaneous active quests with one tracked quest for the HUD overlay.

**Key concepts:**
- **Active missions:** Multiple quests can be active at once, stored in `GameState.active_mission_ids`
- **Tracked mission:** One mission shown in the HUD tracker, stored in `GameState.tracked_mission_id`
- **Auto-tracking:** First started mission is auto-tracked; on completion, next active mission is auto-tracked
- **Legacy compat:** `GameState.current_mission_id` mirrors tracked mission for backward compatibility

**API additions:**
```gdscript
# Tracking
MissionManager.track_mission(mission_id)
MissionManager.get_tracked_mission_id() -> String
MissionManager.get_tracked_mission_data() -> Dictionary

# Multi-quest queries
MissionManager.get_all_active_missions() -> Array
MissionManager.get_all_completed_missions() -> Array

# Unlock system
MissionManager.is_mission_unlockable(mission_id) -> bool
MissionManager.get_unlockable_missions() -> Array

# Kill tracking
MissionManager.notify_enemy_killed(enemy_id)
MissionManager.get_kill_count(enemy_id) -> int

# Debug
MissionManager.debug_complete_mission(mission_id)
```

**Objective checking:** All active missions are checked for objective matches (not just the tracked one), so progress counts across all quests simultaneously.

### New Objective Types

| Type | Parameters | Notify Function |
|------|-----------|----------------|
| kill_enemies | enemy_id, count | `notify_enemy_killed(enemy_id)` |
| survive_waves | arena_id, duration | `notify_survive_complete(arena_id)` |
| investigate | clue_id, location_id | `notify_investigate(clue_id)` |
| solve_puzzle | puzzle_id | `notify_puzzle_solved(puzzle_id)` |
| solve_riddle | riddle_id | `notify_riddle_solved(riddle_id)` |
| defend_location | location_id, duration | `notify_defend_complete(location_id)` |
| timed_objective | time_limit, sub_type, delivery_job_id | `notify_timed_complete(sub_type, delivery_job_id)` |
| stealth | area_id | `notify_stealth_complete(area_id)` |
| dialogue_choice | choice_id | `notify_dialogue_choice(choice_id)` |
| make_choice | choice_id | `notify_make_choice(choice_id)` |

These join the existing 6 types: talk_to_npc, enter_dungeon, collect_item, return_home, deliver_item, reach_location.

### Expanded Mission Data Model

New fields added to each mission in `missions.json`:

```json
{
    "id": "quest_001",
    "display_name": "Luca Delivery",
    "quest_type": "main",
    "description": "Luca asked you for a favour...",
    "recommended_level": 1,
    "character_restriction": null,
    "unlock_conditions": "None — available from the start.",
    "unlock_requirements": [],
    "quest_origin": "luka",
    "objectives": [
        { "type": "talk_to_npc", "npc_id": "luka", "description": "Talk to Luka about the delivery" }
    ],
    "rewards": { "money": 75, "xp": 100, "items": [] },
    "next_mission_id": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| quest_type | String | "main", "side", or "character" |
| description | String | Quest description shown in expanded view |
| recommended_level | int | Suggested player level |
| character_restriction | String/null | Character ID (e.g. "char_hubert") or null for all |
| unlock_conditions | String | Human-readable unlock description (debug view) |
| unlock_requirements | Array | Mission IDs that must be completed first |
| quest_origin | String | NPC who gives the quest |
| objectives[].description | String | Per-objective description override |

### Quest Definitions

#### Original Story Missions (from Phase 5)

| # | ID | Name | Type | Lvl | Objectives | Rewards |
|---|---|---|---|---|---|---|
| 1 | mission_tutorial | Move In | Main | 1 | Talk Hannan, Reach house | 50g, 50 XP |
| 2 | mission_papers | Find Papers | Main | 1 | Talk Lewis, Return home | 100 XP |
| 3 | mission_first_delivery | First Delivery | Main | 1 | Talk Luka, Deliver | 50g, 150 XP |
| 4 | mission_crab_cave | Enter Crab Cave | Main | 2 | Enter dungeon | 100g, 200 XP |
| 5 | mission_pay_rent | Pay Rent | Main | 2 | Reach rent box | 100 XP |

#### New Quest Expansion (13 quests)

| # | ID | Name | Type | Lvl | Mission Type | Unlock After |
|---|---|---|---|---|---|---|
| 1 | quest_001 | Luca Delivery | Main | 1 | Delivery | None |
| 2 | quest_002 | Rat King | Side | 2 | Hunt | quest_001 |
| 3 | quest_003 | Endure | Main | 3 | Survival | quest_001 |
| 4 | quest_004 | Big Smonker | Character | 4 | Boss Investigation | quest_003 (Hubert only) |
| 5 | quest_005 | Lost Relic | Side | 2 | Artifact Recovery | quest_001 |
| 6 | quest_006 | The Dispute | Side | 1 | Diplomacy | quest_001 |
| 7 | quest_007 | Bonding Time | Side | 1 | Relationship | quest_001 |
| 8 | quest_008 | Tunnel Puzzle | Side | 2 | Puzzle | quest_001 |
| 9 | quest_009 | Hannan's Riddle | Side | 1 | Riddle | quest_001 |
| 10 | quest_010 | Hold The Line | Side | 3 | Defense | quest_001 |
| 11 | quest_011 | Express Delivery | Side | 2 | Timed | quest_001 |
| 12 | quest_012 | Sneak | Side | 3 | Infiltration | quest_001 |
| 13 | quest_013 | The Crossroads | Main | 3 | Choice | quest_001 |

### Debug Features

#### Quest Log Debug Tab

The third tab in the Quest Log panel provides full visibility into the quest system:
- Every mission listed with current state (LOCKED / ACTIVE / DONE / FAILED)
- Color-coded borders: green=completed, blue=active, red=failed, grey=locked
- Unlock conditions displayed per mission
- "Force Start" button on locked missions
- Bulk actions: Complete Tracked, Start All Unlockable, Reset All

#### Debug Menu (F3) Additions

New buttons under the Missions category:
- **Complete Tracked Mission** — force-completes the tracked quest and grants rewards
- **Start All Unlockable** — starts every mission whose prerequisites are met
- **Print All Missions** — outputs full mission state list to console
- **Open Quest Log** — opens the quest log panel directly

---

## Testing

### Manual Testing Checklist

#### Quest Log Panel
- [ ] Press L — Quest Log panel opens centered on screen
- [ ] Press L again — Quest Log panel closes
- [ ] Press ESC with Quest Log open — panel closes (does not pause)
- [ ] Active tab shows currently active missions
- [ ] Completed tab shows finished missions
- [ ] Debug tab shows all 18 missions with states
- [ ] Empty state: "No active quests." shown when no missions active
- [ ] Empty state: "No completed quests yet." shown initially

#### Mission Boxes
- [ ] Collapsed box shows: name, Lv. badge, quest type label
- [ ] Main quests: gold text, "MAIN QUEST" badge
- [ ] Side quests: white text, "SIDE QUEST" badge
- [ ] Character quests: purple text, "CHARACTER QUEST" badge
- [ ] Click mission box — expands to show description, objectives, rewards
- [ ] Click expanded box — collapses back
- [ ] Expanded view shows objective checkmarks ([x] done, [ ] pending)
- [ ] Expanded view shows rewards summary (money, XP, items)

#### Quest Tracking
- [ ] First started mission is auto-tracked
- [ ] Tracked mission shows "[TRACKING]" indicator in quest log
- [ ] Tracked mission has blue highlight border
- [ ] HUD tracker (top-right) shows tracked mission name and objectives
- [ ] Click "Track This Quest" on a different active mission — HUD updates
- [ ] Completing tracked mission auto-tracks next active mission
- [ ] With no active missions, HUD tracker is empty

#### Multi-Quest System
- [ ] Can have multiple missions active at the same time
- [ ] Talking to NPC progresses objectives across ALL active missions
- [ ] Completing a mission removes it from active list
- [ ] Completing a mission with next_mission_id auto-starts the next

#### Unlock System
- [ ] Missions with unmet requirements cannot be started
- [ ] Character-restricted missions only start for the correct character
- [ ] Debug "Start All Unlockable" respects prerequisites

#### Debug Features
- [ ] Debug tab: "Force Start" button starts a locked mission
- [ ] Debug tab: "Complete Tracked" completes the tracked mission instantly
- [ ] Debug tab: "Start All Unlockable" starts all eligible missions
- [ ] Debug tab: "Reset All" clears all mission state
- [ ] F3 Debug Menu: "Complete Tracked Mission" works
- [ ] F3 Debug Menu: "Start All Unlockable" works
- [ ] F3 Debug Menu: "Print All Missions" outputs to console
- [ ] F3 Debug Menu: "Open Quest Log" opens the panel

#### Save/Load Integration
- [ ] Save game with active quests — load preserves active quest list
- [ ] Save game with tracked quest — load preserves tracked quest
- [ ] Save game with completed quests — load preserves completion state
- [ ] Save game with kill counts — load preserves kill counts
- [ ] Loading old saves (pre-Phase 10) gracefully rebuilds active list from states

---

## How to Test Manually

1. Run the game — start a new game or load an existing save
2. Press **L** to open the Quest Log — verify it opens centered with 3 tabs
3. Check the **Active** tab — should show the tutorial mission if starting fresh
4. Click a mission box to **expand** it — verify description, objectives, and rewards display
5. Press **F3** to open Debug Menu → under Missions, click "Start All Unlockable"
6. Press **L** again — Active tab should now show multiple missions
7. Click "Track This Quest" on a different mission — verify HUD tracker (top-right) updates
8. Switch to **Completed** tab — verify completed missions appear there
9. Switch to **Debug** tab — verify all 18 missions listed with states and unlock conditions
10. Click "Complete Tracked" in Debug tab — verify mission completes, rewards granted, next mission auto-tracked
11. Click "Reset All" — verify all mission state cleared
12. Save the game, reload — verify all quest state preserved
