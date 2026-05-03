extends PassiveEffect

class_name ResolvePoisonOnHit

@export var tick_power: float = 0.5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.OWNER_IS_ACTOR

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true

func on_trigger(_stage: String, ctx: TriggerEvent) -> void:
	ctx.ctx.tick_power = tick_power
	ctx.ctx.should_tick_consume_duration = false
	
	var ticker: TickDoT = TickDoT.new(ctx.ctx.initial_target, ctx.ctx)
	ticker.execute()
