@abstract
extends Effect
class_name DamageOverTimeEffect


@export var damage_per_turn: int = 5
@export var resolve_phase: TurnPhase = TurnPhase.TURN_END

var category: EffectCategory = EffectCategory.STATUS


func get_category() -> EffectCategory:
	return category

func listened_triggers() -> Array:
	return []

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false

func on_turn_start() -> void:
	if resolve_phase == TurnPhase.TURN_START:
		_resolve_scheduled()

func on_turn_end() -> void:
	if resolve_phase == TurnPhase.TURN_END:
		_resolve_scheduled()

func _resolve_scheduled() -> void:
	var ctx := ActionContext.new()
	ctx.source = source
	ctx.tick_power = 1.0
	ctx.should_tick_consume_duration = true
	tick(ctx)

func tick(ctx: ActionContext) -> void:
	if owner == null or owner.is_dead:
		return

	_deal_damage(ctx)

	if ctx.should_tick_consume_duration:
		consume_duration()

## Subclasses deliver the actual damage (and any visuals) here.
@abstract
func _deal_damage(ctx: ActionContext) -> void
