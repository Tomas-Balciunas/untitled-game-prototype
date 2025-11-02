extends Resource
class_name Chest

@export var id: String
@export var locked: bool = false
@export var trapped: bool = false
@export var trap: Trap = null
@export var items: Array[Item] = []

func remove_item(_item: ItemInstance) -> void:
	for item in items:
		if _item.template == item:
			items.erase(item)

func set_locked(value: bool) -> void:
	locked = value
	ChestBus.chest_state_changed.emit(self)

func set_trapped(value: bool) -> void:
	trapped = value
	ChestBus.chest_state_changed.emit(self)
