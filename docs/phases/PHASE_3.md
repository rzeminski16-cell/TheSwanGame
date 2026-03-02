# Phase 3: Economy, UI, Skill Tree

**Goal:** Skill tree with unlocking and stat modifiers, HUD with health/stamina/XP bars, inventory and skill tree panels, floating damage numbers, notifications, pause menu, and a fully functional rent/economy system with skill bonuses.

**Depends on:** Phase 2 (CombatManager, InventoryManager, EconomyManager stub)

---

## What This Phase Delivers

- Fully implemented `SkillManager` — skill unlocking with requirements, SP cost, stat modifier aggregation
- Updated `PlayerManager` — skill modifiers now feed into `get_effective_stat()` alongside item modifiers
- Updated `EconomyManager` — rent payment, rent reduction from skills, delivery rewards, money drop bonuses
- `HUD` — real-time health/stamina/XP bars, level, money, item count, rent display, skill point indicator
- `SkillTreePanel` — 15 nodes across 3 categories (Combat/Economy/Personality), click to unlock
- `InventoryPanel` — scrollable item list with rarity colors and effect descriptions
- `DamagePopup` — floating numbers on damage hits (red normal, yellow crit, grey dodge)
- `NotificationToast` — slide-in messages for level ups, item pickups, skill unlocks, rent
- `PauseMenu` — ESC to pause/resume with game tree pausing
- Updated `UIManager` — wires all UI together, handles input routing, signal connections
- Updated TestPlayground with new Phase 3 debug keys

---

## File Map

```
scripts/
├── managers/
│   ├── skill_manager.gd           # NEW — skill unlocking, requirements, modifiers
│   ├── player_manager.gd          # UPDATED — skill modifiers in stat computation
│   └── economy_manager.gd         # UPDATED — rent, delivery, money drop bonuses
├── ui/
│   ├── hud.gd                     # NEW — in-game HUD with bars and labels
│   ├── skill_tree_panel.gd        # NEW — 15-node skill tree UI
│   ├── inventory_panel.gd         # NEW — item list with effects
│   ├── damage_popup.gd            # NEW — floating damage numbers
│   ├── notification_toast.gd      # NEW — toast notifications
│   └── pause_menu.gd              # NEW — pause screen
└── ui_manager.gd                  # UPDATED — wires all UI, handles input

scenes/
└── ui/
    ├── HUD.tscn                   # NEW — HUD container
    ├── SkillTreePanel.tscn        # NEW — skill tree panel
    ├── InventoryPanel.tscn        # NEW — inventory panel
    └── PauseMenu.tscn             # NEW — pause menu

tests/
├── test_phase3_json.py            # Python: 305 checks — skills, economy, stat formulas
├── test_phase3_runtime.gd         # GDScript: ~50 checks — SkillManager, EconomyManager
└── TestPhase3Runtime.tscn         # Scene for runtime tests
```

---

## Developer Guide

### How the Skill System Works

`SkillManager` is an autoload singleton that manages skill unlocking. It reads skill definitions from `skills.json` via DataManager.

**Unlock flow:**
```
1. Player levels up → gains 1 skill point (from PlayerManager)
2. Player opens Skill Tree (K key)
3. Player clicks an available skill node
4. SkillManager.unlock_skill() checks:
   a. Skill not already unlocked
   b. Player has >= 1 SP
   c. All requirement skills are unlocked
5. On success: deducts 1 SP, adds to unlocked list, recalculates modifiers
6. PlayerManager.stats_changed emitted → all stats recompute
```

**Modifier aggregation:**
```gdscript
SkillManager.get_skill_modifiers(1)
# Returns: {"damage_percent": 0.05, "health_flat": 10, ...}
# Same format as InventoryManager.get_passive_modifiers()
```

### How Stats Now Work (3-Layer Bonuses)

`PlayerManager.get_effective_stat()` computes stats from three bonus sources:

```
EffectiveStat = (BaseStat + FlatBonuses) × (1 + PercentBonuses)

FlatBonuses = LevelFlat + ItemFlat + SkillFlat
PercentBonuses = LevelPercent + ItemPercent + SkillPercent
```

Sources (in order):
1. **Level-up bonuses** — from `global_config.json` → `level_up_bonuses`
2. **Item passives** — from `InventoryManager.get_passive_modifiers()`
3. **Skill tree** — from `SkillManager.get_skill_modifiers()`

### How to Unlock a Skill Programmatically

```gdscript
# Give a skill point
var data = PlayerManager.get_save_data(1)
data["skill_points"] = data.get("skill_points", 0) + 1
PlayerManager.load_save_data(1, data)

# Check and unlock
if SkillManager.can_unlock_skill(1, "combat_damage_1"):
    SkillManager.unlock_skill(1, "combat_damage_1")

# Check result
print(SkillManager.is_skill_unlocked(1, "combat_damage_1"))  # true
print(SkillManager.get_skill_modifiers(1))  # {"damage_percent": 0.05}
```

### How Rent Works

```gdscript
# Base rent from global_config.json
EconomyManager.get_weekly_rent_base()  # → 250

# Effective rent (applies skill bonuses like Haggler -10%)
EconomyManager.get_effective_rent(1)   # → 225 (with Haggler)

# Pay rent (deducts from player money)
EconomyManager.pay_rent(1)  # → true/false
```

Rent formula: `EffectiveRent = BaseRent × (1 - rent_reduction_percent)`

### How Delivery Rewards Work

```gdscript
# Base delivery reward from global_config.json
EconomyManager.get_delivery_reward(1)  # → 50 (base)
# With Smooth Talker skill: 50 × 1.10 = 55
```

### How the UI System Works

**UIManager** (CanvasLayer, child of Main.tscn) manages all UI:

| Component | Toggle | Description |
|-----------|--------|-------------|
| HUD | Always visible | Health/stamina/XP bars, money, items, rent, SP indicator |
| Skill Tree | K key | 15 nodes in 3 columns, click to unlock |
| Inventory | I key | Scrollable item list with rarity colors |
| Pause Menu | ESC key | Pauses game tree, resume button |
| Damage Popups | Automatic | Float up and fade on every hit |
| Notifications | Automatic | Toast messages for events |

**Input priority:** ESC closes open panels before pausing. Only one panel open at a time.

**Damage popup colors:**
- Red: Normal damage
- Yellow + larger: Critical hit
- Grey "DODGE": Dodge roll

**Notification triggers:**
- Level up
- Item pickup
- Skill unlocked
- Rent paid / rent failed

### How to Change Skill Tree Data

Edit `data/skills.json`. Each skill has:
```json
{
    "id": "combat_damage_1",
    "category": "combat",
    "display_name": "Sharpened Instinct",
    "description": "+5% damage",
    "effects": [
        { "stat": "damage", "modifier_type": "percent", "value": 0.05 }
    ],
    "max_level": 1,
    "requirements": []
}
```

- `requirements`: Array of skill IDs that must be unlocked first
- `effects`: Same format as item effects (stat + modifier_type + value)
- `category`: "combat", "economy", or "personality"

### Skill Tree Structure

```
COMBAT                    ECONOMY                   PERSONALITY
────────────────         ────────────────          ────────────────
Sharpened Instinct       Smooth Talker             Slippery
  (+5% damage)             (+10% delivery)           (+5% dodge)
  └─ Keen Eye            └─ Lucky Find             └─ Giant Slayer
     (+5% crit)             (+5% loot chance)         (+5% boss dmg)
                         └─ Fast Learner           └─ Bully
                            (+5% XP gain)             (+5% elite dmg)

Quick Hands              Haggler                    Endurance
  (+5% atk speed)          (-10% rent)               (+10 stamina)
                         └─ Penny Pincher           └─ Dungeon Runner
Tough Skin                  (+10% money drop)         (+5% dungeon speed)
  (+10 health)
  └─ Fleet Footed
     (+5% move speed)
```

---

## Testing

### Automated Test Scripts

#### 1. Python Skill/Economy Validation (no Godot required)

```bash
python3 tests/test_phase3_json.py
```

**Tests: 305 checks.** What it covers:
- Skill data integrity (15 skills, all required fields)
- Skill requirements validation (no circular deps, same-category reqs)
- Skill tree depth limits
- Skill effects validation (stat, modifier_type, value)
- Skill modifier aggregation math (all 3 categories)
- Economy formulas (rent, delivery, skill bonuses)
- Stat computation with skill modifiers
- Demo content blueprint compliance (15 nodes, max level 5, 4 SP)
- Cross-reference validation (no self-requirements, all IDs exist)

#### 2. GDScript Runtime Tests (requires Godot)

```bash
godot --headless --path . --scene tests/TestPhase3Runtime.tscn
```

**Tests: ~50 checks.** What it covers:
- SkillManager singleton existence and API
- Skill unlock with SP deduction
- Skill requirements enforcement
- Skill modifier aggregation
- Skill modifiers affect PlayerManager stats
- EconomyManager rent payment (success and failure)
- Rent reduction with Haggler skill
- Delivery reward with Smooth Talker skill
- Money drop bonus with Penny Pincher skill
- Cannot unlock without skill points
- Cannot unlock same skill twice
- Available skills query

### Manual Testing Checklist (Human Required)

- [x] Run TestPlayground — HUD visible (health/stamina/XP bars in top-left)
- [x] HUD shows money in bottom-left (yellow text)
- [x] HUD shows rent amount
- [x] HUD updates health bar when taking damage (F2)
- [x] HUD updates XP bar when gaining XP (F1)
- [x] Level up shows notification toast at top-center
- [x] K opens Skill Tree panel with 3 columns
- [x] Root skills (no requirements) are blue/clickable when SP available
- [x] Locked skills (missing requirements) are grey/disabled
- [x] Click an available skill → it turns green, SP decreases
- [x] Unlocking a prerequisite enables dependent skills
- [x] K again closes Skill Tree panel
- [x] I opens Inventory panel — shows items with rarity colors
- [x] F7 gives item — notification toast + inventory updates
- [x] Items show their stat effects (green for positive, red for negative)
- [x] Duplicate items show count (e.g. "Rusty Ring x2")
- [x] I again closes Inventory panel
- [x] ESC closes open panels (Skill Tree or Inventory) before pausing
- [x] ESC pauses game — "PAUSED" overlay with Resume button
- [x] Resume button or ESC again unpauses
- [x] Game tree actually pauses (enemies freeze, player stops)
- [x] Spawn enemies (F4/F5/F6) — damage popups appear on hits
- [x] Normal hits: red numbers
- [x] Critical hits: larger yellow numbers with "!"
- [x] Dodged attacks: grey "DODGE" text
- [x] F10 adds 500 money — HUD updates
- [x] F11 pays rent — notification shows success or failure
- [x] Unlocking damage skill visibly increases damage stat in debug overlay (F3)
- [x] F12 heals player to full — health bar fills up
