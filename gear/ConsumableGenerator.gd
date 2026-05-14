extends Node

class_name ConsumableGenerator

const MAX_QUANTITY = 10


var quantity: int:
	set(value):
		if value < 1 or value > MAX_QUANTITY:
			quantity = randi() % MAX_QUANTITY + 1
		else:
			quantity = value


func _init(qty: int) -> void:
	quantity = qty


func generate() -> Array[Consumable]:
	var out: Array[Consumable] = []
	var pool := _build_pool()

	if pool.is_empty():
		push_warning("ConsumableGenerator: no consumables registered in ItemsRegistry")
		return out

	for i in range(quantity):
		var template: ConsumableItem = pool.pick_random()
		var inst: Consumable = template._build_instance()
		out.append(inst)

	return out


func _build_pool() -> Array[ConsumableItem]:
	var pool: Array[ConsumableItem] = []
	for item: ItemResource in ItemsRegistry.get_all_items():
		if item is ConsumableItem:
			pool.append(item)
	return pool
