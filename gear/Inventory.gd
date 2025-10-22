extends Resource
class_name Inventory

@export var max_slots: int = 20
var slots: Array[ItemInstance] = []

func add_item(item: ItemInstance) -> bool:
	if max_slots > 0 and slots.size() >= max_slots:
		return false
	slots.append(item)
	return true

func remove_item(item: ItemInstance) -> bool:
	if item in slots:
		slots.erase(item)
		return true
		
	push_error("Item %s not found" % item.name)
	return false

func has_item(item: ItemInstance) -> bool:
	return item in slots

func get_all_items() -> Array[ItemInstance]:
	return slots.duplicate()

func find_by_type(type: int) -> Array[ItemInstance]:
	return slots.filter(func(i): return i.type == type)

func has_free_slot() -> bool:
	return max_slots > len(slots)

func transfer_item(from: CharacterInstance, to: CharacterInstance, item: ItemInstance) -> void:
	if !to.inventory.has_free_slot():
		NotificationBus.notification_requested.emit("%s's inventory is full!" % to.resource.name)
		return;
	
	var removed := from.inventory.remove_item(item)
	
	if removed:
		var added := to.inventory.add_item(item)
		
		if added:
			NotificationBus.notification_requested.emit("%s transferred to %s" % [item.get_item_name(), to.resource.name])
		else:
			NotificationBus.notification_requested.emit("%s's inventory is full!" % to.resource.name)
