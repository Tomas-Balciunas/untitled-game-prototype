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
	
	if !chest:
		build_chest(_map_data)
		
	update_chest_state()

func _interact() -> void:
	if !chest:
		push_error("Chest was not built!")
		
		return
	
	ChestBus.open_chest_requested.emit(chest)

func build_items(_map_data: Dictionary) -> Array[Item]:
	var generator := GearGenerator.new(quantity)
	return generator.generate()

func build_chest(map_data: Dictionary) -> void:
	var inst := Chest.new()
	inst.id = id
	inst.trapped = randf() > 0.5
	inst.items = build_items(map_data)

	
	chest = inst
	
func update_chest_state() -> void:
	MapInstance.chest_state[id] = to_dict()
	
func on_chest_state_changed(_chest: Chest) -> void:
	if chest and chest.id == _chest.id:
		update_chest_state()

func to_dict() -> Dictionary:
	var items := []
	
	for item: Item in chest.items:
		if item is Gear:
			var mods := []
			
			for mod: StatModifier in item.modifiers:
				mods.append(mod.id)
			
			items.append({
				"id": item.id,
				"modifiers": mods
			})
			
			continue
		if item is ConsumableItem:
			items.append({
				"id": item.id
			})
			
			continue
	
	return {
		"items": items,
		"locked": chest.locked,
		"trapped": chest.trapped,
		"random": random
	}
	
func from_dict(data: Dictionary) -> Chest:
	if !data:
		return null
		
	var items: Array[Item] = []
	
	for item: Dictionary in data.get("items", {}):
		var item_id: String = item.get("id")
		var item_res := ItemsRegistry.get_item(item_id).duplicate(true)
		
		if item_res:
			if item_res is Gear:
				var mods: Array[StatModifier] = []
				
				for mod_id: String in item.get("modifiers", []):
					var mod_res := StatModifierRegistry.get_modifier(mod_id)
					
					if mod_res:
						mods.append(mod_res)
					
				item_res.modifiers.append_array(mods)
		
		items.append(item_res)
		
	var updated_chest := Chest.new()
	updated_chest.locked = data.get("locked")
	updated_chest.trapped = data.get("trapped")
	updated_chest.items = items
	
	return updated_chest
