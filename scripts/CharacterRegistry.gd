extends Node

var characters: Dictionary[String, CharacterResource] = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths = [
		"res://characters/allies/Lili/Lili.tres",
		"res://characters/allies/Skelly/Skelly.tres",
		"res://characters/foes/Skeltal/Skeltal.tres",
		"res://characters/foes/Balmer/Balmer.tres",
	]
	
	for path in res_paths:
		var res = ResourceLoader.load(path)
		if res:
			register_character(res)

func register_character(res: CharacterResource) -> void:
	characters[res.id] = res

func get_character(id: String) -> CharacterResource:
	return characters.get(id)
