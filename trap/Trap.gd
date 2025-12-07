extends Resource

class_name Trap

@export var id: String
@export var name: String = "Trap"
@export var damage: int

func trigger(_target: CharacterInstance) -> void:
	pass
