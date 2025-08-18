extends Effect

class_name HealBoost

@export var modifier: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HEAL]

func on_trigger(event: TriggerEvent):
	if not event.ctx is HealingContext:
		return
	event.ctx.final_value += event.ctx.final_value * modifier
