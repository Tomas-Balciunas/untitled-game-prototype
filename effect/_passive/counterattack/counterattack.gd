extends Effect
class_name Counterattack

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]

func on_trigger(event: TriggerEvent) -> void:
	var counter = 50 >= randi() % 100
	if counter:
		event.ctx.set_meta("counterattack", event.ctx.source)
