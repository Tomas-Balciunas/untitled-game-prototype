extends Item
class_name ConsumableItem

@export var effects: Array[Effect] = []

func use_item(user: CharacterInstance, target: CharacterInstance):
	for e in effects:
		target.apply_effect(e, null)
