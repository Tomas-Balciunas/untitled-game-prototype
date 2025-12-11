extends Resource
class_name Chest

@export var id: String
@export var locked: bool = false
@export var trapped: bool = false
@export var was_opened: bool = false
@export var trap: Trap = null
@export var custom_items: Array[Item] = []
var items: Array[ItemInstance] = []

func remove_item(_item: ItemInstance) -> bool:
	for item in items:
		if item == _item:
			items.erase(item)
			
			return true
	
	return false

func set_locked(value: bool) -> void:
	locked = value
	ChestBus.chest_state_changed.emit(self)

func set_trapped(value: bool) -> void:
	trapped = value
	ChestBus.chest_state_changed.emit(self)
