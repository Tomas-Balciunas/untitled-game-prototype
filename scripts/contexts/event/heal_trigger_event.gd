extends TriggerEvent

class_name HealTriggerEvent

var target: CharacterInstance
var heal: int

func _init(c: ActionContext, t: CharacterInstance, amount: int) -> void:
	ctx = c
	actor = c.source
	target = t
	heal = amount
