extends Resource

class_name Trap

@export var id: String
@export var name: String = "Trap"
@export var damage: int

func trigger(_target: CharacterInstance) -> void:
	pass

func get_source() -> CharacterInstance:
	var res := CharacterResource.new()
	res.name = name
	return CharacterInstance.new(res)
