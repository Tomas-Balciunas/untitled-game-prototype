extends PassiveEffect
class_name PoisonRes

@export var resistance: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]
	
func can_process(event: TriggerEvent) -> bool:
	return owner == event.target and event is DamageTriggerEvent

func on_trigger(event: TriggerEvent) -> void:
	var dmg: DamageTriggerEvent = event as DamageTriggerEvent
	
	if not dmg.ctx.type == DamageTypes.Type.POISON:
		return
	
	event.calculator.final_value -= (dmg.calculator.final_value * resistance)
