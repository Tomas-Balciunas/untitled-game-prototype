extends Effect

class_name HealBoost

@export var modifier: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HEAL]
	
func can_process(event: TriggerEvent) -> bool:
	return event.actor == owner and event.ctx is HealingContext

func on_trigger(event: TriggerEvent) -> void:
	event.ctx.final_value += event.ctx.final_value * modifier
