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
  storage vars). **Renaming an effect script breaks existing saves.**

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
`_register_all()` is a **hand-maintained list of `.tres` paths** by `id`.
New effects must be added manually (scaling pain — candidate for auto-scan).

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
- `cleanup_after_battle()`: erases `expires_after_battle` effects, clears temp
  modifiers, recalculates stats.

---

## Battle / turn flow
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

## Known gaps / TODO themes (from review)
- Stacking/reapply policy is unfinished (`Poison.stacks` exists; stacking logic
  commented out; no general "already applied" policy).
- `EffectRegistry` manual list (auto-scan candidate).
- `ActionContext` accumulating flags.
- `EffectScope` enum under-used.

## Tests
GUT (Godot Unit Test) 9.x lives in `addons/gut/`; all test code is isolated
under `test/` (nothing in production dirs). Config: `.gutconfig.json`.
Run headless: `./run_tests.ps1` (or see `test/README.md`). Current coverage:
base `Effect` lifecycle (duration tick / expiry / display / save-load),
`Bleed` (stack math, priorities), `PoisonEffect` (config / scoping), the
`EffectRunner` trigger pipeline (priority order + `stop_processing`),
**resolvers** (`DamageResolver` damage/defense/lethal, `HealingResolver`
multipliers/scaling/clamp, `EffectApplicationResolver`, `TurnStageResolver`),
and **BattleManager** state logic (`_check_end_conditions`, turn-queue ordering).
Test doubles in `test/helpers/`: `FakeCharacter` (skips Character's heavy
`_init`; used where only `is_dead`/`action_value`/`effects` matter),
`Combatant` (builds a *real* Character from a `.tres` for resolver tests),
`ProbeEffect`, `RecordingEffect`.
> Resolver tests force determinism by zeroing attacker `accuracy` (skips the
> `randf()` variance in `DamageCalculator`) and register a dummy
> `RichTextLabel` on `BattleTextLines` so `print_line` doesn't error
> headless. GUT fails tests on any engine `push_error`.

## Verifying changes (headless)
Compile + run main scene a few frames, exit 0 = clean:
```
& "C:\Users\Tomas\Desktop\Godot_v4.6-stable_win64_console.exe" --headless --path "<project>" --quit-after 120
```
The Godot **editor** locks files while open — deletes may be denied; ask the
user to close it (or have them delete) and re-add a temporary stub if an
orphaned script references a removed symbol.
