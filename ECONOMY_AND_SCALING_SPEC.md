# ECONOMY_AND_SCALING_SPEC.md
# Project: [Working Title TBD]
# Version: Demo Foundation (Expandable)

---

# 1. DESIGN INTENT

Economy Goals:
- Early struggle
- Mid demo stability
- Clear feeling of upward momentum
- No infinite runaway exponential growth

Scaling Goals:
- Replayable dungeon becomes harder but fair
- Loot improves with difficulty
- Player power grows along soft curve
- No infinite stat inflation

Demo does NOT require perfect balance.
Demo requires stable curve structure.

---

# 2. CORE ECONOMIC VARIABLES

## 2.1 Player Money

Type: Integer  
Minimum: 0  
No debt in demo  

Money Sources:
- Delivery mini-game
- Side quests
- Dungeon loot

Money Sinks:
- Rent (weekly)
- Future upgrades (not in demo)

---

# 3. DELIVERY MINI-GAME ECONOMY

## 3.1 Base Delivery Value

BaseDeliveryReward = 50

Per successful delivery:
Reward = BaseDeliveryReward × DifficultyModifier

Demo:
DifficultyModifier = 1.0

Future-ready:
DifficultyModifier may scale by:
- Story progression
- Risk multiplier
- Dealer modifier

---

## 3.2 Demo Income Target (Flexible)

Target earnings:
~300–600 per hour (to be tuned during playtesting)

This ensures:
£1000 pacer requires 1.5–2.5 hours depending on performance.

---

# 4. RENT STRUCTURE (DEMO)

Rent is weekly.

Rent formula:

WeeklyRent = BaseRent × StoryStageMultiplier

Demo:
BaseRent = 250 (placeholder)
StoryStageMultiplier = 1

Rent pressure should represent:
30–50% of average weekly income.

Rent tuning is deferred to testing.

---

# 5. XP AND LEVEL SCALING

## 5.1 Level Cap (Demo)

MaxLevel = 5

---

## 5.2 XP Curve

XPRequired(Level) = 100 × Level^1.5

Example values:

Level 1 → 100 XP  
Level 2 → 283 XP  
Level 3 → 519 XP  
Level 4 → 800 XP  
Level 5 → Cap

Curve type:
Mild exponential growth (soft curve).

---

## 5.3 XP Sources

Melee enemy kill: 10 XP  
Ranged enemy kill: 15 XP  
Boss kill: 150 XP  
Side quest: 100–200 XP  

---

# 6. PLAYER STAT SCALING

## 6.1 Base Stat Growth Per Level

On level up:

Health += 5  
Damage += 2%  
AttackSpeed += 1%  
MoveSpeed += 1%  

Stat growth intentionally modest.

---

## 6.2 Soft Caps

Stats must use diminishing returns.

Example formula for percentage stats:

EffectiveStat = Base + (MaxBonus × (1 - e^(-ScalingFactor × PointsInvested)))

Example:

CritChance:
SoftCap = 40%
ScalingFactor = 0.08

This prevents infinite scaling.

---

# 7. DUNGEON SCALING MODEL

Replayable dungeon scaling is persistent.

Each completion increments:

CompletionCount += 1

---

## 7.1 Difficulty Multiplier

DifficultyMultiplier = 1 + (CompletionCount × 0.15)

Example:
Completion 1 → 1.15
Completion 2 → 1.30
Completion 3 → 1.45
Completion 5 → 1.75

Cap recommended at:
3.0 (demo limit)

---

## 7.2 Enemy Scaling

EnemyCountMultiplier = 1 + (CompletionCount × 0.10)

SpawnRateMultiplier = 1 + (CompletionCount × 0.08)

EnemyHealthMultiplier = 1 + (CompletionCount × 0.12)

EnemyDamageMultiplier = 1 + (CompletionCount × 0.08)

Scaling must remain linear in demo.

---

# 8. LOOT SCALING

## 8.1 Loot Quality Multiplier

LootQualityMultiplier = 1 + (CompletionCount × 0.10)

---

## 8.2 Item Rarity Probability

Base rarity distribution:

Common: 70%
Rare: 25%
Epic: 5%

Adjusted by difficulty:

RareChance += CompletionCount × 2%
EpicChance += CompletionCount × 1%

Common decreases proportionally.

Cap Epic at 20%.

---

# 9. MONEY DROPS FROM ENEMIES

Base money drop:

Melee: 5–10  
Ranged: 10–15  
Boss: 150–250  

MoneyDrop = BaseDrop × DifficultyMultiplier

Money drops as floor loot.
First-come-first-serve.

Loot disappears after short timer.

---

# 10. ITEM STAT SCALING

Items scale multiplicatively, not additively.

Example:

DamageBoostItem:
+10% damage (Common)
+15% damage (Rare)
+20% damage (Epic)

No item should exceed:
+25% to single stat in demo.

Stacking:
Multiplicative stacking preferred.

FinalDamage = BaseDamage × ItemModifiers × SkillModifiers

---

# 11. POWER FANTASY TRANSITION (FUTURE)

Late game design intent:

Player growth curve should eventually outpace base enemy scaling.

Future formula:

EnemyScaling = Linear  
PlayerScaling = Slight exponential with diminishing returns

This ensures:
- Early struggle
- Mid-game balance
- Late game dominance

---

# 12. ECONOMIC FAILSAFE RULES

To prevent economy breakage:

1. No passive income in demo.
2. No infinite farm loops.
3. Dungeon entry locks player until completion or death.
4. No stat can exceed 2× base value in demo.
5. XP gain slows sharply near level cap.

---

# 13. BALANCE TESTING METRICS

During playtesting track:

- Average income per hour
- Average dungeon completion time
- Player deaths per dungeon
- Time to reach Level 5
- Money at demo end
- Dungeon difficulty at demo end

If players:
Reach Level 5 too quickly → Increase XP curve exponent  
Reach £1000 too easily → Reduce delivery reward  
Never die → Increase spawn scaling  
Always die → Reduce health multiplier  

---

# 14. EXPANSION READINESS

This model must support future:

- Dealer cuts
- Risk multipliers
- Police penalties
- Debt interest rates
- Farming yields
- Reputation price modifiers

All scaling variables must be data-driven.

No hardcoded numbers inside scripts.

---

# END OF DOCUMENT
