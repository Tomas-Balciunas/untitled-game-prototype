extends PassiveEffect

class_name ResolvePoisonOnHit

@export var tick_power: float = 0.5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()

func on_trigger(_stage: String, ctx: TriggerEvent) -> void:
	ctx.ctx.tick_power = tick_power
	ctx.ctx.should_tick_consume_duration = false
	
	var ticker = TickDoT.new(ctx.ctx.initial_target, ctx.ctx)
	ticker.execute()
