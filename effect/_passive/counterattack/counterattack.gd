extends PassiveEffect
class_name Counterattack

@export var chance: float = 0.3

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.ctx.actively_cast and event.ctx.targets.has(owner)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var counter := chance * 100 >= randi() % 100
	if counter:
		event.ctx.set_meta("counterattack", event.ctx.source)
