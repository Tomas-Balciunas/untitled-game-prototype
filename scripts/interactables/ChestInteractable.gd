extends Interactable

class_name ChestInteractable

@export var quantity: int = 1
var chest: Chest = null

func _interact() -> void:
	if !chest:
		chest = Chest.new()
		chest.locked = true
		chest.items = build_items()
	
	ChestBus.open_chest_requested.emit(chest)

func build_items() -> Array[Item]:
	var generator := GearGenerator.new(quantity)
	return generator.generate()
