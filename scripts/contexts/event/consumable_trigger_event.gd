extends TriggerEvent

class_name ConsumableTriggerEvent

var consumable: Consumable = null

func _init(c: ActionContext, t: Character, cons: Consumable) -> void:
	ctx = c
	source = c.source
	target = t
	consumable = cons
