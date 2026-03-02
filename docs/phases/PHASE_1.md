# Phase 1: Player Character — Movement, Stats, Components

**Goal:** A controllable player character with data-driven stats, health/stamina components, XP/leveling system, and a debug overlay for verification.

**Depends on:** Phase 0 (DataManager, GameState, project skeleton)

---

## What This Phase Delivers

- Fully implemented `PlayerManager` with stat computation, XP curve, leveling, soft caps
- `Player.tscn` scene with 8-directional movement, collision, placeholder sprite
- `HealthComponent` with damage/heal, signals, and death
- `StaminaComponent` with usage, passive regen, signals
- `NetworkSyncComponent` stub (prepared for Phase 7)
- `TestPlayground.tscn` updated with player spawn point and a debug stat overlay
- Test scripts (Python + GDScript) for all Phase 1 systems

---

## File Map

```
scripts/
├── managers/
│   └── player_manager.gd           # FULLY IMPLEMENTED — stats, XP, leveling
├── entities/
│   └── player.gd                   # 8-directional movement, reads speed from PlayerManager
└── components/
    ├── health_component.gd          # take_damage(), heal(), signals, death
    ├── stamina_component.gd         # use_stamina(), passive regen, signals
    └── network_sync_component.gd    # Stub for Phase 7

scenes/
├── entities/
│   └── Player.tscn                  # CharacterBody2D with all components
├── TestPlayground.tscn              # Updated with player spawn + debug overlay
└── ui/
    └── DebugOverlay.tscn            # Real-time stat display

tests/
├── test_phase1_json.py              # Python: XP curve math, stat formulas
├── test_phase1_runtime.gd           # GDScript: PlayerManager API, components
└── TestPhase1Runtime.tscn           # Scene for runtime tests
```

---

## Developer Guide

### How the Stat System Works

Player stats are computed by `PlayerManager.get_effective_stat()` using this formula:

```
EffectiveStat = (BaseStat + FlatBonuses) × (1 + PercentBonuses)
```

Where bonuses come from three sources (layered in order):
1. **Level-up bonuses** — from `global_config.json` → `level_up_bonuses`
2. **Item passives** — from `InventoryManager.get_passive_modifiers()` (Phase 2)
3. **Skill tree** — from unlocked skills (Phase 3)

Percentage stats (`crit_chance`, `dodge_chance`) are subject to **soft caps** defined in `global_config.json` → `soft_caps`.

### How to Change Player Base Stats

Edit `data/global_config.json` → `player_base_stats`:
```json
"player_base_stats": {
    "health": 100,
    "stamina": 100,
    "damage": 10,
    "attack_speed": 1.0,
    "move_speed": 120,
    "crit_chance": 0.05,
    "dodge_chance": 0.05
}
```

### How to Change Level-Up Bonuses

Edit `data/global_config.json` → `level_up_bonuses`:
```json
"level_up_bonuses": {
    "health": 5,
    "damage_percent": 0.02,
    "attack_speed_percent": 0.01,
    "move_speed_percent": 0.01
}
```
- `health` is a **flat** bonus per level (Level 3 = +10 health)
- `_percent` suffixed keys are **percent** bonuses per level (Level 3 = +4% damage)

### How to Change the XP Curve

Edit `data/global_config.json`:
```json
"base_xp_per_level": 100,
"xp_curve_exponent": 1.5
```

Formula: `XP_required = base_xp_per_level × level ^ xp_curve_exponent`

| Level | XP Required | Cumulative | Note |
|-------|-------------|------------|------|
| 1→2   | 100         | 100        | 100 × 1^1.5 |
| 2→3   | 283         | 383        | 100 × 2^1.5, rounded |
| 3→4   | 520         | 903        | 100 × 3^1.5, rounded (spec says 519, we use round) |
| 4→5   | 800         | 1703       | 100 × 4^1.5 |

### How to Change Soft Caps

Edit `data/global_config.json` → `soft_caps`:
```json
"soft_caps": {
    "crit_chance": { "max": 0.40, "scaling_factor": 0.08 },
    "dodge_chance": { "max": 0.40, "scaling_factor": 0.08 }
}
```
- `max`: The absolute ceiling the stat can never exceed
- `scaling_factor`: Diminishing returns start as raw value approaches max

Soft cap formula: `capped = max × (1 - e^(-raw / scaling_factor))`

### How to Change Health/Stamina Regen

HealthComponent has no passive regen (healed by items/events only).

StaminaComponent regenerates passively:
- Rate: `stamina_regen_rate` (default 15.0 per second) — editable in the component
- Delay: `stamina_regen_delay` (default 1.0 second after last use) — editable in the component

### How the Player Scene is Structured

```
Player (CharacterBody2D)
├── CollisionShape2D (RectangleShape2D — placeholder)
├── Sprite2D (ColorRect via placeholder texture)
├── HealthComponent (Node)
├── StaminaComponent (Node)
├── NetworkSyncComponent (Node — stub)
├── WeaponPrimary (Node2D — stub for Phase 2)
├── AbilitySlot1 (Node — stub for Phase 2)
└── AbilitySlot2 (Node — stub for Phase 2)
```

### How to Spawn the Player Programmatically

```gdscript
# From any script:
var player = PlayerManager.spawn_player(1)  # player_id = 1
# Player is added to the current scene automatically

# Get stats:
var stats = PlayerManager.get_stats(1)
print(stats.health)  # 100 at level 1

# Add XP:
PlayerManager.add_xp(1, 50)
print(PlayerManager.get_level(1))  # Still 1 (need 100 XP)
PlayerManager.add_xp(1, 50)
print(PlayerManager.get_level(1))  # Now 2
```

### How to Use the Debug Overlay

The debug overlay is shown in TestPlayground and displays real-time stats:
- Level, XP / XP needed
- Health / Max Health
- Stamina / Max Stamina
- All computed stats (damage, speed, crit, dodge)

Toggle with F3 key.

---

## Testing

### Automated Test Scripts

#### 1. Python XP/Stat Math Validation (no Godot required)

Validates XP curve math, level-up bonus calculations, and soft cap formula against the spec.

```bash
python3 tests/test_phase1_json.py
```

**What it covers:**
- XP thresholds match formula for levels 1-5
- Level-up bonuses compute correctly at each level
- Soft cap formula produces correct diminishing returns
- Max level cap (5) is enforced
- Stat formulas: base + flat + percent

#### 2. GDScript Runtime Tests (requires Godot)

```bash
godot --headless --path . --scene tests/TestPhase1Runtime.tscn
```

**What it covers:**
- PlayerManager.spawn_player() returns valid Player node
- Player has all expected child nodes (CollisionShape2D, Sprite2D, HealthComponent, etc.)
- PlayerManager stat computation at each level
- XP addition and level-up triggers correctly
- Level cap at 5 enforced
- HealthComponent: take_damage, heal, death signal
- StaminaComponent: use_stamina, regen, signal
- Player movement responds to input direction
- Signals fire correctly (player_leveled_up, stats_changed, health_changed, died)

### Manual Testing Checklist (Human Required)

- [ ] Run TestPlayground — player character (colored rectangle) appears on screen
- [ ] WASD moves the player in 8 directions smoothly
- [ ] Movement speed visually matches (120 pixels/sec at level 1)
- [ ] Diagonal movement is normalized (not faster than cardinal)
- [ ] F3 toggles debug overlay showing live stats
- [ ] Debug overlay updates when XP is added (press a test key or use debugger)
- [ ] Player stops at scene edges / collision boundaries
