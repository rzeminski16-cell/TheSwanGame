# The Swan Game
**Engine:** Godot 4.x | **Architecture:** Fully Data-Driven | **Multiplayer:** LAN Co-op (1-4)

---

## Quick Start

This project is built phase-by-phase. Each phase has its own developer documentation under `docs/phases/`. Start there to understand what's implemented and how to work with it.

---

## Documentation Structure

```
docs/
├── design/                          # Game design specs
│   ├── Game_Design_Document.md      # Core loop, systems, multiplayer rules
│   └── DEMO_CONTENT_BLUEPRINT.md    # Exact demo content (enemies, items, skills, missions)
│
├── technical/                       # Technical architecture & data specs
│   ├── SYSTEM_ARCHITECTURE.md       # Manager responsibilities, scene structure, multiplayer
│   ├── DATA_SCHEMA_SPEC.md          # JSON schemas for all game data
│   └── ECONOMY_AND_SCALING_SPEC.md  # XP curves, dungeon scaling, loot formulas
│
└── phases/                          # Per-phase developer documentation
    ├── PHASE_0.md                   # Project skeleton + data foundation
    ├── PHASE_1.md                   # Player character, movement, stats
    ├── PHASE_2.md                   # Combat core, enemies, damage, loot
    ├── PHASE_3.md                   # Economy, UI, skill tree
    └── PHASE_4.md                   # Dungeon system, rooms, waves, boss, scaling
```

---

## Development Rules

1. **No hardcoded numbers in scripts.** All gameplay values come from JSON files in `res://data/`.
2. **All stats loaded from JSON.** Enemy stats, item effects, XP curves — everything.
3. **All scaling reads from `global_config.json`.** One place to tune all balance.
4. **No feature expansion without updating documentation.**
5. **Demo max level = 5.** Demo duration target = 45-60 minutes.
6. **Host-authoritative multiplayer.** All state-mutating logic runs on host.

---

## How Developers Should Use This

When implementing or modifying a system:

1. Read the relevant phase doc in `docs/phases/`
2. Check the architecture in `docs/technical/SYSTEM_ARCHITECTURE.md`
3. Confirm the JSON schema in `docs/technical/DATA_SCHEMA_SPEC.md`
4. Modify data in `res://data/` JSON files — never in scripts
5. Test scaling via `global_config.json`

---

## How Claude AI Should Use This

**Must:**
- Follow `DATA_SCHEMA_SPEC.md` exactly
- Only create content defined in `DEMO_CONTENT_BLUEPRINT.md`
- Respect economy caps and stat limits
- Never invent new systems beyond what's documented

**May:**
- Generate JSON entries within blueprint limits
- Help balance numbers within defined ranges
- Write Godot scripts that read from JSON definitions

---

## Demo Goal

The demo must showcase:
- Core combat loop with dungeon scaling
- Economy pressure (earn money, pay rent)
- Story dungeon (Crab Cave) and replayable dungeon
- Skill progression (15-node tree)
- Light comedic narrative

After demo is stable, expand content.

---

## Implementation Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 0 | Project Skeleton + Data Foundation | Complete |
| 1 | Player Character — Movement, Stats, Components | Complete |
| 2 | Combat Core — Enemies, Damage, Loot | Complete |
| 3 | Economy, UI, Skill Tree | Complete |
| 4 | Dungeon System — Rooms, Waves, Boss, Scaling | Complete |
| 5 | Overworld, Missions, Time, Delivery | Planned |
| 6 | Save/Load + Game Flow | Planned |
| 7 | LAN Multiplayer | Planned |
| 8 | Audio, Visuals, Cutscenes | Planned |
| 9 | Integration Testing + Balance Pass | Planned |
