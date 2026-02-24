extends TriggerEvent

class_name ConsumableTriggerEvent

var consumable: Consumable = null
var target: CharacterInstance

func _init(c: ActionContext, t: CharacterInstance, cons: Consumable) -> void:
	ctx = c
	actor = c.source
	target = t
	consumable = cons
