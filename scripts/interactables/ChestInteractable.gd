extends Interactable

class_name ChestInteractable

@export var id: String
@export var random: bool = false
@export var quantity: int = 2
@export var chest: Chest

func on_map_loaded(_map_data: Dictionary) -> void:
	if !ChestBus.chest_state_changed.is_connected(on_chest_state_changed):
		ChestBus.chest_state_changed.connect(on_chest_state_changed)

	var data: Dictionary = MapInstance.chest_state.get(id, {})
	
	if !data.is_empty():
		chest = from_dict(data)
		
		return
	
	if !chest:
		build_chest(_map_data)
		update_chest_state()
		
		return
	
	if not chest.custom_items.is_empty() and not chest.was_opened:
		for item: Item in chest.custom_items:
			chest.items.append(item._build_instance())
	
	chest.custom_items.clear()
	update_chest_state()

func _interact() -> void:
	if !chest:
		push_error("Chest was not built!")
		
		return
	
	ChestBus.open_chest_requested.emit(chest)

func build_items(_map_data: Dictionary) -> Array[ItemInstance]:
	var generator := GearGenerator.new(quantity)
	return generator.generate()

func build_chest(map_data: Dictionary) -> void:
	var inst := Chest.new()
	inst.id = id
	inst.trapped = randf() > 0
	inst.items = build_items(map_data)

	
	chest = inst
	
func update_chest_state() -> void:
	MapInstance.chest_state[id] = to_dict()
	
func on_chest_state_changed(_chest: Chest) -> void:
	if chest and chest.id == _chest.id:
		update_chest_state()

func to_dict() -> Dictionary:
	var items := []
	
	for item: ItemInstance in chest.items:
		items.append(item.game_save())
	
	return {
		"id": id,
		"items": items,
		"locked": chest.locked,
		"trapped": chest.trapped,
		"was_opened": chest.was_opened,
		"random": random
	}
	
func from_dict(data: Dictionary) -> Chest:
	if !data:
		return null
		
	var items: Array[ItemInstance] = []
	
	for item: Dictionary in data.get("items", {}):
		var item_class: String = item.get("class")
		var cls: ItemInstance = ClassDB.instantiate(item_class)
		cls.game_load(item)
		items.append(cls)
		
	var updated_chest := Chest.new()
	updated_chest.id = data.get("id")
	updated_chest.locked = data.get("locked")
	updated_chest.trapped = data.get("trapped")
	updated_chest.was_opened = data.get("was_opened")
	updated_chest.items = items
	
	return updated_chest
