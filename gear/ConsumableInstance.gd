extends ItemInstance
class_name ConsumableInstance

var effects: Array[Effect] = []

func use_item(user: CharacterInstance, item: ConsumableInstance):
	var action = ConsumableAction.new()
	action.source = user
	action.target = user
	action.consumable = item
	ConsumableResolver.apply_consumable(action)
	user.inventory.remove_item(item)

func get_all_effects() -> Array[Effect]:
	return effects
