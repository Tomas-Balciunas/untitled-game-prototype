extends Resource
class_name Inventory

@export var max_slots: int = 20
var slots: Array[Item] = []

func add_item(item: Item) -> bool:
	if max_slots > 0 and slots.size() >= max_slots:
		return false
	slots.append(item)
	return true

func remove_item(item: Item) -> bool:
	if item in slots:
		slots.erase(item)
		return true
		
	push_error("Item %s not found" % item.name)
	return false

func has_item(item: Item) -> bool:
	return item in slots

func get_all_items() -> Array[Item]:
	return slots.duplicate()

func find_by_type(type: int) -> Array[Item]:
	return slots.filter(func(i): return i.type == type)
