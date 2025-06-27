extends Node

var characters: Dictionary[int, CharacterResource] = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths = [
		"res://characters/Lili.tres",
	]
	for path in res_paths:
		var res = ResourceLoader.load(path)
		if res:
			register_character(res)

func register_character(res: CharacterResource) -> void:
	characters[res.id] = res

func get_character(id: int) -> CharacterResource:
	return characters.get(id)
