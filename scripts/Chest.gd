extends Resource
class_name Chest

@export var id: String
@export var locked: bool = false:
	set(value):
		trapped = value
		ChestBus.chest_state_changed.emit(self)
		
@export var trapped: bool = false:
	set(value):
		trapped = value
		ChestBus.chest_state_changed.emit(self)
		
@export var items: Array[Item] = []

func remove_item(_item: ItemInstance) -> void:
	for item in items:
		if _item.template == item:
			items.erase(item)
