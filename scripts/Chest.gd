extends Node

class_name Chest

var locked: bool = false
var items: Array[Item] = []

func remove_item(_item: ItemInstance) -> void:
	for item in items:
		if _item.template == item:
			items.erase(item)
