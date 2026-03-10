extends PassiveEffect
class_name PoisonRes

@export var resistance: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.target and event is DamageInstance

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var dmg: DamageInstance = event as DamageInstance
	
	if not dmg.calculator.type == DamageTypes.Type.POISON:
		return
	
	event.calculator.final_value -= (dmg.calculator.final_value * resistance)
