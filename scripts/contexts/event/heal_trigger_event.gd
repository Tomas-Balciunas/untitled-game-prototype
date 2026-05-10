extends TriggerEvent

class_name HealTriggerEvent

var heal: int

func _init(c: ActionContext, t: CharacterInstance, amount: int) -> void:
	ctx = c
	source = c.source
	target = t
	heal = amount
