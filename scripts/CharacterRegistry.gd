extends Node

var characters: Dictionary[String, CharacterResource] = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths := [
		"res://characters/allies/MC/MC.tres",
		"res://characters/allies/Lili/Lili.tres",
		"res://characters/allies/Skelly/Skelly.tres",
		"res://characters/foes/Skeltal/Skeltal.tres",
		"res://characters/foes/Balmer/Balmer.tres",
		"res://characters/allies/Coura/Coura.tres",
		"res://characters/foes/_fallback/boo.tres"
	]
	
	for path: String in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_character(res)

func register_character(res: CharacterResource) -> void:
	characters[res.id] = res

func get_character(id: String) -> CharacterResource:
	return characters.get(id)

func get_characters(ids: Array) -> Array[CharacterResource]:
	var collection: Array[CharacterResource] = []
	for id: String in ids:
		if characters.has(id):
			collection.append(characters[id])
			
	return collection
