extends Item
class_name ConsumableItem

@export var effects: Array[Effect] = []
@export var targeting_type: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE


func _init() -> void:
	type = Item.ItemType.CONSUMABLE
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> Consumable:
	var consumable: Consumable = Consumable.new()
	consumable.id = id
	consumable.item_name = name
	consumable.type = type
	consumable.item_description = description
	consumable.targeting_type = targeting_type
	consumable.effects = effects
	
	return consumable
