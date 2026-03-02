# Phase 2: Combat Core — Enemies, Damage, Loot

**Goal:** Enemies spawn from JSON data, the player auto-fires a weapon, CombatManager calculates damage (with crit/dodge), enemies drop loot on death, and items go into the player's inventory via InventoryManager.

**Depends on:** Phase 1 (Player, PlayerManager, HealthComponent)

---

## What This Phase Delivers

- Fully implemented `CombatManager` — damage calculation with crit/dodge, enemy spawning, loot resolution
- Fully implemented `InventoryManager` — per-player item lists, passive effect calculation feeding into PlayerManager
- `Enemy.tscn` — CharacterBody2D with AI states (IDLE/CHASE/ATTACK/DEAD) for melee/ranged types
- `AIComponent` — state machine supporting melee chase, ranged retreat+shoot, boss behaviour
- `WeaponPrimary` — auto-fire projectiles toward mouse at `attack_speed` rate
- `Projectile.tscn` — Area2D projectile for player and ranged enemies
- `LootPickup.tscn` — Area2D pickup that grants items or money on player contact
- Updated TestPlayground with enemy spawning for combat verification

---

## File Map

```
scripts/
├── managers/
│   ├── combat_manager.gd            # FULLY IMPLEMENTED — damage, spawning, loot
│   └── inventory_manager.gd         # FULLY IMPLEMENTED — items, passive modifiers
├── entities/
│   ├── enemy.gd                     # Enemy controller, initialized from DataManager
│   ├── projectile.gd                # Moves in direction, damages on hit
│   └── loot_pickup.gd               # Grants item/money on player contact
└── components/
    ├── ai_component.gd              # State machine: IDLE → CHASE → ATTACK → DEAD
    └── weapon_primary.gd            # Auto-fire toward mouse at attack_speed

scenes/
├── entities/
│   ├── Enemy.tscn
│   ├── Projectile.tscn
│   └── LootPickup.tscn
└── TestPlayground.tscn              # Updated with enemy spawn keys
```

---

## Developer Guide

### How Damage Works

All damage flows through `CombatManager.apply_damage()`:

```
1. Attacker rolls crit: random < attacker's crit_chance → damage × 2
2. Defender rolls dodge: random < defender's dodge_chance → damage = 0
3. Final damage applied to target's HealthComponent
4. CombatManager emits damage_dealt signal (used by UI for popups in Phase 3)
```

Formula: `DamageDealt = BaseDamage × CritMultiplier × (1 - DodgeResult)`

### How Enemy AI Works

Each enemy has an `AIComponent` with a state machine. Behaviour varies by type from JSON:

| Type | Chase | Attack Range | Attack Pattern |
|------|-------|-------------|----------------|
| melee | Moves toward player | 30px | Deals damage on contact via timer |
| ranged | Keeps distance (~150px) | 200px | Fires projectile at player |
| boss | Chases slowly | 50px | Melee slam + special phase logic (Phase 4) |

States: `IDLE → CHASE → ATTACK → DEAD`
- IDLE: No target in detection range
- CHASE: Target detected, move toward (melee) or maintain distance (ranged)
- ATTACK: In range, attacking on cooldown
- DEAD: Play death, trigger loot drop, queue_free

### How to Change Enemy Stats

Edit `data/enemies.json`. Stats are base values — scaling is applied at runtime:
```
FinalHealth = base_health × (1 + completion_count × enemy_health_scaling)
FinalDamage = base_damage × (1 + completion_count × enemy_damage_scaling)
```

### How Loot Tables Work

On enemy death:
1. CombatManager reads enemy's `loot_table_id`
2. Resolves weighted random from `loot_tables.json`
3. Spawns `LootPickup` at enemy death position
4. Also drops money (random between min-max from enemy data)

Loot drop chance: Not every enemy drops an item. Base drop rate is 30% for common enemies.

### How Inventory Works

`InventoryManager` stores a list of item IDs per player:
```gdscript
InventoryManager.add_item(1, "damage_ring")    # → true
InventoryManager.get_inventory(1)               # → ["damage_ring"]
InventoryManager.get_passive_modifiers(1)       # → {"damage_percent": 0.10}
```

Passive modifiers are recalculated on add/remove and fed into `PlayerManager.get_effective_stat()` automatically (already wired in Phase 1).

### Collision Layers

| Layer Bit | Value | Used For |
|-----------|-------|----------|
| 1 | 1 | Environment/walls (StaticBody2D) |
| 2 | 2 | Player (CharacterBody2D) |
| 3 | 4 | Enemies (CharacterBody2D) |
| 4 | 8 | Pickups (Area2D) |

- Player: layer=2, mask=1 (collides with walls only)
- Enemy: layer=4, mask=1 (collides with walls only)
- Player projectile: layer=0, mask=4 (detects enemies)
- Enemy projectile: layer=0, mask=2 (detects players)
- Loot pickup: layer=8, mask=2 (detects players)

### How to Add an Item to a Player (Debug)

```gdscript
InventoryManager.add_item(1, "golden_idol")
# Stats update immediately via PlayerManager
```

---

## Testing

### Automated Test Scripts

#### 1. Python Combat Math Validation (no Godot required)

```bash
python3 tests/test_phase2_json.py
```

**Tests: 319 checks.** What it covers:
- Enemy data integrity (3 enemies, all required fields)
- Enemy stat ranges and boss stat superiority
- Loot table integrity and cross-references
- Damage formula correctness (base × crit multiplier)
- Item effects validation (stats, modifier types, values)
- Scaling multiplier config verification
- Inventory modifier aggregation math
- Death penalty config

#### 2. GDScript Runtime Tests (requires Godot)

```bash
godot --headless --path . --scene tests/TestPhase2Runtime.tscn
```

**Tests: ~70 checks.** What it covers:
- CombatManager API (apply_damage, spawn_enemy, spawn_wave, clear)
- InventoryManager API (add, remove, modifiers, remove_random)
- EconomyManager add/deduct money
- Enemy spawning from JSON with correct stats (health, damage, type)
- Scaled enemy spawning (health/damage multipliers)
- Damage calculation returns correct format (amount, is_crit, is_dodge)
- Loot table resolution produces valid weighted items
- Inventory modifier aggregation feeds into PlayerManager stats
- Wave spawning with correct counts
- Enemy death triggers XP reward

### Manual Testing Checklist (Human Required)

- [x] Run TestPlayground — player and enemies visible on screen
- [x] Player auto-fires projectiles toward mouse cursor (left click held or auto)
- [x] Projectiles visually travel from player toward aim direction
- [x] Melee enemies (Cave Rat) chase the player
- [x] Ranged enemies (Spitter Crab) keep distance and fire projectiles
- [x] Enemy projectiles damage the player (health drops in debug overlay)
- [x] Player projectiles damage enemies (enemies flash/die)
- [x] Dead enemies drop loot pickups (colored squares on ground)
- [x] Walking over loot pickup adds item to inventory
- [x] Money pickups increase player money (shown in debug overlay)
- [x] XP increases when enemies die (shown in debug overlay)
- [x] F4 spawns a Cave Rat, F5 spawns a Spitter Crab, F6 spawns Crab King
- [x] F7 gives a random item (check debug overlay Items count increases)
- [x] F8 clears all enemies
- [x] Boss (Crab King) is visibly larger and purple-colored
- [x] Items modify player stats (give damage_ring via F7, check damage in debug overlay)
- [x] Enemies stay within walls
