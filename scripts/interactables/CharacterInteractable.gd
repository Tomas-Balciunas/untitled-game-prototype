extends Interactable

class_name CharacterInteractable

var character: Character = null

func _interact() -> void:
	if !character:
		push_error("Character not assigned to character interactable!")
	
	RestBus.rest_character_interaction_requested.emit(character)

func set_character(chara: Character) -> void:
	character = chara
	
