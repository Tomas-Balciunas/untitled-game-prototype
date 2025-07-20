extends Effect
class_name Counterattack

func on_trigger(trigger: String, data: ActionContext) -> void:
	if trigger == EffectTriggers.ON_RECEIVE_DAMAGE:
		var counter = 50 >= randi() % 100
		if counter:
			data.set_meta("counterattack", data.source)
