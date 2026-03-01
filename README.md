# README.md
# Project: [Working Title TBD]
# Engine: Godot 4.x
# Architecture: Fully Data-Driven

---

# 1. PURPOSE OF THIS DOCUMENTATION

This documentation defines:

- Game systems
- Economy balance
- Data structures
- Demo scope
- Technical architecture

All gameplay logic must follow these documents strictly.

Claude AI and developers must treat this as the source of truth.

---

# 2. DOCUMENT STRUCTURE

## GAME_DESIGN_DOCUMENT.md
High-level design:
- Core loop
- Player progression
- Dungeon structure
- Combat design
- Demo boundaries

## SYSTEM_ARCHITECTURE.md
Technical rules:
- Host authoritative multiplayer
- Manager responsibilities
- Data-driven loading
- Runtime scaling

## ECONOMY_AND_SCALING_SPEC.md
Mathematical formulas:
- XP curves
- Dungeon scaling
- Loot scaling
- Rent structure

## DATA_SCHEMA_SPEC.md
Exact JSON formats:
- Enemies
- Items
- Skills
- Dungeons
- Missions
- Save data

All gameplay values must exist in JSON files following these schemas.

## DEMO_CONTENT_BLUEPRINT.md
Defines EXACT demo content:
- Enemy types
- Items
- Skill nodes
- Dungeons
- Missions
- Delivery jobs

No content outside this file may exist in the demo.

---

# 3. DEVELOPMENT RULES

1. No hardcoded numbers in scripts.
2. All stats loaded from JSON.
3. All scaling read from global_config.json.
4. No feature expansion without updating documentation.
5. Demo max level = 5.
6. Demo duration target = 45–60 minutes.

---

# 4. HOW CLAUDE AI SHOULD USE THIS

Claude must:

- Follow DATA_SCHEMA_SPEC exactly.
- Only create content defined in DEMO_CONTENT_BLUEPRINT.
- Respect economy caps.
- Never invent new systems.
- Never exceed stat caps.

Claude may:
- Generate new JSON entries within blueprint limits.
- Help balance numbers within defined ranges.
- Assist in writing Godot scripts referencing defined schemas.

---

# 5. HOW DEVELOPERS SHOULD USE THIS

When implementing a system:

1. Read SYSTEM_ARCHITECTURE.md
2. Confirm schema in DATA_SCHEMA_SPEC.md
3. Add JSON in res://data/
4. Implement script that reads JSON
5. Test scaling via global_config.json

Never design systems directly in code first.

---

# 6. DEMO GOAL

The demo must:

- Teach core loop
- Showcase dungeon scaling
- Showcase economy loop
- Introduce story dungeon (Crab Cave)
- Introduce replayable dungeon
- Show skill progression
- Show rent pressure

After demo is stable → expand content.

---

# END
