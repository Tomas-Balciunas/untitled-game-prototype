extends Item
class_name ConsumableItem

@export var effects: Array[Effect] = []
@export var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE

func use_item(user: CharacterInstance, item: ConsumableItem):
	var action = ConsumableAction.new()
	action.source = user
	action.target = user
	action.consumable = item
	ConsumableResolver.apply_consumable(action)
	user.inventory.remove_item(item)
