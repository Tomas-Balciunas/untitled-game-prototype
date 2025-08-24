extends Effect
class_name Counterattack

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]
	
func can_process(event: TriggerEvent) -> bool:
	return event.ctx.actively_cast and owner == event.ctx.target

func on_trigger(event: TriggerEvent) -> void:
	var counter = 50 >= randi() % 100
	if counter:
		event.ctx.set_meta("counterattack", event.ctx.source)
