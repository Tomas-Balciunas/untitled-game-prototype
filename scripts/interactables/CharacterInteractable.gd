extends Interactable

class_name CharacterInteractable

var character: CharacterInstance = null

func _interact():
	if !character:
		push_error("Character not assigned to character interactable!")
	
	RestBus.rest_character_interaction_requested.emit(character)

func set_character(char: CharacterInstance):
	character = char
	
