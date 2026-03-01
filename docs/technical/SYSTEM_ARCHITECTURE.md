# SYSTEM_ARCHITECTURE.md
# Project: [Working Title TBD]
# Engine: Godot 4.x
# Architecture Version: Demo Foundation

---

# 1. ARCHITECTURE PRINCIPLES

1. Host authoritative multiplayer.
2. Data-driven definitions (JSON for enemies, items, missions).
3. Scene modularity (Overworld, Dungeon, Minigame separated).
4. Systems isolated via Autoload managers.
5. No circular dependencies between systems.
6. Demo architecture must support future expansion.

---

# 2. HIGH LEVEL SYSTEM MAP

GameRoot
│
├── SceneManager
├── MultiplayerManager
├── GameState
├── SaveManager
├── PlayerManager
├── MissionManager
├── DungeonManager
├── EconomyManager
├── TimeManager
├── InventoryManager
├── CombatManager
├── UIManager
└── DataManager

All managers except SceneManager and UIManager are Autoload singletons.

---

# 3. SCENE STRUCTURE

## 3.1 Root Scene

Main.tscn

Nodes:
- SceneManager
- UIManager
- AudioManager

All gameplay scenes are loaded dynamically under SceneManager.

---

## 3.2 Scene Types

OverworldScene.tscn
DungeonScene.tscn
Minigame_Delivery.tscn
CutsceneScene.tscn

Rules:
- Only one gameplay scene active at a time.
- MultiplayerManager persists across scene changes.

---

# 4. AUTOLOAD SINGLETONS

All below must be registered in Project Settings → Autoload.

---

## 4.1 GameState

Purpose:
Global runtime state container.

Tracks:
- CurrentSceneType
- CurrentMissionID
- PlayerCount
- IsHost
- IsInDungeon
- IsPaused
- CurrentDay
- CurrentTimeOfDay
- DungeonScalingData

No gameplay logic allowed inside GameState.
Only state storage.

---

## 4.2 SaveManager

Responsibilities:
- Save world data
- Load world data
- Serialize/deserialize JSON
- Persist dungeon scaling

Stored Data:
- Player stats
- Player levels
- Inventory
- Money
- Dungeon completion count
- Story progression
- Global statistics

Save rules:
- Allowed outside mission states
- Not allowed during dungeon combat

---

## 4.3 MultiplayerManager

Model:
Host authoritative

Rules:
- Host simulates world state
- Clients receive replicated state
- All combat logic runs on host
- All loot spawning runs on host

Responsibilities:
- Player spawn sync
- RPC validation
- Authority checks
- Scene sync

Important:
No client-side authoritative gameplay logic allowed.

---

## 4.4 PlayerManager

Responsibilities:
- Spawn players
- Track player stats
- Apply upgrades
- Handle leveling

PlayerData structure:
- Level
- XP
- SkillPoints
- Stats
- InventoryRef

---

## 4.5 InventoryManager

Inventory Type:
List-based

Responsibilities:
- AddItem()
- RemoveItem()
- CheckCapacity()
- ApplyPassiveEffects()

Items:
Loaded from JSON definitions.

No drag-and-drop system required.

---

## 4.6 CombatManager

Responsible for:
- Enemy spawning
- Damage calculation
- Loot drops
- Boss triggers
- Combat resolution

Rules:
- All damage calculations executed on host
- Loot spawned on host
- Clients receive replicated spawn events

Stat Formula Model:
DamageDealt = BaseDamage * (1 + Modifiers)

---

## 4.7 DungeonManager

Tracks:
- DungeonID
- CompletionCount
- DifficultyLevel
- LootMultiplier

Scaling rules:
On completion:
- Increment CompletionCount
- Increase DifficultyLevel

Scaling parameters:
- EnemyCountMultiplier
- SpawnRateMultiplier
- LootQualityMultiplier

Persist scaling in SaveManager.

---

## 4.8 EconomyManager

Tracks:
- PlayerMoney
- Rent
- IncomeEvents

Responsibilities:
- AddMoney()
- DeductMoney()
- SplitSharedIncome()

Future-proof:
Must support:
- Dealer system
- Debt system
- Interest rates

Demo:
Debt system disabled.

---

## 4.9 TimeManager

Tracks:
- CurrentTime
- Day/Night state

Rules:
- Active in Overworld only
- Pauses when entering Dungeon
- Pauses during Cutscenes

Exposed signals:
- OnDayStart
- OnNightStart

---

## 4.10 MissionManager

Tracks:
- ActiveMissionID
- MissionState
- Objectives

Mission states:
- NotStarted
- Active
- Completed
- Failed

Mission data loaded from JSON.

Mission dungeon:
Cannot be replayed after completion.

---

## 4.11 DataManager

Loads JSON definitions at game start:

Data types:
- Enemies.json
- Items.json
- Missions.json
- Dungeons.json

All systems must reference DataManager for definitions.
No hardcoded enemy stats allowed.

---

# 5. PLAYER SCENE STRUCTURE

Player.tscn

Nodes:
- CharacterBody2D
- CollisionShape2D
- Sprite2D
- WeaponPrimary
- AbilitySlot1
- AbilitySlot2
- HealthComponent
- StaminaComponent
- NetworkSyncComponent

Important:
Combat logic does NOT live in Player.
CombatManager handles combat resolution.

---

# 6. ENEMY SCENE STRUCTURE

Enemy.tscn

Nodes:
- CharacterBody2D
- CollisionShape2D
- Sprite2D
- HealthComponent
- AIComponent
- LootDropComponent

Enemy type defined by:
EnemyID loaded from JSON.

---

# 7. DUNGEON FLOW

When entering dungeon:

1. OverworldScene pauses
2. TimeManager pauses
3. DungeonScene loads
4. DungeonManager initializes scaling
5. CombatManager spawns first wave

Exit conditions:
- Boss defeated → reward → return to overworld
- Player death → respawn → apply penalty

---

# 8. MULTIPLAYER FLOW

Host:
- Spawns dungeon
- Controls enemy AI
- Calculates damage
- Spawns loot

Clients:
- Send input
- Receive authoritative state

All RPCs must validate:
- Authority
- Player ownership

---

# 9. SAVE DATA STRUCTURE (SIMPLIFIED)

{
  "players": [
    {
      "level": 3,
      "xp": 450,
      "money": 320,
      "inventory": [],
      "skills": []
    }
  ],
  "dungeons": {
    "crab_cave": {
      "completed": true
    },
    "replay_dungeon_1": {
      "completion_count": 4,
      "difficulty_level": 4
    }
  },
  "story_progress": 2,
  "stats": {}
}

---

# 10. DEMO CONTENT LIMITS

Enemies:
- 1 Melee
- 1 Ranged
- 1 Boss

Passive Items:
- 10 maximum

Max Player Level:
- 5

Max Skill Points:
- 4 spendable

---

# 11. FUTURE EXPANSION READINESS

Architecture must support later addition of:

- Dealer system
- Debt system
- Reputation system
- Farming system
- Street combat system
- Police system
- Rival dealers
- Online multiplayer

No system should assume demo-only limitations.

---

# END OF DOCUMENT
