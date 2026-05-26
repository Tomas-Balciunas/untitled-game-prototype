extends TriggerEvent

class_name HealTriggerEvent

var heal: int
var scaling: float

func _init(c: ActionContext, t: Character, amount: int, scale: float = 0.0) -> void:
	ctx = c
	source = c.source
	target = t
	heal = amount
	scaling = scale
