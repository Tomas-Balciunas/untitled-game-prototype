extends TriggerEvent

class_name EffectApplicationTriggerEvent

var effect: Effect = null
var initial_effect: Effect = null

func _init(c: ActionContext, t: Character, e: Effect) -> void:
	ctx = c
	source = c.source
	target = t
	effect = e
	initial_effect = e
