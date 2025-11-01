extends Interactable

class_name ChestInteractable

@export var quantity: int = 2
@export var chest: Chest = null

func on_map_loaded(_map_data: Dictionary) -> void:
	if !chest:
		build_chest(_map_data)

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
	inst.trapped = randf() > 0.5
	inst.items = build_items(map_data)
	
	chest = inst
