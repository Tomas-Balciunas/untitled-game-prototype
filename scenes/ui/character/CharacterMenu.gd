extends Control
class_name CharacterMenu

var character_instance: CharacterInstance

@onready var menu = $Menu
@onready var name_label = $Menu/Name

func bind(character: CharacterInstance) -> void:
	character_instance = character
	$Menu/Name.text = character.resource.name
