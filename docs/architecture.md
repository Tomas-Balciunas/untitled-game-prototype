# Architecture Notes

Self-maintained reference for fast iteration. Keep it updated when the
described systems change. Paths are relative to the project root. Ignore
`_legacy/`.

> Scope so far: the **effect / combat** system (the area most worked on).
> Extend with other subsystems as they're explored.

---

## Effect system

### Core class — `effect/Effect.gd`
Abstract `Resource`, `class_name Effect`. Every effect is a `.tres` whose
`script_class` is a concrete subclass.

Key exported fields:
- `id`, `name`, `description`, `icon`
- `native: bool = false` — innate/permanent trait; drives **character-menu** display.
- `show_in_status: bool = true` — drives **status-screen** display.
- `battle_only` (default true), `expires_after_battle` (default false),
  `immediate_trigger`, `priority` (default 200).
- `process_when_owner_dead` / `process_when_target_dead` (both default false)
  — opt-ins checked by `EffectRunner._passes_filters`. Owner check reads the
  live `owner.is_dead`; target check reads `TriggerEvent.target_was_dead`,
  i.e. the target was **already** a corpse when the event began, not merely
  killed by it. On-death and killing-blow effects therefore need no opt-in;
  corpse-targeting effects (revive, overkill riders) do.
- `duration_turns: int = -1` (-1 = never expires on its own).
- `expire_phase: TurnPhase` (TURN_START / TURN_END / **CUSTOM**) — when a
  phase-driven effect counts down. (DoTs don't use this path — they consume
  duration through their tick; see DamageOverTimeEffect.)

Runtime: `remaining_turns` (init in `Character.apply_effect`, persisted), `owner`, `source`.

Key methods / hooks:
- Abstract: `listened_triggers()`, `can_process(stage, event)`, `get_category()`.
- Trigger behavior: `on_trigger(stage, event)`.
- Turn lifecycle (decoupled from triggers): `on_turn_start()`, `on_turn_end()`
  → default call `_tick_duration(phase)`; override for custom per-turn logic
  (call `super()` to keep the countdown).
- `consume_duration(amount=1)` — single funnel that decrements `remaining_turns`
  and calls `on_expire()` (→ `remove_self()`).
- Display surfaces: `show_in_status_screen()` (→ `show_in_status`),
  `show_in_character_menu()` (→ `native`), `get_icon()`,
  `get_display_turns()` (live remaining unless CUSTOM/non-turn-based),
  `get_display_stacks()`.
- Value transformers: `modify_skill_cost()`, `modify_shop_price()`.
- Save/load: reflection-based `game_save()`/`game_load()` (stores script path +
  storage vars). `create_from_save` tries the script path first; if the file
  was renamed/moved it falls back to `EffectRegistry.get_effect(props.id)` and
  duplicates the prototype (so registered effects survive script renames).
  Unrestorable effects go through `SaveManager.report_load_issue`.

### Templates — `effect/templates/`
Set `category` + sensible flag defaults in `_init` (subclasses overriding
`_init` MUST call `super()`):
- `status_effect.gd` (STATUS, `expires_after_battle=true`)
- `buff_effect.gd` (BUFF, `expires_after_battle=true`)
- `debuff_effect.gd` (DEBUFF, `expires_after_battle=true`)
- `control_effect.gd` (CONTROL, `expires_after_battle=true`)
- `passive_effect.gd` (PASSIVE; sets `native=true`, `show_in_status=false`)
- `damage_over_time_effect.gd` — **DoT base** (see below)
- `stat_bonus_effect.gd` (a PassiveEffect)

NOTE: `PassiveEffect` is somewhat overloaded as a catch-all base for
trigger-driven effects, not only innate traits. When an applier/mechanism
effect needs to be transient, prefer a Debuff/Status base over PassiveEffect
(e.g. `ManaDrainEffect` is a `DebuffEffect`, not a passive).

### DoTs are self-contained (the "cosmos" pattern)
There is **no shared DoT base** anymore — each DoT lives entirely in its own
class, extends a normal template (`StatusEffect`), self-listens to its triggers,
exposes a public method for external manipulation, and fires its own custom
stage(s) carrying a mutable event so modifier effects can transform a
resolution. Trade-off: some duplication across DoTs (accepted for locality).

**`effect/poison/Poison.gd` (`PoisonEffect`, extends `StatusEffect`)**
- `const ON_POISON_DAMAGE` (local stage), `@export damage_per_turn`,
  `@export resolve_trigger` (default `ON_TURN_END`, configurable to TURN_START),
  `stacks`.
- `_init`: `battle_only=false`, `expires_after_battle=false`,
  `expire_phase = NONE` — opts out of the base phase auto-countdown so it
  doesn't double-consume (it spends duration itself via `trigger`).
- `listened_triggers() → [resolve_trigger, ON_MOVEMENT]`; `can_process` =
  owner is the acting character. `on_trigger` is the natural resolution: it
  calls `trigger()` then `consume_duration()` — duration consumption is
  automatic per tick (battle turn end + each movement step).
- **`trigger(power := 1.0)`** — public damage primitive: deals one instance
  (`_deal_damage`) and does NOT spend duration. External effects call it
  directly (on-hit proc, delay/amplify) and manage duration themselves
  (call `consume_duration()` / adjust `remaining_turns` as needed).
- `_deal_damage(power)` builds a `PoisonEvent` (`effect/poison/PoisonEvent.gd`,
  extends TriggerEvent: `damage_per_turn`, `stacks`, `power`),
  fires `EffectRunner.process_trigger(ON_POISON_DAMAGE, ev)`, then resolves
  `roundi(ev.damage_per_turn * ev.stacks * ev.power)` damage.
- `resolve_poison_on_hit.gd`: on the attacker's `ON_DAMAGE_APPLIED`, finds
  `PoisonEffect` on the victim and calls `trigger(tick_power)` (bonus tick, no
  duration spent — `trigger` never spends duration).
- Overworld movement: poison self-listens to `ON_MOVEMENT` (no external ticker).

**`effect/bleed/Bleed.gd` (`Bleed`, extends `StatusEffect`)** — same pattern:
stack-based (no `duration_turns`), reactive damage on `ON_DAMAGE_APPLIED`
(scaled by stacks), halves stacks on `ON_TURN_END`. Fires `ON_BLEED_CONSUME`
and `ON_BLEED_DAMAGE_INSTANCE` with a mutable `BleedEvent` for modifiers
(e.g. `reduce_enemy_bleed_consumption` lowers `stack_loss`); modifiers may also
mutate `stacks` directly. Local stage consts live on the `Bleed` class.

> Pattern for DoT modifiers: subscribe to the DoT's custom stage, scope via
> `can_process`, and mutate the passed event (value transforms) or the
> effect's state directly (e.g. add stacks).

> DEPRECATED / pending deletion (editor-locked at time of writing):
> `effect/templates/damage_over_time_effect.gd` and `effect/TickDoT.gd` (no
> longer used), plus `ActionContext.should_tick_consume_duration` / `tick_power`
> (only the dead DoT base reads them). Delete the two files + those two fields
> together once the editor releases them.

### Trigger pipeline — `effect/EffectRunner.gd` (autoload)
`subscribe`/`unsubscribe` index effects by stage in `_subscriptions`.
`process_trigger(stage, event)`: builds one `pending` list from
`ctx.temporary_effects` (skill/proc effects — bound to owner/source here,
filtered by `listened_triggers`) **plus** `_subscriptions[stage]`, sorts by
`priority` (desc), then runs each through `_passes_filters` (battle_only +
owner-dead + target-was-dead checks) and `can_process`, calling `on_trigger`;
`immediate_trigger`
effects `remove_self()` after firing. `ctx.stop_processing` short-circuits.
> Temporary + persistent effects are **unified** into this single pass
> (priority + stop_processing apply to both).

Stage constants: `effect/EffectTriggers.gd` (ON_TURN_START/END, ON_MOVEMENT,
ON_*_DAMAGE_*, ON_HEAL/RECEIVE_HEAL, ON_*_APPLY_EFFECT, ON_EXPIRE,
ON_*_USE_CONSUMABLE, ON_*_SKILL_USE, ON_DEATH).

`EffectScope` enum exists but appears under-used (filtering is done via
`can_process` + `owner_is_actor/target`).

### Registry — `effect/EffectRegistry.gd` (autoload)
Auto-scans `res://effect` + `res://gear` recursively at startup for `.tres`
resources that are `Effect`s, indexed by `id`. Effects with an empty `id` are
skipped with a warning (give every effect an id — it's also the save-load
fallback key). Handles exported builds (`.remap` suffix stripping). Duplicate
ids warn and last-one-wins.

### Application & ticking
- `scripts/resolvers/DamageResolver.gd`: `run_pipeline` snapshots
  `event.target_was_dead` before anything else, then fires
  ON_BEFORE_RECEIVE_DAMAGE → ON_DAMAGE_ABOUT_TO_BE_APPLIED →
  `set_current_health` → ON_DEATH → ON_DAMAGE_APPLIED. ON_DEATH is gated on
  the alive→dead **transition** (`is_dead and not target_was_dead`), so a
  multi-hit attack fires it once. Hits on an already-dead target still run the
  full pipeline on purpose (HP bar is hidden; each hit reads as anticipation).
- `scripts/resolvers/EffectApplicationResolver.gd`: `run_pipeline` fires
  ON_BEFORE_APPLY_EFFECT → `target.apply_effect()` (which subscribes) →
  ON_APPLY_EFFECT. So an applied effect is subscribed **before**
  ON_APPLY_EFFECT, letting it catch its own application (used by
  `ManaDrainEffect` + `immediate_trigger` for one-shot).
- DoT resolution: no central ticker. Overworld movement
  (`scripts/MapInstance.gd`) fires `ON_MOVEMENT` and DoTs self-resolve; on-hit
  procs call the DoT's public method directly (e.g. `PoisonEffect.trigger`).
  (`effect/TickDoT.gd` is dead — see deprecation note above.)

### Character storage — `scripts/Character.gd`
- `effects: Array[Effect]` — active effects (incl. gear-granted; `gear_effects`
  is just an index for save-skip).
- `apply_effect(effect, source)`: duplicates, sets owner/source/`remaining_turns`,
  `on_apply()`, append, subscribe. `remove_effect()`: unsubscribe + erase.
- Turn hooks: `on_turn_start()` / `on_turn_end()` iterate `effects.duplicate()`
  calling each effect's same-named hook (mutation-safe).
- `cleanup_after_battle()`: removes `expires_after_battle` effects via
  `remove_effect` (which also unsubscribes from EffectRunner), clears temp
  modifiers, recalculates stats.

---

## Battle / turn flow
- **Presentation direction**: battle is fixed-camera, characters don't move
  (scope cut from first-person choreography). The run-up / camera-turn calls
  (`perform_run_towards_target`, `look_at_target`) are commented out in
  `BattleManager.gd` / `basic_attack.gd` pending removal; feedback comes from
  in-place animations + simple effects.
- **Turn indicator**: acting *enemy* gets a pulsing red ring at its feet —
  `FormationSlot.turn_indicator` (`scenes/battle_formation/formation_slot.gd`),
  built in code (no .tscn edit), driven by `BattleBus.turn_started(battler,
  is_party_member)` / `turn_ended`; hidden on `perform_death()` / `clear()`.
- **Party hit flash**: red vignette flash (edges in, clear center; inline
  canvas shader) when a party member takes damage —
  `scenes/ui/hit_flash_overlay.gd` (`HitFlashOverlay`, ColorRect), code-mounted
  as last child of `UIRoot` in `root_interface.gd._ready` (renders above all
  interfaces). Listens to `CharacterBus.character_damaged`, filters via
  `PartyManager.has_member_by_object`; peak alpha scales with final damage / max HP
  (full at 50%+), +bonus on crit, 0.35s fade. Note: fires on any party damage
  incl. overworld DoT ticks (party has no visible 3D bodies — camera sits in
  the MC's body on the ally row; their 3D "damaged" anims play off-screen).
- `scripts/BattleManager.gd`: `_on_turn_start()` builds ctx, runs
  `TurnStageResolver(ON_TURN_START)`, then `current_battler.on_turn_start()`.
  `_on_turn_end()` runs `TurnStageResolver(ON_TURN_END)`, then
  `current_battler.on_turn_end()`. (Turn-start DoT/`should_tick` machinery was
  removed — DoTs resolve via the Character turn hooks at their `resolve_phase`.)
- `scripts/resolvers/turn_stage_resolver.gd`: fires the stage trigger only.
- `ActionContext` (`scripts/contexts/ActionContext.gd`): per-action bag —
  `source`, `targets`, `temporary_effects`, `stop_processing`, `skip_turn`,
  `force_action`, `should_tick_consume_duration`, `tick_power`,
  `additional_procs`, etc. (Tends toward a god-object — many ad-hoc flags.)

## Multi-hit targeting — `scripts/battle_actions/action_targeting_behaviour/`
The projectile launchers reborn **without projectiles**: an abstract
`projectile_launcher.gd` (`ProjectileLauncher`, extends Node) holds the shared
state — `resolver`, `ctx`, `initial_target`, `is_ally`, `actor`, `actor_slot` —
and two concrete launchers built from `(resolver, ctx)`. They select among
**characters** (not slots) via `BattleContext.get_valid_battlers(is_ally)`;
`valid_slot()` rejects a candidate that `is_dead` or equals the excluded one.
Each sub-hit runs through its own `ActionOrchestrator`, but the animation
callable is just `e.confirm()` (no projectile/anim to wait on) — so the hit
resolves immediately.
- `bounce_targeting.gd` (`BounceLauncher`) — `bounce(bounces, is_active_attack
  = false)`: wraps the run in a `"bounce parent"` ActionEvent, then loops
  `bounces`: `i == 0` targets the initial target, otherwise
  `get_valid_slot(previous, …)` (random valid, excluding the previous);
  `continue` (skip) when none found. Each hop builds a fresh `ActionContext`
  with `options.current_bounce` (+ `total_bounces`), resolves, then
  `await BattleContext.wait(0.1)` — sequential chain. The optional effect
  `effect/_offensive/bounce_damage.gd` (`BounceIncreasingDamage`, attach to a
  weapon/character) reads `current_bounce` on `ON_BEFORE_RECEIVE_DAMAGE` and
  escalates each successive hop.
- `salvo_targeting.gd` (`SalvoLauncher`) — `shrapnel(pellets, is_active_attack
  = false)`: fires `pellets` hits at `slots.pick_random()` (no exclusion — can
  repeat, initial not guaranteed), each carrying `options.pellet`. Orchestrators
  are launched **without await** → all land together (shotgun).

**Wiring**: only `basic_attack.gd` so far. `perform` runs the normal animated
melee swing on `ctx.targets` first, then — inside the `attack_rate` loop —
dispatches on `ctx.targeting`: `BOUNCE` → `await BounceLauncher.bounce(…)`,
`SALVO` → `SalvoLauncher.shrapnel(…)` (fire-and-forget). So bounce's `i == 0`
re-hits the initial target *after* the melee swing already hit it. Skills /
items don't use these yet. (Note as of writing: the launcher counts are
hardcoded `50` and `DamageResolver.new(1)` is a flat placeholder — wire to
`Weapon.bounce_instances` / `salvo_pellets` and the attack stat when ready.
`Weapon` already carries those count fields + persists `targeting`.)
(History: original slot-based `ProjectileLauncher` + subclasses removed in
commit 8c38cec, reintroduced character-based in f6135e5.)

## Skills — `skills/Skill.gd`
`Skill` resource: `cost`, `effects: Array[Effect]` (passed as temporary effects),
`get_resolver(ctx)`. `AttackSkill.gd` → `DamageResolver`. Reactive skill effects
(e.g. `PoisonOnHit`) listen on damage stages and queue follow-ups via
`ctx.additional_procs`. `SkillResolver` fires ON_BEFORE/POST_SKILL_USE and runs
the resolver.

## UI surfaces for effects
- Status screen (right-click party member): `scenes/ui/status_effects/` —
  `StatusEffectsWindow.tscn` + `status_effects_window.gd`, mounted under
  `UIRoot` in `scenes/main.tscn`. Lists `effects` where `show_in_status_screen()`;
  shows icon + name, plus turns/stacks when ≥ 0. Right-click handled in
  `scenes/ui/party/party_member_slot_interface.gd` → `CharacterBus.display_status_effects`.
- Character menu Effects tab: `scenes/ui/character/CharacterEffectsUI.gd` — lists
  `effects` where `show_in_character_menu()`.

## Buses (signals, for notifications — not ordered resolution)
`scripts/bus/CharacterBus.gd` (`display_character_menu`, `display_status_effects`,
`stat_changed`, `character_damaged/healed`, ...), `BattleBus`, `ChestBus`.

---

## Stat pipeline — `stat/stat_calculator.gd`

Four `Stats` layers live on `Character` (only `base_stats` is authored data; the
rest are derived and not saved):

| layer | contents |
|---|---|
| `base_stats` | raw, from `CharacterResource.base_stats` |
| `computed_stats` | base + attribute growth + level growth + **gear** |
| `modified_stats` | computed + non-dependent `StatModifier`s |
| `stats` | modified + dependent modifiers + weapon scaling — the value everything gameplay-side reads |

`recalculate_all_stats(c)` is the **only** entry point (a single-stat variant
existed and was removed — see the invariant below). It runs three loops:

1. `_recalculate_modified` for every stat — fills `computed_stats` then
   `modified_stats`. Self-contained per stat: nothing here reads another stat.
2. `_apply_dependent_modifiers` for every stat — modifiers flagged
   `depends_on_another_stat` run here and may read `modified_stats` of *any*
   stat. Writes `stats`.
3. `_apply_weapon_scaling` for the `WeaponScaling.ALLOWED_TARGET_STATS` power
   stats — always last, and reads final `stats` for its `stat_contributions`
   (a source stat may not itself be a power stat, which is push_error-guarded).

**The invariant**: every cross-stat read comes from a layer that is complete and
never written again by the time it is read. Loop 2 only reads `modified_stats`
and only writes `stats`, so mutual conversions — `stat/_modifier/hp_to_atk.gd`
plus `atk_to_hp.gd` on the same character — both see pre-conversion values and
resolve order-independently instead of feeding back into each other. This is
also why single-stat recalculation is gone: buffing ATTACK alone would leave a
HEALTH modifier that reads attack stale.

Writes to the final layer funnel through `_set_final`, which skips the write and
the `CharacterBus.stat_changed` emit when the value is unchanged — that is what
keeps a full recalc from spamming 15 signals per buff application.

Rounding happens once, at the final layer; `computed_stats` / `modified_stats`
stay float. `Stats.get_stat()` rounds to int — use `get_stat_raw()` when reading
a layer back for further math.

`CRITICAL_DAMAGE` is a normal (non-percentage) stat holding a **bonus percent**,
default 0. Baseline + conversion live on `Stats`: `CRITICAL_DAMAGE_BASE` (150.0,
next to `PERCENTAGE_BASE`) and `get_critical_multiplier()` →
`(CRITICAL_DAMAGE_BASE + critical_damage) / 100.0`. `DamageCalculator._init`
just consumes that (falling back to the baseline when there is no actor), so an
unauthored character still crits for 1.5x and gear/modifiers add on top. It is
deliberately not a `PERCENTAGE_STAT`: those use a fixed 100 baseline, drop gear
contributions, and reject flat modifiers. (`Stats` is shared with `Gear`, so any
non-zero default on the resource would be re-added per equipped item.)

### Authoring stat resources — two invariants

**`StatGrowthEntry.stat` is a raw `Stats.StatRef` index.** All four
`stat_attribute_growth.tres` files were written against an enum that predated
`ACTION_POINTS` (index 4), so every entry from `spd` onward was off by one:
speed fed action points, dex fed resistance, and `EVASION` (12) received nothing
at all — every character had 0 evasion, floored to 1.0 by the damage calculator.
Fixed 2026-08-16. When adding an entry, read the index off `Stats.StatRef`
directly; the sub-resource `id=` names are the only record of intent and they
are not checked against anything.

**`base_stats` must author `action_points`.** `turn_state.gd:22` seeds a turn's
AP solely from that stat — there is no fallback and no attribute contribution.
A character with 0 lands on 0 AP and can never afford an action. This was masked
by the off-by-one (speed leaked into AP), so it only became load-bearing once
that was corrected.

Characters with no `base_stats` fall back to the *shared* `DefaultStats.tres`
via `CharacterResource`'s export default. Lili, Skelly, Balmer and Boo all did;
each now has its own resource so tuning one cannot move the others.

### Damage roll (`scripts\DamageCalculator.gd`)

`calculate_final_damage()` runs: variance roll → defense softening
(`200 / (200 + defense)`) → crit multiplier → `damage_reduction`.

The roll in `apply_damage_variance()` is the only randomness. Everything derives
from one scale-invariant measure of the accuracy gap (both stats floored at 1.0):

```
advantage = (accuracy - evasion) / (accuracy + evasion)   # -1 .. 1
```

Parity is 0, 2x accuracy is 0.33, 4x is 0.6, 10x is 0.82. This replaced a raw
`accuracy / evasion` ratio, which was unbounded and exploded whenever a target
had no authored evasion.

**Damage.** `exponent = DAMAGE_SKEW_RANGE ** -advantage` (so 1/3 .. 3), then
`roll = randf() ** exponent` and `final_damage = lerpf(min, max, roll)` with
min/max at `base * (1 ± damage_variance/100)`. The roll has CDF `x ** (1/exponent)`,
giving mean `1 / (1 + exponent)` — 0.5 at parity, capped at 0.75 when dominant
and 0.25 when outclassed. Bounded by construction, so damage never pins to max.

**Crit** is the top slice of that *same* roll, so a crit is always a near-max
hit rather than an independent coin flip:

```
chance    = CRITICAL_CHANCE_MAX * clamp(inverse_lerp(CRITICAL_GATE, CRITICAL_FULL, advantage), 0, 1)
threshold = (1 - chance) ** exponent
```

Solving `1 - threshold ** (1/exponent) = chance` is what makes the observed rate
come out to exactly `chance` despite the skew. Below `CRITICAL_GATE` (0.34, ~2x
evasion) crits are impossible; the rate ramps to `CRITICAL_CHANCE_MAX` (15%) at
`CRITICAL_FULL` (0.80, ~9x). **Accuracy is the crit-chance stat** — there is no
separate crit chance stat, and no miss roll anywhere.

`damage_variance` comes from the equipped weapon; when it is 0 (no weapon) the
roll is skipped entirely and the hit can never crit. Note that integer rounding
in `get_final_damage()` flattens the band at low damage numbers — at ~12 damage,
a variance under ~15 collapses to a single value.

Percentage stats (`Stats.PERCENTAGE_STATS`) bypass the normal path entirely via
`_recalculate_percentage_stat`: baseline `Stats.PERCENTAGE_BASE`, multiplicative
modifiers only (ADDITIVE is push_error-guarded), resolved in loop 1 and skipped
by loop 2. Known gaps: gear-borne percentage stats are silently dropped, and a
`depends_on_another_stat` modifier on a percentage stat would evaluate against
an unfilled `modified_stats`. Neither is reachable with current content.

---

## Save / load — `scripts/SaveManager.gd` (autoload)
- `build_game_state()` aggregates `GameState` + `PartyManager` + `MapInstance`
  + `InteractionTagManager` via cascading `game_save()`/`game_load()` methods;
  binary `store_var` to `user://save_slot_N.save`.
- **Versioned**: root carries `"version"` (`SAVE_VERSION`, currently 1; missing
  = 0). `apply_game_state` runs `_migrate()` (a v→v+1 chain) before applying.
  Bump `SAVE_VERSION` + add a `_migrate_vN_to_vN+1` on any format change.
- **Atomic writes**: saves go to `<path>.tmp` then swap; `load_game` recovers
  from an orphaned `.tmp` if a crash hit between write and swap. Non-Dictionary
  payloads are rejected as corrupt.
- **Load-issue reporting**: loaders call `SaveManager.report_load_issue(msg)`
  (warn + collect into `load_issues`, cleared per load) instead of silent
  drops — used by `Effect.create_from_save`, `Character` (missing character
  resource / skill id), `ContextSource`. `load_issues` is UI-surfaceable.
- Party load is two-phase (characters first, then effects) so cross-character
  effect sources resolve — see `PartyManager.game_load` / `game_load_effects`.

## Doors, locks and keys
- **Blocking is a collider, not a rule.** Player movement is gated by four
  `RayCast3D`s (`Player.tscn`, `target_position` ±2, mask 1). A door blocks
  because `door_interactable.tscn` carries `StaticBody3D/CollisionShape3D2` on
  layer 1. Opening rotates the root 90°, which swings that collider onto the
  *perpendicular* boundary rather than clearing it — so `_set_blocking(false)`
  disables the shape. Never "open" a door by rotation alone.
- **Leaf geometry**: hinge at the node origin, leaf spans local X `0..2` and
  Y `0..2`. `open`/`close`/`RESET` write **absolute** rotation to
  `NodePath(".:rotation")` on the root, so a yaw set on that node is erased on
  first animate.
- **`maps/_door/proc_door.tscn`** exists for exactly that reason: `DoorPivot`
  (Node3D) holds the yaw, with `door_interactable.tscn` as a child at local
  `(-1, 0, 0)` so the closed leaf centres on the pivot origin — and therefore on
  a tile boundary — at any yaw. The animation tracks then compose with the yaw
  instead of destroying it.
- **Flow**: `DoorInteractable._interact` → keyed/trapped emits
  `ObjectBus.open_door_requested` → `DoorManager` (a per-map node on the map's
  `Doors` container, same convention as `ChestManager`) → `display_door_opener`
  → `door_opener_chosen` → on success `door_unlocked` + `door_state_changed`.
  `DoorManager` holds no node reference, which is why unlocking is a broadcast
  the owning `DoorInteractable` matches by instance.
- **Bump-to-open**: there is no `interact` action in `project.godot`, so
  `player.gd::_try_bump` opens the door whose `StaticBody3D` a blocked movement
  ray hit. Mouse click remains the fallback. `E` is already `strafe_right`.
- **Persistence**: `MapInstance.door_state[map_id][door_id]`, written by
  `DoorPivot` on `door_state_changed` and restored via
  `apply_restored_state()` (no animation, so a door already opened does not pop).
  `granted_keys` / `pending_keys` / `expected_keys` are the key ledgers; all four
  are namespaced by `map_id` and default to `{}`, so no `SAVE_VERSION` bump.
- **Keys are ids, not resources.** `gear/KeyFactory.gd` rebuilds a key from
  `map_id` + door id, so no registry entry and no saved resource is needed on any
  load path. `build`/`rebuild` return a **`QuestItemResource`** — assign it
  directly to `Door.key`, `Chest.set_locked()`, `EncounterData.item_rewards`, and
  call `._build_instance()` only where an `Item` is wanted (`Chest.items`,
  `Inventory`). Reversing that is a type error.
- **Procedural chest ids are map-namespaced** (`<map_id>_chest_NN`, via
  `MapGenerator._chest_id`) because `MapInstance.chest_state` is keyed on the
  bare id and two procedural maps would otherwise share one saved state.
- **Every generator draw must come from `_rng`.** Enemy and chest state is keyed
  by positional index, so an unseeded shuffle rebinds saved state to the wrong
  objects on the next entry — procedural maps regenerate from a stored seed on
  *every* entry.
- **Generation pipeline** (`MapGenerator._build_doors`, last step of
  `generate()`): collect candidates → cut the floor graph at them to get regions
  → build one edge per candidate → find bridges → assign door locks by frontier
  BFS from spawn → assign chest locks → roll which candidates become doors.
  Invariants and config keys are documented in `maps/MAP_CONFIG.md`.
- **`generate()` must not reference any autoload, even in dead code.** GDScript
  resolves autoload identifiers at script-compile time, so a single reference
  anywhere in `MapGenerator.gd` prevents the script loading outside a running
  project. This is why trap selection lives in `_populate_doors`.
- **Headless preview**: `maps/tools/gen_preview.tscn` runs the generator without
  playing the game and asserts the lock/key invariants across many seeds. It is
  a *scene*, not a `-s` script, for the autoload reason above:
  `godot --headless --path . maps/tools/gen_preview.tscn -- --map random_crypt_01 --count 25`

## Known gaps / TODO themes (from review)
- Stacking/reapply policy is unfinished (`Poison.stacks` exists; stacking logic
  commented out; no general "already applied" policy).
- `ActionContext` accumulating flags.
- `EffectScope` enum under-used.
- ~10 effect `.tres` files have no `id` (warned at startup by EffectRegistry
  scan) — they can't use the save-load registry fallback until ids are added.

## Tests
GUT (Godot Unit Test) 9.x lives in `addons/gut/`; all test code is isolated
under `test/` (nothing in production dirs). Config: `.gutconfig.json`.
Run headless: `./run_tests.ps1` (or see `test/README.md`). Current coverage:
- **Effects**: base `Effect` lifecycle (duration/expiry/display/save-load),
  `Bleed`, `PoisonEffect`, `EffectRunner` pipeline (priority + `stop_processing`).
- **Resolvers**: `DamageResolver`, `HealingResolver`, `EffectApplicationResolver`,
  `TurnStageResolver`.
- **BattleManager**: `_check_end_conditions`, turn-queue ordering.
- **Stats**: `Stats`/`Attributes` math + save/load, `StatModifier`,
  `StatCalculator` (additive/multiplicative/percentage stats, temp-modifier
  cleanup, weapon scaling), `WeaponScaling` (contributions + save/load).
- **Gear**: `Inventory`, `Equipment` equip/unequip (slots, stats, modifiers).
- **Progression**: `ExperienceManager` curve + level-up.
- **Character**: mana/SP clamping + signals, `SkillCost.consume`,
  `cleanup_after_battle`.
- **Misc**: `EventFlags`, `TargetingManager` basics.
- **Save/load**: `SaveManager` (version stamp, migration chain, atomic write +
  tmp recovery, corrupt-file rejection, issue reporting), `Effect`
  registry-fallback restore, registry auto-scan sanity.

Test doubles in `test/helpers/`: `FakeCharacter` (skips Character's heavy
`_init`; used where only simple fields matter), `Combatant` (builds a *real*
Character from a **code-built fixture resource** with known stats — no
production `.tres` dependency), `ProbeEffect`, `RecordingEffect`.
> Determinism notes: the fixture equips no weapon, so `damage_variance` is 0 and
> the `randf()` roll is skipped; a dummy `RichTextLabel` is registered on `BattleTextLines` where
> production code prints; GUT fails tests on any engine `push_error`.

## Verifying changes (headless)
Compile + run main scene a few frames, exit 0 = clean:
```
& "C:\Users\Tomas\Desktop\Godot_v4.6-stable_win64_console.exe" --headless --path "<project>" --quit-after 120
```
The Godot **editor** locks files while open — deletes may be denied; ask the
user to close it (or have them delete) and re-add a temporary stub if an
orphaned script references a removed symbol.
