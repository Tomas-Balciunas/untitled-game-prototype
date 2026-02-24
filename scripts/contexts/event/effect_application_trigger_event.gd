extends TriggerEvent

class_name EffectApplicationTriggerEvent

var target: CharacterInstance = null
var effect: Effect = null
var initial_effect: Effect = null

func _init(c: ActionContext, t: CharacterInstance, e: Effect) -> void:
	ctx = c
	actor = c.source
	target = t
	effect = e
	initial_effect = e
