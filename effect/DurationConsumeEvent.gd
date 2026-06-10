extends TriggerEvent

class_name DurationConsumeEvent

var effect: Effect = null
var amount: int = 1

func _init(effect_to_consume: Effect) -> void:
	effect = effect_to_consume
