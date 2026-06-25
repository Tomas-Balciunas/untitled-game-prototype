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
  `immediate_trigger`, `process_when_dead`, `priority` (default 200).
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
dead check) and `can_process`, calling `on_trigger`; `immediate_trigger`
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

## Multi-hit targeting — `scripts/battle_actions/attack_launcher.gd`
`AttackLauncher` (RefCounted) is the projectile launchers reborn **without
projectiles** — a reusable attack sequencer that owns the `ActionOrchestrator`
boilerplate so the battle actions stay thin. Constructed `(actor, ctx,
resolver)`; the caller supplies its own animation as `animate: func(e:
ActionEvent, target_slot: FormationSlot)` (closing over the attacker slot —
the launcher passes the per-hit target slot). Used by basic attacks
(`basic_attack.gd`) and skills (`skill_action.gd`); item use can adopt it once
its ConsumableResolver flow is reconciled. Methods:
- `strike(animate)` — one animated action resolving every current `ctx.target`
  (SINGLE / ROW / COLUMN / BLAST / MASS).
- `salvo(pellets, animate)` — sets `ctx.targets` to the **initial target first**
  + `pellets-1` random valid (via `TargetingManager.get_salvo_targets`), then a
  single `strike`. All land together (DamageResolver loops with no delay) —
  shotgun, not a chain.
- `bounce(bounces, is_active_attack, start_from_target, animate)` — **exact
  port** of the original `BounceProjectileLauncher.bounce` (minus projectiles /
  the removed RangeType). Each iteration is its own orchestrated action using
  `resolver`; `get_valid_slot` picks a random valid slot **excluding the
  immediately-previous**, with `i == 0 && !start_from_target` forced to the
  initial target, and `continue` (skip) when no valid slot is found. So basic
  attacks call `bounce(n, true, false, …)`: hit #1 is the initial target
  (`current_bounce = 1`), then chains; a lone enemy yields just that first hit
  (matches original). The animated swing replaces the projectile per hop. The
  optional effect `effect/_offensive/bounce_damage.gd` (`BounceIncreasingDamage`,
  attach to a weapon/character) reads `current_bounce` on
  `ON_BEFORE_RECEIVE_DAMAGE` and escalates each successive hop.

Resolver per caller: basic attacks pass a `DamageResolver` (every hop is plain
damage — exact original). `strike`/`salvo` for **skills** use a `SkillResolver`
(cost + ON_BEFORE/POST_SKILL_USE fire once over all targets). Skill **bounce**
can't run through `SkillResolver` per hop (it would re-consume cost each
bounce), so `skill_action._bounce` fires the skill-use envelope once and passes
`skill.get_resolver(ctx)` (plain damage) to `bounce`.

Counts come from the **entity**: `Weapon.bounce_instances` / `salvo_pellets`
for basic attacks, `Skill.bounce_instances` / `salvo_pellets` for skills (same
field names). `Weapon` save/load persists `targeting` + both counts (previously
`targeting` was hard-reset to SINGLE on load). Salvo pellets land together (one
cast, resolver loops targets); bounce hops are each a full orchestrated action
(per-hop swing), gated by their animation — no fixed inter-hop delay.
(History: original `ProjectileLauncher` + subclasses removed in commit 8c38cec.)

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
> Determinism notes: fixture has `accuracy` 0, which skips `randf()` damage
> variance; a dummy `RichTextLabel` is registered on `BattleTextLines` where
> production code prints; GUT fails tests on any engine `push_error`.

## Verifying changes (headless)
Compile + run main scene a few frames, exit 0 = clean:
```
& "C:\Users\Tomas\Desktop\Godot_v4.6-stable_win64_console.exe" --headless --path "<project>" --quit-after 120
```
The Godot **editor** locks files while open — deletes may be denied; ask the
user to close it (or have them delete) and re-add a temporary stub if an
orphaned script references a removed symbol.
