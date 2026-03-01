# GAME DESIGN DOCUMENT (GDD)
# Project: [Working Title TBD]
# Engine: Godot 4.x
# Version: Pre-Production Lock (Demo Scope)

---

# 1. PROJECT OVERVIEW

## Genre Identity

Primary:
- Comedy-first Roguelite Narrative Adventure

Secondary:
- Light Economy Simulation

Multiplayer:
- LAN Co-op (Host Authoritative)
- 1–4 players
- Cannot change player count after world creation

Art Style:
- 2D Pixel Art
- 2.5D perspective (Stardew-style camera)

---

# 2. DESIGN PHILOSOPHY

Primary Philosophy:
> Comedy first. Systems exist to enable absurdity and social chaos.

Secondary Philosophy:
> Progression should feel satisfying but does not need deep mathematical tuning.

All systems should support:
- Social awkwardness
- Dark satire
- Escalating power fantasy
- Replayable dungeon escalation

---

# 3. GAME STRUCTURE

## Full Game Target
~50 hours

## Demo Target
~2.5 hours

---

## Chapter Structure

Year 1 – Bay Campus (Demo + Tutorial)
Year 2 – Rose Hill
Year 3 – Marlborough
Year 4 – Phillips Parade

Only Year 1 is in scope for demo.

---

# 4. CORE GAMEPLAY LOOPS

## 4.1 Overworld Loop

1. Accept mission
2. Explore campus
3. Complete delivery mini-game or side quest
4. Enter dungeon
5. Gain money, XP, items
6. Upgrade character
7. Repeat until story gate reached

---

## 4.2 Dungeon Loop

Structure:
- Entry
- Combat rooms
- Random events
- Boss fight
- Reward room
- Exit

Dungeon duration target:
15 minutes

Dungeon types:
- Story Dungeon (non-replayable)
- Replayable Dungeon (persistent scaling)

---

# 5. DEMO CONTENT LOCK

Included Systems:

- Bay Campus overworld
- Mission 1 (Papers Intro)
- Mission 2 (Crab Cave – story dungeon)
- 1 Replayable dungeon
- Delivery mini-game (player delivers Luca’s bud)
- XP & Level system (Max Level 5)
- Limited skill tree
- 10 passive items
- 3 enemy types (melee, ranged, boss)
- Dungeon scaling system
- Weekly rent mechanic
- Save system
- LAN multiplayer

Excluded From Demo:

- Farming system
- Dealer system
- Debt system
- Reputation system
- Street combat

---

# 6. PLAYER SYSTEMS

## 6.1 Core Stats

Health: Integer (0–100)
Stamina: Integer (0–100)
Damage: Float
AttackSpeed: Float
MoveSpeed: Float
CritChance: Percentage
DodgeChance: Percentage

---

## 6.2 Weapon System

- 1 Primary weapon (auto-fire)
- 2 Secondary abilities (manual trigger)
- Cannot swap weapons mid-dungeon
- Permanent upgrades
- Soft stat caps

---

## 6.3 Level System (Demo)

Max Level: 5  
Skill Points: 1 per level  

Skill Categories:
- Combat
- Economy
- Personality

Demo version includes limited nodes only.

---

# 7. INVENTORY SYSTEM

Type:
List-based inventory (scrollable list)

Properties:
- No grid
- No manual rearranging
- No item dropping
- Loot disappears if not picked up
- Rarity tiers:
  - Common
  - Rare
  - Epic

---

# 8. ECONOMY (DEMO)

Money Sources:
- Delivery mini-game
- Side quests
- Dungeon loot

Bud Source:
- Fixed story supply from Luca

Debt:
- Not present in demo

Rent:
- Weekly
- Value tuned during testing

---

# 9. DELIVERY MINI-GAME

View:
Bird’s-eye driving map

Core Mechanics:
- Deliver to marked NPCs
- Earn money per delivery
- No failure states in demo

Future-ready architecture must support:
- Police events
- Rival dealers
- Time limits
- Risk modifiers

---

# 10. DUNGEON SYSTEM

## 10.1 Story Dungeon (Crab Cave)

- Handcrafted
- Non-replayable
- Story boss
- No permanent death penalty (mission reset)

---

## 10.2 Replayable Dungeon

Properties:
- Persistent difficulty level
- Infinite replayability
- Scaling per completion
- Scaling persists in save file

Scaling Increases:
- Enemy count
- Spawn frequency
- New enemy behaviors
- Loot quality multiplier

---

# 11. TIME SYSTEM

Day length:
10–20 minutes

Night length:
5–10 minutes

Rules:
- Applies to overworld only
- Pauses during dungeon
- Night changes overworld NPC presence
- No dungeon difficulty effect

---

# 12. MULTIPLAYER SYSTEM

Model:
Host Authoritative (LAN)

Rules:
- Shared house
- Individual money
- Loot is first-come-first-serve
- Shared dungeon instance
- One save file per world
- Player count locked on world creation

Allowed Chaos:
- Chest loot stealing allowed
- Corpse loot not stealable
- Future systems may allow debt-triggering grief

---

# 13. NPC SYSTEM (DEMO)

Primary NPCs:
- Luka (dealer)
- Lewis (hidden roommate)
- Hannan (tutorial helper)
- Jack (comic device)

Dialogue:
- Light comedic
- Minimal branching
- No permanent consequences
- All relationships recoverable

NPC Behavior:
- Static spawn
- Basic movement allowed
- No schedule system

---

# 14. FAILURE SYSTEM

Dungeon Death:
- Lose some money
- Lose random items
- Respawn at house

Mission Dungeon Death:
- Restart mission
- No permanent loss

Game Over:
Not possible in demo

---

# 15. SAVE SYSTEM

Single save file per world.

Tracks:
- Player levels
- Skill selections
- Inventory
- Money
- Dungeon completion count
- Story progression
- Gameplay statistics

Save allowed:
Anytime outside mission states

---

# END OF DOCUMENT
