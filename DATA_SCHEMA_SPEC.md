# DATA_SCHEMA_SPEC.md
# Project: [Working Title TBD]
# Engine: Godot 4.x
# Version: Demo Foundation (Data-Driven Architecture)

---

# 1. DESIGN PRINCIPLES

1. All gameplay values must be defined in JSON.
2. No hardcoded enemy stats in scripts.
3. No hardcoded item values in scripts.
4. Scaling values must reference central config.
5. IDs must be unique and stable.
6. JSON must be human-readable and Claude-generatable.

All JSON files stored in:
res://data/

---

# 2. GLOBAL CONFIG SCHEMA

File: global_config.json

Purpose:
Centralized numeric balance tuning.

Structure:

{
  "xp_curve_exponent": 1.5,
  "base_xp_per_level": 100,
  "dungeon_scaling_per_completion": 0.15,
  "enemy_health_scaling": 0.12,
  "enemy_damage_scaling": 0.08,
  "enemy_spawn_scaling": 0.10,
  "loot_quality_scaling": 0.10,
  "base_delivery_reward": 50,
  "base_weekly_rent": 250,
  "max_player_level_demo": 5
}

All systems must reference this file.

---

# 3. ENEMY DATA SCHEMA

File: enemies.json

Structure:

{
  "enemies": [
    {
      "id": "melee_rat",
      "display_name": "Cave Rat",
      "type": "melee",
      "base_stats": {
        "health": 50,
        "damage": 8,
        "move_speed": 80,
        "attack_speed": 1.0,
        "crit_chance": 0.0,
        "dodge_chance": 0.0
      },
      "xp_reward": 10,
      "money_drop": {
        "min": 5,
        "max": 10
      },
      "loot_table_id": "basic_dungeon_loot"
    }
  ]
}

Rules:
- type must be: melee | ranged | boss
- No scaling values stored here
- Scaling applied at runtime by DungeonManager

---

# 4. LOOT TABLE SCHEMA

File: loot_tables.json

{
  "loot_tables": [
    {
      "id": "basic_dungeon_loot",
      "drops": [
        {
          "item_id": "damage_ring",
          "weight": 70
        },
        {
          "item_id": "crit_charm",
          "weight": 25
        },
        {
          "item_id": "epic_blade_core",
          "weight": 5
        }
      ]
    }
  ]
}

Rules:
- weight defines probability
- Scaling modifies rarity externally
- No drop logic inside enemy script

---

# 5. ITEM DATA SCHEMA

File: items.json

{
  "items": [
    {
      "id": "damage_ring",
      "display_name": "Rusty Ring",
      "rarity": "common",
      "type": "passive",
      "effects": [
        {
          "stat": "damage",
          "modifier_type": "percent",
          "value": 0.10
        }
      ],
      "stackable": false
    }
  ]
}

Valid rarity:
common | rare | epic

Valid modifier_type:
flat | percent

Valid stat:
health
damage
attack_speed
move_speed
crit_chance
dodge_chance
stamina

---

# 6. SKILL TREE SCHEMA

File: skills.json

{
  "skills": [
    {
      "id": "combat_damage_1",
      "category": "combat",
      "display_name": "Sharpened Instinct",
      "description": "+5% damage",
      "effects": [
        {
          "stat": "damage",
          "modifier_type": "percent",
          "value": 0.05
        }
      ],
      "max_level": 1,
      "requirements": []
    }
  ]
}

Valid category:
combat | economy | personality

Requirements:
Array of skill IDs required before unlock.

---

# 7. DUNGEON DATA SCHEMA

File: dungeons.json

{
  "dungeons": [
    {
      "id": "crab_cave",
      "display_name": "Crab Cave",
      "type": "story",
      "base_difficulty": 1,
      "rooms": [
        {
          "room_type": "combat",
          "enemy_groups": [
            {
              "enemy_id": "melee_rat",
              "count": 5
            }
          ]
        },
        {
          "room_type": "boss",
          "enemy_id": "crab_king"
        }
      ],
      "replayable": false
    }
  ]
}

Valid type:
story | replayable

Replayable dungeon must persist:
completion_count
difficulty_level

---

# 8. MISSION DATA SCHEMA

File: missions.json

{
  "missions": [
    {
      "id": "mission_papers",
      "display_name": "Find Papers",
      "type": "story",
      "objectives": [
        {
          "type": "talk_to_npc",
          "npc_id": "shop_clerk"
        },
        {
          "type": "return_home"
        }
      ],
      "rewards": {
        "money": 0,
        "xp": 100,
        "items": []
      },
      "next_mission_id": "mission_crab_cave"
    }
  ]
}

Valid objective types:
talk_to_npc
enter_dungeon
collect_item
return_home
deliver_item
reach_location

---

# 9. DELIVERY JOB SCHEMA

File: delivery_jobs.json

{
  "delivery_jobs": [
    {
      "id": "delivery_basic_1",
      "base_reward": 50,
      "difficulty_modifier": 1.0,
      "delivery_points": 3,
      "time_limit": null,
      "risk_level": 0
    }
  ]
}

Future-ready fields:
- police_chance
- rival_dealer_chance
- failure_penalty

---

# 10. PLAYER SAVE DATA SCHEMA

Saved to:
user://save_data.json

{
  "players": [
    {
      "level": 3,
      "xp": 450,
      "money": 320,
      "skills": ["combat_damage_1"],
      "inventory": ["damage_ring"]
    }
  ],
  "dungeons": {
    "replay_dungeon_1": {
      "completion_count": 3,
      "difficulty_level": 3
    }
  },
  "story_progress": 2,
  "statistics": {
    "total_kills": 120,
    "total_money_earned": 1400
  }
}

---

# 11. RUNTIME SCALING RULES

Important:

Enemy JSON does NOT contain scaling multipliers.

Runtime applies:

FinalHealth =
BaseHealth × (1 + completion_count × enemy_health_scaling)

FinalDamage =
BaseDamage × (1 + completion_count × enemy_damage_scaling)

LootMultiplier =
1 + completion_count × loot_quality_scaling

All scaling variables read from global_config.json

---

# 12. CONTENT EXPANSION RULES

Claude AI must:

1. Never create duplicate IDs.
2. Never exceed demo max level (5).
3. Never create items with >25% single-stat bonus in demo.
4. Never create enemies exceeding 2× base demo stats.
5. Always reference existing loot tables or define new ones properly.

---

# END OF DOCUMENT
