# Weapon Power Stats & Scaling

Weapons contribute to three "power" stats that drive damage calculation:

| Stat | `StatRef` | Typical sources |
|---|---|---|
| Attack Power | `ATTACK` | Swords, daggers, maces, axes |
| Magic Power | `MAGIC_POWER` | Staves, wands, magic-hybrid weapons |
| Divine Power | `DIVINE_POWER` | Holy maces, scepters, prayer focuses |

A weapon can contribute to any combination of these three. A pure sword has only `ATTACK`; a staff has only `MAGIC_POWER`; a holy mace has both `ATTACK` and `DIVINE_POWER`.

## Two sources of contribution

Each weapon contributes to a power stat through **two independent channels**:

1. **Flat base value** — `WeaponResource.base_stats.attack / magic_power / divine_power`.
   - The default value the weapon adds regardless of who wields it (e.g. a basic sword = 5 attack, a basic dagger = 2 attack).
   - Applied like any other gear flat bonus inside `StatCalculator._recalculate_stat_base`.

2. **Scaling** — `WeaponResource.scaling` (a [`WeaponScaling`](../stat/WeaponScaling.gd) resource).
   - Adds value derived from the wielder's attributes and/or other stats.
   - Applied **after** all other stat math, in a second pass (see "Calculation order" below).

## Authoring a `WeaponScaling`

A `WeaponScaling` holds an `entries: Array[WeaponScalingEntry]`. Each entry targets **one** power stat and lists how much it gets from each source.

```
WeaponScaling
└─ entries: [WeaponScalingEntry]
   ├─ stat: ATTACK | MAGIC_POWER | DIVINE_POWER
   ├─ attribute_contributions: [AttributeMultiplier]   # attribute → power
   │  └─ { attribute: STR/DEX/INT/PIE/..., multiplier: float }
   └─ stat_contributions: [StatMultiplier]             # stat → power
      └─ { source_stat: HEALTH/SPEED/..., multiplier: float }
```

`source_stat` **must not** be one of the three power stats — that would cause a feedback loop. A `push_error` fires at runtime if you point one there.

### Example archetypes

| Weapon | Entry: stat | attribute_contributions | stat_contributions |
|---|---|---|---|
| Basic sword | `ATTACK` | `STR × 1.0` | — |
| Dagger | `ATTACK` | `STR × 0.5, DEX × 1.0` | — |
| Staff | `MAGIC_POWER` | `IQ × 1.0` | — |
| Holy mace | `ATTACK` | `STR × 0.8` | — |
| (same weapon, second entry) | `DIVINE_POWER` | `PIE × 1.0` | — |
| Magic dagger | `ATTACK` | `DEX × 0.5` | — |
| (same weapon, second entry) | `MAGIC_POWER` | `IQ × 0.5` | — |
| Health-staff (custom) | `MAGIC_POWER` | — | `HEALTH × 0.1` |
| Speed-dagger (custom) | `ATTACK` | — | `SPEED × 0.8` |

A weapon defines multiple stats by adding multiple entries — one per target power stat.

## Calculation order

Power stats are computed in **two passes** by [`StatCalculator`](../stat/stat_calculator.gd):

1. **Pass 1 — `_recalculate_stat_base`** (runs for every stat):
   `final = base + attribute_growth + level_growth + gear_flat + modifiers`
2. **Pass 2 — `_apply_weapon_scaling`** (runs only for `ATTACK`, `MAGIC_POWER`, `DIVINE_POWER`):
   `final += Σ weapon.scaling.compute_contribution(stat, character)`

This means a `stat_contribution` that reads from `HEALTH` always sees the **fully-resolved** value of HEALTH (base + attribute + gear + buffs), never a half-computed value.

When a single stat is recalculated outside the full sweep (e.g. an effect re-applies an attack buff), `recalculate_stat` runs pass 1 then immediately runs pass 2 for that stat if it is a power stat.

## Save / load

`WeaponScaling.game_save()` and `game_load()` serialize entries to plain dictionaries — weapons keep their scaling across saves even though they're reconstructed from class strings rather than re-loaded from the `WeaponResource`.

## Interaction with skills

`AttackSkill` exposes three scales so skills can weight which power stat fuels their damage:

```
damage = (attack * attack_scale
        + magic_power * magic_scale
        + divine_power * divine_scale) * modifier
```

Defaults: `attack_scale = 1.0`, `magic_scale = 0.0`, `divine_scale = 0.0` — existing skills behave as pure attack-power skills with no migration required.

Examples:

| Skill | attack_scale | magic_scale | divine_scale |
|---|---|---|---|
| Basic strike | 1.0 | 0.0 | 0.0 |
| Fireball | 0.0 | 1.2 | 0.0 |
| Priest smite | 0.8 | 0.0 | 0.6 |
| Spellblade slash | 0.6 | 0.6 | 0.0 |

This is what makes weapon choice matter per-class: a priest wielding a holy mace gets full value from `divine_scale` skills because the mace pumps both `ATTACK` and `DIVINE_POWER`.

## UI display

In item tooltips ([`gear/_ui/general/item_info.gd`](_ui/general/item_info.gd)) each non-empty power stat is rendered as:

```
<Stat name>: <value>  TAG TAG TAG
```

`<value>` depends on context:
- **Inventory tooltip** (no known wielder) → just the weapon's flat base value.
- **Equipped tooltip** (wielder is the owning character) → base value **plus** the actual scaling contribution computed against that character's current attributes/stats. This is what the weapon is really giving them right now.

Tags are short-form labels for each scaling source. Multipliers themselves are intentionally hidden — players read intensity from how many `+` characters follow the label:

| Multiplier (absolute) | Tier |
|---|---|
| `0 < m < 0.4`  | `+` |
| `0.4 ≤ m < 0.8` | `++` |
| `0.8 ≤ m < 1.4` | `+++` |
| `m ≥ 1.4` | `++++` |

**Attribute labels:** `STR`, `INT` (IQ), `PIE`, `VIT`, `DEX`, `SPD`, `LUK`.

**Stat labels:** `HP`, `MP`, `SP`, `ASPD` (SPEED), `DEF`, `MDEF`, `RES`, `ACC`, `EVA`, `HEAL`, `RCV`.

Examples:

| Weapon | Tooltip line |
|---|---|
| Basic sword (5 ATK, STR×1.0) | `Attack: 5  STR+++` |
| Dagger (2 ATK, STR×0.5, DEX×1.0) | `Attack: 2  STR++ DEX+++` |
| Staff (0 base, IQ×1.0) | `Magic Power: 0  INT+++` |
| Holy mace (4 ATK, STR×0.8, 0 DIV, PIE×1.0) | `Attack: 4  STR+++`<br>`Divine Power: 0  PIE+++` |
| Health-staff (IQ×0.5, HEALTH×0.1) | `Magic Power: 0  INT++ HP+` |

Power stats with no base value AND no scaling are omitted entirely — a pure sword does not show "Magic Power: 0".

## File map

| File | Role |
|---|---|
| [`stat/WeaponScaling.gd`](../stat/WeaponScaling.gd) | Resource holding scaling entries; computes contribution and persists. |
| [`stat/WeaponScalingEntry.gd`](../stat/WeaponScalingEntry.gd) | One target stat + its attribute and stat contributions. |
| [`stat/StatMultiplier.gd`](../stat/StatMultiplier.gd) | `(source_stat, multiplier)` pair, mirrors `AttributeMultiplier`. |
| [`stat/AttributeMultiplier.gd`](../stat/AttributeMultiplier.gd) | `(attribute, multiplier)` pair. |
| [`stat/stat_calculator.gd`](../stat/stat_calculator.gd) | Two-pass calculation. |
| [`gear/weapon/weapon_resource.gd`](weapon/weapon_resource.gd) | Editor-facing weapon definition (`scaling` field). |
| [`gear/weapon/weapon.gd`](weapon/weapon.gd) | Runtime weapon instance (carries duplicated scaling). |
| [`skills/AttackSkill.gd`](../skills/AttackSkill.gd) | Skill-side power scales. |
